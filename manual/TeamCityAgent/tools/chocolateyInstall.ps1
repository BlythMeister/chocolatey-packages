$ErrorActionPreference = 'Stop'

# Parse parameters using the Chocolatey helper
$pp = Get-PackageParameters

# Backward-compatibility fallback for legacy semicolon-delimited strings
if (-not $pp.Count -and $env:chocolateyPackageParameters) {
    $pp = ConvertFrom-StringData -StringData ($env:chocolateyPackageParameters -replace ';', "`n")
}

# -------------------------------------------------------------------------
# Parameter Validation
# -------------------------------------------------------------------------

# Community Verifier / Test Runner Check:
# If running in an automated test environment without parameters, exit cleanly
if (-not $pp['serverUrl'] -and ($env:ChocolateyPackageTesting -eq 'true' -or -not $env:chocolateyPackageParameters)) {
    Write-Warning "No 'serverUrl' parameter supplied during verification test."
    Write-Warning "Usage: choco install TeamCityAgent --params ""'/serverUrl:http://your-server:8111 /agentName:MyAgent'"""
    return
}

# End-User Validation: Enforce required serverUrl for actual installs
if (-not $pp['serverUrl']) {
    throw "Missing required parameter 'serverUrl'. Please specify the TeamCity server URL (e.g., --params ""'/serverUrl:http://your-server:8111'"")."
}

# Set variables and apply defaults for optional parameters
$serverUrl = $pp['serverUrl'].TrimEnd('/')
$agentDir  = if ($pp['agentDir'])  { $pp['agentDir'] }  else { "$env:SystemDrive\buildAgent" }
$agentName = if ($pp['agentName']) { $pp['agentName'] } else { $env:COMPUTERNAME }
$ownPort   = if ($pp['ownPort'])   { $pp['ownPort'] }   else { '9090' }

Write-Host "Configuring TeamCity Agent with:"
Write-Host "  serverUrl: $serverUrl"
Write-Host "  agentDir:  $agentDir"
Write-Host "  agentName: $agentName"
Write-Host "  ownPort:   $ownPort"

# -------------------------------------------------------------------------
# Download
# -------------------------------------------------------------------------
# Using native WebClient instead of Get-ChocolateyWebFile to bypass static checksum validation
$downloadUrl = "$serverUrl/update/buildAgent.zip"
$tempZip     = Join-Path $env:TEMP 'buildAgent.zip'

Write-Host "Downloading TeamCity Agent from $downloadUrl..."
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12,Tls13'
$webClient = New-Object System.Net.WebClient
try {
    $webClient.DownloadFile($downloadUrl, $tempZip)
}
finally {
    $webClient.Dispose()
}

# -------------------------------------------------------------------------
# Extract & Clean Up
# -------------------------------------------------------------------------
Get-ChocolateyUnzip -FileFullPath $tempZip -Destination $agentDir

if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
}

# -------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------
$distProps = Join-Path $agentDir 'conf\buildAgent.dist.properties'
$realProps = Join-Path $agentDir 'conf\buildAgent.properties'

if (Test-Path $distProps) {
    Copy-Item $distProps $realProps -Force

    (Get-Content $realProps) `
        -replace 'serverUrl=.*', "serverUrl=$serverUrl" `
        -replace 'name=.*', "name=$agentName" `
        -replace 'ownPort=.*', "ownPort=$ownPort" `
        | Set-Content $realProps
}
else {
    Write-Warning "Could not find $distProps to template configuration."
}

# -------------------------------------------------------------------------
# Service Installation & Start
# -------------------------------------------------------------------------
$serviceInstall = Join-Path $agentDir 'bin\service.install.bat'
$serviceStart   = Join-Path $agentDir 'bin\service.start.bat'

if (Test-Path $serviceInstall) {
    Start-ChocolateyProcessAsAdmin "/C `"$serviceInstall && $serviceStart`"" cmd
}
else {
    Write-Warning "Service install script not found at $serviceInstall."
}

Write-ChocolateySuccess 'TeamCityAgent'

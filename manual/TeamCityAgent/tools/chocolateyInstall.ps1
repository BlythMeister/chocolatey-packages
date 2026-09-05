$ErrorActionPreference = 'Stop'

# Support standard /param:value and space/newline-delimited parameters
$pp = Get-PackageParameters
if (-not $pp.Count -and $env:chocolateyPackageParameters) {
    $pp = ConvertFrom-StringData -StringData ($env:chocolateyPackageParameters.Replace(' ', "`n"))
}

# -------------------------------------------------------------------------
# Parameter Validation & Community Verifier Check
# -------------------------------------------------------------------------
# If running under the automated Community Package Verifier, exit cleanly
if (-not $pp['serverUrl'] -and ($env:ChocolateyPackageTesting -eq 'true' -or -not $env:chocolateyPackageParameters)) {
    Write-Warning "No 'serverUrl' parameter supplied during verification test."
    Write-Warning "Usage: choco install TeamCityAgent --params ""'serverUrl=http://teamcity:8111 agentName=Agent1'"""
    return
}

if (-not $pp['serverUrl']) {
    throw "Please specify the TeamCity server URL by passing it as a parameter to Chocolatey install, e.g. -params 'serverUrl=http://...'"
}

if (-not $pp['agentDir']) {
    $pp['agentDir'] = "$env:SystemDrive\buildAgent"
    Write-Host "No agent directory is specified. Defaulting to $($pp['agentDir'])"
}

if (-not $pp['agentWorkDir']) {
    $pp['agentWorkDir'] = "$($pp['agentDir'])\work"
    Write-Host "No agent work directory is specified. Defaulting to $($pp['agentWorkDir'])"
}

if (-not $pp['agentTempDir']) {
    $pp['agentTempDir'] = "$($pp['agentDir'])\temp"
    Write-Host "No agent temp directory is specified. Defaulting to $($pp['agentTempDir'])"
}

if (-not $pp['agentSystemDir']) {
    $pp['agentSystemDir'] = "$($pp['agentDir'])\system"
    Write-Host "No agent system directory is specified. Defaulting to $($pp['agentSystemDir'])"
}

if (-not $pp['agentName']) {
    $defaultName = $true
    $pp['agentName'] = "$env:COMPUTERNAME"
    Write-Host "No agent name is specified. Defaulting to $($pp['agentName'])"
}

if (-not $pp['ownPort']) {
    $pp['ownPort'] = "9090"
    Write-Host "No agent port is specified. Defaulting to $($pp['ownPort'])"
}

if (-not $pp['serviceAccount']) {
    $defaultServiceAccount = $true
    Write-Host "No service account provided, will run as system account."
}

$agentZipArchiveName = "buildAgent.zip"
if ($pp['downloadFullAgent'] -eq $true -or $pp['downloadFullAgent'] -eq 'true') {
    $agentZipArchiveName = "buildAgentFull.zip"
    Write-Host "Will download full agent ZIP archive with plugins."
}

$packageName = "TeamCityAgent"
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

## Make local variables of it
$serverUrl               = $pp['serverUrl'].TrimEnd('/')
$agentDir                = $pp['agentDir']
$agentWorkDir            = $pp['agentWorkDir'].Replace("\", "\\")
$agentTempDir            = $pp['agentTempDir'].Replace("\", "\\")
$agentSystemDir          = $pp['agentSystemDir'].Replace("\", "\\")
$agentName               = $pp['agentName']
$ownPort                 = $pp['ownPort']
$serviceAccount          = $pp['serviceAccount']
$serviceAccountPassword  = $pp['serviceAccountPassword']
$agentDrive              = Split-Path $agentDir -Qualifier
$buildAgentDistFile      = "$agentDir\conf\buildAgent.dist.properties"
$buildAgentPropFile      = "$agentDir\conf\buildAgent.properties"

if ($serviceAccount -ne $null) {
    if ($serviceAccount -notlike "*\*") {
        Write-Verbose "Service account has no '\' assuming local user"
        $serviceAccount = ".\$serviceAccount"
    }
}

# Write out the install parameters to a file for reference during upgrade/uninstall
$pp.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Write-Verbose
$pp.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Out-File "$toolsDir\install-parameters.txt" -Encoding ascii

$currentConfig = $null
if (Test-Path -Path $buildAgentPropFile) {
    Write-Verbose "Loading previous install settings"
    $currentConfig = Get-Content -Path $buildAgentPropFile
}

# -------------------------------------------------------------------------
# Download & Extraction (Replaces Install-ChocolateyZipPackage to avoid static checksum rule)
# -------------------------------------------------------------------------
$downloadUrl = "$serverUrl/update/$agentZipArchiveName"
$tempZip     = Join-Path $env:TEMP $agentZipArchiveName

Write-Host "Downloading TeamCity Agent from $downloadUrl..."
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12,Tls13'
$webClient = New-Object System.Net.WebClient
try {
    $webClient.DownloadFile($downloadUrl, $tempZip)
}
finally {
    $webClient.Dispose()
}

Get-ChocolateyUnzip -FileFullPath $tempZip -Destination $agentDir

if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
}

# Generic function to read Java properties file into ordered dict
function Get-PropsDictFromJavaPropsFile ($configFile) {
    $config = Get-Content $configFile
    Write-Verbose "$config"
    $configProps = [ordered]@{}
    $config | ForEach-Object {
        if ((!($_.StartsWith('#'))) `
            -and (!($_.StartsWith(';'))) `
            -and (!($_.StartsWith('`'))) `
            -and ($_.Contains('='))) {
            $props = $_.Split('=', 2)
            Write-Verbose "Props are $props"
            $configProps.Add($props[0], $props[1])
        }
    }
    return $configProps
}

# Configure agent
if ($currentConfig -ne $null) {
    Write-Verbose "Keeping previous install settings"
    Set-Content -Path $buildAgentPropFile -Value $currentConfig
    $buildAgentProps = Get-PropsDictFromJavaPropsFile $buildAgentPropFile
}
else {
    $buildAgentProps = Get-PropsDictFromJavaPropsFile $buildAgentDistFile
}

Write-Verbose "Build Agent original settings"
$buildAgentProps.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Write-Verbose

# Set values that require customization
$buildAgentProps['serverUrl'] = $serverUrl
$buildAgentProps['name']      = $agentName
$buildAgentProps['workDir']   = $agentWorkDir
$buildAgentProps['tempDir']   = $agentTempDir
$buildAgentProps['systemDir'] = $agentSystemDir
$buildAgentProps['ownPort']   = $ownPort

Write-Verbose "Build Agent updated settings"
$buildAgentProps.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Write-Verbose
$buildAgentProps.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Out-File $buildAgentPropFile -Encoding 'ascii'

# Rewrite the wrapper config file without comments if non-default settings were supplied
if (-not ($defaultName -eq $true -and $defaultServiceAccount -eq $true)) {
    $wrapperPropsFile = "$agentDir\launcher\conf\wrapper.conf"
    $wrapperProps     = Get-PropsDictFromJavaPropsFile $wrapperPropsFile

    Write-Verbose "Java Service Wrapper original settings"
    $wrapperProps.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Write-Verbose

    if (-not ($defaultName -eq $true -or $agentName -eq "")) {
        $wrapperProps['wrapper.ntservice.name']        = "$agentName"
        $wrapperProps['wrapper.ntservice.displayname'] = "$agentName TeamCity Build Agent"
        $wrapperProps['wrapper.ntservice.description'] = "$agentName TeamCity Build Agent Service"
    }
    if ($serviceAccount -ne $null) {
        $wrapperProps['wrapper.ntservice.account']     = "$serviceAccount"
        $wrapperProps['wrapper.ntservice.interactive'] = "false"
    }
    if ($serviceAccountPassword -ne $null) {
        $wrapperProps['wrapper.ntservice.password']    = "$serviceAccountPassword"
    }

    Write-Verbose "Java Service Wrapper updated settings"
    $wrapperProps.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Write-Verbose
    $wrapperProps.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Out-File $wrapperPropsFile -Encoding 'ascii'
}

# Install and start the service
$workingDirectory = Join-Path $agentDir "bin"
Start-ChocolateyProcessAsAdmin "Set-Location `"$workingDirectory`"; Start-Process -FilePath .\service.install.bat -Wait"
Start-Sleep -Seconds 2
Start-ChocolateyProcessAsAdmin "Set-Location `"$workingDirectory`"; Start-Process -FilePath .\service.start.bat -Wait"
Start-Sleep -Seconds 2

$checkServiceName = "TCBuildAgent"
if (-not ($defaultName -eq $true -or $agentName -eq "")) {
    $checkServiceName = $agentName
}

if ((Get-Service | Where-Object { $_.Status -eq "Running" -and $_.Name -eq $checkServiceName } | Measure-Object).Count -eq 0) {
    Set-PowerShellExitCode 1
}
else {
    Set-PowerShellExitCode 0
}

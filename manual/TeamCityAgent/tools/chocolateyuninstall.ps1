$ErrorActionPreference = 'Stop'

$packageName = 'TeamCityAgent'
$toolsDir    = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$paramsFile  = Join-Path $toolsDir 'install-parameters.txt'

# 1. Parse parameters passed directly to uninstall
$pp = Get-PackageParameters
if (-not $pp.Count -and $env:chocolateyPackageParameters) {
    # Match install script delimiter handling (spaces or semicolons)
    $cleanParams = $env:chocolateyPackageParameters -replace ';', "`n" -replace ' ', "`n"
    $pp = ConvertFrom-StringData -StringData $cleanParams
}

# 2. Fall back to saved install parameters if not explicitly provided during uninstall
if (Test-Path $paramsFile) {
    Write-Verbose "Reading saved install parameters from $paramsFile"
    $savedParams = Get-Content $paramsFile -Raw | ConvertFrom-StringData
    foreach ($key in $savedParams.Keys) {
        if (-not $pp[$key]) {
            $pp[$key] = $savedParams[$key]
        }
    }
}

# Resolve target directory and service name
$agentDir  = if ($pp['agentDir'])  { $pp['agentDir'] }  else { "$env:SystemDrive\buildAgent" }
$agentName = if ($pp['agentName']) { $pp['agentName'] } else { 'TCBuildAgent' }

Write-Host "Uninstalling TeamCity Agent ($agentName) from: $agentDir"

# -------------------------------------------------------------------------
# Stop and Uninstall Windows Service
# -------------------------------------------------------------------------
$serviceStop      = Join-Path $agentDir 'bin\service.stop.bat'
$serviceUninstall = Join-Path $agentDir 'bin\service.uninstall.bat'

# Gracefully stop via TeamCity script if present
if (Test-Path $serviceStop) {
    Write-Host "Stopping TeamCity Agent service via service.stop.bat..."
    Start-ChocolateyProcessAsAdmin "Set-Location `"$agentDir\bin`"; Start-Process -FilePath .\service.stop.bat -Wait"
}

# Uninstall service via TeamCity script
if (Test-Path $serviceUninstall) {
    Write-Host "Uninstalling TeamCity Agent service via service.uninstall.bat..."
    Start-ChocolateyProcessAsAdmin "Set-Location `"$agentDir\bin`"; Start-Process -FilePath .\service.uninstall.bat -Wait"
}

# Fallback: Check if service is still registered under $agentName or TCBuildAgent
$serviceNames = @($agentName, 'TCBuildAgent') | Select-Object -Unique
foreach ($sName in $serviceNames) {
    $svc = Get-Service -Name $sName -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "Stopping and removing lingering service '$sName' via sc.exe..."
        Stop-Service -Name $sName -Force -ErrorAction SilentlyContinue
        & sc.exe delete "$sName" | Out-Null
    }
}

# -------------------------------------------------------------------------
# Remove Files
# -------------------------------------------------------------------------
if (Test-Path $agentDir) {
    Write-Host "Removing agent directory: $agentDir"
    Start-Sleep -Seconds 2
    Remove-Item -Path $agentDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Clean up saved parameters file
if (Test-Path $paramsFile) {
    Remove-Item -Path $paramsFile -Force -ErrorAction SilentlyContinue
}

Write-ChocolateySuccess $packageName

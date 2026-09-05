$ErrorActionPreference = 'Stop'

# Parse parameters using the Chocolatey helper
$pp = Get-PackageParameters

# Backward-compatibility fallback for legacy semicolon-delimited strings
if (-not $pp.Count -and $env:chocolateyPackageParameters) {
    $pp = ConvertFrom-StringData -StringData ($env:chocolateyPackageParameters -replace ';', "`n")
}

# Resolve target directory (defaulting to the same install path)
$agentDir = if ($pp['agentDir']) { $pp['agentDir'] } else { "$env:SystemDrive\buildAgent" }

Write-Host "Uninstalling TeamCity Agent from: $agentDir"

# -------------------------------------------------------------------------
# Stop and Uninstall Windows Service
# -------------------------------------------------------------------------
$serviceStop      = Join-Path $agentDir 'bin\service.stop.bat'
$serviceUninstall = Join-Path $agentDir 'bin\service.uninstall.bat'

# 1. Gracefully stop via TeamCity script if present
if (Test-Path $serviceStop) {
    Write-Host "Stopping TeamCity Agent service..."
    Start-ChocolateyProcessAsAdmin "/C `"$serviceStop`"" cmd
}

# 2. Uninstall service via TeamCity script
if (Test-Path $serviceUninstall) {
    Write-Host "Uninstalling TeamCity Agent service..."
    Start-ChocolateyProcessAsAdmin "/C `"$serviceUninstall`"" cmd
}
else {
    # Fallback in case directory was partially removed or service scripts are missing
    $tcService = Get-Service -Name "TCBuildAgent" -ErrorAction SilentlyContinue
    if ($tcService) {
        Write-Host "Stopping and deleting TCBuildAgent Windows service via sc.exe..."
        Stop-Service -Name "TCBuildAgent" -Force -ErrorAction SilentlyContinue
        & sc.exe delete "TCBuildAgent" | Out-Null
    }
}

# -------------------------------------------------------------------------
# Remove Files
# -------------------------------------------------------------------------
if (Test-Path $agentDir) {
    Write-Host "Removing agent directory: $agentDir"
    # Small pause to allow process handles to fully release
    Start-Sleep -Seconds 2
    Remove-Item -Path $agentDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-ChocolateySuccess 'TeamCityAgent'

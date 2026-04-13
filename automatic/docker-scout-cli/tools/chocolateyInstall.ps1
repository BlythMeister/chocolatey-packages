$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerScoutCli.Helpers.ps1')

$Url64 = 'https://github.com/docker/scout-cli/releases/download/v1.20.3/docker-scout_1.20.3_windows_amd64.zip'
$Checksum64 = '8ed01dd39c7646187ef9f631952df226b84829b0ffe2f57600057f64be73fda3'
$ChecksumType64 = 'sha256'

$packageParameters = Get-DockerScoutCliPackageParameters
$pluginDirectory = Get-DockerScoutCliPluginDirectory -PackageParameters $packageParameters -ToolsPath $toolsPath
$dockerScoutPath = Join-Path $pluginDirectory 'docker-scout.exe'

$archivePath = Join-Path $env:TEMP "$($env:ChocolateyPackageName)-$($env:ChocolateyPackageVersion)-windows-amd64.zip"
$extractPath = Join-Path $env:TEMP "$($env:ChocolateyPackageName)-$($env:ChocolateyPackageVersion)-extract"

try {
    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }

    Get-ChocolateyWebFile `
        -PackageName $env:ChocolateyPackageName `
        -FileFullPath $archivePath `
        -Url64bit $Url64 `
        -Checksum64 $Checksum64 `
        -ChecksumType64 $ChecksumType64 | Out-Null

    Get-ChocolateyUnzip -FileFullPath $archivePath -Destination $extractPath

    $downloadedExecutablePath = Join-Path $extractPath 'docker-scout.exe'
    if (-not (Test-Path $downloadedExecutablePath)) {
        throw "Unable to find docker-scout.exe after extracting '$archivePath'."
    }

    New-Item -ItemType Directory -Path $pluginDirectory -Force | Out-Null
    Copy-Item -Path $downloadedExecutablePath -Destination $dockerScoutPath -Force
    Write-DockerScoutCliPluginDirectoryWarning -PluginDirectory $pluginDirectory

    Save-DockerScoutCliInstallMetadata -ToolsPath $toolsPath -PluginDirectory $pluginDirectory
}
finally {
    if (Test-Path $archivePath) {
        Remove-Item -Path $archivePath -Force
    }

    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }
}

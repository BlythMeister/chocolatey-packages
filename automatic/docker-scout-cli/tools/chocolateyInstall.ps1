$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerScoutCli.Helpers.ps1')

$Url64 = 'https://github.com/docker/scout-cli/releases/download/v1.24.0/docker-scout_1.24.0_windows_amd64.zip'
$Checksum64 = '1b7afb489e9224411fafe848eb5002cdc5c59a5cf2b77d6ccffcb44ffdf4f350'
$ChecksumType64 = 'sha256'

$packageParameters = Get-DockerScoutCliPackageParameters
$pluginDirectory = Get-DockerScoutCliPluginDirectory -PackageParameters $packageParameters -ToolsPath $toolsPath
$dockerScoutPath = Join-Path $pluginDirectory 'docker-scout.exe'
$configPath = Get-DockerScoutCliConfigPath

$archivePath = Join-Path $env:TEMP "$($env:ChocolateyPackageName)-$($env:ChocolateyPackageVersion)-windows-amd64.zip"
$extractPath = Join-Path $env:TEMP "$($env:ChocolateyPackageName)-$($env:ChocolateyPackageVersion)-extract"
$addedCliPluginsExtraDir = $false

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
    $addedCliPluginsExtraDir = Add-DockerScoutCliPluginDirectoryToDockerConfig -PluginDirectory $pluginDirectory

    Save-DockerScoutCliInstallMetadata `
        -ToolsPath $toolsPath `
        -PluginDirectory $pluginDirectory `
        -ConfigPath $configPath `
        -AddedCliPluginsExtraDir $addedCliPluginsExtraDir
}
finally {
    if (Test-Path $archivePath) {
        Remove-Item -Path $archivePath -Force
    }

    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }
}

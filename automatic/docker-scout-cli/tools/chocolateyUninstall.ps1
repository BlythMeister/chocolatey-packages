$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerScoutCli.Helpers.ps1')

$packageParameters = Get-DockerScoutCliPackageParameters
$userProfilePath = Get-DockerScoutCliUserProfilePath -PackageParameters $packageParameters -ToolsPath $toolsPath -AllowMetadataFallback
$pluginDirectory = Get-DockerScoutCliPluginDirectory -UserProfilePath $userProfilePath
$dockerScoutPath = Join-Path $pluginDirectory 'docker-scout.exe'

if (Test-Path $dockerScoutPath) {
    Remove-Item -Path $dockerScoutPath -Force
}

if (Test-Path $pluginDirectory) {
    $remainingFiles = Get-ChildItem -Path $pluginDirectory -Force
    if ($remainingFiles.Count -eq 0) {
        Remove-Item -Path $pluginDirectory -Force
    }
}

Remove-DockerScoutCliPluginDirectoryFromConfig -UserProfilePath $userProfilePath
Remove-DockerScoutCliInstallMetadata -ToolsPath $toolsPath

$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerScoutCli.Helpers.ps1')

$packageParameters = Get-DockerScoutCliPackageParameters
$pluginDirectory = Get-DockerScoutCliPluginDirectory -PackageParameters $packageParameters -ToolsPath $toolsPath -AllowMetadataFallback
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

Remove-DockerScoutCliInstallMetadata -ToolsPath $toolsPath

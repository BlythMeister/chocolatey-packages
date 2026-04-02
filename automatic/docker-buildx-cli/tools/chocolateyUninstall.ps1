$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerBuildxCli.Helpers.ps1')

$packageParameters = Get-DockerBuildxCliPackageParameters
$pluginDirectory = Get-DockerBuildxCliPluginDirectory -PackageParameters $packageParameters -ToolsPath $toolsPath -AllowMetadataFallback
$dockerBuildxPath = Join-Path $pluginDirectory 'docker-buildx.exe'

if (Test-Path $dockerBuildxPath) {
    Remove-Item -Path $dockerBuildxPath -Force
}

if (Test-Path $pluginDirectory) {
    $remainingFiles = Get-ChildItem -Path $pluginDirectory -Force
    if ($remainingFiles.Count -eq 0) {
        Remove-Item -Path $pluginDirectory -Force
    }
}

Remove-DockerBuildxCliInstallMetadata -ToolsPath $toolsPath

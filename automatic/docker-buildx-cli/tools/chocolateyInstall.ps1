$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerBuildxCli.Helpers.ps1')

$Url64 = 'https://github.com/docker/buildx/releases/download/v0.37.1/buildx-v0.37.1.windows-amd64.exe'
$Checksum64 = '3904abb2802f9bd83a2bf483b35bba81c57a4e0baff981e6886564c461f908b3'
$ChecksumType64 = 'sha256'

$packageParameters = Get-DockerBuildxCliPackageParameters
$pluginDirectory = Get-DockerBuildxCliPluginDirectory -PackageParameters $packageParameters -ToolsPath $toolsPath
$setAsDefaultBuilder = Test-DockerBuildxCliSetAsDefaultBuilderRequested -PackageParameters $packageParameters
$dockerBuildxPath = Join-Path $pluginDirectory 'docker-buildx.exe'

New-Item -ItemType Directory -Path $pluginDirectory -Force | Out-Null

Get-ChocolateyWebFile `
    -PackageName $env:ChocolateyPackageName `
    -FileFullPath $dockerBuildxPath `
    -Url64bit $Url64 `
    -Checksum64 $Checksum64 `
    -ChecksumType64 $ChecksumType64 | Out-Null

Write-DockerBuildxCliPluginDirectoryWarning -PluginDirectory $pluginDirectory

if ($setAsDefaultBuilder) {
    $dockerCommand = Get-Command docker -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $dockerCommand) {
        throw "Package parameter '/SetAsDefaultBuilder' requires Docker CLI to already be installed and available on PATH."
    }

    & $dockerCommand.Source buildx install

    if ($LASTEXITCODE -ne 0) {
        throw "docker buildx install failed with exit code $LASTEXITCODE."
    }
}

Save-DockerBuildxCliInstallMetadata -ToolsPath $toolsPath -PluginDirectory $pluginDirectory

$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerBuildxCli.Helpers.ps1')

$Url64 = 'https://github.com/docker/buildx/releases/download/v0.35.0/buildx-v0.35.0.windows-amd64.exe'
$Checksum64 = '8076395009787cd1d30c94edeb5d7ac3945273374fc162c00e9810c3e9325ebe'
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

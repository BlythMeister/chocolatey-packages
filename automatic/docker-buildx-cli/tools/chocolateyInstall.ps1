$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerBuildxCli.Helpers.ps1')

$Url64 = 'https://github.com/docker/buildx/releases/download/v0.36.0/buildx-v0.36.0.windows-amd64.exe'
$Checksum64 = 'ce84699d1d93a67d25888b9e6a717862a71b20305602f96d44770b1c12dfcdd8'
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

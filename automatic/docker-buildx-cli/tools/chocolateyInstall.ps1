$ErrorActionPreference = 'Stop'

$toolsPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $toolsPath 'DockerBuildxCli.Helpers.ps1')

$Url64 = 'https://github.com/docker/buildx/releases/download/v0.38.2/buildx-v0.38.2.windows-amd64.exe'
$Checksum64 = '9a6aca9c84adda0391d1d98d8b74b49359cad1bcdadd196a0a5d7d5dc4cf15e0'
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

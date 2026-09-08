$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/CheckPoint_SASE_13.0.0.19553.msi'
  checksum       = 'f8382cabfad6a5a0a0df984aad9f3a8fdc5abdab8a53e52f794489addb78145d'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

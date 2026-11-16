$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/CheckPoint_SASE_13.3.0.21591.msi'
  checksum       = 'd08620bd8f0417b38cb2628e3d31ce6cb74df16b15a94bd2a7c77351ee3b3ac1'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

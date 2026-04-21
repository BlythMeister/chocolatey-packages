$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/Harmony_SASE_12.7.4.14246.msi'
  checksum       = '7b5fbf4d74b45f879428bc82f65296f8f67caaf3350f49b36f7bb029c8a2fbf9'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

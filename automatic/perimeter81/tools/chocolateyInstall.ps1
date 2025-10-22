$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/Harmony_SASE_12.1.0.9079.msi'
  checksum       = '7dd280478775025506ddb9ce177b768765f35c1e3a7dab1574006b8aba3ff55a'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

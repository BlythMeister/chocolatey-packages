$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/Harmony_SASE_12.5.0.11894.msi'
  checksum       = '2477c7ee0d196f6693891d97209669487f9f46767e1866b4041db7f8812c52cd'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

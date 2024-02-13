$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/Perimeter81_10.4.2.1645.msi'
  checksum       = 'af37f79c904857ddf2687c5f011dfa2dd588de9d7aadfae85c29871658051418'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart /log `"$env:TEMP\chocolatey\$($env:ChocolateyPackageName)\$($env:ChocolateyPackageVersion)\Install.log`"'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

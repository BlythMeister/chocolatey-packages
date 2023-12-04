$ErrorActionPreference = 'Stop'

$toolsPath      = Split-Path $MyInvocation.MyCommand.Definition

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = "Perimeter81*"
  fileType       = 'msi'
  url            = 'https://static.perimeter81.com/agents/windows/Perimeter81_10.3.1.1542.msi'
  checksum       = 'e3e50e578a561ae9beb0b8dbf7cfe4517a60847cbe0e0ec72c3ce924f73609dc'
  checksumType   = 'sha256'
  silentArgs     = '/q /norestart /log `"$env:TEMP\chocolatey\$($env:ChocolateyPackageName)\$($env:ChocolateyPackageVersion)\Install.log`"'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs

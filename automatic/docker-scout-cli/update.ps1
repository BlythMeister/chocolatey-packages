import-module au

$releasesUrl = 'https://api.github.com/repos/docker/scout-cli/releases/298919514'
$assetPattern = '^docker-scout_(?<Version>\d+\.\d+\.\d+)_windows_amd64\.zip$'
$headers = @{
  'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AuScript'
}

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyInstall.ps1' = @{
      '(?i)(^\s*\$Url64\s*=\s*)(''.*'')'          = "`$1'$($Latest.URL64)'"
      '(?i)(^\s*\$Checksum64\s*=\s*)(''.*'')'     = "`$1'$($Latest.Checksum64)'"
      '(?i)(^\s*\$ChecksumType64\s*=\s*)(''.*'')' = "`$1'$($Latest.ChecksumType64)'"
    }
  }
}

function Get-ReleaseAsset {
  param(
    [Parameter(Mandatory)]
    [object[]]$Assets,

    [Parameter(Mandatory)]
    [string]$Pattern
  )

  $asset = $Assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
  if ($null -eq $asset) {
    throw "Unable to find a release asset matching '$Pattern'."
  }

  return $asset
}

function Get-AssetChecksum {
  param(
    [Parameter(Mandatory)]
    [psobject]$Asset
  )

  $digest = [string]$Asset.digest
  if ([string]::IsNullOrWhiteSpace($digest)) {
    throw "Unable to find a digest for release asset '$($Asset.name)'."
  }

  if ($digest -notmatch '^sha256:(?<Checksum>[a-fA-F0-9]+)$') {
    throw "Unable to parse SHA256 digest '$digest' for release asset '$($Asset.name)'."
  }

  return $Matches.Checksum.ToLowerInvariant()
}

function global:au_GetLatest {
  $release = Invoke-RestMethod -Uri $releasesUrl -Headers $headers
  $asset = Get-ReleaseAsset -Assets $release.assets -Pattern $assetPattern

  if ($asset.name -notmatch $assetPattern) {
    throw "Unable to parse version from release asset '$($asset.name)'."
  }

  $version = Get-Version $Matches.Version
  $checksum = Get-AssetChecksum -Asset $asset

  return @{
    URL64 = $asset.browser_download_url
    Version = $version
    Checksum64 = $checksum
    ChecksumType64 = 'sha256'
  }
}

update -ChecksumFor none

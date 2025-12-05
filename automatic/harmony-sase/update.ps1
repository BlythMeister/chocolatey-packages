import-module au

$releases = "https://support.perimeter81.com/docs/windows-agent-release-notes"
$downloadBase = "https://static.perimeter81.com/agents/windows"
$versionPattern = [regex]"Windows agent\s+(\d+\.\d+\.\d+\.\d+)"
$webHeaders = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AuScript' }

function global:au_SearchReplace {
  @{
    ".\tools\chocolateyInstall.ps1" = @{
      "(?i)(^\s*fileType\s*=\s*)('.*')"       = "`$1'$($Latest.FileType)'"
      "(?i)(^\s*url\s*=\s*)('.*')"            = "`$1'$($Latest.URL32)'"
      "(?i)(^\s*checksum\s*=\s*)('.*')"       = "`$1'$($Latest.Checksum32)'"
      "(?i)(^\s*checksumType\s*=\s*)('.*')"   = "`$1'$($Latest.ChecksumType32)'"
    }
  }
}

function global:au_BeforeUpdate {
  $Latest.ChecksumType32 = 'sha256'
  $Latest.Checksum32 = Get-RemoteChecksum -Algorithm $Latest.ChecksumType32 -Url $Latest.URL32
}

function Get-WindowsAgentVersion {
  param(
    [string]$Content
  )

  $match = $versionPattern.Match($Content)
  if (-not $match.Success) {
    throw "Unable to find 'Windows agent <version>' text on $releases"
  }

  return Get-Version $match.Groups[1].Value
}

function global:au_GetLatest {
  $download_page = Invoke-WebRequest -Uri $releases -Headers $webHeaders

  $version = Get-WindowsAgentVersion -Content $download_page.Content
  $downloadUrl = "$( $downloadBase )/Harmony_SASE_$( $version ).msi"

  return @{
    URL32 = $downloadUrl
    Version = $version
    FileType = "msi"
  }
}

update -ChecksumFor none

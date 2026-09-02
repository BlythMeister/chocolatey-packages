import-module au

$releases = "https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/SASE-Admin-Guide/SASE_Security/Topics/windows/windows_agent_release_notes.htmlm"
$versionPattern = [regex]"\d+\.\d+\.\d+\.\d+"
$webHeaders = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AuScript' }

function global:au_SearchReplace {
  @{}
}

function Get-WindowsAgentVersion {
  param(
    [string]$Content
  )

  $match = $versionPattern.Match($Content)
  if (-not $match.Success) {
    throw "Unable to find version text on $releases"
  }

  return Get-Version $match.Value
}

function global:au_GetLatest {
  $download_page = Invoke-WebRequest -Uri $releases -Headers $webHeaders

  $version = Get-WindowsAgentVersion -Content $download_page.Content

  return @{
    Version = $version
  }
}

update -ChecksumFor none
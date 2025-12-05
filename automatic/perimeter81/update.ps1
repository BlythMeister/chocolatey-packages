import-module au

$releases = "https://support.perimeter81.com/docs/windows-agent-release-notes"

function global:au_GetLatest {
  $download_page = Invoke-WebRequest $releases
  $latest = $download_page.AllElements | Where-Object innerText -match "^Windows agent (\d+\.\d+\.\d+\.\d+).*$" | Select-Object -First 1
  $version = Get-Version $Matches[1]

  return @{
    Version = $version
  }
}

update -ChecksumFor none

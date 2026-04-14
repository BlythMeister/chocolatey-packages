$ErrorActionPreference = 'Stop'

function Get-DockerBuildxCliPackageParameters {
    $parameters = @{}

    if (Get-Command Get-PackageParameters -ErrorAction SilentlyContinue) {
        return Get-PackageParameters
    }

    $rawParameters = $env:chocolateyPackageParameters
    if ([string]::IsNullOrWhiteSpace($rawParameters)) {
        return $parameters
    }

    $pattern = '(?:^|\s)/(?<Name>[A-Za-z0-9]+)\s*(?:=|:)\s*(?<Value>"[^"]*"|''[^'']*''|\S+)'
    foreach ($match in [regex]::Matches($rawParameters, $pattern)) {
        $name = $match.Groups['Name'].Value
        $value = $match.Groups['Value'].Value.Trim('"', "'")
        $parameters[$name] = $value
    }

    return $parameters
}

function Get-DockerBuildxCliMetadataPath {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath
    )

    return Join-Path $ToolsPath 'docker-buildx-cli.install.json'
}

function Get-DockerBuildxCliInstallMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath
    )

    $metadataPath = Get-DockerBuildxCliMetadataPath -ToolsPath $ToolsPath
    if (-not (Test-Path $metadataPath)) {
        return $null
    }

    $metadataJson = Get-Content -Path $metadataPath -Raw
    if ([string]::IsNullOrWhiteSpace($metadataJson)) {
        return $null
    }

    return $metadataJson | ConvertFrom-Json
}

function Save-DockerBuildxCliInstallMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath,

        [Parameter(Mandatory)]
        [string]$PluginDirectory
    )

    $metadata = [pscustomobject]@{
        PluginDirectory = $PluginDirectory
    }

    $metadataPath = Get-DockerBuildxCliMetadataPath -ToolsPath $ToolsPath
    $metadata | ConvertTo-Json | Set-Content -Path $metadataPath -Encoding UTF8
}

function Remove-DockerBuildxCliInstallMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath
    )

    $metadataPath = Get-DockerBuildxCliMetadataPath -ToolsPath $ToolsPath
    if (Test-Path $metadataPath) {
        Remove-Item -Path $metadataPath -Force
    }
}

function Get-DockerBuildxCliPluginDirectory {
    param(
        [Parameter(Mandatory)]
        [hashtable]$PackageParameters,

        [Parameter(Mandatory)]
        [string]$ToolsPath,

        [switch]$AllowMetadataFallback
    )

    $pluginDirectory = $null

    if ($PackageParameters.ContainsKey('PluginDirectory')) {
        $pluginDirectory = [Environment]::ExpandEnvironmentVariables([string]$PackageParameters['PluginDirectory'])
    }
    elseif ($AllowMetadataFallback.IsPresent) {
        $metadata = Get-DockerBuildxCliInstallMetadata -ToolsPath $ToolsPath
        if ($null -ne $metadata -and -not [string]::IsNullOrWhiteSpace([string]$metadata.PluginDirectory)) {
            $pluginDirectory = [string]$metadata.PluginDirectory
        }
    }

    if ([string]::IsNullOrWhiteSpace($pluginDirectory)) {
        $pluginDirectory = Join-Path $env:ProgramFiles 'Docker\cli-plugins'
    }

    return [System.IO.Path]::GetFullPath($pluginDirectory)
}

function Get-DockerBuildxCliStandardPluginDirectories {
    $standardDirectories = @()

    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $standardDirectories += Join-Path $env:USERPROFILE '.docker\cli-plugins'
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramData)) {
        $standardDirectories += Join-Path $env:ProgramData 'Docker\cli-plugins'
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $standardDirectories += Join-Path $env:ProgramFiles 'Docker\cli-plugins'
    }

    return $standardDirectories |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { [System.IO.Path]::GetFullPath($_) } |
        Select-Object -Unique
}

function Test-DockerBuildxCliStandardPluginDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$PluginDirectory
    )

    $normalisedPluginDirectory = [System.IO.Path]::GetFullPath($PluginDirectory)
    return $normalisedPluginDirectory -in (Get-DockerBuildxCliStandardPluginDirectories)
}

function Write-DockerBuildxCliPluginDirectoryWarning {
    param(
        [Parameter(Mandatory)]
        [string]$PluginDirectory
    )

    if (Test-DockerBuildxCliStandardPluginDirectory -PluginDirectory $PluginDirectory) {
        return
    }

    $normalisedPluginDirectory = [System.IO.Path]::GetFullPath($PluginDirectory)
    Write-Warning "The plugin directory '$normalisedPluginDirectory' is not one of Docker's standard Windows CLI plugin directories. Docker will only discover the plugin automatically if that directory is configured separately in the Docker CLI settings."
}

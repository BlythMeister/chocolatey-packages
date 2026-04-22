$ErrorActionPreference = 'Stop'

function Get-DockerScoutCliPackageParameters {
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

function Get-DockerScoutCliMetadataPath {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath
    )

    return Join-Path $ToolsPath 'docker-scout-cli.install.json'
}

function Get-DockerScoutCliInstallMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath
    )

    $metadataPath = Get-DockerScoutCliMetadataPath -ToolsPath $ToolsPath
    if (-not (Test-Path $metadataPath)) {
        return $null
    }

    $metadataJson = Get-Content -Path $metadataPath -Raw
    if ([string]::IsNullOrWhiteSpace($metadataJson)) {
        return $null
    }

    return $metadataJson | ConvertFrom-Json
}

function Save-DockerScoutCliInstallMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath,

        [Parameter(Mandatory)]
        [string]$PluginDirectory,

        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [bool]$AddedCliPluginsExtraDir
    )

    $metadata = [pscustomobject]@{
        PluginDirectory         = $PluginDirectory
        ConfigPath              = $ConfigPath
        AddedCliPluginsExtraDir = $AddedCliPluginsExtraDir
    }

    $metadataPath = Get-DockerScoutCliMetadataPath -ToolsPath $ToolsPath
    $metadata | ConvertTo-Json | Set-Content -Path $metadataPath -Encoding UTF8
}

function Remove-DockerScoutCliInstallMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ToolsPath
    )

    $metadataPath = Get-DockerScoutCliMetadataPath -ToolsPath $ToolsPath
    if (Test-Path $metadataPath) {
        Remove-Item -Path $metadataPath -Force
    }
}

function Get-DockerScoutCliPluginDirectory {
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
        $metadata = Get-DockerScoutCliInstallMetadata -ToolsPath $ToolsPath
        if ($null -ne $metadata -and -not [string]::IsNullOrWhiteSpace([string]$metadata.PluginDirectory)) {
            $pluginDirectory = [string]$metadata.PluginDirectory
        }
    }

    if ([string]::IsNullOrWhiteSpace($pluginDirectory)) {
        $pluginDirectory = Join-Path $env:USERPROFILE '.docker\scout'
    }

    return [System.IO.Path]::GetFullPath($pluginDirectory)
}

function Get-DockerScoutCliConfigPath {
    $configDirectory = Join-Path $env:USERPROFILE '.docker'
    return Join-Path $configDirectory 'config.json'
}

function Test-DockerScoutCliUsesCliPluginsExtraDir {
    param(
        [Parameter(Mandatory)]
        [string]$PluginDirectory
    )

    $normalisedPluginDirectory = [System.IO.Path]::GetFullPath($PluginDirectory)
    $standardPluginDirectories = @(
        [System.IO.Path]::GetFullPath('C:\ProgramData\Docker\cli-plugins'),
        [System.IO.Path]::GetFullPath('C:\Program Files\Docker\cli-plugins')
    )

    return $normalisedPluginDirectory -notin $standardPluginDirectories
}

function Add-DockerScoutCliPluginDirectoryToDockerConfig {
    param(
        [Parameter(Mandatory)]
        [string]$PluginDirectory
    )

    $normalisedPluginDirectory = [System.IO.Path]::GetFullPath($PluginDirectory)
    if (-not (Test-DockerScoutCliUsesCliPluginsExtraDir -PluginDirectory $normalisedPluginDirectory)) {
        return $false
    }

    $configPath = Get-DockerScoutCliConfigPath
    $configDirectory = Split-Path -Parent $configPath
    New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null

    $config = [pscustomobject]@{}
    if (Test-Path $configPath) {
        $configJson = Get-Content -Path $configPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($configJson)) {
            $config = $configJson | ConvertFrom-Json
        }
    }

    $existingPluginDirectories = @()
    if ($null -ne $config.PSObject.Properties['cliPluginsExtraDirs']) {
        $existingPluginDirectories = @($config.cliPluginsExtraDirs | ForEach-Object { [string]$_ })
    }

    if ($normalisedPluginDirectory -in $existingPluginDirectories) {
        return $false
    }

    $updatedPluginDirectories = @($existingPluginDirectories + $normalisedPluginDirectory)
    if ($null -ne $config.PSObject.Properties['cliPluginsExtraDirs']) {
        $config.cliPluginsExtraDirs = $updatedPluginDirectories
    }
    else {
        $config | Add-Member -NotePropertyName 'cliPluginsExtraDirs' -NotePropertyValue $updatedPluginDirectories
    }

    $config | ConvertTo-Json -Depth 20 | Set-Content -Path $configPath -Encoding UTF8
    return $true
}

function Remove-DockerScoutCliPluginDirectoryFromDockerConfig {
    param(
        [Parameter(Mandatory)]
        [string]$PluginDirectory,

        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        return
    }

    $configJson = Get-Content -Path $ConfigPath -Raw
    if ([string]::IsNullOrWhiteSpace($configJson)) {
        return
    }

    $config = $configJson | ConvertFrom-Json
    if ($null -eq $config.PSObject.Properties['cliPluginsExtraDirs']) {
        return
    }

    $normalisedPluginDirectory = [System.IO.Path]::GetFullPath($PluginDirectory)
    $remainingPluginDirectories = @(
        $config.cliPluginsExtraDirs |
            ForEach-Object { [string]$_ } |
            Where-Object { $_ -ne $normalisedPluginDirectory }
    )

    if ($remainingPluginDirectories.Count -eq @($config.cliPluginsExtraDirs).Count) {
        return
    }

    if ($remainingPluginDirectories.Count -eq 0) {
        $config.PSObject.Properties.Remove('cliPluginsExtraDirs')
    }
    else {
        $config.cliPluginsExtraDirs = $remainingPluginDirectories
    }

    $config | ConvertTo-Json -Depth 20 | Set-Content -Path $ConfigPath -Encoding UTF8
}

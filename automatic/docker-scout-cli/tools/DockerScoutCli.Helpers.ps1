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
        [string]$UserProfilePath
    )

    $metadata = [pscustomobject]@{
        UserProfilePath = $UserProfilePath
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

function Get-DockerScoutCliUserProfilePath {
    param(
        [Parameter(Mandatory)]
        [hashtable]$PackageParameters,

        [Parameter(Mandatory)]
        [string]$ToolsPath,

        [switch]$AllowMetadataFallback
    )

    $userProfilePath = $null

    if ($PackageParameters.ContainsKey('UserProfilePath')) {
        $userProfilePath = [Environment]::ExpandEnvironmentVariables([string]$PackageParameters['UserProfilePath'])
    }
    elseif ($PackageParameters.ContainsKey('UserProfileName')) {
        $userProfileRoot = if ($PackageParameters.ContainsKey('UserProfileRoot')) {
            [Environment]::ExpandEnvironmentVariables([string]$PackageParameters['UserProfileRoot'])
        }
        else {
            Join-Path $env:SystemDrive 'Users'
        }

        $userProfilePath = Join-Path $userProfileRoot [string]$PackageParameters['UserProfileName']
    }
    elseif ($AllowMetadataFallback.IsPresent) {
        $metadata = Get-DockerScoutCliInstallMetadata -ToolsPath $ToolsPath
        if ($null -ne $metadata -and -not [string]::IsNullOrWhiteSpace([string]$metadata.UserProfilePath)) {
            $userProfilePath = [string]$metadata.UserProfilePath
        }
    }

    if ([string]::IsNullOrWhiteSpace($userProfilePath)) {
        throw "Package parameters must include /UserProfileName=<name> or /UserProfilePath=<path>."
    }

    $fullUserProfilePath = [System.IO.Path]::GetFullPath($userProfilePath)
    if (-not (Test-Path $fullUserProfilePath)) {
        throw "The target user profile path '$fullUserProfilePath' does not exist."
    }

    return $fullUserProfilePath
}

function Get-DockerScoutCliPluginDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$UserProfilePath
    )

    return Join-Path (Join-Path $UserProfilePath '.docker') 'scout'
}

function Get-DockerScoutCliConfigPath {
    param(
        [Parameter(Mandatory)]
        [string]$UserProfilePath
    )

    return Join-Path (Join-Path $UserProfilePath '.docker') 'config.json'
}

function Get-DockerScoutCliConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        return [pscustomobject]@{}
    }

    $configJson = Get-Content -Path $ConfigPath -Raw
    if ([string]::IsNullOrWhiteSpace($configJson)) {
        return [pscustomobject]@{}
    }

    return $configJson | ConvertFrom-Json
}

function Save-DockerScoutCliConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [psobject]$Configuration
    )

    $dockerDirectory = Split-Path -Path $ConfigPath -Parent
    New-Item -ItemType Directory -Path $dockerDirectory -Force | Out-Null

    $Configuration | ConvertTo-Json -Depth 20 | Set-Content -Path $ConfigPath -Encoding UTF8
}

function Get-DockerScoutCliPluginDirectories {
    param(
        [Parameter(Mandatory)]
        [psobject]$Configuration
    )

    $property = $Configuration.PSObject.Properties['cliPluginsExtraDirs']
    if ($null -eq $property -or $null -eq $Configuration.cliPluginsExtraDirs) {
        return @()
    }

    return @($Configuration.cliPluginsExtraDirs)
}

function Set-DockerScoutCliPluginDirectories {
    param(
        [Parameter(Mandatory)]
        [psobject]$Configuration,

        [string[]]$PluginDirectories
    )

    if ($null -eq $PluginDirectories) {
        $PluginDirectories = @()
    }

    $property = $Configuration.PSObject.Properties['cliPluginsExtraDirs']
    if ($PluginDirectories.Count -eq 0) {
        if ($null -ne $property) {
            $Configuration.PSObject.Properties.Remove('cliPluginsExtraDirs')
        }

        return
    }

    if ($null -eq $property) {
        $Configuration | Add-Member -NotePropertyName 'cliPluginsExtraDirs' -NotePropertyValue $PluginDirectories
        return
    }

    $Configuration.cliPluginsExtraDirs = $PluginDirectories
}

function Add-DockerScoutCliPluginDirectoryToConfig {
    param(
        [Parameter(Mandatory)]
        [string]$UserProfilePath
    )

    $pluginDirectory = Get-DockerScoutCliPluginDirectory -UserProfilePath $UserProfilePath
    $configPath = Get-DockerScoutCliConfigPath -UserProfilePath $UserProfilePath
    $configuration = Get-DockerScoutCliConfiguration -ConfigPath $configPath
    $pluginDirectories = Get-DockerScoutCliPluginDirectories -Configuration $configuration

    if ($pluginDirectories -notcontains $pluginDirectory) {
        $pluginDirectories = @($pluginDirectories + $pluginDirectory)
    }

    Set-DockerScoutCliPluginDirectories -Configuration $configuration -PluginDirectories $pluginDirectories
    Save-DockerScoutCliConfiguration -ConfigPath $configPath -Configuration $configuration
}

function Remove-DockerScoutCliPluginDirectoryFromConfig {
    param(
        [Parameter(Mandatory)]
        [string]$UserProfilePath
    )

    $configPath = Get-DockerScoutCliConfigPath -UserProfilePath $UserProfilePath
    if (-not (Test-Path $configPath)) {
        return
    }

    $pluginDirectory = Get-DockerScoutCliPluginDirectory -UserProfilePath $UserProfilePath
    $configuration = Get-DockerScoutCliConfiguration -ConfigPath $configPath
    $pluginDirectories = @(Get-DockerScoutCliPluginDirectories -Configuration $configuration | Where-Object { $_ -ne $pluginDirectory })

    Set-DockerScoutCliPluginDirectories -Configuration $configuration -PluginDirectories $pluginDirectories
    Save-DockerScoutCliConfiguration -ConfigPath $configPath -Configuration $configuration
}

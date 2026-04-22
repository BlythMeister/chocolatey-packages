# [docker-scout-cli](https://github.com/docker/scout-cli)

Chocolatey package for the official Docker Scout CLI plugin on Windows.

This package installs `docker-scout.exe` using Docker's documented manual installation layout for Windows.

## Parameters

Optional:

- `/PluginDirectory=<absolute-path>` to override the default Docker Scout plugin directory

## Examples

Install to the default documented plugin directory:

```powershell
choco install docker-scout-cli
```

Install to an explicit plugin directory:

```powershell
choco install docker-scout-cli --params "'/PluginDirectory:D:\Docker\cli-plugins'"
```

## Installed layout

The package creates:

- `%USERPROFILE%\.docker\scout\docker-scout.exe` by default
- `%USERPROFILE%\.docker\config.json` updated with `cliPluginsExtraDirs` when installing outside `C:\ProgramData\Docker\cli-plugins` or `C:\Program Files\Docker\cli-plugins`

## Notes

- Windows x64 only
- Docker CLI must already be installed and available separately
- The default install location and Docker config update match Docker Scout's Windows installation guide

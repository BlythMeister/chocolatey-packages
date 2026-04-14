# [docker-buildx-cli](https://github.com/docker/buildx)

Chocolatey package for the official Docker Buildx CLI plugin on Windows.

This package installs `docker-buildx.exe` into Docker's machine-wide CLI plugin directory so the plugin is available for all users on the machine.

## Parameters

Optional:

- `/PluginDirectory=<absolute-path>` to override the default machine-wide Docker CLI plugin directory

## Examples

Install to the default machine-wide plugin directory:

```powershell
choco install docker-buildx-cli
```

Install to an explicit plugin directory:

```powershell
choco install docker-buildx-cli --params "'/PluginDirectory:D:\Docker\cli-plugins'"
```

## Installed layout

The package creates:

- `C:\ProgramData\Docker\cli-plugins\docker-buildx.exe` by default

## Notes

- Windows x64 only
- Docker CLI is a dependency
- The default install location is Docker's machine-wide CLI plugin directory

# [docker-buildx-cli](https://github.com/docker/buildx)

Chocolatey package for the official Docker Buildx CLI plugin on Windows.

This package installs `docker-buildx.exe` into Docker's user-scoped CLI plugin directory so the plugin is available to the installing user.

## Parameters

Optional:

- `/PluginDirectory=<absolute-path>` to override the default Docker CLI plugin directory

## Examples

Install to the default user-scoped plugin directory:

```powershell
choco install docker-buildx-cli
```

Install to an explicit plugin directory:

```powershell
choco install docker-buildx-cli --params "'/PluginDirectory:D:\Docker\cli-plugins'"
```

## Installed layout

The package creates:

- `%USERPROFILE%\.docker\cli-plugins\docker-buildx.exe` by default

## Notes

- Windows x64 only
- Docker CLI must already be installed and available separately
- The default install location matches Docker's documented manual installation path for Windows

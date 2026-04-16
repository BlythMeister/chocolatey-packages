# [docker-buildx-cli](https://github.com/docker/buildx)

Chocolatey package for the official Docker Buildx CLI plugin on Windows.

This package installs `docker-buildx.exe` into Docker's user-scoped CLI plugin directory so the plugin is available to the installing user.

## Parameters

Optional:

- `/PluginDirectory=<absolute-path>` to override the default Docker CLI plugin directory
- `/SetAsDefaultBuilder` to run `docker buildx install` after installation and make Buildx the default builder

## Examples

Install to the default user-scoped plugin directory:

```powershell
choco install docker-buildx-cli
```

Install and register Buildx as the default builder:

```powershell
choco install docker-buildx-cli --params "'/SetAsDefaultBuilder'"
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
- `/SetAsDefaultBuilder` is opt-in and defaults to off, so the package remains validation-safe unless you explicitly request the Docker registration step

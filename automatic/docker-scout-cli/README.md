# [docker-scout-cli](https://github.com/docker/scout-cli)

Chocolatey package for the official Docker Scout CLI plugin on Windows.

This package installs `docker-scout.exe` into a specific user profile and updates that profile's Docker CLI configuration exactly as described in the Docker Scout manual installation guidance.

## Parameters

You must provide one of:

- `/UserProfileName=<name>`
- `/UserProfilePath=<absolute-path>`

Optional:

- `/UserProfileRoot=<path>` when using `UserProfileName` and the profile root is not the default `C:\Users`

## Examples

Install for a standard profile name:

```powershell
choco install docker-scout-cli --params "'/UserProfileName:buildsvc'"
```

Install for an explicit profile path:

```powershell
choco install docker-scout-cli --params "'/UserProfilePath:C:\Users\buildsvc'"
```

Install for a non-standard profile root:

```powershell
choco install docker-scout-cli --params "'/UserProfileName:svc-docker /UserProfileRoot:D:\Profiles'"
```

## Installed layout

The package creates:

- `<UserProfile>\.docker\scout\docker-scout.exe`
- `<UserProfile>\.docker\config.json` with `cliPluginsExtraDirs` including `<UserProfile>\.docker\scout`

## Notes

- Windows x64 only
- Docker CLI must already be installed and available separately
- The target user profile should already exist before installation

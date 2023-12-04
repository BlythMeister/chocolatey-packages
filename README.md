# Chocolatey Packages

[![](https://ci.appveyor.com/api/projects/status/github/BlythMeister/chocolatey-packages?svg=true)](https://ci.appveyor.com/project/BlythMeister/chocolatey-packages)
[Update status](https://gist.github.com/BlythMeister/6bd6850e60497d41df07cf651eade984)
[Test status](https://gist.github.com/BlythMeister/df45fe552c0f30fe48333e75037502eb)

### Folder Structure

* automatic - where automatic packaging and packages are kept. These are packages that are automatically maintained using [AU](https://chocolatey.org/packages/au).
* icons - Where you keep icon files for the packages. This is done to reduce issues when packages themselves move around.
* manual - where packages that are not automatic are kept.
* unreleased - where packages that should not be published yet are kept
* deprecated - where deprecated packages are kept

For setting up your own automatic package repository, please see [Automatic Packaging](https://chocolatey.org/docs/automatic-packages)
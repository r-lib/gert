# gert

> Simple Git Client for R

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/r-lib/gert.svg?branch=master)](https://travis-ci.org/r-lib/gert)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/r-lib/gert?branch=master)](https://ci.appveyor.com/project/jeroen/gert)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/gert)](https://cran.r-project.org/package=gert)

Simple git client based on 'libgit2' with user-friendly authentication
and support for both SSH and HTTPS remotes on all platforms. User credentials
are shared with command line 'git' through the git-credential store and ssh keys
stored on disk or ssh-agent. On Linux, a somewhat recent  version of 'libgit2' is
required.

Gert is still in early development with limited documentation. Have a look at the [slides](https://jeroen.github.io/gert2019/#1).

## Installation

Get the latest version from CRAN:

```r
install.packages("gert")

```

Or install the development version:

``` r
remotes::install_github("r-lib/gert")
```

On Linux you need to install libgit2:

 - Debian: [libgit2-dev](https://packages.debian.org/buster/libgit2-dev)
 - Fedora: [libgit2-devel](https://apps.fedoraproject.org/packages/libgit2-devel)
 
For Ubuntu Trusty and Xenial, you can use libgit2 backports from [this ppa](https://launchpad.net/~cran/+archive/ubuntu/libgit2):

```sh
sudo add-apt-repository ppa:cran/libgit2
sudo apt-get update
sudo apt-get install libgit2-dev
```
 
It is still possible to install the package with older versions of libgit2 (e.g. on CentOS) however these do not support authentication over ssh/https remotes. Offline functionality should work fine.

## Example

This is a basic example:

``` r
library(gert)
path <- file.path(tempdir(), "gert")
repo <- git_clone("https://github.com/r-lib/gert", path)
print(repo)
```


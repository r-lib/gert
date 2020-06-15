# gert

> Simple Git Client for R

<!-- badges: start -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/r-lib/gert.svg?branch=master)](https://travis-ci.org/r-lib/gert)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/r-lib/gert?branch=master)](https://ci.appveyor.com/project/jeroen/gert)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/gert)](https://cran.r-project.org/package=gert)
<!-- badges: end -->

Simple git client for R based on 'libgit2' with support for SSH and 
HTTPS remotes. All functions in gert use basic R data types (such as vectors
and data-frames) for their arguments and return values. User credentials are
shared with command line 'git' through the git-credential store and ssh keys
stored on disk or ssh-agent. On Linux, a somewhat recent version of 'libgit2'
is required; we provide a PPA for older Ubuntu LTS versions.

## Documentation:

 - homepage: https://docs.ropensci.org/gert
 - slides: https://jeroen.github.io/gert2019/#1

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

## Hello world

Some basic commands to get started with gert:

``` r
library(gert)
repo <- git_clone("https://github.com/r-lib/gert")
setwd("gert")

# Show some info
git_log(max = 10)

# Create a branch
git_branch_create("mybranch", checkout = TRUE)

# Commit things
writeLines("Lorem ipsum dolor sit amet", 'test.txt')
git_add('test.txt')
git_commit("Adding a file", author = "jerry <jerry@gmail.com>")
git_log(max = 10)

# Merge it in master
git_branch_checkout("master")
git_merge("mybranch")
git_branch_delete("mybranch")

# Remove the commit
git_reset_hard("HEAD^")
```

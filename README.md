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
 - Fedora / CentOS: [libgit2-devel](https://src.fedoraproject.org/rpms/libgit2)
 
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

## Should I use HTTPS or SSH remotes?

On most platforms, gert supports both HTTPS or SSH remotes. If you don't have any preference, the safest choice is  __HTTPS remotes using a PAT as the password__. This is what I use myself as well. HTTPS remotes have the following benefits:

  - Your credentials are safely stored by your OS, accessible both to gert and command line `git`.
  - Https works on any network. However the ssh protocol requires port 22, which is often blocked on public wifi networks.
  - You can authenticate over https using the same GITHUB_PAT that you use for the GitHub API.
  - libgit2 supports https on all platforms (SSH support depends on libssh2 availability).
  
Again: no need to use your Github master password in gert/git. Instead [generate a personal access token](https://github.com/settings/tokens/new) and enter this as the password when pushing/pulling from https remotes. This works both with gert and with the git command line, even when you have 2FA enabled (which you should).

Ninja tip: use `credentials::set_github_pat()` to automatically set the `GITHUB_PAT` environment variable in your R session using the value stored in your git credential store. This is a safer way to store your PAT than hardcoding it in your `.Rprofile`.

## Differences with `git2r`

Gert is based on [libgit2](https://libgit2.org/), just like the rOpenSci package [git2r](https://docs.ropensci.org/git2r/). Both are good packages. The well established git2r has been on CRAN since 2015, is actively maintained by Stefan Widgren, and is widely used. Gert was started in 2019, and takes a fresh approach based on more recent APIs in libgit2 and lessons learned from using git2r. Some of the main differences:

### Simplicity 

Gert is focused on high-level functions that shield the end-user from the complexity of libgit2. Functions in gert use standard R data types (such as vectors and data-frames) for their arguments and return values, which should be easy to work with for R users/packages. The target repository is either inferred from current working directory or is specified as a filepath. Branches and remotes are referred to by name, much like command line `git`. None of the functions in gert expose any externalptr types to the user.

```
> gert::git_log(max=6)
# A tibble: 6 x 6
  commit                        author                    time                files merge message             
* <chr>                         <chr>                     <dttm>              <int> <lgl> <chr>               
1 6f39ba6dae890d679970c0f8bf03… Jeroen Ooms <jeroenooms@… 2020-06-16 01:16:33    17 FALSE "Add some family ta…
2 c023c407a0f0bfa3955576bc3551… Jeroen Ooms <jeroenooms@… 2020-06-16 01:06:38     1 FALSE "Check for matching…
3 24234060ea8e54c73ddd0bce90ff… Jeroen Ooms <jeroenooms@… 2020-06-15 13:17:57     1 FALSE "Update fedora link…
4 e60b0fbad129f470a2f7065063fa… Jeroen Ooms <jeroenooms@… 2020-06-15 13:05:45     4 FALSE "Tweak docs and rea…
5 629420ddccbab51c1e78f472bf06… Jeroen Ooms <jeroenooms@… 2020-06-15 12:14:25     1 FALSE "More tests\n"      
6 a62ce14eb887e183ad0a3cf0e22c… Jeroen Ooms <jeroenooms@… 2020-06-15 12:06:41     1 FALSE "Fix unit test\n"   
```

For R users who are familiar with the `git` command line, gert should be mostly self-explanatory, and generally "just work".

### Automatic authentication

The overall goal for auth is that gert should successfully discover credentials whenever that would also be true for command line `git`. And, should that fail, there is a way to debug it.

To authenticate with a remote in git2r, you often need to manually pass your credentials in every call to, e.g., `git2r::clone()`. This is always the case for an https remote and is often the case even for an ssh remote. This creates special challenges for those new to `git` or for indirect use of git2r.

In gert, authentication is done automatically using the [credentials](https://docs.ropensci.org/credentials/articles/intro.html) package. This package calls out to the local OS credential store which is also used by the `git` command line. Therefore gert will automatically pick up on https credentials that are safely stored in your OS keychain. 

If no credentials are available from the store, gert will try to authenticate using your `GITHUB_PAT` (if set) for GitHub https remotes. If none of that works, it safely prompts the user for credentials using [askpass](https://github.com/jeroen/askpass#readme). Together, these methods should make https authentication "just work" in any scenario, without having to manually provide passwords in R.

Authentication with ssh remotes is a bit more complicated, but gert will again try to make this as smooth as possible. First of all, gert will tell you if SSH is supported when attaching the package (this will be the case on all modern systems):

```r
> library(gert)
Linking to libgit2 v1.0.0, ssh support: YES
Global config: /Users/jeroen/.gitconfig
Default user: Jeroen Ooms <jeroenooms@gmail.com
```

On Mac/Linux, gert first tries to authenticate using credentials from your `ssh-agent`. If that doesn't work it will look for a suitable ssh key on your system (usually `id_rsa`), and if it is protected with a passphrase, gert will safely prompt the user for the passphrase using [askpass](https://github.com/jeroen/askpass#readme).
If the user does not have an SSH key yet, the [credentials](https://docs.ropensci.org/credentials/articles/intro.html) package makes it easy to set that up.

```r
> library(credentials)
Found git version 2.24.3 (Apple Git-128)
Supported HTTPS credential helpers: cache, store
Found OpenSSH_8.1p1, LibreSSL 2.7.3
Default SSH key: /Users/jeroen/.ssh/id_rsa
```

One limitation that remains is that libgit2 does not support `ssh-agent` on Windows. This is [unlikely to change](https://github.com/libgit2/libgit2/issues/4958) because ssh-agent uses unix-sockets which do not exist in native Windows software.

### The libgit2 dependency

Gert always uses the system version of libgit2, i.e. [libgit2-dev](https://packages.ubuntu.com/focal/libgit2-dev) on Debian/Ubuntu and [libgit2-devel](https://src.fedoraproject.org/rpms/libgit2) on Fedora. On MacOS and Windows the package is statically linked to the [Homebrew](https://github.com/Homebrew/homebrew-core/blob/master/Formula/libgit2.rb) and [rtools40](https://github.com/r-windows/rtools-packages/blob/master/mingw-w64-libgit2/PKGBUILD) build of libgit2. These versions of libgit2 are guaranteed to be properly configured for that operating system, especially when it comes to 3rd party libraries that libgit2 needs to support ssh and TLS (for https).

The git2r package takes another approach by bundling the libgit2 source code in the R package, and automatically building libgit2 on-the-fly when the R package is compiled. This is mostly for historical reasons, because until recently, libgit2 was not available on every Linux system. It also saves the R user from having to install libgit2, e.g. via `apt-get install libgit2-dev`.

However the problem is that configuring and building libgit2 is complicated (like most system libraries) and requires several platform-specific flags and system dependencies. As a result, git2r is sometimes installed with missing functionality, depending on what was detected during compilation. On MacOS for example, some git2r users have SSH support but others do not. Weird problems due to missing libgit2 features turn out to be very persistent, and have caused a lot of frustration. For this reason, gert does not bundle libgit2, and always uses the libgit2 provided by the OS, so that we know exactly what we're getting.

One disadvantage of this approach is that on very old versions of Ubuntu, the system-provided version of libgit2 is out of date, and we need to enable a PPA with more recent libgit2 backports. This is the case for Ubuntu Xenial (16.04) which is a system from 2016 that will be EOL in April 2021.

```sh
# Needed on Ubuntu 16.04
sudo add-apt-repository ppa:cran/libgit2
sudo apt-get install libgit2-dev
```

CI users do not need to worry about this, because we automatically enable this PPA on Travis and GitHub Actions. Outside of CI systems, very few people are running Ubuntu 16 anymore, most production servers have updated to Ubuntu 18 or 20 by now, so this is rarely an issue in practice.

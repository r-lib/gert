# gert

> Experimental git client for R based on libgit2

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/jeroen/gert.svg?branch=master)](https://travis-ci.org/jeroen/gert)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/jeroen/gert?branch=master)](https://ci.appveyor.com/project/jeroen/gert)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/gert)](https://cran.r-project.org/package=av)

## Installation

You can install the released version of gert from Github:

``` r
remotes::install_github("jeroen/gert")
```

## Example

This is a basic example:

``` r
library(gert)
path <- file.path(tempdir(), "ggplot2")
repo <- git_clone("https://github.com/hadley/ggplot2", path)
print(repo)
```

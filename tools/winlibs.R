if(!file.exists("../windows/libgit2/include/git2.h")){
  unlink("../windows", recursive = TRUE)
  url <- if(grepl("aarch", R.version$platform)){
    "https://github.com/r-windows/bundles/releases/download/libgit2-1.7.2/libgit2-1.7.2-clang-aarch64.tar.xz"
  } else if(grepl("clang", Sys.getenv('R_COMPILED_BY'))){
    "https://github.com/r-windows/bundles/releases/download/libgit2-1.7.2/libgit2-1.7.2-clang-x86_64.tar.xz"
  } else if(getRversion() >= "4.2") {
    "https://github.com/r-windows/bundles/releases/download/libgit2-1.7.2/libgit2-1.7.2-ucrt-x86_64.tar.xz"
  } else {
    "https://github.com/rwinlib/libgit2/archive/v1.7.1.tar.gz"
  }
  download.file(url, basename(url), quiet = TRUE)
  dir.create("../windows", showWarnings = FALSE)
  untar(basename(url), exdir = "../windows", tar = 'internal')
  unlink(basename(url))
  setwd("../windows")
  file.rename(list.files(), 'libgit2')
}

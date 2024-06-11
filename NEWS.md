# gert 2.0.2

- Workaround for accidental API change in libgit2 1.8.0
- Disable a non-api call in R >= 4.5.0 for now

# gert 2.0.1

- Fix a printf warning for cran

# gert 2.0.0

- Windows: update to libgit2-1.7.1 + libssh-1.11.0 + openssl-3.1.2

# gert 1.9.3

- Add `git_commit_stats()` function
- Add `git_ignore_path_is_ignored()` function
- Fix protect bug in `git_submodule_list()`

# gert 1.9.2

- Replace sprintf with snprintf for CRAN

# gert 1.9.1

- Fix the Wstrict-prototype warnings
- Use special static libgit2 bundle for openssl-3 distros.

# gert 1.9.0

- Add support for the new ED25519 keys when authenticating over SSH

# gert 1.8.0

- The static libgit2 for win/mac/linux are all 1.4.2 with a patched version
  of libssh 1.10.1. This should fix problems with the latest release versions
  of libgit2 and libssh2.
- The patched libssh2 builds should now support RSA-SHA2, which re-enables
  authentication with GitHub using an RSA key.
- On production Linux systems (x64 RHEL/Ubuntu) default to building using the
  static libgit2 because of above reasons. Set `USE_SYSTEM_LIBGIT2=1` to force
  building against a local libgit2 on these platforms.

# gert 1.7.1

- The static libgit2 for linux has been updated to 1.5.0 (this is only used
  on linux systems where no sufficient libgit2 is available).

# gert 1.7.0

- `git_status()` gains parameter pathspec
- `git_ls()` gains paremeter 'ref' and works with bare repositories

# gert 1.6.0

- We recommend at least libgit2 1.0 now
- Windows: update to libgit2 1.4.2
- Tests: switch to ECDSA keys for ssh remote unit tests
- `git_log()` gains a parameter 'after'

# gert 1.5.0

- Windows: use ${HOMEDRIVE}${HOMEPATH} path as home if it exists, to match
  git-for-windows. On most systems this is the same as ${USERPROFILE}.
- `git_commit_info()` no longer includes $diff by default because it can be huge.
  Please use `git_diff()` instead if you need it.

# gert 1.4.3

- Fix a unit test for some older versions of libgit2

# gert 1.4.2

- Make unit tests more robust against network fail and renamed branches
- Windows / MacOS: update to libgit2 1.3.0

# gert 1.4.1

- Fix compile error with some older version of libgit2
- MacOS: automatically use static libs when building in CI

# gert 1.4.0

- Windows / MacOS: update to libgit2 1.2.0
- New function `git_branch_move()`
- `git_branch_checkout()` gains 'orphan' parameter

# gert 1.3.2

- Fix unit test because GitHub has disabled user/pass auth

# gert 1.3.1

- Windows: fix build for ucrt toolchains
- Solaris: disable https cert verfication

# gert 1.3.0

- Some encoding fixes for latin1 paths, especially non-ascii Windows usernames.

# gert 1.2.0

- New `git_stat_files()` function.

# gert 1.1.0

- On x86_64 Linux systems where libgit2 is too old or unavailable, we automatically
  try to download a precompiled static version of libgit2. This includes CentOS 7/8
  as well as Ubuntu 16.04 and 18.04. Therefore the PPA should no longer be needed.
  You can opt-out of this by setting an envvar: USE_SYSTEM_LIBGIT2=1
- Add tooling to manually find and set the location of the system SSL certificates
  on such static builds, and also for Solaris.
- Add several functions to work with submodules.
- Globally enable submodule-caching for faster diffing.
- Refactor internal code to please rchk analysis tool.

# gert 1.0.2

- `git_branch_list()` gains a parameter 'local'
- Windows / MacOS: update to libgit2 1.1.0
- Do not use bash in configure

# gert 1.0.1

- `git_branch_list()` and `git_commit_info()`  gain a date field
- Bug fixes

# gert 1.0

- Lots of new functions
- Windows and MacOS now ship with libgit2-1.0.0
- Do not advertise HTTPS support in startup message because it should
  always be supported.
- Config setters return previous value invisibly (#37)
- Conflicted files are reported by `git_status()` (#40)
- Windows: libgit2 now finds ~/.gitconfig under $USERPROFILE (instead of Documents)
- A git_signature object is now stored as a string instead of an externalptr
- The 'name' parameter in git_remote_ functions has been renamed to 'remote'

# gert 0.3

- Support for clone --mirror and push --mirror (#12)

# gert 0.2

- `git_open()` now searches parent directories for .git repository
- `git_push()` sets upstream if unset
- workaround for ASAN problem in libssh2
- lots of tweaks and bug fixes

# gert 0.1

- Initial CRAN release.

# Even for public repos, Github only allows keys that it knows.
test_that("public ssh remotes with random key", {
  skip_if_offline('github.com')  #Also skips on_cran
  remote <- 'git@github.com:jeroen/webp.git'
  target <- file.path(tempdir(), basename(remote))
  repo <- git_clone(remote, path = target, ssh_key = 'ecdsa.key', password = 'testingjerry')
  expect_true(file.exists(file.path(target, 'DESCRIPTION')))
})

isOldWindows <- Sys.info()[["sysname"]] == "Windows" && grepl('Windows Server 2008', osVersion)

# Even for public repos, Github only allows keys that it knows.
test_that("private ssh remotes with key", {
  skip_if_offline('github.com') #Also skips on_cran
  remote <- 'git@github.com:jeroenooms/testprivate.git'

  # Test errors
  expect_error(git_clone(remote, path = tempfile(), ssh_key = 'doesnotexist'), 'load key', class = 'GIT_EAUTH')
  expect_error(git_clone(remote, path = tempfile(), ssh_key = 'pat.bin'), 'load key', class = 'GIT_EAUTH')

  # Also test password as a callback function
  for(keyfile in c("ecdsa.key", "rsa3072.key")){ #skipped: "ed25519.key"
    target <- tempfile()
    repo <- git_clone(remote, path = target, ssh_key = keyfile, password = function(...){ 'testingjerry'})
    expect_true(file.exists(file.path(target, 'hello')))

    # Test ls-remote auth
    git_remote_ls(repo = target, ssh_key = keyfile, password = function(...){ 'testingjerry'})
  }
})

# Access token for dummy account with minimal rights
test_that("HTTP user/pass auth", {
  skip_if_offline('github.com')
  # Disable user PAT
  Sys.unsetenv("GITHUB_PAT")

  # Test with password
  enc <- readBin('pat.bin', raw(), 1e3)
  dec <- openssl::rsa_decrypt(enc, 'key.pem', password = 'testingjerry')
  target2 <- file.path(tempdir(), 'testprivate2')
  repo <- git_clone('https://testingjerry@github.com/jeroenooms/testprivate',
                    path = target2, password = rawToChar(dec))
  expect_true(file.exists(file.path(target2, 'hello')))

  # Test with password in URL
  target3 <- file.path(tempdir(), 'testprivate3')
  repo <- git_clone(sprintf('https://testingjerry:%s@github.com/jeroenooms/testprivate',
                            rawToChar(dec)), path = target3)
  expect_true(file.exists(file.path(target3, 'hello')))


  # This seems to fail on WinBuilder due to some syscall
  if(!isTRUE(isOldWindows)){
    # Test that repo is private
    expect_error(git_clone('https://github.com/jeroenooms/testprivate',
                           password = "bla", path = tempfile()), 'Authentication', class = 'GIT_EAUTH')
  }

  # Test with PAT
  Sys.setenv(GITHUB_PAT = rawToChar(dec))
  on.exit(Sys.unsetenv("GITHUB_PAT"))
  target4 <- file.path(tempdir(), 'testprivate4')
  repo <- git_clone('https://github.com/jeroenooms/testprivate', path = target4)
  expect_true(file.exists(file.path(target4, 'hello')))
  heads <- git_remote_ls(repo = repo)
  expect_is(heads, 'data.frame')
  expect_equal(git_remote_info(repo = repo)$head, "refs/remotes/origin/master")

  # Try with user in URL
  target5 <- file.path(tempdir(), 'testprivate5')
  repo <- git_clone('https://nobody@github.com/jeroenooms/testprivate', path = target5)
  expect_true(file.exists(file.path(target5, 'hello')))
  heads <- git_remote_ls(repo = repo)
  expect_is(heads, 'data.frame')
  expect_equal(git_remote_info(repo = repo)$head, "refs/remotes/origin/master")
})

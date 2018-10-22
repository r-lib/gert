context("SSH")

# Even for public repos, Github only allows keys that it knows.
test_that("public ssh remotes with random key", {
  remote <- 'git@github.com:jeroen/webp.git'
  target <- file.path(tempdir(), basename(remote))
  repo <- git_clone(remote, path = target, ssh_key = 'key.pem', password = 'testingjerry')
  expect_true(file.exists(file.path(target, 'DESCRIPTION')))
})

# Even for public repos, Github only allows keys that it knows.
test_that("private ssh remotes with key", {
  remote <- 'git@github.com:ropensci/testprivate.git'
  target <- file.path(tempdir(), basename(remote))
  repo <- git_clone(remote, path = target, ssh_key = 'key.pem', password = 'testingjerry')
  expect_true(file.exists(file.path(target, 'hello')))
})

# Access token for dummy account with minimal rights
test_that("HTTP user/pass auth", {
  enc <- readBin('pat.bin', raw(), 1e3)
  dec <- openssl::rsa_decrypt(enc, 'key.pem', password = 'testingjerry')
  target <- file.path(tempdir(), 'testprivate2')
  repo <- git_clone('https://testingjerry@github.com/ropensci/testprivate',
                    path = target, password = rawToChar(dec))
  expect_true(file.exists(file.path(target, 'hello')))
})

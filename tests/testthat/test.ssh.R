context("SSH")

# Even for public repos, Github only allows keys that it knows.
test_that("public ssh remotes with random key", {
  remote <- 'git@github.com:jeroen/webp.git'
  target <- file.path(tempdir(), basename(remote))
  repo <- git_clone(remote, path = target, ssh_key = 'key.pem', password = 'testingjerry')
  expect_true(file.exists(file.path(target, 'DESCRIPTION')))
})

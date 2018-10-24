context("cloning from remote")

test_that("cloning repositories works", {
  skip_if_not(git_libgit2_config()$https, "Your libgit2 does not support HTTPS remotes")
  path <- file.path(tempdir(), 'jsonlite')
  repo <- git_clone('https://github.com/jeroen/jsonlite', path = path)
  expect_true(file.exists(file.path(path, 'DESCRIPTION')))
  info <- git_info(repo)
  expect_equal(info$head, "refs/heads/master")
  expect_equal(info$shorthand, "master")
  repo2 <- git_open(path)
  info2 <- git_info(repo2)
  expect_equal(info, info2)
  expect_is(git_ls(repo), 'data.frame')

  # Test remotes
  remotes <- git_remotes(repo)
  expect_equal(remotes$remote, "origin")
  expect_equal(remotes$url, "https://github.com/jeroen/jsonlite")
})


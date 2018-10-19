context("test-clone")

test_that("cloning repositories works", {
  path <- file.path(tempdir(), 'jsonlite')
  repo <- git_clone('https://github.com/jeroen/jsonlite', path = path)
  expect_true(file.exists(path))
  info <- git_repository_info(repo)
  expect_equal(info$ref, "refs/heads/master")
  expect_equal(info$shorthand, "master")
  repo2 <- git_open(path)
  info2 <- git_repository_info(repo2)
  expect_equal(info, info2)
  expect_is(git_repository_ls(repo), 'data.frame')
})

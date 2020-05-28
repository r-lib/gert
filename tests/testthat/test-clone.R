test_that("cloning repositories works", {
  skip_if_offline()
  path <- file.path(tempdir(), 'gert')
  repo <- git_clone('https://github.com/r-lib/gert', path = path)
  expect_true(file.exists(file.path(path, 'DESCRIPTION')))
  info <- git_info(repo)
  expect_equal(info$head, "refs/heads/master")
  expect_equal(info$shorthand, "master")
  repo2 <- git_open(path)
  info2 <- git_info(repo2)
  expect_equal(info, info2)
  expect_is(git_ls(repo), 'data.frame')
  expect_is(git_log(repo = repo), 'data.frame')

  # Test remotes
  remotes <- git_remote_list(repo)
  expect_equal(remotes$name, "origin")
  expect_equal(remotes$url, "https://github.com/r-lib/gert")
})

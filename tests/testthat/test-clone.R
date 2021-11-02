test_that("cloning repositories works", {
  skip_if_offline()
  path <- file.path(tempdir(), 'gert')
  repo <- git_clone('https://github.com/r-lib/gert', path = path)
  expect_true(file.exists(file.path(path, 'DESCRIPTION')))
  info <- git_info(repo)
  default_head <- git_remote_ls('https://github.com/r-lib/gert')$symref[1]
  default_branch <- basename(default_head)
  expect_equal(info$head, default_head)
  expect_equal(info$shorthand, default_branch)
  repo2 <- git_open(path)
  info2 <- git_info(repo2)
  expect_equal(info, info2)
  expect_is(git_ls(repo), 'data.frame')
  expect_is(git_log(repo = repo), 'data.frame')
  heads <- git_remote_ls(repo = repo)
  expect_is(heads, 'data.frame')
  expect_equal(git_remote_info(repo = repo)$head, paste0("refs/remotes/origin/", default_branch))

  # Test remotes
  remotes <- git_remote_list(repo)
  expect_equal(remotes$name, "origin")
  expect_equal(remotes$url, "https://github.com/r-lib/gert")

  # Test archive
  expect_equal(git_archive_zip(repo = repo), 'gert.zip')
  expect_equal(zip::zip_list('gert.zip')$filename, git_ls(repo=repo)$path)
  unlink('gert.zip')
})

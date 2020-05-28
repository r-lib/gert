test_that("can opt out of recursive search", {
  repo <- git_init(tempfile("gert-tests-open"))
  on.exit(unlink(repo, recursive = TRUE))

  grandchild <- file.path(repo, "aaa", "bbb")
  dir.create(grandchild, recursive = TRUE)
  expect_error(git_open(I(grandchild)), "libgit2 error in git_repository_open")
})

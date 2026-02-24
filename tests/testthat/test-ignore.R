test_that("can check that files are ignored", {
  repo <- git_init(tempfile("gert-tests-open"))
  writeLines(
    c(
      "*.so",
      "!foo.so",
      "some-file",
      "directory/"
    ),
    file.path(repo, ".gitignore")
  )
  expect_true(git_ignore_path_is_ignored("x.so", repo))
  expect_false(git_ignore_path_is_ignored("foo.so", repo))
  expect_true(git_ignore_path_is_ignored("some-file", repo))
  expect_false(git_ignore_path_is_ignored("some-file.txt", repo))
  expect_true(git_ignore_path_is_ignored("directory/a", repo))
  expect_equal(
    git_ignore_path_is_ignored(c("x.so", "foo.so"), repo),
    c(TRUE, FALSE)
  )
  expect_equal(git_ignore_path_is_ignored(character(), repo), logical())
})

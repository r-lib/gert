test_that("git_restore restores a modified file from HEAD", {
  repo <- git_init(tempfile("gert-tests-restore"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  writeLines("original", file.path(repo, "hello.txt"))
  git_add("hello.txt", repo = repo)
  git_commit("First commit", repo = repo)

  writeLines("modified", file.path(repo, "hello.txt"))
  expect_equal(readLines(file.path(repo, "hello.txt")), "modified")

  git_restore("hello.txt", repo = repo)
  expect_equal(readLines(file.path(repo, "hello.txt")), "original")
})

test_that("git_restore restores from a specific ref", {
  repo <- git_init(tempfile("gert-tests-restore-ref"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  writeLines("v1", file.path(repo, "hello.txt"))
  writeLines("v1", file.path(repo, "keep.txt"))

  git_add(c("hello.txt", "keep.txt"), repo = repo)
  first <- git_commit("First commit", repo = repo)

  writeLines("v2", file.path(repo, "hello.txt"))
  writeLines("v2", file.path(repo, "keep.txt"))
  git_add(c("hello.txt", "keep.txt"), repo = repo)
  git_commit("Second commit", repo = repo)

  git_restore("hello.txt", ref = first, repo = repo)
  expect_equal(readLines(file.path(repo, "hello.txt")), "v1")
  expect_equal(readLines(file.path(repo, "keep.txt")), "v2")
})

test_that("git_restore restores all files with path = '.'", {
  repo <- git_init(tempfile("gert-tests-restore-dot"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  writeLines("original a", file.path(repo, "a.txt"))
  writeLines("original b", file.path(repo, "b.txt"))
  git_add(c("a.txt", "b.txt"), repo = repo)
  git_commit("First commit", repo = repo)

  writeLines("modified a", file.path(repo, "a.txt"))
  writeLines("modified b", file.path(repo, "b.txt"))

  git_restore(".", repo = repo)
  expect_equal(readLines(file.path(repo, "a.txt")), "original a")
  expect_equal(readLines(file.path(repo, "b.txt")), "original b")
})

test_that("git_restore raises an error for an untracked path", {
  repo <- git_init(tempfile("gert-tests-restore-untracked"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  writeLines("hello", file.path(repo, "hello.txt"))
  git_add("hello.txt", repo = repo)
  git_commit("First commit", repo = repo)

  expect_error(git_restore("nottracked.txt", repo = repo), "not tracked by git")
})

test_that("git_restore raises an error for an invalid ref", {
  repo <- git_init(tempfile("gert-tests-restore-invalid"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  writeLines("hello", file.path(repo, "hello.txt"))
  git_add("hello.txt", repo = repo)
  git_commit("First commit", repo = repo)

  expect_error(git_restore("hello.txt", ref = "notaref", repo = repo), "notaref")
})

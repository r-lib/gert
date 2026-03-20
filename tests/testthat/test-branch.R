test_that("git_branch_create force applies to checkout", {
  repo <- git_init(tempfile("gert-tests-branch-force"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  # First commit: hello.txt = "v1"
  writeLines("v1", file.path(repo, "hello.txt"))
  git_add("hello.txt", repo = repo)
  first <- git_commit("First commit", repo = repo)

  # Second commit: hello.txt = "v2"
  writeLines("v2", file.path(repo, "hello.txt"))
  git_add("hello.txt", repo = repo)
  git_commit("Second commit", repo = repo)

  # Unstaged local change: hello.txt = "v3"
  writeLines("v3", file.path(repo, "hello.txt"))

  # force = FALSE: checkout to first commit conflicts with local change
  expect_error(
    git_branch_create("oldbranch", ref = first, checkout = TRUE, force = FALSE, repo = repo)
  )

  # force = TRUE: checkout succeeds, overwriting local change
  git_branch_create("oldbranch2", ref = first, checkout = TRUE, force = TRUE, repo = repo)
  expect_equal(git_branch(repo = repo), "oldbranch2")
  expect_equal(readLines(file.path(repo, "hello.txt")), "v1")
})

test_that("`git_worktree_list()`, `git_worktree_exists()`, and `git_worktree_path()` work", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  git_branch_create(branch = "branch", checkout = FALSE, repo = repo)

  git_worktree_add(
    name = "worktree",
    path = tempfile("gert-tests-worktree"),
    branch = "branch",
    repo = repo
  )
  on.exit(
    git_worktree_remove("worktree", repo = repo),
    add = TRUE,
    after = FALSE
  )

  # `git_worktree_list()`
  worktrees <- git_worktree_list(repo = repo)
  expect_identical(worktrees$name, "worktree")
  # Exact path may be normalized by libgit2
  expect_type(worktrees$path, "character")
  expect_identical(worktrees$valid, TRUE)
  expect_identical(worktrees$locked, FALSE)

  # `git_worktree_exists()`
  expect_false(git_worktree_exists("fake", repo = repo))
  expect_true(git_worktree_exists("worktree", repo = repo))

  # `git_worktree_path()`
  # Exact path may be normalized by libgit2
  path <- git_worktree_path("worktree", repo = repo)
  expect_type(path, "character")
  expect_length(path, 1)
})

test_that("`git_worktree_lock()`, `git_worktree_unlock()`, and `git_worktree_is_locked()` work", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  git_branch_create(branch = "branch1", checkout = FALSE, repo = repo)
  git_branch_create(branch = "branch2", checkout = FALSE, repo = repo)

  # Unlocked on creation
  git_worktree_add(
    name = "worktree1",
    path = tempfile("gert-tests-worktree1"),
    branch = "branch1",
    lock = FALSE,
    repo = repo
  )
  on.exit(
    git_worktree_remove("worktree1", repo = repo),
    add = TRUE,
    after = FALSE
  )

  # Locked on creation
  git_worktree_add(
    name = "worktree2",
    path = tempfile("gert-tests-worktree2"),
    branch = "branch2",
    lock = TRUE,
    repo = repo
  )
  on.exit(
    git_worktree_remove("worktree2", repo = repo),
    add = TRUE,
    after = FALSE
  )

  expect_false(git_worktree_is_locked("worktree1", repo = repo))
  git_worktree_lock("worktree1", repo = repo)
  expect_true(git_worktree_is_locked("worktree1", repo = repo))
  git_worktree_unlock("worktree1", repo = repo)
  expect_false(git_worktree_is_locked("worktree1", repo = repo))

  expect_true(git_worktree_is_locked("worktree2", repo = repo))
  git_worktree_unlock("worktree2", repo = repo)
  expect_false(git_worktree_is_locked("worktree2", repo = repo))
  git_worktree_lock("worktree2", repo = repo)
  expect_true(git_worktree_is_locked("worktree2", repo = repo))
})

test_that("`git_worktree_is_valid()` works", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  git_branch_create(branch = "branch", checkout = FALSE, repo = repo)

  path <- tempfile("gert-tests-worktree")

  git_worktree_add(
    name = "worktree",
    path = path,
    branch = "branch",
    repo = repo
  )

  expect_true(git_worktree_is_valid("worktree", repo = repo))

  # Remove the worktree's folder
  unlink(path, recursive = TRUE)
  expect_false(git_worktree_is_valid("worktree", repo = repo))

  # Still exists even though it is invalid
  expect_true(git_worktree_exists("worktree", repo = repo))

  # Now prune it
  expect_true(git_worktree_is_prunable("worktree", repo = repo))
  git_worktree_prune("worktree", repo = repo)
  expect_false(git_worktree_exists("worktree", repo = repo))
})

test_that("`git_worktree_add()` requires that `branch` exist", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  expect_error(
    git_worktree_add(
      name = "worktree",
      path = tempfile("gert-tests-worktree"),
      branch = "branch",
      repo = repo
    ),
    "cannot locate local branch 'branch'"
  )
})

test_that("`git_worktree_add()` can't check out already checked out branch", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  # Check out `branch`
  git_branch_create(branch = "branch", checkout = TRUE, repo = repo)

  expect_error(
    git_worktree_add(
      name = "worktree",
      path = tempfile("gert-tests-worktree"),
      branch = "branch",
      repo = repo
    ),
    "already checked out"
  )
})

test_that("`git_worktree_add()` errors early if `path` already exists", {
  # We error at R level to avoid libgit2 putting us in a corrupt worktree state

  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # `path` exists, but should not!
  path <- tempfile("gert-tests-worktree")
  dir.create(path)

  expect_error(
    git_worktree_add(
      name = "worktree",
      path = path,
      branch = "branch",
      repo = repo
    ),
    "must not exist"
  )
})

test_that("`git_worktree_add()` errors early if `dirname(path)` does not exist", {
  # We error at R level to avoid libgit2 putting us in a corrupt worktree state

  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # `dir` does not exist, but needs to
  dir <- tempfile("gert-tests-worktree-directory")
  path <- tempfile("gert-tests-worktree", tmpdir = dir)

  expect_error(
    git_worktree_add(
      name = "worktree",
      path = path,
      branch = "branch",
      repo = repo
    ),
    "must exist"
  )
})

test_that("`git_worktree_remove()` removes worktree and `path` folder", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  git_branch_create(branch = "branch", checkout = FALSE, repo = repo)

  path <- tempfile("gert-tests-worktree")

  git_worktree_add(
    name = "worktree",
    path = path,
    branch = "branch",
    repo = repo
  )

  expect_true(dir.exists(path))
  expect_true(git_worktree_exists("worktree", repo = repo))

  git_worktree_remove("worktree", repo = repo)

  expect_false(dir.exists(path))
  expect_false(git_worktree_exists("worktree", repo = repo))
})

test_that("`git_worktree_prune()` refuses to remove `valid` worktrees", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  git_branch_create(branch = "branch", checkout = FALSE, repo = repo)

  git_worktree_add(
    name = "worktree",
    path = tempfile("gert-tests-worktree"),
    branch = "branch",
    repo = repo
  )

  # Refuses to prune by default
  expect_false(git_worktree_is_prunable("worktree", repo = repo))
  expect_error(
    git_worktree_prune("worktree", repo = repo),
    "not pruning valid working tree"
  )

  # Can be forced to prune
  expect_no_error(git_worktree_prune(
    "worktree",
    repo = repo,
    prune_valid = TRUE
  ))
})

test_that("`git_worktree_prune()` refuses to remove `locked` worktrees", {
  repo <- git_init(tempfile("gert-tests-repo"))
  on.exit(unlink(repo, recursive = TRUE), add = TRUE, after = FALSE)

  # Need `HEAD`
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  git_branch_create(branch = "branch", checkout = FALSE, repo = repo)

  git_worktree_add(
    name = "worktree",
    path = tempfile("gert-tests-worktree"),
    branch = "branch",
    lock = TRUE,
    repo = repo
  )

  # Refuses to prune by default
  expect_false(git_worktree_is_prunable("worktree", repo = repo))
  expect_error(
    git_worktree_prune("worktree", repo = repo),
    "not pruning locked working tree"
  )

  # Refuses to prune valid worktree by default as well
  expect_error(
    git_worktree_prune("worktree", repo = repo, prune_locked = TRUE),
    "not pruning valid working tree"
  )

  # Can be forced to prune with both options
  expect_no_error(git_worktree_prune(
    "worktree",
    repo = repo,
    prune_valid = TRUE,
    prune_locked = TRUE
  ))
})

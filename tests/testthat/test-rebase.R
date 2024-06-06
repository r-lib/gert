test_that("rebasing things", {
  skip_if_offline('github.com')
  repo <- file.path(tempdir(), 'gert')
  if(!file.exists(repo)) git_clone('https://github.com/r-lib/gert', path = repo)
  git_branch_create('backup', checkout = FALSE, repo = repo)

  # Original log
  orig <- git_log(max = 10, repo = repo)

  # Drop some commits, and fast-forward them back
  git_reset_hard('HEAD~5', repo = repo)
  expect_equal(git_log(max = 5, repo = repo)$commit, utils::tail(orig$commit, 5))
  expect_equal(git_ahead_behind(repo = repo), list(ahead = 0, behind = 5,
    local = git_commit_id(repo = repo), upstream = git_commit_id('origin/HEAD', repo = repo)))
  git_pull(repo = repo)
  expect_equal(orig, git_log(max = 10, repo = repo))

  # Same with rebase
  git_reset_hard('HEAD~5', repo = repo)
  expect_equal(git_log(max = 5, repo = repo)$commit, utils::tail(orig$commit, 5))
  expect_equal(git_ahead_behind(repo = repo), list(ahead = 0, behind = 5,
    local = git_commit_id(repo = repo), upstream = git_commit_id('origin/HEAD', repo = repo)))
  git_pull(rebase = TRUE, repo = repo)
  expect_equal(orig, git_log(max = 10, repo = repo))

  # Now rebase a commit
  git_reset_hard('HEAD~5', repo = repo)
  expect_equal(git_log(max = 5, repo = repo)$commit, utils::tail(orig$commit, 5))
  writeLines("some random change", file.path(repo, 'randomfile.txt'))
  git_add(".", repo = repo)
  commit_id <- git_commit("Added a local change", repo = repo, author = "Jerry <test@jerry.nl>")
  commit_msg <- git_commit_info(commit_id, repo = repo)$message

  # We are 1 ahead and 5 behind
  expect_equal(git_ahead_behind(repo = repo), list(ahead = 1, behind = 5,
    local = git_commit_id(repo = repo), upstream = git_commit_id('origin/HEAD', repo = repo)))

  # Confirm that we cannot fast forward
  upstream <- git_info(repo = repo)$upstream
  expect_error(git_branch_fast_forward(upstream, repo = repo))

  # Pull with rebase
  rebase_info <- git_rebase_list(repo = repo)
  expect_equal(rebase_info$commit, commit_id)
  git_pull(rebase = TRUE, repo = repo)
  newlog <- git_log(max = 11, repo = repo)
  expect_equal(c(commit_msg, orig$message), newlog$message)
  expect_equal(orig$commit, newlog$commit[-1])
  expect_equal(git_ahead_behind(repo = repo), list(ahead = 1, behind = 0,
    local = git_commit_id(repo = repo), upstream = git_commit_id('origin/HEAD', repo = repo)))

  # Check that patch matches
  expect_equal(git_diff(commit_id, repo = repo), git_diff(newlog$commit[1], repo = repo))

  # Merge changes into another branch
  main <- git_info(repo = repo)$shorthand
  git_branch_checkout('backup', repo = repo)
  git_merge(main, repo = repo)
  expect_equal(newlog, git_log(max = 11, repo = repo))

  # Cleanup from master
  git_branch_checkout(main, repo = repo)
  git_reset_hard("HEAD^", repo = repo)
  git_branch_delete('backup', repo = repo)
})

test_that("cherry-picking things", {
  repo <- tempfile()
  gert::git_init(path = repo)
  writeLines("hello", file.path(repo, 'hello.txt'))
  git_add('hello.txt', repo = repo)
  first_commit <- git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)

  # Create a feature branch with a new commit
  mainbranch <- gert::git_branch(repo = repo)
  git_branch_create('feature', repo = repo)
  write.csv(iris, file.path(repo, 'iris.csv'))
  git_add('iris.csv', repo = repo)
  commit <- git_commit("Added iris.csv file", author = "maelle <maelle@salmon.fish>", repo = repo)

  # Cherry pick the commit onto main
  git_branch_checkout(mainbranch, repo = repo)
  expect_equal(gert::git_log(repo=repo)$commit, first_commit)
  short_commit <- substr(commit, 1, 7)
  expect_equal(git_cherry_pick(short_commit, repo = repo), commit)
  expect_length(git_log(repo = repo)$commit, 2)
})

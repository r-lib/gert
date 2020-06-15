test_that("rebasing things", {
  skip_if_offline()
  repo <- file.path(tempdir(), 'gert')
  if(!file.exists(repo)) git_clone('https://github.com/r-lib/gert', path = repo)
  git_branch_create('backup', checkout = FALSE, repo = repo)

  # Original log
  orig <- git_log(max = 10, repo = repo)

  # Drop some commits, and fast-forward them back
  git_reset_hard('HEAD~5', repo = repo)
  expect_equal(git_log(max = 5, repo = repo)$commit, utils::tail(orig$commit, 5))
  git_pull(repo = repo)
  expect_equal(orig, git_log(max = 10, repo = repo))

  # Same with rebase
  git_reset_hard('HEAD~5', repo = repo)
  expect_equal(git_log(max = 5, repo = repo)$commit, utils::tail(orig$commit, 5))
  git_pull(rebase = TRUE, repo = repo)
  expect_equal(orig, git_log(max = 10, repo = repo))

  # Now rebase a commit
  git_reset_hard('HEAD~5', repo = repo)
  expect_equal(git_log(max = 5, repo = repo)$commit, utils::tail(orig$commit, 5))
  writeLines("some random change", file.path(repo, 'randomfile.txt'))
  git_add(".", repo = repo)
  commit_id <- git_commit("Added a local change", repo = repo)
  commit_msg <- git_commit_info(commit_id, repo = repo)$message

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

  # Merge changes into another branch
  git_branch_checkout('backup', repo = repo)
  git_merge("master", repo = repo)
  expect_equal(newlog, git_log(max = 11, repo = repo))

  # Cleanup from master
  git_branch_checkout('master', repo = repo)
  git_reset_hard("HEAD^", repo = repo)
  git_branch_delete('backup', repo = repo)
})

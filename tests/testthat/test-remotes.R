test_that("git_remote_set_pushurl with add = TRUE appends push URLs", {
  repo <- git_init(tempfile("gert-tests-pushurl"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  git_remote_add("https://example.com/fetch", name = "origin", repo = repo)

  git_remote_set_pushurl("https://example.com/push1", remote = "origin", repo = repo)
  git_remote_set_pushurl("https://example.com/push2", remote = "origin", add = TRUE, repo = repo)

  cfg <- git_config(repo = repo)
  pushurls <- cfg$value[cfg$name == "remote.origin.pushurl"]
  expect_setequal(pushurls, c("https://example.com/push1", "https://example.com/push2"))
})

test_that("git_remote_set_pushurl without add replaces push URL", {
  repo <- git_init(tempfile("gert-tests-pushurl-replace"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  git_remote_add("https://example.com/fetch", name = "origin", repo = repo)

  git_remote_set_pushurl("https://example.com/push1", remote = "origin", repo = repo)
  git_remote_set_pushurl("https://example.com/push2", remote = "origin", repo = repo)

  cfg <- git_config(repo = repo)
  pushurls <- cfg$value[cfg$name == "remote.origin.pushurl"]
  expect_equal(pushurls, "https://example.com/push2")
})

test_that("remotes from new repo", {
  skip_if_offline('github.com')
  repo <- git_init(tempfile("gert-tests-remote"))
  on.exit(unlink(repo, recursive = TRUE))
  expect_equal(nrow(git_remote_list(repo = repo)), 0)
  expect_error(git_remote_info(repo = repo))
  expect_error(git_remote_refspecs(repo = repo))
  expect_error(git_remote_set_url('https://github.com/foo/bar', repo = repo))
  expect_error(git_remote_info(repo = repo), "remote 'NA' does not exist")
  expect_error(git_remote_set_pushurl(
    'https://github.com/foo/bar',
    repo = repo
  ))
  expect_error(git_remote_info(repo = repo), "remote 'NA' does not exist")
  expect_equal(
    git_remote_add(
      'https://github.com/jeroen/webp',
      name = 'jeroen',
      repo = repo
    ),
    'jeroen'
  )
  # info should work even when no upstream:
  info <- git_remote_info(repo = repo)
  expect_equal(info$url, "https://github.com/jeroen/webp")
  git_fetch('jeroen', 'master', repo = repo)
  git_branch_create('master', 'jeroen/master', repo = repo)
  git_branch_create(
    'testje',
    git_commit_id('jeroen/master', repo = repo),
    checkout = FALSE,
    repo = repo
  )
  git_remote_set_pushurl('https://github.com/foo/baz', repo = repo)
  info <- git_remote_info(repo = repo)
  expect_equal(info$name, 'jeroen')
  expect_equal(info$url, "https://github.com/jeroen/webp")
  expect_equal(info$push_url, "https://github.com/foo/baz")
  expect_equal(info$fetch, "+refs/heads/*:refs/remotes/jeroen/*")
  branches <- git_branch_list(repo = repo)
  expect_equal(branches$name, c("master", "testje", "jeroen/master"))
  expect_equal(branches$upstream, c("refs/remotes/jeroen/master", NA, NA))
})

test_that("remotes after clone", {
  skip_if_offline('github.com')
  repo <- file.path(tempdir(), 'gert')
  if (!file.exists(repo)) {
    git_clone('https://github.com/r-lib/gert', path = repo)
  }
  info <- git_remote_info(repo = repo)
  expect_equal(info$name, 'origin')
  expect_equal(info$url, "https://github.com/r-lib/gert")
  expect_equal(info$fetch, "+refs/heads/*:refs/remotes/origin/*")
  refspecs <- git_remote_refspecs(repo = repo)
  expect_equal(refspecs$direction, 'fetch')
  remotelist <- git_remote_list(repo = repo)
  expect_equal(remotelist$name, 'origin')
  expect_equal(remotelist$url, 'https://github.com/r-lib/gert')
  expect_error(git_remote_add('https://github.com/jeroen/gert', repo = repo))
  expect_equal(
    git_remote_add(
      'https://github.com/jeroen/gert',
      name = 'myfork',
      repo = repo
    ),
    'myfork'
  )
  remotelist <- git_remote_list(repo = repo)
  expect_equal(sort(remotelist$name), c("myfork", 'origin'))
  expect_equal(
    sort(remotelist$url),
    c("https://github.com/jeroen/gert", 'https://github.com/r-lib/gert')
  )
  expect_equal(
    git_remote_refspecs('myfork', repo = repo)$refspec,
    '+refs/heads/*:refs/remotes/myfork/*'
  )
})

test_that("creating signatures", {
  now <- Sys.time()
  name <- 'Testing Jerry'
  email <- 'test@jerry.com'
  author <- sprintf("%s <%s>", name, email)

  sig <- git_signature(name, email)
  sigdata <- git_signature_parse(sig)
  expect_equal(sigdata$name, name)
  expect_equal(sigdata$email, email)
  expect_lt(difftime(sigdata$time, now, 'secs'), 1)

  yesterday <- now - 24*60*60
  sig <- git_signature(name, email, time = yesterday)
  sigdata <- git_signature_parse(sig)
  expect_equal(sigdata$name, name)
  expect_lt(difftime(sigdata$time, yesterday, 'secs'), 1)
})

test_that("adding and removing files", {
  repo <- git_init(tempfile("gert-tests-commit"))
  on.exit(unlink(repo, recursive = TRUE))

  expect_equal(nrow(git_ls(repo)), 0)
  write.csv(iris, file.path(repo, 'iris.csv'))
  write.csv(cars, file.path(repo, 'cars.csv'))
  git_add(c('cars.csv', 'iris.csv'), repo = repo)
  expect_equal(nrow(git_ls(repo)), 2)
  expect_equal(git_ls(repo)$path, c('cars.csv', 'iris.csv'))
  git_rm(c('cars.csv', 'iris.csv'), repo = repo)
  expect_equal(nrow(git_ls(repo)), 0)
  remotes <- git_remote_list(repo)
  expect_equal(nrow(remotes), 0)
})

test_that("creating a commit", {
  repo <- git_init(tempfile("gert-tests-commit"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  expect_equal(nrow(git_ls(repo)), 0)
  write.csv(cars, file.path(repo, 'cars.csv'))
  git_add('cars.csv', repo = repo)
  git_commit("Added cars.csv file", repo = repo)

  # Another commit before that
  write.csv(iris, file.path(repo, 'iris.csv'))
  git_add("iris.csv", repo = repo)
  timestamp <- round(Sys.time() - 48*60*60)
  sig2 <- git_signature('nobody', 'nobody@gmail.com', time = timestamp)
  git_commit("Added iris.csv also", author = sig2, repo = repo)

  # Inspect the log file
  log <- git_log(repo = repo)
  expect_equal(log$author[2], local_author(repo))
  expect_equal(log$time[1], timestamp)
})

test_that("creating a commit in another directory without author works", {
  path <- tempfile("gert-tests-commit")
  on.exit(unlink(path, recursive = TRUE))

  dir.create(path)
  repo <- git_init(path)
  configure_local_user(repo)
  writeLines("content", file.path(path, "file"))
  git_add("file", repo = path)
  git_commit("Added file", repo = repo)

  log <- git_log(repo = repo)
  expect_equal(log$author, local_author(repo))
})

test_that("status reports a conflicted file", {
  repo <- git_init(tempfile("gert-test-conflicts"))
  on.exit(unlink(repo, recursive = TRUE))
  configure_local_user(repo)

  foo_path <- file.path(repo, "foo.txt")
  bar_path <- file.path(repo, "bar.txt")

  writeLines("cranky-crab-legs", foo_path)
  git_add("foo.txt", repo = repo)
  base <- git_commit("Add a file", repo = repo)

  git_branch_create("my-branch", repo = repo)
  writeLines("cranky-CRAB-LEGS", foo_path)
  git_add("foo.txt", repo = repo)
  git_commit("Uppercase last 2 words", repo = repo)

  git_branch_checkout("master", repo = repo)
  expect_equal(git_merge_analysis("my-branch", repo = repo), "fastforward")

  writeLines("CRANKY-CRAB-legs", foo_path)
  git_add("foo.txt", repo = repo)
  git_commit("Uppercase first 2 words", repo = repo)

  writeLines(c("CRANKY-CRAB-legs", "One more line"), foo_path)
  git_add("foo.txt", repo = repo)
  git_commit("Add another commit", repo = repo)

  writeLines("Nothing special", bar_path)
  git_add("bar.txt", repo = repo)
  git_commit("Non-conflicting commit", repo = repo)

  expect_equal(base, git_merge_find_base("my-branch", repo = repo))
  expect_equal(git_merge_analysis(base, repo = repo), "up_to_date")
  expect_equal(git_merge_analysis('my-branch', repo = repo), "normal")

  # What if we would rebase
  rebase_info <- git_rebase_info("my-branch", repo = repo)
  expect_equal(rebase_info$type, rep("pick", 3))
  expect_equal(rebase_info$commit, rev(head(git_log(repo = repo), -1)$commit))
  expect_equal(rebase_info$conflicts, c(T,T,F))

  # Or rebase onto master
  rebase_info <- git_rebase_info("HEAD", "my-branch", repo = repo)
  expect_equal(rebase_info$type, "pick")
  expect_equal(rebase_info$commit, head(git_log("my-branch", repo = repo), -1)$commit)
  expect_true(rebase_info$conflicts)

  # Merge returns FALSE due to conflicts
  git_merge("my-branch", repo = repo)

  status <- git_status(repo = repo)
  expect_equal(status$file, "foo.txt")
  expect_equal(status$status, "conflicted")
  expect_false(status$staged)

  # Resolve the conflict
  conflicts <- git_conflicts(repo = repo)
  expect_equal(conflicts$our, status$file)
  writeLines("Conflict is resolved", foo_path)
  git_add('foo.txt', repo = repo)
  git_commit("Resolve merge conflict", repo = repo)
  expect_length(git_conflicts(repo = repo)$our, 0)
  expect_length(git_status(repo = repo)$file, 0)
})

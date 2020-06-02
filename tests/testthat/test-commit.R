test_that("creating signatures", {
  now <- Sys.time()
  name <- 'Testing Jerry'
  email <- 'test@jerry.com'
  author <- sprintf("%s <%s>", name, email)

  sig <- git_signature(name, email)
  info <- git_signature_info(sig)
  expect_equal(info$author, author)
  expect_lt(difftime(info$time, now, 'secs'), 1)

  yesterday <- now - 24*60*60
  sig <- git_signature(name, email, time = yesterday)
  info <- git_signature_info(sig)
  expect_equal(info$author, author)
  expect_lt(difftime(info$time, yesterday, 'secs'), 1)
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

  expect_equal(nrow(git_ls(repo)), 0)
  write.csv(cars, file.path(repo, 'cars.csv'))
  git_add('cars.csv', repo = repo)
  git_commit("Added cars.csv file", author = gert_testing_signature, repo = repo)

  # Another commit before that
  write.csv(iris, file.path(repo, 'iris.csv'))
  git_add("iris.csv", repo = repo)
  timestamp <- round(Sys.time() - 48*60*60)
  sig2 <- git_signature('nobody', 'nobody@gmail.com', time = timestamp)
  git_commit("Added iris.csv also", author = sig2, repo = repo)

  # Inspect the log file
  log <- git_log(repo = repo)
  expect_equal(log$author[2], git_signature_info(gert_testing_signature)$author)
  expect_equal(log$time[1], timestamp)
})


test_that("creating a commit in another directory without author works", {
  path <- tempfile("gert-tests-commit")
  on.exit(unlink(path, recursive = TRUE))

  dir.create(path)
  repo <- git_init(path)
  git_config_set('user.name', "Jerry Johnson", repo = repo)
  git_config_set('user.email', "jerry@gmail.com", repo = repo)
  writeLines("content", file.path(path, "file"))
  git_add("file", repo = path)
  git_commit("Added file", repo = repo)

  log <- git_log(repo = repo)
  sig <- git_signature_default(repo)
  expect_equal(log$author, git_signature_info(sig)$author)
})

test_that("status reports a conflicted file", {
  # temporary measure until gert can do a non fast forward merge
  skip_if_not_installed("git2r")

  repo <- git_init(tempfile("gert-test-conflicts"))
  on.exit(unlink(repo, recursive = TRUE))

  foo_path <- file.path(repo, "foo.txt")

  writeLines("cranky-crab-legs", foo_path)
  git_add("foo.txt", repo = repo)
  git_commit("Add a file", author = gert_testing_signature, repo = repo)

  git_branch_create("my-branch", repo = repo)
  writeLines("cranky-CRAB-LEGS", foo_path)
  git_add("foo.txt", repo = repo)
  git_commit("Uppercase last 2 words", author = gert_testing_signature, repo = repo)

  git_branch_checkout("master", repo = repo)
  writeLines("CRANKY-CRAB-legs", foo_path)
  git_add("foo.txt", repo = repo)
  git_commit("Uppercase first 2 words", author = gert_testing_signature, repo = repo)

  # TODO: switch to a gert function when possible
  # https://github.com/r-lib/gert/issues/41
  git2r::merge(x = repo, y = "my-branch")

  status <- git_status(repo)
  expect_equal(status$file, "foo.txt")
  expect_equal(status$status, "conflicted")
  expect_false(status$staged)
})

context("committing")

name <- 'Testing Jerry'
email <- 'test@jerry.com'
author <- sprintf("%s <%s>", name, email)

test_that("creating signatures", {
  now <- Sys.time()
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
  repo <- git_init(tempdir())
  expect_equal(nrow(git_ls(repo)), 0)
  write.csv(iris, file.path(tempdir(), 'iris.csv'))
  write.csv(cars, file.path(tempdir(), 'cars.csv'))
  git_add(c('cars.csv', 'iris.csv'), repo = repo)
  expect_equal(nrow(git_ls(repo)), 2)
  expect_equal(git_ls(tempdir())$path, c('cars.csv', 'iris.csv'))
  git_rm(c('cars.csv', 'iris.csv'), repo = repo)
  expect_equal(nrow(git_ls(repo)), 0)
  remotes <- git_remote_list(repo)
  expect_equal(nrow(remotes), 0)
})

test_that("creating a commit", {
  repo <- tempdir()
  expect_equal(nrow(git_ls(repo)), 0)
  git_add('cars.csv', repo = repo)
  sig1 <- git_signature(name, email)
  git_commit("Added cars.csv file", author = sig1, repo = repo)

  # Another commit before that
  git_add("iris.csv", repo = repo)
  timestamp <- round(Sys.time() - 48*60*60)
  sig2 <- git_signature('nobody', 'nobody@gmail.com', time = timestamp)
  git_commit("Added iris.csv also", author = sig2, repo = repo)

  # Inspect the log file
  log <- git_log(repo = repo)
  expect_equal(log$author[2], author)
  expect_equal(log$time[1], timestamp)
})


test_that("creating a commit in another directory without author works", {
  path <- tempfile()
  dir.create(path)
  repo <- git_init(path)
  writeLines("content", file.path(path, "file"))
  git_add("file", repo = path)
  git_commit("Added file", repo = repo)

  log <- git_log(repo = repo)
  sig <- git_signature_default(repo)
  expect_equal(log$author, git_signature_info(sig)$author)
})

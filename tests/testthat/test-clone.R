context("test-clone")

test_that("cloning repositories works", {
  path <- file.path(tempdir(), 'jsonlite')
  repo <- git_clone('https://github.com/jeroen/jsonlite', path = path)
  expect_true(file.exists(file.path(path, 'DESCRIPTION')))
  info <- git_info(repo)
  expect_equal(info$ref, "refs/heads/master")
  expect_equal(info$shorthand, "master")
  repo2 <- git_open(path)
  info2 <- git_info(repo2)
  expect_equal(info, info2)
  expect_is(git_ls(repo), 'data.frame')

  # Test remotes
  remotes <- git_remotes(repo)
  expect_equal(remotes$remote, "origin")
  expect_equal(remotes$url, "https://github.com/jeroen/jsonlite")

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
  remotes <- git_remotes(repo)
  expect_equal(nrow(remotes), 0)
})

test_that("ssh remotes work", {
  remote <- 'git@github.com:jeroen/webp.git'
  target <- file.path(tempdir(), basename(remote))
  repo <- git_clone(remote, path = target)
  expect_true(file.exists(file.path(target, 'DESCRIPTION')))
})

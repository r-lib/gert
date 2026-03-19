test_that("git_config_get returns value or NULL", {
  repo <- git_init(tempfile("gert-tests-config"))
  on.exit(unlink(repo, recursive = TRUE))

  expect_null(git_config_get("aaa.bbb", repo = repo))
  git_config_set("aaa.bbb", "ccc", repo = repo)
  expect_equal(git_config_get("aaa.bbb", repo = repo), "ccc")
})

test_that("git_config_global_get returns value or NULL", {
  expect_null(git_config_global_get("gert.nonexistent.option.xyzzy"))
  # Note: avoid setting/unsetting real global config in tests
})

test_that("git_config_local_get returns local value or NULL", {
  repo <- git_init(tempfile("gert-tests-config"))
  on.exit(unlink(repo, recursive = TRUE))

  expect_null(git_config_local_get("aaa.bbb", repo = repo))
  git_config_set("aaa.bbb", "ccc", repo = repo)
  expect_equal(git_config_local_get("aaa.bbb", repo = repo), "ccc")
  # global-only option should not be visible at local level
  expect_null(git_config_local_get(
    "gert.nonexistent.option.xyzzy",
    repo = repo
  ))
})

test_that("local, custom config roundtrip", {
  repo <- git_init(tempfile("gert-tests-config"))
  on.exit(unlink(repo, recursive = TRUE))

  orig <- git_config_set("aaa.bbb", "ccc", repo = repo)
  expect_null(orig)
  expect_equal(git_config_get("aaa.bbb", repo = repo), "ccc")

  orig <- git_config_set("aaa.bbb", NULL, repo = repo)
  expect_equal(orig, "ccc")
  expect_null(git_config_get("aaa.bbb", repo = repo))
})

test_that("multivar, local, custom config roundtrip", {
  repo <- git_init(tempfile("gert-tests-config-multivar"))
  on.exit(unlink(repo, recursive = TRUE))

  git_config_set("aaa.bbb", "ccc", repo = repo, add = TRUE)
  git_config_set("aaa.bbb", "ddd", repo = repo, add = TRUE)
  git_config_set("aaa.bbb", "eee", repo = repo, add = TRUE)
  cfg <- git_config(repo)
  expect_equal(cfg$value[cfg$name == "aaa.bbb"], c("ccc", "ddd", "eee"))

  git_config_set("aaa.bbb", "ddd", repo = repo, unset = TRUE)
  cfg <- git_config(repo)
  expect_equal(cfg$value[cfg$name == "aaa.bbb"], c("ccc", "eee"))

  git_config_set("aaa.bbb", "^[a-z]{3}$", repo = repo, unset = TRUE)
  cfg <- git_config(repo)
  expect_equal(cfg$value[cfg$name == "aaa.bbb"], character())
})

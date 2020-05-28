test_that("local, custom config roundtrip", {
  repo <- git_init(tempdir())
  on.exit(unlink(repo, recursive = TRUE))

  orig <- git_config_set("aaa.bbb", "ccc", repo)
  expect_null(orig)
  cfg <- git_config(repo)
  expect_equal(cfg$value[cfg$name == "aaa.bbb"], "ccc")

  orig <- git_config_set("aaa.bbb", NULL, repo)
  expect_equal(orig, "ccc")
  cfg <- git_config(repo)
  expect_equal(cfg$value[cfg$name == "aaa.bbb"], character())
})

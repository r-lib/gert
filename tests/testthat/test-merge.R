test_that("merge analysis works", {
  repo <- git_init(tempfile("gert-tests-merge"))
  on.exit(unlink(repo, recursive = TRUE))
  oldwd <- getwd()
  on.exit(setwd(oldwd), add = TRUE)
  setwd(repo)
  configure_local_user()
  for(i in 1:5){
    writeLines(paste('Blabla', i), "test.txt")
    git_add("test.txt")
    git_commit(paste("This is commit number:", i))
  }
  master_log <- git_log()
  first_commit <- tail(master_log$commit, 1)
  git_branch_create('new', first_commit)
  git_branch_checkout('new')
  expect_equal(git_log()$commit, tail(master_log,1)$commit)
  expect_equal(git_merge_analysis('master'), 'fastforward')

  # Expect no merge commit (ffwd)
  git_merge("master")
  expect_equal(master_log, git_log())

  # Create a branch that diverges
  git_branch_create('new2', first_commit)
  git_branch_checkout('new2')
  writeLines('Something else', 'test2.txt')
  git_add('test2.txt')
  git_commit("Some other commit")
  expect_equal(git_merge_base('master'), first_commit)

  # Require merge commit
  expect_equal(git_merge_analysis('master'), 'normal')
  git_merge('master')
  newlog <- git_log()
  expect_length(newlog$commit, 3)
  expect_equal(newlog$merge, c(TRUE, FALSE, FALSE))

  # Expect no changes
  git_merge('master')
  expect_equal(git_log(), newlog)
})


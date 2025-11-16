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
  main <- git_branch()
  master_log <- git_log()
  first_commit <- tail(master_log$commit, 1)
  git_branch_create('new', first_commit)
  git_branch_checkout('new')
  expect_equal(git_log()$commit, tail(master_log,1)$commit)
  expect_equal(git_merge_analysis(main), 'fastforward')

  # Expect no merge commit (ffwd)
  git_merge(main)
  expect_equal(master_log, git_log())

  # Create a branch that diverges
  git_branch_create('new2', first_commit)
  git_branch_checkout('new2')
  writeLines('Something else', 'test2.txt')
  git_add('test2.txt')
  git_commit("Some other commit")
  expect_equal(git_merge_find_base(main), first_commit)

  # Require merge commit
  expect_equal(git_merge_analysis(main), 'normal')
  git_merge(main)
  newlog <- git_log()
  expect_length(newlog$commit, 3)
  expect_equal(newlog$merge, c(TRUE, FALSE, FALSE))
  expect_null(git_merge_parent_heads())

  # Expect no changes
  git_merge(main)
  expect_equal(git_log(), newlog)
})


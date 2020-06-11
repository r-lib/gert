#' Merging tools
#'
#' Use `git_merge` to merge a branch into the current head. Based on how the branches
#' have diverged, the function will select a fast-forward or merge-commit strategy.
#'
#' By default `git_merge` will automatically commit the merge. However if
#' `commit_on_success` is set to `FALSE` or if the merge fails with
#' merge-conflicts, the changes are staged but you have to run [git_commit] manually.
#'
#' Other functions are more low-level tools that are used by `git_merge`.
#' `git_merge_find_base` looks up the commit where two branches have diverged
#' (i.e. the youngest common ancestor).
#'
#' Use `git_merge_analysis` to test what strategy would be needed to merge a branch.
#' Possible outcomes are `"fastforward"`, `"normal"`, or `"up-to-date"`.
#'
#' The `git_merge_stage` function applies and stages changes from another branch in the
#' current one, without committing anything.
#'
#' @export
#' @family git
#' @rdname git_merge
#' @name git_merge
#' @inheritParams git_open
#' @param ref branch or commit that you want to merge
#' @param commit_on_success automatically create a merge commit if the merge succeeds without
#' conflicts. Set this to `FALSE` if you want to customize your commit message/author.
git_merge <- function(ref, commit_on_success = TRUE, repo = '.'){
  state <- git_merge_analysis(ref = ref, repo = repo)
  if(state == "up_to_date"){
    message("Already up to date, nothing to merge")
  } else if(state == "fastforward"){
    message("Performing fast-foward merge, no commit needed")
    git_branch_fast_forward(ref = ref, repo = repo)
  } else if(state == "normal"){
    merged_without_conflict <- git_merge_stage(ref = ref, repo = repo)
    if(!nrow(git_status(repo = repo))){
      message("Merge did not result in any changes")
    } else if(isTRUE(merged_without_conflict)){
      if(isTRUE(commit_on_success)){
        commit_message <- sprintf("Merged %s into %s", ref, git_info()$shorthand)
        git_commit(commit_message, repo = repo)
      } else {
        message("Merge was not be committed due to merge conflict(s). Please fix first and run git_commit() manually.")
      }
    } else {
      message("Merge has resulted in merge conflict(s).")
    }
  } else {
    stop(sprintf("State is '%s', not sure what to do", state))
  }
}

#' @export
#' @rdname git_merge
#' @useDynLib gert R_git_merge_find_base
#' @param target the branch where you want to merge into. Defaults to current `HEAD`.
git_merge_find_base <- function(ref, target = "HEAD", repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_find_base, repo, ref, target)
}

#' @export
#' @rdname git_merge
#' @useDynLib gert R_git_merge_analysis
git_merge_analysis <- function(ref, repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_analysis, repo, ref)
}

#' @export
#' @rdname git_merge
#' @useDynLib gert R_git_merge_stage
git_merge_stage <- function(ref, repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_stage, repo, ref)
}

#' @export
#' @rdname git_merge
#' @useDynLib gert R_git_merge_cleanup
git_merge_abort <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_cleanup, repo)
}

#' @useDynLib gert R_git_merge_parent_heads
git_merge_parent_heads <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_parent_heads, repo)
}

#' Merging tools
#'
#' Tools for preparing and performing merge operations. Under construction.
#'
#' @export
#' @family git
#' @rdname merge
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
    # TODO: should we not cleanup upon conflicts and leave the merging-state?
    on.exit(git_merge_cleanup(repo = repo))
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
#' @rdname merge
#' @useDynLib gert R_git_merge_base
#' @param target the branch where you want to merge into. Defaults to current `HEAD`.
git_merge_base <- function(ref, target = "HEAD", repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_base, repo, ref, target)
}

#' @export
#' @rdname merge
#' @useDynLib gert R_git_merge_analysis
git_merge_analysis <- function(ref, repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_analysis, repo, ref)
}

#' @export
#' @rdname merge
#' @useDynLib gert R_git_merge_stage
git_merge_stage <- function(ref, repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_stage, repo, ref)
}

#' @export
#' @rdname merge
#' @useDynLib gert R_git_merge_cleanup
git_merge_cleanup <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_cleanup, repo)
}

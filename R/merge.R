#' Merging tools
#'
#' Use `git_merge` to merge a branch into the current head. Based on how the branches
#' have diverged, the function will select a fast-forward or merge-commit strategy.
#'
#' By default `git_merge` automatically commits the merge commit upon success.
#' However if the merge fails with merge-conflicts, or if `commit` is set to
#' `FALSE`, the changes are staged and the repository is put in merging state,
#' and you have to manually run `git_commit` or `git_merge_abort` to proceed.
#'
#' Other functions are more low-level tools that are used by `git_merge`.
#' `git_merge_find_base` looks up the commit where two branches have diverged
#' (i.e. the youngest common ancestor). The `git_merge_analysis` is used to
#' test if a merge can simply be fast forwarded or not.
#'
#' The `git_merge_stage_only` function applies and stages changes, without
#' committing or fast-forwarding.
#'
#' @export
#' @family git
#' @rdname git_merge
#' @name git_merge
#' @inheritParams git_open
#' @param ref branch or commit that you want to merge
#' @param commit automatically create a merge commit if the merge succeeds without
#' conflicts. Set this to `FALSE` if you want to customize your commit message/author.
#' @param squash omits the second parent from the commit, which make the merge a regular
#' single-parent commit.
git_merge <- function(ref, commit = TRUE, squash = FALSE, repo = '.'){
  state <- git_merge_analysis(ref = ref, repo = repo)
  if(state == "up_to_date"){
    inform("Already up to date, nothing to merge")
  } else if(state == "fastforward"){
    inform("Performing fast-forward merge, no commit needed")
    git_branch_fast_forward(ref = ref, repo = repo)
  } else if(state == "normal"){
    merged_without_conflict <- git_merge_stage_only(ref = ref, squash = squash, repo = repo)
    if(!nrow(git_status(repo = repo))){
      inform("Merge did not result in any changes")
    } else if(isTRUE(merged_without_conflict)){
      if(isTRUE(commit)){
        commit_message <- sprintf("Merged %s into %s", ref, git_info(repo = repo)$shorthand)
        git_commit(commit_message, repo = repo)
        inform(commit_message)
      } else {
        inform("Merge was not committed due to merge conflict(s). Please fix and run git_commit() or git_merge_abort()")
      }
    } else {
      inform("Merge has resulted in merge conflict(s).")
    }
  } else {
    stop(sprintf("State is '%s', not sure what to do", state))
  }
  invisible(state)
}

#' @export
#' @rdname git_merge
#' @useDynLib gert R_git_merge_stage
git_merge_stage_only <- function(ref, squash = FALSE, repo = '.'){
  repo <- git_open(repo)
  success <- .Call(R_git_merge_stage, repo, ref)
  if(isTRUE(squash)) # This turns it in a regular commit
    git_merge_cleanup(repo = repo)
  return(success)
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

#' @useDynLib gert R_git_merge_cleanup
git_merge_cleanup <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_cleanup, repo)
}

#' @export
#' @rdname git_merge
git_merge_abort <- function(repo = '.'){
  if(length(git_merge_parent_heads(repo = repo))){
    git_reset_hard(repo = repo)
    git_merge_cleanup(repo = repo)
  } else {
    inform("There is no merge to abort")
  }
}

#' @useDynLib gert R_git_merge_parent_heads
git_merge_parent_heads <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_parent_heads, repo)
}

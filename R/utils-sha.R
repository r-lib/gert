check_ref_in_history <- function(ref, repo) {
  sha <- tryCatch(git_commit_id(ref, repo = repo), error = function(e) {
    stop(sprintf("Cannot resolve '%s' to a commit", ref))
  })

  head_sha <- git_commit_id("HEAD", repo = repo)
  sha_descends_from_head <- git_commit_descendant_of(
    ancestor = sha,
    ref = "HEAD",
    repo = repo
  )
  if (sha != head_sha && !sha_descends_from_head) {
    stop(sprintf("'%s' is not in the current branch history", ref))
  }

  sha
}

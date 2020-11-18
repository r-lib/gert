#' Submodules
#'
#' Interact with submodules in the repository.
#'
#' @export
#' @rdname git_submodule
#' @inheritParams git_open
#' @useDynLib gert R_git_submodule_list
git_submodule_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_submodule_list, repo)
}

#' @export
#' @rdname git_submodule
#' @useDynLib gert R_git_submodule_info
git_submodule_info <- function(submodule, repo = '.'){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  .Call(R_git_submodule_info, repo, submodule)
}

#' @export
#' @rdname git_submodule
#' @useDynLib gert R_git_submodule_init
#' @param submodule name of the submodule
#' @param overwrite overwrite existing entries
git_submodule_init <- function(submodule, overwrite = FALSE, repo = '.'){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  overwrite <- as.logical(overwrite)
  .Call(R_git_submodule_init, repo, submodule, overwrite)
}

#' @export
#' @rdname git_submodule
#' @useDynLib gert R_git_submodule_update
#' @param submodule name of the submodule
#' @param init automatically initialize before updating
git_submodule_update <- function(submodule, init = TRUE, repo = '.'){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  init <- as.logical(init)
  .Call(R_git_submodule_update, repo, submodule, init)
}

#' @export
#' @rdname git_submodule
#' @useDynLib gert R_git_submodule_set_to
#' @param ref branch or tag to point the submodule at. If checkout = FALSE, you
#' can pass a commit hash before downloading the submodule.
#' @param checkout actually switch the contents of the directory to this commit
git_submodule_set_to <- function(submodule, ref, checkout = TRUE, repo = '.'){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  info <- git_submodule_info(submodule, repo = repo)
  if(isTRUE(checkout)){
    git_reset_hard(ref = ref, repo = I(info$path))
    ref <- git_info(repo = I(info$path))$commit
  } else if(!is_full_hash(ref)) {
    ref <- git_commit_info(ref, repo = I(info$path))$id
  }
  if(!is_full_hash(ref))
    stop("When checkout = FALSE, parameter ref must be a full hash")
 .Call(R_git_submodule_set_to, repo, submodule, ref)
}

#' @export
#' @rdname git_submodule
#' @param url full git url of the submodule
#' @param path relative of the submodule
#' @param ref a branch or tag or hash with
#' @param ... extra arguments for [git_fetch] for authentication things
git_submodule_add <- function(url, path = basename(url), ref = 'HEAD', ..., repo = '.'){
  if(!is_a_hash(ref)){
    upstream_refs <- git_remote_ls(url, ..., repo = repo)
    ref_match <- sub("refs/(heads|tags)/","", upstream_refs$ref) == ref
    if(!any(ref_match)){
      stop(sprintf("Upstream repo %s does not have a branch or tag named '%s'",
                   basename(url), ref))
    }
    ref <- upstream_refs$oid[ref_match]
  }
  submodule <- git_submodule_setup(url = url, path = path, repo = repo)
  git_fetch('origin', ..., repo = submodule)
  git_reset_hard(ref, repo = submodule)
  git_submodule_save(path, repo = repo)
  git_submodule_info(path, repo = repo)
}

#' @export
#' @rdname git_submodule
git_submodule_fetch <- function(submodule, ..., repo = '.'){
  sm <- git_submodule_info(submodule = submodule, repo = repo)
  subrepo = I(sm$path)
  tryCatch(git_info(repo = subrepo), error = function(e){
    inform("Cloning submodule '%s'", submodule)
    git_submodule_update(submodule, repo = repo)
  })
  git_fetch('origin', ..., repo = subrepo)
  if(length(sm$branch) && !is.na(sm$branch)){
    git_reset_hard(sm$branch, repo = subrepo)
  } else {
    remote_head <- git_remote_info('origin', repo = subrepo)$head
    if(!length(remote_head)){
      git_remote_ls('origin', ..., repo = subrepo)
      remote_head <- git_remote_info('origin', repo = subrepo)$head
    }
    git_reset_hard(remote_head, repo = I(sm$path))
  }
  git_commit_id(repo = subrepo)
}

#' @useDynLib gert R_git_submodule_setup
git_submodule_setup <- function(url, path, repo){
  repo <- git_open(repo)
  path <- as.character(path)
  url <- as.character(url)
  .Call(R_git_submodule_setup, repo, url, path)
}

#' @useDynLib gert R_git_submodule_save
git_submodule_save <- function(submodule, repo){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  .Call(R_git_submodule_save, repo, submodule)
}

is_a_hash <- function(x){
  grepl('^[a-f0-9]{7,}$', tolower(x))
}

is_full_hash <- function(x){
  grepl('^[a-f0-9]{40}$', tolower(x))
}

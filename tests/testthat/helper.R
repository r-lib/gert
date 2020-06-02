configure_local_user <- function(repo = ".") {
  git_config_set('user.name', "Jerry Johnson", repo = repo)
  git_config_set('user.email', "jerry@gmail.com", repo = repo)
}

local_author <- function(repo = ".") {
  git_signature_info(git_signature_default(repo))$author
}

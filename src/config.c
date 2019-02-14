#include "utils.h"

static int count_config_iter(git_config *cfg){
  int count = 0;
  git_config_entry *entry = NULL;
  git_config_iterator *iter = NULL;
  bail_if(git_config_iterator_new(&iter, cfg), "git_config_iterator_new");
  while (git_config_next(&entry, iter) == 0)
    count++;
  git_config_iterator_free(iter);
  return count;
}

static SEXP R_git_config_list(git_repository *repo){
  git_config_iterator *iter = NULL;
  git_config_entry *entry = NULL;
  git_config *cfg = NULL;
  if(repo == NULL) {
    bail_if(git_config_open_default(&cfg), "git_config_open_default");
  } else {
    bail_if(git_repository_config(&cfg, repo),"git_repository_config");
  }
  int count = count_config_iter(cfg);
  SEXP names = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP values = PROTECT(Rf_allocVector(STRSXP, count));
  int i = 0;
  bail_if(git_config_iterator_new(&iter, cfg), "git_config_iterator_new");
  while (git_config_next(&entry, iter) == 0) {
    SET_STRING_ELT(names, i, safe_char(entry->name));
    SET_STRING_ELT(values, i, safe_char(entry->value));
    i++;
  }
  git_config_iterator_free(iter);
  git_config_free(cfg);
  return build_tibble(2, "name", names, "value", values);
}

SEXP R_git_config_repo(SEXP ptr){
  return R_git_config_list(get_git_repository(ptr));
}

SEXP R_git_config_default(){
  return R_git_config_list(NULL);
}

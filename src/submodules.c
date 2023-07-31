#include <string.h>
#include "utils.h"

static int submodule_count(git_submodule *submod, const char *name, void *payload){
  int *count = payload;
  *count = (*count) + 1;
  return 0;
}

static int submodule_fill(git_submodule *sm, const char *name, void *payload){
  REprintf(".");
  SEXP df = payload;
  SEXP names = VECTOR_ELT(df, 0);
  SEXP paths = VECTOR_ELT(df, 1);
  SEXP urls = VECTOR_ELT(df, 2);
  SEXP branches = VECTOR_ELT(df, 3);
  SEXP heads = VECTOR_ELT(df, 4);
  for(int i = 0; i < Rf_length(names); i++){
    if(Rf_length(STRING_ELT(names, i)) == 0){
      SET_STRING_ELT(names, i, safe_char(git_submodule_name(sm)));
      SET_STRING_ELT(paths, i, safe_char(git_submodule_path(sm)));
      SET_STRING_ELT(urls, i, safe_char(git_submodule_url(sm)));
      SET_STRING_ELT(branches, i, safe_char(git_submodule_branch(sm)));
      SET_STRING_ELT(heads, i, safe_char(git_oid_tostr_s(git_submodule_head_id(sm))));
      return 0;
    }
  }
  return 1;
}

SEXP R_git_submodule_list(SEXP ptr){
  int n = 0;
  git_repository *repo = get_git_repository(ptr);
  git_submodule_foreach(repo, submodule_count, &n);
  SEXP df = PROTECT(build_tibble(5,
                         "name", PROTECT(Rf_allocVector(STRSXP, n)),
                         "path", PROTECT(Rf_allocVector(STRSXP, n)),
                         "url", PROTECT(Rf_allocVector(STRSXP, n)),
                         "branch", PROTECT(Rf_allocVector(STRSXP, n)),
                         "head", PROTECT(Rf_allocVector(STRSXP, n))));
  REprintf("Filling: ");
  git_submodule_foreach(repo, submodule_fill, df);
  REprintf("\nDONE\n");
  UNPROTECT(6);
  return df;
}

SEXP R_git_submodule_info(SEXP ptr, SEXP name){
  git_repository *repo = get_git_repository(ptr);
  git_submodule *sm = NULL;
  bail_if(git_submodule_lookup(&sm, repo, CHAR(STRING_ELT(name, 0))), "git_submodule_lookup");
  SEXP out = build_list(5,
                        "name", PROTECT(safe_string(git_submodule_name(sm))),
                        "path", PROTECT(safe_string(git_submodule_path(sm))),
                        "url", PROTECT(safe_string(git_submodule_url(sm))),
                        "branch", PROTECT(safe_string(git_submodule_branch(sm))),
                        "head", PROTECT(safe_string(git_oid_tostr_s(git_submodule_head_id(sm)))));
  UNPROTECT(5);
  git_submodule_free(sm);
  return out;
}

SEXP R_git_submodule_init(SEXP ptr, SEXP name, SEXP overwrite){
  git_repository *repo = get_git_repository(ptr);
  git_submodule *sm = NULL;
  bail_if(git_submodule_lookup(&sm, repo, CHAR(STRING_ELT(name, 0))), "git_submodule_lookup");
  bail_if(git_submodule_init(sm, Rf_asLogical(overwrite)), "git_submodule_init");
  SEXP path = safe_string(git_submodule_path(sm));
  git_submodule_free(sm);
  return path;
}

SEXP R_git_submodule_update(SEXP ptr, SEXP name, SEXP init){
  git_repository *repo = get_git_repository(ptr);
  git_submodule *sm = NULL;
  bail_if(git_submodule_lookup(&sm, repo, CHAR(STRING_ELT(name, 0))), "git_submodule_lookup");
  git_submodule_update_options opt = GIT_SUBMODULE_UPDATE_OPTIONS_INIT;
  bail_if(git_submodule_update(sm, Rf_asLogical(init), &opt), "git_submodule_update");
  SEXP path = safe_string(git_submodule_path(sm));
  git_submodule_free(sm);
  return path;
}

SEXP R_git_submodule_setup(SEXP ptr, SEXP url, SEXP path){
  git_submodule *sm = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_submodule_add_setup(&sm, repo, CHAR(STRING_ELT(url, 0)),
                                  CHAR(STRING_ELT(path, 0)), 1), "git_submodule_add_setup");
  git_repository *subrepo = NULL;
  bail_if(git_submodule_open(&subrepo, sm), "git_submodule_open");
  git_submodule_free(sm);
  return new_git_repository(subrepo);
}

SEXP R_git_submodule_save(SEXP ptr, SEXP submodule){
  git_submodule *sm = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_submodule_lookup(&sm, repo, CHAR(STRING_ELT(submodule, 0))), "git_submodule_lookup");
  bail_if(git_submodule_add_finalize(sm), "git_submodule_add_finalize");
  git_submodule_free(sm);
  return submodule;
}

SEXP R_git_submodule_set_to(SEXP ptr, SEXP submodule, SEXP oid){
  git_submodule *sm = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_submodule_lookup(&sm, repo, CHAR(STRING_ELT(submodule, 0))), "git_submodule_lookup");
  git_index_entry entry = {{0}};
  bail_if(git_oid_fromstr(&entry.id, CHAR(STRING_ELT(oid, 0))), "git_oid_fromstr");
  entry.path = git_submodule_path(sm);
  entry.mode = GIT_FILEMODE_COMMIT;
  git_index *index;
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  bail_if(git_index_add(index, &entry), "git_index_add");
  git_index_write(index);
  git_index_free(index);
  git_submodule_free(sm);
  return oid;
}

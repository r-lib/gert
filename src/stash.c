#include <string.h>
#include "utils.h"

SEXP R_git_stash_save(SEXP ptr, SEXP message, SEXP keep_index,
                      SEXP include_untracked, SEXP include_ignored){
  git_oid out;
  git_signature *me;
  git_repository *repo = get_git_repository(ptr);
  const char *msg = Rf_translateCharUTF8(STRING_ELT(message, 0));
  bail_if(git_signature_default(&me, repo), "git_signature_default");
  git_stash_flags flags = GIT_STASH_DEFAULT;
  flags += Rf_asLogical(keep_index) * GIT_STASH_KEEP_INDEX;
  flags += Rf_asLogical(include_untracked) * GIT_STASH_INCLUDE_UNTRACKED;
  flags += Rf_asLogical(include_ignored) * GIT_STASH_INCLUDE_IGNORED;
  bail_if(git_stash_save(&out, repo, me, msg, flags), "git_stash_save");
  return safe_string(git_oid_tostr_s(&out));
}

SEXP R_git_stash_pop(SEXP ptr, SEXP index){
  size_t i = Rf_asInteger(index);
  git_repository *repo = get_git_repository(ptr);
  git_stash_apply_options opts = GIT_STASH_APPLY_OPTIONS_INIT;
  bail_if(git_stash_pop(repo, i, &opts), "git_stash_pop");
  return R_NilValue;
}

SEXP R_git_stash_drop(SEXP ptr, SEXP index){
  size_t i = Rf_asInteger(index);
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_stash_drop(repo, i), "git_stash_drop");
  return R_NilValue;
}

static int counter_cb(size_t i, const char* message, const git_oid *stash_id, void *payload){
  int *count = payload;
  (*count)++;
  return 0;
}

static int stash_ls_cb(size_t i, const char* message, const git_oid *stash_id, void *payload){
  SEXP df = payload;
  INTEGER(VECTOR_ELT(df, 0))[i] = i;
  SET_STRING_ELT(VECTOR_ELT(df, 1), i, safe_char(message));
  SET_STRING_ELT(VECTOR_ELT(df, 2), i, safe_char(git_oid_tostr_s(stash_id)));
  return 0;
}

SEXP R_git_stash_list(SEXP ptr){
  int count = 0;
  git_repository *repo = get_git_repository(ptr);
  git_stash_foreach(repo, counter_cb, &count);

  SEXP indexes = PROTECT(Rf_allocVector(INTSXP, count));
  SEXP messages = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP oidstr = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP df = PROTECT(build_tibble(3, "index", indexes, "message", messages, "oid", oidstr));
  if(count > 0)
    git_stash_foreach(repo, stash_ls_cb, df);
  UNPROTECT(1);
  return df;
}

#include <string.h>
#include "utils.h"

static SEXP shrink_strvec(SEXP input, int n){
  if(Rf_length(input) <= n)
    return input;
  SEXP output = PROTECT(Rf_allocVector(STRSXP, n));
  for(int i = 0; i < n; i++)
    SET_STRING_ELT(output, i, STRING_ELT(input, i));
  UNPROTECT(1);
  return output;
}

SEXP R_git_commit_log(SEXP ptr, SEXP max, SEXP ref){
  git_repository *repo = get_git_repository(ptr);
  git_oid oid_parent_commit;  /* the SHA1 for last commit */
  bail_if(git_reference_name_to_id( &oid_parent_commit, repo, CHAR(STRING_ELT(ref, 0))), "git_reference_name_to_id");

  git_commit *head = NULL;
  git_commit *commit = NULL;
  bail_if(git_commit_lookup(&head, repo, &oid_parent_commit), "git_commit_lookup");
  int len = Rf_asInteger(max);
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP msg = PROTECT(Rf_allocVector(STRSXP, len));
  int i;
  for(i = 0; i < len; i++){
    SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(git_commit_id(head))));
    SET_STRING_ELT(msg, i, safe_char(git_commit_message(head)));
    int res = git_commit_parent(&commit, head, 0);
    git_commit_free(head);
    if(res == GIT_ENOTFOUND)
      break;
    bail_if(res, "git_commit_parent");
    head = commit;
  }
  if(i < len){
    ids = shrink_strvec(ids, i+1);
    msg = shrink_strvec(msg, i+1);
    UNPROTECT(2); //unprotect input vecs
    PROTECT(ids);
    PROTECT(msg);
  }
  return build_tibble(2, "id", ids, "message", msg);
}

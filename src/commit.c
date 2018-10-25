#include <string.h>
#include "utils.h"

static int count_commit_parents(git_commit *input, int max){
  git_commit *x = NULL;
  git_commit *y = NULL;
  git_commit_dup(&x, input);
  for(int i = 1; i < max; i++){
    int res = git_commit_parent(&y, x, 0);
    git_commit_free(x);
    if(res == GIT_ENOTFOUND)
      return i;
    bail_if(res, "git_commit_parent");
    x = y;
  }
  git_commit_free(x);
  return max;
}

static SEXP make_author(const git_signature *p){
  char buf[2000] = "";
  if(p->name && p->email){
    snprintf(buf, 1999, "%s <%s>", p->name, p->email);
  } else if(p->name){
    snprintf(buf, 1999, "%s", p->name);
  } else if(p->email){
    snprintf(buf, 1999, "%s", p->email);
  }
  return safe_char(buf);
}

SEXP R_git_commit_log(SEXP ptr, SEXP max, SEXP ref){
  git_commit *head = NULL;
  git_commit *commit = NULL;
  git_object *revision = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_revparse_single(&revision, repo, CHAR(STRING_ELT(ref, 0))), "git_revparse_single");
  bail_if(git_commit_lookup(&head, repo, git_object_id(revision)), "git_commit_lookup");
  git_object_free(revision);

  /* Find out how many ancestors we have */
  int len = count_commit_parents(head, Rf_asInteger(max));
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP msg = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP author = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP time = PROTECT(Rf_allocVector(REALSXP, len));

  for(int i = 0; i < len; i++){
    SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(git_commit_id(head))));
    SET_STRING_ELT(msg, i, safe_char(git_commit_message(head)));
    SET_STRING_ELT(author, i, make_author(git_commit_author(head)));
    REAL(time)[i] = git_commit_time(head);

    /* traverse to next commit (except for the final one) */
    if(i < len-1)
      bail_if(git_commit_parent(&commit, head, 0), "git_commit_parent");
    git_commit_free(head);
    head = commit;
  }
  Rf_setAttrib(time, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  return build_tibble(4, "id", ids, "author", author, "time", time, "message", msg);
}

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

SEXP R_git_signature_default(SEXP ptr){
  git_signature *sig;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_signature_default(&sig, repo), "git_signature_default");
  SEXP out = Rf_ScalarString(make_author(sig));
  git_signature_free(sig);
  return out;
}

SEXP R_git_commit_create(SEXP ptr, SEXP message){
  git_buf msg = {0};
  git_tree *tree;
  git_index *index;
  git_signature *me;
  git_commit *commit = NULL;
  git_reference *head = NULL;
  git_oid tree_id, commit_id;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_signature_default(&me, repo), "git_signature_default");
  if(git_repository_head(&head, repo) == 0){
    bail_if(git_commit_lookup(&commit, repo, git_reference_target(head)), "git_commit_lookup");
  }
  bail_if(git_message_prettify(&msg, Rf_translateCharUTF8(STRING_ELT(message, 0)), 0, 0), "git_message_prettify");

  // Setup tree, see: https://libgit2.org/docs/examples/init/
  const git_commit *parents[1] = {commit};
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  bail_if(git_index_write_tree(&tree_id, index), "git_index_write_tree");
  bail_if(git_tree_lookup(&tree, repo, &tree_id), "git_tree_lookup");
  bail_if(git_commit_create(&commit_id, repo, "HEAD", me, me, "UTF-8", msg.ptr,
                            tree, commit ? 1 : 0, parents), "git_commit_create");
  git_buf_free(&msg);
  git_tree_free(tree);
  git_index_free(index);
  git_signature_free(me);
  git_commit_free(commit);
  git_reference_free(head);
  return safe_string(git_oid_tostr_s(&commit_id));
}

SEXP R_git_commit_log(SEXP ptr, SEXP ref, SEXP max){
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
  return build_tibble(4, "commit", ids, "author", author, "time", time, "message", msg);
}

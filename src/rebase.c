#include <string.h>
#include "utils.h"

static const char * type_to_string(git_rebase_operation_t type){
  static const char *pick = "pick";
  static const char *reword = "reword";
  static const char *edit = "edit";
  static const char *squash = "squash";
  static const char *fixup = "fixup";
  static const char *exec = "exec";
  switch(type){
  case GIT_REBASE_OPERATION_PICK:
    return pick;
  case GIT_REBASE_OPERATION_REWORD:
    return reword;
  case GIT_REBASE_OPERATION_EDIT:
    return edit;
  case GIT_REBASE_OPERATION_SQUASH:
    return squash;
  case GIT_REBASE_OPERATION_FIXUP:
    return fixup;
  case GIT_REBASE_OPERATION_EXEC:
    return exec;
  }
  return NULL;
}

SEXP R_git_rebase_info(SEXP ptr, SEXP target, SEXP upstream){
  git_index *index = NULL;
  git_rebase *rebase = NULL;
  git_rebase_operation *operation = NULL;
  git_annotated_commit *base_head = NULL;
  git_annotated_commit *upstream_head = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_annotated_commit_from_revspec(&base_head, repo, CHAR(STRING_ELT(target, 0))),
          "git_annotated_commit_from_revspec");
  bail_if(git_annotated_commit_from_revspec(&upstream_head, repo, CHAR(STRING_ELT(upstream, 0))),
          "git_annotated_commit_from_revspec");
  git_rebase_options opt = GIT_REBASE_OPTIONS_INIT;
  opt.inmemory = 1;
  bail_if(git_rebase_init(&rebase, repo, base_head, upstream_head, NULL, &opt), "git_rebase_init");
  git_annotated_commit_free(base_head);
  git_annotated_commit_free(upstream_head);
  size_t len = git_rebase_operation_entrycount(rebase);
  SEXP types = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP oids = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP conflicts = PROTECT(Rf_allocVector(LGLSXP, len));
  for(int i = 0; i < len; i++){
    bail_if(git_rebase_next(&operation, rebase), "git_rebase_next");
    SET_STRING_ELT(oids, i, safe_char(git_oid_tostr_s(&operation->id)));
    SET_STRING_ELT(types, i, safe_char(type_to_string(operation->type)));
    bail_if(git_rebase_inmemory_index(&index, rebase), "git_rebase_inmemory_index");
    LOGICAL(conflicts)[i] = git_index_has_conflicts(index);
    git_index_conflict_cleanup(index);
    git_index_free(index);
  }
  bail_if(git_rebase_abort(rebase), "git_rebase_abort");
  git_rebase_free(rebase);
  return build_tibble(3, "commit", oids, "type", types, "conflicts", conflicts);
}

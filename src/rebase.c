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

SEXP R_git_rebase_list(SEXP ptr, SEXP target, SEXP upstream){
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

SEXP R_git_cherry_pick(SEXP ptr, SEXP commit_id){
  git_oid oid = {0};
  git_oid tree_id = {0};
  git_tree *tree = NULL;
  git_index *index = NULL;
  git_commit *orig = NULL;
  git_commit *parent = NULL;
  git_reference *head = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_head(&head, repo), "git_repository_head");
  bail_if(git_commit_lookup(&parent, repo, git_reference_target(head)), "git_commit_lookup");
  git_cherrypick_options opt = GIT_CHERRYPICK_OPTIONS_INIT;
  opt.merge_opts.flags = GIT_MERGE_FAIL_ON_CONFLICT;
  bail_if(git_oid_fromstr(&oid, CHAR(STRING_ELT(commit_id, 0))), "git_oid_fromstr");
  bail_if(git_commit_lookup(&orig, repo, &oid), "git_commit_lookup");
  bail_if(git_cherrypick(repo, orig, &opt), "git_cherrypick");
  git_oid new_oid = {0};
  const git_commit *parents[1] = {parent}; // This ignores (aka squashes) other parents from a merge-commit
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  bail_if(git_index_write_tree(&tree_id, index), "git_index_write_tree");
  bail_if(git_tree_lookup(&tree, repo, &tree_id), "git_tree_lookup");
  bail_if(git_commit_create(&new_oid, repo, "HEAD", git_commit_author(orig),
                            git_commit_committer(orig), git_commit_message_encoding(orig),
                            git_commit_message(orig), tree, 1, parents), "git_commit_create");
  git_reference_free(head);
  git_commit_free(parent);
  git_commit_free(orig);
  git_index_free(index);
  git_tree_free(tree);
  return safe_string(git_oid_tostr_s(&new_oid));
}

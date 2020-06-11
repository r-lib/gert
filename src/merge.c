#include <string.h>
#include "utils.h"

/* Attempt fast forward merge (simply add commits from other branch)
 * Example: https://github.com/libgit2/libgit2/blob/master/examples/merge.c#L116-L182
 */
SEXP R_git_merge_fast_forward(SEXP ptr, SEXP ref){
  git_reference *head;
  git_reference *target;
  git_object *revision = NULL;
  git_annotated_commit *commit;
  git_repository *repo = get_git_repository(ptr);
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = GIT_CHECKOUT_SAFE;

  /* Lookup current and target tree state */
  bail_if(git_repository_head(&head, repo), "git_repository_head");
  bail_if(git_revparse_single(&revision, repo, CHAR(STRING_ELT(ref, 0))), "git_revparse_single");
  bail_if(git_annotated_commit_lookup(&commit, repo, git_object_id(revision)), "git_annotated_commit_lookup");

  /* Test if they can safely be merged */
  git_merge_analysis_t analysis;
  git_merge_preference_t preference;
  const git_annotated_commit *ccommit = commit;
  bail_if(git_merge_analysis(&analysis, &preference, repo, &ccommit, 1), "git_merge_analysis");
  git_annotated_commit_free(commit);

  /* Check analysis output */
  if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE){
    goto done;
  } else if(analysis & GIT_MERGE_ANALYSIS_FASTFORWARD || analysis & GIT_MERGE_ANALYSIS_UNBORN){
    bail_if(git_checkout_tree(repo, revision, &opts), "git_checkout_tree");
    bail_if(git_reference_set_target(&target, head, git_object_id(revision), NULL), "git_reference_set_target");
    git_reference_free(target);
  } else {
    Rf_error("Fast forward not possible for this branch");
  }

done:
  git_reference_free(head);
  git_object_free(revision);
  return ptr;
}

SEXP R_git_merge_find_base(SEXP ptr, SEXP ref1, SEXP ref2){
  git_object *t1 = NULL;
  git_object *t2 = NULL;
  git_oid base = {{0}};
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_revparse_single(&t1, repo, CHAR(STRING_ELT(ref1, 0))), "git_revparse_single");
  bail_if(git_revparse_single(&t2, repo, CHAR(STRING_ELT(ref2, 0))), "git_revparse_single");
  bail_if(git_merge_base(&base, repo, git_object_id(t1), git_object_id(t2)), "git_merge_base");
  git_object_free(t1);
  git_object_free(t2);
  return Rf_mkString(git_oid_tostr_s(&base));
}

static const char *analysis_to_str(git_merge_analysis_t analysis, git_merge_preference_t preference){
  static const char *none = "none";
  static const char *normal = "normal";
  static const char *uptodate = "up_to_date";
  static const char *fastforward = "fastforward";
  if(analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE){
    return uptodate;
  }
  if (analysis & GIT_MERGE_ANALYSIS_UNBORN || (analysis & GIT_MERGE_ANALYSIS_FASTFORWARD && !(preference & GIT_MERGE_PREFERENCE_NO_FASTFORWARD))){
    return fastforward;
  }
  if (analysis & GIT_MERGE_ANALYSIS_NORMAL){
    return normal;
  }
  if (analysis & GIT_MERGE_ANALYSIS_NONE){
    return none;
  }
  return NULL;
}

static git_annotated_commit** refs_to_git(SEXP refs, git_repository *repo){
  int n = Rf_length(refs);
  git_annotated_commit **commits = malloc(n);
  for(int i = 0; i < n; i++){
    bail_if(git_annotated_commit_from_revspec(&commits[i], repo, CHAR(STRING_ELT(refs, i))),
            "git_annotated_commit_from_revspec");
  }
  return commits;
}

static void free_commit_list(git_annotated_commit** commits, int n){
  for(int i = 0; i < n; i++)
    git_annotated_commit_free(commits[i]);
  free(commits);
}

SEXP R_git_merge_analysis(SEXP ptr, SEXP refs){
  int n = Rf_length(refs);
  git_repository *repo = get_git_repository(ptr);
  git_annotated_commit **commits = refs_to_git(refs, repo);
  git_merge_analysis_t analysis_out;
  git_merge_preference_t preference_out;
  int res = git_merge_analysis(&analysis_out, &preference_out, repo, (const git_annotated_commit**) commits, n);
  free_commit_list(commits, n);
  bail_if(res, "git_merge_analysis");
  return safe_string(analysis_to_str(analysis_out, preference_out));
}

SEXP R_git_merge_stage(SEXP ptr, SEXP refs){
  int n = Rf_length(refs);
  git_repository *repo = get_git_repository(ptr);
  git_annotated_commit **commits = refs_to_git(refs, repo);
  git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;
  git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;
  merge_opts.flags = 0;
  merge_opts.file_flags = GIT_MERGE_FILE_STYLE_DIFF3;
  checkout_opts.checkout_strategy = GIT_CHECKOUT_FORCE | GIT_CHECKOUT_ALLOW_CONFLICTS;
  int res = git_merge(repo, (const git_annotated_commit**) commits, n, &merge_opts, &checkout_opts);
  free_commit_list(commits, n);
  bail_if(res, "git_merge");

  /* Merge success! Now look if we had any conflicts. */
  git_index *index = NULL;
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  int conflicted = git_index_has_conflicts(index);
  git_index_free(index);
  return Rf_ScalarLogical(conflicted == 0);
}

/* Need to call cleanup both after committing or aborting a merge state */
SEXP R_git_merge_cleanup(SEXP ptr){
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_state_cleanup(repo), "git_repository_state_cleanup");
  return R_NilValue;
}

static int merge_heads_cb(const git_oid *oid, void *payload){
  SEXP vec = payload;
  int i = Rf_length(vec);
  SETLENGTH(vec, i + 1);
  SET_STRING_ELT(vec, i, safe_char(git_oid_tostr_s(oid)));
  return 0;
}

SEXP R_git_merge_parent_heads(SEXP ptr){
  git_repository *repo = get_git_repository(ptr);
  if(git_repository_state(repo) != GIT_REPOSITORY_STATE_MERGE)
    return R_NilValue;
  SEXP parents = PROTECT(Rf_allocVector(STRSXP, 0));
  git_repository_mergehead_foreach(repo, merge_heads_cb, parents);
  UNPROTECT(1);
  return parents;
}

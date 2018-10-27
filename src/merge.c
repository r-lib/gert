#include <string.h>
#include "utils.h"

/* Tries to fast forward merge (i.e. simply adding commits)
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

  /* Check analysis output */
  if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE){
    Rprintf("Already up-to-date\n");
    goto done;
  } else if(analysis & GIT_MERGE_ANALYSIS_FASTFORWARD){
    Rprintf("Performing fast forward\n");
    bail_if(git_checkout_tree(repo, revision, &opts), "git_checkout_tree");
    bail_if(git_reference_set_target(&target, head, git_object_id(revision), NULL), "git_reference_set_target");
    git_reference_free(target);
  } else {
    Rf_error("Fast forward not possible\n");
  }

done:
  git_reference_free(head);
  git_annotated_commit_free(commit);
  git_object_free(revision);
  return ptr;
}


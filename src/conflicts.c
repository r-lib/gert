#include <string.h>
#include "utils.h"

SEXP R_git_conflict_list(SEXP ptr){
  int count = 0;
  git_index *index = NULL;
  const git_index_entry *ancestor_out = NULL;
  const git_index_entry *our_out = NULL;
  const git_index_entry *their_out = NULL;
  git_index_conflict_iterator *iter = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "bail_if");
  if(git_index_has_conflicts(index)){
    bail_if(git_index_conflict_iterator_new(&iter, index), "git_index_conflict_iterator_new");
    while(!git_index_conflict_next(&ancestor_out, &our_out, &their_out, iter))
      count++;
    git_index_conflict_iterator_free(iter);
  }
  SEXP ancestor = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP our = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP their = PROTECT(Rf_allocVector(STRSXP, count));
  count = 0;
  if(git_index_has_conflicts(index)){
    bail_if(git_index_conflict_iterator_new(&iter, index), "git_index_conflict_iterator_new");
    while(!git_index_conflict_next(&ancestor_out, &our_out, &their_out, iter)){
      SET_STRING_ELT(ancestor, count, safe_char(ancestor_out->path));
      SET_STRING_ELT(our, count, safe_char(our_out->path));
      SET_STRING_ELT(their, count, safe_char(their_out->path));
      count++;
    }
    git_index_conflict_iterator_free(iter);
  }
  git_index_free(index);
  return build_tibble(3, "ancestor", ancestor, "our", our, "their", their);
}

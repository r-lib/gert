#include <string.h>
#include "utils.h"

static git_strarray *files_to_array(SEXP files){
  int len = Rf_length(files);
  git_strarray *paths = malloc(sizeof *paths);
  paths->count = len;
  paths->strings = calloc(len, sizeof *paths->strings);
  for(int i = 0; i < len; i++)
    paths->strings[i] = strdup(CHAR(STRING_ELT(files, i)));
  return paths;
}

SEXP R_git_repository_info(SEXP ptr){
  git_strarray ref_list;
  git_repository *repo = get_git_repository(ptr);

  bail_if(git_reference_list(&ref_list, repo), "git_reference_list");
  SEXP refs = PROTECT(Rf_allocVector(STRSXP, ref_list.count));
  for(int i = 0; i < ref_list.count; i++){
    SET_STRING_ELT(refs, i, Rf_mkChar(ref_list.strings[i]));
  }
  SEXP list = PROTECT(Rf_allocVector(VECSXP, 4));
  SEXP names = PROTECT(Rf_allocVector(STRSXP, Rf_length(list)));
  SET_STRING_ELT(names, 0, Rf_mkChar("path"));
  SET_STRING_ELT(names, 1, Rf_mkChar("ref"));
  SET_STRING_ELT(names, 2, Rf_mkChar("shorthand"));
  SET_STRING_ELT(names, 3, Rf_mkChar("reflist"));
  SET_VECTOR_ELT(list, 0, safe_string(git_repository_workdir(repo)));

  git_reference *head = NULL;
  if(git_repository_head(&head, repo) == 0){
    SET_VECTOR_ELT(list, 1, safe_string(git_reference_name(head)));
    SET_VECTOR_ELT(list, 2, safe_string(git_reference_shorthand(head)));
  } else {
    SET_VECTOR_ELT(list, 1, Rf_ScalarString(NA_STRING));
    SET_VECTOR_ELT(list, 2, Rf_ScalarString(NA_STRING));
  }
  SET_VECTOR_ELT(list, 3, refs);
  Rf_setAttrib(list, R_NamesSymbol, names);
  UNPROTECT(3);
  git_reference_free(head);
  git_strarray_free(&ref_list);
  return list;
}

SEXP R_git_repository_ls(SEXP ptr){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");

  size_t entry_count = git_index_entrycount(index);
  SEXP paths = PROTECT(Rf_allocVector(STRSXP, entry_count));
  SEXP sizes = PROTECT(Rf_allocVector(REALSXP, entry_count));
  SEXP mtimes = PROTECT(Rf_allocVector(REALSXP, entry_count));

  for(size_t i = 0; i < entry_count; i++){
    const git_index_entry *entry = git_index_get_byindex(index, i);
    git_index_time timeval = entry->mtime;
    SET_STRING_ELT(paths, i, safe_char(entry->path));
    REAL(sizes)[i] = (double) entry->file_size;
    REAL(mtimes)[i] = (double) timeval.seconds + timeval.nanoseconds * 1e-9;
  }
  git_index_free(index);
  return make_tibble_and_unprotect(3, "path", paths, "filesize", sizes, "mtime", mtimes);
}

SEXP R_git_repository_add(SEXP ptr, SEXP files, SEXP force){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  git_strarray *paths = files_to_array(files);
  git_index_add_option_t flags = Rf_asLogical(force) ? GIT_INDEX_ADD_FORCE : GIT_INDEX_ADD_DEFAULT;
  bail_if(git_index_add_all(index, paths, flags, NULL, NULL), "git_index_add_bypath");
  bail_if(git_index_write(index), "git_index_write");
  git_strarray_free(paths);
  git_index_free(index);
  return ptr;
}

SEXP R_git_repository_rm(SEXP ptr, SEXP files){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  git_strarray *paths = files_to_array(files);
  bail_if(git_index_remove_all(index, paths, NULL, NULL), "git_index_remove_all");
  bail_if(git_index_write(index), "git_index_write");
  git_strarray_free(paths);
  git_index_free(index);
  return ptr;
}


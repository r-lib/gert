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
  for(int i = 0; i < ref_list.count; i++)
    SET_STRING_ELT(refs, i, Rf_mkChar(ref_list.strings[i]));
  git_strarray_free(&ref_list);
  SEXP path = PROTECT(safe_string(git_repository_workdir(repo)));
  git_reference *head = NULL;
  int err = git_repository_head(&head, repo) == 0;
  SEXP headref = PROTECT(safe_string(err ? git_reference_name(head) : NULL));
  SEXP shorthand = PROTECT(safe_string(err ? git_reference_shorthand(head) : NULL));
  git_reference_free(head);
  return build_list(4, "path", path, "head", headref, "shorthand", shorthand, "reflist", refs);
}

SEXP R_git_repository_ls(SEXP ptr){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");

  size_t entry_count = git_index_entrycount(index);
  SEXP paths = PROTECT(Rf_allocVector(STRSXP, entry_count));
  SEXP sizes = PROTECT(Rf_allocVector(REALSXP, entry_count));
  SEXP mtimes = PROTECT(Rf_allocVector(REALSXP, entry_count));
  SEXP ctimes = PROTECT(Rf_allocVector(REALSXP, entry_count));

  for(size_t i = 0; i < entry_count; i++){
    const git_index_entry *entry = git_index_get_byindex(index, i);
    SET_STRING_ELT(paths, i, safe_char(entry->path));
    REAL(sizes)[i] = (double) entry->file_size;
    REAL(mtimes)[i] = (double) entry->mtime.seconds + entry->mtime.nanoseconds * 1e-9;
    REAL(ctimes)[i] = (double) entry->ctime.seconds + entry->ctime.nanoseconds * 1e-9;
  }
  git_index_free(index);
  Rf_setAttrib(mtimes, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  Rf_setAttrib(ctimes, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  return build_tibble(4, "path", paths, "filesize", sizes, "modified", mtimes, "created", ctimes);
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

static SEXP status_string(git_status_t status){
  if (status & (GIT_STATUS_WT_NEW))
    return safe_char("untracked");
  if (status & (GIT_STATUS_INDEX_NEW))
    return safe_char("new");
  if (status & (GIT_STATUS_WT_MODIFIED | GIT_STATUS_INDEX_MODIFIED))
    return safe_char("modified");
  if (status & (GIT_STATUS_WT_DELETED | GIT_STATUS_INDEX_DELETED))
    return safe_char("deleted");
  if (status & (GIT_STATUS_WT_RENAMED | GIT_STATUS_INDEX_RENAMED))
    return safe_char("renamed");
  if (status & (GIT_STATUS_WT_TYPECHANGE | GIT_STATUS_INDEX_TYPECHANGE))
    return safe_char("typehange");
  if (status & (GIT_STATUS_IGNORED))
    return safe_char("ignored");
  return safe_char("");
}

static SEXP guess_path(const git_status_entry *file){
  if(file->index_to_workdir){
    if(file->index_to_workdir->new_file.path)
      return safe_char(file->index_to_workdir->new_file.path);
    if(file->index_to_workdir->old_file.path)
      return safe_char(file->index_to_workdir->old_file.path);
  }
  if(file->head_to_index){
    if(file->head_to_index->new_file.path)
      return safe_char(file->head_to_index->new_file.path);
    if(file->head_to_index->old_file.path)
      return safe_char(file->head_to_index->new_file.path);
  }
  return safe_char(NULL);
}

/* See https://github.com/libgit2/libgit2/blob/master/examples/status.c
 * And https://libgit2.org/libgit2/#HEAD/type/git_status_opt_t
 * Todo: perhaps this is a bit overly simplified...
 */
SEXP R_git_status_list(SEXP ptr){
  git_status_list *list = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_status_options opts = GIT_STATUS_OPTIONS_INIT;
  opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
  opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
    GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
    GIT_STATUS_OPT_SORT_CASE_SENSITIVELY;
  bail_if(git_status_list_new(&list, repo, &opts), "git_status_list_new");
  size_t len = git_status_list_entrycount(list);
  SEXP files = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP status = PROTECT(Rf_allocVector(STRSXP, len));
  for(size_t i = 0; i < len; i++){
    const git_status_entry *file = git_status_byindex(list, i);
    if(file == NULL)
      continue;
    SET_STRING_ELT(files, i, guess_path(file));
    SET_STRING_ELT(status, i, status_string(file->status));
  }
  git_status_list_free(list);
  return build_tibble(2, "file", files, "status", status);
}

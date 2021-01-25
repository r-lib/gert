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
  git_buf buf = {0};
  git_strarray ref_list;
  git_reference *ref_upstream = NULL;
  git_repository *repo = get_git_repository(ptr);

  bail_if(git_reference_list(&ref_list, repo), "git_reference_list");

  SEXP refs = PROTECT(Rf_allocVector(STRSXP, ref_list.count));
  for(int i = 0; i < ref_list.count; i++)
    SET_STRING_ELT(refs, i, Rf_mkChar(ref_list.strings[i]));
  git_strarray_free(&ref_list);

  int is_bare = git_repository_is_bare(repo);

  SEXP bare = PROTECT(Rf_ScalarLogical(is_bare));
  SEXP path = PROTECT(safe_string(
    is_bare ? git_repository_path(repo) : git_repository_workdir(repo)
  ));
  SEXP headref = PROTECT(safe_string(NULL));
  SEXP shorthand = PROTECT(safe_string(NULL));
  SEXP target = PROTECT(safe_string(NULL));
  SEXP upstream = PROTECT(safe_string(NULL));
  SEXP remote = PROTECT(safe_string(NULL));

  git_reference *head = NULL;
  if(git_repository_head(&head, repo) == 0){
    SET_STRING_ELT(headref, 0, safe_char(git_reference_name(head)));
    SET_STRING_ELT(shorthand, 0, safe_char(git_reference_shorthand(head)));
    SET_STRING_ELT(target, 0, safe_char(git_oid_tostr_s(git_reference_target(head))));
    if(git_branch_upstream(&ref_upstream, head) == 0){
      SET_STRING_ELT(upstream, 0, safe_char(git_reference_shorthand(ref_upstream)));
      if(git_branch_remote_name(&buf, repo, git_reference_name(ref_upstream)) == 0){
        SET_STRING_ELT(remote, 0, safe_char(buf.ptr));
        git_buf_free(&buf);
      }
    }
    git_reference_free(head);
  }

  SEXP out = build_list(8, "path", path, "bare", bare, "head", headref, "shorthand", shorthand,
                    "commit", target, "remote", remote, "upstream", upstream, "reflist", refs);
  UNPROTECT(8);
  return out;
}

SEXP R_git_repository_path(SEXP ptr){
  git_repository *repo = get_git_repository(ptr);
  return safe_string(
    git_repository_is_bare(repo) ? git_repository_path(repo) : git_repository_workdir(repo)
  );
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
  SEXP out = build_tibble(4, "path", paths, "filesize", sizes, "modified", mtimes, "created", ctimes);
  UNPROTECT(4);
  return out;
}

SEXP R_git_repository_add(SEXP ptr, SEXP files, SEXP force){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  git_strarray *paths = files_to_array(files);
  git_index_add_option_t flags = Rf_asLogical(force) ? GIT_INDEX_ADD_FORCE : GIT_INDEX_ADD_DEFAULT;
  bail_if(git_index_add_all(index, paths, flags, NULL, NULL), "git_index_add_all");
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


/* See https://github.com/libgit2/libgit2/blob/master/examples/status.c
 * And https://libgit2.org/libgit2/#HEAD/type/git_status_opt_t
 */

static const char *guess_filename(git_diff_delta *diff){
  if(diff && diff->new_file.path)
    return diff->new_file.path;
  if(diff && diff->old_file.path)
    return diff->old_file.path;
  return NULL;
}

static void extract_entry_data(const git_status_entry *file, char *status, char *filename, int *isstaged){
  if(file == NULL)
    return;
  git_status_t s = file->status;
  if(s & (GIT_STATUS_INDEX_DELETED | GIT_STATUS_INDEX_MODIFIED | GIT_STATUS_INDEX_NEW | GIT_STATUS_INDEX_RENAMED | GIT_STATUS_INDEX_TYPECHANGE)){
    strcpy(filename, guess_filename(file->head_to_index));
    *isstaged = 1;
    if(s & GIT_STATUS_INDEX_NEW){
      strcpy(status, "new");
    } else if(s & GIT_STATUS_INDEX_MODIFIED){
      strcpy(status, "modified");
    } else if(s & GIT_STATUS_INDEX_RENAMED){
      strcpy(status, "renamed");
    } else if(s & GIT_STATUS_INDEX_TYPECHANGE){
      strcpy(status, "typechange");
    } else if(s & GIT_STATUS_INDEX_DELETED){
      strcpy(status, "deleted");
    }
  } else if(s & (GIT_STATUS_WT_DELETED | GIT_STATUS_WT_MODIFIED | GIT_STATUS_WT_NEW | GIT_STATUS_WT_RENAMED | GIT_STATUS_WT_TYPECHANGE | GIT_STATUS_CONFLICTED)){
    strcpy(filename, guess_filename(file->index_to_workdir));
    *isstaged = 0;
    if(s & GIT_STATUS_WT_NEW){
      strcpy(status, "new");
    } else if(s & GIT_STATUS_WT_MODIFIED){
      strcpy(status, "modified");
    } else if(s & GIT_STATUS_WT_RENAMED){
      strcpy(status, "renamed");
    } else if(s & GIT_STATUS_WT_TYPECHANGE){
      strcpy(status, "typechange");
    } else if(s & GIT_STATUS_WT_DELETED){
      strcpy(status, "deleted");
    } else if(s &  GIT_STATUS_CONFLICTED){
      strcpy(status, "conflicted");
    }
  }
}

SEXP R_git_status_list(SEXP ptr, SEXP show_staged){
  git_status_list *list = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_status_options opts = GIT_STATUS_OPTIONS_INIT;
  if(!Rf_length(show_staged) || Rf_asLogical(show_staged) == NA_LOGICAL){
    opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
  } else {
    opts.show = Rf_asLogical(show_staged) ? GIT_STATUS_SHOW_INDEX_ONLY : GIT_STATUS_SHOW_WORKDIR_ONLY;
  }
  opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
    GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
    GIT_STATUS_OPT_SORT_CASE_SENSITIVELY;
  bail_if(git_status_list_new(&list, repo, &opts), "git_status_list_new");
  size_t len = git_status_list_entrycount(list);
  SEXP files = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP statuses = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP staged = PROTECT(Rf_allocVector(LGLSXP, len));
  for(size_t i = 0; i < len; i++){
    char status[100] = "";
    char filename[4000] = "";
    int isstaged = NA_LOGICAL;
    extract_entry_data(git_status_byindex(list, i), status, filename, &isstaged);
    SET_STRING_ELT(files, i, safe_char(filename));
    SET_STRING_ELT(statuses, i, safe_char(status));
    LOGICAL(staged)[i] = isstaged;
  }
  git_status_list_free(list);
  SEXP out = build_tibble(3, "file", files, "status", statuses, "staged", staged);
  UNPROTECT(3);
  return out;
}

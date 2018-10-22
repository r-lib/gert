#include <string.h>
#include "utils.h"

#define print_if_verbose(...) print_log(verbose, __VA_ARGS__)

typedef struct {
  int verbose;
  int retries;
  SEXP getkey;
  SEXP askpass;
} auth_callback_data;

typedef struct {
  const char *key_path;
  const char *pubkey_path;
  const char *pass_phrase;
} auth_key_data;

static void print_log(int verbose, const char *fmt, ...){
  if(verbose){
    va_list args;
    va_start(args, fmt);
    REvprintf(fmt, args);
    va_end(args);
  }
}

static const char *session_keyphrase(const char *set){
  static char *key;
  if(set){
    key = strdup(set);
    return NULL;
  }
  return key;
}

static const char *prompt_user_password(SEXP rpass, const char *prompt){
  if(Rf_isString(rpass) && Rf_length(rpass)) {
    return CHAR(STRING_ELT(rpass, 0));
  } else if(Rf_isFunction(rpass)){
    int err;
    SEXP call = PROTECT(Rf_lcons(rpass, Rf_lcons(safe_string(prompt), R_NilValue)));
    SEXP res = PROTECT(R_tryEval(call, R_GlobalEnv, &err));
    if(err || !Rf_isString(res)){
      UNPROTECT(2);
      return NULL;
    }
    return CHAR(STRING_ELT(res, 0));
  } //should never happen
  Rf_errorcall(R_NilValue, "unsupported password type (must be string or function)");
}

static const auth_key_data *get_key_files(SEXP cb, auth_key_data *out){
  if(!Rf_isFunction(cb))
    Rf_error("cb must be a function");
  int err;
  SEXP call = PROTECT(Rf_lcons(cb, R_NilValue));
  SEXP res = PROTECT(R_tryEval(call, R_GlobalEnv, &err));
  if(err || !Rf_isString(res)){
    UNPROTECT(2);
    return NULL;
  }
  /* Todo: Maybe strdup() in case res gets collected */
  out->pubkey_path = CHAR(STRING_ELT(res, 0));
  out->key_path = CHAR(STRING_ELT(res, 1));
  out->pass_phrase = CHAR(STRING_ELT(res, 2));
  UNPROTECT(2);
  return out;
}

static void fin_git_repository(SEXP ptr){
  if(!R_ExternalPtrAddr(ptr)) return;
  git_repository_free(R_ExternalPtrAddr(ptr));
  R_ClearExternalPtr(ptr);
}

static SEXP new_git_repository(git_repository *repo){
  SEXP ptr = PROTECT(R_MakeExternalPtr(repo, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, fin_git_repository, 1);
  Rf_setAttrib(ptr, R_ClassSymbol, Rf_mkString("git_repository"));
  UNPROTECT(1);
  return ptr;
}

static git_repository *get_git_repository(SEXP ptr){
  if(TYPEOF(ptr) != EXTPTRSXP || !Rf_inherits(ptr, "git_repository"))
    Rf_error("handle is not a git_repository");
  if(!R_ExternalPtrAddr(ptr))
    Rf_error("pointer is dead");
  return R_ExternalPtrAddr(ptr);
}

static int fetch_progress(const git_transfer_progress *stats, void *payload){
  R_CheckUserInterrupt();
  unsigned int tot = stats->total_objects;
  unsigned int cur = stats->received_objects;
  static size_t prev = 0;
  if(prev != cur){
    prev = cur;
    REprintf("\rReceived %d of %d objects...", cur, tot);
    if(cur == tot)
      REprintf("done!\n");
  }
  return 0;
}

static void checkout_progress(const char *path, size_t cur, size_t tot, void *payload){
  R_CheckUserInterrupt();
  static size_t prev = 0;
  if(prev != cur){
    prev = cur;
    REprintf("\rChecked out %d of %d commits...", cur, tot);
    if(cur == tot)
      REprintf(" done!\n");
  }
}

/* Examples: https://github.com/libgit2/libgit2/blob/master/tests/online/clone.c */
static int auth_callback(git_cred **cred, const char *url, const char *username,
                               unsigned int allowed_types, void *payload){
  /* First get a username */
  auth_callback_data *cb_data = payload;
  const char * ssh_user = username ? username : "git";
  int verbose = cb_data->verbose;

#if AT_LEAST_LIBGIT2(0, 20)

  /* This is for SSH remotes */
  if(allowed_types & GIT_CREDTYPE_SSH_KEY){
    // First try the ssh agent
    if(cb_data->retries == 0){
      cb_data->retries++;
      if(git_cred_ssh_key_from_agent(cred, ssh_user) == 0){
        print_if_verbose("Trying to authenticate '%s' using ssh-agent...\n", ssh_user);
        return 0;
      } else {
        print_if_verbose("Failed to connect to ssh-agent: %s\n", giterr_last()->message);
      }
    }
    // Second try is with the user provided key
    if(cb_data->retries == 1) {
      cb_data->retries++;
      auth_key_data data;
      const auth_key_data *key_data = get_key_files(cb_data->getkey, &data);
      if(key_data && !git_cred_ssh_key_new(cred, ssh_user, key_data->pubkey_path,
                                                 key_data->key_path, key_data->pass_phrase)){
        print_if_verbose("Trying to authenticate '%s' using provided ssh-key...\n", ssh_user);
        return 0;
      } else {
        print_if_verbose("Failed to load ssh-key: %s\n", giterr_last()->message);
      }
    }

    // Third is just bail with an error
    if(cb_data->retries == 2) {
      print_if_verbose("Failed to authenticate over SSH. You either need to provide a key or setup ssh-agent\n");
      if(strcmp(ssh_user, "git"))
        print_if_verbose("Are you sure ssh address has username '%s'? (ssh remotes usually have username 'git')\n", ssh_user);
      return GIT_EUSER;
    }
  }

#endif

  /* This is for HTTP remotes */
  if(allowed_types & GIT_CREDTYPE_USERPASS_PLAINTEXT){
    if(cb_data->retries > 2){
      print_if_verbose("Failed password authentiation %d times. Giving up\n", cb_data->retries);
      cb_data->retries = 0;
    } else {
      cb_data->retries++;
      if(username == NULL)
        username = prompt_user_password(cb_data->askpass, "Please enter USERNAME");
      if(!username)
        goto cred_fail;
      print_if_verbose("Trying plaintext auth for user '%s' (attempt #%d)\n", username, cb_data->retries);
      char buf[1000];
      snprintf(buf, 999, "Enter PASSWORD or PAT for user '%s'", username);
      const char *pass = prompt_user_password(cb_data->askpass, buf);
      if(!pass)
        goto cred_fail;
      return git_cred_userpass_plaintext_new(cred, username, pass);
    }
  }

cred_fail:
  print_if_verbose("All authentication methods failed\n");
  return GIT_EUSER;
}

static git_strarray *files_to_array(SEXP files){
  int len = Rf_length(files);
  git_strarray *paths = malloc(sizeof *paths);
  paths->count = len;
  paths->strings = calloc(len, sizeof *paths->strings);
  for(int i = 0; i < len; i++)
    paths->strings[i] = strdup(CHAR(STRING_ELT(files, i)));
  return paths;
}

static void free_file_array(git_strarray *paths){
  for(int i = 0; i < paths->count; i++)
    free(paths->strings[i]);
  free(paths);
}

SEXP R_git_repository_init(SEXP path){
  git_repository *repo = NULL;
  bail_if(git_repository_init(&repo, CHAR(STRING_ELT(path, 0)), 0), "git_repository_init");
  return new_git_repository(repo);
}

SEXP R_git_repository_open(SEXP path){
  git_repository *repo = NULL;
  bail_if(git_repository_open(&repo, CHAR(STRING_ELT(path, 0))), "git_repository_open");
  return new_git_repository(repo);
}

SEXP R_git_repository_clone(SEXP url, SEXP path, SEXP branch, SEXP getkey, SEXP askpass, SEXP verbose){
  git_repository *repo = NULL;
  git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;
  clone_opts.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE;

#if AT_LEAST_LIBGIT2(0, 23)
    auth_callback_data data_cb;
    data_cb.verbose = Rf_asLogical(verbose);
    data_cb.retries = 0;
    data_cb.askpass = askpass;
    data_cb.getkey = getkey;
    clone_opts.fetch_opts.callbacks.payload = &data_cb;
    clone_opts.fetch_opts.callbacks.credentials = auth_callback;
#endif

  /* Enables download progress and user interrupt */
  if(Rf_asLogical(verbose)){
    clone_opts.checkout_opts.progress_cb = checkout_progress;
    clone_opts.fetch_opts.callbacks.transfer_progress = fetch_progress;
  }

  /* specify branch to checkout */
  if(Rf_length(branch))
    clone_opts.checkout_branch = CHAR(STRING_ELT(branch, 0));

  /* try to clone */
  bail_if(git_clone(&repo, CHAR(STRING_ELT(url, 0)), CHAR(STRING_ELT(path, 0)),
                    &clone_opts), "git_clone");
  bail_if_null(repo, "failed to clone repo");
  return new_git_repository(repo);
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
  SEXP df = PROTECT(Rf_allocVector(VECSXP, 3));
  SET_VECTOR_ELT(df, 0, paths);
  SET_VECTOR_ELT(df, 1, sizes);
  SET_VECTOR_ELT(df, 2, mtimes);
  UNPROTECT(4);
  return df;
}

SEXP R_git_repository_add(SEXP ptr, SEXP files, SEXP force){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  git_strarray *paths = files_to_array(files);
  git_index_add_option_t flags = Rf_asLogical(force) ? GIT_INDEX_ADD_FORCE : GIT_INDEX_ADD_DEFAULT;
  bail_if(git_index_add_all(index, paths, flags, NULL, NULL), "git_index_add_bypath");
  bail_if(git_index_write(index), "git_index_write");
  free_file_array(paths);
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
  free_file_array(paths);
  git_index_free(index);
  return ptr;
}

SEXP R_git_checkout(SEXP ptr, SEXP ref, SEXP force){
  git_repository *repo = get_git_repository(ptr);

  /* Set checkout options */
#if AT_LEAST_LIBGIT2(0, 21)
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
#else
  git_checkout_opts opts = GIT_CHECKOUT_OPTS_INIT;
#endif
  opts.checkout_strategy = Rf_asLogical(force) ? GIT_CHECKOUT_FORCE : GIT_CHECKOUT_SAFE;

  /* Parse the branch/tag/ref string */
  git_object *treeish = NULL;
  const char *refstring = CHAR(STRING_ELT(ref, 0));
  bail_if(git_revparse_single(&treeish, repo, refstring), "git_revparse_single");
  bail_if(git_checkout_tree(repo, treeish, &opts), "git_checkout_tree");
  git_object_free(treeish);
  return ptr;
}

static SEXP make_refspecs(git_remote *remote){
  int size = git_remote_refspec_count(remote);
  SEXP out = PROTECT(Rf_allocVector(STRSXP, size));
  for(int i = 0; i < size; i++){
    SET_STRING_ELT(out, i, safe_char(git_refspec_string(git_remote_get_refspec(remote, i))));
  }
  UNPROTECT(1);
  return out;
}

SEXP R_git_remotes_list(SEXP ptr){
  git_strarray remotes = {0};
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_list(&remotes, repo), "git_remote_list");
  SEXP names = PROTECT(Rf_allocVector(STRSXP, remotes.count));
  SEXP url = PROTECT(Rf_allocVector(STRSXP, remotes.count));
  SEXP refspecs = PROTECT(Rf_allocVector(VECSXP, remotes.count));
  for(int i = 0; i < remotes.count; i++){
    git_remote *remote = NULL;
    char *name = remotes.strings[i];
    SET_STRING_ELT(names, i, safe_char(name));
    if(!git_remote_lookup(&remote, repo, name)){
      SET_STRING_ELT(url, i, safe_char(git_remote_url(remote)));
      SET_VECTOR_ELT(refspecs, i, make_refspecs(remote));
      git_remote_free(remote);
    }
    free(name);
  }
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 3));
  SET_VECTOR_ELT(out, 0, names);
  SET_VECTOR_ELT(out, 1, url);
  SET_VECTOR_ELT(out, 2, refspecs);
  UNPROTECT(4);
  return out;
}

SEXP R_git_remote_fetch(SEXP ptr, SEXP name, SEXP refspecs){
#if AT_LEAST_LIBGIT2(0, 23)
  git_remote *remote = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_lookup(&remote, repo, CHAR(STRING_ELT(name, 0))), "git_remote_lookup");
  git_strarray *refs = files_to_array(refspecs);
  git_fetch_options opts = GIT_FETCH_OPTIONS_INIT;
  opts.callbacks.transfer_progress = fetch_progress;
  bail_if(git_remote_fetch(remote, refs, &opts, NULL), "git_remote_fetch");
  git_remote_free(remote);
  free_file_array(refs);
  return ptr;
#else
  Rf_error("git_remote_fetch requires at least libgit2 v0.23");
#endif
}

SEXP R_set_session_keyphrase(SEXP key){
  if(!Rf_length(key) || !Rf_isString(key))
    Rf_error("Need to pass a string");
  session_keyphrase(CHAR(STRING_ELT(key, 0)));
  return R_NilValue;
}

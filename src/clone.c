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
  Rf_setAttrib(ptr, R_ClassSymbol, Rf_mkString("git_repo_ptr"));
  UNPROTECT(1);
  return ptr;
}

git_repository *get_git_repository(SEXP ptr){
  if(TYPEOF(ptr) != EXTPTRSXP || !Rf_inherits(ptr, "git_repo_ptr"))
    Rf_error("handle is not a git_repo_ptr");
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

/* We only want to send the PAT to Github */
static int url_is_github(const char *url, const char *user){
  if(url == NULL)
    return 0;
  if(strstr(url, "http://github.com") == url)
    return 1;
  if(strstr(url, "https://github.com") == url)
    return 1;
  if(user){
    char buf[4000];
    snprintf(buf, 3999, "http://%s@github.com", user);
    if(strstr(url, buf) == url)
      return 1;
    snprintf(buf, 3999, "https://%s@github.com", user);
    if(strstr(url, buf) == url)
      return 1;
  }
  return 0;
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
      if(getenv("SSH_AUTH_SOCK")){
        if(git_cred_ssh_key_from_agent(cred, ssh_user) == 0){
          print_if_verbose("Trying to authenticate '%s' using ssh-agent...\n", ssh_user);
          return 0;
        } else {
          print_if_verbose("Failed to connect to ssh-agent: %s\n", giterr_last()->message);
        }
      } else {
        print_if_verbose("Unable to find ssh-agent (SSH_AUTH_SOCK undefined)\n");
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
    if(cb_data->retries > 3){
      print_if_verbose("Failed password authentiation %d times. Giving up\n", cb_data->retries);
      cb_data->retries = 0;
    } else {
      if(cb_data->retries == 0){
        cb_data->retries++;
        if(url_is_github(url, username) && getenv("GITHUB_PAT")){
          print_if_verbose("Trying to authenticate with your GITHUB_PAT\n");
          return git_cred_userpass_plaintext_new(cred, "git", getenv("GITHUB_PAT"));
        }
      }
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

    /* Enables download progress and user interrupt */
    if(Rf_asLogical(verbose)){
      clone_opts.checkout_opts.progress_cb = checkout_progress;
      clone_opts.fetch_opts.callbacks.transfer_progress = fetch_progress;
    }

#endif

  /* specify branch to checkout */
  if(Rf_length(branch))
    clone_opts.checkout_branch = CHAR(STRING_ELT(branch, 0));

  /* try to clone */
  bail_if(git_clone(&repo, CHAR(STRING_ELT(url, 0)), CHAR(STRING_ELT(path, 0)),
                    &clone_opts), "git_clone");
  bail_if_null(repo, "failed to clone repo");
  return new_git_repository(repo);
}

/* From: https://github.com/libgit2/libgit2/blob/master/examples/network/fetch.c */
static int update_cb(const char *refname, const git_oid *a, const git_oid *b, void *data){
  char a_str[GIT_OID_HEXSZ+1], b_str[GIT_OID_HEXSZ+1];
  git_oid_fmt(b_str, b);
  b_str[GIT_OID_HEXSZ] = '\0';
  if (git_oid_iszero(a)) {
    Rprintf("[new]     %.20s %s\n", b_str, refname);
  } else {
    git_oid_fmt(a_str, a);
    a_str[GIT_OID_HEXSZ] = '\0';
    Rprintf("[updated] %.10s..%.10s %s\n", a_str, b_str, refname);
  }
  return 0;
}

SEXP R_git_remote_fetch(SEXP ptr, SEXP name, SEXP refspec){
  git_remote *remote = NULL;
  git_repository *repo = get_git_repository(ptr);
  if(git_remote_lookup(&remote, repo, CHAR(STRING_ELT(name, 0))) < 0){
    if(git_remote_create_anonymous(&remote, repo, CHAR(STRING_ELT(name, 0))) < 0)
      Rf_error("Remote must either be an existing remote or URL");
  }
  git_strarray *rs = Rf_length(refspec) ? files_to_array(refspec) : NULL;
  git_fetch_options opts = GIT_FETCH_OPTIONS_INIT;
  opts.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_ALL;
  opts.update_fetchhead = 1;
  opts.callbacks.transfer_progress = fetch_progress;
  opts.callbacks.update_tips = &update_cb;
  bail_if(git_remote_fetch(remote, rs, &opts, NULL), "git_remote_fetch");
  git_remote_free(remote);
  return ptr;
}

SEXP R_set_session_keyphrase(SEXP key){
  if(!Rf_length(key) || !Rf_isString(key))
    Rf_error("Need to pass a string");
  session_keyphrase(CHAR(STRING_ELT(key, 0)));
  return R_NilValue;
}

#include <string.h>
#include "utils.h"

SEXP R_git_stash_save(SEXP ptr, SEXP message, SEXP keep_index,
                      SEXP include_untracked, SEXP include_ignored){
  git_oid out;
  git_signature *me;
  git_repository *repo = get_git_repository(ptr);
  const char *msg = Rf_translateCharUTF8(STRING_ELT(message, 0));
  bail_if(git_signature_default(&me, repo), "git_signature_default");
  git_stash_flags flags = GIT_STASH_DEFAULT;
  flags += Rf_asLogical(keep_index) * GIT_STASH_KEEP_INDEX;
  flags += Rf_asLogical(include_untracked) * GIT_STASH_INCLUDE_UNTRACKED;
  flags += Rf_asLogical(include_ignored) * GIT_STASH_INCLUDE_IGNORED;
  bail_if(git_stash_save(&out, repo, me, msg, flags), "git_stash_save");
  return safe_string(git_oid_tostr_s(&out));
}


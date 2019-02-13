#include <string.h>
#include "utils.h"

SEXP R_git_tag_list(SEXP ptr, SEXP pattern){
  git_repository *repo = get_git_repository(ptr);
  git_strarray tag_list;
  bail_if(git_tag_list_match(&tag_list, CHAR(STRING_ELT(pattern, 0)), repo), "git_tag_list");
  SEXP names = PROTECT(Rf_allocVector(STRSXP, tag_list.count));
  SEXP refs = PROTECT(Rf_allocVector(STRSXP, tag_list.count));
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, tag_list.count));
  for(int i = 0; i < tag_list.count; i++){
    git_oid oid;
    char refstr[1000];
    snprintf(refstr, 999, "refs/tags/%s", tag_list.strings[i]);
    SET_STRING_ELT(names, i, safe_char(tag_list.strings[i]));
    SET_STRING_ELT(refs, i, safe_char(refstr));
    if(git_reference_name_to_id(&oid, repo, refstr) == 0)
      SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(&oid)));
  }
  git_strarray_free(&tag_list);
  return build_tibble(3, "name", names, "ref", refs, "commit", ids);
}

SEXP R_git_tag_create(SEXP ptr, SEXP name, SEXP message, SEXP ref){
  git_oid tag = {0};
  git_signature *me = NULL;
  git_object *revision = NULL;
  const char *cname = CHAR(STRING_ELT(name, 0));
  const char *cmsg = CHAR(STRING_ELT(message, 0));
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_signature_default(&me, repo), "git_signature_default");
  bail_if(git_revparse_single(&revision, repo, CHAR(STRING_ELT(ref, 0))), "git_revparse_single");
  bail_if(git_tag_create(&tag, repo, cname, revision, me, cmsg, 0), "git_tag_create");
  git_signature_free(me);
  git_object_free(revision);
  return safe_string(git_oid_tostr_s(&tag));
}

#include "utils.h"

static int count_config_iter(git_config *cfg){
  int count = 0;
  git_config_entry *entry = NULL;
  git_config_iterator *iter = NULL;
  bail_if(git_config_iterator_new(&iter, cfg), "git_config_iterator_new");
  while (git_config_next(&entry, iter) == 0)
    count++;
  git_config_iterator_free(iter);
  return count;
}

SEXP R_git_config_list(SEXP ptr){
  git_config_iterator *iter = NULL;
  git_config_entry *entry = NULL;
  git_config *cfg = NULL;
  if(Rf_isNull(ptr)) {
    bail_if(git_config_open_default(&cfg), "git_config_open_default");
  } else {
    bail_if(git_repository_config(&cfg, get_git_repository(ptr)),"git_repository_config");
  }
  int count = count_config_iter(cfg);
  SEXP names = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP values = PROTECT(Rf_allocVector(STRSXP, count));
  int i = 0;
  bail_if(git_config_iterator_new(&iter, cfg), "git_config_iterator_new");
  while (git_config_next(&entry, iter) == 0) {
    SET_STRING_ELT(names, i, safe_char(entry->name));
    SET_STRING_ELT(values, i, safe_char(entry->value));
    i++;
  }
  git_config_iterator_free(iter);
  git_config_free(cfg);
  return build_tibble(2, "name", names, "value", values);
}

SEXP R_git_config_set(SEXP ptr, SEXP name, SEXP value){
  double val;
  git_config *cfg = NULL;
  const char *cname = CHAR(STRING_ELT(name, 0));
  if(Rf_isNull(ptr)) {
    bail_if(git_config_open_default(&cfg), "git_config_open_default");
  } else {
    bail_if(git_repository_config(&cfg, get_git_repository(ptr)),"git_repository_config");
  }
  switch(TYPEOF(value)){
    case STRSXP:
      bail_if(git_config_set_string(cfg, cname, CHAR(STRING_ELT(value, 0))), "git_config_set_string");
      break;
    case LGLSXP:
      bail_if(git_config_set_bool(cfg, cname, Rf_asLogical(value)), "git_config_set_bool");
      break;
    case INTSXP:
      bail_if(git_config_set_int32(cfg, cname, Rf_asInteger(value)), "git_config_set_int32");
      break;
    case REALSXP:
      val = Rf_asReal(value);
      if(val <= INT_MAX){
        bail_if(git_config_set_int32(cfg, cname, (int32_t) val), "git_config_set_int32");
      } else {
        bail_if(git_config_set_int64(cfg, cname, (int64_t) val), "git_config_set_int64");
      }
      break;
    case NILSXP:
      bail_if(git_config_delete_entry(cfg, cname), "git_config_delete_entry");
      break;
    default:
      Rf_error("Option value must be string, boolean, number, or NULL");
  }
  return R_NilValue;
}

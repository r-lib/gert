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

static const char *level2string(int level){
  static char *programdata = "programdata";
  static char *system = "system";
  static char *xdg = "xdg";
  static char *global = "global";
  static char *local = "local";
  static char *app = "app";
  static char *highest = "highest";
  static char *unknown = "unknown";
  switch(level){
  case GIT_CONFIG_LEVEL_PROGRAMDATA:
    return programdata;
  case GIT_CONFIG_LEVEL_SYSTEM:
    return system;
  case GIT_CONFIG_LEVEL_XDG:
    return xdg;
  case GIT_CONFIG_LEVEL_GLOBAL:
    return global;
  case GIT_CONFIG_LEVEL_LOCAL:
    return local;
  case GIT_CONFIG_LEVEL_APP:
    return app;
  case GIT_CONFIG_HIGHEST_LEVEL:
    return highest;
  }
  return unknown;
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
  SEXP levels = PROTECT(Rf_allocVector(STRSXP, count));
  int i = 0;
  bail_if(git_config_iterator_new(&iter, cfg), "git_config_iterator_new");
  while (git_config_next(&entry, iter) == 0) {
    SET_STRING_ELT(names, i, safe_char(entry->name));
    SET_STRING_ELT(values, i, safe_char(entry->value));
    SET_STRING_ELT(levels, i, safe_char(level2string(entry->level)));
    i++;
  }
  git_config_iterator_free(iter);
  git_config_free(cfg);
  SEXP out = build_tibble(3, "name", names, "value", values, "level", levels);
  UNPROTECT(3);
  return out;
}

SEXP R_git_config_set(SEXP ptr, SEXP name, SEXP value){
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
      //NB: gets stored as string anyway
      bail_if(git_config_set_int64(cfg, cname, (int64_t) Rf_asReal(value)), "git_config_set_int64");
      break;
    case NILSXP:
      bail_if(git_config_delete_entry(cfg, cname), "git_config_delete_entry");
      break;
    default:
      Rf_error("Option value must be string, boolean, number, or NULL");
  }
  git_config_free(cfg);
  return R_NilValue;
}

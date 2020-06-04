#include "utils.h"

void bail_if(int err, const char *what){
  if (err) {
    const git_error *info = giterr_last();
    SEXP code = PROTECT(Rf_ScalarInteger(err));
    SEXP kclass = PROTECT(Rf_ScalarInteger(info ? info->klass : NA_INTEGER));
    SEXP message = PROTECT(safe_string(info ? info->message : "Unknown error message"));
    SEXP expr = PROTECT(Rf_install("raise_libgit2_error"));
    SEXP call = PROTECT(Rf_lang4(expr, code, message, kclass));
    Rf_eval(call, R_FindNamespace(Rf_mkString("gert")));
    UNPROTECT(5);
  }
}

void warn_last_msg(){
  const git_error *info = giterr_last();
  if (info){
    Rf_warningcall_immediate(R_NilValue, "libgit2 warning: %s (%d)\n", info->message, info->klass);
  }
}

void bail_if_null(void * ptr, const char * what){
  if(!ptr)
    bail_if(-1, what);
}

SEXP safe_string(const char *x){
  return Rf_ScalarString(safe_char(x));
}

SEXP safe_char(const char *x){
  if(x == NULL)
    return NA_STRING;
  return Rf_mkCharCE(x, CE_UTF8);
}

SEXP make_strvec(int n, ...){
  va_list args;
  va_start(args, n);
  SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
  for (int i = 0; i < n; i++)  {
    const char *val = va_arg(args, const char *);
    SET_STRING_ELT(out, i, safe_char(val));
  }
  va_end(args);
  UNPROTECT(1);
  return out;
}

/* The input SEXPS must be protected beforehand */
SEXP build_list(int n, ...){
  va_list args;
  va_start(args, n);
  SEXP names = PROTECT(Rf_allocVector(STRSXP, n));
  SEXP vec = PROTECT(Rf_allocVector(VECSXP, n));
  for (int i = 0; i < n; i++)  {
    SET_STRING_ELT(names, i, safe_char(va_arg(args, const char *)));
    SET_VECTOR_ELT(vec, i, va_arg(args, SEXP));
  }
  va_end(args);
  Rf_setAttrib(vec, R_NamesSymbol, names);
  UNPROTECT(2 + n);
  return vec;
}

SEXP list_to_tibble(SEXP df){
  PROTECT(df);
  int nrows = Rf_length(df) ? Rf_length(VECTOR_ELT(df, 0)) : 0;
  SEXP rownames = PROTECT(Rf_allocVector(INTSXP, nrows));
  for(int j = 0; j < nrows; j++)
    INTEGER(rownames)[j] = j+1;
  Rf_setAttrib(df, R_RowNamesSymbol, rownames);
  Rf_setAttrib(df, R_ClassSymbol, make_strvec(3, "tbl_df", "tbl", "data.frame"));
  UNPROTECT(2);
  return df;
}

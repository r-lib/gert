#include "utils.h"

void bail_if(int err, const char *what){
  if (err) {
    const git_error *info = giterr_last();
    if (info){
      Rf_error("libgit2 error in %s: %s (%d)\n", what, info->message, info->klass);
    } else {
      Rf_error("Unknown libgit2 error in %s", what);
    }
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

SEXP make_tibble(int n, ...){
  /* Just for storing pointers */
  const char *names[n];
  SEXP values[n];

  /* Protect all SEXP inputs before allocating anything */
  va_list args;
  va_start(args, n);
  for (int i = 0; i < n; i++)  {
    names[i] = va_arg(args, const char *);
    values[i] = PROTECT(va_arg(args, SEXP));
  }
  va_end(args);

  /* Create output list and names */
  SEXP namevec = PROTECT(Rf_allocVector(STRSXP, n));
  SEXP df = PROTECT(Rf_allocVector(VECSXP, n));
  for (int i = 0; i < n; i++)  {
    SET_STRING_ELT(namevec, i, safe_char(names[i]));
    SET_VECTOR_ELT(df, i, values[i]);
  }

  /* Create mandatory row names vector */
  int nrows = n ? Rf_length(VECTOR_ELT(df, 0)) : 0;
  SEXP rownames = PROTECT(Rf_allocVector(INTSXP, nrows));
  for(int j = 0; j < nrows; j++)
    INTEGER(rownames)[j] = j+1;
  Rf_setAttrib(df, R_NamesSymbol, namevec);
  Rf_setAttrib(df, R_RowNamesSymbol, rownames);
  Rf_setAttrib(df, R_ClassSymbol, make_strvec(3, "tbl_df", "tbl", "data.frame"));
  UNPROTECT(3 + n);
  return df;
}

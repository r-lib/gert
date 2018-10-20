void bail_if(int err, const char *what);
void bail_if_null(void * ptr, const char * what);
#define AT_LEAST_LIBGIT2(x,y) (LIBGIT2_VER_MAJOR > x || LIBGIT2_VER_MINOR >= y)
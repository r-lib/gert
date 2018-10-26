#include <git2.h>
#ifdef LIBGIT2_VER_MINOR
#if LIBGIT2_VER_MAJOR == 0 && LIBGIT2_VER_MINOR < 26
#error Your version of libgit2 is too old!
#endif
#endif

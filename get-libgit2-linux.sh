IS_MUSL=$(ldd --version 2>&1 | grep musl)
if [ $? -eq 0 ] && [ "$IS_MUSL" ]; then
echo "Do not use static libgit2 on MUSL C"
else
OLDOPENSSL=$("${R_HOME}/bin/Rscript" -e 'cat(openssl::openssl_config()$version)' | grep "OpenSSL 1.0")
if [ $? -eq 0 ] && [ "$OLDOPENSSL" ]; then
URL="https://r-lib.github.io/gert/libgit2-1.1.0.x86_64_legacy-linux.tar.gz"
TMP_LIBS="-lstatgit2 -lrt -lpthread -lstatssh2 -lstatssl -lstatcrypto -ldl -lpcre -lz"
else
OPENSSL3=$("${R_HOME}/bin/Rscript" -e 'cat(openssl::openssl_config()$version)' | grep "OpenSSL 3")
if [ $? -eq 0 ] && [ "$OPENSSL3" ]; then
URL="https://r-lib.github.io/gert/libgit2-1.4.2-openssl3-x86_64_linux.tar.gz"
echo "Found OpenSSL3"
else
URL="https://autobrew.github.io/archive/x86_64_linux/libgit2-1.4.2-x86_64_linux.tar.gz"
fi
TMP_LIBS="-lstatgit2 -lrt -lpthread -lstatssh2 -lstatssl -lstatcrypto -ldl"
fi
if "${R_HOME}/bin/R" -s -e "curl::curl_download('$URL','bundle.tar.gz')"; then
  DEPS="$PWD/.deps"
  LIBDIR="$DEPS/lib"
  mkdir -p $DEPS
  tar xzf bundle.tar.gz --strip 1 -C $DEPS
  mv $LIBDIR/libgit2.a $LIBDIR/libstatgit2.a
  mv $LIBDIR/libssh2.a $LIBDIR/libstatssh2.a
  mv $LIBDIR/libssl.a $LIBDIR/libstatssl.a
  mv $LIBDIR/libcrypto.a $LIBDIR/libstatcrypto.a
  PKG_CFLAGS="-I$DEPS/include -DSTATIC_LIBGIT2"
  PKG_LIBS="-L$LIBDIR $TMP_LIBS"
  HAVE_STATIC_LIBGIT2=TRUE
fi
fi

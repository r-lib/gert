IS_MUSL=$(ldd --version 2>&1 | grep musl)
if [ $? -eq 0 ] && [ "$IS_MUSL" ]; then
echo "Do not use static libgit2 on MUSL C"
else
OLDOPENSSL=$("${R_HOME}/bin/Rscript" -e 'cat(openssl::openssl_config()$version)' | grep "OpenSSL 1.0")
if [ $? -eq 0 ] && [ "$OLDOPENSSL" ]; then
URL="https://r-lib.github.io/gert/libgit2-1.1.0.x86_64_legacy-linux.tar.gz"
PKG_CFLAGS="-DSTATIC_LIBGIT2 -I${PWD}/libgit2/include"
PKG_LIBS="-L${PWD}/libgit2/lib -lgit2 -lrt -lpthread -lssh2 -lssl -lcrypto -ldl -lpcre -lz"
else
URL="https://r-lib.github.io/gert/libgit2-1.4.2-x86_64_linux.tar.gz"
PKG_CFLAGS="-DSTATIC_LIBGIT2 -I${PWD}/libgit2-1.4.2-x86_64_linux/include"
PKG_LIBS="-L${PWD}/libgit2-1.4.2-x86_64_linux/lib -lgit2 -lrt -lpthread -lssh2 -lssl -lcrypto -ldl"
fi
"${R_HOME}/bin/R" -s -e "curl::curl_download('$URL','bundle.tar.gz')"
tar xzf bundle.tar.gz && rm -f bundle.tar.gz
HAVE_STATIC_LIBGIT2=TRUE
fi

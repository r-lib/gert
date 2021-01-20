if [ `arch` = "x86_64" ]; then
URL="http://r-lib.github.io/gert/libgit2-1.1.0.x86_64_linux.tar.gz"
${R_HOME}/bin/R -q -e "curl::curl_download('$URL','bundle.tar.gz',quiet=FALSE)"
tar xzf bundle.tar.gz && rm -f bundle.tar.gz
PKG_CFLAGS="-I${PWD}/libgit2/include"
PKG_LIBS="-L${PWD}/libgit2/lib -lgit2 -lrt -lpthread -lssh2 -lssl -lcrypto -ldl -lpcre -lz"
else
"DOWNLOAD_STATIC_LIBGIT2 not supported on `arch`"
exit 1
fi

#!/bin/bash

# disable libidn for security reasons:
#   http://lists.gnupg.org/pipermail/gnutls-devel/2015-May/007582.html
# if ever want it back, package and link against libidn2 instead

if [ "$(uname)" == "Linux" ]
then
   export LDFLAGS="$LDFLAGS -Wl,-rpath-link,${PREFIX}/lib"
fi

./configure --prefix="${PREFIX}" \
            --without-idn \
            --without-libidn2 \
            --with-included-libtasn1 \
            --with-included-unistring \
            --without-p11-kit
make -j${CPU_COUNT}
make install
make check

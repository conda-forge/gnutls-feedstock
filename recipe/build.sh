#!/bin/bash

if [ "$(uname)" == "Linux" ]
then
   export LDFLAGS="$LDFLAGS -Wl,-rpath-link,${PREFIX}/lib"
fi

# disable libidn for security reasons:
#   http://lists.gnupg.org/pipermail/gnutls-devel/2015-May/007582.html
# if ever want it back, package and link against libidn2 instead

export CPPFLAGS="${CPPFLAGS//-DNDEBUG/}"

autoreconf -vfi tests/

./configure --prefix="${PREFIX}" \
            --without-idn \
            --without-libidn2 \
            --with-included-libtasn1 \
            --with-included-unistring \
            --without-p11-kit || { cat config.log; exit 1; }
make -j${CPU_COUNT}
make install
make -j${CPU_COUNT} check V=1 || { cat tests/test-suite.log; exit 1; }

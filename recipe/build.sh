#!/bin/bash

# disable libidn for security reasons:
#   http://lists.gnupg.org/pipermail/gnutls-devel/2015-May/007582.html
# if ever want it back, package and link against libidn2 instead

./configure --prefix="${PREFIX}" \
            --without-idn \
            --without-libidn2 \
            --with-included-libtasn1 \
            --with-included-unistring \
            --without-p11-kit
make
make install
make check

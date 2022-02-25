#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./build-aux
# Remove  nettle static libs to test if it works:
# https://github.com/conda-forge/nettle-feedstock/pull/10
rm -f ${PREFIX}/lib/libnettle.a
rm -f ${PREFIX}/lib/libhogweed.a
set -x

if [[ ${target_platform} =~ .*linux.* ]]; then
   export LDFLAGS="$LDFLAGS -Wl,-rpath-link,${PREFIX}/lib"
fi

# disable libidn for security reasons:
#   http://lists.gnupg.org/pipermail/gnutls-devel/2015-May/007582.html
# if ever want it back, package and link against libidn2 instead
#
# Also --disable-full-test-suite does not disable all tests but rather
# "disable[s] running very slow components of test suite"

export CPPFLAGS="${CPPFLAGS//-DNDEBUG/}"

libtoolize --copy --force --verbose
# libtoolize deletes things we need from build-aux, this puts them back
automake --add-missing --copy --verbose

./configure --prefix="${PREFIX}"          \
            --without-idn                 \
            --cache-file=test-output.log  \
            --disable-full-test-suite     \
            --disable-maintainer-mode     \
            --with-included-libtasn1      \
            --with-included-unistring     \
            --without-p11-kit || { cat config.log; exit 1; }

cat libtool | grep as-needed 2>&1 >/dev/null || { echo "ERROR: Not using libtool with --as-needed fixes?"; exit 1; }

make -j${CPU_COUNT} ${VERBOSE_AT}
make install
if [[ "${target_platform}" == "linux-ppc64le" ]]; then
   export fail_test_exit_code="0"
else
   export fail_test_exit_code="1"
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
   make -j${CPU_COUNT} check -k V=1 || {
      echo CONDA-FORGE TEST OUTPUT;
      cat test-output.log;
      cat tests/test-suite.log;
      cat tests/slow/test-suite.log;
      if [[ "${fail_test_exit_code}" == "1" ]]; then
         exit fail_test_exit_code;
      fi
   }
fi

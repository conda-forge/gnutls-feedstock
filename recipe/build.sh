#!/bin/bash
# Get an updated config.sub and config.guess
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

./configure --prefix="${PREFIX}"          \
            --with-idn                    \
            --cache-file=test-output.log  \
            --disable-full-test-suite     \
            --disable-maintainer-mode     \
            --with-included-unistring     \
            --with-p11-kit || { cat config.log; exit 1; }

make -j${CPU_COUNT} ${VERBOSE_AT}
make install
if [[ "${target_platform}" == "linux-ppc64le" ]]; then
   export fail_test_exit_code="0"
else
   export fail_test_exit_code="1"
fi

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
   # if [[ ${target_platform} =~ .*osx.* ]]; then
      # hmaarrfk - 2024/08
      # skip two problematic tests on OSX
      # https://github.com/conda-forge/gnutls-feedstock/pull/47
      # https://gitlab.com/gnutls/gnutls/-/issues/1539
      # sed -i.back 's,gnutls-cli-debug.sh,,g' tests/Makefile
      # this test should have been fixed there https://gitlab.com/gnutls/gnutls/-/issues/1546
      # commenting
      # sed -i.back 's,ocsp-tests/ocsp-must-staple-connection.sh,,g' tests/Makefile
   # fi
   make -j${CPU_COUNT} check -k V=1 || {
      echo CONDA-FORGE TEST OUTPUT;
      cat test-output.log;
      cat tests/test-suite.log;
      cat tests/slow/test-suite.log;
      if [[ "${fail_test_exit_code}" == "1" ]]; then
         exit ${fail_test_exit_code};
      fi
   }
fi

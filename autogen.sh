#!/bin/sh
ln -fs README.textile README
autoreconf -vi && \
autoconf && {
  echo "Running configure with --enable-maintainer-mode $@"
  ./configure --enable-maintainer-mode $@
}

#!/bin/bash

MINGW_STD_THREADS_REPO="https://github.com/meganz/mingw-std-threads.git"
MINGW_STD_THREADS_COMMIT="6c2061b7da41d6aa1b2162ff4383ec3ece864bc6"

ffbuild_enabled() {
    [[ $TARGET =~ ^(ucrt64|win(64|32))$ ]] || return -1
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$MINGW_STD_THREADS_REPO" "$MINGW_STD_THREADS_COMMIT" mingw-std-threads
    cd mingw-std-threads

    mkdir -p "$FFBUILD_PREFIX"/include
    cp *.h "$FFBUILD_PREFIX"/include
}

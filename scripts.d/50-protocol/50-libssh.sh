#!/bin/bash

LIBSSH_REPO="https://gitlab.com/libssh/libssh-mirror.git"
LIBSSH_COMMIT="7f442afd5748d9791e9821d571b6a9561ae2c036"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$LIBSSH_REPO" "$LIBSSH_COMMIT" libssh
    cd libssh

    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF \
        -DWITH_{SFTP,ZLIB}=ON \
        -DWITH_{EXAMPLES,SERVER}=OFF \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install

    {
        echo "Libs.private: -liphlpapi"
        echo "Requires.private: libssl libcrypto zlib"
        echo "Cflags.private: -DLIBSSH_STATIC"
    } >> "$FFBUILD_PREFIX"/lib/pkgconfig/libssh.pc
}

ffbuild_configure() {
    echo --enable-libssh
}

ffbuild_unconfigure() {
    echo --disable-libssh
}

#!/bin/bash

FREETYPE_REPO="https://github.com/freetype/freetype.git"
FREETYPE_COMMIT="e82371bf6ec2efdf79f9ed2d00e633ba0bbf7830"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$FREETYPE_REPO" "$FREETYPE_COMMIT" freetype
    cd freetype

    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DBUILD_SHARED_LIBS=OFF \
        -GNinja \
        ..
    ninja -j$(nproc)
    ninja install
}

ffbuild_configure() {
    echo --enable-libfreetype
}

ffbuild_unconfigure() {
    echo --disable-libfreetype
}

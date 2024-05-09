#!/bin/bash

AOM_REPO="https://github.com/Clybius/aom-av1-lavish"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git clone --filter=tree:0 --branch=Endless_Merging --single-branch "$AOM_REPO" aom
    cd aom

    mkdir aom_build && cd aom_build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_EXAMPLES=NO \
    -DENABLE_TESTS=NO \
    -DENABLE_TOOLS=NO \
    -GNinja \
    ..
    ninja -j$(nproc)
    ninja install
}

ffbuild_configure() {
    echo --enable-libaom
}

ffbuild_unconfigure() {
    echo --disable-libaom
}

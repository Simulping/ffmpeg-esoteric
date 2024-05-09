 #!/bin/bash

VVDEC_REPO="https://github.com/fraunhoferhhi/vvdec.git"
VVDEC_COMMIT="edd47ab839a73e47d672b1f1ad071725eb955f93"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$VVDEC_REPO" "$VVDEC_COMMIT" vvdec
    cd vvdec

    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -GNinja \
        ..
    ninja -j$(nproc)
    ninja install
}

ffbuild_configure() {
    echo --enable-libvvdec
}

ffbuild_unconfigure() {
    echo --disable-libvvdec
}
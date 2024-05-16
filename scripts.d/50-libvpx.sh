#!/bin/bash

LIBVPX_REPO="https://github.com/webmproject/libvpx.git"
LIBVPX_COMMIT="1a3cd4922bcde7c381b1f2681b0463804e71f0c7"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$LIBVPX_REPO" "$LIBVPX_COMMIT" libvpx
    cd libvpx

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-{shared,dependency-tracking,docs,examples,tools,unit-tests}
        --enable-{static,pic,vp9-highbitdepth}
    )

    if [[ $TARGET == win64 ]]; then
        myconf+=(
            --target=x86_64-win64-gcc
        )
        export CROSS="$FFBUILD_CROSS_PREFIX"
    elif [[ $TARGET == win32 ]]; then
        myconf+=(
            --target=x86-win32-gcc
        )
        export CROSS="$FFBUILD_CROSS_PREFIX"
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j"$(nproc)"
    make install
}

ffbuild_configure() {
    echo --enable-libvpx
}

ffbuild_unconfigure() {
    echo --disable-libvpx
}

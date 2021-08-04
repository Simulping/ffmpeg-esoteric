#!/bin/bash

LIBRIST_REPO="https://github.com/nanake/librist.git"
LIBRIST_COMMIT="13fadfb7a138b9633f9c618a9c5c6f90cb268652"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$LIBRIST_REPO" "$LIBRIST_COMMIT" librist
    cd librist

    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        -Dhave_mingw_pthreads=true
        -D{built_tools,test,use_mbedtls}"=false"
        # Workaround/fixes for cJSON symbol collision
        -Ddisable_json=true
    )

    if [[ $TARGET == win* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    else
        echo "Unknown target"
        return -1
    fi

    meson "${myconf[@]}" ..
    ninja -j"$(nproc)"
    ninja install
}

ffbuild_configure() {
    echo --enable-librist
}

ffbuild_unconfigure() {
    echo --disable-librist
}

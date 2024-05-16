#!/bin/bash

X265_REPO="https://bitbucket.org/multicoreware/x265_git.git"
X265_COMMIT="f3c5fbaffaf54b5f79aa8983d59f1b0232d5eccf"

ffbuild_enabled() {
    [[ $VARIANT == lgpl* ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    git clone --filter=tree:0 --branch=master --single-branch "$X265_REPO" x265
    cd x265
    git checkout "$X265_COMMIT"

    local common_config=(
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
        -DCMAKE_BUILD_TYPE=Release
        -DENABLE_{SHARED,CLI}"=OFF"
        -Wno-dev
    )

    if [[ $TARGET != *32 ]]; then
        mkdir 8bit 10bit 12bit
        cmake "${common_config[@]}" -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_HDR10_PLUS=ON -DMAIN12=ON -S source -B 12bit &
        cmake "${common_config[@]}" -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_HDR10_PLUS=ON -S source -B 10bit &
        cmake "${common_config[@]}" -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_{10,12}BIT=ON -S source -B 8bit &
        wait

        cat >Makefile <<"EOF"
all: 12bit/libx265.a 10bit/libx265.a 8bit/libx265.a

%/libx265.a:
	$(MAKE) -C $(subst /libx265.a,,$@)

.PHONY: all
EOF

        make -j"$(nproc)"

        cd 8bit
        mv ../12bit/libx265.a ../8bit/libx265_main12.a
        mv ../10bit/libx265.a ../8bit/libx265_main10.a
        mv libx265.a libx265_main.a

        ${AR} -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
    else
        mkdir 8bit
        cd 8bit
        cmake "${common_config[@]}" ../source
        make -j"$(nproc)"
    fi

    make install

    echo "Libs.private: -lstdc++" >> "$FFBUILD_PREFIX"/lib/pkgconfig/x265.pc
}

ffbuild_configure() {
    echo --enable-libx265
}

ffbuild_unconfigure() {
    echo --disable-libx265
}

ffbuild_cflags() {
    return 0
}

ffbuild_ldflags() {
    return 0
}

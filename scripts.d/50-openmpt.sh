#!/bin/bash

OPENMPT_REPO="https://github.com/OpenMPT/openmpt.git"
OPENMPT_COMMIT="7f018ff08f8f9043ca2b35fce01611a8c8850b56"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$OPENMPT_REPO" "$OPENMPT_COMMIT" openmpt
    cd openmpt

    local myconf=(
        PREFIX="$FFBUILD_PREFIX"
        CXXSTDLIB_PCLIBSPRIVATE="-lstdc++"
        VERBOSE=2
        STATIC_LIB=1
        SHARED_LIB=0
        DYNLINK=0
        EXAMPLES=0
        OPENMPT123=0
        IN_OPENMPT=0
        XMP_OPENMPT=0
        DEBUG=0
        OPTIMIZE=1
        TEST=0
        MODERN=1
        FORCE_DEPS=1
        NO_MINIMP3=0
        NO_ZLIB=0
        NO_OGG=0
        NO_VORBIS=0
        NO_VORBISFILE=0
        NO_MPG123=1
        NO_SDL2=1
        NO_PULSEAUDIO=1
        NO_SNDFILE=1
        NO_PORTAUDIO=1
        NO_PORTAUDIOCPP=1
        NO_FLAC=1
    )

    if [[ $TARGET == win64 ]]; then
        myconf+=(
            CONFIG=mingw-w64
            WINDOWS_ARCH=amd64
        )
        export CPPFLAGS="$CPPFLAGS -DMPT_WITH_MINGWSTDTHREADS"
    elif [[ $TARGET == win32 ]]; then
        myconf+=(
            CONFIG=mingw-w64
            WINDOWS_ARCH=x86
        )
        export CPPFLAGS="$CPPFLAGS -DMPT_WITH_MINGWSTDTHREADS"
    else
        echo "Unknown target"
        return -1
    fi

    make -j$(nproc) "${myconf[@]}" all install
}

ffbuild_configure() {
    echo --enable-libopenmpt
}

ffbuild_unconfigure() {
    echo --disable-libopenmpt
}

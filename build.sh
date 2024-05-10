#!/bin/bash
set -e
shopt -s globstar
cd "$(dirname "$0")"
source util/vars.sh

get_output() {
    (
        SELF="$1"
        source $1
        if ffbuild_enabled; then
            ffbuild_$2 || exit 0
        else
            ffbuild_un$2 || exit 0
        fi
    )
}

source "variants/${TARGET}-${VARIANT}.sh"

for addin in ${ADDINS[*]}; do
    source "addins/${addin}.sh"
done

export FFBUILD_PREFIX="$(docker run --rm "$IMAGE" bash -c 'echo $FFBUILD_PREFIX')"

for script in scripts.d/**/*.sh; do
    FF_CONFIGURE+=" $(get_output $script configure)"
    FF_CFLAGS+=" $(get_output $script cflags)"
    FF_CXXFLAGS+=" $(get_output $script cxxflags)"
    FF_LDFLAGS+=" $(get_output $script ldflags)"
    FF_LIBS+=" $(get_output $script libs)"
done

FF_CONFIGURE="$(xargs <<< "$FF_CONFIGURE")"
FF_CFLAGS="$(xargs <<< "$FF_CFLAGS")"
FF_CXXFLAGS="$(xargs <<< "$FF_CXXFLAGS")"
FF_LDFLAGS="$(xargs <<< "$FF_LDFLAGS")"
FF_LIBS="$(xargs <<< "$FF_LIBS")"

TESTFILE="uidtestfile"
rm -f "$TESTFILE"
docker run --rm -v "$PWD:/uidtestdir" "$IMAGE" touch "/uidtestdir/$TESTFILE"
DOCKERUID="$(stat -c "%u" "$TESTFILE")"
rm -f "$TESTFILE"
[[ "$DOCKERUID" != "$(id -u)" ]] && UIDARGS=( -u "$(id -u):$(id -g)" ) || UIDARGS=()

rm -rf ffbuild
mkdir ffbuild

FFMPEG_REPO="${FFMPEG_REPO:-https://git.ffmpeg.org/ffmpeg.git}"
FFMPEG_REPO="${FFMPEG_REPO_OVERRIDE:-$FFMPEG_REPO}"
GIT_BRANCH="${GIT_BRANCH:-master}"
GIT_BRANCH="${GIT_BRANCH_OVERRIDE:-$GIT_BRANCH}"

BUILD_SCRIPT="$(mktemp)"
trap "rm -f -- '$BUILD_SCRIPT'" EXIT

cat <<EOF >"$BUILD_SCRIPT"
    set -xe
    cd /ffbuild
    rm -rf ffmpeg prefix

    git clone '$FFMPEG_REPO' ffmpeg
    cd ffmpeg
    git checkout release/7.0

    curl -O https://patchwork.ffmpeg.org/series/11673/mbox/ -o Add-support-for-H266-VVC.patch
    git apply Add-support-for-H266-VVC.patch

    curl https://x266.mov/files/ffmpeg-ac4.patch -o Add-Support-for-AC4-Decode.patch
    git apply Add-Support-for-AC4-Decode.patch

    curl https://x266.mov/files/lavf-matroska-vvc-muxing.patch -o Add-Support-for-VVC-Muxing.patch
    git apply Add-Support-for-VVC-Muxing.patch

    curl https://x266.mov/files/lavf-matroska-vvc-demuxing.patch -o Add-Support-for-VVC-Demuxing.patch
    git apply Add-Support-for-VVC-Demuxing.patch

    ./configure --prefix=/ffbuild/prefix --pkg-config-flags="--static" \$FFBUILD_TARGET_FLAGS $FF_CONFIGURE \
        --extra-cflags="$FF_CFLAGS" --extra-cxxflags="$FF_CXXFLAGS" \
        --extra-ldflags="$FF_LDFLAGS" --extra-libs="$FF_LIBS"
    make -j\$(nproc)
    make install
EOF

[[ -t 1 ]] && TTY_ARG="-t" || TTY_ARG=""

docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v $PWD/ffbuild:/ffbuild -v "$BUILD_SCRIPT":/build.sh "$IMAGE" bash /build.sh

mkdir -p artifacts
ARTIFACTS_PATH="$PWD/artifacts"
FFMPEG_VERSION="$(./ffbuild/ffmpeg/ffbuild/version.sh ffbuild/ffmpeg)"
BUILD_NAME="ffmpeg-${FFMPEG_VERSION//-g/-git-}-${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}"

mkdir -p "ffbuild/pkgroot/$BUILD_NAME"
package_variant ffbuild/prefix "ffbuild/pkgroot/$BUILD_NAME"

if [[ -n "$GITHUB_ACTIONS" ]]; then
    cd ffbuild/pkgroot
    tar -I 'zstdmt -9 --long' -cf "${ARTIFACTS_PATH}/${BUILD_NAME}.tar.zst" "$BUILD_NAME"
    cd -
else
    mv "ffbuild/pkgroot/$BUILD_NAME" "${ARTIFACTS_PATH}"
fi

rm -rf ffbuild

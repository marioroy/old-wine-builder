#!/bin/bash

BUILD_THREADS="${BUILD_THREADS:-4}"
echo "Using $BUILD_THREADS threads for build."

BUILD_DEBUG="${BUILD_DEBUG:-0}"
if [ "$BUILD_DEBUG" = "1" ]; then
  echo "The build will produce debugging information."
fi

BUILD_WAYLAND="${BUILD_WAYLAND:-1}"
if [ "$BUILD_WAYLAND" = "0" ]; then
  echo "The build will skip the Wine Wayland driver."
fi

flags=(
  "-std=gnu17" "-msse3" "-mfpmath=sse" "-mpopcnt"
  "-O2" "-ftree-vectorize" "-pipe"
)

[ "$BUILD_DEBUG" = "1" ] && flags+=("-g")

nowarnings=(
  "-Wno-discarded-qualifiers"
  "-Wno-format"
  "-Wno-maybe-uninitialized"
  "-Wno-misleading-indentation"
  "-Wno-stringop-overflow"
)

# Generic and cross-compilation flags
export CFLAGS="-march=x86-64 ${flags[*]} ${nowarnings[*]}"
export CXXFLAGS="-march=x86-64 ${flags[*]} ${nowarnings[*]}"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed"

export CROSSCC="x86_64-w64-mingw32-gcc"
export CROSSCXX="x86_64-w64-mingw32-g++"
export CROSSCFLAGS="${CFLAGS}"
export CROSSCXXFLAGS="${CXXFLAGS}"
export CROSSLDFLAGS="${LDFLAGS}"

# Prepare/configure, build and install Wine
sudo mkdir -p wine-src/wine-install
mkdir -p wine-build && cd wine-build || exit 1

echo
echo "Preparing build environment for Wine..."
echo
sleep 1.35

if [ "$BUILD_WAYLAND" = "0" ]; then
  ../wine-src/configure --prefix=/wine-builder/wine-src/wine-install \
    --disable-tests --disable-win16 --disable-winemenubuilder \
    --enable-opencl --without-oss --without-wayland \
    --enable-archs=x86_64,i386 || exit 1
else
  ../wine-src/configure --prefix=/wine-builder/wine-src/wine-install \
    --disable-tests --disable-win16 --disable-winemenubuilder \
    --enable-opencl --without-oss \
    --enable-archs=x86_64,i386 || exit 1
fi

echo "Building Wine..."
echo
( make -j$BUILD_THREADS >/dev/null || exit 1
) 2>&1 | grep -Ev "(aqs|parser|sql)\.y: (warning|note):"

sudo make install -j$BUILD_THREADS >/dev/null || exit 1

echo
echo "Build complete, final output is in 'wine-install'"
echo

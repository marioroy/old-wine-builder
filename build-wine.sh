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

flags=("-mfpmath=sse" "-std=gnu17" "-O2" "-ftree-vectorize" "-pipe")

nowarnings=(
  "-Wno-discarded-qualifiers"
  "-Wno-format"
  "-Wno-maybe-uninitialized"
  "-Wno-misleading-indentation"
)

# Generic flags
export CFLAGS="-march=x86-64 -msse3 -mpopcnt ${flags[*]} ${nowarnings[*]} -ffat-lto-objects"

# Flags for cross-compilation
export CROSSCFLAGS="-march=i686 -msse2 ${flags[*]} ${nowarnings[*]}"
export CROSSCXXFLAGS="-march=i686 -msse2 ${flags[*]} ${nowarnings[*]}"
export CROSSLDFLAGS="-Wl,-O1"

if [ "$BUILD_DEBUG" = "1" ]; then
  CFLAGS+=" -g"; CROSSCFLAGS+=" -g"; CROSSCXXFLAGS+=" -g"
fi

# Prepare the build environment
mkdir -p wine32-build wine64-build 
sudo mkdir -p wine-src/wine-install

###############################################################################
# Build 64-bit Wine
###############################################################################
echo
echo "Preparing build environment for 64-bit Wine..."
echo
sleep 1.35

cd wine64-build
sudo apt install -y samba-dev libcups2-dev

if [ "$BUILD_WAYLAND" = "0" ]; then
  ../wine-src/configure --prefix=/wine-builder/wine-src/wine-install \
    --enable-opencl --enable-win64 --without-oss --without-wayland \
    --disable-winemenubuilder --disable-win16 --disable-tests
else
  ../wine-src/configure --prefix=/wine-builder/wine-src/wine-install \
    --enable-opencl --enable-win64 --without-oss \
    --disable-winemenubuilder --disable-win16 --disable-tests
fi

echo "Building 64-bit Wine..."
echo
( make -j$BUILD_THREADS >/dev/null
) 2>&1 | grep -Ev "(aqs|parser|sql)\.y: (warning|note):"

# Install 64-bit Wine
sudo make install -j$BUILD_THREADS >/dev/null

###############################################################################
# Build 32-bit Wine
###############################################################################
echo
echo "Preparing build environment for 32-bit Wine..."
echo
sleep 1.35

cd ../wine32-build
sudo apt install -y samba-dev:i386 libcups2-dev:i386

if [ "$BUILD_WAYLAND" = "0" ]; then
  PKG_CONFIG_PATH=/usr/lib/pkgconfig \
    ../wine-src/configure --prefix=/wine-builder/wine-src/wine-install \
    --with-wine64=../wine64-build --without-oss --without-wayland \
    --disable-winemenubuilder --disable-win16 --disable-tests
else
  PKG_CONFIG_PATH=/usr/lib/pkgconfig \
    ../wine-src/configure --prefix=/wine-builder/wine-src/wine-install \
    --with-wine64=../wine64-build --without-oss \
    --disable-winemenubuilder --disable-win16 --disable-tests
fi

echo "Building 32-bit Wine..."
echo
( make -j$BUILD_THREADS >/dev/null
) 2>&1 | grep -Ev "(aqs|parser|sql)\.y: (warning|note):"

# Install 32-bit Wine
sudo make install -j$BUILD_THREADS >/dev/null

echo
echo "Build complete, final output is in 'wine-install'"
echo

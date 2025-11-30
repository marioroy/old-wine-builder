#!/bin/bash
# Container ENTRYPOINT script.

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48 (ISO/IEC-6429)
  BD_RED='\033[01;31m' CYAN='\033[00;36m' NC='\033[00m' # no color
else
  BD_RED= CYAN= NC=
fi

# Check for missing shield.ico
if [ -e wine-src/dlls/shell32/resources/shield.svg ]; then
  if [ ! -e wine-src/dlls/shell32/resources/shield.ico ]; then
    echo -e "${BD_RED}ERROR: 'dlls/shell32/resources/shield.ico' does not exists${NC}"
    echo -e "Run the following command in your wine src to create the shield icon."
    echo -e "This step is needed after applying the patches."
    echo 
    echo -e "${CYAN}  git apply /path-to/patches/common/0001-shield-ico.patch${NC}"
    echo 
    exit 1
  fi
fi

BUILD_THREADS="${BUILD_THREADS:-4}"
echo "Using $BUILD_THREADS threads for build."

BUILD_WAYLAND="${BUILD_WAYLAND:-1}"
if [ "$BUILD_WAYLAND" = "0" ]; then
  echo "The build will skip the Wine Wayland driver."
fi

BUILD_DEBUG="${BUILD_DEBUG:-0}"
if [ "$BUILD_DEBUG" = "1" ]; then
  echo "The build will produce debugging information."
fi

flags=(
  "-mfpmath=sse" "-mpopcnt" "-std=gnu17" "-O2" "-ftree-vectorize" "-pipe"
)

[ "$BUILD_DEBUG" = "1" ] && flags+=("-g")

nowarnings=(
  "-Wno-discarded-qualifiers"
  "-Wno-format"
  "-Wno-maybe-uninitialized"
  "-Wno-misleading-indentation"
  "-Wno-stringop-overflow"
  "-Wno-unused-variable"
)

# Generic and cross-compilation flags
export CFLAGS="-march=x86-64 -msse3 ${flags[*]} ${nowarnings[*]}"
export CXXFLAGS="-march=x86-64 -msse3 ${flags[*]} ${nowarnings[*]}"
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
echo -e "${CYAN}Preparing build environment for Wine...${NC}"
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

echo -e "${CYAN}Building Wine WoW64...${NC}"
echo
( make -j$BUILD_THREADS >/dev/null || exit 1
) 2>&1 | grep -Ev "(aqs|parser|sql)\.y: (warning|note):"

sudo make install -j$BUILD_THREADS >/dev/null || exit 1

echo
echo "Build complete, final output is in 'wine-install'"
echo

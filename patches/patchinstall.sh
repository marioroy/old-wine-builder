#!/usr/bin/env bash
# Patch automation for Wine.
# Must be in the root Wine source to run.

PATCH_DIR=$(cd "$(dirname "$BASH_SOURCE")"; pwd)

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48 (ISO/IEC-6429)
  BD_RED='\033[01;31m' CYAN='\033[00;36m' NC='\033[00m' # no color
else
  BD_RED= CYAN= NC=
fi

function get_wine_version {
  if [[ ! -d "dlls" || ! -e "VERSION" || -z $(grep -i "^Wine" VERSION) ]]; then
    echo -e "${BD_RED}ERROR: Cannot determine Wine version${NC}"
    echo -e "Change directory to the root of the Wine source and try again."
    echo
    exit 1
  fi
  # Okay for the grep result to be blank if the format differs (very old)
  # All the Wine versions we have patches have "Wine version ..." format
  local wine_ver=$(grep "^Wine " VERSION)
  echo ${wine_ver##* }
}

function check_for_avail_patch {
  local ver="$1"
  if [ ! -d "${PATCH_DIR}/wine-${ver}" ]; then
    echo "Patches unavailable for $(head -1 VERSION), exiting..."
    exit 0
  fi
}

function check_for_missing_pkgs {
  local missing_pkgs=()
  if ! command -v "git" &>/dev/null; then missing_pkgs+=("git"); fi
  if ! command -v "patch" &>/dev/null; then missing_pkgs+=("patch"); fi
  if [ ${#missing_pkgs[@]} -gt 0 ]; then
    echo -e "${BD_RED}ERROR: Missing required packages${NC}"
    echo -e "Install the following packages and try again."
    echo
    echo -e "${CYAN}  ${missing_pkgs[*]}${NC}"
    echo
    exit 1
  fi
}

VER=$(get_wine_version)
check_for_avail_patch "$VER" # exits if unavailable
check_for_missing_pkgs       # exits if any missing

set -e # exit on error

# Apply patches for this Wine version
for patch in $(ls "${PATCH_DIR}/wine-${VER}"/*.patch); do
  echo -e "${CYAN}Applying patch wine-${VER}/${patch##*/}...${NC}"
  if patch -p1 --dry-run -i "$patch" 2>&1 |\
      grep -qE "(already exists|previously applied)"; then
    echo "patch previously applied, skipping"
    continue
  fi
  patch -p1 --no-backup-if-mismatch -i "${patch}"
done

# Apply the shield icon patch
if [ -e "dlls/shell32/resources/shield.svg" ]; then
  echo -e "${CYAN}Applying patch common/0001-shield-ico.patch...${NC}"
  if [ -e "dlls/shell32/resources/shield.ico" ]; then
    echo "patch previously applied, skipping"
  else
    git apply "$PATCH_DIR/common/0001-shield-ico.patch"
    echo "patching dlls/shell32/resources/shield.ico"
  fi
fi

echo
echo "Patching complete."
echo

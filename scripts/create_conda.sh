#!/usr/bin/env bash
#
# setup_rconda.sh
#
# Creates a self-contained conda environment with:
#   * base R only (NO CRAN/Bioconductor packages; rv handles those)
#   * C/C++/Fortran compilers, make, cmake, pkg-config
#   * the system libraries R packages commonly link against
#
# Usage:
#   bash setup_rconda.sh
#   ENV_PREFIX=/big/disk/r461 GCC_VERSION=13 bash setup_rconda.sh
#
# Afterwards, in a NEW shell (no HPC modules loaded):
#   source ~/activate_r461.sh
#   rv sync
#
# Notes
#   * GCC is pinned to 14 by default. GCC 15 defaults to C23, which breaks
#     some older CRAN packages' C code. Override with GCC_VERSION if needed.
#   * OpenMPI is deliberately left out: conda's MPI generally won't match the
#     cluster's interconnect/scheduler. Add it only if you need Rmpi.
#   * r-recommended (MASS, Matrix, lattice, ...) is deliberately left out so
#     that rv installs those from your configured repositories like any other
#     package.
#
set -euo pipefail

ENV_PREFIX="${ENV_PREFIX:-$HOME/.conda/envs/r461}"
R_VERSION="${R_VERSION:-4.6.1}"
GCC_VERSION="${GCC_VERSION:-14}"
ACTIVATE_SCRIPT="${ACTIVATE_SCRIPT:-$HOME/activate_r461.sh}"
# Only this one channel is used. --override-channels below makes conda/mamba
# ignore anything in ~/.condarc (including "defaults"/"main"/"r").
# To use a mirror instead of conda.anaconda.org, e.g.:
#   CHANNEL=https://prefix.dev/conda-forge bash setup_rconda.sh
CHANNEL="${CHANNEL:-conda-forge}"
MGR=conda

if [ -e "$ENV_PREFIX" ]; then
  echo "ERROR: $ENV_PREFIX already exists. Remove it or set ENV_PREFIX to a new path." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Package list
# ---------------------------------------------------------------------------
PKGS=(
  # --- R itself (base packages only) ---
  "r-base=${R_VERSION}"

  # --- compilers (C, C++, Fortran) ---
  "gcc_linux-64=${GCC_VERSION}"
  "gxx_linux-64=${GCC_VERSION}"
  "gfortran_linux-64=${GCC_VERSION}"

  # --- build tools ---
  make
  cmake
  pkg-config
  git
  curl
  zip
  unzip

  # --- BLAS/LAPACK ---
  "libblas=*=*openblas"
  libopenblas
  liblapack

  # --- compression / crypto / networking ---
  zlib
  bzip2
  xz
  zstd
  libcurl
  openssl
  libssh2
  libgit2

  # --- text, XML, regex ---
  expat
  libxml2
  libxml2-devel
  icu
  pcre2
  libiconv
  freetype

  # --- graphics / fonts / images ---
  libpng
  libjpeg-turbo
  libtiff
  libwebp
  freetype
  fontconfig
  harfbuzz
  fribidi
  cairo
  pango
  xorg-libx11
  xorg-xorgproto


  # --- numerics / science ---
  gsl
  glpk
  gmp
  mpfr
  fftw
  nlopt

  # --- data formats / geospatial ---
  sqlite
  hdf5
  libnetcdf
  udunits2
  proj
  geos
  gdal

  # --- optional: needed only if you knit documents ---
  pandoc
)

# ---------------------------------------------------------------------------
# Create the environment (single channel; never touches Anaconda's defaults)
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$ENV_PREFIX")"
echo ">> Creating environment at $ENV_PREFIX"
"$MGR" create -y -p "$ENV_PREFIX" --override-channels -c "$CHANNEL" "${PKGS[@]}" python=3.12

# ---------------------------------------------------------------------------
# Write an activation helper that also keeps HPC modules from leaking in
# ---------------------------------------------------------------------------
HOOK_LINE='eval "$(conda shell.bash hook)"'
ACT_LINE="conda activate \"$ENV_PREFIX\""

{
  echo "# Source this file:  source $ACTIVATE_SCRIPT"
  cat <<'EOS'
# Start from a clean slate so no HPC module libraries leak into builds or runtime.
if type module >/dev/null 2>&1; then module purge; fi
unset LD_LIBRARY_PATH LIBRARY_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH \
      PKG_CONFIG_PATH R_HOME R_LIBS R_LIBS_USER R_LIBS_SITE
# Drop any hand-built R (e.g. ~/bin/R-4.6.1/bin) from PATH
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v -E '/R-[0-9.]+/(lib64/R/)?bin' | paste -sd: -)"
export PATH
EOS
  echo "$HOOK_LINE"
  echo "$ACT_LINE"
} > "$ACTIVATE_SCRIPT"
echo ">> Wrote activation helper: $ACTIVATE_SCRIPT"

# ---------------------------------------------------------------------------
# Verify (run with a scrubbed environment so modules can't interfere)
# ---------------------------------------------------------------------------
run_in_env() {
  env -u LD_LIBRARY_PATH -u LIBRARY_PATH -u CPATH -u PKG_CONFIG_PATH \
      "$MGR" run -p "$ENV_PREFIX" "$@"
}

echo
echo ">> Verifying..."
run_in_env R --version | head -n 1

echo ">> Channels the installed packages came from (should be one line):"
grep -h '"channel"' "$ENV_PREFIX"/conda-meta/*.json | sort | uniq -c | sed 's/^/   /'

echo ">> R's configured compilers:"
for v in CC CXX17 FC; do
  printf '   %s = ' "$v"; run_in_env R CMD config "$v"
done

echo ">> R packages by priority (expect only 'base'):"
run_in_env R --vanilla -q -e 'print(table(installed.packages()[, "Priority"], useNA = "ifany"))'

echo ">> C++17 smoke test (class template argument deduction with default args):"
TMP="$(mktemp -d)"
cat > "$TMP/t.cpp" <<'EOF'
template <typename T = int> struct Opts { T x = 0; };
int main() { Opts o; return o.x; }
EOF
run_in_env sh -c '"$CXX" -std=gnu++17 -o "$1/t" "$1/t.cpp" && "$1/t" && echo "   OK"' _ "$TMP" \
  || echo "   FAILED (check the compiler output above)"
rm -rf "$TMP"

echo ">> Library versions:"
run_in_env sh -c 'gdal-config --version; pkg-config --modversion hdf5 2>/dev/null || true' | sed 's/^/   /'

cat <<EOM

Done. To use it:
  1. Open a NEW shell (do not load any modules).
  2. source $ACTIVATE_SCRIPT
EOM
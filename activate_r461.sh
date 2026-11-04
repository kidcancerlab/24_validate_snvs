# Source this file:  source /home/gdrobertslab/mvc002/activate_r461.sh
# Start from a clean slate so no HPC module libraries leak into builds or runtime.
if type module >/dev/null 2>&1; then module purge; fi
unset LD_LIBRARY_PATH LIBRARY_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH \
      PKG_CONFIG_PATH R_HOME R_LIBS R_LIBS_USER R_LIBS_SITE
# Drop any hand-built R (e.g. ~/bin/R-4.6.1/bin) from PATH
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v -E '/R-[0-9.]+/(lib64/R/)?bin' | paste -sd: -)"
export PATH
eval "$(conda shell.bash hook)"
conda activate "/home/gdrobertslab/mvc002/.conda/envs/r461"

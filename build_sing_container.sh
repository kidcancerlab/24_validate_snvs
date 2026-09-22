#!/bin/sh
#SBATCH --output=build.out
#SBATCH --error=build.err
#SBATCH --job-name=sing
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --partition=himem,general
#SBATCH --time=24:00:00

set -e ### stops bash script if line ends with error

singularity build \
  --fakeroot \
  sing_container.sif \
  validation_container.def

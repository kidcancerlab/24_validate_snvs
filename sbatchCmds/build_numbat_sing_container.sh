#!/bin/sh
#SBATCH --output=slurmOut/build_numbat.out
#SBATCH --error=slurmOut/build_numbat.err
#SBATCH --job-name=sing
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --partition=himem,general
#SBATCH --time=24:00:00

set -e ### stops bash script if line ends with error

singularity build \
  --fakeroot \
  sing_numbat_container.sif \
  numbat_container.def

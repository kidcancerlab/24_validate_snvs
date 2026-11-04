#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/render.out
#SBATCH --error=slurmOut/render.err
#SBATCH --job-name=render_val
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --partition=himem
#SBATCH --time=3-00:00:00
#SBATCH --export=NONE

set -e

ml purge
source activate_r461.sh

quarto render 24_validate_snvs.qmd

conda deactivate

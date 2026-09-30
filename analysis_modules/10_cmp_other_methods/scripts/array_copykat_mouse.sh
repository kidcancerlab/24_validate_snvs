#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/copykat_mouse-%j.out
#SBATCH --error=slurmOut/copykat_mouse-%j.out
#SBATCH --job-name=copykat_mouse
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=himem
#SBATCH --time=24:00:00
#SBATCH --wait

set -e

mouse_data=(
  $(
    {
      cut -f 1 misc/mouse_samples_Roberts_metadata.tsv
      cut -f 1 misc/mouse_samples_Roberts_realign_metadata.tsv
    } |
      grep -v '^Sample_ID$' |
      sort -u
  )
)

this_sample=${mouse_data[${SLURM_ARRAY_TASK_ID}]}

singularity exec \
  --no-home \
  --cleanenv \
  --bind $(pwd):/project \
  --home "$(pwd):/project" \
  --pwd /project \
  sing_container.sif \
  Rscript --no-init-file \
    analysis_modules/10_cmp_other_methods/scripts/run_copykat.R \
    ${this_sample} \
    mouse

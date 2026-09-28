#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/slurmOut_scevan-%j.out
#SBATCH --error=slurmOut/slurmOut_scevan-%j.out
#SBATCH --job-name=scevan
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
      cut -f 5 misc/validation_geo_metadata.tsv
      cut -f 5 misc/mouse_samples_Roberts_realign_metadata_human.tsv
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
    analysis_modules/10_cmp_other_methods/scripts/run_scevan.R \
    ${this_sample} \
    mouse

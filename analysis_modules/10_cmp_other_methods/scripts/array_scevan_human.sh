#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/scevan_human-%j.out
#SBATCH --error=slurmOut/scevan_human-%j.out
#SBATCH --job-name=scevan_human
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=himem
#SBATCH --time=24:00:00
#SBATCH --wait

set -e

human_data=(
  $(grep 10x-hg38 misc/validation_geo_metadata.tsv \
    | cut -f 3 \
    | sort \
    | uniq \
    | grep -v Sample_ID\
  )
)

this_sample=${human_data[${SLURM_ARRAY_TASK_ID}]}

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
    human

#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=call_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/variant_call/variant_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/variant_call/variant_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=1-00:00:00

set -euo pipefail

module load BCFtools/1.11 \
    SAMtools/1.15

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# read samples from sample tsv
mapfile \
    -t \
    sample_types \
    < \
    <(cut \
        -f2 \
        $wd_path/misc/compare_snps_samples.tsv \
        | tail -n +2
    )

mapfile \
    -t \
    SRR_IDs \
    < \
    <(cut \
        -f1 \
        $wd_path/misc/compare_snps_samples.tsv \
        | tail -n +2
    )

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}

echo "Processing $sample_type ($accession)"


#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=load_rna
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/rna_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/rna_%A_%a.txt
#SBATCH --array=0-57
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --time=3-00:00:00

set -euo pipefail

module load SRAToolkit/3.0.1

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# read samples from sample tsv
## -t => skips trailing newline character as it reads each line
## <() => process substitution; runs command inside () as if it were file
## cut => extract columns from tsv
## -f1 => field 1 or first column
mapfile \
    -t \
    sample_types \
    < \
    <(cut \
        -f2 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2
    )

mapfile \
    -t \
    SRR_IDs \
    < \
    <(cut \
        -f1 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2
    )

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}

echo "Processing $sample_type ($accession)"

mkdir -p $wd_path/input/rna/${sample_type}/${accession}

prefetch $accession -O $wd_path/input/rna/${sample_type}

for sra_file in $wd_path/input/rna/${sample_type}/${accession}*/*.sra; do
    fasterq-dump "$sra_file" -O "$wd_path/input/rna/${sample_type}/${accession}" --split-files -e 8
done
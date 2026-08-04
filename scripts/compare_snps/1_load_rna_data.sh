#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=load_rna
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/rna_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/rna_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=1-00:00:00

set -euo pipefail

module load SRAToolkit/3.0.1

path_to_rna_input=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/rna

# SRX accessions
rna_accessions=(
    SRR22515680 # F420 cell line rna
    SRR22515682 # K7M2 cell line rna
    xx # Balbc rna
    xx # B6 rna
)

rna_accession=${rna_accessions[$SLURM_ARRAY_TASK_ID]}

mkdir -p $path_to_rna_input/$rna_accession

prefetch $rna_accession -O $path_to_rna_input

for sra_file in $path_to_rna_input/${rna_accession}*/*.sra; do
    fasterq-dump "$sra_file" -O "$path_to_rna_input" --split-files -e 8
done

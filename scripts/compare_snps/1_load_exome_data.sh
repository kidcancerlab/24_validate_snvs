#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=load_exome
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/exome_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/exome_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=1-00:00:00

module load SRAToolkit/3.0.1

path_to_exome_input=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/exome

# SRX accessions
exome_accessions=(
    SRR13611861 # F420 cell line exome
    SRR13611860 # K7M2 cell line exome
    SRR27799014 # Balbc exome
    SRR27799015 # B6 exome
)

exome_accession=${exome_accessions[$SLURM_ARRAY_TASK_ID]}

mkdir -p $path_to_exome_input/$exome_accession

prefetch $exome_accession -O $path_to_exome_input

for sra_file in $path_to_exome_input/${exome_accession}*/*.sra; do
    fasterq-dump "$sra_file" -O "$path_to_exome_input" --split-files -e 8
done
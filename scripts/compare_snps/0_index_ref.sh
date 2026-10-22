#!/bin/bash
#SBATCH --job-name=bwa_index
#SBATCH --partition=himem
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/bwa_index_%j.out
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/bwa_index_%j.err
#SBATCH --mem=100G
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4

module load bwa-mem2/2.2.1

bwa-mem2 index \
    -p \
    /home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/reference \
    ~/../../../../reference/mus_musculus/mm10/ucsc_assmebly/illumina_download/Sequence/BWAIndex/genome.fa
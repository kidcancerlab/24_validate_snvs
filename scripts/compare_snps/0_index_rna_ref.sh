#!/bin/bash
#SBATCH --job-name=rna_index
#SBATCH --partition=himem
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/rna_index_%j.out
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/rna_index_%j.err
#SBATCH --mem=100G
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4

# copied .fa file from: /reference/mus_musculus/GRCm38/ensembl/release-86/Sequence/WholeGenomeFasta/Mus_musculus.GRCm38.dna.primary_assembly.fa
# to my own input directory

module load SAMtools/1.15 \
    GATK/4.5.0.0-Java-17.0.2

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

samtools faidx \
    $wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.fa

gatk CreateSequenceDictionary \
    -R $wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.fa \
    -O $wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.dict
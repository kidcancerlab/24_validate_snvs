#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=load_exome
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/aligning_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/aligning_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=05:00:00

module load gcc/6.2.0 bwa/0.7.8 SAMtools/1.15

sample=(
    SRR13611861 # F420 cell line exome
    SRR13611860 # K7M2 cell line exome
    SRR27799014 # Balbc exome
    SRR27799015 # B6 exome
)

# first align to reference mm10, BL6
bwa mem -M -t 2 \
    /input/reference/XXXXX \
    /input/exome/${sample}_1.fastq /input/exome/${sample}_2.fastq \
    2> /output/bwa/logs/bwa_${sample}.err \
# correct any flaw in read-pairing introduced from aligner
    | samtools fixmate -m -@ 2 - - \
# sort to genome chromosome and coordinate
    | samtools sort -@ 2 -m 2G -o /output/bwa/${sample}_sorted.bam -T /output/bwa/tmp_${sample} --write-index - \
    2> /output/bwa/logs/sort_${sample}.err \
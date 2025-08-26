#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/mkfastq-%j.out
#SBATCH --error=slurmOut/mkfastq-%j.out
#SBATCH --job-name=mkfastq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=general,himem
#SBATCH --array=0-3
#SBATCH --wait

set -e ### stops bash script if line ends with error

# This is a bit different since two samples are reruns of two older samples and
# so we want to re-align using all of the fastq data combined per sample
echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

export PATH=/gpfs0/home2/gdrobertslab/lab/Tools/10x/cellranger-7.2.0:$PATH

sample_array=($( \
    cut -f 1 misc/mouse_samples_Roberts_barcoded_metadata.tsv \
    | grep -v Sample_ID \
))
this_sample=${sample_array[$SLURM_ARRAY_TASK_ID]}

sample_label=($( \
    cut -f 30 misc/mouse_samples_Roberts_barcoded_metadata.tsv \
    | grep -v cluster_label \
))
this_label=${sample_label[$SLURM_ARRAY_TASK_ID]}

echo ${this_sample} ${this_label}

cellranger \
    bamtofastq \
    --nthreads=8 \
    /home/gdrobertslab/lab/Counts_2/${this_sample}/possorted_genome_bam.bam \
    input/fastqs/${this_sample}

rename \
    bamtofastq \
    ${this_label} \
    input/fastqs/${this_sample}/*/*.fastq.gz

# mv \
#     input/fastqs/${this_sample}/*/*.fastq.gz \
#     input/fastqs/${this_label}/

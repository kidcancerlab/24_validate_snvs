#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/recount-%j.out
#SBATCH --error=slurmOut/recount-%j.out
#SBATCH --job-name=recount
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=general,himem
#SBATCH --array=0-1
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge

export PATH=/gpfs0/home2/gdrobertslab/lab/Tools/10x/cellranger-7.2.0:$PATH

sample_array=($( \
    cut -f 1 misc/mouse_samples_Roberts_realign_metadata.tsv \
    | grep -v Sample_ID \
))

this_sample=${sample_array[${SLURM_ARRAY_TASK_ID}]}

this_ref=custom_ref/gfp_rfp_mm10

echo ${this_sample} ${this_ref}

cellranger count \
    --id ${this_sample} \
    --output-dir output/cellranger_out/${this_sample} \
    --fastqs input/fastqs/${this_sample}/ \
    --localcores 10 \
    --transcriptome custom_ref/gfp_rfp_mm10 \
    --nosecondary \
    --disable-ui

rm output/cellranger_out/${this_sample}/_*

rm -r output/cellranger_out/${this_sample}/SC_RNA_COUNTER_CS

rm output/cellranger_out/${this_sample}/${this_sample}.mri.tgz

mv \
    output/cellranger_out/${this_sample}/outs/* \
    output/cellranger_out/${this_sample}/

rmdir output/cellranger_out/${this_sample}/outs
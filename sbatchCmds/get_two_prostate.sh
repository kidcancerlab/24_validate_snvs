#!/bin/sh
#SBATCH --output=input/othertumors/slurmout/two_prostate_get-%j.out
#SBATCH --error=input/othertumors/slurmout/two_prostate_get-%j.out
#SBATCH --job-name=prostate_get
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --partition=himem,general
#SBATCH --array=0-3
#SBATCH --wait


# HMP11_1
## SRR20761355
## SRR20761356
# HMP11_2
## SRR20761353
## SRR20761354

sras_dl=(SRR20761355
         SRR20761356
         SRR20761353
         SRR20761354)

sample_array=(HMP11_A
              HMP11_A
              HMP11_B
              HMP11_B)

echo ${sras_dl[@]}

this_sra=${sras_dl[${SLURM_ARRAY_TASK_ID}]}
this_sample=${sample_array[${SLURM_ARRAY_TASK_ID}]}

mkdir input/othertumors/fastqs/

prefetch ${this_sra} \
    -C yes \
    --max-size 300g \
    -O input/othertumors/fastqs/

fastq-dump \
    --split-files \
    --outdir input/othertumors/fastqs/ \
    input/othertumors/fastqs/${this_sra}/${this_sra}.sra

rm -r input/othertumors/fastqs/${this_sra}/${this_sra}.sra

pigz input/othertumors/fastqs/${this_sra}*.fastq

# need to rename the files:
# https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/fastq-input
# [Sample Name]_S1_L00[Lane Number]_[Read Type]_001.fastq.gz
# make lane number according to the order of SRR entries
mv \
    input/othertumors/fastqs/${this_sra}_1.fastq.gz \
    input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${SLURM_ARRAY_TASK_ID}_R1_001.fastq.gz

mv \
    input/othertumors/fastqs/${this_sra}_2.fastq.gz \
    input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${SLURM_ARRAY_TASK_ID}_R2_001.fastq.gz

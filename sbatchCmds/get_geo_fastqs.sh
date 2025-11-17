#!/bin/sh
#SBATCH --output=input/othertumors/slurmout/get_geo_fastq-%j.out
#SBATCH --error=input/othertumors/slurmout/get_geo_fastq-%j.out
#SBATCH --job-name=get_geo_fastq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --partition=himem,general
#SBATCH --wait

set -e

sras_dl=($(cut -f 2 misc/validation_geo_metadata.tsv | grep -v sra_number))

sample_array=($(cut -f 3 misc/validation_geo_metadata.tsv | grep -v Sample_ID))

lane_array=($(cut -f 7 misc/validation_geo_metadata.tsv | grep -v fake_lane))

this_sra=${sras_dl[${SLURM_ARRAY_TASK_ID}]}
this_sample=${sample_array[${SLURM_ARRAY_TASK_ID}]}
this_lane=${lane_array[${SLURM_ARRAY_TASK_ID}]}

echo ${this_sra} ${this_sample} ${this_lane} ${SLURM_ARRAY_TASK_ID}

if [ ! -d input/othertumors/fastqs/${this_sample} ]
then
    mkdir -p input/othertumors/fastqs/${this_sample}
fi

prefetch ${this_sra} \
    -C yes \
    --max-size 300g \
    -O input/othertumors/fastqs/${this_sample}

fastq-dump \
    --outdir input/othertumors/fastqs/${this_sample} \
    --split-files \
    input/othertumors/fastqs/${this_sample}/${this_sra}/${this_sra}.sra
# _1 is index
# _2 is R1 bc/umi
# _3 is R2 align

# For G0014
# _1 is R1
# _2 is R2

pigz -p 4 input/othertumors/fastqs/${this_sample}/${this_sra}*.fastq

# need to rename the files:
# https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/fastq-input
# [Sample Name]_S1_L00[Lane Number]_[Read Type]_001.fastq.gz
# make lane number according to the order of SRR entries

if [ -f input/othertumors/fastqs/${this_sample}/${this_sra}_4.fastq.gz ]
then
    echo _1 is index, _2 is index, _3 is R1 _4 is R2
    mv \
        input/othertumors/fastqs/${this_sample}/${this_sra}_3.fastq.gz \
        input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${this_lane}_R1_001.fastq.gz

    mv \
        input/othertumors/fastqs/${this_sample}/${this_sra}_4.fastq.gz \
        input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${this_lane}_R2_001.fastq.gz
elif [ -f input/othertumors/fastqs/${this_sample}/${this_sra}_3.fastq.gz ]
then
    echo _1 is index, _2 is R1 _3 is R2
    mv \
        input/othertumors/fastqs/${this_sample}/${this_sra}_2.fastq.gz \
        input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${this_lane}_R1_001.fastq.gz

    mv \
        input/othertumors/fastqs/${this_sample}/${this_sra}_3.fastq.gz \
        input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${this_lane}_R2_001.fastq.gz
else
    echo _1 is R1 _2 is R2
    mv \
        input/othertumors/fastqs/${this_sample}/${this_sra}_1.fastq.gz \
        input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${this_lane}_R1_001.fastq.gz

    mv \
        input/othertumors/fastqs/${this_sample}/${this_sra}_2.fastq.gz \
        input/othertumors/fastqs/${this_sample}/${this_sample}_S1_L00${this_lane}_R2_001.fastq.gz
fi

rm -r input/othertumors/fastqs/${this_sample}/${this_sra}/${this_sra}.sra

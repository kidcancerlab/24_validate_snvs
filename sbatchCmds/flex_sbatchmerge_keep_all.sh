#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=output/snv/flex/tempdir/slurmOut/flex_snv_merge-%j.out_merge-%j.out
#SBATCH --error=output/snv/flex/tempdir/slurmOut/flex_snv_merge-%j.out_merge-%j.out
#SBATCH --job-name=merge_bcfs
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --partition=himem,general
#SBATCH --wait


set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

bcftools merge \
        --threads 4 \
        -O u \
        output/snv/flex/tempdir/split_bcfs_[0-9]*_c1//*.bcf \
    | bcftools view \
        -O b \
        --output output/snv/flex//mergedflex_snvs_c1_keep_all.bcf

bcftools index \
    --threads 4 \
    output/snv/flex//mergedflex_snvs_c1_keep_all.bcf

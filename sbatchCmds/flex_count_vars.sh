#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/slurmOut_depth-%j.out
#SBATCH --error=slurmOut/slurmOut_depth-%j.out
#SBATCH --job-name=merge_bcfs
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --partition=himem,general
#SBATCH --time=02:00:00
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

bcf_files=($(ls output/snv/flex/tempdir/split_bcfs_*_c1/*.bcf | perl -pe 's/.+\///' | perl -pe 's/.bcf//'))

parallel \
    -j 10 \
    "bcftools view -O u output/snv/flex/tempdir/split_bcfs_*_c1/{}.bcf | bcftools query -f '[%CHROM\t%FIRST_ALT\t%DP\n]' | perlUnique.pl -c | sort -k 3n > output/flex/var_counts_d1/{}.txt" \
    ::: ${bcf_files[@]}

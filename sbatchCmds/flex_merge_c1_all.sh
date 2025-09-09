#!/bin/sh
#SBATCH --output=slurmOut/flex_snv_merge-%j.out
#SBATCH --error=slurmOut/flex_snv_merge-%j.out
#SBATCH --job-name=merge_bcfs
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --wait
#SBATCH --time=8:00:00
#SBATCH --partition=himem,general

ml purge
ml miniforge3
eval "$(conda shell.bash hook)"

set -e ### stops bash script if line ends with error

start_time=$(date +%s)

echo ${HOSTNAME} Beginning: $(date '+%Y-%m-%d %H:%M:%S')

conda activate scanBit_xkcd_1337

bcftools merge \
        --threads 3 \
        -O u \
        output/snv/flex/tempdir/split_bcfs_[0-9]*_c1/*.bcf \
    | bcftools view \
        -O b \
        -i 'N_ALT<=1' \
        --output output/snv/flex/mergedflex_snvs_c1_keep_all.bcf

bcftools index \
    --threads 3 \
    output/snv/flex/mergedflex_snvs_c1_keep_all.bcf

end_time=$(date +%s)

elapsed_seconds=$((end_time - start_time))

echo Done: $(date '+%Y-%m-%d %H:%M:%S')
echo Elapsed seconds: $elapsed_seconds

conda deactivate
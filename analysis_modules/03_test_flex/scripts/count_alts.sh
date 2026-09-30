#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/count_alts-%j.out
#SBATCH --error=slurmOut/count_alts-%j.out
#SBATCH --job-name=count_alts
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --partition=himem
#SBATCH --time=24:00:00
#SBATCH --wait
#SBATCH --export=NONE

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

python scripts/count_variant_pos.py \
    --threads 4 \
    --bcf output/03_test_flex/snvs/mergedflex_snvs_c1_keep_all.bcf \
    --verbose \
    > output/03_test_flex/counts/alt_pos_counts_flex.txt

echo "first count done"

# Filter out any multi-allelic site using -M 2
# bcftools view \
#     -M 2 \
#     -O b \
#     output/03_test_flex/snvs/mergedmouse_ours_c1_keep_all.bcf \
#   > temp_bcf_mouse.bcf

# bcftools index temp_bcf_mouse.bcf

# python scripts/count_variant_pos.py \
#     --threads 4 \
#     --bcf temp_bcf_mouse.bcf \
#     --verbose \
#     > output/03_test_flex/counts/alt_pos_counts_mouse.txt

# rm temp_bcf_mouse.bcf temp_bcf_mouse.bcf.csi

#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=output/snv/mouse/tempdir/slurmOut_merge-%j.out
#SBATCH --error=output/snv/mouse/tempdir/slurmOut_merge-%j.out
#SBATCH --job-name=count_alts
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --partition=himem
#SBATCH --time=24:00:00
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! I bet this has variants with more than one alt

python scripts/count_variant_pos.py \
    --threads 4 \
    --bcf output/snv/flex/mergedflex_snvs_c1_keep_all.bcf \
    --verbose \
    > output/snv/flex/alt_pos_counts.txt

echo "first count done"

python scripts/count_variant_pos.py \
    --threads 4 \
    --bcf output/snv/mouse/mergedmouse_ours_c1_keep_all.bcf \
    --verbose \
    > output/snv/mouse/alt_pos_counts.txt

#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/depth-%j.out
#SBATCH --error=slurmOut/depth-%j.out
#SBATCH --job-name=count_sc_vars
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --time=02:00:00
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

samples=$(ls -d output/04_read_depth_analysis/snv/geo/G00* | perl -pe 's/.+\///')

for sample in ${samples}
do
    echo "Processing sample ${sample}"

    export this_sample=${sample}

    parallel \
        -j 10 \
        --env this_sample \
        "bcftools view \
            -O u \
            -i 'GT[*]=\"alt\"' \
            {} \
          | bcftools query \
            -f '[%CHROM\t%FIRST_ALT\t%DP\n]' \
          > output/04_read_depth_analysis/depths/call_count/bcf_calls_depth_${this_sample}_{/.}.txt" \
        ::: output/04_read_depth_analysis/snv/geo/${sample}/tempdir/split_bcfs_1_c1/clust_*.bcf

done

find output/04_read_depth_analysis/depths/call_count/ -size 0G | xargs rm

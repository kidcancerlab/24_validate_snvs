#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/slurmOut_depth-%j.out
#SBATCH --error=slurmOut/slurmOut_depth-%j.out
#SBATCH --job-name=merge_bcfs
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --partition=himem
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

samples=$(ls -d output/read_depth/scanbit_out/x_samples/X00* | perl -pe 's/.+\///')

for sample in ${samples}
do
    echo "Processing sample ${sample}"

    export this_sample=${sample}

    parallel \
        -j 10 \
        --env this_sample \
        "bcftools view -O u -i 'GT[*]=\"alt\"' {} | bcftools query -f '[%CHROM\t%FIRST_ALT\t%DP\n]' > output/read_depth/depths/call_count/bcf_calls_depth_${this_sample}_{/.}.txt" \
        ::: output/read_depth/scanbit_out/x_samples/${sample}/tempdir/split_bcfs_1_c1/clust_*.bcf

done

find output/read_depth/depths/call_count/ -size 0G | xargs rm

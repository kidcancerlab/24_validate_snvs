#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/slurmOut_depth-%j.out
#SBATCH --error=slurmOut/slurmOut_depth-%j.out
#SBATCH --job-name=geo_readdepth
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --partition=general,himem
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

samples=$(ls -d output/read_depth/scanbit_out/geo_samples/G00* | perl -pe 's/.+\///')

for sample in ${samples}
do
    echo "Processing sample ${sample}"

    export this_sample=${sample}

    # Count the number of positions covered, both variant and ref
    parallel \
        -j 10 \
        --env this_sample \
        'echo -e "depth\tcount" \
            > output/read_depth/depths/bcf_depth/bcf_depth_${this_sample}_{/.}.txt;
        bcftools query \
                -f "[%DP\n]" \
                {} \
            | perlUnique.pl -c \
            | sort -k1n \
            >> output/read_depth/depths/bcf_depth/bcf_depth_${this_sample}_{/.}.txt' \
        ::: output/read_depth/scanbit_out/geo_samples/${sample}/tempdir/split_bcfs_1_c1/clust_*.bcf

    # Count number of positions with variant at any position in the sample
    # Begin by filtering down to just variant positions
    parallel \
        -j 10 \
        --env this_sample \
        "echo -e 'depth\tcount' \
            > output/read_depth/depths/bcf_depth/variant_pos_${this_sample}_{/.}.txt;
        bcftools view \
                -i 'GT[*]=\"alt\"' \
                -O u \
                {} \
            | bcftools query -f '[%DP\n]' \
            | perlUnique.pl -c \
            | sort -k1n \
            >> output/read_depth/depths/bcf_depth/variant_pos_${this_sample}_{/.}.txt" \
        ::: output/read_depth/scanbit_out/geo_samples/${sample}/tempdir/split_bcfs_1_c1/clust_*.bcf
done

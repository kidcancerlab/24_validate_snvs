#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/slurmOut_shared-%j.out
#SBATCH --error=slurmOut/slurmOut_shared-%j.out
#SBATCH --job-name=count_sc_shared
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=himem
#SBATCH --time=02:00:00
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge
ml load Miniconda3/4.9.2

eval "$(conda shell.bash hook)"
conda activate scanBit_xkcd_1337

samples=$(ls -d output/read_depth/scanbit_out/geo_samples/G00* | perl -pe 's/.+\///')

cutoffs=(1 2 5 10 20)

for sample in ${samples}
do
    echo "Processing sample ${sample}"
    for cutoff in ${cutoffs[@]}
    do
        export this_sample=${sample}
        export this_cutoff=${cutoff}

        python scripts/count_shared_pos.py \
            --bcf output/read_depth/scanbit_out/geo_samples/${this_sample}/downsample_1_cells/mergeddownsample_${this_sample}_1_c${this_cutoff}.bcf \
            > output/read_depth/shared/shared_${this_sample}_${this_cutoff}.txt
    done
done

conda deactivate

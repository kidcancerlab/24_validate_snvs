#!/bin/sh
#SBATCH --output=input/othertumors/slurmout/two_prostate_count-%j.out
#SBATCH --error=input/othertumors/slurmout/two_prostate_count-%j.out
#SBATCH --job-name=prostate_count
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --partition=himem,general
#SBATCH --array=0-1
#SBATCH --wait

set -e

sample_array=(HMP11_A
              HMP11_B)

this_sample=${sample_array[${SLURM_ARRAY_TASK_ID}]}

if [ ! -d output/cellranger_out/${this_sample} ]
then
    mkdir -p output/cellranger_out/${this_sample}
fi

RefFolder=/home/gdrobertslab/lab/GenRef

export PATH=/gpfs0/home2/gdrobertslab/lab/Tools/10x/cellranger-7.2.0:$PATH

cellranger count \
  --id ${this_sample} \
  --fastqs input/othertumors/fastqs/${this_sample}/ \
  --sample ${this_sample} \
  --transcriptome ${RefFolder}/10x-hg38 \
  --localcores 10 \
  --expect-cells 8000 \
  --nosecondary \
  --disable-ui \
  --output-dir output/cellranger_out/${this_sample}

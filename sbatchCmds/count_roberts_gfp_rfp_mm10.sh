#!/bin/sh
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/recount-%j.out
#SBATCH --error=slurmOut/recount-%j.out
#SBATCH --job-name=recount
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --partition=general,himem
#SBATCH --array=0-3
#SBATCH --wait

set -e ### stops bash script if line ends with error

echo ${HOSTNAME} ${SLURM_ARRAY_TASK_ID}

ml purge

export PATH=/gpfs0/home2/gdrobertslab/lab/Tools/10x/cellranger-7.2.0:$PATH

sample_name_array=(S0122 S0123 S0260 S0261)
this_sample=${sample_name_array[$SLURM_ARRAY_TASK_ID]}

cellranger count \
    --id ${this_sample} \
    --output-dir output/cellranger_out/${this_sample} \
    --fastqs input/fastqs/${this_sample}/ \
    --localcores 10 \
    --transcriptome custom_ref/gfp_rfp_mm10 \
    --nosecondary \
    --disable-ui

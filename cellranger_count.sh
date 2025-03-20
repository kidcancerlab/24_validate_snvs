#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=mk_counts_%j
#SBATCH --output=counts/output/%j.txt
#SBATCH --error=counts/output/%j.txt
#SBATCH --array=0-2
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00
#SBATCH --wait

set -e

#make array of values
sra_array=(SRR26705626 SRR26705627 SRR26705629)
sra_id=${sra_array[$SLURM_ARRAY_TASK_ID]}

mv counts/output/${SLURM_JOBID}.txt counts/output/${sra_id}.txt

echo Running cellranger count for $sra_id

#Run cellranger
cellranger count \
    --id ${sra_id} \
    --output-dir counts/${sra_id} \
    --fastqs input/fastqs/${sra_id}/ \
    --localcores 20 \
    --transcriptome custom_ref/demo_GFP \
    --nosecondary \
    --disable-ui \
    --create-bam true
#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=mk_counts_%j
#SBATCH --output=counts/GSE247228/output/%j.txt
#SBATCH --error=counts/GSE247228/output/%j.txt
#SBATCH --array=0-2
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00
#SBATCH --wait

set -e
ml cellranger
#make array of values
# sra_array=(SRR26705626 SRR26705627 SRR26705629)
sra_array=(SRR26705628 SRR26705630 SRR26705631)
sra_id=${sra_array[$SLURM_ARRAY_TASK_ID]}

mv counts/GSE247228/output/${SLURM_JOBID}.txt counts/GSE247228/output/${sra_id}.txt

echo Running cellranger count for $sra_id

#Run cellranger
cellranger count \
    --id ${sra_id} \
    --output-dir counts/GSE247228/${sra_id} \
    --fastqs input/fastqs/GSE247228/${sra_id}/ \
    --localcores 20 \
    --transcriptome custom_ref/eGFP/demo_eGFP \
    --nosecondary \
    --disable-ui \
    --create-bam true
#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=mk_counts_%j
#SBATCH --output=counts/GSE201615/output/%j.txt
#SBATCH --error=counts/GSE201615/output/%j.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00
#SBATCH --wait

set -e
ml cellranger
sra_array=(SRR18932562 SRR18932563 SRR18932566 SRR18932567)
sra_id=${sra_array[$SLURM_ARRAY_TASK_ID]}

mv counts/GSE201615/output/${SLURM_JOBID}.txt counts/GSE201615/output/${sra_id}.txt

echo Running cellranger count for $sra_id

cellranger count \
    --id ${sra_id} \
    --output-dir counts/GSE201615/${sra_id} \
    --fastqs input/fastqs/GSE201615/${sra_id}/ \
    --localcores 20 \
    --transcriptome custom_ref/RFP/full_RFP \
    --nosecondary \
    --disable-ui \
    --create-bam true
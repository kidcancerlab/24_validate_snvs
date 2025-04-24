#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=mk_counts_%j
#SBATCH --output=counts/GSE179077/output/%j.txt
#SBATCH --error=counts/GSE179077/output/%j.txt
#SBATCH --array=0-7
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00
#SBATCH --wait

set -e
ml cellranger
#make array of values
sra_array=(SRR29428580 SRR29428581 SRR29428582 SRR29428583 SRR29428584 SRR29428585 SRR29428586 SRR29428587)
sra_id=${sra_array[$SLURM_ARRAY_TASK_ID]}

mv counts/GSE179077/output/${SLURM_JOBID}.txt counts/GSE179077/output/${sra_id}.txt

echo Running cellranger count for $sra_id

#Run cellranger
cellranger count \
    --id ${sra_id} \
    --output-dir counts/GSE179077/${sra_id} \
    --fastqs input/fastqs/GSE179077/${sra_id}/ \
    --localcores 20 \
    --transcriptome custom_ref/unag/unag_ref \
    --nosecondary \
    --disable-ui \
    --create-bam true
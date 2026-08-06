#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=merge_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/merge_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/merge_%A_%a.txt
#SBATCH --array=0-57
#SBATCH --cpus-per-task=10
#SBATCH --partition=himem,general
#SBATCH --time=2-00:00:00

set -euo pipefail

ml purge

module load \
    GCC/9.3.0 \
    GCCcore/9.3.0 \
    BCFtools/1.11 \
    SAMtools/1.15

bcftools merge \
    --threads 10 \
    --output output/rna/vcfs/${sample_type}/${sample_type}.vcf.gz \
    -O z \
    output/rna/vcfs/${sample_type}/*.vcf.gz

bcftools index $wd_path/output/rna/vcfs/${sample_type}/${accession}.vcf.gz

# rm output/rna/vcfs/${sample_type}/*SRR*.vcf.gz
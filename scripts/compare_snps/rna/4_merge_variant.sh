#!/bin/bash
#SBATCH --job-name=merge_variant
#SBATCH --partition=himem
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/merge/merge_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/merge/merge_%A_%a.txt
#SBATCH --mem=100G
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4

# don't actually need to run this for my workflow

set -euo pipefail

ml purge

module load \
    GCC/9.3.0 \
    GCCcore/9.3.0 \
    BCFtools/1.11 \
    SAMtools/1.15

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

bcftools merge \
    --threads 10 \
    --output $wd_path/output/rna/vcfs/all_sample_types.vcf.gz \
    -O z \
    $wd_path/output/rna/vcfs/*/*.vcf.gz

echo "**Finished merging, now indexing..."

bcftools index $wd_path/output/rna/vcfs/all_sample_types.vcf.gz
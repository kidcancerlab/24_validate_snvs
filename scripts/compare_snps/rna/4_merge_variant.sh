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

echo "**Merging all samples."

bcftools merge \
    --threads 10 \
    --output $wd_path/output/rna/vcfs/merged.vcf.gz \
    -O z \
    $wd_path/output/rna/vcfs/*/*.vcf.gz

echo "**Finished merging, now indexing..."

echo "**Indexing file."

bcftools index $wd_path/output/rna/vcfs/merged.vcf.gz

echo "**Keeping only shared sites from all samples."

# keep only regions that overlap in every sample (missing = ./. at site)
bcftools view \
    -i 'F_MISSING==0' \
    $wd_path/output/rna/vcfs/merged.vcf.gz \
    -O z \
    -o $wd_path/output/rna/vcfs/merged_shared.vcf.gz

echo "**Indexing file."

bcftools index $wd_path/output/rna/vcfs/merged_shared.vcf.gz

# now, keep any regions that has a variant at any of the shared sites, across all samples
bcftools view \
    -i 'GT[*]="alt"' \
    $wd_path/output/rna/vcfs/merged_shared.vcf.gz \
    -O z \
    -o $wd_path/output/rna/vcfs/merged_shared_variant.vcf.gz

bcftools index $wd_path/output/rna/vcfs/merged_shared_variant.vcf.gz
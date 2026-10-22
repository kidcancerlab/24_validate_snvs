#!/bin/bash
#SBATCH --job-name=merge_variant
#SBATCH --partition=himem
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/4_merge/logs/merge_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/4_merge/logs/merge_%A_%a.txt
#SBATCH --mem=100G
#SBATCH --time=2-00:00:00
#SBATCH --cpus-per-task=5

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

mkdir -p $wd_path/output/rna/4_merge

bcftools merge \
    --threads 5 \
    --output $wd_path/output/rna/4_merge/merged.bcf \
    -O b \
    $wd_path/output/rna/3_run_rna/*/*.bcf

echo "**Finished merging, now indexing..."

echo "**Indexing file."

bcftools index $wd_path/output/rna/4_merge/merged.bcf

echo "**Keeping only shared sites from all samples."

# keep only regions that overlap in every sample (missing = ./. at site)
bcftools view \
    -i 'F_MISSING<0.25' \
    $wd_path/output/rna/4_merge/merged.bcf \
    -O z \
    -o $wd_path/output/rna/4_merge/merged_shared.vcf.gz

echo "**Indexing file."

bcftools index $wd_path/output/rna/4_merge/merged_shared.vcf.gz

# now, keep any regions that has a variant at any of the shared sites, across all samples
# use the below file for the tree
bcftools view \
    -i 'GT[*]="alt"' \
    $wd_path/output/rna/4_merge/merged_shared.vcf.gz \
    -O z \
    -o $wd_path/output/rna/4_merge/merged_shared_variant.bcf

bcftools index $wd_path/output/rna/4_merge/merged_shared_variant.bcf 

# convert bcf file to vcf.gz for easy reading
bcftools view \
    $wd_path/output/rna/4_merge/merged_shared_variant.bcf \
    -O z \
    -o $wd_path/output/rna/4_merge/merged_shared_variant.vcf.gz

bcftools index $wd_path/output/rna/4_merge/merged_shared_variant.vcf.gz
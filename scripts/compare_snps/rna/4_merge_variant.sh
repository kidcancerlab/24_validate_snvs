#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=merge_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/merge/merge_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/merge/merge_%A_%a.txt
#SBATCH --array=0-3
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

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# read samples from sample tsv
mapfile \
    -t \
    sample_types \
    < \
    <(cut \
        -f2 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        | uniq
    )


sample_types=($(cut \
        -f2 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        | uniq))

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}

echo "**Processing $sample_type"

bcftools merge \
    --threads 10 \
    --output $wd_path/output/rna/vcfs/${sample_type}.vcf.gz \
    -O z \
    $wd_path/output/rna/vcfs/${sample_type}/*.vcf.gz

echo "**Finished merging, now indexing..."

bcftools index $wd_path/output/rna/vcfs/${sample_type}.vcf.gz

# rm output/rna/vcfs/${sample_type}/*SRR*.vcf.gz
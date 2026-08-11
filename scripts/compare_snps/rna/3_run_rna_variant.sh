#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=call_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/variant/variant_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/variant/variant_%A_%a.txt
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

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

# read samples from sample tsv
mapfile \
    -t \
    sample_types \
    < \
    <(cut \
        -f2 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2
    )

mapfile \
    -t \
    SRR_IDs \
    < \
    <(cut \
        -f1 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2
    )

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}

echo "Processing $sample_type ($accession)"

mkdir -p $wd_path/output/rna/vcfs/${sample_type}

if [ ! -f "$wd_path/output/rna/bwa/${sample_type}/${accession}/${accession}_markdup.bam" ]; then
    echo "Input file not found for sample ${sample_type} (${accession}). Skipping." >&2
    exit 0
fi

if [ ! -f "$wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.fa" ]; then
    echo "Reference file not found. Skipping." >&2
    exit 0
fi

if [ ! -f "$wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.fa" ]; then
    echo "Reference file not found. Skipping." >&2
    exit 0
fi

bcftools mpileup \
    --threads 3 \
    --max-depth 2000 \
    -O u \
    -f $wd_path/input/reference/GRCm38/Mus_musculus.GRCm38.dna.primary_assembly.fa \
    $wd_path/output/rna/bwa/${sample_type}/${accession}/${accession}_markdup.bam | \
bcftools call \
    --threads 3 \
    -m \
    -O u | \
bcftools filter \
    --threads 3 \
    -g 10 \
    -s LowQual \
    -e "QUAL<20 || DP<20" \
    -O u | \
bcftools view \
    --threads 3 \
    -O z \
    -i 'GT[*]="alt"' \
    -o $wd_path/output/rna/vcfs/${sample_type}/${accession}.vcf.gz

bcftools index $wd_path/output/rna/vcfs/${sample_type}/${accession}.vcf.gz
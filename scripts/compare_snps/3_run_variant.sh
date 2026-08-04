#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=call_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/variant_call/variant_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/input/logs/variant_call/variant_%A_%a.txt
#SBATCH --array=0-3
#SBATCH --cpus-per-task=20
#SBATCH --partition=himem,general
#SBATCH --time=1-00:00:00

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
        $wd_path/misc/compare_snps_samples.tsv \
        | tail -n +2
    )

mapfile \
    -t \
    SRR_IDs \
    < \
    <(cut \
        -f1 \
        $wd_path/misc/compare_snps_samples.tsv \
        | tail -n +2
    )

sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}

echo "Processing $sample_type ($accession)"

bcftools mpileup \
    --threads 3 \
    --max-depth 2000 \
    -O u \
    -f ~/../../../../reference/mus_musculus/mm10/ucsc_assmebly/illumina_download/Sequence/BWAIndex/genome.fa \
    $wd_path/output/bwa/${sample_type}/${accession}/${accession}.bam | \
bcftools call \
    --threads 3 \
    -m \
    -O u | \
bcftools filter \
    --threads 3 \
    -g 10 \
    -s LowQual \
    -e "QUAL<20 | DP<20" \
    -O u | \
bcftools view \
    --threads 3 \
    --exclude-types indels \
    -O z \
    -o output/vcfs/${sample_type}/${accession}.vcf.gz

bcftools concat \
    --threads 10 \
    --output output/vcfs/${sample_type}/${sample_type}.vcf.gz \
    -O z \
    output/vcfs/${sample_type}/*.vcf.gz

rm output/vcfs/${sample_type}/*SRR*.vcf.gz
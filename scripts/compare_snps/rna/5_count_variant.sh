#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=count_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/count/count_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/count/count_%A_%a.txt
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
sample_types=($(cut \
        -f2 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        ))

SRR_IDs=($(cut \
        -f1 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        ))

locations=($(cut \
        -f3 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        ))

accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}
sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
location=${locations[$SLURM_ARRAY_TASK_ID]}

echo "**Processing $sample_type ($accession)"

mkdir -p $wd_path/output/rna/count/${sample_type}

if [ ! -f "$wd_path/output/rna/bwa/${sample_type}/${accession}/${accession}_markdup.bam" ]; then
    echo "Input file not found for sample ${sample_type} (${accession}). Skipping." >&2
    exit 0
fi

bam=$wd_path/output/rna/bwa/${sample_type}/${accession}/${accession}_markdup.bam
vcf=$wd_path/output/rna/vcfs/${sample_type}/${accession}.vcf.gz

mkdir -p $wd_path/output/rna/count

# covered Mb (depth >=10)
covered_bases=$(samtools depth -a "$bam" | awk '$3>=10' | wc -l)
covered_mb=$(echo "scale=6; $covered_bases / 1000000" | bc)

# PASS SNV count
variant_count=$(bcftools view -H -f PASS -v snps "$vcf" | wc -l)

# mutations per Mb (guard against divide-by-zero)
if (( $(echo "$covered_mb > 0" | bc -l) )); then
    mut_per_mb=$(echo "scale=6; $variant_count / $covered_mb" | bc)
else
    mut_per_mb="NA"
fi

# write this sample's row to its own file
printf "%s\t%s\t%s\t%s\t%s\n" \
    "$accession" "$sample_type" "$location" "$variant_count" "$covered_mb" "$mut_per_mb" \
    > $wd_path/output/rna/count/${sample_type}/${accession}_count.tsv
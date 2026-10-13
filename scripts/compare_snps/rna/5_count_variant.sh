#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --job-name=count_variant
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/count/logs/count_%A_%a.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/count/logs/count_%A_%a.txt
#SBATCH --array=0-29
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
new_names=($(cut \
        -f3 \
        $wd_path/misc/compare_rna_snps_samples.tsv \
        | tail -n +2 \
        ))


accession=${SRR_IDs[$SLURM_ARRAY_TASK_ID]}
sample_type=${sample_types[$SLURM_ARRAY_TASK_ID]}
location=${locations[$SLURM_ARRAY_TASK_ID]}
name=${new_names[$SLURM_ARRAY_TASK_ID]}

echo "**Processing $sample_type ($accession)"

mkdir -p $wd_path/output/rna/5_count/${sample_type}

if [[ $accession == SRR* ]]; then
    bam=$wd_path/output/rna/2_align/${sample_type}/${accession}/${accession}_markdup.bam
else
    bam=$wd_path/output/rna/2_align/${sample_type}/${accession}_markdup.bam
fi


bcf=$wd_path/output/rna/3_run_rna/${sample_type}/${name}.bcf

mkdir -p $wd_path/output/rna/5_count

# covered bases (depth (third column) >=10)
covered_bases=$(samtools depth -a "$bam" | awk '$3>=10' | wc -l)
# covered Mb (in scientific notation, keeps six numbers behind decimals) & convert to Mb
covered_mb=$(echo "scale=6; $covered_bases / 1000000" | bc)

# keep only files that PASS in the quality filter
# keep snps
# wc -l = count them
variant_count=$(bcftools view -H -f PASS -v snps "$bcf" | wc -l)

# mutations per Mb (guard against divide-by-zero)
if (( $(echo "$covered_mb > 0" | bc -l) )); then
    mut_per_mb=$(echo "scale=6; $variant_count / $covered_mb" | bc)
else
    mut_per_mb="NA"
fi

# write this sample's row to its own file
printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$accession" "$sample_type" "$sample_name" "$location" "$variant_count" "$covered_mb" "$mut_per_mb" \
    > $wd_path/output/rna/5_count/${sample_type}/${name}_count.csv
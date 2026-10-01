#!/bin/bash
#SBATCH --account=gdrobertslab
#SBATCH --output=slurmOut/numbat-%j.out
#SBATCH --error=slurmOut/numbat-%j.out
#SBATCH --job-name=numbat
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=himem
#SBATCH --time=24:00:00
#SBATCH --wait

set -e

# This program only works on human data

human_data=(
  $(grep 10x-hg38 misc/validation_geo_metadata.tsv \
    | cut -f 3 \
    | sort \
    | uniq \
    | grep -v Sample_ID\
  )
)

this_sample=${human_data[${SLURM_ARRAY_TASK_ID}]}

# Prep alignment data and pileup
singularity exec \
    --no-home \
    --cleanenv \
    --bind $(pwd):/project \
    --home "$(pwd):/project" \
    --pwd /project \
    numbat-rbase_latest.sif \
  /numbat/inst/bin/pileup_and_phase.R \
    --label ${this_sample} \
    --samples ${this_sample} \
    --bams output/cellranger_out/${this_sample}/possorted_genome_bam.bam \
    --barcodes output/cellranger_out/${this_sample}/filtered_feature_bc_matrix/barcodes.tsv.gz \
    --gmap /Eagle_v2.4.1/tables/genetic_map_hg38_withX.txt.gz \
    --snpvcf input/numbat/genome1K.phase3.SNP_AF5e2.chr1toX.hg38.vcf.gz \
    --paneldir input/numbat/1000G_hg38/ \
    --outdir output/10_cmp_other_methods/numbat_results/numbat_temp/${this_sample} \
    --ncores 4

echo "Finished preparing alignment data and pileup for sample ${this_sample}"

# Run numbat
singularity exec \
  --no-home \
  --cleanenv \
  --bind $(pwd):/project \
  --home "$(pwd):/project" \
  --pwd /project \
  numbat-rbase_latest.sif \
  Rscript --no-init-file \
    analysis_modules/10_cmp_other_methods/scripts/run_numbat.R \
    ${this_sample}

#!/bin/bash
#SBATCH --job-name=tsv_combine
#SBATCH --partition=himem
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/6_combine/logs/combine_%j.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/6_combine/logs/combine_%j.txt
#SBATCH --mem=100G
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

files=($wd_path/output/rna/5_count/*/*_count.csv)

out="$wd_path/output/rna/6_combine"

mkdir -p ${out}

out_file="$out/combined.csv"

printf "accession,sample_type,sample_name,location,variant_count,covered_mb,mutations_per_mb\n" > "$out_file"

cat "${files[@]}" | tr '\t' ',' >> "$out_file"
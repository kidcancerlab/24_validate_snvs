#!/bin/bash
#SBATCH --job-name=tsv_combine
#SBATCH --partition=himem
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/count/combine_%j.txt
#SBATCH --error=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/vcfs/logs/count/combine_%j.txt
#SBATCH --mem=100G
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=4

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

files=($wd_path/output/rna/count/*/*_count.tsv)

printf "accession\tsample_type\tlocation\tvariant_count\tcovered_mb\tmutations_per_mb\n" > $wd_path/output/rna/count/combined.tsv

cat "${files[@]}" >> $wd_path/output/rna/count/combined.tsv
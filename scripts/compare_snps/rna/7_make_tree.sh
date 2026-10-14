#!/usr/bin/env bash
#SBATCH --job-name=tree
#SBATCH --account=gdrobertslab
#SBATCH --partition=himem
#SBATCH --mem=200G
#SBATCH --time=02:00:00
#SBATCH --output=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs/output/rna/figures/logs/tree_%j.out

set -euo pipefail

module load \
    GCC/7.3.0 \
    OpenMPI/3.1.1 \
    Python/3.6.6 \
    Pysam/0.15.1 \
    matplotlib/3.0.0

wd_path=/home/gdrobertslab/lab/Analysis/Katie/24_validate_snvs

py_file="$wd_path/scripts/vcfToMatrix.py"
bcf_file="$wd_path/output/rna/vcfs/merged_shared_variant.bcf"

python "$py_file" --bcf "$bcf_file"
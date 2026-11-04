#!/bin/bash
#SBATCH --error=slurmOut/meta-%j.txt
#SBATCH --output=slurmOut/meta-%j.txt
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name flex_data
#SBATCH --wait
#SBATCH --time=0-12:00:00

set -e

cd input/10x_flex/
# Data from https://www.10xgenomics.com/datasets/40k-mixture-of-cells-dissociated-from-4-fixed-mouse-tissues-using-manual-dissociation-multiplexed-samples-4-probe-barcodes-1-standard

mkdir -p flex_eye
mkdir -p flex_ovary
mkdir -p flex_stomach
mkdir -p flex_intestine

# Eye Output Files
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1_web_summary.html \
    -O flex_eye/web_summary.html
wget https://s3-us-west-2.amazonaws.com/10x.files/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1_count_sample_alignments.bam \
    -O flex_eye/count_sample_alignments.bam
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1_count_sample_alignments.bam.bai \
    -O flex_eye/count_sample_alignments.bam.bai
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Eye_Manual_BC1_count_sample_filtered_feature_bc_matrix.h5 \
    -O flex_eye/filtered_feature_bc_matrix.h5

# Ovary Output Files
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2_web_summary.html \
    -O flex_ovary/web_summary.html
wget https://s3-us-west-2.amazonaws.com/10x.files/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2_count_sample_alignments.bam \
    -O flex_ovary/count_sample_alignments.bam
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2_count_sample_alignments.bam.bai \
    -O flex_ovary/count_sample_alignments.bam.bai
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Ovary_Manual_BC2_count_sample_filtered_feature_bc_matrix.h5 \
    -O flex_ovary/filtered_feature_bc_matrix.h5

# Stomach Output Files
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3_web_summary.html \
    -O flex_stomach/web_summary.html
wget https://s3-us-west-2.amazonaws.com/10x.files/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3_count_sample_alignments.bam \
    -O flex_stomach/count_sample_alignments.bam
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3_count_sample_alignments.bam.bai \
    -O flex_stomach/count_sample_alignments.bam.bai
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Stomach_Manual_BC3_count_sample_filtered_feature_bc_matrix.h5 \
    -O flex_stomach/filtered_feature_bc_matrix.h5

# intestine Output Files
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4_web_summary.html \
    -O flex_intestine/web_summary.html
wget https://s3-us-west-2.amazonaws.com/10x.files/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4_count_sample_alignments.bam \
    -O flex_intestine/count_sample_alignments.bam
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4_count_sample_alignments.bam.bai \
    -O flex_intestine/count_sample_alignments.bam.bai
wget https://cf.10xgenomics.com/samples/cell-exp/7.1.0/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4/4plex_mouse_eye_ovary_intest_stom_manual_dissoc_multiplex_Small_Intestine_Manual_BC4_count_sample_filtered_feature_bc_matrix.h5 \
    -O flex_intestine/filtered_feature_bc_matrix.h5



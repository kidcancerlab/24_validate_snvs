#!/usr/bin/env Rscript

library(copykat)

source("analysis_modules/10_cmp_other_methods/10_helper_functions.R")

this_sample <- commandArgs(trailingOnly = TRUE)[1]
species <- commandArgs(trailingOnly = TRUE)[2]

counts_matrix <-
  qs2::qs_read(paste0(
    "output/01_process_raw/rdata/individual/",
    this_sample,
    "_",
    species,
    ".qs2"
  )) |>
    Seurat::GetAssayData(layer = "counts") |>
    as.matrix() # gene x cell integer UMI count matrix


copykat_out <-
  run_copykat(
    count_mat = counts_matrix,
    species = species,
    temp_dir = paste0("output/10_cmp_other_methods/copykat_results/temp/", this_sample),
    sample_name = this_sample
  )

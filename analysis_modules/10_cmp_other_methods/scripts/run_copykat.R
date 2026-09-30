#!/usr/bin/env Rscript

library(copykat)

source("analysis_modules/10_cmp_other_methods/10_helper_functions.R")

this_sample <- commandArgs(trailingOnly = TRUE)[1]
species <- commandArgs(trailingOnly = TRUE)[2]

copykat_out <-
  run_copykat(
    count_mat = readRDS(paste0(
      "output/10_cmp_other_methods/numbat_results/rdata/",
      this_sample,
      "_human_counts.rds"
    )) |>
      as.matrix(), # gene x cell integer UMI count matrix
    species = species,
    temp_dir = paste0("output/10_cmp_other_methods/copykat_results/temp/", this_sample)
  )

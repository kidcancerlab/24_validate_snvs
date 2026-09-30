#!/usr/bin/env Rscript

source("analysis_modules/10_cmp_other_methods/10_helper_functions.R")

this_sample <- commandArgs(trailingOnly = TRUE)[1]
species <- commandArgs(trailingOnly = TRUE)[2]

run_scevan(
  sobj = qs2::qs_read(paste0(
    "output/01_process_raw/rdata/individual/",
    this_sample,
    "_",
    species,
    ".qs2"
  )),
  organism = species,
  sample_name = this_sample,
  temp_dir = "output/10_cmp_other_methods/scevan_results/temp_dir/"
)

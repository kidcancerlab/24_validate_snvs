#!/usr/bin/env Rscript

source("analysis_modules/10_cmp_other_methods/10_helper_functions.R")

this_sample <- commandArgs(trailingOnly = TRUE)[1]
species <- commandArgs(trailingOnly = TRUE)[2]

infercna_wrapper(
  sobj = qs2::qs_read(paste0(
    "output/01_process_raw/rdata/individual/",
    this_sample,
    "_",
    species,
    ".qs2"
  )),
  species = species,
  sample_name = this_sample
)

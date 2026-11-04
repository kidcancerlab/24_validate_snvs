#!/usr/bin/env Rscript

library(numbat)

this_sample <- commandArgs(trailingOnly = TRUE)[1]

print(paste0("Running numbat for sample: ", this_sample))
print(paste0("Current working directory: ", getwd()))

source("analysis_modules/10_cmp_other_methods/10_helper_functions.R")

numbat_out <-
  run_numbat(
    count_mat = readRDS(paste0(
      "output/10_cmp_other_methods/numbat_results/rdata/counts/",
      this_sample,
      "_human_counts.rds"
    )), # gene x cell integer UMI count matrix
    lambdas_ref = ref_hca, # reference expression profile, a gene x cell type normalized expression level matrix
    df_allele = read.delim(
      paste0(
        "output/10_cmp_other_methods/numbat_results/numbat_temp/",
        this_sample,
        "/",
        this_sample,
        "_allele_counts.tsv.gz"
      ),
      sep = "\t"
    ),
    genome = "hg38",
    t = 1e-5,
    ncores = 4,
    plot = TRUE,
    out_dir = paste0(
      "output/10_cmp_other_methods/numbat_results/rdata/",
      this_sample,
      "/output"
    )
  )

saveRDS(
  numbat_out,
  paste0(
    "output/10_cmp_other_methods/numbat_results/rdata/results/",
    this_sample,
    "_numbat_out.rds"
  )
)

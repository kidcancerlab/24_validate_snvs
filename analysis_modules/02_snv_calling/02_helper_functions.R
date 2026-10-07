## Helper function to run scanbit
# This asssumes a bunch of things about the structure of this project
scanbit_one_sample <- function(
  this_sample,
  species,
  ploidy,
  ref_fasta,
  out_dir,
  temp_dir
) {
  sobj <-
    qs2::qs_read(paste0(
      "output/01_process_raw/rdata/individual/",
      this_sample,
      "_",
      species,
      ".qs2"
    ))

  sobj$cell_group <-
    paste0(
      sobj$cluster_label,
      "_c",
      sobj$individ_clusters
    )

  cell_barcode_group_table <-
    sobj@meta.data |>
    dplyr::select(cell_group, cell_barcode, bam_file) |>
    dplyr::as_tibble()

  job_worked <-
    scanBit::get_snp_tree(
      cellid_bam_table = cell_barcode_group_table,
      ploidy = ploidy,
      output_dir = out_dir,
      temp_dir = temp_dir, #paste0("/gpfs0/scratch/mvc002/scanbit/", this_sample),
      output_base_name = paste0("snvs_", this_sample),
      ref_fasta = ref_fasta,
      min_depth = c(5, 10, 20, 30),
      job_base = paste0("sb_", this_sample),
      log_base = paste0("slurmOut/snv_", this_sample),
      min_snvs_per_cluster = 200,
      n_bootstraps = 10000,
      max_prop_missing_at_site = 0.9,
      tree_image_type = "pdf",
      cleanup = TRUE,
      other_job_header_options = c(
        "--time=8:00:00",
        "--partition=himem,general"
      ),
      other_batch_options = c(
        "ml purge"
      ),
      use_apptainer = TRUE
    )

  return(job_worked)
}

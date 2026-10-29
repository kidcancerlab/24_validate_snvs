## Helper function to run scanbit
# This asssumes a bunch of things about the structure of this project
scanbit_one_sample <- function(
  this_sample,
  species,
  ploidy,
  ref_fasta,
  out_dir,
  temp_dir,
  control_celltypes = c(
    "T cells",
    "NK cells",
    "CD4+ T cells",
    "CD8+ T cells",
    "Macrophages" ##########
  )
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
      temp_dir = temp_dir,
      output_base_name = paste0("snvs_", this_sample),
      ref_fasta = ref_fasta,
      min_depth = c(5, 10, 20, 30),
      job_base = paste0("sb_", this_sample),
      log_base = paste0("slurmOut/snv_", this_sample),
      min_snvs_per_cluster = 200,
      n_bootstraps = 10000,
      bootstrap_cutoff = 0.85,
      max_prop_missing_at_site = 0.9,
      tree_image_type = "pdf",
      cleanup = TRUE,
      allow_chr_mismatch = TRUE,
      other_job_header_options = c(
        "--time=8:00:00",
        "--partition=himem,general"
      ),
      other_batch_options = c(
        "ml purge"
      ),
      use_apptainer = TRUE
    )

  if (job_worked) {
    normal_clusters <-
      match_celltype_clusters(
        sobject = sobj,
        normal_celltypes = control_celltypes,
        cluster_col = "cell_group",
        celltype_col = "cell_type"
      )

    sobj <-
      add_snv_group_to_sobj(
        sobj,
        snv_group_file = paste0(
          out_dir,
          "/snvs_",
          this_sample,
          "_5_groups.txt"
        ),
        new_columns = c("snv_group_5", "snv_top_lvl_group_5"),
        cell_group = "cell_group"
      ) %>%
      add_snv_group_to_sobj(
        snv_group_file = paste0(
          out_dir,
          "/snvs_",
          this_sample,
          "_10_groups.txt"
        ),
        new_columns = c("snv_group_10", "snv_top_lvl_group_10"),
        cell_group = "cell_group"
      ) %>%
      add_snv_group_to_sobj(
        snv_group_file = paste0(
          out_dir,
          "/snvs_",
          this_sample,
          "_20_groups.txt"
        ),
        new_columns = c("snv_group_20", "snv_top_lvl_group_20"),
        cell_group = "cell_group"
      )

    called_clusters <-
      sobj@meta.data %>%
      select(cell_group, snv_top_lvl_group_10) %>% as_tibble() %>%
      dplyr::filter(!is.na(snv_top_lvl_group_10)) %>%
      dplyr::pull(cell_group) %>%
      unique()

    # if there are no genetically distinct clusters, mark all cells as unassigned
    n_groups <-
      sobj$snv_top_lvl_group_10 %>%
      unique() %>%
      na.omit() %>%
      length()
    if(n_groups == 1) {
      sobj@meta.data$snv_tumor_call_10 <- "Unassigned"
    } else if (any(normal_clusters %in% called_clusters)) {
      # Make sure that one of the clusters in the tree output includes normal clusters
      # Throws an error otherwise
      sobj <-
        label_tumor_cells(
          sobj = sobj,
          cell_group = "cell_group",
          snv_group_col = "snv_top_lvl_group_10",
          normal_clusters = normal_clusters,
          tumor_call_column = "snv_tumor_call_10"
        )
    } else {
      sobj@meta.data$snv_tumor_call_10 <- "Unassigned"
    }
  }

  write_tsv(
    sobj@meta.data |>
      dplyr::select(dplyr::starts_with("snv_")) |>
      rownames_to_column("cell_barcode") |>
      dplyr::as_tibble(),
    file = paste0(out_dir, "/snvs_", this_sample, "_meta_data.tsv")
  )

  return(job_worked)
}

read_raw <- function(
  i,
  samples_tsv,
  species_pattern = "",
  organism = NULL,
  ncount_min = NA,
  ncount_max = NA,
  mt_percent_max = NA,
  save_qs_dir = "output/01_process_raw/rdata/individual/",
  h5_folder = "/home/gdrobertslab/lab/Counts_2/",
  min_n_cells = 50,
  annotate_ref,
  annotate_labels,
  annotate_species = "",
  annotate_additional_ref,
  annotate_additional_labels,
  bam_file
) {
  sample_name <- samples_tsv$Sample_ID[i]

  # Not making this an lapply as defaults are different, may do it later
  ncount_min <-
    pick_cutoff(
      ncount_min,
      samples_tsv$subset_nCount_RNA_min[i],
      0,
      species_pattern
    )
  ncount_max <-
    pick_cutoff(
      ncount_max,
      samples_tsv$subset_nCount_RNA_max[i],
      Inf,
      species_pattern
    )
  mt_percent_max <-
    pick_cutoff(
      mt_percent_max,
      samples_tsv$subset_percent.mt_max[i],
      100,
      species_pattern
    )

  path_h5 <-
    paste0(h5_folder, "/", sample_name, "/filtered_feature_bc_matrix.h5")

  counts <- tibble::tibble(sample_name = sample_name)

  if (!file.exists(path_h5)) {
    stop(paste(sample_name, "h5 file does not exist"))
  } else {
    sobj <-
      rrrSingleCellUtils::tenx_load_qc(
        h5_file = path_h5,
        species_pattern = species_pattern,
        violin_plot = FALSE
      )

    sobj$bam_file <- bam_file

    sobj$cell_barcode <- Seurat::Cells(sobj)

    pre_filt_hist <-
      rrrSingleCellUtils::feature_hist(
        sobj,
        features = c("nCount_RNA", "percent.mt"),
        cutoff_table = tibble::tibble(
          feature = c("nCount_RNA", "percent.mt"),
          min_val = c(ncount_min, mt_percent_max),
          max_val = c(ncount_max, NA)
        )
      )

    counts$n_cells_pre_filter <- ncol(sobj)

    counts$n_cells_post_filter <-
      sobj@meta.data %>%
      as.data.frame() %>%
      filter(
        nCount_RNA > ncount_min &
          nCount_RNA < ncount_max &
          percent.mt < mt_percent_max
      ) %>%
      nrow()

    if (counts$n_cells_post_filter >= min_n_cells) {
      counts$kept <- TRUE
      sobj <-
        subset(
          sobj,
          nCount_RNA > ncount_min &
            nCount_RNA < ncount_max &
            percent.mt < mt_percent_max
        ) %>%
        rrrSingleCellUtils::process_seurat()

      opt_res <-
        rrrSingleCellUtils::optimize_silhouette(
          sobj,
          summary_plot = FALSE
        ) %>%
        dplyr::arrange(dplyr::desc(sil_vals)) %>%
        dplyr::pull(res_vals) %>%
        head(1)

      sobj <- Seurat::FindClusters(sobj, resolution = opt_res)

      sobj$individ_clusters <- sobj$seurat_clusters

      # Add metadata to Seurat object from samples_tsv
      for (colname in colnames(samples_tsv)) {
        sobj[[colname]] <- samples_tsv[[colname]][i]
      }

      # Annotate celltypes
      sobj <-
        rrrSingleCellUtils::annotate_celltypes(
          sobj,
          species = annotate_species,
          ref = annotate_ref,
          labels = annotate_labels,
          add_ref = annotate_additional_ref,
          add_labels = annotate_additional_labels,
          aggr_ref = TRUE
        )

      dimplot_fig <-
        Seurat::DimPlot(
          sobj,
          group.by = c("individ_clusters", "cell_type"),
          label = TRUE,
          label.size = 2,
          label.box = TRUE,
          repel = TRUE,
          ncol = 1
        ) +
        Seurat::NoLegend()

      ggplot2::ggsave(
        paste0(
          "output/01_process_raw/figures/qc_cutoffs/pre_filter_hist_",
          sample_name,
          dplyr::if_else(
            organism == "",
            "",
            paste0("_", organism)
          ),
          ".pdf"
        ),
        patchwork::wrap_plots(
          pre_filt_hist,
          dimplot_fig,
          ncol = 1,
          heights = c(1, 5)
        ),
        width = 10,
        height = 20
      )

      qs2::qs_save(
        sobj,
        dplyr::if_else(
          organism == "",
          paste0(save_qs_dir, "/", sample_name, ".qs2"),
          paste0(save_qs_dir, "/", sample_name, "_", organism, ".qs2")
        )
      )

      message(sample_name, " sobject made and saved")
    } else {
      counts$kept <- FALSE
      message(
        paste0(
          sample_name,
          " started with ",
          ncol(sobj),
          " cells but has ",
          counts$n_cells_post_filter,
          " cells left after filtering which is less than ",
          min_n_cells,
          " hence it was discarded"
        )
      )
    }
  }

  counts$median_ncount <-
    median(sobj$nCount_RNA)

  counts$mean_ncount <-
    mean(sobj$nCount_RNA)

  return(counts)
}

pick_cutoff <- function(
  arg_provided,
  from_sample_tsv,
  default,
  species_pattern
) {
  from_sample_tsv <- pull_species_cutoff(from_sample_tsv, species_pattern)
  if (is.na(arg_provided)) {
    if (is.na(from_sample_tsv)) {
      return(default)
    } else {
      return(from_sample_tsv)
    }
  } else {
    return(arg_provided)
  }
}

# Pull the cutoff value from the sample tsv data if it's in there
pull_species_cutoff <- function(from_sample_tsv, species_pattern) {
  if (species_pattern != "") {
    if (
      !grepl(
        # we don't want the caret in the pattern for this
        stringr::str_remove(species_pattern, "^\\^"),
        from_sample_tsv
      )
    ) {
      stop(
        "Species pattern provided but not found in from_sample_tsv. ",
        "Species_pattern: ",
        species_pattern,
        ". Cutoff info from sample sheet: ",
        from_sample_tsv
      )
    }
    cutoff <-
      stringr::str_match(
        from_sample_tsv,
        paste0(stringr::str_remove(species_pattern, "\\^"), "([0-9]+)")
      )[1, 2]
    return(as.numeric(cutoff))
  } else {
    # If from_sample_tsv has letters in it, species pattern likely there
    # We need to specify scientific = F so that 100,000 != 1e+05 which
    # has an "e" :-| and so fails here
    if (
      grepl("[a-zA-Z]", format(from_sample_tsv, scientific = FALSE)) &&
        !is.na(from_sample_tsv)
    ) {
      stop(
        "Sample cutoff value is not just a number but species_pattern ",
        "not provided. Species_pattern: ",
        species_pattern,
        ". Cutoff from sample sheet: ",
        from_sample_tsv
      )
      # Otherwise it's either a number or NA
    } else {
      return(from_sample_tsv)
    }
  }
}

read_raw_from_table <- function(
  sample_table,
  h5_folder,
  min_n_cells = 1000,
  organism,
  annotate_species,
  count_table_file,
  bam_file,
  annotate_additional_ref = list(),
  annotate_additional_labels = list()
) {
  count_table <- parallel::mclapply(
    seq_len(nrow(sample_table)),
    mc.preschedule = FALSE,
    mc.cores = parallelly::availableCores(),
    function(i) {
      read_raw(
        i = i,
        h5_folder = h5_folder,
        min_n_cells = min_n_cells,
        sample_table,
        organism = organism,
        annotate_species = annotate_species,
        bam_file = paste0(
          h5_folder,
          "/",
          sample_table$Sample_ID[i],
          "/",
          bam_file
        ),
        annotate_additional_ref = annotate_additional_ref,
        annotate_additional_labels = annotate_additional_labels
      )
    }
  ) |>
    confirm_mclapply_worked() |>
    dplyr::bind_rows()

  readr::write_tsv(count_table, count_table_file)
}

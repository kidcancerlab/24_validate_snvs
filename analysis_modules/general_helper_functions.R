## Confirm that we have HDF5 available
#' Check for HDF5 File Support
#'
#' This function checks for the availability of HDF5 file support in the current R environment.
#'
#' @return Logical value indicating whether HDF5 support is available.
hdf5_check <- function() {
  h5_return <-
    suppressWarnings(
      try(
        system(
          "ldconfig -p | grep libhdf5.so",
          intern = TRUE,
          ignore.stderr = TRUE
        )
      )
    ) |>
      length() ==
      0
  if (!h5_return) {
    stop(
      "\nYou need to have h5pfc installed to read in h5_files. ",
      "Perhaps ml load HDF5 before you start R?\n"
    )
  }
}

## Confirm that Seurat version installed is > 5
#' Check Seurat Version
#'
#' This function checks the version of the Seurat package installed in the R environment.
#' It ensures that the correct version of Seurat is being used for downstream analysis.
#'
#' @return A message indicating the version of Seurat installed.
seurat_version_check <- function() {
  if (packageVersion("Seurat") < "5.0.0") {
    stop(
      "Please install Seurat version 5.0.0 or higher. ",
      "You are currently using version ",
      packageVersion("Seurat")
    )
  }
}

#' Confirm mclapply Worked And Dump Error Messages If Not
#'
#' This function checks if the `mclapply` function executed successfully on the provided input list.
#'
#' @param input_list A list that was processed by `mclapply`.
#' @return The input list if `mclapply` was successful or the error messages if it failed.
confirm_mclapply_worked <- function(input_list) {
  if (length(input_list) == 0) {
    stop("Empty input list")
  }

  has_error <- FALSE
  for (item in input_list) {
    if (inherits(item, "try-error")) {
      warning("mclapply failed with error: ", item[[1]])
      has_error <- TRUE
    }
  }

  if (has_error) {
    stop("mclapply failed")
  } else {
    return(input_list)
  }
}

## Plotting Functions
dimplot_better <- function(
  object,
  group_by = NULL,
  cols,
  ncol = 1,
  label_size = 2.5,
  split_by = NULL,
  ...
) {
  Seurat::DimPlot(
    object,
    group.by = group_by,
    split.by = split_by,
    ncol = ncol,
    label.size = label_size,
    label = TRUE,
    repel = TRUE,
    shuffle = TRUE,
    label.box = TRUE,
    cols = c(rrrSingleCellUtils::plot_cols, sample(rainbow(1000))),
    ...
  ) +
    ggplot2::coord_fixed()
}

## Samples for downsample analysis
filter_cells_umi_cutoff <- function(sobj, max_umi) {
  keep_cells <-
    sobj |>
    SeuratObject::FetchData(
      vars = c(
        "cell_group",
        "cell_barcode",
        "bam_file",
        "nCount_RNA"
      )
    ) |>
    tibble::as_tibble() |>
    dplyr::group_by(cell_group) |>
    dplyr::arrange(cell_group, cell_barcode) |>
    dplyr::mutate(cumsum = cumsum(nCount_RNA)) |>
    dplyr::filter(cumsum < max_umi) |>
    dplyr::pull(cell_barcode)

  sobj_sub <- subset(sobj, cells = keep_cells)
  return(sobj_sub)
}

filter_cells_n_cell_cutoff <- function(sobj, n_cells) {
  set.seed(1337)
  sobj <- subset(sobj, downsample = n_cells)

  return(sobj)
}

make_cbt <- function(sobj, cutoff, downsample_type) {
  if (downsample_type == "max_umi") {
    sub_sobj <- filter_cells_umi_cutoff(sobj, cutoff)
  } else if (downsample_type == "n_cells") {
    sub_sobj <- filter_cells_n_cell_cutoff(sobj, cutoff)
  } else {
    stop("Must provide either max_umi or n_cells as downsample type")
  }

  cell_barcode_group_table <-
    sub_sobj |>
    SeuratObject::FetchData(
      vars = c(
        "cell_group",
        "cell_barcode",
        "bam_file",
        "nCount_RNA"
      )
    ) |>
    tibble::as_tibble() |>
    dplyr::arrange(cell_group)

  return(cell_barcode_group_table)
}

scanbit_downsample_loop <- function(
  sobj,
  cutoff_vector,
  out_dir_base,
  sample_label,
  min_read_depth = 5,
  min_snvs_per_cluster = 10,
  downsample_type = "n_cells",
  keep_temp_dir = FALSE,
  ploidy,
  ref_fasta
) {
  parallel::mclapply(
    cutoff_vector,
    mc.cores = 10,
    mc.preschedule = FALSE,
    function(cutoff) {
      out_dir <-
        file.path(
          out_dir_base,
          paste0(
            "downsample_",
            sprintf("%.0f", cutoff),
            "_cells"
          )
        )

      dir.create(
        out_dir,
        recursive = TRUE,
        showWarnings = FALSE
      )

      if (keep_temp_dir) {
        temp_dir <- file.path(out_dir_base, "tempdir")
        cleanup <- FALSE
      } else {
        temp_dir <- tempfile(
          pattern = paste0(
            "tempdir_",
            cutoff,
            sample_label
          )
        )
        cleanup <- TRUE
      }

      # Get the cell barcodes for the current cutoff
      cell_barcode_group_table <-
        make_cbt(
          sobj,
          cutoff = cutoff,
          downsample_type = downsample_type
        )

      readr::write_tsv(
        cell_barcode_group_table,
        file.path(
          out_dir,
          paste0(
            "cell_barcode_table_",
            sample_label,
            "_",
            sprintf("%.0f", cutoff),
            "_cells.txt"
          )
        )
      )

      cell_barcode_group_table <-
        dplyr::select(cell_barcode_group_table, -nCount_RNA)

      scanBit::get_snp_tree(
        cellid_bam_table = cell_barcode_group_table,
        ploidy = ploidy,
        temp_dir = temp_dir,
        output_dir = out_dir,
        output_base_name = paste0(
          "downsample_",
          sample_label,
          "_",
          sprintf("%.0f", cutoff)
        ),
        ref_fasta = ref_fasta,
        min_depth = min_read_depth,
        job_base = "downsample_cells",
        min_snvs_per_cluster = min_snvs_per_cluster,
        n_bootstraps = 10000,
        max_prop_missing_at_site = 0.9,
        cleanup = cleanup,
        tree_image_type = "pdf",
        other_job_header_options = c(
          "--time=8:00:00",
          "--partition=himem,general"
        ),
        other_batch_options = c(
          "ml purge"
        ),
        use_apptainer = TRUE
      )
    }
  )
}

#' ggsave_wrap
#'
#' A wrapper function for saving a single ggplot object in multiple file formats at once.
#'
#' This function simplifies the process of saving a ggplot object by allowing the user
#' to specify multiple file formats and save the plot in all of them with a single call.
#'
#' @param file_stub The base file name (without extension) to use for saving the plot.
#' @param file_types A character vector of file extensions (e.g., c(".png", ".pdf")).
#' @param plot_variable The ggplot object to be saved.
#' @param width The width of the saved plot.
#' @param height The height of the saved plot.
#'
#' @return The function does not return a value but saves the plot to the specified files.
#'
#' @examples
#' # Example usage:
#' # ggsave_wrap("my_plot", c(".png", ".pdf"), my_plot, width = 6, height = 4)
#'
#' @export
ggsave_wrap <- function(
  file_stub,
  file_types,
  plot_variable,
  width,
  height
) {
  files_made <-
    lapply(
      file_types,
      function(x) {
        ggplot2::ggsave(
          paste0(file_stub, ".", x),
          plot_variable,
          width = width,
          height = height
        )
      }
    )
}

run_scevan <- function(
  sobj,
  organism,
  sample_name,
  temp_dir
) {
  # SCEVAN writes a bunch of files to whatever directory you're in and if you
  # run two instances simultaneously, we need separate temporary directories for
  # each sample.
  temp_dir <- tempfile(pattern = sample_name, tmpdir = temp_dir)
  dir.create(temp_dir, recursive = TRUE)

  counts <- Seurat::GetAssayData(sobj, layer = "counts")

  orig_wd <- getwd()

  setwd(temp_dir)
  on.exit(setwd(orig_wd), add = TRUE)

  scevan_out <-
    tryCatch(
      {
        SCEVAN::pipelineCNA(
          count_mtx = counts,
          sample = sample_name,
          organism = organism,
          par_cores = parallelly::availableCores(),
          SUBCLONES = FALSE
        )
      },
      error = function(e) {
        message("Error running SCEVAN: ", e)
        return(NULL)
      }
    )

  setwd(orig_wd)

  # Clean up temporary directory
  unlink(temp_dir, recursive = TRUE)

  scevan_out |>
    tibble::rownames_to_column(var = "barcode") |>
    readr::write_tsv(
      paste0(
        "output/10_cmp_other_methods/scevan_results/",
        sample_name,
        "_scevan_results.tsv"
      )
    )
}

run_scatomic <- function(
  sobj,
  sample_name,
  use_cnvs = TRUE
) {
  counts <- Seurat::GetAssayData(sobj, layer = "counts")

  cell_predictions <-
    scATOMIC::run_scATOMIC(
      rna_counts = counts,
      mc.cores = parallelly::availableCores()
    )
  scatomic_results <-
    tryCatch(
      {
        scATOMIC::create_summary_matrix(
          prediction_list = cell_predictions,
          use_CNVs = use_cnvs,
          modify_results = TRUE,
          mc.cores = parallelly::availableCores(),
          raw_counts = counts,
          min_prop = 0.5
        ) |>
          select(
            starts_with("layer_"),
            any_of(c(
              "scATOMIC_pred",
              "classification_confidence",
              "CNV_status",
              "pan_cancer_cluster"
            ))
          )
      },
      error = function(e) {
        message("scATOMIC failed for ", sample_name, " with error: ", e)
      }
    )

  if (is.data.frame(scatomic_results)) {
    scatomic_results |>
      tibble::rownames_to_column(var = "barcode") |>
      readr::write_tsv(
        paste0(
          "output/10_cmp_other_methods/scatomic_results/",
          sample_name,
          "_scatomic_results.tsv"
        )
      )
  }
}


##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Maybe not needed
get_human_count_matrix <- function(sobj, species = "human") {
  if (species == "mouse") {
    counts <- convert_mouse_to_human(Seurat::GetAssayData(
      sobj,
      layer = "counts"
    ))
  } else if (species == "human") {
    counts <- Seurat::GetAssayData(sobj, layer = "counts")
  } else {
    stop("Unsupported species: ", species)
  }

  return(counts)
}

convert_mouse_to_human <- function(counts) {
  human_genenames <-
    nichenetr::convert_mouse_to_human_symbols() |>
    as.character()

  counts <- counts[!is.na(human_genenames), ]
  rownames(counts) <- human_genenames[!is.na(human_genenames)]

  return(counts)
}

run_numbat <- function(count_mat, species) {

}



run_copykat <- function(count_mat, species, temp_dir) {
  if (species == "mouse") {
    genome <- "mm10"
  } else if (species == "human") {
    genome <- "hg20" # same as hg38 - https://github.com/navinlabcode/copykat/issues/4
  } else {
    stop("Unsupported species: ", species)
  }

  orig_wd <- getwd()

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }
  setwd(temp_dir)
  on.exit(setwd(orig_wd), add = TRUE)

  copykat_results <-
    copykat(
      rawmat = count_mat,
      sam.name = "test",
      genome = genome,
      n.cores = 5
    )

  qs2::qs_save(
    copykat_results,
    paste0(
      "output/10_cmp_other_methods/copykat_results/",
      sample_name,
      "_copykat_results.qs2"
    )
  )

  setwd(orig_wd)
}

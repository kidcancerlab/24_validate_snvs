#' Get the number of shared sites per cell from a shared-sites file
#'
#' Reads a tab-delimited shared-sites matrix and extracts its diagonal, which
#' contains the number of sites for each cell. The number of cells and the
#' sample name are parsed from the input file name.
#'
#' @param in_file Path to a tab-delimited file with a header and a row-name
#'   column named `X`. The file name must end in `_10_n_comps.txt`, with the
#'   number of cells immediately before that suffix, and must contain
#'   `downsample_` followed by the sample name.
#'
#' @return A tibble with one row per matrix diagonal entry and columns:
#'   \describe{
#'     \item{name}{Row name from the input matrix, as returned by
#'       [tibble::enframe()].}
#'     \item{shared_sites}{Diagonal value from the matrix.}
#'     \item{cells}{Number of cells parsed from the file name.}
#'     \item{sample}{Sample name parsed from the file name.}
#'     \item{numeric_n_cells}{`cells` converted to numeric.}
#'   }
#'   If the file is empty, returns a tibble with only a zero-length character
#'   column, `sample`.
#'
#' @examples
#' \dontrun{
#' get_n_shared_sites("downsample_G0001_5_10_n_comps.txt")
#' }
get_n_shared_sites <- function(in_file) {
  n_cells <-
    stringr::str_remove(in_file, "_10_n_comps.txt") |>
    stringr::str_remove(".+_") |>
    as.numeric()

  sample_name <-
    stringr::str_remove(in_file, ".+downsample_") |>
    stringr::str_remove("_.+")

  if (file.size(in_file) > 0) {
    output <-
      read.table(in_file, sep = "\t", header = TRUE) |>
      tibble::column_to_rownames("X") |>
      as.matrix() |>
      diag() |>
      tibble::enframe() |>
      dplyr::mutate(
        cells = n_cells,
        sample = sample_name
      ) |>
      dplyr::mutate(
        numeric_n_cells = cells
      ) %>%
      dplyr::rename(shared_sites = value)
  } else {
    output <- tibble(sample = character())
  }

  return(output)
}
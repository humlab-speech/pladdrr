# as-data-frame-missing.R — as.data.frame S3 methods for classes missing them

# ---- Classes WITH $as_data_frame() internally ----

#' @export
as.data.frame.Discriminant <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.Electroglottogram <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.FormantModeler <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.PCA <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.PowerCepstrogram <- function(x, ...) x$as_data_frame()

# ---- Classes WITHOUT $as_data_frame() ----

#' @export
as.data.frame.BarkSpectrogram <- function(x, ...) {
  as.data.frame(x$to_matrix(to_db = TRUE))
}

#' @param power If TRUE, convert to PowerCepstrum (nonnegative, dB) instead of
#'   Praat's default raw signed cepstrum view. Default FALSE matches
#'   `Cepstrum_drawLinear`, Praat's default "Draw..." command.
#' @export
as.data.frame.Cepstrum <- function(x, power = FALSE, ...) {
  if (power) {
    pc <- x$to_powercepstrum()
    return(pc$as_data_frame())
  }
  x$as_data_frame()
}

#' @export
as.data.frame.Cochleagram <- function(x, ...) {
  m <- x$as_matrix()
  n_row <- nrow(m); n_col <- ncol(m)
  df <- expand.grid(row = seq_len(n_row), col = seq_len(n_col))
  df$frequency <- vapply(df$row, x$get_frequency_from_row, numeric(1))
  df$time <- vapply(df$col, x$get_time_from_column, numeric(1))
  df$excitation <- as.vector(m)
  df[, c("time", "frequency", "excitation")]
}

#' @export
as.data.frame.DTW <- function(x, ...) {
  path <- x$get_path()
  if (is.null(path) || nrow(path) == 0) {
    return(data.frame(x = numeric(0), y = numeric(0)))
  }
  path
}

#' @export
as.data.frame.KlattGrid <- function(x, ...) {
  tmin <- x$get_xmin()
  tmax <- x$get_xmax()
  times <- seq(tmin, tmax, length.out = 100)
  n_formants <- 6L
  rows <- list()
  for (t in times) {
    for (f in seq_len(n_formants)) {
      freq <- tryCatch(x$get_formant_at_time(.klattgrid_formant_type_code("oral"), f, t),
                       error = function(e) NA_real_)
      if (!is.na(freq)) {
        rows[[length(rows) + 1]] <- data.frame(
          time = t, formant_number = f, frequency = freq,
          stringsAsFactors = FALSE)
      }
    }
  }
  if (length(rows) == 0) {
    return(data.frame(time = numeric(0), formant_number = integer(0),
                       frequency = numeric(0)))
  }
  do.call(rbind, rows)
}

#' @export
as.data.frame.LPC <- function(x, ...) {
  gains <- x$get_all_gains()
  coeffs <- x$get_all_coefficients()
  n_frames <- length(gains)
  if (n_frames == 0) {
    return(data.frame(frame = integer(0), coefficient = integer(0),
                       value = numeric(0)))
  }
  rows <- list()
  for (i in seq_len(n_frames)) {
    frame_coeffs <- coeffs[[i]]
    for (j in seq_along(frame_coeffs)) {
      rows[[length(rows) + 1]] <- data.frame(
        frame = i, coefficient = j, value = frame_coeffs[j],
        gain = gains[i], stringsAsFactors = FALSE)
    }
  }
  do.call(rbind, rows)
}

#' @export
as.data.frame.LongSound <- function(x, ...) {
  stop("LongSound streams from disk. Use x$extract_part(from, to) to get a Sound, then as.data.frame().")
}

#' @export
as.data.frame.Matrix <- function(x, ...) {
  mat <- x$as_matrix()
  n_row <- x$get_ny(); n_col <- x$get_nx()
  y1 <- x$get_y1()
  x1 <- x$get_x1()
  df <- expand.grid(row = seq_len(n_row), col = seq_len(n_col))
  df$value <- as.vector(mat)
  df$col <- x1 + (df$col - 1) * x$get_dx()
  df$row <- y1 + (df$row - 1) * x$get_dy()
  df
}

#' @export
as.data.frame.MelSpectrogram <- function(x, ...) {
  as.data.frame(x$to_matrix(to_db = TRUE))
}

#' @export
as.data.frame.VocalTract <- function(x, ...) {
  areas <- x$get_areas()
  n <- length(areas)
  dx <- x$get_section_length()
  data.frame(distance = seq(0, (n - 1) * dx, length.out = n), area = areas)
}

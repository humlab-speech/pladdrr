#' Autoplot and Autolayer Methods for pladdrr Objects
#'
#' @description
#' ggplot2-style autoplot() and autolayer() methods for Praat objects.
#' These provide a tidyverse-idiomatic interface for plotting, allowing
#' flexible composition of multi-object visualizations.
#'
#' @details
#' The autoplot/autolayer pattern enables flexible plot composition:
#' \itemize{
#'   \item \code{autoplot(object)} - Creates a complete ggplot
#'   \item \code{autolayer(object)} - Returns a layer to add to existing plots
#' }
#'
#' This allows combining multiple objects:
#' \preformatted{
#' autoplot(spectrogram) +
#'   autolayer(formant, max_formant = 3) +
#'   autolayer(pitch, color = "blue")
#' }
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
#' p <- ggplot2::autoplot(sound)
#'
#' pitch <- sound$to_pitch()
#' p2 <- ggplot2::autoplot(pitch)
#'
#' @name autoplot-methods
#' @importFrom ggplot2 autoplot autolayer
NULL

# ============================================================================
# Sound
# ============================================================================

#' @rdname autoplot-methods
#' @param object Sound object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param color Line color (default: "steelblue")
#' @param ... Additional arguments passed to geom_line
#' @return A ggplot2 object
#' @export
autoplot.Sound <- function(object, from_time = NULL, to_time = NULL,
                           color = "steelblue", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }


  df <- object$as_data_frame()

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$value)) +
    ggplot2::geom_line(color = color, linewidth = 0.5, ...) +
    ggplot2::labs(title = "Sound", x = "Time (s)", y = "Amplitude") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Sound <- function(object, from_time = NULL, to_time = NULL,
                            color = "steelblue", ...) {
  df <- object$as_data_frame()

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::geom_line(
    data = df,
    ggplot2::aes(x = .data$time, y = .data$value),
    color = color, linewidth = 0.5, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# Pitch
# ============================================================================

#' @rdname autoplot-methods
#' @param object Pitch object
#' @param show_voicing Color by voicing strength (default: FALSE)
#' @export
autoplot.Pitch <- function(object, from_time = NULL, to_time = NULL,
                           color = "darkgreen", show_voicing = FALSE, ...) {
 if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  df <- object$as_data_frame()

  # Remove unvoiced frames
  df <- df[!is.na(df$frequency) & df$frequency > 0, ]

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  if (nrow(df) == 0) {
    warning("No voiced frames in Pitch object")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)

  p + ggplot2::labs(title = "Pitch", x = "Time (s)", y = "Frequency (Hz)") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @param geom For Pitch: type of geometry ("line" or "point")
#' @export
autolayer.Pitch <- function(object, from_time = NULL, to_time = NULL,
                            color = "darkgreen", geom = c("line", "point"), ...) {
  geom <- match.arg(geom)
  df <- object$as_data_frame()

  # Remove unvoiced
  df <- df[!is.na(df$frequency) & df$frequency > 0, ]

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  if (nrow(df) == 0) return(NULL)

  if (geom == "line") {
    ggplot2::geom_line(
      data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency),
      color = color, linewidth = 0.8, inherit.aes = FALSE, ...
    )
  } else {
    ggplot2::geom_point(
      data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency),
      color = color, size = 1, inherit.aes = FALSE, ...
    )
  }
}

# ============================================================================
# Formant
# ============================================================================

#' @rdname autoplot-methods
#' @param object Formant object
#' @param max_formant Maximum formant number to display (default: 3)
#' @param colors Colors for each formant track
#' @export
autoplot.Formant <- function(object, from_time = NULL, to_time = NULL,
                             max_formant = 3, colors = NULL, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  # object$as_data_frame() is already long format (time, formant, frequency,
  # bandwidth), one row per (frame, formant number) - no reshape needed.
  df <- object$as_data_frame(max_formants = max_formant)
  if (nrow(df) == 0) {
    warning("Formant object has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]
  df <- df[df$formant <= max_formant & !is.na(df$frequency), ]

  if (nrow(df) == 0) {
    warning("No formant data after filtering")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  df$formant_label <- paste0("F", df$formant)
  formant_labels <- paste0("F", sort(unique(df$formant)))

  if (is.null(colors)) {
    colors <- c("red", "green4", "blue", "purple", "orange")[seq_along(formant_labels)]
    names(colors) <- formant_labels
  }

  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency,
                                    color = .data$formant_label)) +
    ggplot2::geom_line(linewidth = 0.8, ...) +
    ggplot2::scale_color_manual(values = colors, name = "Formant") +
    ggplot2::labs(title = "Formant", x = "Time (s)", y = "Frequency (Hz)") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Formant <- function(object, from_time = NULL, to_time = NULL,
                              max_formant = 3, colors = NULL, ...) {
  df <- object$as_data_frame(max_formants = max_formant)
  if (nrow(df) == 0) return(NULL)

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]
  df <- df[df$formant <= max_formant & !is.na(df$frequency), ]

  if (nrow(df) == 0) return(NULL)

  df$formant_label <- paste0("F", df$formant)
  formant_labels <- paste0("F", sort(unique(df$formant)))

  if (is.null(colors)) {
    colors <- c("red", "yellow", "cyan", "magenta", "white")[seq_along(formant_labels)]
    names(colors) <- formant_labels
  }

  list(
    ggplot2::geom_line(
      data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency, color = .data$formant_label),
      linewidth = 1.2, alpha = 0.8, inherit.aes = FALSE, ...
    ),
    ggplot2::scale_color_manual(values = colors, name = "Formant")
  )
}

# ============================================================================
# Intensity
# ============================================================================

#' @rdname autoplot-methods
#' @param object Intensity object
#' @export
autoplot.Intensity <- function(object, from_time = NULL, to_time = NULL,
                               color = "darkorange", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  df <- object$as_data_frame()

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$intensity_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...) +
    ggplot2::labs(title = "Intensity", x = "Time (s)", y = "Intensity (dB)") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Intensity <- function(object, from_time = NULL, to_time = NULL,
                                color = "darkorange", ...) {
  df <- object$as_data_frame()

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::geom_line(
    data = df,
    ggplot2::aes(x = .data$time, y = .data$intensity_db),
    color = color, linewidth = 0.8, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# Spectrogram
# ============================================================================

#' @rdname autoplot-methods
#' @param object Spectrogram object
#' @param from_freq Start frequency in Hz
#' @param to_freq End frequency in Hz
#' @param dynamic_range Dynamic range in dB (default: 70)
#' @export
autoplot.Spectrogram <- function(object, from_time = NULL, to_time = NULL,
                                 from_freq = NULL, to_freq = NULL,
                                 dynamic_range = 70, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  mat <- object$as_matrix()
  n_times <- ncol(mat)
  n_freqs <- nrow(mat)

  t_min <- object$get_start_time()
  t_max <- object$get_end_time()
  f_max <- object$get_highest_frequency()

  times <- seq(t_min, t_max, length.out = n_times)
  freqs <- seq(0, f_max, length.out = n_freqs)

  df <- expand.grid(time = times, frequency = freqs)
  df$power_db <- as.vector(mat)

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]
  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq)) df <- df[df$frequency <= to_freq, ]

  max_power <- max(df$power_db, na.rm = TRUE)
  df$power_db[df$power_db < (max_power - dynamic_range)] <- max_power - dynamic_range

  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency,
                                    fill = .data$power_db)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_gradient(low = "white", high = "black", name = "Power (dB)") +
    ggplot2::labs(title = "Spectrogram", x = "Time (s)", y = "Frequency (Hz)") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Spectrogram <- function(object, from_time = NULL, to_time = NULL,
                                  from_freq = NULL, to_freq = NULL,
                                  dynamic_range = 70, ...) {
  mat <- object$as_matrix()
  n_times <- ncol(mat)
  n_freqs <- nrow(mat)

  t_min <- object$get_start_time()
  t_max <- object$get_end_time()
  f_max <- object$get_highest_frequency()

  times <- seq(t_min, t_max, length.out = n_times)
  freqs <- seq(0, f_max, length.out = n_freqs)

  df <- expand.grid(time = times, frequency = freqs)
  df$power_db <- as.vector(mat)

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]
  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq)) df <- df[df$frequency <= to_freq, ]

  max_power <- max(df$power_db, na.rm = TRUE)
  df$power_db[df$power_db < (max_power - dynamic_range)] <- max_power - dynamic_range

  list(
    ggplot2::geom_raster(
      data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency, fill = .data$power_db),
      ...
    ),
    ggplot2::scale_fill_gradient(low = "white", high = "black", name = "Power (dB)")
  )
}

# ============================================================================
# Spectrum
# ============================================================================

#' @rdname autoplot-methods
#' @param object Spectrum object
#' @param log_freq Use logarithmic frequency scale (default: FALSE)
#' @export
autoplot.Spectrum <- function(object, from_freq = NULL, to_freq = NULL,
                              log_freq = FALSE, color = "navy", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  df <- object$as_data_frame()

  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq)) df <- df[df$frequency <= to_freq, ]

  if (!"power_db" %in% names(df) && "power" %in% names(df)) {
    df$power_db <- 10 * log10(df$power)
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$frequency, y = .data$power_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)

  if (log_freq) p <- p + ggplot2::scale_x_log10()

  p + ggplot2::labs(
    title = "Spectrum",
    x = if (log_freq) "Frequency (Hz, log)" else "Frequency (Hz)",
    y = "Power (dB)"
  ) + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Spectrum <- function(object, from_freq = NULL, to_freq = NULL,
                               color = "navy", ...) {
  df <- object$as_data_frame()

  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq)) df <- df[df$frequency <= to_freq, ]

  if (!"power_db" %in% names(df) && "power" %in% names(df)) {
    df$power_db <- 10 * log10(df$power)
  }

  ggplot2::geom_line(
    data = df,
    ggplot2::aes(x = .data$frequency, y = .data$power_db),
    color = color, linewidth = 0.8, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# Ltas
# ============================================================================

#' @rdname autoplot-methods
#' @param object Ltas object
#' @export
autoplot.Ltas <- function(object, from_freq = NULL, to_freq = NULL,
                          log_freq = FALSE, color = "darkred", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  df <- object$as_data_frame()

  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq)) df <- df[df$frequency <= to_freq, ]

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$frequency, y = .data$power_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)

  if (log_freq) p <- p + ggplot2::scale_x_log10()

  p + ggplot2::labs(
    title = "LTAS",
    x = if (log_freq) "Frequency (Hz, log)" else "Frequency (Hz)",
    y = "Power (dB SPL)"
  ) + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Ltas <- function(object, from_freq = NULL, to_freq = NULL,
                           color = "darkred", ...) {
  df <- object$as_data_frame()

  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq)) df <- df[df$frequency <= to_freq, ]

  ggplot2::geom_line(
    data = df,
    ggplot2::aes(x = .data$frequency, y = .data$power_db),
    color = color, linewidth = 0.8, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# Harmonicity
# ============================================================================

#' @rdname autoplot-methods
#' @param object Harmonicity object
#' @export
autoplot.Harmonicity <- function(object, from_time = NULL, to_time = NULL,
                                 color = "darkviolet", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  df <- object$as_data_frame()

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$hnr_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
    ggplot2::labs(title = "Harmonicity (HNR)", x = "Time (s)", y = "HNR (dB)") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Harmonicity <- function(object, from_time = NULL, to_time = NULL,
                                  color = "darkviolet", ...) {
  df <- object$as_data_frame()

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::geom_line(
    data = df,
    ggplot2::aes(x = .data$time, y = .data$hnr_db),
    color = color, linewidth = 0.8, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# PointProcess
# ============================================================================

#' @rdname autoplot-methods
#' @param object PointProcess object
#' @export
autoplot.PointProcess <- function(object, from_time = NULL, to_time = NULL,
                                  color = "black", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  n_points <- object$get_number_of_points()
  if (n_points == 0) {
    warning("PointProcess has no points")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  times <- vapply(seq_len(n_points), object$get_time_from_index, numeric(1))
  df <- data.frame(time = times, y = 1)

  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time)) df <- df[df$time <= to_time, ]

  ggplot2::ggplot(df, ggplot2::aes(x = .data$time, xend = .data$time,
                                    y = 0, yend = 1)) +
    ggplot2::geom_segment(color = color, linewidth = 0.5, ...) +
    ggplot2::labs(title = "PointProcess", x = "Time (s)", y = "") +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank())
}

#' @rdname autoplot-methods
#' @param ymin For PointProcess: minimum y value for vertical lines (default: 0)
#' @param ymax For PointProcess: maximum y value for vertical lines (default: 1)
#' @export
autolayer.PointProcess <- function(object, from_time = NULL, to_time = NULL,
                                   color = "black", ymin = 0, ymax = 1, ...) {
  n_points <- object$get_number_of_points()
  if (n_points == 0) return(NULL)

  times <- vapply(seq_len(n_points), object$get_time_from_index, numeric(1))
  df <- data.frame(time = times)

  if (!is.null(from_time)) df <- df[df$time >= from_time, , drop = FALSE]
  if (!is.null(to_time)) df <- df[df$time <= to_time, , drop = FALSE]

  ggplot2::geom_vline(
    data = df,
    ggplot2::aes(xintercept = .data$time),
    color = color, linewidth = 0.5, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# PowerCepstrum
# ============================================================================

#' @rdname autoplot-methods
#' @param object PowerCepstrum object
#' @param from_quefrency Start quefrency in seconds
#' @param to_quefrency End quefrency in seconds
#' @param mark_peak Mark the cepstral peak (default: TRUE)
#' @export
autoplot.PowerCepstrum <- function(object, from_quefrency = NULL, to_quefrency = NULL,
                                   color = "darkblue", mark_peak = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }

  df <- object$as_data_frame()
  if (nrow(df) == 0) {
    warning("PowerCepstrum has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  if (!is.null(from_quefrency)) df <- df[df$quefrency >= from_quefrency, ]
  if (!is.null(to_quefrency)) df <- df[df$quefrency <= to_quefrency, ]

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$quefrency, y = .data$power_dB)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)

  if (mark_peak && nrow(df) > 0) {
    peak_idx <- which.max(df$power_dB)
    if (length(peak_idx) > 0) {
      peak_q <- df$quefrency[peak_idx]
      peak_v <- df$power_dB[peak_idx]

      p <- p +
        ggplot2::geom_vline(xintercept = peak_q, linetype = "dashed",
                            color = "red", alpha = 0.5) +
        ggplot2::annotate("text", x = peak_q, y = peak_v,
                          label = sprintf("%.4f s\n(%.0f Hz)", peak_q, 1/peak_q),
                          hjust = -0.1, size = 3, color = "red")
    }
  }

  p + ggplot2::labs(title = "Power Cepstrum", x = "Quefrency (s)", y = "Power (dB)") +
    ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.PowerCepstrum <- function(object, from_quefrency = NULL, to_quefrency = NULL,
                                    color = "darkblue", ...) {
  df <- object$as_data_frame()
  if (nrow(df) == 0) return(NULL)

  if (!is.null(from_quefrency)) df <- df[df$quefrency >= from_quefrency, ]
  if (!is.null(to_quefrency)) df <- df[df$quefrency <= to_quefrency, ]

  ggplot2::geom_line(
    data = df,
    ggplot2::aes(x = .data$quefrency, y = .data$power_dB),
    color = color, linewidth = 0.8, inherit.aes = FALSE, ...
  )
}

# ============================================================================
# TextGrid
# ============================================================================

#' @rdname autoplot-methods
#' @export
autoplot.TextGrid <- function(object, ...) {
  plot.TextGrid(object, ...)
}

#' @rdname autoplot-methods
#' @param object TextGrid object
#' @param tier Tier number or name to display (default: 1)
#' @param alpha Fill transparency (default: 0.3)
#' @export
autolayer.TextGrid <- function(object, tier = 1, from_time = NULL, to_time = NULL,
                               color = "steelblue", alpha = 0.3, ...) {
  n_tiers <- object$get_number_of_tiers()

  # Resolve tier by name if needed
  if (is.character(tier)) {
    tier_names <- vapply(seq_len(n_tiers), object$get_tier_name, character(1))
    tier <- which(tier_names == tier)
    if (length(tier) == 0) stop("Tier '", tier, "' not found")
    tier <- tier[1]
  }

  if (tier < 1 || tier > n_tiers) {
    stop("Tier ", tier, " out of range (1-", n_tiers, ")")
  }

  is_interval <- object$tier_is_interval_tier(tier)

  if (is_interval) {
    n_intervals <- object$get_number_of_intervals(tier)
    tier_data <- data.frame(
      start = vapply(seq_len(n_intervals),
                     function(i) object$get_interval_start_time(tier, i),
                     numeric(1)),
      end = vapply(seq_len(n_intervals),
                   function(i) object$get_interval_end_time(tier, i),
                   numeric(1)),
      label = vapply(seq_len(n_intervals),
                     function(i) object$get_interval_text(tier, i),
                     character(1)),
      stringsAsFactors = FALSE
    )

    if (!is.null(from_time)) tier_data <- tier_data[tier_data$end >= from_time, ]
    if (!is.null(to_time)) tier_data <- tier_data[tier_data$start <= to_time, ]

    list(
      ggplot2::geom_rect(
        data = tier_data,
        ggplot2::aes(xmin = .data$start, xmax = .data$end, ymin = -Inf, ymax = Inf),
        fill = color, alpha = alpha, color = "black", inherit.aes = FALSE, ...
      ),
      ggplot2::geom_text(
        data = tier_data[tier_data$label != "", ],
        ggplot2::aes(x = (.data$start + .data$end) / 2, y = Inf, label = .data$label),
        vjust = 1.5, size = 3, inherit.aes = FALSE
      )
    )
  } else {
    n_points <- object$get_number_of_points(tier)
    tier_data <- data.frame(
      time = vapply(seq_len(n_points),
                    function(i) object$get_point_time(tier, i),
                    numeric(1)),
      label = vapply(seq_len(n_points),
                     function(i) object$get_point_text(tier, i),
                     character(1)),
      stringsAsFactors = FALSE
    )

    if (!is.null(from_time)) tier_data <- tier_data[tier_data$time >= from_time, ]
    if (!is.null(to_time)) tier_data <- tier_data[tier_data$time <= to_time, ]

    list(
      ggplot2::geom_vline(
        data = tier_data,
        ggplot2::aes(xintercept = .data$time),
        color = color, linewidth = 0.5, inherit.aes = FALSE, ...
      ),
      ggplot2::geom_text(
        data = tier_data[tier_data$label != "", ],
        ggplot2::aes(x = .data$time, y = Inf, label = .data$label),
        vjust = 1.5, angle = 90, hjust = 0, size = 3, inherit.aes = FALSE
      )
    )
  }
}

# autoplot-missing.R — autoplot + autolayer S3 methods for pladdrr classes
# Covers 27 classes: Tier, Formant-like, Spectral, Heatmap, Statistical, Specialized.

# ===========================================================================
# Helpers
# ===========================================================================

.formant_colors <- function(df, max_formant, colors) {
  if (!is.null(colors)) return(colors)
  n <- length(unique(df$formant_label))
  pal <- c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00",
           "#A65628", "#F781BF", "#999999")
  rep_len(pal, max(n, 1L))
}

.prep_formant_df <- function(df, from_time, to_time, max_formant) {
  if (!"formant_number" %in% names(df) && "formant" %in% names(df)) {
    names(df)[names(df) == "formant"] <- "formant_number"
  }
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  df <- df[df$formant_number <= max_formant, ]
  df$formant_label <- paste0("F", df$formant_number)
  df
}

.klattgrid_formant_type_code <- function(type) {
  codes <- c(oral = 1L, nasal = 2L, frication = 3L, tracheal = 4L,
             nasal_anti = 5L, tracheal_anti = 6L, delta = 7L)
  unname(codes[[type]])
}

#' @rdname autoplot-methods
#' @param garnish Whether to add a title and axis labels (default TRUE).
#' @param quefrency_range Optional `c(min, max)` quefrency range to display
#'   (PowerCepstrogram); NULL shows the full range.
#' @param fill_color Fill color for closed shapes (Polygon); distinct from
#'   `fill_col`, which selects a data column to map to a continuous fill scale.
#' @param plot_type Plot style selector (VocalTract).
#' @param from_track,to_track Track index range to display (FormantModeler).
#' @param power If TRUE, use the power/dB variant of the quantity instead of
#'   the raw linear default (Cepstrum).
#' @param style Speckle vs. line rendering style, where applicable (FormantTier).
#' @export
autoplot.AmplitudeTier <- function(object, from_time = NULL, to_time = NULL,
                                    color = "darkred", garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) {
    warning("AmplitudeTier has no data in the specified time range")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$value)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...) +
    ggplot2::geom_point(color = color, size = 1.5, ...)
  if (garnish) {
    p <- p + ggplot2::labs(title = "AmplitudeTier", x = "Time (s)",
                            y = "Amplitude (Pa)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.AmplitudeTier <- function(object, from_time = NULL, to_time = NULL,
                                     color = "darkred", ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) return(NULL)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$value),
      color = color, linewidth = 0.8, ...),
    ggplot2::geom_point(data = df,
      ggplot2::aes(x = .data$time, y = .data$value),
      color = color, size = 1.5, ...)
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.DurationTier <- function(object, from_time = NULL, to_time = NULL,
                                    color = "steelblue", garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) {
    warning("DurationTier has no data in the specified time range")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$duration_factor)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...) +
    ggplot2::geom_point(color = color, size = 1.5, ...) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.4)
  if (garnish) {
    p <- p + ggplot2::labs(title = "DurationTier", x = "Time (s)",
                            y = "Duration Factor")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.DurationTier <- function(object, from_time = NULL, to_time = NULL,
                                     color = "steelblue", ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) return(NULL)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$duration_factor),
      color = color, linewidth = 0.8, ...),
    ggplot2::geom_point(data = df,
      ggplot2::aes(x = .data$time, y = .data$duration_factor),
      color = color, size = 1.5, ...)
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.IntensityTier <- function(object, from_time = NULL, to_time = NULL,
                                    color = "darkgreen", garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) {
    warning("IntensityTier has no data in the specified time range")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$intensity_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...) +
    ggplot2::geom_point(color = color, size = 1.5, ...)
  if (garnish) {
    p <- p + ggplot2::labs(title = "IntensityTier", x = "Time (s)",
                            y = "Intensity (dB)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.IntensityTier <- function(object, from_time = NULL, to_time = NULL,
                                     color = "darkgreen", ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) return(NULL)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$intensity_db),
      color = color, linewidth = 0.8, ...),
    ggplot2::geom_point(data = df,
      ggplot2::aes(x = .data$time, y = .data$intensity_db),
      color = color, size = 1.5, ...)
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.PitchTier <- function(object, from_time = NULL, to_time = NULL,
                                    color = "blue", garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) {
    warning("PitchTier has no data in the specified time range")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...) +
    ggplot2::geom_point(color = color, size = 1.5, ...)
  if (garnish) {
    p <- p + ggplot2::labs(title = "PitchTier", x = "Time (s)",
                            y = "Frequency (Hz)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.PitchTier <- function(object, from_time = NULL, to_time = NULL,
                                     color = "blue", ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) return(NULL)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency),
      color = color, linewidth = 0.8, ...),
    ggplot2::geom_point(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency),
      color = color, size = 1.5, ...)
  )
}

#' @rdname autoplot-methods
#' @param max_formant Maximum formant number to display (default: 3).
#' @param colors Colors for each formant track (default: auto).
#' @param time_step Sampling interval in seconds, only used when style="line" (default: 0.005).
#' @param style "speckle" (default, matches Praat's FormantTier_speckle: plots the
#'   tier's own stored points, unconnected) or "line" (interpolates on a
#'   time_step grid and connects with a line — not Praat's default view).
#' @export
autoplot.FormantTier <- function(object, from_time = NULL, to_time = NULL,
                                  max_formant = 3L, colors = NULL,
                                  time_step = 0.005,
                                  style = c("speckle", "line"),
                                  garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  style <- match.arg(style)
  tmin <- if (is.null(from_time)) object$get_start_time() else from_time
  tmax <- if (is.null(to_time)) object$get_end_time() else to_time
  n_max <- min(object$get_max_num_formants(), max_formant)

  if (style == "speckle") {
    point_info <- object$as_data_frame()  # time, num_formants per stored point
    rows <- list()
    for (i in seq_len(nrow(point_info))) {
      t <- point_info$time[i]
      if (t < tmin || t > tmax) next
      nf <- min(point_info$num_formants[i], n_max)
      for (f in seq_len(nf)) {
        freq <- tryCatch(object$get_value_at_time(f, t), error = function(e) NA_real_)
        if (!is.na(freq)) {
          rows[[length(rows) + 1]] <- data.frame(
            time = t, formant_number = f, frequency = freq,
            bandwidth = NA_real_, stringsAsFactors = FALSE)
        }
      }
    }
  } else {
    times <- seq(tmin, tmax, by = time_step)
    rows <- list()
    for (f in seq_len(n_max)) {
      for (t in times) {
        freq <- tryCatch(object$get_value_at_time(f, t), error = function(e) NA_real_)
        if (!is.na(freq)) {
          rows[[length(rows) + 1]] <- data.frame(
            time = t, formant_number = f, frequency = freq,
            bandwidth = NA_real_, stringsAsFactors = FALSE)
        }
      }
    }
  }

  if (length(rows) == 0) {
    warning("FormantTier has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  df <- .prep_formant_df(do.call(rbind, rows), NULL, NULL, max_formant)
  if (nrow(df) == 0) {
    warning("FormantTier has no data after filtering")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  colors <- .formant_colors(df, max_formant, colors)
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label))
  p <- if (style == "speckle") {
    p + ggplot2::geom_point(size = 1.5, ...)
  } else {
    p + ggplot2::geom_line(linewidth = 0.8, ...) + ggplot2::geom_point(size = 1.5, ...)
  }
  p <- p + ggplot2::scale_color_manual(values = colors, name = "Formant")
  if (garnish) {
    p <- p + ggplot2::labs(title = "FormantTier", x = "Time (s)",
                            y = "Frequency (Hz)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.FormantTier <- function(object, from_time = NULL, to_time = NULL,
                                   max_formant = 3L, colors = NULL,
                                   time_step = 0.005,
                                   style = c("speckle", "line"), ...) {
  style <- match.arg(style)
  tmin <- if (is.null(from_time)) object$get_start_time() else from_time
  tmax <- if (is.null(to_time)) object$get_end_time() else to_time
  n_max <- min(object$get_max_num_formants(), max_formant)

  if (style == "speckle") {
    point_info <- object$as_data_frame()  # time, num_formants per stored point
    rows <- list()
    for (i in seq_len(nrow(point_info))) {
      t <- point_info$time[i]
      if (t < tmin || t > tmax) next
      nf <- min(point_info$num_formants[i], n_max)
      for (f in seq_len(nf)) {
        freq <- tryCatch(object$get_value_at_time(f, t), error = function(e) NA_real_)
        if (!is.na(freq)) {
          rows[[length(rows) + 1]] <- data.frame(
            time = t, formant_number = f, frequency = freq,
            bandwidth = NA_real_, stringsAsFactors = FALSE)
        }
      }
    }
  } else {
    times <- seq(tmin, tmax, by = time_step)
    rows <- list()
    for (f in seq_len(n_max)) {
      for (t in times) {
        freq <- tryCatch(object$get_value_at_time(f, t), error = function(e) NA_real_)
        if (!is.na(freq)) {
          rows[[length(rows) + 1]] <- data.frame(
            time = t, formant_number = f, frequency = freq,
            bandwidth = NA_real_, stringsAsFactors = FALSE)
        }
      }
    }
  }

  if (length(rows) == 0) return(NULL)
  df <- .prep_formant_df(do.call(rbind, rows), NULL, NULL, max_formant)
  if (nrow(df) == 0) return(NULL)
  colors <- .formant_colors(df, max_formant, colors)
  if (style == "speckle") {
    list(
      ggplot2::geom_point(data = df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label),
        size = 1.5, ...),
      ggplot2::scale_color_manual(values = colors, name = "Formant")
    )
  } else {
    list(
      ggplot2::geom_line(data = df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label),
        linewidth = 0.8, ...),
      ggplot2::geom_point(data = df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label),
        size = 1.5, ...),
      ggplot2::scale_color_manual(values = colors, name = "Formant")
    )
  }
}

#' @rdname autoplot-methods
#' @export
autoplot.FormantGrid <- function(object, from_time = NULL, to_time = NULL,
                                  max_formant = 3L, colors = NULL,
                                  garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- .prep_formant_df(object$as_data_frame(), from_time, to_time, max_formant)
  if (nrow(df) == 0) {
    warning("FormantGrid has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  colors <- .formant_colors(df, max_formant, colors)
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label)) +
    ggplot2::geom_line(linewidth = 0.8, ...) +
    ggplot2::geom_point(size = 1.5, ...) +
    ggplot2::scale_color_manual(values = colors, name = "Formant")
  if (garnish) {
    p <- p + ggplot2::labs(title = "FormantGrid", x = "Time (s)",
                            y = "Frequency (Hz)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.FormantGrid <- function(object, from_time = NULL, to_time = NULL,
                                   max_formant = 3L, colors = NULL, ...) {
  df <- .prep_formant_df(object$as_data_frame(), from_time, to_time, max_formant)
  if (nrow(df) == 0) return(NULL)
  colors <- .formant_colors(df, max_formant, colors)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency,
                   color = .data$formant_label),
      linewidth = 0.8, ...),
    ggplot2::geom_point(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency,
                   color = .data$formant_label),
      size = 1.5, ...),
    ggplot2::scale_color_manual(values = colors, name = "Formant")
  )
}

#' @rdname autoplot-methods
#' @param show_candidates Logical. Overlay candidate paths (default: TRUE).
#' @export
autoplot.FormantPath <- function(object, from_time = NULL, to_time = NULL,
                                  max_formant = 3L, colors = NULL,
                                  show_candidates = TRUE, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- .prep_formant_df(object$as_data_frame(max_formants = max_formant),
                          from_time, to_time, max_formant)
  if (nrow(df) == 0) {
    warning("FormantPath has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  colors <- .formant_colors(df, max_formant, colors)
  if (show_candidates && "candidate" %in% names(df)) {
    optimal <- df[df$candidate == 0 | is.na(df$candidate), ]
    candidates <- df[df$candidate > 0, ]
    if (nrow(optimal) > 0) {
      p <- ggplot2::ggplot() +
        ggplot2::geom_line(data = candidates,
          ggplot2::aes(x = .data$time, y = .data$frequency,
                       color = .data$formant_label,
                       group = interaction(.data$formant_label, .data$candidate)),
          alpha = 0.15, linewidth = 0.3, ...) +
        ggplot2::geom_line(data = optimal,
          ggplot2::aes(x = .data$time, y = .data$frequency,
                       color = .data$formant_label),
          linewidth = 1.0, ...) +
        ggplot2::scale_color_manual(values = colors, name = "Formant")
    } else {
      p <- ggplot2::ggplot(df,
            ggplot2::aes(x = .data$time, y = .data$frequency,
                         color = .data$formant_label)) +
        ggplot2::geom_line(linewidth = 0.8, ...) +
        ggplot2::scale_color_manual(values = colors, name = "Formant")
    }
  } else {
    p <- ggplot2::ggplot(df,
          ggplot2::aes(x = .data$time, y = .data$frequency,
                       color = .data$formant_label)) +
      ggplot2::geom_line(linewidth = 0.8, ...) +
      ggplot2::scale_color_manual(values = colors, name = "Formant")
  }
  if (garnish) {
    p <- p + ggplot2::labs(title = "FormantPath", x = "Time (s)",
                            y = "Frequency (Hz)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.FormantPath <- function(object, from_time = NULL, to_time = NULL,
                                   max_formant = 3L, colors = NULL,
                                   show_candidates = FALSE, ...) {
  df <- .prep_formant_df(object$as_data_frame(max_formants = max_formant),
                          from_time, to_time, max_formant)
  if (nrow(df) == 0) return(NULL)
  colors <- .formant_colors(df, max_formant, colors)
  if (show_candidates && "candidate" %in% names(df)) {
    optimal <- df[df$candidate == 0 | is.na(df$candidate), ]
    if (nrow(optimal) == 0) return(NULL)
    list(
      ggplot2::geom_line(data = optimal,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label),
        linewidth = 1.0, ...),
      ggplot2::scale_color_manual(values = colors, name = "Formant")
    )
  } else {
    list(
      ggplot2::geom_line(data = df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label),
        linewidth = 0.8, ...),
      ggplot2::scale_color_manual(values = colors, name = "Formant")
    )
  }
}

#' @rdname autoplot-methods
#' @export
autoplot.Excitation <- function(object, garnish = TRUE,
                                 color = "darkred", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (nrow(df) == 0) {
    warning("Excitation has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$frequency_bark, y = .data$excitation)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)
  if (garnish) {
    p <- p + ggplot2::labs(title = "Excitation Pattern",
                            x = "Frequency (Bark)", y = "Excitation (dB)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Excitation <- function(object, color = "darkred", ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0) return(NULL)
  ggplot2::geom_line(data = df,
    ggplot2::aes(x = .data$frequency_bark, y = .data$excitation),
    color = color, linewidth = 0.8, ...)
}

#' @rdname autoplot-methods
#' @param show_phase Include phase as separate panel (default: FALSE).
#' @export
autoplot.ComplexSpectrogram <- function(object, from_time = NULL, to_time = NULL,
    from_freq = NULL, to_freq = NULL, dynamic_range = 70,
    garnish = TRUE, show_phase = FALSE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq))   df <- df[df$frequency <= to_freq, ]
  if (nrow(df) == 0) {
    warning("ComplexSpectrogram has no data in range")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  amp_col <- "amplitude_dB"
  if (!"amplitude_dB" %in% names(df)) {
    if (!"amplitude" %in% names(df)) stop("ComplexSpectrogram data frame missing amplitude column")
    ref <- max(df$amplitude, 1e-300)
    # equivalent to 10*log10(power/ref^2) since power = amplitude^2
    df$amplitude_dB <- 20 * log10(pmax(df$amplitude, 1e-300) / ref)
    floor_dB <- -dynamic_range
    df$amplitude_dB <- pmax(df$amplitude_dB, floor_dB)
  }
  p_amp <- ggplot2::ggplot(df,
            ggplot2::aes(x = .data$time, y = .data$frequency,
                         fill = .data[[amp_col]])) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Amplitude (dB)",
                                  limits = c(-dynamic_range, 0))
  if (garnish) {
    p_amp <- p_amp + ggplot2::labs(title = "ComplexSpectrogram",
                                    x = "Time (s)", y = "Frequency (Hz)")
  }
  p_amp <- p_amp + ggplot2::theme_minimal()
  if (show_phase && "phase" %in% names(df)) {
    p_phase <- ggplot2::ggplot(df,
                ggplot2::aes(x = .data$time, y = .data$frequency,
                             fill = .data$phase)) +
      ggplot2::geom_raster() +
      ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7",
                                     high = "#B2182B", name = "Phase") +
      ggplot2::labs(title = "Phase", x = "Time (s)",
                     y = "Frequency (Hz)") +
      ggplot2::theme_minimal()
    if (requireNamespace("patchwork", quietly = TRUE)) {
      return(p_amp / p_phase + patchwork::plot_layout(heights = c(2, 1)))
    }
  }
  p_amp
}

#' @rdname autoplot-methods
#' @export
autolayer.ComplexSpectrogram <- function(object, from_time = NULL,
    to_time = NULL, from_freq = NULL, to_freq = NULL, dynamic_range = 70, ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (!is.null(from_freq)) df <- df[df$frequency >= from_freq, ]
  if (!is.null(to_freq))   df <- df[df$frequency <= to_freq, ]
  if (nrow(df) == 0) return(NULL)
  amp_col <- "amplitude_dB"
  if (!"amplitude_dB" %in% names(df)) {
    if (!"amplitude" %in% names(df)) stop("ComplexSpectrogram data frame missing amplitude column")
    ref <- max(df$amplitude, 1e-300)
    # equivalent to 10*log10(power/ref^2) since power = amplitude^2
    df$amplitude_dB <- 20 * log10(pmax(df$amplitude, 1e-300) / ref)
    floor_dB <- -dynamic_range
    df$amplitude_dB <- pmax(df$amplitude_dB, floor_dB)
  }
  list(
    ggplot2::geom_raster(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency,
                   fill = .data[[amp_col]]),
      ...),
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Amplitude (dB)",
                                  limits = c(-dynamic_range, 0))
  )
}

#' @rdname autoplot-methods
#' @param power If TRUE, plot as PowerCepstrum (dB). Default FALSE matches
#'   Praat's default `Cepstrum_drawLinear` (raw signed cepstrum, linear scale).
#' @export
autoplot.Cepstrum <- function(object, power = FALSE, garnish = TRUE, color = "darkblue", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object, power = power)
  if (nrow(df) == 0) {
    warning("Cepstrum has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  if (power) df$power_dB <- 10 * log10(pmax(df$power, 1e-20))
  y_col <- if (power) "power_dB" else "value"
  y_lab <- if (power) "Power (dB)" else "Amplitude"
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$quefrency, y = .data[[y_col]])) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)
  if (garnish) {
    p <- p + ggplot2::labs(title = "Cepstrum", x = "Quefrency (s)", y = y_lab)
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Cepstrum <- function(object, power = FALSE, color = "darkblue", ...) {
  df <- as.data.frame(object, power = power)
  if (nrow(df) == 0) return(NULL)
  if (power) df$power_dB <- 10 * log10(pmax(df$power, 1e-20))
  y_col <- if (power) "power_dB" else "value"
  ggplot2::geom_line(data = df,
    ggplot2::aes(x = .data$quefrency, y = .data[[y_col]]),
    color = color, linewidth = 0.8, ...)
}

#' @rdname autoplot-methods
#' @export
autoplot.Cochleagram <- function(object, from_time = NULL, to_time = NULL,
    garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) {
    warning("Cochleagram has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     fill = .data$excitation)) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient(low = "white", high = "darkblue",
                                  name = "Excitation")
  if (garnish) {
    p <- p + ggplot2::labs(title = "Cochleagram", x = "Time (s)",
                            y = "Frequency (Bark)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Cochleagram <- function(object, from_time = NULL, to_time = NULL, ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) return(NULL)
  list(
    ggplot2::geom_raster(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency,
                   fill = .data$excitation),
      ...),
    ggplot2::scale_fill_gradient(low = "white", high = "darkblue",
                                  name = "Excitation")
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.PowerCepstrogram <- function(object, from_time = NULL, to_time = NULL,
    quefrency_range = NULL, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (!is.null(quefrency_range)) {
    df <- df[df$quefrency >= quefrency_range[1] &
             df$quefrency <= quefrency_range[2], ]
  }
  if (nrow(df) == 0) {
    warning("PowerCepstrogram has no data in range")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  df$power_dB <- 10 * log10(pmax(df$power, 1e-20))
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$time, y = .data$quefrency,
                     fill = .data$power_dB)) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Power (dB)")
  if (garnish) {
    p <- p + ggplot2::labs(title = "PowerCepstrogram", x = "Time (s)",
                            y = "Quefrency (s)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.PowerCepstrogram <- function(object, from_time = NULL, to_time = NULL,
    quefrency_range = NULL, ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (!is.null(quefrency_range)) {
    df <- df[df$quefrency >= quefrency_range[1] &
             df$quefrency <= quefrency_range[2], ]
  }
  if (nrow(df) == 0) return(NULL)
  df$power_dB <- 10 * log10(pmax(df$power, 1e-20))
  list(
    ggplot2::geom_raster(data = df,
      ggplot2::aes(x = .data$time, y = .data$quefrency,
                   fill = .data$power_dB),
      ...),
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Power (dB)")
  )
}

#' @rdname autoplot-methods
#' @param coefficient_range Range of coefficients to display (e.g. 1:12).
#' @export
autoplot.MFCC <- function(object, coefficient_range = NULL, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  val_cols <- grep("^c[0-9]+$", names(df), value = TRUE)
  if (length(val_cols) == 0) {
    warning("MFCC has no coefficient columns")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  df_long <- data.frame(
    time = rep(df$time, length(val_cols)),
    coefficient = rep(as.integer(gsub("c", "", val_cols, fixed = TRUE)),
                      each = nrow(df)),
    value = as.vector(as.matrix(df[, val_cols, with = FALSE]))
  )
  if (!is.null(coefficient_range)) {
    df_long <- df_long[df_long$coefficient %in% coefficient_range, ]
  }
  if (nrow(df_long) == 0) {
    warning("MFCC has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df_long,
        ggplot2::aes(x = .data$time, y = .data$coefficient,
                     fill = .data$value)) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7",
                                   high = "#B2182B", name = "Value")
  if (garnish) {
    p <- p + ggplot2::labs(title = "MFCC", x = "Time (s)",
                            y = "Coefficient")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.MFCC <- function(object, coefficient_range = NULL, ...) {
  df <- as.data.frame(object)
  val_cols <- grep("^c[0-9]+$", names(df), value = TRUE)
  if (length(val_cols) == 0) return(NULL)
  df_long <- data.frame(
    time = rep(df$time, length(val_cols)),
    coefficient = rep(as.integer(gsub("c", "", val_cols, fixed = TRUE)),
                      each = nrow(df)),
    value = as.vector(as.matrix(df[, val_cols, with = FALSE]))
  )
  if (!is.null(coefficient_range)) {
    df_long <- df_long[df_long$coefficient %in% coefficient_range, ]
  }
  if (nrow(df_long) == 0) return(NULL)
  list(
    ggplot2::geom_raster(data = df_long,
      ggplot2::aes(x = .data$time, y = .data$coefficient,
                   fill = .data$value),
      ...),
    ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7",
                                   high = "#B2182B", name = "Value")
  )
}

#' @rdname autoplot-methods
#' @param coefficient_range Range of coefficients to display (e.g. 1:12).
#' @export
autoplot.LFCC <- function(object, coefficient_range = NULL, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  val_cols <- grep("^c[0-9]+$", names(df), value = TRUE)
  if (length(val_cols) == 0) {
    warning("LFCC has no coefficient columns")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  df_long <- data.frame(
    time = rep(df$time, length(val_cols)),
    coefficient = rep(as.integer(gsub("c", "", val_cols, fixed = TRUE)),
                      each = nrow(df)),
    value = as.vector(as.matrix(df[, val_cols, with = FALSE]))
  )
  if (!is.null(coefficient_range)) {
    df_long <- df_long[df_long$coefficient %in% coefficient_range, ]
  }
  if (nrow(df_long) == 0) {
    warning("LFCC has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  p <- ggplot2::ggplot(df_long,
        ggplot2::aes(x = .data$time, y = .data$coefficient,
                     fill = .data$value)) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7",
                                   high = "#B2182B", name = "Value")
  if (garnish) {
    p <- p + ggplot2::labs(title = "LFCC", x = "Time (s)",
                            y = "Coefficient")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.LFCC <- function(object, coefficient_range = NULL, ...) {
  df <- as.data.frame(object)
  val_cols <- grep("^c[0-9]+$", names(df), value = TRUE)
  if (length(val_cols) == 0) return(NULL)
  df_long <- data.frame(
    time = rep(df$time, length(val_cols)),
    coefficient = rep(as.integer(gsub("c", "", val_cols, fixed = TRUE)),
                      each = nrow(df)),
    value = as.vector(as.matrix(df[, val_cols, with = FALSE]))
  )
  if (!is.null(coefficient_range)) {
    df_long <- df_long[df_long$coefficient %in% coefficient_range, ]
  }
  if (nrow(df_long) == 0) return(NULL)
  list(
    ggplot2::geom_raster(data = df_long,
      ggplot2::aes(x = .data$time, y = .data$coefficient,
                   fill = .data$value),
      ...),
    ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7",
                                   high = "#B2182B", name = "Value")
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.BarkSpectrogram <- function(object, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (nrow(df) == 0) {
    warning("BarkSpectrogram has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  xc <- if ("time" %in% names(df)) "time"
    else if ("col" %in% names(df)) "col"
    else if ("row" %in% names(df)) "row"
    else names(df)[1]
  yc <- if ("frequency" %in% names(df)) "frequency" else if ("row" %in% names(df)) "row" else names(df)[2]
  fc <- if ("power_db" %in% names(df)) "power_db" else if ("value" %in% names(df)) "value" else names(df)[3]
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data[[xc]], y = .data[[yc]],
                     fill = .data[[fc]])) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Power (dB)")
  if (garnish) {
    p <- p + ggplot2::labs(title = "BarkSpectrogram", x = "Time (s)",
                            y = "Frequency (Bark)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.BarkSpectrogram <- function(object, ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0) return(NULL)
  xc <- if ("time" %in% names(df)) "time"
    else if ("col" %in% names(df)) "col"
    else if ("row" %in% names(df)) "row"
    else names(df)[1]
  yc <- if ("frequency" %in% names(df)) "frequency" else if ("row" %in% names(df)) "row" else names(df)[2]
  fc <- if ("power_db" %in% names(df)) "power_db" else if ("value" %in% names(df)) "value" else names(df)[3]
  list(
    ggplot2::geom_raster(data = df,
      ggplot2::aes(x = .data[[xc]], y = .data[[yc]],
                   fill = .data[[fc]]),
      ...),
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Power (dB)")
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.MelSpectrogram <- function(object, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (nrow(df) == 0) {
    warning("MelSpectrogram has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  xc <- if ("time" %in% names(df)) "time"
    else if ("col" %in% names(df)) "col"
    else if ("row" %in% names(df)) "row"
    else names(df)[1]
  yc <- if ("frequency" %in% names(df)) "frequency" else if ("row" %in% names(df)) "row" else names(df)[2]
  fc <- if ("power_db" %in% names(df)) "power_db" else if ("value" %in% names(df)) "value" else names(df)[3]
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data[[xc]], y = .data[[yc]],
                     fill = .data[[fc]])) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Power (dB)")
  if (garnish) {
    p <- p + ggplot2::labs(title = "MelSpectrogram", x = "Time (s)",
                            y = "Frequency (Mel)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.MelSpectrogram <- function(object, ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0) return(NULL)
  xc <- if ("time" %in% names(df)) "time"
    else if ("col" %in% names(df)) "col"
    else if ("row" %in% names(df)) "row"
    else names(df)[1]
  yc <- if ("frequency" %in% names(df)) "frequency" else if ("row" %in% names(df)) "row" else names(df)[2]
  fc <- if ("power_db" %in% names(df)) "power_db" else if ("value" %in% names(df)) "value" else names(df)[3]
  list(
    ggplot2::geom_raster(data = df,
      ggplot2::aes(x = .data[[xc]], y = .data[[yc]],
                   fill = .data[[fc]]),
      ...),
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = "Power (dB)")
  )
}

#' @rdname autoplot-methods
#' @param x_col Column name for x-axis (default: auto-detect).
#' @param y_col Column name for y-axis (default: auto-detect).
#' @param fill_col Column name for fill (default: auto-detect).
#' @export
autoplot.Matrix <- function(object, x_col = NULL, y_col = NULL,
    fill_col = NULL, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (nrow(df) == 0) {
    warning("Matrix has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  if (is.null(x_col)) {
    x_col <- if ("x" %in% names(df)) "x"
             else if ("time" %in% names(df)) "time"
             else if ("col" %in% names(df)) "col"
             else names(df)[1]
  }
  if (is.null(y_col)) {
    y_col <- if ("y" %in% names(df)) "y"
             else if ("frequency" %in% names(df)) "frequency"
             else if ("row" %in% names(df)) "row"
             else names(df)[2]
  }
  if (is.null(fill_col)) {
    fill_col <- if ("value" %in% names(df)) "value"
                else if ("power_db" %in% names(df)) "power_db"
                else names(df)[3]
  }
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]],
                     fill = .data[[fill_col]])) +
    ggplot2::geom_raster(...) +
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = fill_col)
  if (garnish) {
    p <- p + ggplot2::labs(title = "Matrix", x = x_col, y = y_col)
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Matrix <- function(object, x_col = NULL, y_col = NULL,
    fill_col = NULL, ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0) return(NULL)
  if (is.null(x_col)) {
    x_col <- if ("x" %in% names(df)) "x"
             else if ("time" %in% names(df)) "time"
             else if ("col" %in% names(df)) "col"
             else names(df)[1]
  }
  if (is.null(y_col)) {
    y_col <- if ("y" %in% names(df)) "y"
             else if ("frequency" %in% names(df)) "frequency"
             else if ("row" %in% names(df)) "row"
             else names(df)[2]
  }
  if (is.null(fill_col)) {
    fill_col <- if ("value" %in% names(df)) "value"
                else if ("power_db" %in% names(df)) "power_db"
                else names(df)[3]
  }
  list(
    ggplot2::geom_raster(data = df,
      ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]],
                   fill = .data[[fill_col]]),
      ...),
    ggplot2::scale_fill_gradient(low = "white", high = "black",
                                  name = fill_col)
  )
}

#' @rdname autoplot-methods
#' @param type For PCA: "scree" (variance explained), "scores"
#'   (component scores), or "both" (combined via patchwork).
#' @export
autoplot.PCA <- function(object, type = c("scree", "scores", "both"),
    garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  type <- match.arg(type)
  if (type == "scree" || type == "both") {
    eigenvals <- object$get_eigenvalues()
    variance <- eigenvals / sum(eigenvals) * 100
    comp_labels <- paste0("PC", seq_along(variance))
    scree_df <- data.frame(
      component = factor(comp_labels, levels = comp_labels),
      variance = variance, cumulative = cumsum(variance))
    p_scree <- ggplot2::ggplot(scree_df,
                ggplot2::aes(x = .data$component, y = .data$variance)) +
      ggplot2::geom_col(fill = "steelblue", alpha = 0.7) +
      ggplot2::geom_line(ggplot2::aes(y = .data$cumulative, group = 1),
        color = "darkred", linewidth = 1) +
      ggplot2::geom_point(ggplot2::aes(y = .data$cumulative),
        color = "darkred", size = 2) +
      ggplot2::scale_y_continuous(
        name = "Variance Explained (%)",
        sec.axis = ggplot2::sec_axis(~ ., name = "Cumulative (%)")) +
      ggplot2::labs(title = "PCA Scree Plot", x = "Principal Component") +
      ggplot2::theme_minimal()
  }
  if (type == "scores" || type == "both") {
    df <- as.data.frame(object)
    if (ncol(df) < 2) {
      warning("PCA scores data frame has fewer than 2 columns")
      if (type == "scores") return(ggplot2::ggplot() + ggplot2::theme_void())
    }
    pc_cols <- names(df)[seq_len(min(2, ncol(df)))]
    p_scores <- ggplot2::ggplot(df,
                 ggplot2::aes(x = .data[[pc_cols[1]]],
                              y = .data[[pc_cols[2]]])) +
      ggplot2::geom_point(alpha = 0.6, size = 2, ...) +
      ggplot2::labs(title = "PCA Scores", x = pc_cols[1], y = pc_cols[2]) +
      ggplot2::theme_minimal()
  }
  if (type == "both") {
    if (requireNamespace("patchwork", quietly = TRUE))
      return(p_scree | p_scores)
    warning("patchwork not installed; returning scree plot only")
    return(p_scree)
  }
  if (type == "scree") return(p_scree)
  p_scores
}

#' @rdname autoplot-methods
#' @export
autolayer.PCA <- function(object, ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0 || ncol(df) < 2) return(NULL)
  pc_cols <- names(df)[1:2]
  ggplot2::geom_point(data = df,
    ggplot2::aes(x = .data[[pc_cols[1]]], y = .data[[pc_cols[2]]]),
    alpha = 0.6, size = 2, ...)
}

#' @rdname autoplot-methods
#' @export
autoplot.Discriminant <- function(object, type = c("scree", "scores", "both"),
    garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  type <- match.arg(type)
  if (type == "scree" || type == "both") {
    eigenvals <- object$get_eigenvalues()
    variance <- eigenvals / sum(eigenvals) * 100
    comp_labels <- paste0("LD", seq_along(variance))
    scree_df <- data.frame(
      component = factor(comp_labels, levels = comp_labels),
      variance = variance, cumulative = cumsum(variance))
    p_scree <- ggplot2::ggplot(scree_df,
                ggplot2::aes(x = .data$component, y = .data$variance)) +
      ggplot2::geom_col(fill = "darkgreen", alpha = 0.7) +
      ggplot2::geom_line(ggplot2::aes(y = .data$cumulative, group = 1),
        color = "darkred", linewidth = 1) +
      ggplot2::geom_point(ggplot2::aes(y = .data$cumulative),
        color = "darkred", size = 2) +
      ggplot2::scale_y_continuous(
        name = "Variance Explained (%)",
        sec.axis = ggplot2::sec_axis(~ ., name = "Cumulative (%)")) +
      ggplot2::labs(title = "Discriminant Analysis Scree Plot",
                    x = "Function") +
      ggplot2::theme_minimal()
  }
  if (type == "scores" || type == "both") {
    df <- as.data.frame(object)
    if (ncol(df) < 2) {
      warning("Discriminant scores data frame has fewer than 2 columns")
      if (type == "scores") return(ggplot2::ggplot() + ggplot2::theme_void())
    }
    pc_cols <- names(df)[seq_len(min(2, ncol(df)))]
    p_scores <- ggplot2::ggplot(df,
                 ggplot2::aes(x = .data[[pc_cols[1]]],
                              y = .data[[pc_cols[2]]])) +
      ggplot2::geom_point(alpha = 0.6, size = 2, ...) +
      ggplot2::labs(title = "Discriminant Scores",
                    x = pc_cols[1], y = pc_cols[2]) +
      ggplot2::theme_minimal()
  }
  if (type == "both") {
    if (requireNamespace("patchwork", quietly = TRUE))
      return(p_scree | p_scores)
    warning("patchwork not installed; returning scree plot only")
    return(p_scree)
  }
  if (type == "scree") return(p_scree)
  p_scores
}

#' @rdname autoplot-methods
#' @export
autolayer.Discriminant <- function(object, ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0 || ncol(df) < 2) return(NULL)
  pc_cols <- names(df)[1:2]
  ggplot2::geom_point(data = df,
    ggplot2::aes(x = .data[[pc_cols[1]]], y = .data[[pc_cols[2]]]),
    alpha = 0.6, size = 2, ...)
}

# as.data.frame.FormantModeler() returns one row per time point, wide-format
# (F1_original, F1_modeled, F2_original, F2_modeled, ...). autoplot/autolayer
# need long format (time, formant_number, frequency) filtered to a track
# range; this reshapes on the *_modeled columns (the fitted/smoothed track,
# the point of a Modeler).
.formant_modeler_long_df <- function(wide, from_track, to_track, n_tracks) {
  empty <- data.frame(time = numeric(0), formant_number = integer(0),
                       frequency = numeric(0))
  if (nrow(wide) == 0) return(empty)
  if (to_track == 0L) to_track <- n_tracks
  if (from_track > to_track) return(empty)
  tracks <- from_track:to_track
  rows <- lapply(tracks, function(tr) {
    col <- paste0("F", tr, "_modeled")
    if (!col %in% names(wide)) return(NULL)
    data.frame(time = wide$time, formant_number = tr, frequency = wide[[col]])
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0) return(empty)
  do.call(rbind, rows)
}

#' @rdname autoplot-methods
#' @export
autoplot.FormantModeler <- function(object, from_track = 1L, to_track = 0L,
    garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- .formant_modeler_long_df(as.data.frame(object), from_track, to_track,
                                  object$get_number_of_tracks())
  if (nrow(df) == 0) {
    warning("FormantModeler has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  df$formant_label <- paste0("F", df$formant_number)
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label)) +
    ggplot2::geom_line(linewidth = 0.8, ...) +
    ggplot2::scale_color_brewer(palette = "Set1", name = "Formant")
  if (garnish) {
    p <- p + ggplot2::labs(title = "FormantModeler", x = "Time (s)",
                            y = "Frequency (Hz)")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.FormantModeler <- function(object, from_track = 1L, to_track = 0L, ...) {
  df <- .formant_modeler_long_df(as.data.frame(object), from_track, to_track,
                                  object$get_number_of_tracks())
  if (nrow(df) == 0) return(NULL)
  df$formant_label <- paste0("F", df$formant_number)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency,
                   color = .data$formant_label),
      linewidth = 0.8, ...),
    ggplot2::scale_color_brewer(palette = "Set1", name = "Formant")
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.Electroglottogram <- function(object, from_time = NULL, to_time = NULL,
    color = "black", garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) {
    warning("Electroglottogram has no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  yc <- if ("amplitude" %in% names(df)) "amplitude" else "value"
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data[[yc]])) +
    ggplot2::geom_line(color = color, linewidth = 0.5, ...)
  if (garnish) {
    p <- p + ggplot2::labs(title = "Electroglottogram", x = "Time (s)",
                            y = "Amplitude")
  }
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Electroglottogram <- function(object, from_time = NULL, to_time = NULL,
    color = "black", ...) {
  df <- as.data.frame(object)
  if (!is.null(from_time)) df <- df[df$time >= from_time, ]
  if (!is.null(to_time))   df <- df[df$time <= to_time, ]
  if (nrow(df) == 0) return(NULL)
  yc <- if ("amplitude" %in% names(df)) "amplitude" else "value"
  ggplot2::geom_line(data = df,
    ggplot2::aes(x = .data$time, y = .data[[yc]]),
    color = color, linewidth = 0.5, ...)
}

#' @rdname autoplot-methods
#' @export
autoplot.LongSound <- function(object, from_time = 0, to_time = 2,
    color = "black", garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  if (is.null(from_time) || is.null(to_time))
    stop("from_time and to_time are required for LongSound (streaming from disk)")
  message("Extracting ", from_time, "-", to_time, " s from LongSound...")
  sound <- object$extract_part(from_time, to_time)
  df <- sound$as_data_frame()
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$value)) +
    ggplot2::geom_line(color = color, linewidth = 0.5, ...)
  if (garnish)
    p <- p + ggplot2::labs(title = "LongSound (segment)", x = "Time (s)",
                            y = "Amplitude")
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.LongSound <- function(object, from_time = 0, to_time = 2,
    color = "black", ...) {
  if (is.null(from_time) || is.null(to_time))
    stop("from_time and to_time are required for LongSound (streaming from disk)")
  sound <- object$extract_part(from_time, to_time)
  df <- sound$as_data_frame()
  yc <- if ("amplitude" %in% names(df)) "amplitude" else "value"
  ggplot2::geom_line(data = df,
    ggplot2::aes(x = .data$time, y = .data[[yc]]),
    color = color, linewidth = 0.5, ...)
}

#' @rdname autoplot-methods
#' @param alpha_path Alpha for warping path line (default: 0.8).
#' @export
autoplot.DTW <- function(object, garnish = TRUE, alpha_path = 0.8, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  path <- object$get_path()
  if (is.null(path) || nrow(path) == 0) {
    warning("DTW has no path data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  xc <- if ("x_time" %in% names(path)) "x_time" else if ("x" %in% names(path)) "x" else names(path)[1]
  yc <- if ("y_time" %in% names(path)) "y_time" else if ("y" %in% names(path)) "y" else names(path)[2]
  p <- ggplot2::ggplot(path,
        ggplot2::aes(x = .data[[xc]], y = .data[[yc]])) +
    ggplot2::geom_path(color = "darkred", linewidth = 0.8,
                        alpha = alpha_path, ...) +
    ggplot2::geom_point(color = "darkred", size = 1, alpha = 0.6) +
    ggplot2::coord_fixed()
  if (garnish)
    p <- p + ggplot2::labs(title = "DTW Warping Path",
                            x = "Candidate Time (s)", y = "Reference Time (s)")
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.DTW <- function(object, alpha_path = 0.8, ...) {
  path <- object$get_path()
  if (is.null(path) || nrow(path) == 0) return(NULL)
  xc <- if ("x_time" %in% names(path)) "x_time" else if ("x" %in% names(path)) "x" else names(path)[1]
  yc <- if ("y_time" %in% names(path)) "y_time" else if ("y" %in% names(path)) "y" else names(path)[2]
  list(
    ggplot2::geom_path(data = path,
      ggplot2::aes(x = .data[[xc]], y = .data[[yc]]),
      color = "darkred", linewidth = 0.8, alpha = alpha_path, ...),
    ggplot2::geom_point(data = path,
      ggplot2::aes(x = .data[[xc]], y = .data[[yc]]),
      color = "darkred", size = 1, alpha = 0.6)
  )
}

#' @rdname autoplot-methods
#' @param fill_polygon Fill the polygon interior (default: FALSE).
#' @export
autoplot.Polygon <- function(object, garnish = TRUE,
    fill_polygon = FALSE, color = "black", fill_color = "grey80", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  df <- as.data.frame(object)
  if (nrow(df) == 0) {
    warning("Polygon has no points")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  geom_fn <- if (fill_polygon) ggplot2::geom_polygon else ggplot2::geom_path
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y)) +
    geom_fn(color = color, fill = if (fill_polygon) fill_color else NA,
            linewidth = 0.8, ...) +
    ggplot2::geom_point(color = color, size = 2, ...) +
    ggplot2::coord_fixed()
  if (garnish)
    p <- p + ggplot2::labs(title = "Polygon", x = "x", y = "y")
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.Polygon <- function(object, color = "black", ...) {
  df <- as.data.frame(object)
  if (nrow(df) == 0) return(NULL)
  list(
    ggplot2::geom_path(data = df,
      ggplot2::aes(x = .data$x, y = .data$y),
      color = color, linewidth = 0.8, ...),
    ggplot2::geom_point(data = df,
      ggplot2::aes(x = .data$x, y = .data$y),
      color = color, size = 2, ...)
  )
}

#' @rdname autoplot-methods
#' @export
autoplot.VocalTract <- function(object, garnish = TRUE,
    plot_type = c("area", "line"), ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  plot_type <- match.arg(plot_type)
  areas <- object$get_areas()
  n <- length(areas)
  dx <- object$get_section_length()
  df <- data.frame(
    distance = seq(0.5 * dx, by = dx, length.out = n), area = areas)
  if (plot_type == "area") {
    p <- ggplot2::ggplot(df,
          ggplot2::aes(x = .data$distance, y = .data$area)) +
      ggplot2::geom_area(fill = "steelblue", alpha = 0.5) +
      ggplot2::geom_line(color = "darkblue", linewidth = 0.8)
  } else {
    p <- ggplot2::ggplot(df,
          ggplot2::aes(x = .data$distance, y = .data$area)) +
      ggplot2::geom_col(fill = "steelblue", alpha = 0.7, width = dx * 0.9)
  }
  if (garnish)
    p <- p + ggplot2::labs(title = "VocalTract Area Function",
                            x = "Distance from Glottis (m)",
                            y = expression("Area (m"^2 * ")"))
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.VocalTract <- function(object, ...) {
  areas <- object$get_areas()
  n <- length(areas)
  dx <- object$get_section_length()
  df <- data.frame(
    distance = seq(0.5 * dx, by = dx, length.out = n), area = areas)
  ggplot2::geom_line(data = df,
    ggplot2::aes(x = .data$distance, y = .data$area),
    color = "darkblue", linewidth = 0.8, ...)
}

#' @rdname autoplot-methods
#' @param frame Time or frame index to extract LPC spectrum at.
#' @export
autoplot.LPC <- function(object, frame = 1L, garnish = TRUE,
    color = "darkred", ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  spectrum <- object$to_spectrum(frame)
  df <- spectrum$as_data_frame()
  if (!"power_dB" %in% names(df) && "power" %in% names(df))
    df$power_dB <- 10 * log10(pmax(df$power, 1e-20))
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$frequency, y = .data$power_dB)) +
    ggplot2::geom_line(color = color, linewidth = 0.8, ...)
  if (garnish)
    p <- p + ggplot2::labs(
      title = paste0("LPC Spectrum Envelope (frame ", frame, ")"),
      x = "Frequency (Hz)", y = "Power (dB)")
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.LPC <- function(object, frame = 1L, color = "darkred", ...) {
  spectrum <- object$to_spectrum(frame)
  df <- spectrum$as_data_frame()
  if (!"power_dB" %in% names(df) && "power" %in% names(df))
    df$power_dB <- 10 * log10(pmax(df$power, 1e-20))
  ggplot2::geom_line(data = df,
    ggplot2::aes(x = .data$frequency, y = .data$power_dB),
    color = color, linewidth = 0.8, ...)
}

#' @rdname autoplot-methods
#' @param formant_type Type of formant to plot: "oral", "nasal", "frication",
#'   "tracheal", "delta", or (autoplot.KlattGrid only) "all".
#' @export
autoplot.KlattGrid <- function(object, from_time = NULL, to_time = NULL,
    formant_type = c("all", "oral", "nasal", "frication", "tracheal", "delta"),
    max_formant = 6L, garnish = TRUE, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Please install it.")
  formant_type <- match.arg(formant_type)
  .ekf <- function(obj, ftype, nf, tmin, tmax) {
    times <- seq(tmin, tmax, length.out = 100)
    rows <- list()
    for (t in times)
      for (f in seq_len(nf)) {
        freq <- tryCatch(obj$get_formant_at_time(.klattgrid_formant_type_code(ftype), f, t),
                         error = function(e) NA_real_)
        if (!is.na(freq))
          rows[[length(rows) + 1]] <- data.frame(
            time = t, formant = f, frequency = freq, stringsAsFactors = FALSE)
      }
    if (length(rows) == 0) return(data.frame())
    do.call(rbind, rows)
  }
  tmin <- if (is.null(from_time)) object$get_xmin() else from_time
  tmax <- if (is.null(to_time)) object$get_xmax() else to_time
  types <- if (formant_type == "all")
    c("oral", "nasal", "frication", "tracheal", "delta") else formant_type
  all_dfs <- list()
  for (ft in types) {
    df <- .ekf(object, ft, max_formant, tmin, tmax)
    if (nrow(df) > 0) {
      df$formant_label <- paste0(toupper(substr(ft, 1, 1)), "F", df$formant)
      all_dfs[[ft]] <- df
    }
  }
  if (length(all_dfs) == 0) {
    warning("KlattGrid has no formant data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  df <- do.call(rbind, all_dfs)
  p <- ggplot2::ggplot(df,
        ggplot2::aes(x = .data$time, y = .data$frequency,
                     color = .data$formant_label)) +
    ggplot2::geom_line(linewidth = 0.8, ...) +
    ggplot2::scale_color_brewer(palette = "Set1", name = "Formant")
  if (garnish)
    p <- p + ggplot2::labs(title = "KlattGrid Formants", x = "Time (s)",
                            y = "Frequency (Hz)")
  p + ggplot2::theme_minimal()
}

#' @rdname autoplot-methods
#' @export
autolayer.KlattGrid <- function(object, from_time = NULL, to_time = NULL,
    formant_type = c("oral", "nasal", "frication", "tracheal", "delta"),
    max_formant = 6L, ...) {
  formant_type <- match.arg(formant_type)
  tmin <- if (is.null(from_time)) object$get_xmin() else from_time
  tmax <- if (is.null(to_time)) object$get_xmax() else to_time
  times <- seq(tmin, tmax, length.out = 100)
  rows <- list()
  for (t in times)
    for (f in seq_len(max_formant)) {
      freq <- tryCatch(object$get_formant_at_time(.klattgrid_formant_type_code(formant_type), f, t),
                       error = function(e) NA_real_)
      if (!is.na(freq))
        rows[[length(rows) + 1]] <- data.frame(
          time = t, formant = f, frequency = freq, stringsAsFactors = FALSE)
    }
  if (length(rows) == 0) return(NULL)
  df <- do.call(rbind, rows)
  df$formant_label <- paste0(toupper(substr(formant_type, 1, 1)), "F", df$formant)
  list(
    ggplot2::geom_line(data = df,
      ggplot2::aes(x = .data$time, y = .data$frequency,
                   color = .data$formant_label),
      linewidth = 0.8, ...),
    ggplot2::scale_color_brewer(palette = "Set1", name = "Formant")
  )
}

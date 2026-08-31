#' PowerCepstrum and PowerCepstrogram Visualization Functions
#'
#' @description
#' ggplot2-based visualizations for power cepstrum objects, replacing
#' Praat's native graphics system with R's powerful plotting capabilities.
#'
#' @return This is a documentation-only overview; see the individual functions
#'   (\code{\link{plot_powercepstrum}}, \code{\link{create_cepstrum_report}})
#'   for their return values.
#'
#' @examples
#' # See individual functions, e.g. ?plot_powercepstrum
#' @name cepstrum_plots
NULL
#'

# Apply the shared cepstrum plot theme (minimal/bw/classic + title styling).
.apply_cepstrum_theme <- function(p, theme) {
  p + switch(theme,
    minimal = ggplot2::theme_minimal(),
    bw = ggplot2::theme_bw(),
    classic = ggplot2::theme_classic()
  ) + ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 14),
    plot.subtitle = ggplot2::element_text(size = 10, color = "gray40")
  )
}

# Sample the CPP time series at the given times (NA on error).
.sample_cpp_timeseries <- function(cepstrogram, sample_times, qmin, qmax) {
  vapply(sample_times, function(t) {
    tryCatch(
      cepstrogram$get_cpp_at_time(time = t, interpolation = "linear",
                                 qmin = qmin, qmax = qmax),
      error = function(e) NA_real_
    )
  }, numeric(1))
}

# Add a peak marker + CPP label to a power cepstrum plot.
.add_peak_annotation <- function(p, cepstrum, qmin, qmax, fit_method) {
  tryCatch({
    peak_quefrency <- cepstrum$get_quefrency_of_peak(
      interpolation = "parabolic", qmin = qmin, qmax = qmax)
    cpp <- cepstrum$get_peak_prominence(
      interpolation = "parabolic", qmin = qmin, qmax = qmax, fit_method = fit_method)
    peak_value <- cepstrum$get_value_at_quefrency(
      quefrency = peak_quefrency, interpolation = "parabolic",
      qmin = qmin, qmax = qmax, unit = "dB")
    p + ggplot2::geom_point(
      data = data.frame(quefrency = peak_quefrency, power_db = peak_value),
      ggplot2::aes(x = quefrency, y = power_db),
      color = "red", size = 4, shape = 17
    ) + ggplot2::annotate("text",
      x = peak_quefrency, y = peak_value,
      label = sprintf("CPP: %.2f dB\nQ: %.4f s", cpp, peak_quefrency),
      vjust = -1.5, hjust = 0.5, size = 3.5, fontface = "bold", color = "red")
  }, error = function(e) {
    warning("Could not compute peak: ", e$message)
    p
  })
}

# Per-time-frame cepstral peak quefrency from a cepstrogram raster.
.cpp_peak_by_time <- function(plot_data) {
  do.call(rbind, lapply(
    split(plot_data, plot_data$time),
    function(d) {
      data.frame(
        time = d$time[1],
        quefrency = d$quefrency[which.max(d$power_db)]
      )
    }
  ))
}

# Arrange the three cepstrum panels and optionally save the report.
.assemble_cepstrum_report <- function(p1, p2, p3, save_path, dpi, format) {
  combined <- gridExtra::grid.arrange(p1, p2, p3, ncol = 1,
    heights = c(1, 1.5, 1))
  if (!is.null(save_path)) {
    ggplot2::ggsave(filename = save_path, plot = combined,
                    width = 10, height = 12, dpi = dpi, device = format)
    message("Cepstrum report saved to: ", save_path)
  }
  invisible(combined)
}






#' @title Plot PowerCepstrum
#'
#' @description
#' Creates a visualization of a power cepstrum showing the cepstral values
#' across quefrencies, with optional peak and trend line annotations.
#'
#' @param cepstrum PowerCepstrum object
#' @param show_peak Logical. Highlight the cepstral peak (default: TRUE)
#' @param show_trendline Logical. Show regression trend line (default: TRUE)
#' @param qmin Numeric. Minimum quefrency for peak search (seconds, default:
#  0.001)
#' @param qmax Numeric. Maximum quefrency for peak search (seconds, default: 0)
#' @param fit_method Character. Trend line fit method (default: "straight")
#' @param quefrency_range Numeric vector. c(min, max) quefrency range to display
#  (default: NULL = auto)
#' @param db_range Numeric vector. c(min, max) dB range to display (default:
#  NULL = auto)
#' @inheritParams pladdrr_shared_params title
#' @param theme Character. ggplot2 theme: "minimal", "bw", "classic" (default:
#  "minimal")
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' spectrum <- sound$to_spectrum()
#' cepstrum <- spectrum$to_power_cepstrum()
#'
#' # Basic plot
#' plot_powercepstrum(cepstrum)
#'
#' # Customized plot
#' plot_powercepstrum(cepstrum,
#'                   show_peak = TRUE,
#'                   show_trendline = TRUE,
#'                   quefrency_range = c(0.001, 0.02),
#'                   title = "Voice Quality Analysis")
#'
#' @export

plot_powercepstrum <- function(cepstrum,
                              show_peak = TRUE,
                              show_trendline = TRUE,
                              qmin = 0.001,
                              qmax = 0,
                              fit_method = c("straight", "exponential decay",
                                "parabolic"),
                              quefrency_range = NULL,
                              db_range = NULL,
                              title = NULL,
                              theme = c("minimal", "bw", "classic")) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(cepstrum, "PowerCepstrum")) {
    stop("cepstrum must be a PowerCepstrum object")
  }
  
  fit_method <- match.arg(fit_method)
  theme <- match.arg(theme)
  
  # Real quefrency values and power come from the object's own
  # as_data_frame(), whose "power" column holds raw linear power (confirmed
  # against get_value_at_quefrency(unit = "dB"), a different accessor on the
  # same object that returns real dB). Convert explicitly.
  plot_data <- cepstrum$as_data_frame()
  plot_data$power_db <- 10 * log10(pmax(plot_data$power, 1e-20))
  
  # Apply quefrency range filter if specified
  if (!is.null(quefrency_range)) {
    plot_data <- plot_data[plot_data$quefrency >= quefrency_range[1] & 
                           plot_data$quefrency <= quefrency_range[2], ]
  }
  
  # Create base plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = quefrency, y = power_db)) +
    ggplot2::geom_line(color = "steelblue", linewidth = 0.8)
  
  # Add peak annotation if requested
  if (show_peak) p <- .add_peak_annotation(p, cepstrum, qmin, qmax, fit_method)
  
  # Add trend line if requested
  p <- .add_trendline(p, plot_data, show_trendline)
  
  # Finish plot (dB range, labels, theme)
  p <- .finish_powercepstrum_plot(p, title, db_range, theme)
  
  return(p)
}


#' @title Plot PowerCepstrogram
#'
#' @description
#' Creates a heatmap visualization of a power cepstrogram showing how
#' the cepstral spectrum varies over time, similar to a spectrogram.
#'
#' @inheritParams pladdrr_shared_params cepstrogram
#' @param time_range Numeric vector. c(start, end) time range to display
#  (default: NULL = auto)
#' @param quefrency_range Numeric vector. c(min, max) quefrency range to display
#  (default: c(0, 0.05))
#' @param db_range Numeric vector. c(min, max) dB range for color scale
#  (default: NULL = auto)
#' @param color_scale Character. Color palette: "viridis", "inferno", "magma",
#  "plasma" (default: "viridis")
#' @param show_cpp_contour Logical. Overlay CPP contour over time (default:
#  FALSE)
#' @param contour_color Character. Color for CPP contour line (default: "white")
#' @inheritParams pladdrr_shared_params title
#' @param theme Character. ggplot2 theme (default: "minimal")
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)
#'
#' # Basic plot
#' plot_powercepstrogram(cepstrogram)
#'
#' # With CPP contour
#' plot_powercepstrogram(cepstrogram,
#'                      show_cpp_contour = TRUE,
#'                      quefrency_range = c(0.001, 0.02))
#'
#' @export
plot_powercepstrogram <- function(cepstrogram,
                                 time_range = NULL,
                                 quefrency_range = c(0, 0.05),
                                 db_range = NULL,
                                 color_scale = c("viridis", "inferno",
                                   "magma", "plasma"),
                                 show_cpp_contour = FALSE,
                                 contour_color = "white",
                                 title = NULL,
                                 theme = c("minimal", "bw", "classic")) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(cepstrogram, "PowerCepstrogram")) {
    stop("cepstrogram must be a PowerCepstrogram object")
  }
  
  color_scale <- match.arg(color_scale)
  theme <- match.arg(theme)
  
  # Long-format data frame with real per-bin time/quefrency values,
  # correctly oriented (delegates to as.data.frame.PowerCepstrogram,
  # which already gets this right — see R/as-data-frame-missing.R).
  plot_data <- .cepstrogram_plot_data(cepstrogram, time_range, quefrency_range)
  
  # Create base heatmap
  p <- ggplot2::ggplot(plot_data,
    ggplot2::aes(x = time, y = quefrency, fill = power_db)) +
    ggplot2::geom_raster(interpolate = TRUE)
  
  # Apply color scale (with dB range)
  p <- .apply_cepstrogram_color_scale(p, color_scale, db_range)
  
  # Add CPP contour if requested: overlay the cepstral-peak quefrency track,
  # computed per time frame from the cepstrogram's own raster. Peak location
  # is invariant under the monotone log transform, so power_db (already
  # computed above) selects the same bin as raw power. This replaces the
  # previous flat placeholder at quefrency = 0.01 with the real per-frame
  # argmax; no per-time-point C++ query or interpolation is needed.
  p <- .add_cpp_contour(p, plot_data, show_cpp_contour, contour_color)
  
  # Add labels + theme
  p <- .finish_cepstrogram_plot(p, title, theme)
  
  return(p)
}


#' @title Plot CPP Time Series
#'
#' @description
#' Creates a line plot of Cepstral Peak Prominence (CPP) values over time
#' from a PowerCepstrogram object. Useful for tracking voice quality variation.
#'
#' @inheritParams pladdrr_shared_params cepstrogram
#' @param time_range Numeric vector. c(start, end) time range to display
#  (default: NULL = auto)
#' @param qmin Numeric. Minimum quefrency for peak search (default: 0.001)
#' @param qmax Numeric. Maximum quefrency for peak search (default: 0)
#' @param n_samples Integer. Number of time points to sample (default: 100)
#' @param smooth Logical. Apply smoothing to CPP contour (default: FALSE)
#' @param smooth_span Numeric. Smoothing span for loess (default: 0.1)
#' @param reference_lines Numeric vector. Reference CPP values to plot as
#  horizontal lines (default: NULL)
#' @inheritParams pladdrr_shared_params title
#' @param theme Character. ggplot2 theme (default: "minimal")
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)
#'
#' # CPP time series
#' plot_cpp_timeseries(cepstrogram, n_samples = 20)
#'
#' # With smoothing and reference lines
#' plot_cpp_timeseries(cepstrogram,
#'                    n_samples = 20,
#'                    smooth = TRUE,
#'                    reference_lines = c(5, 10, 15))
#'
#' @export
plot_cpp_timeseries <- function(cepstrogram,
                               time_range = NULL,
                               qmin = 0.001,
                               qmax = 0,
                               n_samples = 100,
                               smooth = FALSE,
                               smooth_span = 0.1,
                               reference_lines = NULL,
                               title = NULL,
                               theme = c("minimal", "bw", "classic")) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(cepstrogram, "PowerCepstrogram")) {
    stop("cepstrogram must be a PowerCepstrogram object")
  }
  
  theme <- match.arg(theme)
  
  max_time <- max(as.data.frame(cepstrogram)$time)
  
  # Determine time range
  if (is.null(time_range)) {
    time_range <- c(0, max_time)
  }
  
  # Sample CPP time series and build plot data
  plot_data <- .cpp_timeseries_data(cepstrogram, time_range, n_samples, qmin,
    qmax)
  
  # Create base plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = time, y = cpp)) +
    ggplot2::geom_line(color = "steelblue", linewidth = 1)
  
  # Add smoothing if requested
  if (smooth && nrow(plot_data) > 10) {
    p <- p + ggplot2::geom_smooth(
      method = "loess",
      span = smooth_span,
      se = TRUE,
      color = "darkblue",
      fill = "lightblue",
      alpha = 0.3
    )
  }
  
  # Add reference lines if specified
  p <- .add_reference_lines(p, reference_lines)
  
  # Add mean CPP line
  p <- .add_mean_cpp_line(p, plot_data)
  
  # Add labels + theme
  p <- .finish_cpp_timeseries_plot(p, plot_data, title, theme)
  
  return(p)
}


#' @title Create Cepstrum Report Plot
#'
#' @description
#' Creates a multi-panel diagnostic plot combining power cepstrum,
#' cepstrogram, and CPP time series for comprehensive analysis.
#'
#' @inheritParams pladdrr_shared_params cepstrogram
#' @param time_slice Numeric. Time point for extracting single cepstrum
#  (default: middle)
#' @param save_path Character. Path to save plot (optional)
#' @param format Character. Output format: "png", "pdf", "svg" (default: "png")
#' @param dpi Numeric. Resolution for raster formats (default: 300)
#'
#' @return A combined plot object (invisibly)
#'
#' @examples
#' if (requireNamespace("gridExtra", quietly = TRUE)) {
#' sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate =
#  16000)
#'   cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
#'
#'   # Create comprehensive report at t = 0.3s (mid-signal)
#'   create_cepstrum_report(cepstrogram, time_slice = 0.3)
#' }
#'
#' @export
create_cepstrum_report <- function(cepstrogram,
                                  time_slice = NULL,
                                  save_path = NULL,
                                  format = c("png", "pdf", "svg"),
                                  dpi = 300) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }
  
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    stop(
      "Package 'gridExtra' is required for multi-panel layout. Please install it.")
  }
  
  format <- match.arg(format)
  
  # Determine time slice if not specified
  if (is.null(time_slice)) {
    # Default to mid-signal, using the cepstrogram's real duration — not a
    # hardcoded 5.0 s placeholder, which overran short signals.
    max_time <- max(as.data.frame(cepstrogram)$time)
    time_slice <- max_time / 2
  }
  
  # Extract single cepstrum at time slice
  cepstrum <- cepstrogram$get_power_cepstrum_at_time(time_slice)
  
  # Create individual plots
  p1 <- plot_powercepstrum(
    cepstrum,
    title = sprintf("Power Cepstrum at t=%.2f s", time_slice)
  )
  
  p2 <- plot_powercepstrogram(
    cepstrogram,
    title = "Power Cepstrogram"
  )
  
  p3 <- plot_cpp_timeseries(
    cepstrogram,
    title = "CPP Over Time"
  )
  
  .assemble_cepstrum_report(p1, p2, p3, save_path, dpi, format)
  
}


# Build cepstrogram plot data (long format, dB) filtered to ranges.
.cepstrogram_plot_data <- function(cepstrogram, time_range, quefrency_range) {
  plot_data <- as.data.frame(cepstrogram)
  plot_data$power_db <- 10 * log10(pmax(plot_data$power, 1e-20))
  if (!is.null(time_range)) {
    plot_data <- plot_data[plot_data$time >= time_range[1] &
                           plot_data$time <= time_range[2], ]
  }
  plot_data[plot_data$quefrency >= quefrency_range[1] &
            plot_data$quefrency <= quefrency_range[2], ]
}


# Add dashed horizontal reference lines to a CPP time-series plot.
.add_reference_lines <- function(p, reference_lines) {
  if (is.null(reference_lines)) return(p)
  for (ref_val in reference_lines) {
    p <- p + ggplot2::geom_hline(yintercept = ref_val,
      linetype = "dashed", color = "red", alpha = 0.7)
  }
  p
}

# Add the mean CPP line + label.
.add_mean_cpp_line <- function(p, plot_data) {
  if (nrow(plot_data) == 0) return(p)
  mean_cpp <- mean(plot_data$cpp, na.rm = TRUE)
  p + ggplot2::geom_hline(yintercept = mean_cpp,
    linetype = "solid", color = "red", linewidth = 0.8, alpha = 0.6) +
    ggplot2::annotate("text", x = max(plot_data$time) * 0.95, y = mean_cpp,
                      label = sprintf("Mean: %.2f dB", mean_cpp),
                      vjust = -0.5, hjust = 1, size = 3.5,
                      color = "red", fontface = "bold")
}


# Add a linear-regression trend line to a power cepstrum plot.
.add_trendline <- function(p, plot_data, show_trendline) {
  if (!show_trendline) return(p)
  fit <- lm(power_db ~ quefrency, data = plot_data)
  plot_data$fitted <- predict(fit)
  p + ggplot2::geom_line(data = plot_data,
    ggplot2::aes(x = quefrency, y = fitted),
    color = "darkgray", linetype = "dashed", linewidth = 0.6)
}


# Finish a power cepstrum plot: dB range, labels, theme.
.finish_powercepstrum_plot <- function(p, title, db_range, theme) {
  if (!is.null(db_range)) p <- p + ggplot2::coord_cartesian(ylim = db_range)
  if (is.null(title)) title <- "Power Cepstrum"
  p <- p + ggplot2::labs(title = title,
    subtitle = "Cepstral analysis for voice quality assessment",
    x = "Quefrency (s)", y = "Power (dB)")
  .apply_cepstrum_theme(p, theme)
}


# Apply the cepstrogram color scale, optionally with a dB range.
.apply_cepstrogram_color_scale <- function(p, color_scale, db_range) {
  p <- p + switch(color_scale,
    viridis = ggplot2::scale_fill_viridis_c(name = "Power (dB)",
      option = "viridis"),
    inferno = ggplot2::scale_fill_viridis_c(name = "Power (dB)",
      option = "inferno"),
    magma = ggplot2::scale_fill_viridis_c(name = "Power (dB)",
      option = "magma"),
    plasma = ggplot2::scale_fill_viridis_c(name = "Power (dB)",
      option = "plasma"))
  if (!is.null(db_range)) {
    p + ggplot2::scale_fill_viridis_c(name = "Power (dB)",
                                      option = color_scale, limits = db_range)
  } else {
    p
  }
}


# Finish a CPP time-series plot: labels + theme.
.finish_cpp_timeseries_plot <- function(p, plot_data, title, theme) {
  if (is.null(title)) title <- "CPP Time Series"
  p <- p + ggplot2::labs(title = title,
    subtitle = if (nrow(plot_data) > 0) {
      sprintf("Mean CPP: %.2f dB (SD: %.2f)",
              mean(plot_data$cpp, na.rm = TRUE),
              sd(plot_data$cpp, na.rm = TRUE))
    } else {
      "No samples"
    },
    x = "Time (s)", y = "CPP (dB)")
  .apply_cepstrum_theme(p, theme)
}


# Sample a CPP time series and build NA-filtered plot data.
.cpp_timeseries_data <- function(cepstrogram, time_range, n_samples, qmin,
  qmax) {
  sample_times <- seq(time_range[1], time_range[2], length.out = n_samples)
  cpp_values <- .sample_cpp_timeseries(cepstrogram, sample_times, qmin, qmax)
  plot_data <- data.frame(time = sample_times, cpp = cpp_values)
  plot_data[!is.na(plot_data$cpp), ]
}


# Overlay the cepstral-peak quefrency contour.
.add_cpp_contour <- function(p, plot_data, show_cpp_contour, contour_color) {
  if (!show_cpp_contour || nrow(plot_data) == 0) return(p)
  peak_q_by_time <- .cpp_peak_by_time(plot_data)
  p + ggplot2::geom_line(data = peak_q_by_time,
    ggplot2::aes(x = time, y = quefrency),
    color = contour_color, linewidth = 1.2, inherit.aes = FALSE)
}

# Finish a cepstrogram plot: labels + theme.
.finish_cepstrogram_plot <- function(p, title, theme) {
  if (is.null(title)) title <- "Power Cepstrogram"
  p <- p + ggplot2::labs(title = title,
    subtitle = "Time-varying cepstral analysis",
    x = "Time (s)", y = "Quefrency (s)")
  .apply_cepstrum_theme(p, theme)
}

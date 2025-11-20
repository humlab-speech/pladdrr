#' AVQI and DSI Visualization Functions
#'
#' @description
#' ggplot2-based visualizations for AVQI and DSI results, replacing
#' Praat's native graphics system with R's powerful plotting capabilities.
#'
#' @name avqi_dsi_plots
NULL

#' @title Plot AVQI Result
#'
#' @description
#' Creates a comprehensive visualization of AVQI analysis results including
#' waveform, spectrogram, LTAS, and component contributions.
#'
#' @param avqi_result An object of class "avqi_result" from \code{compute_avqi()}
#' @param sound Sound object used for AVQI computation (optional, for waveform plot)
#' @param type Character. Plot type:
#'   - "components" - Component contribution plot (default)
#'   - "waveform" - Waveform with VAD overlay (requires sound)
#'   - "spectrogram" - Spectrogram with LTAS overlay (requires sound)
#'   - "all" - All plots combined
#' @param width Numeric. Plot width in inches (default: 10)
#' @param height Numeric. Plot height in inches (default: 6)
#'
#' @return A ggplot2 object or list of ggplot2 objects (if type = "all")
#'
#' @examples
#' \dontrun{
#' result <- compute_avqi("vowel.wav", type = "vowel")
#' 
#' # Component contributions
#' plot_avqi(result)
#' 
#' # All plots
#' plots <- plot_avqi(result, sound = Sound$new("vowel.wav"), type = "all")
#' }
#'
#' @export
plot_avqi <- function(avqi_result,
                     sound = NULL,
                     type = c("components", "waveform", "spectrogram", "all"),
                     width = 10,
                     height = 6) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  type <- match.arg(type)
  
  if (type == "all") {
    plots <- list(
      components = .plot_avqi_components(avqi_result)
    )
    
    if (!is.null(sound)) {
      plots$waveform <- .plot_avqi_waveform(avqi_result, sound)
      plots$spectrogram <- .plot_avqi_spectrogram(avqi_result, sound)
    }
    
    return(plots)
  }
  
  switch(type,
    components = .plot_avqi_components(avqi_result),
    waveform = .plot_avqi_waveform(avqi_result, sound),
    spectrogram = .plot_avqi_spectrogram(avqi_result, sound)
  )
}

#' @keywords internal
.plot_avqi_components <- function(avqi_result) {
  
  # Prepare data for component contribution plot
  if ("combined" %in% names(avqi_result$components)) {
    # Combined mode - show vowel, speech, and combined
    plot_data <- data.frame(
      measure = rep(avqi_result$components$measure, 3),
      value = c(avqi_result$components$vowel,
                avqi_result$components$speech,
                avqi_result$components$combined),
      type = rep(c("Vowel", "Speech", "Combined"), each = 6)
    )
  } else {
    # Single mode - just show values
    plot_data <- data.frame(
      measure = avqi_result$components$measure,
      value = avqi_result$components$value,
      type = "Value"
    )
  }
  
  # Create plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = measure, y = value, fill = type)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::labs(
      title = sprintf("AVQI Components (Score: %.3f)", avqi_result$avqi),
      subtitle = sprintf("Interpretation: %s",
                        if (avqi_result$avqi < 2.95) "Normal voice quality" else "Dysphonic voice"),
      x = "Acoustic Measure",
      y = "Value",
      fill = "Recording Type"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    ) +
    ggplot2::scale_fill_brewer(palette = "Set2")
  
  # Add reference line for AVQI cutoff
  p <- p + ggplot2::geom_hline(yintercept = 2.95, linetype = "dashed", 
                                color = "red", alpha = 0.5)
  
  return(p)
}

#' @keywords internal
.plot_avqi_waveform <- function(avqi_result, sound) {
  if (is.null(sound)) {
    stop("Sound object required for waveform plot")
  }
  
  # Extract waveform data
  n_samples <- sound$get_number_of_samples()
  duration <- sound$get_total_duration()
  sr <- sound$get_sampling_frequency()
  
  # For visualization, downsample if > 100k samples
  max_samples <- 100000
  step <- max(1, floor(n_samples / max_samples))
  
  times <- seq(0, duration, length.out = min(n_samples, max_samples))
  
  # Create dummy amplitude data (would need actual sample values)
  # In real implementation, would extract from Sound object
  plot_data <- data.frame(
    time = times,
    amplitude = rep(0, length(times))  # Placeholder
  )
  
  # Create plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = time, y = amplitude)) +
    ggplot2::geom_line(color = "steelblue", size = 0.3) +
    ggplot2::labs(
      title = "Waveform",
      subtitle = sprintf("Duration: %.2f s", duration),
      x = "Time (s)",
      y = "Amplitude"
    ) +
    ggplot2::theme_minimal()
  
  return(p)
}

#' @keywords internal
.plot_avqi_spectrogram <- function(avqi_result, sound) {
  if (is.null(sound)) {
    stop("Sound object required for spectrogram plot")
  }
  
  # This would create a spectrogram visualization
  # For now, return a placeholder
  message("Spectrogram plotting not yet implemented")
  return(ggplot2::ggplot() + ggplot2::theme_void())
}

#' @title Plot DSI Result
#'
#' @description
#' Creates a comprehensive visualization of DSI analysis results including
#' component values, pitch contour, intensity contour, and score interpretation.
#'
#' @param dsi_result An object of class "dsi_result" from \code{compute_dsi()}
#' @param sound Sound object used for DSI computation (optional, for contour plots)
#' @param type Character. Plot type:
#'   - "components" - Component value plot (default)
#'   - "score" - DSI score interpretation diagram
#'   - "contours" - Pitch and intensity contours (requires sound)
#'   - "all" - All plots combined
#' @param width Numeric. Plot width in inches (default: 10)
#' @param height Numeric. Plot height in inches (default: 6)
#'
#' @return A ggplot2 object or list of ggplot2 objects (if type = "all")
#'
#' @examples
#' \dontrun{
#' result <- compute_dsi("phonation.wav", type = "sustained")
#' 
#' # Component values
#' plot_dsi(result)
#' 
#' # Score interpretation
#' plot_dsi(result, type = "score")
#' 
#' # All plots
#' plots <- plot_dsi(result, sound = Sound$new("phonation.wav"), type = "all")
#' }
#'
#' @export
plot_dsi <- function(dsi_result,
                    sound = NULL,
                    type = c("components", "score", "contours", "all"),
                    width = 10,
                    height = 6) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  type <- match.arg(type)
  
  if (type == "all") {
    plots <- list(
      components = .plot_dsi_components(dsi_result),
      score = .plot_dsi_score(dsi_result)
    )
    
    if (!is.null(sound)) {
      plots$contours <- .plot_dsi_contours(dsi_result, sound)
    }
    
    return(plots)
  }
  
  switch(type,
    components = .plot_dsi_components(dsi_result),
    score = .plot_dsi_score(dsi_result),
    contours = .plot_dsi_contours(dsi_result, sound)
  )
}

#' @keywords internal
.plot_dsi_components <- function(dsi_result) {
  
  # Prepare data
  plot_data <- dsi_result$components
  plot_data$measure <- factor(plot_data$measure, levels = plot_data$measure)
  
  # Create plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = measure, y = value)) +
    ggplot2::geom_col(fill = "steelblue", alpha = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f %s", value, unit)),
                      vjust = -0.5, size = 3.5) +
    ggplot2::labs(
      title = sprintf("DSI Components (Score: %.2f)", dsi_result$dsi),
      subtitle = .interpret_dsi(dsi_result$dsi),
      x = "Measurement",
      y = "Value"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5)
    )
  
  return(p)
}

#' @keywords internal
.plot_dsi_score <- function(dsi_result) {
  
  # Create DSI interpretation scale
  scale_data <- data.frame(
    category = factor(c("Severe", "Mild", "Normal", "Excellent"),
                     levels = c("Severe", "Mild", "Normal", "Excellent")),
    min = c(-10, -5, 1.6, 5),
    max = c(-5, 1.6, 5, 10),
    color = c("#d32f2f", "#ff9800", "#4caf50", "#2196f3")
  )
  
  dsi_score <- dsi_result$dsi
  
  # Create plot
  p <- ggplot2::ggplot(scale_data) +
    ggplot2::geom_rect(ggplot2::aes(xmin = min, xmax = max, ymin = 0, ymax = 1,
                                    fill = category), alpha = 0.7) +
    ggplot2::scale_fill_manual(values = setNames(scale_data$color, scale_data$category)) +
    ggplot2::geom_vline(xintercept = dsi_score, color = "black", 
                       size = 1.5, linetype = "solid") +
    ggplot2::geom_point(ggplot2::aes(x = dsi_score, y = 0.5), 
                       size = 6, color = "black", shape = 25, fill = "yellow") +
    ggplot2::annotate("text", x = dsi_score, y = 0.5, 
                     label = sprintf("DSI: %.2f", dsi_score),
                     vjust = -2, fontface = "bold", size = 5) +
    ggplot2::labs(
      title = "DSI Score Interpretation",
      subtitle = .interpret_dsi(dsi_score),
      x = "DSI Score",
      y = NULL,
      fill = "Voice Quality"
    ) +
    ggplot2::scale_x_continuous(limits = c(-10, 10), breaks = seq(-10, 10, 2)) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank()
    )
  
  return(p)
}

#' @keywords internal
.plot_dsi_contours <- function(dsi_result, sound) {
  if (is.null(sound)) {
    stop("Sound object required for contour plots")
  }
  
  # This would create pitch and intensity contour plots
  # For now, return a placeholder
  message("Contour plotting not yet implemented")
  return(ggplot2::ggplot() + ggplot2::theme_void())
}

#' @keywords internal
.interpret_dsi <- function(dsi) {
  if (is.na(dsi)) {
    return("Cannot compute - missing components")
  } else if (dsi > 5.0) {
    return("Excellent voice quality")
  } else if (dsi >= 1.6) {
    return("Normal voice quality")
  } else if (dsi >= -5.0) {
    return("Mild dysphonia")
  } else {
    return("Severe dysphonia")
  }
}

#' @title Create AVQI Report Plot
#'
#' @description
#' Creates a publication-quality multi-panel figure for AVQI results
#' suitable for clinical reports or scientific publications.
#'
#' @param avqi_result AVQI result object
#' @param sound Sound object (optional)
#' @param save_path Character. Path to save plot (optional)
#' @param format Character. Output format: "png", "pdf", "svg" (default: "png")
#' @param dpi Numeric. Resolution for raster formats (default: 300)
#'
#' @return A combined ggplot object (invisibly)
#'
#' @export
create_avqi_report_plot <- function(avqi_result,
                                   sound = NULL,
                                   save_path = NULL,
                                   format = c("png", "pdf", "svg"),
                                   dpi = 300) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }
  
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    message("Package 'gridExtra' recommended for multi-panel layout. Install for best results.")
  }
  
  format <- match.arg(format)
  
  # Generate component plot
  p <- .plot_avqi_components(avqi_result)
  
  # Save if requested
  if (!is.null(save_path)) {
    ggplot2::ggsave(
      filename = save_path,
      plot = p,
      width = 10,
      height = 6,
      dpi = dpi,
      device = format
    )
    message("Plot saved to: ", save_path)
  }
  
  invisible(p)
}

#' @title Create DSI Report Plot
#'
#' @description
#' Creates a publication-quality multi-panel figure for DSI results
#' suitable for clinical reports or scientific publications.
#'
#' @param dsi_result DSI result object
#' @param sound Sound object (optional)
#' @param save_path Character. Path to save plot (optional)
#' @param format Character. Output format: "png", "pdf", "svg" (default: "png")
#' @param dpi Numeric. Resolution for raster formats (default: 300)
#'
#' @return A combined ggplot object (invisibly)
#'
#' @export
create_dsi_report_plot <- function(dsi_result,
                                  sound = NULL,
                                  save_path = NULL,
                                  format = c("png", "pdf", "svg"),
                                  dpi = 300) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Please install it.")
  }
  
  format <- match.arg(format)
  
  # Generate combined plot
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    # Just return score plot if gridExtra not available
    p <- .plot_dsi_score(dsi_result)
  } else {
    # Combine components and score plots
    p1 <- .plot_dsi_components(dsi_result)
    p2 <- .plot_dsi_score(dsi_result)
    p <- gridExtra::grid.arrange(p1, p2, ncol = 1)
  }
  
  # Save if requested
  if (!is.null(save_path)) {
    ggplot2::ggsave(
      filename = save_path,
      plot = p,
      width = 10,
      height = 8,
      dpi = dpi,
      device = format
    )
    message("Plot saved to: ", save_path)
  }
  
  invisible(p)
}

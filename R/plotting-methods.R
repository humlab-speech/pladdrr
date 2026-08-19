#' S3 Plot Methods for pladdrr Objects
#'
#' @description
#' Convenient S3 plot methods for Praat objects. These are ggplot2-based
#' wrappers that provide sensible defaults while allowing full customization.
#' All methods return ggplot2 objects that can be further customized.
#'
#' @details
#' These methods follow R's S3 generic dispatch system, allowing you to use
#' the standard `plot()` function with pladdrr objects. Each method converts
#' the Praat object to a data frame and creates an appropriate ggplot2
#' visualization.
#'
#' All plot methods support:
#' - Time range filtering via `from_time` and `to_time` parameters
#' - Axis labels and titles via `garnish` parameter
#' - ggplot2 object return for further customization
#'
#' @return This is a documentation-only overview; see the individual
#'   methods (e.g. \code{\link{plot.Sound}}, \code{\link{plot.Pitch}}) for
#'   their return values.
#'
#' @examples
#' # See individual methods, e.g. ?plot.Sound
#'
#' @name plotting-methods
NULL

#' @title Plot Sound Waveform
#'
#' @description
#' Creates a waveform visualization of a Sound object.
#'
#' @param x Sound object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Sound")
#' @param color Character. Line color (default: "steelblue")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 440, duration = 1.0)
#'
#' # Basic plot
#' plot(sound)
#'
#' # Time range
#' plot(sound, from_time = 0.2, to_time = 0.8)
#'
#' # Customize
#' plot(sound, color = "darkblue", title = "Speech Recording") +
#'   ggplot2::geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5)
#'
#' @export
plot.Sound <- function(x, from_time = NULL, to_time = NULL,
                      garnish = TRUE, title = "Sound", 
                      color = "steelblue", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Sound")) {
    stop("x must be a Sound object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$value)) +
    ggplot2::geom_line(color = color, linewidth = 0.5)

  # Add garnish
  if (garnish) {
    p <- p +
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = "Amplitude"
      ) +
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Pitch Contour
#'
#' @description
#' Creates a pitch (F0) contour visualization of a Pitch object.
#'
#' @param x Pitch object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Pitch")
#' @param color Character. Line color (default: "darkgreen")
#' @param show_voicing Logical. Color by voicing (default: TRUE)
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#' pitch <- sound$to_pitch()
#'
#' # Basic plot
#' plot(pitch)
#'
#' # Time range
#' plot(pitch, from_time = 0.2, to_time = 0.8)
#'
#' # Customize
#' plot(pitch, show_voicing = FALSE, color = "blue") +
#'   ggplot2::geom_hline(yintercept = 120, linetype = "dashed")
#'
#' @export
plot.Pitch <- function(x, from_time = NULL, to_time = NULL,
                      garnish = TRUE, title = "Pitch",
                      color = "darkgreen", show_voicing = TRUE, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Pitch")) {
    stop("x must be a Pitch object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }
  
  # Create plot
  if (show_voicing && "voicing_strength" %in% names(df)) {
    # Color by voicing strength
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency, 
                                          color = .data$voicing_strength)) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::scale_color_gradient(low = "gray70", high = color, 
                                    name = "Voicing")
  } else {
    # Single color
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency)) +
      ggplot2::geom_line(color = color, linewidth = 0.8)
  }
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = "Frequency (Hz)"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Formant Tracks
#'
#' @description
#' Creates a formant trajectory visualization showing F1, F2, F3, etc.
#'
#' @param x Formant object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param max_formant Maximum formant number to display (default: 3)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Formant")
#' @param colors Character vector. Colors for each formant (default: auto)
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' formant <- sound$to_formant_burg()
#'
#' # Basic plot
#' plot(formant)
#'
#' # Show first 5 formants
#' plot(formant, max_formant = 5)
#'
#' # Customize
#' plot(formant, max_formant = 2,
#'      colors = c("red", "blue"))
#'
#' @export
plot.Formant <- function(x, from_time = NULL, to_time = NULL,
                        max_formant = 3, garnish = TRUE, 
                        title = "Formant", colors = NULL, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Formant")) {
    stop("x must be a Formant object")
  }
  
  # Convert to data frame with max_formants parameter. Long format: one row
  # per (frame, formant number), columns time/formant/frequency/bandwidth.
  df <- x$as_data_frame(max_formants = max_formant)

  # Check if data frame is empty
  if (nrow(df) == 0) {
    warning("Formant object has no data to plot")
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = "No formant data available"))
  }

  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }

  # Filter formant number and undefined frequencies
  df <- df[df$formant <= max_formant & !is.na(df$frequency), ]

  # Check if we have formant data
  if (nrow(df) == 0) {
    warning("Formant object has no data to plot")
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = "No formant data available"))
  }

  # Default colors
  if (is.null(colors)) {
    colors <- c("red", "green4", "blue", "purple", "orange")[seq_len(max_formant)]
  }

  # Create formant label
  df$formant_label <- paste0("F", df$formant)

  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency,
                                        color = .data$formant_label)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_color_manual(values = colors, name = "Formant")
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = "Frequency (Hz)"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Intensity Contour
#'
#' @description
#' Creates an intensity (loudness) contour visualization.
#'
#' @param x Intensity object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Intensity")
#' @param color Character. Line color (default: "darkorange")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#' intensity <- sound$to_intensity()
#'
#' # Basic plot
#' plot(intensity)
#'
#' # Time range
#' plot(intensity, from_time = 0.2, to_time = 0.8)
#'
#' @export
plot.Intensity <- function(x, from_time = NULL, to_time = NULL,
                          garnish = TRUE, title = "Intensity",
                          color = "darkorange", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Intensity")) {
    stop("x must be an Intensity object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$intensity_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8)
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = "Intensity (dB)"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Spectrogram Heatmap
#'
#' @description
#' Creates a time-frequency heatmap visualization of a Spectrogram.
#'
#' @param x Spectrogram object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param from_freq Start frequency in Hz (NULL = from 0)
#' @param to_freq End frequency in Hz (NULL = to Nyquist)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Spectrogram")
#' @param dynamic_range Numeric. Dynamic range in dB (default: 70)
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' spectrogram <- sound$to_spectrogram()
#'
#' # Basic plot
#' plot(spectrogram)
#'
#' # Focus on speech range
#' plot(spectrogram, to_freq = 5000)
#'
#' @export
plot.Spectrogram <- function(x, from_time = NULL, to_time = NULL,
                            from_freq = NULL, to_freq = NULL,
                            garnish = TRUE, title = "Spectrogram",
                            dynamic_range = 70, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Spectrogram")) {
    stop("x must be a Spectrogram object")
  }
  
  df <- x$as_data_frame()
  df$power_db <- 10 * log10(pmax(df$power, 1e-20))
  
  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }
  
  # Filter frequency range
  if (!is.null(from_freq)) {
    df <- df[df$frequency >= from_freq, ]
  }
  if (!is.null(to_freq)) {
    df <- df[df$frequency <= to_freq, ]
  }
  
  # Apply dynamic range
  max_power <- max(df$power_db, na.rm = TRUE)
  df$power_db[df$power_db < (max_power - dynamic_range)] <- max_power - dynamic_range
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency, 
                                        fill = .data$power_db)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_gradient(low = "white", high = "black", name = "Power (dB)")
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = "Frequency (Hz)"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Spectrum
#'
#' @description
#' Creates a frequency spectrum visualization.
#'
#' @param x Spectrum object
#' @param from_freq Start frequency in Hz (NULL = from 0)
#' @param to_freq End frequency in Hz (NULL = to Nyquist)
#' @param log_freq Logical. Use logarithmic frequency scale (default: FALSE)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Spectrum")
#' @param color Character. Line color (default: "navy")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' spectrum <- sound$to_spectrum()
#'
#' # Basic plot
#' plot(spectrum)
#'
#' # Logarithmic frequency
#' plot(spectrum, log_freq = TRUE)
#'
#' @export
plot.Spectrum <- function(x, from_freq = NULL, to_freq = NULL,
                         log_freq = FALSE, garnish = TRUE,
                         title = "Spectrum", color = "navy", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Spectrum")) {
    stop("x must be a Spectrum object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter frequency range
  if (!is.null(from_freq)) {
    df <- df[df$frequency >= from_freq, ]
  }
  if (!is.null(to_freq)) {
    df <- df[df$frequency <= to_freq, ]
  }
  
  # Convert power to dB if not already in dB
  if (!"power_db" %in% names(df) && "power" %in% names(df)) {
    df$power_db <- 10 * log10(df$power)
  }
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$frequency, y = .data$power_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8)
  
  # Log frequency scale
  if (log_freq) {
    p <- p + ggplot2::scale_x_log10()
  }
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = if (log_freq) "Frequency (Hz, log scale)" else "Frequency (Hz)",
        y = "Power (dB)"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Long-Term Average Spectrum
#'
#' @description
#' Creates a LTAS (long-term average spectrum) visualization.
#'
#' @param x Ltas object
#' @param from_freq Start frequency in Hz (NULL = from 0)
#' @param to_freq End frequency in Hz (NULL = to maximum)
#' @param log_freq Logical. Use logarithmic frequency scale (default: FALSE)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "LTAS")
#' @param color Character. Line color (default: "darkred")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#' ltas <- sound$to_ltas()
#'
#' # Basic plot
#' plot(ltas)
#'
#' # Speech frequency range
#' plot(ltas, to_freq = 5000)
#'
#' @export
plot.Ltas <- function(x, from_freq = NULL, to_freq = NULL,
                     log_freq = FALSE, garnish = TRUE,
                     title = "LTAS", color = "darkred", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Ltas")) {
    stop("x must be an Ltas object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter frequency range
  if (!is.null(from_freq)) {
    df <- df[df$frequency >= from_freq, ]
  }
  if (!is.null(to_freq)) {
    df <- df[df$frequency <= to_freq, ]
  }
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$frequency, y = .data$power_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8)
  
  # Log frequency scale
  if (log_freq) {
    p <- p + ggplot2::scale_x_log10()
  }
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = if (log_freq) "Frequency (Hz, log scale)" else "Frequency (Hz)",
        y = "Power (dB SPL)"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}

#' @title Plot Harmonicity (HNR) Contour
#'
#' @description
#' Creates a harmonics-to-noise ratio contour visualization.
#'
#' @param x Harmonicity object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Harmonicity")
#' @param color Character. Line color (default: "darkviolet")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#' harmonicity <- sound$to_harmonicity_cc()
#'
#' # Basic plot
#' plot(harmonicity)
#'
#' # Time range
#' plot(harmonicity, from_time = 0.2, to_time = 0.8)
#'
#' @export
plot.Harmonicity <- function(x, from_time = NULL, to_time = NULL,
                            garnish = TRUE, title = "Harmonicity (HNR)",
                            color = "darkviolet", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Harmonicity")) {
    stop("x must be a Harmonicity object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$hnr_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8)
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = "HNR (dB)"
      ) + 
      ggplot2::theme_minimal() +
      ggplot2::geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3)
  }
  
  p
}

#' @title Plot PointProcess Events
#'
#' @description
#' Creates a visualization of PointProcess events (e.g., glottal pulses).
#'
#' @param x PointProcess object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "PointProcess")
#' @param color Character. Line color (default: "black")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#' pulses <- sound$to_pointprocess_periodic_cc()
#'
#' # Basic plot
#' plot(pulses)
#'
#' # Time range
#' plot(pulses, from_time = 0.2, to_time = 0.5)
#'
#' @export
plot.PointProcess <- function(x, from_time = NULL, to_time = NULL,
                             garnish = TRUE, title = "PointProcess",
                             color = "black", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "PointProcess")) {
    stop("x must be a PointProcess object")
  }
  
  # Get time points
  n_points <- x$get_number_of_points()
  
  if (n_points == 0) {
    warning("PointProcess has no points to plot")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  
  times <- numeric(n_points)
  for (i in seq_len(n_points)) {
    times[i] <- x$get_time_from_index(i)
  }
  
  df <- data.frame(time = times, y = 1)
  
  # Filter time range
  if (!is.null(from_time)) {
    df <- df[df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    df <- df[df$time <= to_time, ]
  }
  
  # Create plot - vertical lines at each point
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, xend = .data$time,
                                        y = 0, yend = 1)) +
    ggplot2::geom_segment(color = color, linewidth = 0.5)
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = "Time (s)",
        y = ""
      ) + 
      ggplot2::theme_minimal() +
      ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                    axis.ticks.y = ggplot2::element_blank())
  }
  
  p
}


#' @title Plot Matrix as Heatmap
#'
#' @description
#' Creates a heatmap visualization of a Matrix object. Supports any Matrix-derived
#' objects including generic matrices, spectrograms, etc.
#'
#' @param x Matrix object
#' @param from_x Start value for x-axis (NULL = from beginning)
#' @param to_x End value for x-axis (NULL = to end)
#' @param from_y Start value for y-axis (NULL = from beginning)
#' @param to_y End value for y-axis (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Matrix")
#' @param x_label Character. X-axis label (default: "X")
#' @param y_label Character. Y-axis label (default: "Y")
#' @param color_scale Character. Color scale to use: "viridis", "magma", "plasma", 
#'   "inferno", "cividis", or "greyscale" (default: "viridis")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' m <- matrix_create_simple(3, 4)
#'
#' # Basic heatmap
#' plot(m)
#'
#' # Custom color scale
#' plot(m, color_scale = "magma", title = "My Matrix")
#'
#' @export
plot.Matrix <- function(x, from_x = NULL, to_x = NULL,
                       from_y = NULL, to_y = NULL,
                       garnish = TRUE, title = "Matrix",
                       x_label = "X", y_label = "Y",
                       color_scale = "viridis", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Matrix")) {
    stop("x must be a Matrix object")
  }

  # Convert to long-format data frame (Matrix has no as_data_frame(); build
  # it from the raw matrix plus its axis metadata)
  mat <- x$as_matrix()
  nx <- x$get_number_of_columns()
  ny <- x$get_number_of_rows()
  xs <- x$get_xmin() + (seq_len(nx) - 0.5) * x$get_dx()
  ys <- x$get_ymin() + (seq_len(ny) - 0.5) * x$get_dy()
  df <- data.frame(x = rep(xs, each = ny), y = rep(ys, times = nx), value = as.vector(mat))

  if (nrow(df) == 0) {
    warning("Matrix contains no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  
  # Filter ranges
  if (!is.null(from_x) && "x" %in% names(df)) {
    df <- df[df$x >= from_x, ]
  }
  if (!is.null(to_x) && "x" %in% names(df)) {
    df <- df[df$x <= to_x, ]
  }
  if (!is.null(from_y) && "y" %in% names(df)) {
    df <- df[df$y >= from_y, ]
  }
  if (!is.null(to_y) && "y" %in% names(df)) {
    df <- df[df$y <= to_y, ]
  }
  
  # Determine column names (flexible for different matrix types)
  x_col <- if ("time" %in% names(df)) "time" else if ("x" %in% names(df)) "x" else names(df)[1]
  y_col <- if ("frequency" %in% names(df)) "frequency" else if ("y" %in% names(df)) "y" else names(df)[2]
  val_col <- if ("value" %in% names(df)) "value" else if ("amplitude" %in% names(df)) "amplitude" else names(df)[3]
  
  # Create base plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]], 
                                        fill = .data[[val_col]])) +
    ggplot2::geom_tile()
  
  # Apply color scale
  p <- switch(color_scale,
    "viridis" = p + ggplot2::scale_fill_viridis_c(),
    "magma" = p + ggplot2::scale_fill_viridis_c(option = "magma"),
    "plasma" = p + ggplot2::scale_fill_viridis_c(option = "plasma"),
    "inferno" = p + ggplot2::scale_fill_viridis_c(option = "inferno"),
    "cividis" = p + ggplot2::scale_fill_viridis_c(option = "cividis"),
    "greyscale" = p + ggplot2::scale_fill_gradient(low = "white", high = "black"),
    p + ggplot2::scale_fill_viridis_c()  # default
  )
  
  # Add garnish
  if (garnish) {
    p <- p + 
      ggplot2::labs(
        title = title,
        x = x_label,
        y = y_label,
        fill = "Value"
      ) + 
      ggplot2::theme_minimal()
  }
  
  p
}


#' @title Plot PowerCepstrum
#'
#' @description
#' Creates a visualization of a PowerCepstrum object showing the cepstral
#' coefficients as a function of quefrency. Optionally highlights the peak
#' related to pitch.
#'
#' @param x PowerCepstrum object
#' @param from_quefrency Start quefrency in seconds (NULL = from beginning)
#' @param to_quefrency End quefrency in seconds (NULL = to end)
#' @param garnish Logical. Add axis labels and title (default: TRUE)
#' @param title Character. Plot title (default: "Power Cepstrum")
#' @param color Character. Line color (default: "darkblue")
#' @param mark_peak Logical. Mark the peak prominence if available (default: TRUE)
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' spectrum <- sound$to_spectrum()
#' pc <- spectrum$to_power_cepstrum()
#'
#' # Basic plot
#' plot(pc)
#'
#' # Focus on vocal range (60-500 Hz = 0.002-0.0167 s quefrency)
#' plot(pc, from_quefrency = 0.002, to_quefrency = 0.017)
#'
#' # Customize
#' plot(pc, color = "red", title = "Cepstral Analysis")
#'
#' @export
plot.PowerCepstrum <- function(x, from_quefrency = NULL, to_quefrency = NULL,
                               garnish = TRUE, title = "Power Cepstrum",
                               color = "darkblue", mark_peak = TRUE, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "PowerCepstrum")) {
    stop("x must be a PowerCepstrum object")
  }
  
  # Convert to data frame
  df <- x$as_data_frame()
  
  if (nrow(df) == 0) {
    warning("PowerCepstrum contains no data")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }
  
  # as_data_frame()'s "power_dB" column is raw linear power (misleading name);
  # convert explicitly so the y-axis and peak marker are real dB.
  df$power_db <- 10 * log10(pmax(df$power_dB, 1e-20))
  
  # Filter quefrency range
  if (!is.null(from_quefrency)) {
    df <- df[df$quefrency >= from_quefrency, ]
  }
  if (!is.null(to_quefrency)) {
    df <- df[df$quefrency <= to_quefrency, ]
  }
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$quefrency, y = .data$power_db)) +
    ggplot2::geom_line(color = color, linewidth = 0.8)

  # Optionally mark peak
  if (mark_peak && nrow(df) > 0) {
    # Find peak in visible range
    peak_idx <- which.max(df$power_db)
    if (length(peak_idx) > 0) {
      peak_q <- df$quefrency[peak_idx]
      peak_v <- df$power_db[peak_idx]
      
      p <- p +
        ggplot2::geom_vline(xintercept = peak_q, linetype = "dashed", 
                           color = "red", alpha = 0.5) +
        ggplot2::annotate("text", x = peak_q, y = peak_v,
                         label = sprintf("Peak\n%.4f s\n(%.0f Hz)",
                                       peak_q, 1/peak_q),
                         hjust = -0.1, size = 3, color = "red")
    }
  }

  # Add garnish
  if (garnish) {
    p <- p +
      ggplot2::labs(
        title = title,
        x = "Quefrency (s)",
        y = "Power (dB)"
      ) +
      ggplot2::theme_minimal()
  }

  p
}


#' Plot TextGrid Annotations
#'
#' Visualize tier labels and boundaries as a standalone plot.
#'
#' @param x A TextGrid object
#' @param tier Integer or character specifying which tier to plot (default: all tiers)
#' @param from_time Start time in seconds (NULL = beginning)
#' @param to_time End time in seconds (NULL = end)
#' @param ... Additional arguments (ignored)
#'
#' @return A ggplot2 object
#'
#' @examples
#' tg <- TextGrid$create(0, 1, "words")
#' tg$set_interval_text("words", 1, "hello")
#' plot(tg)
#' plot(tg, tier = 1)
#'
#' @export
plot.TextGrid <- function(x, tier = NULL, from_time = NULL, to_time = NULL, ...) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }

  if (!inherits(x, "TextGrid")) {
    stop("x must be a TextGrid object")
  }

  n_tiers <- x$get_number_of_tiers()
  if (n_tiers == 0) {
    warning("TextGrid has no tiers to plot")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  tier_names <- x$get_tier_names()

  # Determine which tiers to plot
  if (!is.null(tier)) {
    if (is.character(tier)) {
      tier_indices <- match(tier, tier_names)
      tier_indices <- tier_indices[!is.na(tier_indices)]
    } else {
      tier_indices <- as.integer(tier)
    }
  } else {
    tier_indices <- seq_len(n_tiers)
  }

  if (length(tier_indices) == 0) {
    warning("No matching tiers found")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  # Collect interval data across tiers
  all_data <- list()
  for (ti in tier_indices) {
    intervals <- tryCatch(
      x$get_all_intervals(ti),
      error = function(e) NULL
    )
    if (!is.null(intervals) && nrow(intervals) > 0) {
      intervals$tier <- tier_names[ti]
      intervals$tier_y <- match(ti, tier_indices)
      all_data[[length(all_data) + 1]] <- intervals
    }
  }

  if (length(all_data) == 0) {
    warning("No interval data found")
    return(ggplot2::ggplot() + ggplot2::theme_void())
  }

  df <- do.call(rbind, all_data)

  # Filter time range
  if (!is.null(from_time)) df <- df[df$end > from_time, ]
  if (!is.null(to_time)) df <- df[df$start < to_time, ]

  df$mid <- (df$start + df$end) / 2

  p <- ggplot2::ggplot(df) +
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = .data$start, xmax = .data$end,
        ymin = .data$tier_y - 0.4, ymax = .data$tier_y + 0.4
      ),
      fill = "grey90", color = "grey50", linewidth = 0.3
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$mid, y = .data$tier_y, label = .data$text),
      size = 3, na.rm = TRUE
    ) +
    ggplot2::scale_y_continuous(
      breaks = seq_along(tier_indices),
      labels = tier_names[tier_indices]
    ) +
    ggplot2::labs(x = "Time (s)", y = "Tier", title = "TextGrid") +
    ggplot2::theme_minimal()

  p
}


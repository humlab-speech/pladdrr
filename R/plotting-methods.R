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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' 
#' # Basic plot
#' plot(sound)
#' 
#' # Time range
#' plot(sound, from_time = 1.0, to_time = 2.0)
#' 
#' # Customize
#' plot(sound, color = "darkblue", title = "Speech Recording") +
#'   ggplot2::geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5)
#' }
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
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$amplitude)) +
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' pitch <- sound$to_pitch()
#' 
#' # Basic plot
#' plot(pitch)
#' 
#' # Time range
#' plot(pitch, from_time = 0.5, to_time = 2.0)
#' 
#' # Customize
#' plot(pitch, show_voicing = FALSE, color = "blue") +
#'   ggplot2::geom_hline(yintercept = 120, linetype = "dashed")
#' }
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
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency_hz, 
                                          color = .data$voicing_strength)) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::scale_color_gradient(low = "gray70", high = color, 
                                    name = "Voicing")
  } else {
    # Single color
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency_hz)) +
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
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
#' }
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
  
  # Convert to data frame with max_formants parameter
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
  
  # Filter formant number
  df <- df[df$formant_number <= max_formant, ]
  
  # Default colors
  if (is.null(colors)) {
    colors <- c("red", "green4", "blue", "purple", "orange")[1:max_formant]
  }
  
  # Create formant label
  df$formant_label <- paste0("F", df$formant_number)
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$time, y = .data$frequency_hz, 
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' intensity <- sound$to_intensity()
#' 
#' # Basic plot
#' plot(intensity)
#' 
#' # Time range
#' plot(intensity, from_time = 1.0, to_time = 2.0)
#' }
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
#' @param preemphasis Numeric. Pre-emphasis from Hz (default: 50)
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot2 object
#'
#' @examples
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' spectrogram <- sound$to_spectrogram()
#' 
#' # Basic plot
#' plot(spectrogram)
#' 
#' # Focus on speech range
#' plot(spectrogram, to_freq = 5000)
#' }
#'
#' @export
plot.Spectrogram <- function(x, from_time = NULL, to_time = NULL,
                            from_freq = NULL, to_freq = NULL,
                            garnish = TRUE, title = "Spectrogram",
                            dynamic_range = 70, preemphasis = 50, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(x, "Spectrogram")) {
    stop("x must be a Spectrogram object")
  }
  
  # Convert to matrix
  mat <- x$as_matrix()
  
  # Get dimensions
  n_times <- ncol(mat)
  n_freqs <- nrow(mat)
  
  # Get time and frequency ranges from object methods
  t_min <- x$get_start_time()
  t_max <- x$get_end_time()
  f_max <- x$get_highest_frequency()
  
  times <- seq(t_min, t_max, length.out = n_times)
  freqs <- seq(0, f_max, length.out = n_freqs)
  
  # Create long-format data frame
  df <- expand.grid(time = times, frequency = freqs)
  df$power_db <- as.vector(mat)
  
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' spectrum <- sound$to_spectrum()
#' 
#' # Basic plot
#' plot(spectrum)
#' 
#' # Logarithmic frequency
#' plot(spectrum, log_freq = TRUE)
#' }
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' ltas <- sound$to_ltas()
#' 
#' # Basic plot
#' plot(ltas)
#' 
#' # Speech frequency range
#' plot(ltas, to_freq = 5000)
#' }
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' harmonicity <- sound$to_harmonicity_cc()
#' 
#' # Basic plot
#' plot(harmonicity)
#' 
#' # Time range
#' plot(harmonicity, from_time = 1.0, to_time = 2.0)
#' }
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
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' pulses <- sound$to_pointprocess_periodic_cc()
#' 
#' # Basic plot
#' plot(pulses)
#' 
#' # Time range
#' plot(pulses, from_time = 1.0, to_time = 1.5)
#' }
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
  for (i in 1:n_points) {
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

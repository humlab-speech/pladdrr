#' Combined Visualization Functions
#'
#' @description
#' Convenience functions for common multi-object visualizations that combine
#' multiple Praat objects in a single plot. These replicate common Praat
#' plotting patterns using ggplot2 and patchwork/gridExtra.
#'
#' @return This is a documentation-only overview; see the individual
#'   functions (e.g. \code{\link{plot_sound_pitch}},
#'   \code{\link{plot_textgrid_sound}}) for their return values.
#'
#' @examples
#' # See individual functions, e.g. ?plot_sound_pitch
#'
#' @name plotting-combined
NULL

#' @title Plot TextGrid with Sound Waveform
#'
#' @description
#' Creates a combined visualization showing a waveform with TextGrid annotation
#' tiers overlaid. This replicates Praat's TextGrid_Sound_draw() function.
#'
#' @param textgrid TextGrid object
#' @param sound Sound object
#' @param tier Integer or character. Tier number or name to display (default: all)
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param waveform_color Character. Waveform color (default: "steelblue")
#' @param tier_colors Character vector. Colors for each tier (default: auto)
#' @param title Character. Plot title (default: NULL)
#' @param ... Additional arguments passed to plot methods
#'
#' @return A combined ggplot object (requires patchwork or gridExtra)
#'
#' @examples
#' if (requireNamespace("patchwork", quietly = TRUE) ||
#'     requireNamespace("gridExtra", quietly = TRUE)) {
#'   sound <- Sound$create_tone(frequency = 440, duration = 1.0)
#'   textgrid <- TextGrid$create(0, 1, "words")
#'   textgrid$set_interval_text("words", 1, "tone")
#'
#'   # Basic combined plot
#'   plot_textgrid_sound(textgrid, sound)
#'
#'   # Single tier with time range
#'   plot_textgrid_sound(textgrid, sound, tier = 1,
#'                      from_time = 0.2, to_time = 0.8)
#' }
#'
#' @export
plot_textgrid_sound <- function(textgrid, sound, tier = NULL,
                               from_time = NULL, to_time = NULL,
                               waveform_color = "steelblue",
                               tier_colors = NULL,
                               title = NULL, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    warning("Package 'patchwork' recommended for better layout. Installing it is recommended.")
  }
  
  if (!inherits(textgrid, "TextGrid")) {
    stop("textgrid must be a TextGrid object")
  }
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  
  # Determine time range
  if (is.null(from_time)) {
    tg_df <- textgrid$as_data_frame()
    snd_df <- sound$as_data_frame()
    from_time <- max(min(tg_df$start, na.rm = TRUE), min(snd_df$time, na.rm = TRUE))
  }
  if (is.null(to_time)) {
    tg_df <- if (exists("tg_df")) tg_df else textgrid$as_data_frame()
    snd_df <- if (exists("snd_df")) snd_df else sound$as_data_frame()
    to_time <- min(max(tg_df$end, na.rm = TRUE), max(snd_df$time, na.rm = TRUE))
  }
  
  # Plot waveform
  p_wave <- plot(sound, from_time = from_time, to_time = to_time,
                color = waveform_color, garnish = TRUE,
                title = if (!is.null(title)) title else "Sound + TextGrid")
  
  # Get tier information
  n_tiers <- textgrid$get_number_of_tiers()
  
  # Determine which tiers to plot
  if (is.null(tier)) {
    tiers_to_plot <- seq_len(n_tiers)
  } else if (is.numeric(tier)) {
    tiers_to_plot <- tier
  } else {
    # Find tier by name
    tier_names <- vapply(seq_len(n_tiers), textgrid$get_tier_name, character(1))
    tiers_to_plot <- which(tier_names == tier)
    if (length(tiers_to_plot) == 0) {
      stop("Tier '", tier, "' not found in TextGrid")
    }
  }
  
  # Default tier colors
  if (is.null(tier_colors)) {
    tier_colors <- scales::hue_pal()(length(tiers_to_plot))
  }
  
  # Create tier plots
  tier_plots <- list()
  for (i in seq_along(tiers_to_plot)) {
    tier_idx <- tiers_to_plot[i]
    tier_name <- textgrid$get_tier_name(tier_idx)
    tier_type <- if (textgrid$tier_is_interval_tier(tier_idx)) "interval" else "point"
    
    # Create tier visualization data
    if (tier_type == "interval") {
      n_intervals <- textgrid$get_number_of_intervals(tier_idx)
      tier_data <- data.frame(
        start = numeric(n_intervals),
        end = numeric(n_intervals),
        label = character(n_intervals),
        stringsAsFactors = FALSE
      )
      
      for (j in seq_len(n_intervals)) {
        tier_data$start[j] <- textgrid$get_interval_start_time(tier_idx, j)
        tier_data$end[j] <- textgrid$get_interval_end_time(tier_idx, j)
        tier_data$label[j] <- textgrid$get_interval_text(tier_idx, j)
      }
      
      # Filter by time range
      tier_data <- tier_data[tier_data$end >= from_time & tier_data$start <= to_time, ]
      
      # Create tier plot
      p_tier <- ggplot2::ggplot(tier_data) +
        ggplot2::geom_rect(ggplot2::aes(xmin = .data$start, xmax = .data$end,
                                       ymin = 0, ymax = 1),
                          fill = tier_colors[i], alpha = 0.3, color = "black") +
        ggplot2::geom_text(ggplot2::aes(x = (.data$start + .data$end) / 2, y = 0.5,
                                       label = .data$label),
                          size = 3) +
        ggplot2::xlim(from_time, to_time) +
        ggplot2::labs(x = NULL, y = tier_name) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                      axis.ticks.y = ggplot2::element_blank())
      
    } else {
      # Point tier
      n_points <- textgrid$get_number_of_points(tier_idx)
      tier_data <- data.frame(
        time = numeric(n_points),
        label = character(n_points),
        stringsAsFactors = FALSE
      )
      
      for (j in seq_len(n_points)) {
        tier_data$time[j] <- textgrid$get_point_time(tier_idx, j)
        tier_data$label[j] <- textgrid$get_point_text(tier_idx, j)
      }
      
      # Filter by time range
      tier_data <- tier_data[tier_data$time >= from_time & tier_data$time <= to_time, ]
      
      # Create tier plot
      p_tier <- ggplot2::ggplot(tier_data, ggplot2::aes(x = .data$time)) +
        ggplot2::geom_segment(ggplot2::aes(xend = .data$time, y = 0, yend = 1),
                             color = tier_colors[i]) +
        ggplot2::geom_text(ggplot2::aes(y = 1.1, label = .data$label),
                          size = 3, angle = 90, hjust = 0) +
        ggplot2::xlim(from_time, to_time) +
        ggplot2::labs(x = NULL, y = tier_name) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                      axis.ticks.y = ggplot2::element_blank())
    }
    
    tier_plots[[i]] <- p_tier
  }
  
  # Combine plots
  if (requireNamespace("patchwork", quietly = TRUE)) {
    # Use patchwork for better layout
    combined <- p_wave
    for (p in tier_plots) {
      combined <- combined / p
    }
    combined <- combined + patchwork::plot_layout(heights = c(2, rep(1, length(tier_plots))))
  } else {
    # Fallback to gridExtra
    if (!requireNamespace("gridExtra", quietly = TRUE)) {
      stop("Either 'patchwork' or 'gridExtra' is required for combined plots")
    }
    combined <- gridExtra::grid.arrange(p_wave, grobs = tier_plots,
                                       ncol = 1,
                                       heights = c(2, rep(1, length(tier_plots))))
  }
  
  combined
}

#' @title Plot TextGrid with Pitch Contour
#'
#' @description
#' Creates a combined visualization showing a pitch contour with TextGrid
#' annotation tiers. This replicates Praat's TextGrid_Pitch_draw() function.
#'
#' @param textgrid TextGrid object
#' @param pitch Pitch object
#' @param tier Integer or character. Tier number or name to display (default: all)
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param pitch_color Character. Pitch line color (default: "darkgreen")
#' @param tier_colors Character vector. Colors for each tier (default: auto)
#' @param title Character. Plot title (default: NULL)
#' @param ... Additional arguments passed to plot methods
#'
#' @return A combined ggplot object
#'
#' @examples
#' if (requireNamespace("patchwork", quietly = TRUE) ||
#'     requireNamespace("gridExtra", quietly = TRUE)) {
#'   sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#'   pitch <- sound$to_pitch()
#'   textgrid <- TextGrid$create(0, 1, "phonemes")
#'   textgrid$set_interval_text("phonemes", 1, "a")
#'
#'   # Combined pitch + TextGrid
#'   plot_textgrid_pitch(textgrid, pitch)
#'
#'   # Single tier
#'   plot_textgrid_pitch(textgrid, pitch, tier = "phonemes")
#' }
#'
#' @export
plot_textgrid_pitch <- function(textgrid, pitch, tier = NULL,
                               from_time = NULL, to_time = NULL,
                               pitch_color = "darkgreen",
                               tier_colors = NULL,
                               title = NULL, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(textgrid, "TextGrid")) {
    stop("textgrid must be a TextGrid object")
  }
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  
  # Determine time range
  if (is.null(from_time)) {
    tg_df <- textgrid$as_data_frame()
    p_df <- pitch$as_data_frame()
    from_time <- max(min(tg_df$start, na.rm = TRUE), min(p_df$time, na.rm = TRUE))
  }
  if (is.null(to_time)) {
    tg_df <- if (exists("tg_df")) tg_df else textgrid$as_data_frame()
    p_df <- if (exists("p_df")) p_df else pitch$as_data_frame()
    to_time <- min(max(tg_df$end, na.rm = TRUE), max(p_df$time, na.rm = TRUE))
  }
  
  # Plot pitch
  p_pitch <- plot(pitch, from_time = from_time, to_time = to_time,
                 color = pitch_color, garnish = TRUE,
                 title = if (!is.null(title)) title else "Pitch + TextGrid")
  
  # Get tier information (reuse logic from plot_textgrid_sound)
  n_tiers <- textgrid$get_number_of_tiers()
  
  if (is.null(tier)) {
    tiers_to_plot <- seq_len(n_tiers)
  } else if (is.numeric(tier)) {
    tiers_to_plot <- tier
  } else {
    tier_names <- vapply(seq_len(n_tiers), textgrid$get_tier_name, character(1))
    tiers_to_plot <- which(tier_names == tier)
    if (length(tiers_to_plot) == 0) {
      stop("Tier '", tier, "' not found in TextGrid")
    }
  }
  
  if (is.null(tier_colors)) {
    tier_colors <- scales::hue_pal()(length(tiers_to_plot))
  }
  
  # Create tier plots (same as plot_textgrid_sound)
  tier_plots <- list()
  for (i in seq_along(tiers_to_plot)) {
    tier_idx <- tiers_to_plot[i]
    tier_name <- textgrid$get_tier_name(tier_idx)
    tier_type <- if (textgrid$tier_is_interval_tier(tier_idx)) "interval" else "point"
    
    if (tier_type == "interval") {
      n_intervals <- textgrid$get_number_of_intervals(tier_idx)
      tier_data <- data.frame(
        start = numeric(n_intervals),
        end = numeric(n_intervals),
        label = character(n_intervals),
        stringsAsFactors = FALSE
      )
      
      for (j in seq_len(n_intervals)) {
        tier_data$start[j] <- textgrid$get_interval_start_time(tier_idx, j)
        tier_data$end[j] <- textgrid$get_interval_end_time(tier_idx, j)
        tier_data$label[j] <- textgrid$get_interval_text(tier_idx, j)
      }
      
      tier_data <- tier_data[tier_data$end >= from_time & tier_data$start <= to_time, ]
      
      p_tier <- ggplot2::ggplot(tier_data) +
        ggplot2::geom_rect(ggplot2::aes(xmin = .data$start, xmax = .data$end,
                                       ymin = 0, ymax = 1),
                          fill = tier_colors[i], alpha = 0.3, color = "black") +
        ggplot2::geom_text(ggplot2::aes(x = (.data$start + .data$end) / 2, y = 0.5,
                                       label = .data$label),
                          size = 3) +
        ggplot2::xlim(from_time, to_time) +
        ggplot2::labs(x = NULL, y = tier_name) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                      axis.ticks.y = ggplot2::element_blank())
      
    } else {
      n_points <- textgrid$get_number_of_points(tier_idx)
      tier_data <- data.frame(
        time = numeric(n_points),
        label = character(n_points),
        stringsAsFactors = FALSE
      )
      
      for (j in seq_len(n_points)) {
        tier_data$time[j] <- textgrid$get_point_time(tier_idx, j)
        tier_data$label[j] <- textgrid$get_point_text(tier_idx, j)
      }
      
      tier_data <- tier_data[tier_data$time >= from_time & tier_data$time <= to_time, ]
      
      p_tier <- ggplot2::ggplot(tier_data, ggplot2::aes(x = .data$time)) +
        ggplot2::geom_segment(ggplot2::aes(xend = .data$time, y = 0, yend = 1),
                             color = tier_colors[i]) +
        ggplot2::geom_text(ggplot2::aes(y = 1.1, label = .data$label),
                          size = 3, angle = 90, hjust = 0) +
        ggplot2::xlim(from_time, to_time) +
        ggplot2::labs(x = NULL, y = tier_name) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                      axis.ticks.y = ggplot2::element_blank())
    }
    
    tier_plots[[i]] <- p_tier
  }
  
  # Combine plots
  if (requireNamespace("patchwork", quietly = TRUE)) {
    combined <- p_pitch
    for (p in tier_plots) {
      combined <- combined / p
    }
    combined <- combined + patchwork::plot_layout(heights = c(2, rep(1, length(tier_plots))))
  } else {
    if (!requireNamespace("gridExtra", quietly = TRUE)) {
      stop("Either 'patchwork' or 'gridExtra' is required for combined plots")
    }
    combined <- gridExtra::grid.arrange(p_pitch, grobs = tier_plots,
                                       ncol = 1,
                                       heights = c(2, rep(1, length(tier_plots))))
  }
  
  combined
}

#' @title Plot Pitch and Intensity Together
#'
#' @description
#' Creates a dual-axis visualization showing pitch and intensity contours together.
#' This replicates Praat's Pitch_Intensity_draw() function.
#'
#' @param pitch Pitch object
#' @param intensity Intensity object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param pitch_color Character. Pitch line color (default: "darkgreen")
#' @param intensity_color Character. Intensity line color (default: "darkorange")
#' @param title Character. Plot title (default: "Pitch and Intensity")
#' @param ... Additional arguments (currently unused)
#'
#' @return A ggplot object with dual y-axes
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#' pitch <- sound$to_pitch()
#' intensity <- sound$to_intensity()
#'
#' # Combined plot
#' plot_pitch_intensity(pitch, intensity)
#'
#' # Time range
#' plot_pitch_intensity(pitch, intensity,
#'                     from_time = 0.2, to_time = 0.8)
#'
#' @export
plot_pitch_intensity <- function(pitch, intensity,
                                from_time = NULL, to_time = NULL,
                                pitch_color = "darkgreen",
                                intensity_color = "darkorange",
                                title = "Pitch and Intensity", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  if (!inherits(intensity, "Intensity")) {
    stop("intensity must be an Intensity object")
  }
  
  # Determine time range
  if (is.null(from_time)) {
    df_temp <- pitch$as_data_frame()
    from_time <- min(df_temp$time, na.rm = TRUE)
  }
  if (is.null(to_time)) {
    df_temp <- if (exists("df_temp")) df_temp else pitch$as_data_frame()
    to_time <- max(df_temp$time, na.rm = TRUE)
  }
  
  # Get data frames
  pitch_df <- pitch$as_data_frame()
  intensity_df <- intensity$as_data_frame()
  
  # Filter time ranges
  pitch_df <- pitch_df[pitch_df$time >= from_time & pitch_df$time <= to_time, ]
  intensity_df <- intensity_df[intensity_df$time >= from_time & intensity_df$time <= to_time, ]
  
  # Normalize intensity to pitch scale for dual axis
  pitch_range <- range(pitch_df$frequency, na.rm = TRUE)
  intensity_range <- range(intensity_df$intensity_db, na.rm = TRUE)
  
  # Scale factor for intensity to match pitch range
  scale_factor <- diff(pitch_range) / diff(intensity_range)
  offset <- pitch_range[1] - intensity_range[1] * scale_factor
  
  intensity_df$scaled_intensity <- intensity_df$intensity_db * scale_factor + offset
  
  # Create combined plot
  p <- ggplot2::ggplot() +
    ggplot2::geom_line(data = pitch_df,
                      ggplot2::aes(x = .data$time, y = .data$frequency),
                      color = pitch_color, linewidth = 0.8) +
    ggplot2::geom_line(data = intensity_df,
                      ggplot2::aes(x = .data$time, y = .data$scaled_intensity),
                      color = intensity_color, linewidth = 0.8) +
    ggplot2::scale_y_continuous(
      name = "Frequency (Hz)",
      sec.axis = ggplot2::sec_axis(
        trans = ~ (. - offset) / scale_factor,
        name = "Intensity (dB)"
      )
    ) +
    ggplot2::labs(
      title = title,
      x = "Time (s)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.title.y.left = ggplot2::element_text(color = pitch_color),
      axis.text.y.left = ggplot2::element_text(color = pitch_color),
      axis.title.y.right = ggplot2::element_text(color = intensity_color),
      axis.text.y.right = ggplot2::element_text(color = intensity_color)
    )
  
  p
}

#' @title Plot Spectrogram with Formant Overlay
#'
#' @description
#' Creates a spectrogram heatmap with formant trajectories overlaid.
#' This is a common visualization pattern in Praat for vowel analysis.
#'
#' @param spectrogram Spectrogram object
#' @param formant Formant object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param max_formant Maximum formant number to display (default: 3)
#' @param formant_colors Character vector. Colors for formants (default: auto)
#' @param dynamic_range Numeric. Spectrogram dynamic range in dB (default: 70)
#' @param title Character. Plot title (default: "Spectrogram + Formants")
#' @param ... Additional arguments passed to plot.Spectrogram
#'
#' @return A ggplot object with formant tracks overlaid on spectrogram
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' spectrogram <- sound$to_spectrogram()
#' formant <- sound$to_formant_burg()
#'
#' # Combined plot
#' plot_spectrogram_formants(spectrogram, formant)
#'
#' # Show F1-F5
#' plot_spectrogram_formants(spectrogram, formant, max_formant = 5)
#'
#' @export
plot_spectrogram_formants <- function(spectrogram, formant,
                                     from_time = NULL, to_time = NULL,
                                     max_formant = 3,
                                     formant_colors = NULL,
                                     dynamic_range = 70,
                                     title = "Spectrogram + Formants", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(spectrogram, "Spectrogram")) {
    stop("spectrogram must be a Spectrogram object")
  }
  if (!inherits(formant, "Formant")) {
    stop("formant must be a Formant object")
  }
  
  # Determine time range
  if (is.null(from_time)) {
    s_mat <- spectrogram$as_matrix()
    f_df <- formant$as_data_frame()
    from_time <- min(f_df$time, na.rm = TRUE)
  }
  if (is.null(to_time)) {
    s_mat <- if (exists("s_mat")) s_mat else spectrogram$as_matrix()
    f_df <- if (exists("f_df")) f_df else formant$as_data_frame()
    to_time <- max(f_df$time, na.rm = TRUE)
  }
  
  # Create spectrogram base plot
  p <- plot(spectrogram, from_time = from_time, to_time = to_time,
           dynamic_range = dynamic_range, title = title, ...)
  
  # Get formant data. Long format: one row per (frame, formant number),
  # columns time/formant/frequency/bandwidth.
  formant_df <- formant$as_data_frame(max_formants = max_formant)
  formant_df <- formant_df[formant_df$time >= from_time & formant_df$time <= to_time, ]
  formant_df <- formant_df[formant_df$formant <= max_formant & !is.na(formant_df$frequency), ]

  # Check if we have formant data
  if (nrow(formant_df) == 0) {
    warning("No formant data available in the specified time range")
    return(p)
  }

  # Add formant label
  formant_df$formant_label <- paste0("F", formant_df$formant)

  # Default formant colors
  if (is.null(formant_colors)) {
    formant_colors <- c("red", "yellow", "cyan", "magenta", "white")[seq_len(max_formant)]
  }

  # Overlay formant tracks
  p <- p +
    ggplot2::geom_line(data = formant_df,
                      ggplot2::aes(x = .data$time, y = .data$frequency,
                                  color = .data$formant_label),
                      linewidth = 1.2, alpha = 0.8, inherit.aes = FALSE) +
    ggplot2::scale_color_manual(values = formant_colors, name = "Formant")
  
  p
}


#' @title Plot Spectrogram with Pitch Overlay
#'
#' @description
#' Creates a combined visualization showing a spectrogram with pitch contour
#' overlaid. This is one of the most common Praat visualizations for voice analysis.
#'
#' @param spectrogram Spectrogram object
#' @param pitch Pitch object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param freq_max Maximum frequency to display in Hz (default: 5000)
#' @param pitch_color Character. Pitch track color (default: "blue")
#' @param pitch_floor Minimum F0 to display in Hz (default: NULL = auto)
#' @param pitch_ceiling Maximum F0 to display in Hz (default: NULL = auto)
#' @param title Character. Plot title (default: "Spectrogram with Pitch")
#' @param ... Additional arguments passed to plot methods
#'
#' @return A ggplot2 object
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' spectrogram <- sound$to_spectrogram()
#' pitch <- sound$to_pitch()
#'
#' # Basic combined plot
#' plot_spectrogram_pitch(spectrogram, pitch)
#'
#' # Customize pitch range
#' plot_spectrogram_pitch(spectrogram, pitch,
#'                       pitch_floor = 75, pitch_ceiling = 500,
#'                       pitch_color = "red")
#'
#' @export
plot_spectrogram_pitch <- function(spectrogram, pitch,
                                  from_time = NULL, to_time = NULL,
                                  freq_max = 5000,
                                  pitch_color = "blue",
                                  pitch_floor = NULL,
                                  pitch_ceiling = NULL,
                                  title = "Spectrogram with Pitch", ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(spectrogram, "Spectrogram")) {
    stop("spectrogram must be a Spectrogram object")
  }
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  
  # Create base spectrogram plot
  p <- plot(spectrogram, from_time = from_time, to_time = to_time,
           garnish = TRUE, title = title, to_freq = freq_max)
  
  # Get pitch data
  pitch_df <- pitch$as_data_frame()
  
  # Filter time range
  if (!is.null(from_time)) {
    pitch_df <- pitch_df[pitch_df$time >= from_time, ]
  }
  if (!is.null(to_time)) {
    pitch_df <- pitch_df[pitch_df$time <= to_time, ]
  }
  
  # Filter pitch range
  if (!is.null(pitch_floor)) {
    pitch_df <- pitch_df[pitch_df$frequency >= pitch_floor, ]
  }
  if (!is.null(pitch_ceiling)) {
    pitch_df <- pitch_df[pitch_df$frequency <= pitch_ceiling, ]
  }
  
  # Remove unvoiced frames
  pitch_df <- pitch_df[!is.na(pitch_df$frequency) & pitch_df$frequency > 0, ]
  
  if (nrow(pitch_df) == 0) {
    warning("No pitch data available in the specified range")
    return(p)
  }
  
  # Overlay pitch track
  p <- p +
    ggplot2::geom_line(data = pitch_df,
                      ggplot2::aes(x = .data$time, y = .data$frequency),
                      color = pitch_color, linewidth = 1.5, alpha = 0.9,
                      inherit.aes = FALSE) +
    ggplot2::geom_point(data = pitch_df,
                       ggplot2::aes(x = .data$time, y = .data$frequency),
                       color = pitch_color, size = 1, alpha = 0.6,
                       inherit.aes = FALSE)
  
  p
}


#' @title Plot Sound Waveform with Pitch Contour
#'
#' @description
#' Creates a two-panel visualization showing the sound waveform in the top panel
#' and pitch contour in the bottom panel, aligned by time. This is a common
#' Praat visualization pattern.
#'
#' @param sound Sound object
#' @param pitch Pitch object
#' @param from_time Start time in seconds (NULL = from beginning)
#' @param to_time End time in seconds (NULL = to end)
#' @param waveform_color Character. Waveform color (default: "steelblue")
#' @param pitch_color Character. Pitch color (default: "darkblue")
#' @param title Character. Overall plot title (default: NULL)
#' @param ... Additional arguments (currently unused)
#'
#' @return A combined plot object (requires patchwork or gridExtra)
#'
#' @examples
#' if (requireNamespace("patchwork", quietly = TRUE) ||
#'     requireNamespace("gridExtra", quietly = TRUE)) {
#'   sound <- Sound$create_tone(frequency = 220, duration = 1.0)
#'   pitch <- sound$to_pitch()
#'
#'   # Basic two-panel plot
#'   plot_sound_pitch(sound, pitch)
#'
#'   # Time range and custom colors
#'   plot_sound_pitch(sound, pitch,
#'                   from_time = 0.2, to_time = 0.8,
#'                   waveform_color = "black",
#'                   pitch_color = "red")
#' }
#'
#' @export
plot_sound_pitch <- function(sound, pitch,
                            from_time = NULL, to_time = NULL,
                            waveform_color = "steelblue",
                            pitch_color = "darkblue",
                            title = NULL, ...) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Please install it.")
  }
  
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  
  # Create individual plots
  p_sound <- plot(sound, from_time = from_time, to_time = to_time,
                 garnish = TRUE, title = "Waveform",
                 color = waveform_color)
  
  p_pitch <- plot(pitch, from_time = from_time, to_time = to_time,
                 garnish = TRUE, title = "Pitch",
                 color = pitch_color)
  
  # Try patchwork first, then gridExtra
  if (requireNamespace("patchwork", quietly = TRUE)) {
    combined <- p_sound / p_pitch
    if (!is.null(title)) {
      combined <- combined + patchwork::plot_annotation(title = title)
    }
    return(combined)
  } else if (requireNamespace("gridExtra", quietly = TRUE)) {
    if (!is.null(title)) {
      title_grob <- grid::textGrob(title, gp = grid::gpar(fontsize = 14, fontface = "bold"))
      combined <- gridExtra::grid.arrange(
        title_grob,
        p_sound, p_pitch,
        ncol = 1,
        heights = c(0.5, 5, 5)
      )
    } else {
      combined <- gridExtra::grid.arrange(p_sound, p_pitch, ncol = 1)
    }
    return(combined)
  } else {
    stop("Either 'patchwork' or 'gridExtra' package is required for combined plots. Please install one.")
  }
}

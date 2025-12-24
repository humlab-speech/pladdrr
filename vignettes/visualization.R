## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 8,
  fig.height = 6
)

## ----setup--------------------------------------------------------------------
library(pladdrr)
library(ggplot2)

## ----cepstrum-basic, eval=FALSE-----------------------------------------------
# # Create PowerCepstrum object
# sound <- Sound$new("voice.wav")
# cepstrum <- sound$to_power_cepstrum(
#   pitch_floor = 60,
#   time_step = 0.002
# )
# 
# # Plot with peak annotation
# plot_powercepstrum(
#   cepstrum,
#   show_peak = TRUE,
#   show_trendline = TRUE,
#   fit_method = "exponential decay",
#   title = "Power Cepstrum with CPP Peak"
# )

## ----cepstrogram, eval=FALSE--------------------------------------------------
# # Create PowerCepstrogram
# cepstrogram <- sound$to_power_cepstrogram(
#   pitch_floor = 60,
#   time_step = 0.002,
#   max_frequency = 5000,
#   pre_emphasis_from = 50
# )
# 
# # Heatmap visualization
# plot_powercepstrogram(
#   cepstrogram,
#   quefrency_range = c(0.001, 0.05),
#   db_range = c(20, 80),
#   palette = "viridis"
# )

## ----cpp-timeseries, eval=FALSE-----------------------------------------------
# # CPP time series with smoothing
# plot_cpp_timeseries(
#   cepstrogram,
#   smooth = TRUE,
#   trend_line = TRUE,
#   title = "CPP Over Time"
# )

## ----cepstrum-report, eval=FALSE----------------------------------------------
# # Complete cepstral analysis report
# report_plot <- create_cepstrum_report(
#   cepstrogram = cepstrogram,
#   width = 12,
#   height = 10,
#   pitch_floor = 60,
#   pitch_ceiling = 300
# )
# 
# ggsave("cepstrum_report.pdf", report_plot, width = 12, height = 10)

## ----vowel-space, eval=FALSE--------------------------------------------------
# # Extract formants from vowel sounds
# sound <- Sound$new("vowels.wav")
# textgrid <- TextGrid$new("vowels.TextGrid")
# 
# # Get formants at vowel midpoints
# formant_data <- data.frame(
#   vowel = character(),
#   F1 = numeric(),
#   F2 = numeric(),
#   F3 = numeric()
# )
# 
# tier <- textgrid$get_tier(1)
# for (i in 1:tier$get_number_of_intervals()) {
#   label <- tier$get_label(i)
#   if (label %in% c("i", "e", "a", "o", "u")) {
#     t_start <- tier$get_start_time(i)
#     t_end <- tier$get_end_time(i)
#     t_mid <- (t_start + t_end) / 2
# 
#     formant <- sound$to_formant_burg()
#     f1 <- formant$get_value_at_time(1, t_mid, "HERTZ")
#     f2 <- formant$get_value_at_time(2, t_mid, "HERTZ")
#     f3 <- formant$get_value_at_time(3, t_mid, "HERTZ")
# 
#     formant_data <- rbind(formant_data, data.frame(
#       vowel = label,
#       F1 = f1,
#       F2 = f2,
#       F3 = f3
#     ))
#   }
# }
# 
# # Create vowel space plot
# ggplot(formant_data, aes(x = F2, y = F1, color = vowel, label = vowel)) +
#   geom_point(size = 4, alpha = 0.7) +
#   geom_text(vjust = -1, size = 5) +
#   scale_x_reverse() +  # F2 decreases left to right
#   scale_y_reverse() +  # F1 decreases bottom to top
#   labs(
#     title = "Vowel Space (F1-F2)",
#     x = "F2 (Hz)",
#     y = "F1 (Hz)"
#   ) +
#   theme_minimal() +
#   theme(legend.position = "none")

## ----formant-trajectories, eval=FALSE-----------------------------------------
# # Extract formant tracks
# formant <- sound$to_formant_burg(
#   time_step = 0.01,
#   max_number_of_formants = 5,
#   maximum_formant = 5500
# )
# 
# # Convert to data frame
# formant_df <- formant$as_data_frame()
# 
# # Plot F1-F3 over time
# ggplot(formant_df, aes(x = time)) +
#   geom_line(aes(y = F1, color = "F1"), linewidth = 1) +
#   geom_line(aes(y = F2, color = "F2"), linewidth = 1) +
#   geom_line(aes(y = F3, color = "F3"), linewidth = 1) +
#   scale_color_manual(
#     name = "Formant",
#     values = c("F1" = "#E41A1C", "F2" = "#377EB8", "F3" = "#4DAF4A")
#   ) +
#   labs(
#     title = "Formant Trajectories",
#     x = "Time (s)",
#     y = "Frequency (Hz)"
#   ) +
#   theme_minimal()

## ----pitch-contour, eval=FALSE------------------------------------------------
# # Extract pitch
# sound <- Sound$new("speech.wav")
# pitch <- sound$to_pitch()
# 
# # Convert to data frame
# pitch_df <- pitch$as_data_frame()
# 
# # Plot pitch contour
# ggplot(pitch_df, aes(x = time, y = frequency)) +
#   geom_line(color = "#1f77b4", linewidth = 0.8) +
#   geom_point(color = "#1f77b4", size = 1, alpha = 0.5) +
#   labs(
#     title = "Fundamental Frequency (F0) Contour",
#     x = "Time (s)",
#     y = "Frequency (Hz)"
#   ) +
#   theme_minimal()

## ----intensity-contour, eval=FALSE--------------------------------------------
# # Extract intensity
# intensity <- sound$to_intensity()
# 
# # Convert to data frame
# intensity_df <- intensity$as_data_frame()
# 
# # Plot intensity contour
# ggplot(intensity_df, aes(x = time, y = intensity)) +
#   geom_line(color = "#ff7f0e", linewidth = 0.8) +
#   geom_area(fill = "#ff7f0e", alpha = 0.3) +
#   labs(
#     title = "Intensity Contour",
#     x = "Time (s)",
#     y = "Intensity (dB)"
#   ) +
#   theme_minimal()

## ----pitch-intensity-combined, eval=FALSE-------------------------------------
# # Merge data frames
# library(dplyr)
# combined <- pitch_df %>%
#   left_join(intensity_df, by = "time")
# 
# # Dual-axis plot
# ggplot(combined, aes(x = time)) +
#   geom_line(aes(y = frequency, color = "F0"), linewidth = 0.8) +
#   geom_line(aes(y = intensity * 3, color = "Intensity"), linewidth = 0.8) +
#   scale_y_continuous(
#     name = "Frequency (Hz)",
#     sec.axis = sec_axis(~./3, name = "Intensity (dB)")
#   ) +
#   scale_color_manual(
#     name = "",
#     values = c("F0" = "#1f77b4", "Intensity" = "#ff7f0e")
#   ) +
#   labs(
#     title = "Pitch and Intensity",
#     x = "Time (s)"
#   ) +
#   theme_minimal() +
#   theme(legend.position = "top")

## ----textgrid-tiers, eval=FALSE-----------------------------------------------
# # Load TextGrid
# tg <- TextGrid$new("annotations.TextGrid")
# 
# # Extract tier 1 intervals
# tier1 <- tg$get_tier(1)
# n_intervals <- tier1$get_number_of_intervals()
# 
# tier_data <- data.frame(
#   start = numeric(n_intervals),
#   end = numeric(n_intervals),
#   label = character(n_intervals)
# )
# 
# for (i in 1:n_intervals) {
#   tier_data$start[i] <- tier1$get_start_time(i)
#   tier_data$end[i] <- tier1$get_end_time(i)
#   tier_data$label[i] <- tier1$get_label(i)
# }
# 
# # Plot intervals
# ggplot(tier_data, aes(xmin = start, xmax = end, ymin = 0, ymax = 1)) +
#   geom_rect(aes(fill = label), alpha = 0.5, color = "black") +
#   geom_text(aes(x = (start + end) / 2, y = 0.5, label = label), size = 3) +
#   scale_x_continuous(expand = c(0, 0)) +
#   labs(
#     title = "TextGrid Annotations",
#     x = "Time (s)",
#     y = ""
#   ) +
#   theme_minimal() +
#   theme(
#     axis.text.y = element_blank(),
#     axis.ticks.y = element_blank(),
#     legend.position = "none"
#   )

## ----duration-histogram, eval=FALSE-------------------------------------------
# # Calculate interval durations
# tier_data$duration <- tier_data$end - tier_data$start
# 
# # Filter out empty intervals
# tier_data_labeled <- tier_data[tier_data$label != "", ]
# 
# # Duration histogram by label
# ggplot(tier_data_labeled, aes(x = duration, fill = label)) +
#   geom_histogram(bins = 30, alpha = 0.7, color = "black") +
#   facet_wrap(~label, scales = "free_y") +
#   labs(
#     title = "Interval Duration Distribution",
#     x = "Duration (s)",
#     y = "Count"
#   ) +
#   theme_minimal() +
#   theme(legend.position = "none")

## ----spectrogram, eval=FALSE--------------------------------------------------
# # Create spectrogram
# sound <- Sound$new("speech.wav")
# spectrogram <- sound$to_spectrogram(
#   window_length = 0.005,
#   maximum_frequency = 5000,
#   time_step = 0.002,
#   frequency_step = 20,
#   window_shape = "Gaussian"
# )
# 
# # Convert to matrix for plotting
# spec_matrix <- spectrogram$as_matrix()
# time_vec <- seq(0, sound$get_total_duration(), length.out = ncol(spec_matrix))
# freq_vec <- seq(0, 5000, length.out = nrow(spec_matrix))
# 
# # Create data frame for ggplot2
# library(tidyr)
# spec_df <- as.data.frame(spec_matrix)
# colnames(spec_df) <- time_vec
# spec_df$frequency <- freq_vec
# 
# spec_long <- spec_df %>%
#   pivot_longer(-frequency, names_to = "time", values_to = "power") %>%
#   mutate(time = as.numeric(time))
# 
# # Plot spectrogram
# ggplot(spec_long, aes(x = time, y = frequency, fill = power)) +
#   geom_tile() +
#   scale_fill_viridis_c(option = "magma", name = "Power (dB)") +
#   labs(
#     title = "Spectrogram",
#     x = "Time (s)",
#     y = "Frequency (Hz)"
#   ) +
#   theme_minimal()

## ----spectrum, eval=FALSE-----------------------------------------------------
# # Create spectrum from sound
# spectrum <- sound$to_spectrum(fast = TRUE)
# 
# # Convert to data frame
# spectrum_df <- spectrum$as_data_frame()
# 
# # Plot spectrum
# ggplot(spectrum_df, aes(x = frequency, y = power)) +
#   geom_line(color = "#2ca02c", linewidth = 0.8) +
#   labs(
#     title = "Power Spectrum",
#     x = "Frequency (Hz)",
#     y = "Power (dB)"
#   ) +
#   theme_minimal()

## ----ltas, eval=FALSE---------------------------------------------------------
# # Create LTAS
# ltas <- sound$to_ltas(bandwidth = 100)
# 
# # Convert to data frame
# ltas_df <- ltas$as_data_frame()
# 
# # Plot LTAS
# ggplot(ltas_df, aes(x = frequency, y = power)) +
#   geom_line(color = "#d62728", linewidth = 0.8) +
#   geom_area(fill = "#d62728", alpha = 0.3) +
#   labs(
#     title = "Long-Term Average Spectrum",
#     x = "Frequency (Hz)",
#     y = "Power (dB)"
#   ) +
#   theme_minimal()

## ----custom-colors, eval=FALSE------------------------------------------------
# # Define custom color palette
# my_colors <- c(
#   "#E69F00",  # Orange
#   "#56B4E9",  # Sky Blue
#   "#009E73",  # Green
#   "#F0E442",  # Yellow
#   "#0072B2",  # Blue
#   "#D55E00",  # Vermillion
#   "#CC79A7"   # Purple
# )
# 
# # Apply to vowel space plot
# ggplot(formant_data, aes(x = F2, y = F1, color = vowel)) +
#   geom_point(size = 4) +
#   scale_color_manual(values = my_colors) +
#   scale_x_reverse() +
#   scale_y_reverse() +
#   theme_minimal()

## ----pub-theme, eval=FALSE----------------------------------------------------
# # Black and white theme for journals
# ggplot(pitch_df, aes(x = time, y = frequency)) +
#   geom_line() +
#   labs(
#     title = "Fundamental Frequency",
#     x = "Time (s)",
#     y = "F0 (Hz)"
#   ) +
#   theme_bw() +
#   theme(
#     panel.grid.minor = element_blank(),
#     text = element_text(size = 12, family = "serif")
#   )

## ----multipanel, eval=FALSE---------------------------------------------------
# library(gridExtra)
# 
# # Create individual plots
# p1 <- ggplot(pitch_df, aes(x = time, y = frequency)) +
#   geom_line() +
#   labs(title = "Pitch", x = "Time (s)", y = "F0 (Hz)") +
#   theme_minimal()
# 
# p2 <- ggplot(intensity_df, aes(x = time, y = intensity)) +
#   geom_line() +
#   labs(title = "Intensity", x = "Time (s)", y = "dB") +
#   theme_minimal()
# 
# p3 <- ggplot(formant_df, aes(x = time)) +
#   geom_line(aes(y = F1, color = "F1")) +
#   geom_line(aes(y = F2, color = "F2")) +
#   labs(title = "Formants", x = "Time (s)", y = "Hz") +
#   theme_minimal()
# 
# # Arrange in grid
# grid.arrange(p1, p2, p3, nrow = 3)

## ----save-plots, eval=FALSE---------------------------------------------------
# # Save as PDF (vector graphics)
# ggsave("figure1.pdf", plot = p1, width = 8, height = 6, units = "in")
# 
# # Save as PNG (high DPI)
# ggsave("figure1.png", plot = p1, width = 8, height = 6, dpi = 300)
# 
# # Save as SVG (editable vector)
# ggsave("figure1.svg", plot = p1, width = 8, height = 6)
# 
# # Save as TIFF (for journals)
# ggsave("figure1.tiff", plot = p1, width = 8, height = 6, dpi = 300, compression = "lzw")

## ----batch-save, eval=FALSE---------------------------------------------------
# # List of plots
# plots <- list(pitch = p1, intensity = p2, formants = p3)
# 
# # Save all plots
# for (name in names(plots)) {
#   ggsave(
#     filename = paste0("figure_", name, ".pdf"),
#     plot = plots[[name]],
#     width = 8,
#     height = 6
#   )
# }


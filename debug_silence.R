library(pladdrr)

sound <- Sound$new("inst/extdata/test.wav")
cat("Sound loaded:", sound$get_duration(), "s\n")

# Manually try the steps that Sound_to_TextGrid_detectSilences does:
cat("\n1. Filtering sound (80-8000 Hz)...\n")
filtered <- sound$filter_pass_hann_band(80, 8000, 80)
cat("   Filtered sound duration:", filtered$get_duration(), "s\n")

cat("\n2. Computing intensity...\n")
intensity <- filtered$to_intensity(minimum_pitch = 100, time_step = 0.01, subtract_mean = TRUE)
cat("   Intensity frames:", intensity$get_number_of_frames(), "\n")

cat("\n3. Converting intensity to TextGrid (THIS IS WHERE IT CRASHES)...\n")
# This is what Sound_to_TextGrid_detectSilences calls internally
cat("   Calling Intensity$to_textgrid_silences()...\n")
tg <- intensity$to_textgrid_silences(
    silence_threshold = -25,
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1,
    silent_label = "silent",
    sounding_label = "sounding"
)
cat("   TextGrid created!\n")

cat("\nSUCCESS!\n")

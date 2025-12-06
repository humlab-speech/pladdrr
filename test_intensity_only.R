library(pladdrr)

sound <- Sound$new("inst/extdata/test.wav")
cat("Sound duration:", sound$get_duration(), "s\n")

cat("Creating intensity with min_pitch=100, time_step=0.01...\n")
intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.01, subtract_mean = TRUE)
cat("Intensity created! Frames:", intensity$get_number_of_frames(), "\n")

cat("\nSUCCESS!\n")

library(pladdrr)

sound <- Sound$new("inst/extdata/test.wav")
cat("Sound loaded\n")
cat("Duration:", sound$get_duration(), "\n")
cat("Sample rate:", sound$get_sampling_frequency(), "\n")

# Try pitch first
cat("\nTrying to_pitch...\n")
pitch <- sound$to_pitch()
cat("Pitch created\n")

# Try intensity (uses different Praat function)
cat("\nTrying to_intensity...\n")
intensity <- sound$to_intensity()
cat("Intensity created\n")

cat("\nAll basic operations work!\n")

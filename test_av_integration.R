#!/usr/bin/env Rscript
# Test av integration for Sound I/O

library(speaker)

cat("================================================================================\n")
cat("Testing av Integration for Sound I/O\n")
cat("================================================================================\n\n")

# Test 1: Check av package is available
cat("Test 1: Checking av package availability...\n")
if (!requireNamespace("av", quietly = TRUE)) {
  cat("✗ av package not installed\n")
  cat("  Install with: remotes::install_github('humlab-speech/av')\n")
  quit(status = 1)
}
cat("✓ av package available\n\n")

# Test 2: Create synthetic audio
cat("Test 2: Creating synthetic audio (440Hz tone)...\n")
tone <- Sound$create_tone(duration = 1.0, frequency = 440, sampling_rate = 44100)
cat(sprintf("✓ Created tone: %.3f seconds, %d Hz\n", 
            tone$get_duration(), tone$get_sampling_frequency()))
cat(sprintf("  Channels: %d, Samples: %d\n",
            tone$get_number_of_channels(), tone$get_number_of_samples()))
cat("\n")

# Test 3: Save to WAV using av
cat("Test 3: Saving to WAV file using av...\n")
test_wav <- tempfile(fileext = ".wav")
tone$save(test_wav)
if (file.exists(test_wav)) {
  cat(sprintf("✓ Saved to: %s\n", test_wav))
  cat(sprintf("  File size: %.1f KB\n", file.info(test_wav)$size / 1024))
} else {
  cat("✗ Failed to save WAV file\n")
  quit(status = 1)
}
cat("\n")

# Test 4: Load from WAV using av
cat("Test 4: Loading WAV file using av...\n")
sound_loaded <- Sound$new(test_wav)
cat(sprintf("✓ Loaded sound: %.3f seconds, %d Hz\n",
            sound_loaded$get_duration(), sound_loaded$get_sampling_frequency()))
cat(sprintf("  Channels: %d, Samples: %d\n",
            sound_loaded$get_number_of_channels(), sound_loaded$get_number_of_samples()))
cat("\n")

# Test 5: Save to MP3 (if av supports it)
cat("Test 5: Saving to MP3 file using av...\n")
test_mp3 <- tempfile(fileext = ".mp3")
tryCatch({
  tone$save(test_mp3, format = "mp3")
  if (file.exists(test_mp3)) {
    cat(sprintf("✓ Saved to: %s\n", test_mp3))
    cat(sprintf("  File size: %.1f KB\n", file.info(test_mp3)$size / 1024))
  } else {
    cat("⚠ MP3 save completed but file not found\n")
  }
}, error = function(e) {
  cat(sprintf("⚠ MP3 format not supported: %s\n", e$message))
})
cat("\n")

# Test 6: Check if existing test files can be loaded
cat("Test 6: Testing with existing audio files...\n")
test_files <- c(
  "inst/extdata/test.wav",
  "inst/extdata/1min.wav"
)

for (f in test_files) {
  if (file.exists(f)) {
    tryCatch({
      s <- Sound$new(f)
      cat(sprintf("✓ Loaded %s: %.3f s, %d Hz\n", 
                  basename(f), s$get_duration(), s$get_sampling_frequency()))
    }, error = function(e) {
      cat(sprintf("✗ Failed to load %s: %s\n", basename(f), e$message))
    })
  } else {
    cat(sprintf("  %s not found (skipping)\n", basename(f)))
  }
}
cat("\n")

# Cleanup
unlink(test_wav)
if (exists("test_mp3") && file.exists(test_mp3)) unlink(test_mp3)

cat("================================================================================\n")
cat("av Integration Tests Complete\n")
cat("================================================================================\n")
cat("\nAll core tests passed! ✓\n")
cat("The speaker package is now using av for all Sound file I/O operations.\n")

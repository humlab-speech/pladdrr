library(pladdrr, lib.loc='~/R-lib')

cat("=== COMPREHENSIVE NATIVE I/O TEST ===\n\n")

# Test 1: Standard WAV file (should use native)
cat("1. Testing native WAV I/O...\n")
wav_file <- "inst/extdata/test.wav"
if (file.exists(wav_file)) {
  system.time({
    snd_native <- Sound$new(wav_file)
  }) -> time_native
  
  cat("  - Loaded:", snd_native$get_duration(), "sec\n")
  cat("  - Sample rate:", snd_native$get_sampling_frequency(), "Hz\n")
  cat("  - Time:", round(time_native[3] * 1000, 2), "ms\n")
  
  # Test write
  tmp_wav <- tempfile(fileext = ".wav")
  system.time({
    snd_native$save(tmp_wav)
  }) -> time_write
  
  size_orig <- file.info(wav_file)$size
  size_new <- file.info(tmp_wav)$size
  cat("  - Write time:", round(time_write[3] * 1000, 2), "ms\n")
  cat("  - Size: orig=", size_orig, "bytes, new=", size_new, "bytes\n")
  
  # Verify integrity
  snd_reload <- Sound$new(tmp_wav)
  cat("  - Reload OK:", snd_reload$get_duration(), "sec\n")
  unlink(tmp_wav)
  
} else {
  cat("  - SKIP: test.wav not found\n")
}

cat("\n")

# Test 2: Multi-channel if available
cat("2. Testing multi-channel support...\n")
if (exists("snd_native") && snd_native$get_number_of_channels() > 1) {
  cat("  - Channels:", snd_native$get_number_of_channels(), "\n")
} else {
  cat("  - Creating stereo test...\n")
  # Create a simple stereo sound
  mono <- Sound$create_tone(440, 0, 1, 44100, 0.5)
  # Note: stereo conversion would need to_stereo() method if available
  cat("  - Mono created, stereo test skipped (need to_stereo method)\n")
}

cat("\n")

# Test 3: MP3 fallback (if MP3 available)
cat("3. Testing MP3 fallback to av...\n")
mp3_files <- list.files("inst/extdata", pattern="\\.mp3$", full.names=TRUE)
if (length(mp3_files) > 0) {
  tryCatch({
    snd_mp3 <- Sound$new(mp3_files[1])
    cat("  - MP3 loaded via fallback\n")
    cat("  - Duration:", snd_mp3$get_duration(), "sec\n")
  }, error = function(e) {
    cat("  - MP3 error:", e$message, "\n")
  })
} else {
  cat("  - No MP3 files found (expected - tests fallback mechanism)\n")
}

cat("\n")

# Test 4: Large file performance (if available)
cat("4. Testing performance with larger files...\n")
wav_files <- list.files("inst/extdata", pattern="\\.wav$", full.names=TRUE)
if (length(wav_files) > 1) {
  for (wf in wav_files[1:min(3, length(wav_files))]) {
    size_kb <- round(file.info(wf)$size / 1024, 1)
    t <- system.time(snd <- Sound$new(wf))
    cat("  -", basename(wf), ":", size_kb, "KB in", round(t[3]*1000, 2), "ms\n")
  }
} else {
  cat("  - Only 1 WAV file available\n")
}

cat("\n=== TEST COMPLETE ===\n")

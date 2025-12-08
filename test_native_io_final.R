library(pladdrr, lib.loc='~/R-lib')

cat("=== NATIVE I/O VALIDATION ===\n\n")

# Test 1: Native WAV read/write cycle
cat("TEST 1: WAV Read/Write Cycle\n")
wav_file <- "inst/extdata/test.wav"
if (file.exists(wav_file)) {
  # Read
  t_read <- system.time(snd <- Sound$new(wav_file))
  cat("  ✓ Read:", round(t_read[3] * 1000, 2), "ms\n")
  cat("    - Duration:", snd$get_duration(), "sec\n")
  cat("    - Sample rate:", snd$get_sampling_frequency(), "Hz\n")
  cat("    - Channels:", snd$get_number_of_channels(), "\n")
  
  # Write
  tmp <- tempfile(fileext = ".wav")
  t_write <- system.time(snd$save(tmp))
  cat("  ✓ Write:", round(t_write[3] * 1000, 2), "ms\n")
  
  # Verify
  snd2 <- Sound$new(tmp)
  match <- all.equal(snd$get_duration(), snd2$get_duration())
  cat("  ✓ Integrity:", if(isTRUE(match)) "PASS" else "FAIL", "\n")
  
  size_orig <- file.info(wav_file)$size
  size_new <- file.info(tmp)$size
  cat("  - File sizes: ", size_orig, "→", size_new, "bytes\n")
  unlink(tmp)
}

cat("\n")

# Test 2: Performance benchmark
cat("TEST 2: Performance Benchmark\n")
n_iter <- 100
times <- replicate(n_iter, system.time(Sound$new(wav_file))[3])
cat("  ✓ 100 iterations:\n")
cat("    - Mean:", round(mean(times) * 1000, 2), "ms\n")
cat("    - Median:", round(median(times) * 1000, 2), "ms\n")
cat("    - Min:", round(min(times) * 1000, 2), "ms\n")
cat("    - Max:", round(max(times) * 1000, 2), "ms\n")

cat("\n")

# Test 3: Check all available WAV files
cat("TEST 3: Multiple File Formats\n")
wav_files <- list.files("inst/extdata", pattern="\\.wav$", full.names=TRUE)
cat("  Found", length(wav_files), "WAV file(s)\n")
for (wf in wav_files) {
  tryCatch({
    t <- system.time(s <- Sound$new(wf))
    size_kb <- round(file.info(wf)$size / 1024, 1)
    cat("  ✓", basename(wf), "-", size_kb, "KB,", 
        round(s$get_duration(), 2), "sec,", 
        round(t[3]*1000, 2), "ms\n")
  }, error = function(e) {
    cat("  ✗", basename(wf), "- ERROR:", e$message, "\n")
  })
}

cat("\n=== ALL TESTS COMPLETE ===\n")

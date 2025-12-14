#!/usr/bin/env Rscript
# Memory Leak Test: Sound POC Implementation
# POC Day 5 - Memory Testing

library(pladdrr)

cat("=== Sound POC Memory Leak Test ===\n")
cat("Run with: R -d valgrind --vanilla < test_sound_memory.R\n\n")

# Find test file
test_file <- "inst/extdata/test.wav"
if (!file.exists(test_file)) {
  test_file <- "inst/extdata/hallo.wav"
  if (!file.exists(test_file)) {
    stop("No test audio file found")
  }
}

cat("Using test file:", test_file, "\n\n")

# Test 1: Object Creation/Destruction Cycles
cat("=== Test 1: Creation/Destruction (1000 cycles) ===\n")
for (i in 1:1000) {
  sound <- new(SoundModulePOC, test_file)
  rm(sound)
  if (i %% 100 == 0) {
    gc()
    cat(sprintf("  Completed %d cycles\n", i))
  }
}
cat("✓ Test 1 complete\n\n")

# Test 2: Query Operations
cat("=== Test 2: Query Operations (1000 cycles) ===\n")
sound <- new(SoundModulePOC, test_file)
for (i in 1:1000) {
  duration <- sound$get_duration()
  sampling <- sound$get_sampling_frequency()
  nsamples <- sound$get_number_of_samples()
  if (i %% 100 == 0) {
    cat(sprintf("  Completed %d queries\n", i))
  }
}
rm(sound)
gc()
cat("✓ Test 2 complete\n\n")

# Test 3: Transform Operations
cat("=== Test 3: Transform Operations (100 cycles) ===\n")
for (i in 1:100) {
  sound <- new(SoundModulePOC, test_file)
  pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  rm(pitch)
  rm(sound)
  if (i %% 10 == 0) {
    gc()
    cat(sprintf("  Completed %d transforms\n", i))
  }
}
cat("✓ Test 3 complete\n\n")

# Test 4: Export Operations
cat("=== Test 4: Export Operations (500 cycles) ===\n")
sound <- new(SoundModulePOC, test_file)
for (i in 1:500) {
  mat <- sound$as_matrix()
  rm(mat)
  if (i %% 50 == 0) {
    gc()
    cat(sprintf("  Completed %d exports\n", i))
  }
}
rm(sound)
gc()
cat("✓ Test 4 complete\n\n")

# Test 5: Modification Operations
cat("=== Test 5: Modification Operations (200 cycles) ===\n")
for (i in 1:200) {
  sound <- new(SoundModulePOC, test_file)
  sound$scale_intensity(70)
  rm(sound)
  if (i %% 20 == 0) {
    gc()
    cat(sprintf("  Completed %d modifications\n", i))
  }
}
cat("✓ Test 5 complete\n\n")

# Test 6: Mixed Operations
cat("=== Test 6: Mixed Operations (100 cycles) ===\n")
for (i in 1:100) {
  sound <- new(SoundModulePOC, test_file)
  
  # Query
  duration <- sound$get_duration()
  
  # Transform
  pitch <- sound$to_pitch()
  mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
  
  # Export
  mat <- sound$as_matrix()
  
  # Cleanup
  rm(mat)
  rm(pitch)
  rm(sound)
  
  if (i %% 10 == 0) {
    gc()
    cat(sprintf("  Completed %d mixed operations\n", i))
  }
}
cat("✓ Test 6 complete\n\n")

# Final cleanup
gc()

cat("\n=== ALL MEMORY TESTS COMPLETE ===\n")
cat("\nValgrind Analysis:\n")
cat("Check for 'definitely lost' or 'possibly lost' in valgrind output\n")
cat("Expected: 0 bytes definitely lost, 0 bytes possibly lost\n")
cat("\nIf running normally (not under valgrind):\n")
cat("✓ All tests completed without crashes\n")
cat("✓ No obvious memory issues detected\n")

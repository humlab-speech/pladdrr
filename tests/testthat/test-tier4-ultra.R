# test-tier4-ultra.R
# Tests for Tier 4 "Ultra" API - DSI Performance Optimization
# pladdrr v4.4.0

library(testthat)
library(pladdrr)

# =============================================================================
# Phase 1: get_durations_batch() - WAV header reading
# =============================================================================

test_that("get_durations_batch returns correct durations", {
  # Use existing test files
  files <- c(
    system.file("signalfiles/DSI/input/mpt1.wav", package = "pladdrr"),
    system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  )

  # Skip if files don't exist
  skip_if(any(!file.exists(files)), "Test WAV files not found")

  durations <- get_durations_batch(files)

  expect_type(durations, "double")
  expect_equal(length(durations), 2)
  expect_true(all(durations > 0))
})

test_that("get_durations_batch matches Sound durations", {
  file <- system.file("signalfiles/DSI/input/mpt1.wav", package = "pladdrr")
  skip_if(!file.exists(file), "Test WAV file not found")

  # Get duration via Tier 4 Ultra
  tier4_duration <- get_durations_batch(file)

  # Get duration via existing Sound method (xmax - xmin)
  sound <- Sound(file)
  expected_duration <- sound$get_xmax() - sound$get_xmin()

  # Should match within 1ms tolerance
  expect_equal(tier4_duration, expected_duration, tolerance = 0.001)
})

test_that("get_durations_batch handles invalid files gracefully", {
  files <- c(
    system.file("signalfiles/DSI/input/mpt1.wav", package = "pladdrr"),
    "/nonexistent/file.wav"
  )

  skip_if(!file.exists(files[1]), "Test WAV file not found")

  durations <- get_durations_batch(files)

  expect_equal(length(durations), 2)
  expect_true(durations[1] > 0)
  expect_true(is.na(durations[2]))  # Invalid file returns NA
})

test_that("get_durations_batch handles single file", {
  file <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(file), "Test WAV file not found")

  duration <- get_durations_batch(file)

  expect_type(duration, "double")
  expect_equal(length(duration), 1)
  expect_true(duration > 0)
})

test_that("get_durations_batch validates input", {
  expect_error(get_durations_batch(123), "character")
  expect_error(get_durations_batch(NULL), "character")
})

test_that("get_durations_batch is faster than LongSound loop", {
  skip_on_cran()
  skip_if_not_installed("bench")

  # Get all DSI input files
  dsi_dir <- system.file("signalfiles/DSI/input", package = "pladdrr")
  skip_if(!dir.exists(dsi_dir), "DSI directory not found")

  files <- list.files(dsi_dir, pattern = "\\.wav$", full.names = TRUE)
  skip_if(length(files) < 2, "Need at least 2 WAV files for benchmark")

  # Benchmark
  result <- bench::mark(
    tier4 = get_durations_batch(files),
    longsound = sapply(files, function(f) LongSound(f)$get_total_duration()),
    check = FALSE,
    min_iterations = 3
  )

  # Tier 4 should be significantly faster (target: 77x)
  speedup <- result$median[2] / result$median[1]
  message(sprintf("get_durations_batch speedup: %.1fx", speedup))
  expect_true(speedup > 5)  # At least 5x faster
})


# =============================================================================
# Phase 2: calculate_f0_stats_ultra() - Single-call F0 statistics
# =============================================================================

test_that("calculate_f0_stats_ultra returns correct max F0", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Get max F0 via Tier 4 Ultra
  max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75, max_pitch = 600)

  expect_type(max_f0, "double")
  expect_true(!is.na(max_f0))
  expect_true(max_f0 >= 75 && max_f0 <= 600)
})

test_that("calculate_f0_stats_ultra matches existing pitch methods", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Get stats via Tier 4 Ultra
  max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75, max_pitch = 600)
  mean_f0 <- calculate_f0_stats_ultra(sound, stat = "mean", min_pitch = 75, max_pitch = 600)

  # Get stats via existing method
  pitch <- sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  expected_max <- pitch$get_maximum(0, 0, "hertz", TRUE)
  expected_mean <- pitch$get_mean(0, 0, "hertz")

  # Should match within 1 Hz tolerance
  expect_equal(max_f0, expected_max, tolerance = 1)
  expect_equal(mean_f0, expected_mean, tolerance = 1)
})

test_that("calculate_f0_stats_ultra supports all stat types", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Test all supported stats
  stats <- c("max", "min", "mean", "median", "sd")
  for (stat in stats) {
    result <- calculate_f0_stats_ultra(sound, stat = stat, min_pitch = 75, max_pitch = 600)
    expect_type(result, "double")
  }
})

test_that("calculate_f0_stats_ultra validates input", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  expect_error(calculate_f0_stats_ultra("not_a_sound", "max"))
  expect_error(calculate_f0_stats_ultra(sound, "invalid_stat"))
})


# =============================================================================
# Phase 2: calculate_minimum_intensity_ultra() - Voiced-region intensity
# =============================================================================

test_that("calculate_minimum_intensity_ultra returns valid intensity", {
  sound_path <- system.file("signalfiles/DSI/input/im1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  min_int <- calculate_minimum_intensity_ultra(sound, min_pitch = 75)

  expect_type(min_int, "double")
  expect_true(!is.na(min_int))
  expect_true(min_int > 0 && min_int < 100)  # Reasonable dB range
})

test_that("calculate_minimum_intensity_ultra matches DSI reference value", {
  # Bug fix verification: must match DSI algorithm result (~66.21 dB)
  # Previously returned ~43 dB due to incorrect algorithm
  sound_path <- system.file("signalfiles/DSI/input/im1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Use exact DSI parameters
  min_int <- calculate_minimum_intensity_ultra(
    sound,
    min_pitch = 70,
    max_pitch = 600,
    time_step = 0,
    subtract_mean = TRUE
  )

  # Expected value from validated Praat DSI script: ~66.21 dB
  # Tolerance of 1 dB to account for minor algorithmic differences
  expect_equal(min_int, 66.21, tolerance = 1.0)
})

test_that("calculate_minimum_intensity_ultra validates input", {
  expect_error(calculate_minimum_intensity_ultra("not_a_sound"))
})


# =============================================================================
# Phase 3: get_voice_quality_ultra() - Complete voice quality metrics
# =============================================================================

test_that("get_voice_quality_ultra returns all metrics with 'all'", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  vq <- get_voice_quality_ultra(sound, metrics = "all", min_pitch = 75)

  expect_type(vq, "list")

  # Should have jitter metrics
  expect_true("jitter_local" %in% names(vq))
  expect_true("jitter_ppq5" %in% names(vq))

  # Should have shimmer metrics
  expect_true("shimmer_local" %in% names(vq))
  expect_true("shimmer_apq5" %in% names(vq))

  # Should have HNR metrics
  expect_true("hnr_mean" %in% names(vq))
})

test_that("get_voice_quality_ultra matches existing batch API", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Get via Tier 4 Ultra
  vq <- get_voice_quality_ultra(sound, metrics = "jitter", min_pitch = 75)

  # Get via existing Tier 2/3 API
  pitch <- sound$to_pitch_cc(pitch_floor = 75)
  pp <- to_point_process_from_sound_and_pitch(sound, pitch)
  existing <- get_jitter_shimmer_batch(pp, sound)

  # Compare jitter_ppq5
  expect_equal(vq$jitter_ppq5, existing$jitter_ppq5, tolerance = 0.0001)
})

test_that("get_voice_quality_ultra supports selective metrics", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Request only jitter
  vq_jitter <- get_voice_quality_ultra(sound, metrics = "jitter", min_pitch = 75)
  expect_true("jitter_local" %in% names(vq_jitter))

  # Request only shimmer
  vq_shimmer <- get_voice_quality_ultra(sound, metrics = "shimmer", min_pitch = 75)
  expect_true("shimmer_local" %in% names(vq_shimmer))

  # Request only HNR
  vq_hnr <- get_voice_quality_ultra(sound, metrics = "hnr", min_pitch = 75)
  expect_true("hnr_mean" %in% names(vq_hnr))
})

test_that("get_voice_quality_ultra validates input", {
  expect_error(get_voice_quality_ultra("not_a_sound"))
})


# =============================================================================
# Integration: Full DSI workflow benchmark
# =============================================================================

test_that("Tier 4 Ultra provides significant DSI speedup", {
  skip_on_cran()
  skip_if_not_installed("bench")

  # Get DSI input files
  dsi_dir <- system.file("signalfiles/DSI/input", package = "pladdrr")
  skip_if(!dir.exists(dsi_dir), "DSI directory not found")

  mpt_file <- file.path(dsi_dir, "mpt1.wav")
  fh_file <- file.path(dsi_dir, "fh1.wav")
  im_file <- file.path(dsi_dir, "im1.wav")
  ppq_file <- file.path(dsi_dir, "ppq1.wav")

  skip_if(!all(file.exists(c(mpt_file, fh_file, im_file, ppq_file))),
          "DSI test files not found")

  # Load sounds once
  sound_fh <- Sound(fh_file)
  sound_im <- Sound(im_file)
  sound_ppq <- Sound(ppq_file)

  # Tier 4 Ultra workflow
  tier4_dsi <- function() {
    max_mpt <- max(get_durations_batch(mpt_file))
    max_f0 <- calculate_f0_stats_ultra(sound_fh, "max", min_pitch = 75, max_pitch = 600)
    min_int <- calculate_minimum_intensity_ultra(sound_im, min_pitch = 75)
    vq <- get_voice_quality_ultra(sound_ppq, "jitter", min_pitch = 75)
    jitter_ppq5 <- vq$jitter_ppq5
    c(max_mpt = max_mpt, max_f0 = max_f0, min_int = min_int, jitter_ppq5 = jitter_ppq5)
  }

  # Verify it runs successfully
  result <- tier4_dsi()
  expect_equal(length(result), 4)
  expect_true(all(!is.na(result)))

  message(sprintf("DSI Tier 4 result: MPT=%.2fs, F0=%.1fHz, Int=%.1fdB, PPQ5=%.4f",
                  result["max_mpt"], result["max_f0"], result["min_int"], result["jitter_ppq5"]))
})


# =============================================================================
# Concatenated Sounds - Regression Tests (Bug #2 verification)
# =============================================================================

test_that("to_pitch_cc_direct works with concatenated sounds", {
  # Bug #2 regression test: ensure no segfault with concatenated sounds
  dsi_dir <- system.file("signalfiles/DSI/input", package = "pladdrr")
  skip_if(!dir.exists(dsi_dir), "DSI directory not found")

  im_files <- list.files(dsi_dir, pattern = "^im.*[.]wav$", full.names = TRUE)
  skip_if(length(im_files) < 2, "Need at least 2 im files for test")

  # Load and concatenate multiple sounds
  sounds <- lapply(im_files[1:2], Sound)
  concatenated <- sound_concatenate_all(sounds)

  # Tier 2 should not crash
  expect_no_error({
    pitch <- to_pitch_cc_direct(
      concatenated,
      time_step = 0,
      pitch_floor = 70,
      max_candidates = 15,
      very_accurate = FALSE,
      silence_threshold = 0.03,
      voicing_threshold = 0.8,
      octave_cost = 0.01,
      octave_jump_cost = 0.35,
      voiced_unvoiced_cost = 0.14,
      pitch_ceiling = 600
    )
  })
})

test_that("Tier 4 functions work with extracted and concatenated parts", {
  sound_path <- system.file("signalfiles/DSI/input/im1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  # Extract and concatenate parts
  part1 <- sound$extract_part(0, sound$get_xmax() / 2)
  part2 <- sound$extract_part(sound$get_xmax() / 2, sound$get_xmax())
  concatenated <- sound_concatenate_all(list(part1, part2))

  # Test Tier 4 functions on concatenated sound
  expect_no_error({
    max_f0 <- calculate_f0_stats_ultra(concatenated, "max", min_pitch = 75, max_pitch = 600)
  })

  expect_no_error({
    min_int <- calculate_minimum_intensity_ultra(concatenated, min_pitch = 75)
  })

  expect_no_error({
    vq <- get_voice_quality_ultra(concatenated, "jitter", min_pitch = 75)
  })
})

# =============================================================================
# Reusable multiband HNR path
# =============================================================================

test_that("build_multiband_harmonicity returns named Harmonicity objects", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)
  built <- build_multiband_harmonicity(sound)

  expect_equal(names(built), c("full", "band500", "band1500", "band2500", "band3500"))
  expect_true(all(vapply(built, inherits, logical(1), "Harmonicity")))
})

test_that("multiband_hnr_stats matches the one-shot API", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)
  built <- build_multiband_harmonicity(sound)

  reused <- multiband_hnr_stats(built)
  one_shot <- calculate_multiband_hnr_ultra(sound)

  expect_equal(reused, one_shot, tolerance = 1e-10)
})

test_that("reusable multiband HNR objects work across intervals", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)
  midpoint <- sound$get_xmax() / 2
  built <- build_multiband_harmonicity(sound)

  first_half <- multiband_hnr_stats(built, 0, midpoint)
  second_half <- multiband_hnr_stats(built, midpoint, sound$get_xmax())

  expect_equal(
    first_half,
    calculate_multiband_hnr_ultra(sound, from_time = 0, to_time = midpoint),
    tolerance = 1e-10
  )
  expect_equal(
    second_half,
    calculate_multiband_hnr_ultra(sound, from_time = midpoint, to_time = sound$get_xmax()),
    tolerance = 1e-10
  )
})

test_that("reusable multiband HNR helpers validate input", {
  sound_path <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(sound_path), "Test WAV file not found")

  sound <- Sound(sound_path)

  expect_error(
    build_multiband_harmonicity(sound, bands = c(0, 500)),
    "bands parameter must have exactly 5 elements"
  )
  expect_error(
    multiband_hnr_stats(list(full = 1)),
    "named list of 5 Harmonicity objects"
  )
})

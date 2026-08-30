test_wav <- system.file("extdata", "test.wav", package = "pladdrr")

test_that("Sound$to_textgrid_silences() works with all parameters", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  
  # Test with default parameters
  tg <- sound$to_textgrid_silences(
    min_pitch = 100,
    time_step = 0.0,
    silence_threshold = -25,
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1,
    silent_label = "silent",
    sounding_label = "sounding"
  )
  
  expect_s3_class(tg, "TextGrid")
  expect_equal(tg$get_number_of_tiers(), 1)
  
  # Check tier name
  tier_name <- tg$get_tier_name(1)
  expect_identical(tier_name, "silences")
  
  # Check labels exist
  n_intervals <- tg$get_number_of_intervals(1)
  expect_gt(n_intervals, 0)
  
  # Check label values
  labels <- sapply(1:n_intervals, function(i) {
    tg$get_interval_text(1, i)
  })
  expect_true(all(labels %in% c("silent", "sounding")))
})

test_that("Sound$to_textgrid_silences() respects custom labels", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  
  tg <- sound$to_textgrid_silences(
    min_pitch = 100,
    time_step = 0.0,
    silence_threshold = -25,
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1,
    silent_label = "pause",
    sounding_label = "speech"
  )
  
  n_intervals <- tg$get_number_of_intervals(1)
  labels <- sapply(1:n_intervals, function(i) {
    tg$get_interval_text(1, i)
  })
  
  expect_true(all(labels %in% c("pause", "speech")))
  expect_false(any(labels %in% c("silent", "sounding")))
})

test_that("Sound$to_textgrid_silences() threshold affects detection", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  
  # Stricter threshold (more silence detected)
  tg_strict <- sound$to_textgrid_silences(
    min_pitch = 100,
    silence_threshold = -20,  # Higher threshold
    min_silent_duration = 0.05,
    min_sounding_duration = 0.05
  )
  
  # Looser threshold (less silence detected)
  tg_loose <- sound$to_textgrid_silences(
    min_pitch = 100,
    silence_threshold = -35,  # Lower threshold
    min_silent_duration = 0.05,
    min_sounding_duration = 0.05
  )
  
  # Count silent intervals
  count_silent <- function(tg) {
    n <- tg$get_number_of_intervals(1)
    sum(sapply(1:n, function(i) tg$get_interval_text(1, i) == "silent"))
  }
  
  n_silent_strict <- count_silent(tg_strict)
  n_silent_loose <- count_silent(tg_loose)
  
  # Stricter threshold should detect more (or equal) silent intervals
  expect_gte(n_silent_strict, n_silent_loose)
})

test_that("PointProcess$to_textgrid_vuv() creates voiced/unvoiced intervals", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  
  # Get pitch first
  pitch <- sound$to_pitch()
  
  # Convert to point process
  pp <- pitch$to_point_process()
  
  # Create VUV TextGrid
  tg_vuv <- pp$to_textgrid_vuv(
    max_voiced_period = 0.02,
    max_unvoiced_period = 0.01
  )
  
  expect_s3_class(tg_vuv, "TextGrid")
  expect_equal(tg_vuv$get_number_of_tiers(), 1)
  
  # Check tier name
  tier_name <- tg_vuv$get_tier_name(1)
  expect_identical(tier_name, "vuv")
  
  # Check labels are V or U
  n_intervals <- tg_vuv$get_number_of_intervals(1)
  labels <- sapply(1:n_intervals, function(i) {
    tg_vuv$get_interval_text(1, i)
  })
  
  expect_true(all(labels %in% c("V", "U")))
})

test_that("PointProcess$to_textgrid_vuv() parameters affect detection", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  
  # Stricter period threshold
  tg_strict <- pp$to_textgrid_vuv(
    max_voiced_period = 0.015,  # Shorter max period
    max_unvoiced_period = 0.008
  )
  
  # Looser period threshold
  tg_loose <- pp$to_textgrid_vuv(
    max_voiced_period = 0.025,  # Longer max period
    max_unvoiced_period = 0.012
  )
  
  # Both should produce valid TextGrids
  expect_s3_class(tg_strict, "TextGrid")
  expect_s3_class(tg_loose, "TextGrid")
  
  # Count voiced intervals
  count_voiced <- function(tg) {
    n <- tg$get_number_of_intervals(1)
    sum(sapply(1:n, function(i) tg$get_interval_text(1, i) == "V"))
  }
  
  n_voiced_strict <- count_voiced(tg_strict)
  n_voiced_loose <- count_voiced(tg_loose)
  
  # Looser threshold should allow more (or equal) voiced intervals
  expect_gte(n_voiced_loose, n_voiced_strict)
})

test_that("New methods integrate in DSI workflow", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  
  # Step 1: Detect silences
  tg_silences <- sound$to_textgrid_silences(
    min_pitch = 100,
    silence_threshold = -25,
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1
  )
  expect_s3_class(tg_silences, "TextGrid")
  
  # Step 2: Get pitch and point process
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  
  # Step 3: Create VUV intervals
  tg_vuv <- pp$to_textgrid_vuv(max_voiced_period = 0.02, max_unvoiced_period = 0.01)
  expect_s3_class(tg_vuv, "TextGrid")
  
  # All steps completed successfully - DSI workflow possible
  expect_true(TRUE)
})

test_that("New methods integrate in AVQI workflow", {
  skip_if_not(file.exists(test_wav), "Test audio file not found")
  
  sound <- Sound$new(test_wav)
  
  # Step 1: Accurate silence detection (critical for AVQI)
  tg_silences <- sound$to_textgrid_silences(
    min_pitch = 100,
    time_step = 0.0,
    silence_threshold = -25,  # AVQI uses specific threshold
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1,
    silent_label = "silent",
    sounding_label = "sounding"
  )
  
  expect_s3_class(tg_silences, "TextGrid")
  
  # Step 2: Extract sounding intervals only
  # (This would be used for subsequent CPPS analysis)
  n_intervals <- tg_silences$get_number_of_intervals(1)
  sounding_count <- sum(sapply(1:n_intervals, function(i) {
    tg_silences$get_interval_text(1, i) == "sounding"
  }))
  
  # Should detect at least some sounding intervals
  expect_gt(sounding_count, 0)
  
  # AVQI workflow possible
  expect_true(TRUE)
})

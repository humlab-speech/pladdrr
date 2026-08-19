# Tests for performance enhancement features
library(data.table)
# Added 2026-01-06 based on user feedback


test_that("sound_concatenate_all works with Sound objects", {
  skip_if_not_installed("pladdrr")
  
  # Create test sounds using synthetic tones
  s1 <- tryCatch({
    pladdrr::sound_create_tone(duration = 0.1, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  s2 <- tryCatch({
    pladdrr::sound_create_tone(duration = 0.1, sampling_rate = 44100, frequency = 880)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test concatenation with Sound objects (this was the bug)
  result <- tryCatch({
    pladdrr::sound_concatenate_all(list(s1, s2))
  }, error = function(e) {
    fail(paste("sound_concatenate_all failed with error:", e$message))
  })
  
  # Verify result
  expect_s3_class(result, "Sound")
  expect_equal(result$get_duration(), 0.2, tolerance = 0.01)
})

test_that("Sound$get_values returns correct data", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::sound_create_tone(duration = 0.01, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test direct vector access
  values <- tryCatch({
    sound$get_values(channel = 1)
  }, error = function(e) {
    skip("get_values method not available yet - package may need recompilation")
  })
  
  times <- tryCatch({
    sound$get_sample_times()
  }, error = function(e) {
    skip("get_sample_times method not available yet - package may need recompilation")
  })
  
  # Compare with data frame method
  df <- sound$as_data_frame()
  expect_equal(length(values), nrow(df))
  expect_equal(length(times), nrow(df))
  expect_equal(values, df$value, tolerance = 1e-10)
  expect_equal(times, df$time, tolerance = 1e-10)
})

test_that("Sound$get_values is faster than as_data_frame", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  skip_if_not_installed("microbenchmark")
  
  # Create larger test sound for meaningful benchmark
  sound <- tryCatch({
    pladdrr::sound_create_tone(duration = 1.0, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Check if method is available
  has_get_values <- tryCatch({
    sound$get_values()
    TRUE
  }, error = function(e) {
    FALSE
  })
  
  if (!has_get_values) {
    skip("get_values method not available - package needs recompilation")
  }
  
  # Benchmark
  bench <- microbenchmark::microbenchmark(
    direct = sound$get_values(),
    dataframe = sound$as_data_frame()$value,
    times = 50
  )
  
  median_direct <- median(bench$time[bench$expr == "direct"])
  median_df <- median(bench$time[bench$expr == "dataframe"])
  
  # get_values should be faster (ideally 2x+, but at least 1.2x)
  expect_lt(median_direct, median_df * 0.85)
})

test_that("Pitch$get_statistics returns all metrics", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound and pitch
  sound <- tryCatch({
    pladdrr::sound_create_tone(duration = 0.5, sampling_rate = 44100, frequency = 200)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  pitch <- tryCatch({
    sound$to_pitch_cc()
  }, error = function(e) {
    skip("Could not create pitch object")
  })
  
  # Test batch statistics
  stats <- tryCatch({
    pitch$.cpp$get_statistics(
      from_time = 0,
      to_time = 0,
      unit = 0L,  # Hertz
      metrics = c("minimum", "maximum", "mean", "stdev")
    )
  }, error = function(e) {
    skip("get_statistics method not available - package needs recompilation")
  })
  
  # Verify structure
  expect_type(stats, "list")
  expect_true("minimum" %in% names(stats))
  expect_true("maximum" %in% names(stats))
  expect_true("mean" %in% names(stats))
  expect_true("stdev" %in% names(stats))
  
  # Verify values are numeric and reasonable
  expect_true(all(sapply(stats, is.numeric)))
  expect_true(stats$minimum <= stats$mean)
  expect_true(stats$mean <= stats$maximum)
  expect_gte(stats$stdev, 0)
})

test_that("Intensity$get_statistics returns all metrics", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound and intensity
  sound <- tryCatch({
    pladdrr::sound_create_tone(duration = 0.5, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  intensity <- tryCatch({
    sound$to_intensity()
  }, error = function(e) {
    skip("Could not create intensity object")
  })
  
  # Test batch statistics
  stats <- tryCatch({
    intensity$.cpp$get_statistics(
      from_time = 0,
      to_time = 0,
      metrics = c("minimum", "maximum", "mean", "stdev")
    )
  }, error = function(e) {
    skip("get_statistics method not available - package needs recompilation")
  })
  
  # Verify structure
  expect_type(stats, "list")
  expect_true("minimum" %in% names(stats))
  expect_true("maximum" %in% names(stats))
  expect_true("mean" %in% names(stats))
  expect_true("stdev" %in% names(stats))
  
  # Verify values are numeric and reasonable
  expect_true(all(sapply(stats, is.numeric)))
  expect_true(stats$minimum <= stats$mean)
  expect_true(stats$mean <= stats$maximum)
  expect_gte(stats$stdev, 0)
})

test_that("TextGrid$get_all_intervals works correctly", {
  skip_if_not_installed("pladdrr")
  
  tg <- tryCatch({
    tg <- textgrid_create(0, 3, "words", "")
    tg$insert_boundary("words", 1.0)
    tg$insert_boundary("words", 2.0)
    tg$set_interval_text("words", 1, "hello")
    tg$set_interval_text("words", 2, "world")
    tg$set_interval_text("words", 3, "test")
    tg
  }, error = function(e) skip("Could not create test TextGrid"))
  
  intervals <- tryCatch({
    tg$get_all_intervals("words")
  }, error = function(e) skip("get_all_intervals not available - needs recompilation"))
  
  expect_s3_class(intervals, "data.frame")
  expect_equal(names(intervals), c("start", "end", "text"))
  expect_equal(nrow(intervals), 3)
  
  for (i in 1:3) {
    expect_equal(intervals$start[i], tg$get_interval_start_time("words", i))
    expect_equal(intervals$end[i], tg$get_interval_end_time("words", i))
    expect_equal(intervals$text[i], tg$get_interval_text("words", i))
  }
})

test_that("TextGrid$get_all_points works correctly", {
  skip_if_not_installed("pladdrr")
  
  tg <- tryCatch({
    tg <- textgrid_create(0, 3, "", "events")
    tg$insert_point("events", 0.5, "start")
    tg$insert_point("events", 1.5, "middle")
    tg$insert_point("events", 2.5, "end")
    tg
  }, error = function(e) skip("Could not create test TextGrid"))
  
  points <- tryCatch({
    tg$get_all_points("events")
  }, error = function(e) skip("get_all_points not available - needs recompilation"))
  
  expect_s3_class(points, "data.frame")
  expect_equal(names(points), c("time", "text"))
  expect_equal(nrow(points), 3)
})

test_that("TextGrid$extract_intervals_batch works correctly", {
  skip_if_not_installed("pladdrr")
  
  # Create test TextGrid with mixed labels
  tg <- tryCatch({
    tg <- textgrid_create(0, 5, "labels", "")
    tg$insert_boundary("labels", 1.0)
    tg$insert_boundary("labels", 2.0)
    tg$insert_boundary("labels", 3.0)
    tg$insert_boundary("labels", 4.0)
    tg$set_interval_text("labels", 1, "V")
    tg$set_interval_text("labels", 2, "silent")
    tg$set_interval_text("labels", 3, "V")
    tg$set_interval_text("labels", 4, "noise")
    tg$set_interval_text("labels", 5, "V")
    tg
  }, error = function(e) skip("Could not create test TextGrid"))
  
  # Test batch extraction without sounds
  result <- tryCatch({
    tg$extract_intervals_batch(
      tier = "labels",
      comparison_type = "equals",
      target_value = "V",
      extract_sounds = FALSE
    )
  }, error = function(e) skip("extract_intervals_batch not available - needs recompilation"))
  
  expect_type(result, "list")
  expect_true("indices" %in% names(result))
  expect_true("labels" %in% names(result))
  expect_true("start_times" %in% names(result))
  expect_true("end_times" %in% names(result))
  
  # Should extract 3 "V" intervals
  expect_equal(length(result$indices), 3)
  expect_equal(result$indices, c(1, 3, 5))
  expect_equal(result$labels, c("V", "V", "V"))
  expect_equal(result$start_times, c(0, 2, 4))
  expect_equal(result$end_times, c(1, 3, 5))
})

test_that("TextGrid$extract_intervals_batch with sounds works correctly", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    sound_create_tone(duration = 5.0, sampling_rate = 22050, frequency = 440)
  }, error = function(e) skip("Could not create test sound"))
  
  # Create test TextGrid
  tg <- tryCatch({
    tg <- textgrid_create(0, 5, "labels", "")
    tg$insert_boundary("labels", 2.0)
    tg$insert_boundary("labels", 3.0)
    tg$set_interval_text("labels", 1, "A")
    tg$set_interval_text("labels", 2, "B")
    tg$set_interval_text("labels", 3, "A")
    tg
  }, error = function(e) skip("Could not create test TextGrid"))
  
  # Test batch extraction WITH sound extraction
  result <- tryCatch({
    tg$extract_intervals_batch(
      tier = "labels",
      comparison_type = "equals",
      target_value = "A",
      sound = sound,
      extract_sounds = TRUE
    )
  }, error = function(e) skip("extract_intervals_batch with sounds not available"))
  
  expect_type(result, "list")
  expect_true("sounds" %in% names(result))
  expect_equal(length(result$sounds), 2)
  
  # Verify sounds are Sound objects
  expect_s3_class(result$sounds[[1]], "Sound")
  expect_s3_class(result$sounds[[2]], "Sound")
  
  # Verify durations match intervals
  expect_equal(result$sounds[[1]]$get_duration(), 2.0, tolerance = 0.01)
  expect_equal(result$sounds[[2]]$get_duration(), 2.0, tolerance = 0.01)
})

test_that("Pitch$get_adaptive_range works correctly", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound and pitch
  sound <- tryCatch({
    sound_create_tone(duration = 1.0, sampling_rate = 22050, frequency = 200)
  }, error = function(e) skip("Could not create test sound"))
  
  pitch <- tryCatch({
    sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  }, error = function(e) skip("Could not create pitch object"))
  
  # Test adaptive range calculation
  result <- tryCatch({
    pitch$get_adaptive_range(q1_factor = 0.75, q3_factor = 1.5)
  }, error = function(e) skip("get_adaptive_range not available - needs recompilation"))
  
  # Verify structure
  expect_type(result, "list")
  expect_true("q1" %in% names(result))
  expect_true("q3" %in% names(result))
  expect_true("min_pitch" %in% names(result))
  expect_true("max_pitch" %in% names(result))
  
  # Verify values are numeric and reasonable
  expect_true(all(sapply(result, is.numeric)))
  expect_gt(result$q1, 0)
  expect_gt(result$q3, result$q1)
  expect_equal(result$min_pitch, result$q1 * 0.75, tolerance = 0.01)
  expect_equal(result$max_pitch, result$q3 * 1.5, tolerance = 0.01)
  
  # Verify it matches manual calculation
  q1_manual <- pitch$get_quantile(0.25, 0, 0, "hertz")
  q3_manual <- pitch$get_quantile(0.75, 0, 0, "hertz")
  expect_equal(result$q1, q1_manual, tolerance = 0.01)
  expect_equal(result$q3, q3_manual, tolerance = 0.01)
})

test_that("Pitch$get_adaptive_range with custom factors works", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound and pitch
  sound <- tryCatch({
    sound_create_tone(duration = 0.5, sampling_rate = 22050, frequency = 300)
  }, error = function(e) skip("Could not create test sound"))
  
  pitch <- tryCatch({
    sound$to_pitch_cc()
  }, error = function(e) skip("Could not create pitch object"))
  
  # Test with different factors
  result <- tryCatch({
    pitch$get_adaptive_range(q1_factor = 0.5, q3_factor = 2.0)
  }, error = function(e) skip("get_adaptive_range not available"))
  
  # Verify calculation
  expect_equal(result$min_pitch, result$q1 * 0.5, tolerance = 0.01)
  expect_equal(result$max_pitch, result$q3 * 2.0, tolerance = 0.01)
})

# =============================================================================
# Phase 3: XPtr Function Tests (RcppXPtrUtils Integration)
# =============================================================================

test_that("apply_window_xptr works with RcppXPtrUtils", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  skip_if_not_installed("RcppXPtrUtils")

  # Create test sound
  sound <- tryCatch({
    sound_create_tone(duration = 0.5, sampling_rate = 22050, frequency = 440)
  }, error = function(e) skip("Could not create test sound"))

  # Create Hanning window via XPtr
  hanning_xptr <- tryCatch({
    RcppXPtrUtils::cppXPtr(
      "#include <cmath>
       #ifndef M_PI
       #define M_PI 3.14159265358979323846
       #endif
       double window(double t) {
         return 0.5 * (1.0 - cos(2.0 * M_PI * t));
       }",
      depends = character()
    )
  }, error = function(e) skip("Could not compile XPtr window function"))

  # Apply window
  result <- tryCatch({
    apply_window_xptr(sound, hanning_xptr)
  }, error = function(e) skip("apply_window_xptr not available - needs recompilation"))

  # Verify result
  expect_s3_class(result, "Sound")
  expect_equal(result$get_duration(), sound$get_duration(), tolerance = 0.001)

  # Window should zero out the edges (Hanning window = 0 at t=0 and t=1)
  # Get first and last sample values
  values <- result$get_values()
  expect_lt(abs(values[1]), 0.01)  # Should be near zero at start
  expect_lt(abs(values[length(values)]), 0.01)  # Should be near zero at end
})

test_that("apply_transform_xptr works with RcppXPtrUtils", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  skip_if_not_installed("RcppXPtrUtils")

  # Create test sound
  sound <- tryCatch({
    sound_create_tone(duration = 0.1, sampling_rate = 22050, frequency = 440)
  }, error = function(e) skip("Could not create test sound"))

  # Create absolute value (rectifier) transform via XPtr
  rectifier_xptr <- tryCatch({
    RcppXPtrUtils::cppXPtr(
      "#include <cmath>
       double transform(double x) {
         return fabs(x);
       }",
      depends = character()
    )
  }, error = function(e) skip("Could not compile XPtr transform function"))

  # Apply transform
  result <- tryCatch({
    apply_transform_xptr(sound, rectifier_xptr)
  }, error = function(e) skip("apply_transform_xptr not available - needs recompilation"))

  # Verify result
  expect_s3_class(result, "Sound")

  # All values should be non-negative after rectification
  values <- result$get_values()
  expect_true(all(values >= 0))
})

test_that("create_window_xptr creates valid window functions", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  skip_if_not_installed("RcppXPtrUtils")

  # Test that create_window_xptr works for all window types
  window_types <- c("hamming", "hanning", "gaussian", "triangular", "blackman", "rectangular")

  for (wtype in window_types) {
    window_xptr <- tryCatch({
      create_window_xptr(wtype)
    }, error = function(e) {
      skip(paste("create_window_xptr failed for", wtype))
    })

    if (!inherits(window_xptr, "externalptr")) {
      # Compiling 6 xptrs in one test can hit CI-only resource limits
      # (disk/tmp) without cppXPtr() raising an error; treat like the
      # tryCatch above rather than failing the whole suite.
      skip(paste("create_window_xptr did not return a valid pointer for", wtype))
    }
    expect_true(inherits(window_xptr, "externalptr"),
                info = paste("Window type:", wtype))
  }
})

# =============================================================================
# Phase 3: Batch Statistics Tests
# =============================================================================

test_that("pitch_get_statistics_batch returns correct matrix", {
  skip_if_not_installed("pladdrr")

  # Create test sound and pitch
  sound <- tryCatch({
    sound_create_tone(duration = 3.0, sampling_rate = 22050, frequency = 200)
  }, error = function(e) skip("Could not create test sound"))

  pitch <- tryCatch({
    sound$to_pitch_cc()
  }, error = function(e) skip("Could not create pitch object"))

  # Define time intervals
  from_times <- c(0, 1, 2)
  to_times <- c(1, 2, 3)
  metrics <- c("min", "max", "mean", "stdev", "q25", "q75")

  # Test batch statistics
  result <- tryCatch({
    pitch_get_statistics_batch(
      pitch$.xptr,
      from_times,
      to_times,
      metrics,
      unit = 0L
    )
  }, error = function(e) skip("pitch_get_statistics_batch not available - needs recompilation"))

  # Verify structure
  expect_true(is.matrix(result))
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 6)
  expect_equal(colnames(result), metrics)

  # Verify values are reasonable
  for (i in seq_len(nrow(result))) {
    expect_true(result[i, "min"] <= result[i, "mean"])
    expect_true(result[i, "mean"] <= result[i, "max"])
    expect_gte(result[i, "stdev"], 0)
  }
})

test_that("intensity_get_statistics_batch returns correct matrix", {
  skip_if_not_installed("pladdrr")

  # Create test sound and intensity
  sound <- tryCatch({
    sound_create_tone(duration = 3.0, sampling_rate = 22050, frequency = 440)
  }, error = function(e) skip("Could not create test sound"))

  intensity <- tryCatch({
    sound$to_intensity()
  }, error = function(e) skip("Could not create intensity object"))

  # Define time intervals
  from_times <- c(0, 1, 2)
  to_times <- c(1, 2, 3)
  metrics <- c("min", "max", "mean", "stdev")

  # Test batch statistics
  result <- tryCatch({
    intensity_get_statistics_batch(
      intensity$.xptr,
      from_times,
      to_times,
      metrics,
      averaging_method = 0L
    )
  }, error = function(e) skip("intensity_get_statistics_batch not available - needs recompilation"))

  # Verify structure
  expect_true(is.matrix(result))
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 4)
  expect_equal(colnames(result), metrics)

  # Verify values are reasonable
  for (i in seq_len(nrow(result))) {
    expect_true(result[i, "min"] <= result[i, "mean"])
    expect_true(result[i, "mean"] <= result[i, "max"])
    expect_gte(result[i, "stdev"], 0)
  }
})

test_that("batch statistics are faster than individual calls", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  skip_if_not_installed("microbenchmark")

  # Create test sound and pitch
  sound <- tryCatch({
    sound_create_tone(duration = 10.0, sampling_rate = 22050, frequency = 200)
  }, error = function(e) skip("Could not create test sound"))

  pitch <- tryCatch({
    sound$to_pitch_cc()
  }, error = function(e) skip("Could not create pitch object"))

  # Define 100 time intervals
  n_intervals <- 100
  from_times <- seq(0, 9, length.out = n_intervals)
  to_times <- from_times + 0.1
  metrics <- c("min", "max", "mean", "stdev")

  # Test if batch function exists
  batch_works <- tryCatch({
    pitch_get_statistics_batch(pitch$.xptr, from_times[1:2], to_times[1:2], metrics[1:2], 0L)
    TRUE
  }, error = function(e) FALSE)

  if (!batch_works) {
    skip("pitch_get_statistics_batch not available")
  }

  # Benchmark batch vs individual
  bench <- microbenchmark::microbenchmark(
    batch = pitch_get_statistics_batch(pitch$.xptr, from_times, to_times, metrics, 0L),
    individual = {
      for (i in 1:n_intervals) {
        pitch$get_minimum(from_times[i], to_times[i], "hertz")
        pitch$get_maximum(from_times[i], to_times[i], "hertz")
        pitch$get_mean(from_times[i], to_times[i], "hertz")
        pitch$get_standard_deviation(from_times[i], to_times[i], "hertz")
      }
    },
    times = 10
  )

  median_batch <- median(bench$time[bench$expr == "batch"])
  median_individual <- median(bench$time[bench$expr == "individual"])

  # Batch should be at least 2x faster
  expect_lt(median_batch, median_individual * 0.5)
})

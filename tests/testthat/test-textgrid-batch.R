# Tests for TextGrid Batch Operations
# Part of Phase 3 Performance Enhancements (v2.0.7)

test_that("extract_textgrid_intervals extracts correct intervals", {
  # Create test data
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  # Extract voiced intervals without sounds
  result <- extract_textgrid_intervals(
    textgrid = tg,
    tier = 1,
    text_equals = "V",
    extract_sounds = FALSE
  )
  
  # Check structure
  expect_type(result, "list")
  expect_true("indices" %in% names(result))
  expect_true("labels" %in% names(result))
  expect_true("start_times" %in% names(result))
  expect_true("end_times" %in% names(result))
  expect_true("n_total" %in% names(result))
  expect_true("n_matched" %in% names(result))
  
  # Check data types
  expect_type(result$indices, "integer")
  expect_type(result$labels, "character")
  expect_type(result$start_times, "double")
  expect_type(result$end_times, "double")
  
  # All labels should be "V"
  expect_true(all(result$labels == "V"))
  
  # Times should be in order
  expect_true(all(result$start_times < result$end_times))
  
  # Matched should be <= total
  expect_lte(result$n_matched, result$n_total)
})


test_that("extract_textgrid_intervals with sound extraction works", {
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  # Extract voiced intervals WITH sounds
  result <- extract_textgrid_intervals(
    textgrid = tg,
    sound = sound,
    tier = 1,
    text_equals = "V",
    extract_sounds = TRUE
  )
  
  # Should have sounds list
  expect_true("sounds" %in% names(result))
  expect_type(result$sounds, "list")
  expect_equal(length(result$sounds), result$n_matched)
  
  # Each sound should be valid
  for (i in seq_along(result$sounds)) {
    snd <- result$sounds[[i]]
    if (!is.null(snd)) {
      expect_true(inherits(snd, "Sound"))
      expect_true(snd$get_duration() > 0)
    }
  }
})


test_that("extract_textgrid_intervals with text_contains works", {
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  # This should match both "V" and "U" if searching for empty string
  # Or just "V" if searching for "V"
  result <- extract_textgrid_intervals(
    textgrid = tg,
    tier = 1,
    text_contains = "V",
    extract_sounds = FALSE
  )
  
  expect_gt(result$n_matched, 0)
})


test_that("extract_textgrid_intervals validates inputs", {
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  # Invalid textgrid
  expect_error(extract_textgrid_intervals("not a textgrid", tier = 1, text_equals = "V"))
  
  # Invalid tier
  expect_error(extract_textgrid_intervals(tg, tier = 999, text_equals = "V"))
  
  # No comparison criterion
  expect_error(extract_textgrid_intervals(tg, tier = 1))
  
  # Multiple criteria
  expect_error(extract_textgrid_intervals(tg, tier = 1, text_equals = "V", text_contains = "V"))
  
  # extract_sounds = TRUE without sound
  expect_error(extract_textgrid_intervals(tg, tier = 1, text_equals = "V", extract_sounds = TRUE))
})


test_that("get_textgrid_labels_all returns all labels", {
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  labels <- get_textgrid_labels_all(tg, tier = 1)
  
  # Should be character vector
  expect_type(labels, "character")
  
  # Should have same length as number of intervals
  n_intervals <- tg$get_number_of_intervals(1)
  expect_equal(length(labels), n_intervals)
  
  # Labels should match individual queries
  for (i in 1:min(5, n_intervals)) {
    expect_equal(labels[i], tg$get_interval_text(1, i))
  }
})


test_that("get_textgrid_interval_stats returns correct stats", {
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  stats <- get_textgrid_interval_stats(tg, tier = 1)
  
  # Should be data frame
  expect_s3_class(stats, "data.frame")

  # Check columns
  expect_true("index" %in% names(stats))
  expect_true("label" %in% names(stats))
  expect_true("start" %in% names(stats))
  expect_true("end" %in% names(stats))
  expect_true("duration" %in% names(stats))
  
  # Check dimensions
  n_intervals <- tg$get_number_of_intervals(1)
  expect_equal(nrow(stats), n_intervals)
  expect_equal(ncol(stats), 5)
  
  # Durations should match
  expect_equal(stats$duration, stats$end - stats$start, tolerance = 1e-10)
  
  # All durations should be positive
  expect_true(all(stats$duration >= 0))
})


test_that("batch operations are faster than manual loops", {
  skip_if_not_installed("microbenchmark")
  
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  # Manual loop
  manual_extract <- function() {
    n <- tg$get_number_of_intervals(1)
    indices <- integer()
    starts <- numeric()
    ends <- numeric()
    labels <- character()
    
    for (i in 1:n) {
      label <- tg$get_interval_text(1, i)
      if (label == "V") {
        indices <- c(indices, i)
        labels <- c(labels, label)
        starts <- c(starts, tg$get_interval_start_time(1, i))
        ends <- c(ends, tg$get_interval_end_time(1, i))
      }
    }
    
    list(indices = indices, labels = labels, start_times = starts, end_times = ends)
  }
  
  # Batch operation
  batch_extract <- function() {
    extract_textgrid_intervals(tg, tier = 1, text_equals = "V", extract_sounds = FALSE)
  }
  
  library(microbenchmark)
  result <- microbenchmark(
    manual = manual_extract(),
    batch = batch_extract(),
    times = 50
  )
  
  median_manual <- median(result$time[result$expr == "manual"])
  median_batch <- median(result$time[result$expr == "batch"])
  
  speedup <- median_manual / median_batch
  
  # Expect at least 3x speedup (usually 10-50x) - threshold kept well below
  # typical observed range to avoid timing-noise flakiness
  expect_gt(speedup, 3)
  
  message(sprintf("TextGrid batch speedup: %.1fx", speedup))
})


test_that("batch operations return same results as manual", {
  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)
  
  # Manual extraction
  n <- tg$get_number_of_intervals(1)
  manual_labels <- character(n)
  manual_starts <- numeric(n)
  manual_ends <- numeric(n)
  
  for (i in 1:n) {
    manual_labels[i] <- tg$get_interval_text(1, i)
    manual_starts[i] <- tg$get_interval_start_time(1, i)
    manual_ends[i] <- tg$get_interval_end_time(1, i)
  }
  
  # Batch extraction
  batch_stats <- get_textgrid_interval_stats(tg, tier = 1)
  
  # Compare
  expect_equal(batch_stats$label, manual_labels)
  expect_equal(batch_stats$start, manual_starts, tolerance = 1e-10)
  expect_equal(batch_stats$end, manual_ends, tolerance = 1e-10)
})

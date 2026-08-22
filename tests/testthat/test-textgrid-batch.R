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
  skip_on_cran()
  skip_on_ci()

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

# ----------------------------------------------------------------------------
# Coverage gap-fill: textgrid_batch_operations.cpp error/edge paths (task 21)
#
# These call the exported low-level C++ wrappers directly (bypassing the
# validating R-level wrappers in R/textgrid-batch.R) to reach guard branches
# that are otherwise unreachable from the higher-level API. `null_ptr` is the
# same safe null-external-pointer pattern already used elsewhere in this
# suite (see test-extract-voiced-segments-ultra.R, test-performance-helpers.R)
# to exercise "Invalid ... pointer" checks without touching a real object.
# ----------------------------------------------------------------------------

test_that("textgrid_extract_intervals_batch errors on invalid pointers and unknown comparison_type", {
  null_ptr <- methods::new("externalptr")

  expect_error(
    textgrid_extract_intervals_batch(null_ptr, NULL, 1L),
    "Invalid TextGrid pointer"
  )

  sound_file <- system.file("extdata/test.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  pitch <- sound$to_pitch()
  pp <- pitch$to_point_process()
  tg <- pp$to_textgrid_vuv(0.02, 0.01)

  expect_error(
    textgrid_extract_intervals_batch(tg$.xptr, null_ptr, 1L, extract_sounds = TRUE),
    "Invalid Sound pointer"
  )

  expect_error(
    textgrid_extract_intervals_batch(tg$.xptr, NULL, 1L, comparison_type = "bogus"),
    "Unknown comparison_type"
  )
})

test_that("textgrid_get_all_labels errors on an invalid TextGrid pointer", {
  null_ptr <- methods::new("externalptr")
  expect_error(textgrid_get_all_labels(null_ptr, 1L), "Invalid TextGrid pointer")
})

test_that("textgrid_interval_statistics_batch errors on invalid pointer and matches with SIMD disabled", {
  null_ptr <- methods::new("externalptr")
  expect_error(textgrid_interval_statistics_batch(null_ptr, 1L), "Invalid TextGrid pointer")

  tg <- textgrid_create(0, 2.0, tier_names = "segment", point_tiers = "")
  tg$insert_boundary(1, 0.3)
  tg$insert_boundary(1, 0.5)
  tg$insert_boundary(1, 0.8)
  tg$set_interval_text(1, 1, "a")
  tg$set_interval_text(1, 2, "b")
  tg$set_interval_text(1, 3, "c")
  tg$set_interval_text(1, 4, "d")

  simd_was_enabled <- textgrid_simd_enabled()
  set_textgrid_simd_enabled_bridge(FALSE)
  stats <- textgrid_interval_statistics_batch(tg$.xptr, 1L)
  set_textgrid_simd_enabled_bridge(simd_was_enabled)

  expect_equal(stats$duration[1], 0.3, tolerance = 1e-10)
  expect_equal(stats$duration[4], 1.2, tolerance = 1e-10)
})

test_that("get_interval_predicate builds usable built-in predicates and errors on unknown type", {
  expect_error(get_interval_predicate("bogus"), "Unknown predicate type")

  pred_ne <- get_interval_predicate("non_empty")
  expect_true(inherits(pred_ne, "externalptr"))

  pred_min <- get_interval_predicate("min_duration", 0.35)
  pred_max <- get_interval_predicate("max_duration", 0.35)
  expect_true(inherits(pred_min, "externalptr"))
  expect_true(inherits(pred_max, "externalptr"))
})

test_that("textgrid_filter_xptr filters with built-in predicates and errors on bad inputs", {
  tg <- textgrid_create(0, 2.0, tier_names = "segment", point_tiers = "")
  tg$insert_boundary(1, 0.3)
  tg$insert_boundary(1, 0.5)
  tg$insert_boundary(1, 0.8)
  tg$set_interval_text(1, 1, "")
  tg$set_interval_text(1, 2, "b")
  tg$set_interval_text(1, 3, "")
  tg$set_interval_text(1, 4, "d")

  pred_ne <- get_interval_predicate("non_empty")
  result <- textgrid_filter_xptr(tg$.xptr, 1L, pred_ne)
  expect_equal(result$n_matched, 2L)
  expect_equal(result$labels, c("b", "d"))

  pred_min <- get_interval_predicate("min_duration", 1.0)
  result2 <- textgrid_filter_xptr(tg$.xptr, 1L, pred_min)
  expect_equal(result2$n_matched, 1L)  # only interval 4: [0.8, 2.0] = 1.2s

  # With sound extraction
  sound <- Sound$create_tone(frequency = 150, duration = 2, sampling_rate = 16000)
  result3 <- textgrid_filter_xptr(
    tg$.xptr, 1L, pred_ne,
    sound_xptr = sound$.xptr, extract_sounds = TRUE
  )
  expect_true("sounds" %in% names(result3))
  expect_equal(length(result3$sounds), result3$n_matched)

  null_ptr <- methods::new("externalptr")
  expect_error(textgrid_filter_xptr(null_ptr, 1L, pred_ne), "Invalid TextGrid pointer")
  expect_error(textgrid_filter_xptr(tg$.xptr, 1L, 42), "external pointer")
  expect_error(textgrid_filter_xptr(tg$.xptr, 1L, null_ptr), "NULL")
  expect_error(
    textgrid_filter_xptr(tg$.xptr, 1L, pred_ne, sound_xptr = null_ptr, extract_sounds = TRUE),
    "Invalid Sound pointer"
  )
})

# FLAC is decoded natively (vendored libFLAC), without the av fallback.
flac <- system.file("extdata", "test.flac", package = "pladdrr")

test_that("shipped FLAC loads natively and quietly", {
  expect_no_warning(s <- Sound(flac))
  expect_equal(s$get_sampling_frequency(), 44100)
  expect_equal(s$get_total_duration(), 0.15, tolerance = 1e-3)
})

test_that("FLAC save/read round-trips sample-exactly", {
  s <- Sound(flac)
  out <- tempfile(fileext = ".flac")
  on.exit(unlink(out))
  s$save(out, format = "FLAC")
  expect_no_warning(r <- Sound(out))
  expect_identical(r$get_values(1), s$get_values(1))
})

test_that("FLAC works through LongSound and get_durations_batch", {
  ls <- longsound_open(flac)
  expect_equal(ls$get_duration(), 0.15, tolerance = 1e-3)
  expect_equal(get_durations_batch(flac), 0.15, tolerance = 1e-3)
})

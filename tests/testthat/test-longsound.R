# test-longsound.R - Tests for LongSound (streaming large audio files)

.make_wav <- function(frequency = 150, duration = 1.0, sampling_rate = 44100) {
  path <- tempfile(fileext = ".wav")
  Sound$create_tone(frequency = frequency, duration = duration,
                     sampling_rate = sampling_rate)$save(path)
  path
}

.make_stereo_wav <- function(duration = 1.0, sampling_rate = 44100) {
  path <- tempfile(fileext = ".wav")
  mono <- Sound$create_tone(frequency = 150, duration = duration,
                             sampling_rate = sampling_rate)
  mono$save(path)
  path
}

test_that("LongSound$open() opens a file and reports correct properties", {
  path <- .make_wav(frequency = 150, duration = 1.0, sampling_rate = 44100)
  on.exit(unlink(path))

  ls <- LongSound$open(path)

  expect_s3_class(ls, "LongSound")
  expect_true(ls$is_valid())
  expect_equal(ls$get_sample_rate(), 44100)
  expect_equal(ls$get_number_of_channels(), 1)
  expect_equal(ls$get_number_of_samples(), 44100)
  expect_equal(ls$get_start_time(), 0)
  expect_equal(ls$get_end_time(), 1.0, tolerance = 1e-6)
  expect_equal(ls$get_duration(), 1.0, tolerance = 1e-6)
  expect_true(nzchar(ls$get_file_path()))
})

test_that("longsound_open() is equivalent to LongSound$open()", {
  path <- .make_wav()
  on.exit(unlink(path))

  ls <- longsound_open(path)
  expect_s3_class(ls, "LongSound")
  expect_true(ls$is_valid())
})

test_that("longsound_open() errors on a missing file", {
  expect_error(longsound_open(tempfile(fileext = ".wav")), "not found")
})

test_that("print.LongSound() reports file, duration, rate, channels, samples", {
  path <- .make_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  output <- capture.output(print(ls))
  expect_true(any(grepl("LongSound", output)))
  expect_true(any(grepl("Duration", output)))
  expect_true(any(grepl("Sample rate", output)))
  expect_true(any(grepl("Channels", output)))
  expect_true(any(grepl("Samples", output)))
})

test_that("LongSound query methods match an equivalent in-memory Sound", {
  path <- .make_wav(frequency = 220, duration = 0.5, sampling_rate = 44100)
  on.exit(unlink(path))

  ls <- LongSound$open(path)
  snd <- Sound(path = path)

  expect_equal(ls$get_sample_rate(), snd$get_sampling_frequency())
  expect_equal(ls$get_number_of_channels(), snd$get_number_of_channels())
  expect_equal(ls$get_number_of_samples(), snd$get_number_of_samples())
  expect_equal(ls$get_duration(), snd$get_duration(), tolerance = 1e-6)
})

test_that("extract_part() returns a Sound matching the source samples", {
  path <- .make_wav(frequency = 220, duration = 1.0, sampling_rate = 44100)
  on.exit(unlink(path))

  ls <- LongSound$open(path)
  snd <- Sound(path = path)

  part <- ls$extract_part(0.1, 0.3)
  expect_s3_class(part, "Sound")
  expect_equal(part$get_duration(), 0.2, tolerance = 1e-3)

  full_values <- snd$get_values()
  part_values <- part$get_values()
  start_sample <- round(0.1 * 44100) + 1
  expect_equal(part_values,
               full_values[start_sample:(start_sample + length(part_values) - 1)],
               tolerance = 1e-6)
})

test_that("extract_part() preserve_times keeps the original time domain", {
  path <- .make_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  reset_part <- ls$extract_part(0.2, 0.5, preserve_times = FALSE)
  expect_equal(reset_part$get_start_time(), 0, tolerance = 1e-6)

  kept_part <- ls$extract_part(0.2, 0.5, preserve_times = TRUE)
  expect_equal(kept_part$get_start_time(), 0.2, tolerance = 1e-6)
})

test_that("have_window() and get_window_extrema() report sane values", {
  path <- .make_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  expect_type(ls$have_window(0, 0.5), "logical")

  extrema <- ls$get_window_extrema(0, 0.5, channel = 1)
  expect_true(extrema[["maximum"]] >= extrema[["minimum"]])
  expect_true(extrema[["maximum"]] <= 1.0)
  expect_true(extrema[["minimum"]] >= -1.0)
})

test_that("get_dx()/get_x1() match the Sampled convention (dx = 1/rate, x1 = xmin + dx/2)", {
  path <- .make_wav(sampling_rate = 44100)
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  expect_equal(ls$get_dx(), 1 / 44100, tolerance = 1e-12)
  expect_equal(ls$get_x1(), ls$get_start_time() + ls$get_dx() / 2, tolerance = 1e-12)
})

test_that("get_time_from_sample() and get_sample_from_time() round-trip", {
  path <- .make_wav(sampling_rate = 44100)
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  for (sample in c(1L, 100L, 22050L, 44100L)) {
    t <- ls$get_time_from_sample(sample)
    expect_equal(ls$get_sample_from_time(t), sample)
  }
})

test_that("save_part() writes a correctly-sized audio file (regression: nmax=0 buffer overflow)", {
  path <- .make_wav(duration = 1.0, sampling_rate = 44100)
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  out <- tempfile(fileext = ".wav")
  on.exit(unlink(out), add = TRUE)

  ls$save_part(0, 0.5, out)
  expect_true(file.exists(out))

  saved <- Sound(path = out)
  expect_equal(saved$get_duration(), 0.5, tolerance = 1e-3)
})

test_that("save_part() survives repeated calls without crashing (heap-overflow regression)", {
  path <- .make_wav(duration = 1.0, sampling_rate = 44100)
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  for (i in 1:5) {
    out <- tempfile(fileext = ".wav")
    ls$save_part(0, 0.5, out)
    expect_true(file.exists(out))
    expect_gt(file.size(out), 0)
    unlink(out)
  }
})

test_that("save_channel() errors clearly on a mono file", {
  path <- .make_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  out <- tempfile(fileext = ".wav")
  on.exit(unlink(out), add = TRUE)
  expect_error(ls$save_channel(1, out), "stereo")
})

test_that("save_part() rejects an unknown format", {
  path <- .make_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  expect_error(ls$save_part(0, 0.5, tempfile(), format = "mp3"), "Unknown format")
})

test_that("is_valid() is TRUE for a freshly opened LongSound", {
  path <- .make_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)
  expect_true(ls$is_valid())
  expect_true(is.numeric(ls$get_xptr()) || inherits(ls$get_xptr(), "externalptr"))
})

test_that("longsound_get_buffer_size_pref_seconds()/set round-trip and default is sane", {
  original <- longsound_get_buffer_size_pref_seconds()
  on.exit(longsound_set_buffer_size_pref_seconds(original))

  expect_gt(original, 0)  # regression: used to silently read 0

  old <- longsound_set_buffer_size_pref_seconds(120)
  expect_equal(old, original)
  expect_equal(longsound_get_buffer_size_pref_seconds(), 120)
})

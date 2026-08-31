# Extracted from test-longsound.R:28

# prequel ----------------------------------------------------------------------
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

# test -------------------------------------------------------------------------
path <- .make_wav(frequency = 150, duration = 1.0, sampling_rate = 44100)
on.exit(unlink(path))
ls <- LongSound$open(path)
expect_s3_class(ls, "LongSound")
expect_true(ls$is_valid())
expect_equal(ls$get_sample_rate(), 44100, tolerance = sqrt(.Machine$double.eps))
expect_identical(ls$get_number_of_channels(), 1L)
expect_identical(ls$get_number_of_samples(), 44100L)

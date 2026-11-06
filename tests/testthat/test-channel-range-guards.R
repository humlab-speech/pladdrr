# test-channel-range-guards.R
#
# F-memsec-01: a `channel` index larger than the sound's channel count reached
# Praat's raw sample array unchecked (Sound$get_mean() returned arbitrary heap
# doubles, -6.8e+302 for a mono sound; ASan segfaults). Every accessor that
# takes a channel must now reject an out-of-range one instead.
#
# F-api-07: Sound$get_maximum(from, to, channel) / get_minimum(...) documented a
# channel argument and dropped it, so a stereo sound answered with the global
# extremum for every channel.
#
# Expected values are computed from the numeric matrix that built the sound,
# never from the accessor under test.

.make_channels <- function(sampling_rate = 8000, duration = 1.0) {
  n <- as.integer(sampling_rate * duration)
  t <- (0:(n - 1)) / sampling_rate
  # Both tones complete a whole number of cycles per half second, so the
  # extrema below are the same for the whole signal and for 0-0.5 s.
  rbind(
    left = 0.2 * sin(2 * pi * 100 * t),
    right = 0.9 * sin(2 * pi * 250 * t)
  )
}

.stereo <- function(channels, sampling_rate = 8000) {
  list(channels = channels, sound = Sound$from_values(channels, sampling_rate))
}

.mono <- function(channels, sampling_rate = 8000) {
  Sound$from_values(channels[1, , drop = TRUE], sampling_rate)
}

test_that("Sound$get_mean() rejects a channel that does not exist (F-memsec-01)", {
  ch <- .make_channels()
  s <- .mono(ch)
  st <- .stereo(ch)$sound

  expect_equal(s$get_number_of_channels(), 1L)
  # channel 0 is Praat's Vector_CHANNEL_AVERAGE and must stay legal
  expect_equal(s$get_mean(0, 0, 0), s$get_mean(0, 0, 1), tolerance = 0)

  expect_error(s$get_mean(0, 0, 2), "Channel out of range")
  expect_error(s$get_mean(0, 0, 99), "Channel out of range")
  expect_error(s$get_mean(0, 0, -1), "Channel out of range")

  expect_error(st$get_mean(0, 0, 3), "Channel out of range")
  expect_error(st$get_mean(0, 0, -1), "Channel out of range")
})

test_that("Sound$get_mean() answers with the requested channel (F-memsec-01)", {
  ch <- .make_channels()
  st <- .stereo(ch)$sound

  expect_equal(st$get_mean(0, 0, 1), mean(ch[1, ]), tolerance = 1e-12)
  expect_equal(st$get_mean(0, 0, 2), mean(ch[2, ]), tolerance = 1e-12)
  # average over channels
  expect_equal(st$get_mean(0, 0, 0), mean(ch), tolerance = 1e-12)
  expect_equal(st$get_mean(0, 0, 0),
    mean(c(st$get_mean(0, 0, 1), st$get_mean(0, 0, 2))), tolerance = 1e-12)
})

test_that(
  "Sound$get_maximum()/get_minimum() honour channel (F-api-07)", {
  ch <- .make_channels()
  st <- .stereo(ch)$sound

  # interpolation = "none" -> the extremum is a plain sample, so it can be
  # compared exactly with the values that built the sound
  expect_equal(st$get_maximum(0, 0, 1, "none"), max(ch[1, ]), tolerance = 1e-9)
  expect_equal(st$get_maximum(0, 0, 2, "none"), max(ch[2, ]), tolerance = 1e-9)
  expect_equal(st$get_minimum(0, 0, 1, "none"), min(ch[1, ]), tolerance = 1e-9)
  expect_equal(st$get_minimum(0, 0, 2, "none"), min(ch[2, ]), tolerance = 1e-9)

  # channel 0 and the default mean "all channels" = Praat's behaviour
  expect_equal(st$get_maximum(0, 0, 0, "none"), max(ch), tolerance = 1e-9)
  expect_equal(st$get_minimum(0, 0, 0, "none"), min(ch), tolerance = 1e-9)
  expect_equal(st$get_maximum(0, 0, interpolation = "none"), max(ch),
    tolerance = 1e-9)
  expect_equal(st$get_minimum(0, 0, interpolation = "none"), min(ch),
    tolerance = 1e-9)

  expect_error(st$get_maximum(0, 0, 3, "none"), "Channel out of range")
  expect_error(st$get_minimum(0, 0, 3, "none"), "Channel out of range")
})

test_that(
  "single-channel get_maximum()/get_minimum() results are unchanged (F-api-07)", {
  ch <- .make_channels()
  s <- .mono(ch)

  expect_equal(s$get_maximum(0, 0, interpolation = "none"), max(ch[1, ]),
    tolerance = 1e-9)
  expect_equal(s$get_minimum(0, 0, interpolation = "none"), min(ch[1, ]),
    tolerance = 1e-9)
  # channel 0 (all channels) and channel 1 agree on a mono sound
  expect_equal(s$get_maximum(0, 0, 0, "none"), s$get_maximum(0, 0, 1, "none"),
    tolerance = 0)
  expect_equal(s$get_minimum(0, 0, 0, "none"), s$get_minimum(0, 0, 1, "none"),
    tolerance = 0)
})

test_that(
  "PointProcess$get_values_from_sound() guards the channel (F-memsec-01)", {
  ch <- .make_channels()
  st <- .stereo(ch)$sound
  pp <- st$to_point_process_periodic_cc(pitch_floor = 60, pitch_ceiling = 500)

  v1 <- pp$get_values_from_sound(st, channel = 1, interpolation = "nearest")
  v2 <- pp$get_values_from_sound(st, channel = 2, interpolation = "nearest")

  # channel 1 never exceeds channel 1's own amplitude range (pre-fix: heap
  # garbage of order 1e+300), and channel 2 must exceed channel 1's maximum,
  # which proves it read channel 2's samples rather than the whole sound
  expect_lte(max(abs(v1)), max(abs(ch[1, ])) + 1e-9)
  expect_gt(max(abs(v2)), max(abs(ch[1, ])))
  expect_lte(max(abs(v2)), max(abs(ch[2, ])) + 1e-9)
  # channel 0 = average over channels
  expect_equal(pp$get_values_from_sound(st, channel = 0, interpolation = "nearest"),
    (v1 + v2) / 2, tolerance = 1e-12)

  expect_error(pp$get_values_from_sound(st, channel = 3), "Channel out of range")
  expect_error(pp$get_values_from_sound(st, channel = -1), "Channel out of range")
})

test_that(
  "LPC filter-inverse-at-time guards the channel (F-memsec-01)", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  expect_error(lpc$filter_inverse_at_time(sound, time = 0.1, channel = 3),
    "Channel out of range")
  expect_error(
    lpc$.cpp$filter_inverse_at_time_ptr(sound$get_xptr(), 3L, 0.1),
    "Channel out of range")
  expect_error(
    pladdrr:::.lpc_sound_filter_inverse_at_time(
      lpc$get_xptr(), sound$get_xptr(), 3L, 0.1),
    "Channel out of range")

  # in-range still works: 1 = that channel, 0 = every channel
  expect_type(lpc$.cpp$filter_inverse_at_time_ptr(sound$get_xptr(), 1L, 0.1),
    "externalptr")
  expect_type(pladdrr:::.lpc_sound_filter_inverse_at_time(
    lpc$get_xptr(), sound$get_xptr(), 0L, 0.1), "externalptr")
})

.make_stereo_wav <- function(duration = 1.0, sampling_rate = 8000) {
  path <- tempfile(fileext = ".wav")
  .stereo(.make_channels(sampling_rate, duration), sampling_rate)$sound$save(path)
  path
}

test_that("LongSound$get_window_extrema() guards the channel (F-memsec-01)", {
  ch <- .make_channels()
  path <- .make_stereo_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)
  expect_equal(ls$get_number_of_channels(), 2L)

  # the on-disk window extrema are the 16-bit version of the channel's own
  # samples (quantisation step 1/32768)
  e1 <- ls$get_window_extrema(0, 0.5, channel = 1)
  e2 <- ls$get_window_extrema(0, 0.5, channel = 2)
  expect_equal(e1[["minimum"]], min(ch[1, 1:4000]), tolerance = 1e-3)
  expect_equal(e1[["maximum"]], max(ch[1, 1:4000]), tolerance = 1e-3)
  expect_equal(e2[["minimum"]], min(ch[2, 1:4000]), tolerance = 1e-3)
  expect_equal(e2[["maximum"]], max(ch[2, 1:4000]), tolerance = 1e-3)

  expect_error(ls$get_window_extrema(0, 0.5, channel = 3), "Channel out of range")
  expect_error(ls$get_window_extrema(0, 0.5, channel = 0), "Channel out of range")
  expect_error(ls$get_window_extrema(0, 0.5, channel = -1), "Channel out of range")
})

test_that("LongSound$save_channel() guards the channel (F-memsec-01)", {
  path <- .make_stereo_wav()
  on.exit(unlink(path))
  ls <- LongSound$open(path)

  out <- tempfile(fileext = ".wav")
  on.exit(unlink(out), add = TRUE)
  # Praat's convention here: 0 = left, 1 = right
  expect_error(ls$save_channel(0, out), NA)
  expect_true(file.exists(out))
  expect_error(ls$save_channel(1, out), NA)

  expect_error(ls$save_channel(2, out), "Channel out of range")
  expect_error(ls$save_channel(-1, out), "Channel out of range")
})

test_that(
  "Sound$extract_electroglottogram() guards the channel (F-memsec-01)", {
  ch <- .make_channels()
  s <- .mono(ch)
  st <- .stereo(ch)$sound

  expect_s3_class(s$extract_electroglottogram(channel = 1), "Electroglottogram")
  expect_s3_class(st$extract_electroglottogram(channel = 2), "Electroglottogram")
  expect_error(s$extract_electroglottogram(channel = 2), "Channel out of range")
  expect_error(s$extract_electroglottogram(channel = 0), "Channel out of range")

  # the module entry point (used by test-phase4-modules.R) is guarded too
  egg_mod <- Rcpp::Module("electroglottogram_module", PACKAGE = "pladdrr")
  expect_error(egg_mod$Sound_extract_Electroglottogram(s$get_xptr(), 99L, FALSE),
    "Channel out of range")
})

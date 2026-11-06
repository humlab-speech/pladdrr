# Regression tests for the av fallback in .sound_ptr_from_path() (F-deps-01,
# merged with F-security-03). Formats whose native reader is stubbed (FLAC,
# MP3, OGG/Opus/MP4) are decoded with av::read_audio_bin(), which returns a
# plain *interleaved* integer vector in raw S32LE (full scale 2^31) — not a
# channels x samples matrix in +-1. Before the fix the fallback divided by the
# file's own peak and folded stereo into a double-length mono track, so the
# same tone read +6.02 dB too hot from .flac and a 2 x N stereo file became
# 1 x 2N. The fallback must return the file's own amplitudes and channel
# layout, and must say so once per load.

skip_if_not_installed("av")

av_sr <- 8000L
av_n <- av_sr # exactly one second of samples
av_t <- (seq_len(av_n) - 1) / av_sr
av_left <- 0.5 * sin(2 * pi * 440 * av_t)
av_right <- 0.25 * sin(2 * pi * 660 * av_t)

# av encodes from a WAV, so the container under test holds the same 16-bit
# samples as the native fixture.
av_convert <- function(from, format) {
  out <- tempfile(fileext = paste0(".", format))
  suppressMessages(av::av_audio_convert(from, out, format = format,
    verbose = FALSE))
  out
}

av_wav_mono <- tempfile(fileext = ".wav")
av_wav_stereo <- tempfile(fileext = ".wav")
sound_from_values(av_left, av_sr)$save(av_wav_mono)
sound_from_values(rbind(av_left, av_right), av_sr)$save(av_wav_stereo)
# fixtures live in tempdir(); R removes them at the end of the test session

test_that("native WAV load stays quiet and keeps the file's level", {
  msgs <- capture_messages(wav_mono <- Sound(av_wav_mono))
  expect_length(msgs, 0L)
  expect_equal(max(abs(wav_mono$get_values(1))), max(abs(av_left)),
    tolerance = 1e-4)
  expect_equal(wav_mono$get_number_of_channels(), 1L)
  expect_equal(wav_mono$get_nx(), av_n)
})

test_that("FLAC (lossless, av fallback) reads back at the file's own level", {
  flac <- av_convert(av_wav_mono, "flac")
  msgs <- capture_messages(s <- Sound(flac))
  expect_length(msgs, 1L) # one notice per load, naming the decoder
  expect_match(paste(msgs, collapse = " "), "av")
  wav <- Sound(av_wav_mono)
  expect_equal(s$get_number_of_channels(), wav$get_number_of_channels())
  expect_equal(s$get_nx(), wav$get_nx())
  # FLAC is lossless and both containers carry the same 16-bit samples, so the
  # decoded amplitudes must match the WAV exactly, not just approximately.
  expect_equal(max(abs(s$get_values(1) - wav$get_values(1))), 0,
    tolerance = 1e-9)
  expect_equal(max(abs(s$get_values(1))), max(abs(wav$get_values(1))),
    tolerance = 1e-9)
  expect_equal(s$get_rms(0, 1), wav$get_rms(0, 1), tolerance = 1e-9)
})

test_that("OGG Vorbis (lossy, av fallback) reads back near the file's level", {
  ogg <- av_convert(av_wav_mono, "ogg")
  s <- suppressMessages(Sound(ogg))
  wav <- Sound(av_wav_mono)
  wav_peak <- max(abs(wav$get_values(1)))
  peak <- max(abs(s$get_values(1)))
  # Vorbis is lossy, so no exactness is claimed — but the level must be the
  # file's own, i.e. much closer to the WAV peak than to the normalised 1.0.
  expect_lt(abs(peak - wav_peak), abs(1 - peak))
  expect_lt(abs(peak - wav_peak), 0.05)
  expect_lt(abs(s$get_rms(0, 1) - wav$get_rms(0, 1)), 0.02)
  expect_equal(s$get_nx(), wav$get_nx())
})

test_that("stereo through the av fallback returns 2 channels, not 2x mono", {
  flac <- av_convert(av_wav_stereo, "flac")
  s <- suppressMessages(Sound(flac))
  wav <- Sound(av_wav_stereo)
  expect_equal(s$get_number_of_channels(), 2L)
  expect_equal(s$get_nx(), av_n) # not 2 * n: interleaving must be undone
  expect_equal(s$get_total_duration(), wav$get_total_duration(),
    tolerance = 1e-6)
  # Per-channel values; the channels differ in frequency and amplitude, so a
  # de-interleave filled byrow = TRUE cannot pass this.
  expect_equal(max(abs(s$get_values(1) - wav$get_values(1))), 0,
    tolerance = 1e-9)
  expect_equal(max(abs(s$get_values(2) - wav$get_values(2))), 0,
    tolerance = 1e-9)
  expect_equal(max(abs(s$get_values(1))), max(abs(av_left)), tolerance = 1e-4)
  expect_equal(max(abs(s$get_values(2))), max(abs(av_right)),
    tolerance = 1e-4)
})

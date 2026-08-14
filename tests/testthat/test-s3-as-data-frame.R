# test-s3-as-data-frame.R - Tests for the live as.data.frame.<Module> S3
# delegates in R/s3-methods.R (as.data.frame.Sound/Formant/Intensity/Pitch/
# PointProcess/TextGrid/MFCC/LFCC). These are NOT the deprecated legacy
# praat_sound/praat_pitch/praat_formant/praat_intensity S3 API, which
# test-s3-methods.R skips wholesale (no live constructor produces those
# classes any more) -- they are plain `x$as_data_frame()` delegates that
# make generic as.data.frame() work on the current R6 objects.

tone_sound <- function(freq = 150, dur = 0.3, sr = 16000) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)
}

test_that("as.data.frame.Sound delegates to Sound$as_data_frame()", {
  sound <- tone_sound()
  df <- as.data.frame(sound)

  expect_equal(df, sound$as_data_frame())
})

test_that("as.data.frame.Formant delegates to Formant$as_data_frame()", {
  formant <- tone_sound(freq = 220)$to_formant_burg()
  df <- as.data.frame(formant)

  expect_equal(df, formant$as_data_frame())
})

test_that("as.data.frame.Intensity delegates to Intensity$as_data_frame()", {
  intensity <- tone_sound()$to_intensity()
  df <- as.data.frame(intensity)

  expect_equal(df, intensity$as_data_frame())
})

test_that("as.data.frame.Pitch delegates to Pitch$as_data_frame()", {
  pitch <- tone_sound()$to_pitch()
  df <- as.data.frame(pitch)

  expect_equal(df, pitch$as_data_frame())
})

test_that("as.data.frame.PointProcess delegates to PointProcess$as_data_frame()", {
  pp <- tone_sound()$to_point_process_periodic_cc(75, 600)
  df <- as.data.frame(pp)

  expect_equal(df, pp$as_data_frame())
})

test_that("as.data.frame.TextGrid delegates to TextGrid$as_data_frame()", {
  tg <- textgrid_create(0, 1, "words")
  tg$insert_boundary("words", 0.5)
  tg$set_interval_text("words", 1, "hello")

  df <- as.data.frame(tg)
  expect_equal(df, tg$as_data_frame())
})

test_that("as.data.frame.MFCC delegates to MFCC$as_data_frame()", {
  mfcc <- tone_sound()$to_mfcc()
  df <- as.data.frame(mfcc)

  expect_equal(df, mfcc$as_data_frame())
})

test_that("as.data.frame.LFCC delegates to LFCC$as_data_frame()", {
  lpc <- tone_sound()$to_lpc_burg()
  lfcc <- lpc$to_lfcc()
  df <- as.data.frame(lfcc)

  expect_equal(df, lfcc$as_data_frame())
})

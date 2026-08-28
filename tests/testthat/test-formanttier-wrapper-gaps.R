# tests/testthat/test-formanttier-wrapper-gaps.R
# Coverage gap-fill for R/formanttier-wrapper.R (was ~57%): the empty-tier
# getters, the from_formant static conversion, value queries, as_data_frame,
# save and filter_sound.

sound_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
}
formant_fixture <- function() sound_fixture()$to_formant_burg()

test_that("empty FormantTier getters and helpers", {
  ft <- FormantTier(tmin = 0, tmax = 1)
  expect_s3_class(ft, "FormantTier")
  expect_true(ft$is_valid())
  expect_equal(ft$get_start_time(), 0)
  expect_equal(ft$get_end_time(), 1)
  expect_equal(ft$get_duration(), 1)
  expect_identical(ft$get_number_of_points(), 0L)
  expect_type(ft$get_min_num_formants(), "integer")
  expect_type(ft$get_max_num_formants(), "integer")
  expect_identical(ft$get_xptr(), ft$get_ptr())
  expect_output(ft$print(), "FormantTier")
})

test_that("FormantTier$from_formant converts a Formant", {
  ft <- FormantTier$from_formant(formant_fixture())
  expect_s3_class(ft, "FormantTier")
  expect_gte(ft$get_number_of_points(), 1L)
  expect_gt(ft$get_duration(), 0)
  expect_error(FormantTier$from_formant("not a formant"), "must be a Formant")
})

test_that("FormantTier value queries", {
  ft <- FormantTier$from_formant(formant_fixture())
  t <- ft$get_start_time() + 0.05
  v <- ft$get_value_at_time(1, t)
  expect_type(v, "double")
  b <- ft$get_bandwidth_at_time(1, t)
  expect_type(b, "double")
})

test_that("FormantTier S3 methods and accessor NULL branch", {
  ft <- FormantTier$from_formant(formant_fixture())
  expect_null(ft$no_such_method)
  expect_output(print(ft), "FormantTier")
  expect_invisible(print(ft))
  expect_s3_class(as.data.frame(ft), "data.frame")
})

test_that("FormantTier as_data_frame/save/filter_sound", {
  ft <- FormantTier$from_formant(formant_fixture())
  df <- ft$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  tmp <- tempfile(fileext = ".tier")
  expect_invisible(ft$save(tmp))
  expect_true(file.exists(tmp))
  res <- ft$filter_sound(sound_fixture())
  expect_s3_class(res, "Sound")
})

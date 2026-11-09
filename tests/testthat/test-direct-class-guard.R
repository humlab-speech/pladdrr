## The *_direct getters take a bare external pointer. R lets any pointer through,
## so a wrong-class object was reinterpreted as the expected struct: garbage
## answers (sound_get_duration_direct(<TextGrid>) returned 3) or an uncatchable
## SIGSEGV (get_pitch_mean_direct(<TextGrid>) aborted R). They now raise
## a tagged pladdrr_input_error message, like the module constructors do.

# The *_direct R wrappers do not run under with_pladdrr_errors(), so the
# condition is a bare Rcpp::exception carrying the pladdrr tag in its message.
expect_wrong_class <- function(expr) {
  cond <- tryCatch(expr, error = function(e) e)
  expect_s3_class(cond, "error")
  expect_match(conditionMessage(cond), "pladdrr_input_error.*Not an? .* \\(found TextGrid\\)")
}

test_that("*_direct getters refuse a pointer of the wrong class", {
  tg <- TextGrid$create(0, 1, "a", "")$.xptr
  expect_wrong_class(pladdrr:::sound_get_duration_direct(tg))
  expect_wrong_class(pladdrr:::sound_get_rms_direct(tg))
  expect_wrong_class(get_pitch_value_direct(tg, 0.5))
  expect_wrong_class(get_pitch_mean_direct(tg))
  expect_wrong_class(get_pitch_stdev_direct(tg))
  expect_wrong_class(get_pitch_quantile_direct(tg, 0.5))
  expect_wrong_class(get_pitch_stats_direct(tg))
  expect_wrong_class(get_formants_direct(tg, 0.5))
  expect_wrong_class(get_formant_value_direct(tg, 1, 0.5))
  expect_wrong_class(get_intensity_value_direct(tg, 0.5))
})

test_that("*_direct getters still accept the right class", {
  s <- Sound$create_tone(0.5, 22050, 150, 0.5)
  p <- s$to_pitch_cc()
  expect_equal(pladdrr:::sound_get_duration_direct(s$.xptr), 0.5)
  expect_equal(get_pitch_mean_direct(p$.xptr), 150, tolerance = 1e-3)
  expect_true(is.finite(get_pitch_value_direct(p$.xptr, 0.25)))
  expect_true(is.finite(get_intensity_value_direct(s$to_intensity()$.xptr, 0.25)))
  expect_true(is.finite(get_formants_direct(s$to_formant()$.xptr, 0.25)[1]))
})

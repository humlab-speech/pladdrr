## F-cochleagram-input-validation: a step size that cannot describe a Cochleagram
## or an Excitation must be refused with a catchable error before Praat sizes
## its tensor. On macOS `df = 1e-9` (a 2.5 TB request) used to get the whole R
## session SIGKILLed (exit 137); on Linux it failed with an allocation error.
## Nothing here reads the result of the huge requests: the test passing means the
## process lived.

sound <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 44100)

test_that("non-positive or non-finite steps raise a classed input error", {
  bad <- list(0, -1, NA_real_, Inf, NaN, "a", c(0.1, 0.2))
  for (v in bad) {
    for (arg in c("dt", "df", "window_length")) {
      cond <- tryCatch(do.call(sound$to_cochleagram, setNames(list(v), arg)),
        error = function(e) e)
      expect_s3_class(cond, "pladdrr_input_error")
      expect_identical(cond$param, arg)
    }
    for (arg in c("dtime", "dfreq")) {
      cond <- tryCatch(do.call(sound$to_cochleagram_edb, setNames(list(v), arg)),
        error = function(e) e)
      expect_s3_class(cond, "pladdrr_input_error")
      expect_identical(cond$param, arg)
    }
  }
})

test_that("a negative dfreq no longer builds a Cochleagram with negative bands", {
  expect_error(sound$to_cochleagram_edb(dfreq = -1), "dfreq must be a positive")
})

test_that("a step size that asks for an impossible tensor is refused in C++", {
  expect_error(sound$to_cochleagram(df = 1e-9), "not allowed")
  expect_error(sound$to_cochleagram_edb(dfreq = 1e-9), "not allowed")
  spectrum <- sound$to_spectrum()
  expect_error(spectrum$to_excitation(erb_density = 1e-9), "not allowed")
  # The script door has no R-level check at all.
  expect_error(praat_run_script(sprintf(
    'sound = Create Sound from formula: "t", 1, 0, 1, 44100, "sin(2*pi*440*x)"\nTo Cochleagram: 0.01, 0.000000001, 0.03, 0.03')),
    "not allowed")
})

test_that("the default steps still produce the documented shape", {
  cg <- sound$to_cochleagram()
  expect_s3_class(cg, "Cochleagram")
  expect_equal(dim(as.matrix(cg))[1], 256L)
})

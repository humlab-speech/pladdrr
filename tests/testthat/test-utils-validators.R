# test-utils-validators.R - Tests for R/utils.R (internal parameter
# validators and is_praat_*/validate_*_object type checks)

# --- validate_positive -------------------------------------------------------

test_that("validate_positive accepts positive numbers and rejects everything else", {
  expect_equal(pladdrr:::validate_positive(5), 5)
  expect_error(pladdrr:::validate_positive(0), "must be positive")
  expect_error(pladdrr:::validate_positive(-1), "must be positive")
  expect_error(pladdrr:::validate_positive(NA_real_), "cannot be NA")
  expect_error(pladdrr:::validate_positive("x"), "single numeric value")
  expect_error(pladdrr:::validate_positive(c(1, 2)), "single numeric value")
})

# --- validate_non_negative ----------------------------------------------------

test_that("validate_non_negative accepts zero and positive, rejects negative", {
  expect_equal(pladdrr:::validate_non_negative(0), 0)
  expect_equal(pladdrr:::validate_non_negative(5), 5)
  expect_error(pladdrr:::validate_non_negative(-0.1), "non-negative")
  expect_error(pladdrr:::validate_non_negative(NA_real_), "cannot be NA")
  expect_error(pladdrr:::validate_non_negative("x"), "single numeric value")
})

# --- validate_range ------------------------------------------------------------

# --- validate_positive_int -----------------------------------------------------

test_that("validate_positive_int accepts positive integers and rejects the rest", {
  expect_equal(pladdrr:::validate_positive_int(5), 5L)
  expect_error(pladdrr:::validate_positive_int(5.5), "must be a positive integer")
  expect_error(pladdrr:::validate_positive_int(0), "must be a positive integer")
  expect_error(pladdrr:::validate_positive_int(-3), "must be a positive integer")
  expect_error(pladdrr:::validate_positive_int(NA_real_), "cannot be NA")
})

# --- validate_string ------------------------------------------------------------

test_that("validate_string accepts non-empty strings and rejects the rest", {
  expect_identical(pladdrr:::validate_string("hello"), "hello")
  expect_error(pladdrr:::validate_string(""), "cannot be an empty string")
  expect_error(pladdrr:::validate_string(NA_character_), "cannot be NA")
  expect_error(pladdrr:::validate_string(5), "single character string")
  expect_error(pladdrr:::validate_string(c("a", "b")), "single character string")

  expect_equal(pladdrr:::validate_string(NA_character_, allow_na = TRUE), NA_character_)
})

# --- validate_logical ------------------------------------------------------------

# --- is_praat_sound / validate_sound_object --------------------------------

legacy_praat_sound <- function(values, sampling_rate = 8000) {
  n <- length(values)
  structure(
    list(
      values = values,
      time = seq(0, (n - 1) / sampling_rate, length.out = n),
      sampling_rate = sampling_rate,
      n_samples = n,
      duration = n / sampling_rate,
      start_time = 0,
      end_time = n / sampling_rate
    ),
    class = "praat_sound"
  )
}

test_that("is_praat_sound recognizes R6 Sound and well-formed legacy praat_sound", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.1, sampling_rate = 8000)
  expect_true(is_praat_sound(sound))
  expect_true(is_praat_sound(legacy_praat_sound(c(1, 2, 3))))
  expect_false(is_praat_sound(42))
  expect_false(is_praat_sound(list(class = "not a sound")))
})

test_that("is_praat_sound rejects legacy praat_sound objects missing required fields/types", {
  bad <- structure(list(values = 1:3), class = "praat_sound")
  expect_false(is_praat_sound(bad))

  bad2 <- legacy_praat_sound(c(1, 2, 3))
  bad2$values <- "not numeric"
  expect_false(is_praat_sound(bad2))

  bad3 <- legacy_praat_sound(c(1, 2, 3))
  bad3$n_samples <- c(1, 2)
  expect_false(is_praat_sound(bad3))
})

test_that("validate_sound_object passes through valid sounds and errors otherwise", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.1, sampling_rate = 8000)
  expect_equal(pladdrr:::validate_sound_object(sound), sound)
  expect_error(pladdrr:::validate_sound_object(42), "must be a praat_sound object")
})

# --- is_praat_pitch / validate_pitch_object ---------------------------------

test_that("is_praat_pitch recognizes R6 Pitch and well-formed legacy praat_pitch data.frame", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  expect_true(is_praat_pitch(pitch))

  legacy <- data.frame(time = c(0.1, 0.2), frequency = c(120, 130))
  class(legacy) <- c("praat_pitch", "data.frame")
  expect_true(is_praat_pitch(legacy))

  expect_false(is_praat_pitch(42))
  expect_false(is_praat_pitch(structure(list(), class = "praat_pitch")))
})

# --- validate_file_exists / validate_file_extension -------------------------

# --- quality_warning ---------------------------------------

test_that("quality_warning issues an immediate warning with the given message", {
  expect_warning(pladdrr:::quality_warning("example quality issue"), "example quality issue")
})

# --- is_praat_formant / validate_formant_object ------------------------------

test_that("is_praat_formant recognizes R6 Formant and well-formed legacy praat_formant", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  formant <- sound$to_formant_burg()
  expect_true(is_praat_formant(formant))

  legacy <- structure(
    list(
      values = data.frame(time = 0.1, formant_number = 1, frequency = 500, bandwidth = 80),
      n_frames = 1,
      n_formants = 1
    ),
    class = "praat_formant"
  )
  expect_true(is_praat_formant(legacy))

  expect_false(is_praat_formant(42))
  expect_false(is_praat_formant(structure(list(n_frames = 1), class = "praat_formant")))
})

test_that("validate_formant_object passes through valid formants and errors otherwise", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
  formant <- sound$to_formant_burg()
  expect_equal(pladdrr:::validate_formant_object(formant), formant)
  expect_error(pladdrr:::validate_formant_object(42), "must be a praat_formant object")
})

# --- is_praat_intensity ---------------------------

test_that("is_praat_intensity recognizes R6 Intensity and well-formed legacy praat_intensity", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  intensity <- sound$to_intensity()
  expect_true(is_praat_intensity(intensity))

  legacy <- structure(
    list(values = data.frame(time = 0.1, intensity_db = 60), n_frames = 1),
    class = "praat_intensity"
  )
  expect_true(is_praat_intensity(legacy))

  expect_false(is_praat_intensity(42))
  expect_false(is_praat_intensity(structure(list(n_frames = 1), class = "praat_intensity")))
})

test_that("is_praat_formant returns FALSE for non-Formant input", {
  expect_false(is_praat_formant(list()))
  expect_false(is_praat_formant("x"))
  expect_false(is_praat_formant(123))
})

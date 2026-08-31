# test-manipulation-module-gaps.R
# Coverage gap-fill for src/modules/manipulation_module.cpp (Task 29)
#
# Complements test-manipulation-wrapper.R: closes gaps in the Rcpp MODULE
# methods (extract_*_ptr, get_resynthesis_*_ptr, get_info, save) plus the
# module factory functions (Sound_to_Manipulation, Manipulation_create),
# which the R6-style wrapper does not call directly — it routes extract/
# resynthesis-overlap-add through the standalone Rcpp::export wrappers in
# src/manipulation_wrappers.cpp instead, and never exposes get_info/save/
# get_resynthesis_pulses_hum or the module factories at all.

manip_from_tone <- function() {
  snd <- Sound$create_tone(frequency = 150, duration = 0.5,
    sampling_rate = 16000)
  snd$to_manipulation(pitch_floor = 75, pitch_ceiling = 300)
}

test_that("module extract_*_ptr methods return external pointers", {
  manip <- manip_from_tone()

  expect_type(manip$.cpp$extract_pitch_tier_ptr(), "externalptr")
  expect_type(manip$.cpp$extract_duration_tier_ptr(), "externalptr")
  expect_type(manip$.cpp$extract_pulses_ptr(), "externalptr")
  expect_type(manip$.cpp$extract_original_sound_ptr(), "externalptr")
})

test_that("module extract_*_ptr methods error when the tier is absent", {
  mod <- pladdrr:::get_module("manipulation_module")
  empty <- mod$RManipulation$new(mod$Manipulation_create(0.0, 0.5))

  # Manipulation_create() makes a Manipulation with only a duration tier
  # (no pitch tier, no pulses, no sound), so those three extractors error
  # while the duration-tier extractor succeeds.
  expect_error(empty$extract_pitch_tier_ptr(), "No pitch tier")
  expect_error(empty$extract_pulses_ptr(), "No pulses")
  expect_error(empty$extract_original_sound_ptr(), "No original sound")
  expect_type(empty$extract_duration_tier_ptr(), "externalptr")
})

test_that("module resynthesis methods return external pointers", {
  manip <- manip_from_tone()

  expect_type(manip$.cpp$get_resynthesis_overlap_add_ptr(), "externalptr")
  expect_type(manip$.cpp$get_resynthesis_pulses_ptr(), "externalptr")
  expect_type(manip$.cpp$get_resynthesis_pulses_hum_ptr(), "externalptr")
})

test_that("module get_info returns a named list", {
  manip <- manip_from_tone()
  info <- manip$.cpp$get_info()

  expect_type(info, "list")
  expect_true(all(c("xmin", "xmax", "has_pitch_tier", "has_duration_tier",
                    "has_pulses", "has_sound") %in% names(info)))
})

test_that("module save writes a file", {
  manip <- manip_from_tone()
  tmp <- tempfile(fileext = ".Manipulation")
  on.exit(unlink(tmp), add = TRUE)

  manip$.cpp$save(tmp)
  expect_true(file.exists(tmp))
})

test_that("module factory Sound_to_Manipulation builds a valid Manipulation", {
  mod <- pladdrr:::get_module("manipulation_module")
  snd <- Sound$create_tone(frequency = 150, duration = 0.5,
    sampling_rate = 16000)

  xptr <- mod$Sound_to_Manipulation(snd$get_xptr(), 0.01, 75, 300)
  expect_type(xptr, "externalptr")

  manip <- mod$RManipulation$new(xptr)
  expect_true(manip$is_valid())
  expect_true(manip$has_pitch_tier())
  expect_true(manip$has_original_sound())
})

test_that("module factory Sound_to_Manipulation rejects a null sound pointer", {
  mod <- pladdrr:::get_module("manipulation_module")
  # A bare externalptr (not NULL) slips past Rcpp's XPtr conversion and
  # reaches the C++ guard.
  expect_error(mod$Sound_to_Manipulation(new("externalptr"), 0.01, 75, 300),
               "Invalid Sound pointer")
})

test_that("module factory Manipulation_create builds an empty Manipulation", {
  mod <- pladdrr:::get_module("manipulation_module")
  xptr <- mod$Manipulation_create(0.0, 0.5)
  expect_type(xptr, "externalptr")

  manip <- mod$RManipulation$new(xptr)
  expect_true(manip$is_valid())
  expect_false(manip$has_pitch_tier())
  # Manipulation_create() seeds an identity duration tier but no pitch
  # tier, pulses, or sound.
  expect_true(manip$has_duration_tier())
  expect_false(manip$has_pulses())
  expect_false(manip$has_original_sound())
})

# test-formantmodeler-r6.R - Tests for R/formantmodeler-wrapper.R

make_test_modeler <- function() {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5)
  formant <- sound$to_formant_burg()
  formant$to_formant_modeler(tmin = 0, tmax = 0, num_tracks = 3, num_params = 3)
}

test_that("FormantModeler constructs and reports basic properties", {
  modeler <- make_test_modeler()
  expect_s3_class(modeler, "FormantModeler")
  expect_true(modeler$is_valid())
  expect_type(modeler$get_xmin(), "double")
  expect_type(modeler$get_xmax(), "double")
  expect_type(modeler$get_duration(), "double")
  expect_identical(modeler$get_number_of_tracks(), 3L)
  expect_gte(modeler$get_number_of_data_points(), 1)
})

test_that("FormantModeler per-track fit-quality queries work", {
  modeler <- make_test_modeler()
  expect_gte(modeler$get_number_of_parameters(1), 1)
  expect_gte(modeler$get_number_of_invalid_data_points(1), 0)
  expect_type(modeler$get_coefficient_of_determination(1, 3), "double")
  expect_equal(modeler$get_r_squared(1, 3),
    modeler$get_coefficient_of_determination(1,
      3), tolerance = sqrt(.Machine$double.eps))
  expect_type(modeler$get_standard_deviation(1), "double")
  expect_type(modeler$get_residual_sum_of_squares(1), "double")
  expect_type(modeler$get_stress(1, 3), "double")
  expect_type(modeler$get_weighted_mean(1), "double")
})

test_that("FormantModeler per-track value queries and refit", {
  modeler <- make_test_modeler()
  expect_type(modeler$get_model_value_at_time(1, 0.25), "double")
  expect_type(modeler$get_estimated_value_at_time(1, 0.25), "double")
  expect_type(modeler$get_data_point_value(1, 1), "double")
  expect_type(modeler$get_data_point_sigma(1, 1), "double")
  expect_type(modeler$get_track_model_values(1), "double")

  # get_estimated_value_at_time() is documented as a distinct query, but
  # src/modules/formantmodeler_module.cpp's implementation literally calls
  # FormantModeler_getModelValueAtTime() -- the same underlying Praat call as
  # get_model_value_at_time() (getEstimatedValueAtTime() is declared but not
  # implemented in Praat source, per the C++ comment there). They must agree.
  expect_equal(
    modeler$get_estimated_value_at_time(1, 0.25),
    modeler$get_model_value_at_time(1, 0.25)
  , tolerance = sqrt(.Machine$double.eps))

  # get_track_model_values(track) returns one modeled value per data point
  # (src/modules/formantmodeler_module.cpp loops i = 1..n_data_points) --
  # cross-check its length against the data-point count.
  expect_length(modeler$get_track_model_values(1),
    modeler$get_number_of_data_points())

  # process_outliers() is a pure function: it returns a *new* FormantModeler
  # (verified via identical() against the original -- FALSE), it does not
  # mutate `modeler` in place. Capture the return value to actually exercise
  # that code path rather than discarding it.
  cleaned <- modeler$process_outliers(num_sigmas = 3.0)
  expect_s3_class(cleaned, "FormantModeler")
  expect_true(cleaned$is_valid())

  # fit() does mutate/refit in place and (invisibly) returns `.self`.
  refit <- modeler$fit()
  expect_identical(refit, modeler)
  expect_true(modeler$is_valid())
})

test_that("FormantModeler to_formant, as_data_frame, get_info, save", {
  modeler <- make_test_modeler()

  fmt <- modeler$to_formant()
  expect_s3_class(fmt, "Formant")

  df <- modeler$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true(all(c("time", "F1_original", "F1_modeled") %in% names(df)))
  expect_equal(nrow(df), modeler$get_number_of_data_points(),
    tolerance = sqrt(.Machine$double.eps))

  # as_data_frame()'s F1_original column and get_data_point_value(1, i) both
  # read FormantModeler_getDataPointValue() per data point (same C++ call in
  # src/modules/formantmodeler_module.cpp) -- cross-check they agree.
  original_via_getter <- vapply(
    seq_len(nrow(df)),
    function(i) modeler$get_data_point_value(1, i),
    numeric(1)
  )
  expect_equal(df$F1_original, original_via_getter,
    tolerance = sqrt(.Machine$double.eps))

  # get_info() returns a *list* of summary fields (xmin, xmax, n_tracks,
  # n_data_points, track_r2, track_sd, track_parameters) -- not a character
  # string as the draft assumed. print.FormantModeler() formats this list.
  info <- modeler$get_info()
  expect_type(info, "list")
  expect_named(info, c(
    "xmin", "xmax", "n_tracks", "n_data_points",
    "track_r2", "track_sd", "track_parameters"
  ))
  expect_equal(info$n_tracks, 3, tolerance = sqrt(.Machine$double.eps))

  tmp <- tempfile(fileext = ".FormantModeler")
  on.exit(unlink(tmp), add = TRUE)
  modeler$save(tmp)
  expect_true(file.exists(tmp))

  expect_output(print(modeler), "Praat FormantModeler")
})

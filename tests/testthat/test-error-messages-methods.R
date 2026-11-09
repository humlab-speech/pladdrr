# G5.2b: argument checks and diagnostics in Sound methods, PointProcess
# voice reports, TextGrid helpers, the Praat interpreter and configuration
# functions each have their own message, shown here.

snd <- generate_sine_wave(200, 0.3, sampling_rate = 16000, amplitude = 0.5)
tg_path <- system.file("extdata", "test.TextGrid", package = "pladdrr")

test_that("Sound methods that take a second Sound reject other objects", {
  expect_error(snd$concatenate("a"), "sound$concatenate(): other_sound must be a Sound object", fixed = TRUE)
  expect_error(snd$convolve("a"), "sound$convolve(): other_sound must be a Sound object", fixed = TRUE)
  expect_error(snd$cross_correlate("a"), "sound$cross_correlate(): other_sound must be a Sound object", fixed = TRUE)
  expect_error(snd$mix("a"), "sound$mix(): other_sound must be a Sound object", fixed = TRUE)
})

test_that("Sound methods validate frequency, rate and value arguments", {
  expect_error(snd$filter_pass_hann_band(500, 100),
               "sound$filter_pass_hann_band(): Invalid frequency range: fmin must be >= 0 and fmax must be > fmin", fixed = TRUE)
  expect_error(snd$filter_stop_hann_band(500, 100),
               "sound$filter_stop_hann_band(): Invalid frequency range: fmin must be >= 0 and fmax must be > fmin", fixed = TRUE)
  expect_error(snd$resample(-1), "new_frequency must be positive", fixed = TRUE)
  expect_error(sound_from_values(list(1, 2)), "values must be numeric, got", fixed = TRUE)
  expect_error(sound_from_values(data.frame(a = 1, b = 2)),
               "values must be a numeric vector or matrix", fixed = TRUE)
  expect_error(generate_noise(0.1, seed = "a"), "'seed' must be a single numeric value or NULL", fixed = TRUE)
})

test_that("mono/stereo conversions say when there is nothing to do", {
  expect_message(snd$convert_to_mono(), "Sound is already mono, returning copy", fixed = TRUE)
  expect_warning(snd$convert_to_stereo()$convert_to_stereo(),
                 "Sound is already multi-channel, returning as-is", fixed = TRUE)
})

test_that("PointProcess$voice_report checks its Sound and Pitch arguments", {
  pp <- snd$to_point_process_periodic_cc(75, 600)
  expect_error(pp$voice_report("a", snd$to_pitch_cc()), "sound argument must be a Sound object", fixed = TRUE)
  expect_error(pp$voice_report(snd, "a"), "pitch argument must be a Pitch object", fixed = TRUE)
})

test_that("Manipulation, Cochleagram, Excitation and LPC methods check their operands", {
  expect_error(snd$to_manipulation()$replace_duration_tier("a"),
               "duration_tier must be a DurationTier object", fixed = TRUE)
  expect_error(snd$to_manipulation()$replace_pitch_tier("a"),
               "pitch_tier must be a PitchTier object", fixed = TRUE)
  expect_error(snd$to_cochleagram()$get_difference("a"), "other must be a Cochleagram object", fixed = TRUE)
  expect_error(snd$to_spectrum()$to_excitation()$get_distance("a"),
               "other must be an Excitation object", fixed = TRUE)
  expect_error(snd$to_lpc_burg()$filter_inverse_at_time(snd, "a"),
               "time must be a single numeric value", fixed = TRUE)
})

test_that("TextGrid interval extraction demands exactly one criterion and a valid tier", {
  tg <- TextGrid(path = tg_path)
  expect_error(extract_textgrid_intervals(tg, tier = 0, text_equals = "a"),
               "tier must be a positive integer or valid tier name", fixed = TRUE)
  expect_error(extract_textgrid_intervals(tg, tier = 1),
               "Must specify one comparison criterion", fixed = TRUE)
  expect_error(extract_textgrid_intervals(tg, tier = 1, text_equals = "a", text_contains = "b"),
               "Specify only ONE comparison criterion", fixed = TRUE)
  expect_error(extract_textgrid_intervals(tg, tier = 1, text_equals = "a", extract_sounds = TRUE),
               "sound argument required when extract_sounds = TRUE", fixed = TRUE)
  expect_error(pladdrr:::.textgrid_resolve_tier(NULL, TRUE),
               "Tier must be numeric index or character name", fixed = TRUE)
})

test_that("pair_files supports only basename matching and warns when nothing pairs", {
  d <- withr::local_tempdir()
  expect_error(pair_files(d, by = "other"), "Only 'basename' matching is currently supported", fixed = TRUE)
  expect_warning(pair_files(d), "No matching pairs found", fixed = TRUE)
})

test_that("interpreter helpers and configuration functions validate their arguments", {
  expect_error(PraatInterpreter$new()$eval(""),
               "'expression' must be a single non-empty character string", fixed = TRUE)
  expect_error(PraatInterpreter$new()$set_object("x", 1),
               "object must be a PraatObject (Sound, Pitch, etc.)", fixed = TRUE)
  expect_error(praat_run_script(""), "'script' must be a single non-empty character string", fixed = TRUE)
  expect_error(PraatInterpreter$new()$set_variable("", 1),
               "'name' must be a single non-empty character string", fixed = TRUE)
  expect_error(pladdrr_simd("x"), "enabled must be TRUE, FALSE, or NULL", fixed = TRUE)
  expect_error(pladdrr_threads(-1), "n must be a single non-negative integer (0 = automatic)", fixed = TRUE)
})

test_that("multiband and time-pair validators name the problem", {
  bad <- stats::setNames(as.list(1:5), letters[1:5])
  expect_error(pladdrr:::.coerce_multiband_harmonicity(bad),
               "multiband entries must be Harmonicity objects or external pointers", fixed = TRUE)
  expect_error(pladdrr:::.validate_time_pair("a", 1),
               "from_time and to_time must be single numeric values", fixed = TRUE)
})

test_that("robust slow trend fit warns once per session about non-determinism", {
  # the warning is emitted once; reset the flag so the test is order independent
  flag <- get(".warned_robust_slow", envir = asNamespace("pladdrr"))
  old <- flag$done; flag$done <- NULL
  withr::defer(flag$done <- old)
  expect_warning(pladdrr:::.check_trend_fit_method("robust slow"), r"(fit_method = "robust slow" (Praat's Theil-Sen trend fit) is not reproducible)", fixed = TRUE)
})

test_that("plotting a TextGrid without data warns", {
  tg <- TextGrid(path = tg_path)
  expect_warning(plot(tg, tier = 99), "No interval data found", fixed = TRUE)
})

test_that("tier plots warn when the requested range holds no data", {
  skip_if_not_installed("ggplot2")
  at <- amplitude_tier_create(0, 1); at$add_point(0.2, 0.5)
  dt <- DurationTier(0, 1); dt$add_point(0.2, 1)
  it <- IntensityTier(0, 1); it$add_point(0.2, 60)
  pt <- PitchTier(0, 1); pt$add_point(0.2, 100)
  expect_warning(ggplot2::autoplot(at, from_time = 5, to_time = 6),
                 "AmplitudeTier has no data in the specified time range", fixed = TRUE)
  expect_warning(ggplot2::autoplot(dt, from_time = 5, to_time = 6),
                 "DurationTier has no data in the specified time range", fixed = TRUE)
  expect_warning(ggplot2::autoplot(it, from_time = 5, to_time = 6),
                 "IntensityTier has no data in the specified time range", fixed = TRUE)
  expect_warning(ggplot2::autoplot(pt, from_time = 5, to_time = 6),
                 "PitchTier has no data in the specified time range", fixed = TRUE)
})

test_that("cepstrum plot functions check the class of their first argument", {
  expect_error(plot_cpp_timeseries("a"),
               "plot_cpp_timeseries(): cepstrogram must be a PowerCepstrogram object", fixed = TRUE)
  expect_error(plot_powercepstrogram("a"),
               "plot_powercepstrogram(): cepstrogram must be a PowerCepstrogram object", fixed = TRUE)
  expect_error(plot_powercepstrum("a"), "cepstrum must be a PowerCepstrum object", fixed = TRUE)
})

test_that("analyze_files_parallel announces that it is running on a single core", {
  expect_message(analyze_files_parallel(character(0), function(x) 1, n_cores = 1),
                 "Using single core (set n_cores > 1 for parallel processing)", fixed = TRUE)
})

test_that("LongSound refuses to become a data frame and points to extract_part()", {
  path <- withr::local_tempfile(fileext = ".wav")
  snd$save(path)
  ls <- LongSound$open(path)
  expect_error(as.data.frame(ls),
               "LongSound streams from disk. Use x$extract_part(from, to) to get a Sound", fixed = TRUE)
})

test_that("ComplexSpectrogram and LPC methods report unusable arguments", {
  fake <- structure(list(), class = c("Sound", "PraatObject"))
  expect_error(ComplexSpectrogram(fake), "Cannot extract XPtr from Sound object", fixed = TRUE)
  expect_error(snd$to_lpc_burg()$filter_inverse_at_time(snd, 0.1, channel = 0),
               "channel must be a positive integer", fixed = TRUE)
})

test_that("interpreter pointer helpers warn or error on objects without a pointer", {
  expect_warning(pladdrr:::.wrap_praat_object(snd$.xptr),
                 "Object has no praat_class attribute, returning raw pointer", fixed = TRUE)
  expect_error(pladdrr:::.praat_object_xptr(list()),
               "Could not extract Praat external pointer from object", fixed = TRUE)
})

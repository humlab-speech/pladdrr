# G2.0-G2.2: scalar arguments are checked for length and type before they reach
# C++. autotest (dev/ropensci-autotest-findings.md) showed these functions
# accepted a length-2 vector, a character vector or 0/1 for a flag.

test_that("file-listing functions require single strings and TRUE/FALSE flags", {
  d <- withr::local_tempdir()
  expect_error(create_file_list(c(d, d)), "create_file_list(): directory must be a single string",
               fixed = TRUE, class = "pladdrr_input_error")
  expect_error(create_file_list(d, pattern = c("a", "b")),
               "create_file_list(): pattern must be a single string", fixed = TRUE)
  expect_error(create_file_list(d, full_names = 1),
               "create_file_list(): full_names must be TRUE or FALSE", fixed = TRUE)
  expect_error(create_file_list(d, recursive = NA),
               "create_file_list(): recursive must be TRUE or FALSE", fixed = TRUE)
  expect_equal(create_file_list(d, pattern = NULL), character(0))

  for (fn in c("pair_files", "pair_sound_textgrid")) {
    f <- get(fn)
    expect_error(f(c(d, d)), paste0(fn, "(): sound_dir must be a single string"), fixed = TRUE)
    expect_error(f(d, textgrid_dir = 1), paste0(fn, "(): textgrid_dir must be a single string"), fixed = TRUE)
    expect_error(f(d, sound_pattern = c("a", "b")),
                 paste0(fn, "(): sound_pattern must be a single string"), fixed = TRUE)
    expect_error(f(d, textgrid_pattern = NA_character_),
                 paste0(fn, "(): textgrid_pattern must be a single string"), fixed = TRUE)
    expect_error(f(d, require_both = 1),
                 paste0(fn, "(): require_both must be TRUE or FALSE"), fixed = TRUE)
  }

  fun <- function(s) 1
  expect_error(batch_process(c(d, d), func = fun), "batch_process(): directory must be a single string", fixed = TRUE)
  expect_error(batch_process(d, pattern = 1, func = fun), "batch_process(): pattern must be a single string", fixed = TRUE)
  expect_error(batch_process(d, func = fun, recursive = 1), "batch_process(): recursive must be TRUE or FALSE", fixed = TRUE)
  expect_error(batch_process(d, func = fun, parallel = "yes"), "batch_process(): parallel must be TRUE or FALSE", fixed = TRUE)
  expect_error(batch_process(d, func = fun, progress = NA), "batch_process(): progress must be TRUE or FALSE", fixed = TRUE)
})

test_that("pitch batch and direct functions reject malformed analysis parameters", {
  snd <- generate_sine_wave(200, 0.3, sampling_rate = 16000, amplitude = 0.5)
  for (fn in c("sound_to_pitch_ac_batch", "sound_to_pitch_cc_batch")) {
    f <- get(fn)
    expect_error(f(list(snd), pitch_floor = "a"), class = "pladdrr_input_error", info = fn)
    expect_error(f(list(snd), pitch_floor = 500, pitch_ceiling = 100), class = "pladdrr_input_error", info = fn)
    expect_error(f(list(snd), max_candidates = 0), class = "pladdrr_input_error", info = fn)
    expect_error(f(list(snd), time_step = c(0.01, 0.02)), class = "pladdrr_input_error", info = fn)
  }
  expect_error(sound_to_pitch_batch(list(snd), pitch_floor = c(75, 80)), class = "pladdrr_input_error")
  expect_error(sound_to_pitch_shs_batch(list(snd), max_subharmonics = "a"), class = "pladdrr_input_error")
  expect_error(sound_to_pitch_shs_batch(list(snd), n_points_per_octave = 0), class = "pladdrr_input_error")
  expect_error(sound_to_pitch_spinet_batch(list(snd), n_filters = -1), class = "pladdrr_input_error")
  expect_error(sound_to_pitch_spinet_batch(list(snd), pitch_ceiling = list(500)), class = "pladdrr_input_error")
  for (fn in c("to_pitch_ac_direct", "to_pitch_cc_direct")) {
    f <- get(fn)
    expect_error(f(snd, pitch_floor = "a"), class = "pladdrr_input_error", info = fn)
    expect_error(f(snd, max_candidates = c(5, 6)), class = "pladdrr_input_error", info = fn)
  }
  expect_error(to_pitch_shs_direct(snd, max_subharmonics = 0), class = "pladdrr_input_error")
  expect_error(to_pitch_spinet_direct(snd, n_filters = "x"), class = "pladdrr_input_error")
  # valid calls still work
  expect_length(sound_to_pitch_cc_batch(list(snd), return_r6 = FALSE), 1L)
})

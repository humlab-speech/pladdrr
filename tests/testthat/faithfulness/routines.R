# Faithfulness routine registry.
#
# Each entry binds a Praat-side oracle (script text + result parser) to a
# pladdrr-side call (R expression producing the same scalar/vector) at a
# documented tolerance, evaluated on a fixture audio file.
#
# Adding a routine:
#   1. Add a Praat script that prints exactly one value per line on stdout.
#   2. Add a pladdrr R expression that returns the same shape numeric.
#   3. Pick tolerance:
#        - 0       : exact-arithmetic routines (frame indexing, copies).
#                    Default — silent drift fails loudly.
#        - small   : DSP routines with well-understood FP noise (≤1e-6 typical).
#        - documented: anything looser MUST carry a rationale comment.
#   4. Reference a fixture by basename in `inst/extdata/`, `inst/signalfiles/`,
#      or `inst/testdata/`.
#
# Routines are intentionally Praat-script-heredoc rather than .praat files so
# the spec and the oracle stay in one place per row.

FAITHFULNESS_ROUTINES <- list(

  list(
    name        = "Sound$get_total_duration",
    fixture     = "extdata/test.wav",
    tolerance   = 0,
    rationale   = "Pure metadata read; must match Praat to the last bit.",
    praat_script = '
      sound = Read from file: "{path}"
      dur = Get total duration
      writeInfoLine: dur
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr     = function(path) pladdrr::Sound(path)$get_total_duration()
  ),

  list(
    name        = "Sound$get_number_of_samples",
    fixture     = "extdata/test.wav",
    tolerance   = 0,
    rationale   = "Frame count; integer equality required.",
    praat_script = '
      sound = Read from file: "{path}"
      n = Get number of samples
      writeInfoLine: n
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr     = function(path) pladdrr::Sound(path)$get_number_of_samples()
  ),

  list(
    name        = "Sound -> Pitch (cc) -> mean F0 (Hz)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-4,
    rationale   = "Pitch CC pipeline; FP noise from FFT + interpolation. 0.0001 Hz is below any phonetic threshold.",
    praat_script = '
      sound = Read from file: "{path}"
      pitch = To Pitch (cc): 0.0, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
      mean_f0 = Get mean: 0, 0, "Hertz"
      writeInfoLine: mean_f0
    ',
    parse_praat = function(lines) {
      v <- as.numeric(tail(lines, 1))
      if (is.na(v) || grepl("undefined", tail(lines, 1), ignore.case = TRUE)) NA_real_ else v
    },
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      p <- s$to_pitch_cc(time_step = 0.0, pitch_floor = 75, max_candidates = 15,
                        very_accurate = FALSE, silence_threshold = 0.03,
                        voicing_threshold = 0.45, octave_cost = 0.01,
                        octave_jump_cost = 0.35, voiced_unvoiced_cost = 0.14,
                        pitch_ceiling = 600)
      p$get_mean(0, 0, "hertz")
    }
  ),

  list(
    name        = "Sound -> Intensity -> mean (dB)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-6,
    rationale   = "RMS-based intensity; FP noise from log + windowing.",
    praat_script = '
      sound = Read from file: "{path}"
      intensity = To Intensity: 100, 0, "yes"
      m = Get mean: 0, 0, "dB"
      writeInfoLine: m
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      i <- s$to_intensity(minimum_pitch = 100, time_step = 0,
                         subtract_mean = TRUE)
      i$get_mean(0, 0, "dB")
    }
  ),

  list(
    name        = "Sound -> Formant (burg) -> F1@0.5s (Hz)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-3,
    rationale   = "Burg LPC; well-conditioned for vowel-like input. Hz-level tolerance is below within-speaker variability.",
    praat_script = '
      sound = Read from file: "{path}"
      formant = To Formant (burg): 0, 5, 5500, 0.025, 50
      f1 = Get value at time: 1, 0.5, "Hertz", "Linear"
      writeInfoLine: f1
    ',
    parse_praat = function(lines) {
      v <- as.numeric(tail(lines, 1))
      if (is.na(v) || grepl("undefined", tail(lines, 1), ignore.case = TRUE)) NA_real_ else v
    },
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      f <- s$to_formant_burg(time_step = 0, max_number_of_formants = 5,
                            maximum_formant = 5500, window_length = 0.025,
                            pre_emphasis_from = 50)
      f$get_value_at_time(formant_number = 1, time = 0.5,
                          unit = "hertz", interpolation = "linear")
    }
  )
)

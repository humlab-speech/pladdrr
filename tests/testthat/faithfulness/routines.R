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
  ),
# --- Expanded coverage (v4.9.17 assessment) ---

  # CPPS via calculate_cpps_ultra
  list(
    name        = "CPPS (calculate_cpps_ultra)",
    fixture     = "extdata/test.wav",
    tolerance   = 5e-3,
    rationale   = paste("CPPS dB. 0.005 dB covers the ~0.003 dB drift traced to the",
                        "pocketfft-for-FFTPACK substitution (PRAAT_MODIFICATIONS v4.8.12):",
                        "~1e-11 relative in the cepstrogram, amplified by log + peak-pick +",
                        "robust fit. Three orders of magnitude below any clinical threshold."),
    praat_script = '
      sound = Read from file: "{path}"
      cepstrogram = To PowerCepstrogram: 60, 0.002, 5000, 50
      cpps = Get CPPS: "yes", 0.001, 0.0005, 60, 333.3, 0.05, "parabolic", 0.003, 0.04, "Straight", "Robust"
      writeInfoLine: cpps
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr     = function(path) {
      s <- pladdrr::Sound(path)
      pladdrr::calculate_cpps_ultra(s)
    }
  ),

  # Pitch AC algorithm
  list(
    name        = "Pitch (AC) -> mean F0 (Hz)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-4,
    rationale   = "Pitch AC pipeline; FP noise from autocorrelation + interpolation.",
    praat_script = '
      sound = Read from file: "{path}"
      pitch = To Pitch (ac): 0.0, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
      mean_f0 = Get mean: 0, 0, "Hertz"
      writeInfoLine: mean_f0
    ',
    parse_praat = function(lines) {
      v <- as.numeric(tail(lines, 1))
      if (is.na(v) || grepl("undefined", tail(lines, 1), ignore.case = TRUE)) NA_real_ else v
    },
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      p <- s$to_pitch_ac(time_step = 0, pitch_floor = 75, max_candidates = 15,
                         very_accurate = FALSE, silence_threshold = 0.03,
                         voicing_threshold = 0.45, octave_cost = 0.01,
                         octave_jump_cost = 0.35, voiced_unvoiced_cost = 0.14,
                         pitch_ceiling = 600)
      p$get_mean(unit = "hertz")
    }
  ),

  # Pitch SHS algorithm
  list(
    name        = "Pitch (SHS) -> mean F0 (Hz)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-4,
    rationale   = paste("Pitch SHS pipeline; subharmonic summation FP noise.",
                        "Time step must be > 0: Praat rejects 0 for To Pitch (shs)."),
    praat_script = '
      sound = Read from file: "{path}"
      pitch = To Pitch (shs): 0.01, 75, 15, 1250, 15, 0.84, 600, 48
      mean_f0 = Get mean: 0, 0, "Hertz"
      writeInfoLine: mean_f0
    ',
    parse_praat = function(lines) {
      v <- as.numeric(tail(lines, 1))
      if (is.na(v) || grepl("undefined", tail(lines, 1), ignore.case = TRUE)) NA_real_ else v
    },
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      p <- s$to_pitch_shs(time_step = 0.01, pitch_floor = 75, max_frequency = 1250,
                          max_candidates = 15, compression_factor = 0.84,
                          pitch_ceiling = 600, n_points_per_octave = 48)
      p$get_mean(unit = "hertz")
    }
  ),

  # Intensity
  list(
    name        = "Intensity -> mean (energy-averaged, dB)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-5,
    rationale   = paste("Energy averaging converts to the linear domain and back",
                        "(mean of 10^(x/10), then 10*log10), so it carries more FP",
                        "amplification than the dB-averaged query above, which holds",
                        "at 1e-6. Observed |D| ~ 7.7e-6 dB on ~85 dB is ~4 ulp."),
    praat_script = '
      sound = Read from file: "{path}"
      intensity = To Intensity: 100, 0, "yes"
      mean_db = Get mean: 0, 0, "energy"
      writeInfoLine: mean_db
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      i <- s$to_intensity(minimum_pitch = 100, time_step = 0, subtract_mean = TRUE)
      i$get_mean(averaging_method = "energy")
    }
  ),

  # Formant (KeepAll) at time point
  list(
    name        = "Formant (keepAll) -> F1@0.5s (Hz)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-3,
    rationale   = paste("KeepAll LPC variant; same precision expectation as Burg.",
                        "On the 440 Hz tone fixture both sides return 0 Hz for F1:",
                        "a pure tone has no formant structure, so this row guards the",
                        "degenerate-input path rather than a formant value."),
    praat_script = '
      sound = Read from file: "{path}"
      formant = To Formant (keep all): 0, 5, 5500, 0.025, 50
      f1 = Get value at time: 1, 0.5, "Hertz", "Linear"
      writeInfoLine: f1
    ',
    parse_praat = function(lines) {
      v <- as.numeric(tail(lines, 1))
      if (is.na(v) || grepl("undefined", tail(lines, 1), ignore.case = TRUE)) NA_real_ else v
    },
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      f <- s$to_formant_keepall(time_step = 0, max_formants = 5,
                                max_frequency = 5500, window_length = 0.025,
                                pre_emphasis_from = 50)
      f$get_value_at_time(formant_number = 1, time = 0.5,
                          unit = "hertz", interpolation = "linear")
    }
  ),

# --- Coverage gaps identified in dev/ASSESSMENT_2026-08-05.md section 2.5 ---

  # Harmonicity (cc)
  list(
    name        = "Harmonicity (cc) -> mean (dB)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-4,
    rationale   = paste("HNR runs through the pitch autocorrelation machinery, so it",
                        "inherits the pocketfft substitution's ~1e-11 relative FFT",
                        "drift plus interpolation noise. Observed |D| ~ 8.2e-5 dB on",
                        "~92 dB, i.e. ~9e-7 relative - the loosest DSP row in the",
                        "registry, and worth revisiting if pocketfft is reverted."),
    praat_script = '
      sound = Read from file: "{path}"
      harmonicity = To Harmonicity (cc): 0.01, 75, 0.1, 1.0
      m = Get mean: 0, 0
      writeInfoLine: m
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      s$to_harmonicity_cc(time_step = 0.01, min_pitch = 75,
                          silence_threshold = 0.1,
                          periods_per_window = 1.0)$get_mean(0, 0)
    }
  ),

  # Spectrogram power at a (time, frequency) point.
  # This row exists because the assessment measured a 24% relative deviation here
  # and nothing in the suite caught it. Keep the tolerance tight: if it fails, that
  # is the finding, not a reason to widen it.
  list(
    name        = "Spectrogram -> power at (0.5 s, 1000 Hz)",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-9,
    rationale   = paste("Direct cell query on a Gaussian-window spectrogram; no",
                        "robust fitting or peak picking to amplify FP noise, so it",
                        "should agree far below 1e-9."),
    praat_script = '
      sound = Read from file: "{path}"
      spectrogram = To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"
      p = Get power at: 0.5, 1000
      writeInfoLine: p
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      s$to_spectrogram(0.005, 5000, 0.002, 20, "Gaussian")$get_power_at(0.5, 1000)
    }
  ),

  # PointProcess -> jitter (local)
  list(
    name        = "PointProcess (cc) -> jitter local",
    fixture     = "extdata/test.wav",
    tolerance   = 1e-9,
    rationale   = paste("Jitter is a ratio of period differences; absolute values are",
                        "~1e-6, so a 1e-9 absolute tolerance is ~1e-3 relative and",
                        "still tight enough to catch a changed period set."),
    praat_script = '
      sound = Read from file: "{path}"
      pp = To PointProcess (periodic, cc): 75, 600
      j = Get jitter (local): 0, 0, 0.0001, 0.02, 1.3
      writeInfoLine: j
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      s$to_point_process_periodic_cc(75, 600)$get_jitter_local(0, 0, 0.0001, 0.02, 1.3)
    }
  ),

  # MFCC frame count (structural: frame grid must line up exactly)
  list(
    name        = "MFCC -> number of frames",
    fixture     = "extdata/test.wav",
    tolerance   = 0,
    rationale   = "Frame-grid arithmetic; integer equality required.",
    praat_script = '
      sound = Read from file: "{path}"
      mfcc = To MFCC: 12, 0.015, 0.005, 100, 100, 0
      n = Get number of frames
      writeInfoLine: n
    ',
    parse_praat = function(lines) as.numeric(tail(lines, 1)),
    pladdrr = function(path) {
      s <- pladdrr::Sound(path)
      s$to_mfcc(12, 0.015, 0.005, 100, 100, 0)$get_number_of_frames()
    }
  )
)

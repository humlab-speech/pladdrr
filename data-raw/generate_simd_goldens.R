# Generates golden reference CSVs from real Praat.app for SIMD parity testing.
#
# Run manually when adding a new fixture, a new module, or after a
# Praat-facing algorithm change; the outputs are committed under
# tests/testthat/fixtures/simd-golden/ so the testthat suite
# (test-simd-vs-praat-golden.R, test-simd-modules-vs-praat-golden.R) never has
# to shell out to Praat itself -- CI has no Praat binary, and per-test
# generation would make results depend on whatever Praat build happens to be
# installed on the machine running the suite.
#
# Requires Praat.app at /Applications/Praat.app (macOS) and the speakr
# package (a Suggests-only dependency of this script, not of the package).

library(pladdrr)
library(speakr)

fixture_dir <- "tests/testthat/fixtures/simd-golden"
dir.create(fixture_dir, showWarnings = FALSE, recursive = TRUE)
fixture_dir <- normalizePath(fixture_dir, mustWork = TRUE)

mono_script <- normalizePath(
  "data-raw/simd-golden/mono_analysis_golden.praat", mustWork = TRUE
)
mono_conversion_script <- normalizePath(
  "data-raw/simd-golden/mono_conversion_golden.praat", mustWork = TRUE
)
klattgrid_script <- normalizePath(
  "data-raw/simd-golden/klattgrid_golden.praat", mustWork = TRUE
)

# --- Mono fixtures -----------------------------------------------------
# tone_200hz / tone_120hz_low: pure tones, cheap sanity check across the
#   full F0 range pladdrr's default pitch_floor/pitch_ceiling cover.
# silence: exercises the "no signal" edge case (unvoiced/undefined frames).
# complex_tone: a harmonic series with 1/n rolloff -- pure tones have a
#   degenerate spectral envelope that doesn't exercise Formant/LPC/MFCC in
#   any interesting way, this fixture gives them actual spectral structure
#   to track.
mono_fixtures <- list(
  tone_200hz = function() {
    Sound$create_tone(
      duration = 1.0, sampling_rate = 16000, frequency = 200
    )
  },
  tone_120hz_low = function() {
    Sound$create_tone(
      duration = 1.0, sampling_rate = 16000, frequency = 120
    )
  },
  silence = function() Sound$from_values(rep(0, 16000), 16000),
  complex_tone = function() {
    sr <- 16000
    t <- seq(0, 1, length.out = sr)
    f0 <- 120
    values <- Reduce(`+`, lapply(1:30, function(k) sin(2 * pi * k * f0 * t) / k))
    Sound$from_values(values / max(abs(values)) * 0.5, sr)
  }
)

for (name in names(mono_fixtures)) {
  snd <- mono_fixtures[[name]]()
  wav_path <- file.path(fixture_dir, paste0(name, ".wav"))
  snd$save(wav_path)
  praat_run(mono_script, wav_path, fixture_dir, name)
  cat("mono golden generated:", name, "\n")
}

# --- Stereo fixture (for stereo-to-mono conversion SIMD path) ----------
if (requireNamespace("tuneR", quietly = TRUE)) {
  sr <- 16000
  t <- seq(0, 1, length.out = sr)
  left <- sin(2 * pi * 200 * t) * 0.5
  right <- sin(2 * pi * 300 * t) * 0.5
  w <- tuneR::Wave(left = as.integer(left * 32767), right = as.integer(right * 32767),
                    samp.rate = sr, bit = 16)
  stereo_wav <- file.path(fixture_dir, "stereo_test.wav")
  tuneR::writeWave(w, stereo_wav)

  praat_run(mono_conversion_script, stereo_wav,
            file.path(fixture_dir, "stereo_test_mono_conversion_golden.csv"))
  cat("stereo golden generated: stereo_test\n")
} else {
  cat("tuneR not installed -- skipped stereo_test fixture regeneration\n")
}

# --- KlattGrid synthesis (standalone, no input wav needed) -------------
praat_run(klattgrid_script, file.path(fixture_dir, "klattgrid_vowel_golden.csv"))
cat("klattgrid golden generated\n")

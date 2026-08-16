# Generates golden reference CSVs from real Praat.app for SIMD parity testing.
#
# Run manually when adding a new fixture or after a Praat-facing algorithm
# change; the outputs are committed under tests/testthat/fixtures/simd-golden/
# so the testthat suite (test-simd-vs-praat-golden.R) never has to shell out
# to Praat.app itself (CI has no Praat binary).
#
# Requires Praat.app at /Applications/Praat.app (macOS) and the speakr package.

library(pladdrr)
library(speakr)

fixture_dir <- "tests/testthat/fixtures/simd-golden"
dir.create(fixture_dir, showWarnings = FALSE, recursive = TRUE)
fixture_dir <- normalizePath(fixture_dir, mustWork = TRUE)

praat_script <- "data-raw/simd-golden/pitch_intensity_golden.praat"

fixtures <- list(
  tone_200hz = function() {
    Sound$create_tone(duration = 1.0, sampling_rate = 16000, frequency = 200)
  },
  tone_120hz_low = function() {
    Sound$create_tone(duration = 1.0, sampling_rate = 16000, frequency = 120)
  },
  silence = function() {
    Sound$from_values(rep(0, 16000), 16000)
  }
)

for (name in names(fixtures)) {
  snd <- fixtures[[name]]()
  wav_path <- file.path(fixture_dir, paste0(name, ".wav"))
  snd$save(wav_path)

  pitch_csv <- file.path(fixture_dir, paste0(name, "_pitch_golden.csv"))
  intensity_csv <- file.path(fixture_dir, paste0(name, "_intensity_golden.csv"))

  praat_run(normalizePath(praat_script, mustWork = TRUE), wav_path, pitch_csv, intensity_csv)

  cat("golden generated:", name, "\n")
}

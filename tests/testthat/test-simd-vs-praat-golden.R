# Cross-validates pladdrr's Pitch/Intensity output (both scalar and SIMD
# code paths) against real Praat.app-generated golden references.
#
# Internal SIMD-vs-scalar parity tests only prove pladdrr's two C++ paths
# agree with each other; they can't catch a bug shared by both. These tests
# close that gap by comparing against ground truth captured from Praat.app
# itself (see data-raw/generate_simd_goldens.R). The goldens are committed
# CSVs so this suite never has to shell out to Praat at test time.

fixture_dir <- test_path("fixtures/simd-golden")

fixtures <- c("tone_200hz", "tone_120hz_low", "silence")

read_golden_pitch <- function(name) {
  df <- read.csv(file.path(fixture_dir, paste0(name, "_pitch_golden.csv")),
                  colClasses = "character")
  df$time <- as.numeric(df$time)
  df$f0_hz <- suppressWarnings(as.numeric(df$f0_hz)) # "--undefined--" -> NA
  df
}

read_golden_intensity <- function(name) {
  df <- read.csv(file.path(fixture_dir, paste0(name, "_intensity_golden.csv")))
  df$time <- as.numeric(df$time)
  df$db <- as.numeric(df$db)
  df
}

for (fixture in fixtures) {
  for (simd_enabled in c(FALSE, TRUE)) {
    label <- if (simd_enabled) "SIMD" else "scalar"

    test_that(paste0("Pitch matches Praat.app golden (", fixture, ", ", label, ")"), {
      skip_if_not(file.exists(file.path(fixture_dir, paste0(fixture, ".wav"))),
                  "golden fixture missing; run data-raw/generate_simd_goldens.R")

      old <- pladdrr_simd()$enabled
      on.exit(pladdrr_simd(old))
      pladdrr_simd(simd_enabled)

      snd <- Sound(file.path(fixture_dir, paste0(fixture, ".wav")))
      pitch <- snd$to_pitch(0, 75, 600)
      golden <- read_golden_pitch(fixture)

      expect_equal(pitch$get_number_of_frames(), nrow(golden))

      f0 <- vapply(seq_len(nrow(golden)), function(i) {
        t <- pitch$get_time_from_frame(i)
        pitch$get_value_at_time(t, unit = "hertz", interpolate = FALSE)
      }, numeric(1))

      # Praat reports unvoiced frames as "--undefined--" (NA); pladdrr
      # reports them as NaN or 0 depending on path -- treat both as unvoiced.
      voiced <- !is.na(golden$f0_hz)
      expect_equal(f0[voiced], golden$f0_hz[voiced], tolerance = 1e-3)
      expect_true(all(is.na(f0[!voiced]) | f0[!voiced] == 0))
    })

    test_that(paste0("Intensity matches Praat.app golden (", fixture, ", ", label, ")"), {
      skip_if_not(file.exists(file.path(fixture_dir, paste0(fixture, ".wav"))),
                  "golden fixture missing; run data-raw/generate_simd_goldens.R")

      old <- pladdrr_simd()$enabled
      on.exit(pladdrr_simd(old))
      pladdrr_simd(simd_enabled)

      snd <- Sound(file.path(fixture_dir, paste0(fixture, ".wav")))
      intensity <- snd$to_intensity(100, 0, TRUE)
      golden <- read_golden_intensity(fixture)

      expect_equal(intensity$get_number_of_frames(), nrow(golden))

      db <- vapply(seq_len(nrow(golden)), function(i) {
        t <- intensity$get_time_from_frame(i)
        intensity$get_value_at_time(t, interpolation = "none")
      }, numeric(1))

      expect_equal(db, golden$db, tolerance = 1e-3)
    })
  }
}

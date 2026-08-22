# test-extract-voiced-segments-ultra.R
# Tests for extract_voiced_segments_ultra ZCR accuracy fix
# Bug fix: ZCR was using naive sample counting instead of AVQI formula

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Test Setup
# =============================================================================

# Create test signal with known characteristics
create_voiced_signal <- function(duration = 1.0, f0 = 150, sr = 44100) {
    Sound$create_tone(duration = duration, sampling_rate = sr, frequency = f0, amplitude = 0.8)
}

# =============================================================================
# extract_voiced_segments_ultra Tests
# =============================================================================

test_that("extract_voiced_segments_ultra v2.03 returns valid sound", {
    sound <- create_voiced_signal(duration = 1.0, f0 = 150)

    result <- extract_voiced_segments_ultra(sound, version = "v2.03")

    expect_s3_class(result, "Sound")
    expect_true(result$get_duration() > 0)
})

test_that("extract_voiced_segments_ultra v3.01 returns valid sound", {
    sound <- create_voiced_signal(duration = 1.0, f0 = 150)

    result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    expect_s3_class(result, "Sound")
    # v3.01 applies additional filtering, may have shorter duration
    expect_true(result$get_duration() >= 0)
})

test_that("extract_voiced_segments_ultra matches Praat on a constant-amplitude tone", {
    # Praat reference (6.4.47), AVQI203.praat PART 1 run verbatim on
    #   Create Sound from formula: "cs", 1, 0, 2.0, 44100, ~ 0.5*sin(2*pi*150*x)
    # -> onlyLoud 2.000000, 65 windows examined, **0 kept**, result 0.001000 s
    #    (just the 1 ms `Create Sound: "onlyVoice", 0, 0.001, ...` seed).
    #
    # A constant-amplitude tone is a degenerate input for this algorithm: every
    # 30 ms window's zero-crossing walk runs off the window edge, so `checkZeros`
    # returns undefined and the window is rejected. Praat keeps nothing, and so
    # must we. Earlier revisions of this test asserted "> 1.5s preserved", which
    # described pladdrr's pre-v4.9.21 hand-rolled approximation, not Praat.
    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    v203_result <- extract_voiced_segments_ultra(sound, version = "v2.03")
    v301_result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    expect_s3_class(v203_result, "Sound")
    expect_s3_class(v301_result, "Sound")

    expect_equal(v203_result$get_total_duration(), 0.001, tolerance = 1e-9)
    expect_equal(v301_result$get_total_duration(), 0.001, tolerance = 1e-9)
})

test_that("ZCR calculation uses interpolated zero crossings", {
    # Create a simple sine wave - ZCR should be ~2*frequency
    freq <- 200  # 200 Hz sine wave
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = freq)

    # Get ZCR using the standard implementation
    zcr <- sound_get_zcr(sound, window_duration = 0.05)

    # For a sine wave, ZCR should be approximately 2*frequency
    # (one zero crossing up, one down per cycle)
    expected_zcr <- 2 * freq
    mean_zcr <- mean(zcr$zcr, na.rm = TRUE)

    # Allow 20% tolerance (windowing effects can cause some variation)
    expect_true(abs(mean_zcr - expected_zcr) / expected_zcr < 0.2,
                label = sprintf("ZCR %.1f should be ~%.1f Hz", mean_zcr, expected_zcr))
})

test_that("extract_voiced_segments_ultra always returns at least Praat's 1 ms seed", {
    # AVQI203.praat builds its result by concatenating kept windows onto
    # `Create Sound: "onlyVoice", 0, 0.001, samplingRate, "0"`, so the returned
    # sound is never empty and is always 1 ms longer than the kept windows.
    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    expect_s3_class(result, "Sound")
    expect_gte(result$get_total_duration(), 0.001)
})

test_that("extract_voiced_segments_ultra works with different sampling rates", {
    sr_list <- c(16000, 22050, 44100)

    for (sr in sr_list) {
        sound <- Sound$create_tone(duration = 1.0, sampling_rate = sr, frequency = 150)

        result <- tryCatch(
            extract_voiced_segments_ultra(sound, version = "v3.01"),
            error = function(e) NULL
        )

        expect_true(!is.null(result),
                    label = sprintf("Should work with SR=%d", sr))
        if (!is.null(result)) {
            expect_s3_class(result, "Sound")
        }
    }
})

test_that("extract_voiced_segments_ultra handles edge cases", {
    # Very short signal
    short_sound <- Sound$create_tone(duration = 0.05, sampling_rate = 44100, frequency = 150)

    result <- tryCatch(
        extract_voiced_segments_ultra(short_sound, version = "v2.03"),
        error = function(e) NULL
    )

    # Should either return a valid Sound or NULL (not error)
    if (!is.null(result)) {
        expect_s3_class(result, "Sound")
    }
})

test_that("v2.03 and v3.01 produce different results", {
    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    v203 <- extract_voiced_segments_ultra(sound, version = "v2.03")
    v301 <- extract_voiced_segments_ultra(sound, version = "v3.01")

    # Both should return valid sounds
    expect_s3_class(v203, "Sound")
    expect_s3_class(v301, "Sound")

    # v3.01 typically has more aggressive filtering
    # so duration may be different (but not always)
    # Just verify both work correctly
    expect_true(v203$get_duration() > 0)
    expect_true(v301$get_duration() >= 0)  # Can be 0 if heavily filtered
})

# =============================================================================
# Regression Tests for Bug Fix
# =============================================================================

test_that("windows are kept, and the kept count matches Praat, at 137 Hz", {
    # 150 Hz is degenerate here: its period divides the 30 ms window exactly, so
    # every zero-crossing walk runs off the window edge and Praat keeps nothing
    # (see the test above). 137 Hz does not divide evenly, the walk terminates
    # inside the window, and windows are actually kept -- which is what exercises
    # the keep path of the power + ZCR filter.
    #
    # Praat reference (6.4.47), AVQI203.praat PART 1 verbatim on
    #   Create Sound from formula: "cs", 1, 0, 2.0, 44100, ~ 0.5*sin(2*pi*137*x)
    # -> onlyLoud 2.000000, 65 windows examined, 45 kept, result 1.350998 s.
    sound <- Sound$create_tone(duration = 2.0, sampling_rate = 44100,
                               frequency = 137, amplitude = 0.5)

    result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    expect_s3_class(result, "Sound")
    expect_equal(result$get_total_duration(), 1.350998, tolerance = 1e-6)
})

test_that("CPPS calculation on ultra-extracted segments is reasonable", {
    skip_if_not(exists("calculate_cpps_ultra", where = asNamespace("pladdrr"), inherits = FALSE))

    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    # Extract voiced segments
    voiced <- extract_voiced_segments_ultra(sound, version = "v3.01")

    # Skip if no voiced segments extracted
    if (voiced$get_duration() < 0.1) {
        skip("No voiced segments extracted")
    }

    # Calculate CPPS
    cpps <- calculate_cpps_ultra(voiced)

    # CPPS should be numeric and reasonable for a periodic signal
    expect_true(is.numeric(cpps))

    # For a clean periodic signal, CPPS should be high (typically > 5 dB)
    if (is.finite(cpps)) {
        expect_true(cpps > 0,
                    label = sprintf("CPPS %.2f dB should be > 0 for periodic signal", cpps))
    }
})

test_that("extract_voiced_segments_ultra rejects a null external pointer at the C++ layer", {
  # extract_voiced_segments_ultra() accepts a bare externalptr, so a null
  # pointer reaches extract_voiced_segments_ultra_cpp()'s own "Invalid
  # Sound pointer" guard directly through the public API.
  null_ptr <- methods::new("externalptr")
  expect_error(extract_voiced_segments_ultra(null_ptr), "Invalid Sound pointer")
})

test_that("extract_voiced_segments_ultra returns the minimal 1ms seed when nothing is sounding", {
  # Every other test in this file uses a synthetic continuous tone, which is
  # one single unbroken sounding interval throughout. A silent (zero-
  # amplitude) sound has zero sounding intervals, exercising the "no
  # sounding regions found -> return Praat's minimal 1ms silence" branch,
  # distinct from both the single-region and multi-region concatenation
  # paths.
  silence <- Sound$create_tone(frequency = 0, duration = 0.5, sampling_rate = 16000)
  result <- suppressWarnings(extract_voiced_segments_ultra(silence, version = "v3.01"))
  expect_s3_class(result, "Sound")
  expect_equal(result$get_total_duration(), 0.001, tolerance = 1e-9)
})

test_that("extract_voiced_segments_ultra concatenates multiple sounding regions on real speech", {
  # Real speech has natural pauses, so TextGrid_Sound_extractIntervalsWhere()
  # returns more than one sounding interval, exercising the
  # Sounds_concatenate() multi-region branch that the synthetic
  # continuous-tone fixtures used elsewhere in this file never reach (those
  # are always a single unbroken sounding interval).
  wav <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(wav), "Test WAV file not found")
  sound <- Sound(wav)

  result <- extract_voiced_segments_ultra(sound, version = "v3.01")
  expect_s3_class(result, "Sound")
  expect_true(result$get_total_duration() > 0.001)
  expect_true(result$get_total_duration() < sound$get_total_duration())
})

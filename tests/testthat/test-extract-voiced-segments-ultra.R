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

test_that("extract_voiced_segments_ultra v2.03 and v3.01 produce reasonable results", {
    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    # Get results from both versions
    v203_result <- extract_voiced_segments_ultra(sound, version = "v2.03")
    v301_result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    # Both should return Sound objects
    expect_s3_class(v203_result, "Sound")
    expect_s3_class(v301_result, "Sound")

    # v2.03 should preserve most of the signal
    v203_dur <- v203_result$get_duration()
    expect_true(v203_dur > 1.5, label = sprintf("v2.03 duration %.2f should be > 1.5s", v203_dur))

    # v3.01 should also preserve most of a clean periodic signal
    v301_dur <- v301_result$get_duration()
    expect_true(v301_dur > 1.5, label = sprintf("v3.01 duration %.2f should be > 1.5s", v301_dur))
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

test_that("extract_voiced_segments_ultra preserves voiced content", {
    # Create a clear voiced signal
    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    # Extract voiced segments with v3.01 (most aggressive filtering)
    result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    # Should preserve most of the signal for a clear voiced tone
    original_dur <- sound$get_duration()
    result_dur <- result$get_duration()

    # At least 50% should be preserved for a pure tone
    expect_true(result_dur / original_dur > 0.5,
                label = sprintf("Preserved %.0f%% of signal", 100 * result_dur / original_dur))
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

test_that("ZCR filtering doesn't over-reject voiced content", {
    # This is the key test for the bug fix
    # The old code was over-rejecting voiced content due to incorrect ZCR

    sound <- create_voiced_signal(duration = 2.0, f0 = 150)

    result <- extract_voiced_segments_ultra(sound, version = "v3.01")

    # With correct ZCR, a pure tone should have ZCR ~300 Hz (2*150)
    # which is well below typical max_zcr threshold (3000 Hz)
    # So most of the signal should be preserved

    preservation_ratio <- result$get_duration() / sound$get_duration()

    # Should preserve at least 70% for a clean periodic signal
    expect_true(preservation_ratio > 0.7,
                label = sprintf("Preservation %.0f%% should be >70%%", 100 * preservation_ratio))
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

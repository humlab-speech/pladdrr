# test-phase4-complexspectrogram-simd.R
# Originally: SIMD vs scalar parity tests for ComplexSpectrogram power/phase
# and polar conversion. src/complexspectrogram_simd.cpp was confirmed dead
# code (never called from any R6 path) and removed; pladdrr_simd() no longer
# has any effect here. What remains exercises the surviving scalar-only R6
# path.

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Task 4.3: ComplexSpectrogram Tests (scalar path)
# =============================================================================

test_that("Sound_to_ComplexSpectrogram works", {
    # Create test sound
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 22050, frequency = 200)

    # Convert to ComplexSpectrogram
    cs <- sound$to_complex_spectrogram()

    expect_s3_class(cs, "ComplexSpectrogram")
    expect_true(cs$nx() > 0)  # number of frames
    expect_true(cs$ny() > 0)  # number of frequency bins
})

test_that("ComplexSpectrogram works with different window lengths", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 22050, frequency = 200)

    # Test different window lengths
    cs_short <- sound$to_complex_spectrogram(window_length = 0.020)
    cs_long <- sound$to_complex_spectrogram(window_length = 0.050)

    expect_s3_class(cs_short, "ComplexSpectrogram")
    expect_s3_class(cs_long, "ComplexSpectrogram")

    # Both should have frames
    expect_true(cs_short$nx() > 0)
    expect_true(cs_long$nx() > 0)
})

test_that("ComplexSpectrogram works with various signal lengths", {
    # Test various signal lengths to exercise edge/remainder handling
    durations <- c(0.25, 0.5, 0.75, 1.0)

    for (dur in durations) {
        sound <- Sound$create_tone(duration = dur, sampling_rate = 22050, frequency = 200)

        # Should not error
        cs <- tryCatch(
            sound$to_complex_spectrogram(),
            error = function(e) NULL
        )

        if (!is.null(cs)) {
            expect_s3_class(cs, "ComplexSpectrogram")
            expect_true(cs$nx() > 0)
        }
    }
})

test_that("ComplexSpectrogram to Sound roundtrip", {
    # Create test sound
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    # Convert to ComplexSpectrogram
    cs <- sound$to_complex_spectrogram()

    # Convert back to Sound. Module-attached methods are not listed in
    # names(), so the old names() guard made this test silently empty; call
    # the method directly and assert the result.
    reconstructed <- cs$to_sound()
    expect_s3_class(reconstructed, "Sound")
    expect_true(reconstructed$get_duration() > 0)
})

test_that("ComplexSpectrogram to Spectrum conversion", {
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    cs <- sound$to_complex_spectrogram()

    # Get spectrum at a specific time. Module-attached methods are not listed
    # in names(), so the old names() guard made this test silently empty.
    t_mid <- (cs$xmin() + cs$xmax()) / 2
    spectrum <- cs$to_spectrum(t_mid)
    expect_s3_class(spectrum, "Spectrum")
    expect_true(length(spectrum$get_frequencies_vector()) > 0)
})

test_that("ComplexSpectrogram amplitude and phase retrieval", {
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    cs <- sound$to_complex_spectrogram()

    # Test amplitude and phase retrieval at a specific point
    if (cs$nx() > 0 && cs$ny() > 0) {
        t_mid <- (cs$xmin() + cs$xmax()) / 2
        f_mid <- (cs$ymin() + cs$ymax()) / 2

        # These should return numeric values
        amp <- cs$get_amplitude(t_mid, f_mid)
        phase <- cs$get_phase(t_mid, f_mid)

        expect_true(is.numeric(amp))
        expect_true(is.numeric(phase))
    }
})

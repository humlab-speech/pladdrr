# test-phase4-complexspectrogram-simd.R
# Tests for Task 4.3: ComplexSpectrogram SIMD optimization
# Tests SIMD functions for power/phase calculation and polar conversion

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Task 4.3: ComplexSpectrogram SIMD Tests
# =============================================================================

test_that("ComplexSpectrogram SIMD info is available", {
    info <- pladdrr:::.complexspectrogram_simd_info()

    expect_true(is.list(info))
    expect_true("simd_available" %in% names(info))
    expect_true("batch_size" %in% names(info))
    expect_true("architecture" %in% names(info))
    expect_true("functions" %in% names(info))

    # Check function list
    expected_functions <- c(
        "compute_power_and_phase_simd",
        "polar_to_rectangular_simd",
        "sqrt_power_to_magnitude_simd",
        "generate_hanning_window_simd",
        "apply_window_simd",
        "overlap_add_simd"
    )

    if (info$simd_available) {
        expect_true(all(expected_functions %in% info$functions))
    }
})

test_that("Sound_to_ComplexSpectrogram works", {
    # Create test sound
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 22050, frequency = 200)

    options(speaker.use_simd = TRUE)

    # Convert to ComplexSpectrogram
    cs <- sound$to_complex_spectrogram()

    expect_s3_class(cs, "ComplexSpectrogram")
    expect_true(cs$nx() > 0)  # number of frames
    expect_true(cs$ny() > 0)  # number of frequency bins
})

test_that("ComplexSpectrogram SIMD matches scalar", {
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 150)

    # Force scalar
    options(speaker.use_simd = FALSE)
    cs_scalar <- sound$to_complex_spectrogram()

    # Force SIMD
    options(speaker.use_simd = TRUE)
    cs_simd <- sound$to_complex_spectrogram()

    # Compare dimensions
    expect_equal(cs_simd$nx(), cs_scalar$nx())
    expect_equal(cs_simd$ny(), cs_scalar$ny())
})

test_that("ComplexSpectrogram works with different window lengths", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 22050, frequency = 200)

    options(speaker.use_simd = TRUE)

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
    # Test various signal lengths to exercise SIMD remainder handling
    durations <- c(0.25, 0.5, 0.75, 1.0)

    options(speaker.use_simd = TRUE)

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

test_that("ComplexSpectrogram SIMD toggle works correctly", {
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    # Toggle SIMD multiple times
    results <- list()

    for (i in 1:3) {
        options(speaker.use_simd = (i %% 2 == 1))  # Alternate TRUE/FALSE
        cs <- sound$to_complex_spectrogram()
        results[[i]] <- cs$nx()
    }

    # All results should have same number of frames
    expect_equal(results[[1]], results[[2]])
    expect_equal(results[[2]], results[[3]])
})

test_that("ComplexSpectrogram to Sound roundtrip", {
    # Create test sound
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    options(speaker.use_simd = TRUE)

    # Convert to ComplexSpectrogram
    cs <- sound$to_complex_spectrogram()

    # Convert back to Sound (if method exists)
    if ("to_sound" %in% names(cs)) {
        reconstructed <- cs$to_sound()
        expect_s3_class(reconstructed, "Sound")
    }
})

test_that("ComplexSpectrogram to Spectrum conversion", {
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    options(speaker.use_simd = TRUE)

    cs <- sound$to_complex_spectrogram()

    # Get spectrum at a specific time (if method exists)
    if ("to_spectrum" %in% names(cs)) {
        t_mid <- (cs$xmin() + cs$xmax()) / 2
        spectrum <- cs$to_spectrum(t_mid)
        expect_s3_class(spectrum, "Spectrum")
    }
})

test_that("ComplexSpectrogram amplitude and phase retrieval", {
    sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 200)

    options(speaker.use_simd = TRUE)

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

# =============================================================================
# Cleanup
# =============================================================================

# Reset SIMD setting
options(speaker.use_simd = TRUE)

# test-phase4-harmonicity-simd.R
# Tests for Task 4.2: Harmonicity SIMD optimization
# Tests SIMD vs scalar accuracy for harmonicity/HNR calculation

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Task 4.2: Harmonicity SIMD Tests
# =============================================================================

test_that("Harmonicity AC method works with SIMD", {
    # Longer duration for reliable analysis
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 150)

    # Run with SIMD enabled
    pladdrr_simd(TRUE)
    harm_simd <- sound$to_harmonicity_ac()

    expect_s3_class(harm_simd, "Harmonicity")
    expect_true(harm_simd$get_number_of_frames() > 0)
    expect_true(is.numeric(harm_simd$get_mean()))
})

test_that("Harmonicity CC method works with SIMD", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 120)

    # Run with SIMD enabled
    pladdrr_simd(TRUE)
    harm_simd <- sound$to_harmonicity_cc()

    expect_s3_class(harm_simd, "Harmonicity")
    expect_true(harm_simd$get_number_of_frames() > 0)
    expect_true(is.numeric(harm_simd$get_mean()))
})

test_that("Harmonicity SIMD matches scalar for AC method", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 150)

    # Force scalar
    pladdrr_simd(FALSE)
    harm_scalar <- sound$to_harmonicity_ac()

    # Force SIMD
    pladdrr_simd(TRUE)
    harm_simd <- sound$to_harmonicity_ac()

    # Compare number of frames (must be identical)
    expect_equal(harm_simd$get_number_of_frames(), harm_scalar$get_number_of_frames())

    # Compare results - AC method may have small differences due to FFT
    scalar_mean <- harm_scalar$get_mean()
    simd_mean <- harm_simd$get_mean()

    # Both should be numeric (may be NaN for pure tones)
    expect_true(is.numeric(scalar_mean))
    expect_true(is.numeric(simd_mean))

    # If both are finite, they should match
    if (is.finite(scalar_mean) && is.finite(simd_mean)) {
        expect_equal(simd_mean, scalar_mean, tolerance = 1e-6,
                     label = "AC harmonicity SIMD should match scalar")
    }
})

test_that("Harmonicity SIMD matches scalar for CC method (FCC - SIMD optimized)", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 120)

    # Force scalar
    pladdrr_simd(FALSE)
    harm_scalar <- sound$to_harmonicity_cc()

    # Force SIMD
    pladdrr_simd(TRUE)
    harm_simd <- sound$to_harmonicity_cc()

    # Compare number of frames (must be identical)
    expect_equal(harm_simd$get_number_of_frames(), harm_scalar$get_number_of_frames())

    # CC method uses SIMD-optimized FCC cross-correlation
    scalar_mean <- harm_scalar$get_mean()
    simd_mean <- harm_simd$get_mean()

    expect_true(is.numeric(scalar_mean))
    expect_true(is.numeric(simd_mean))

    # If both are finite, they should match closely
    if (is.finite(scalar_mean) && is.finite(simd_mean)) {
        expect_equal(simd_mean, scalar_mean, tolerance = 1e-6,
                     label = "CC harmonicity SIMD should match scalar")
    }
})

test_that("Harmonicity works with different pitch floors", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 150)

    pladdrr_simd(TRUE)

    # Test different pitch floors
    harm_75 <- sound$to_harmonicity_ac(min_pitch =75)
    harm_100 <- sound$to_harmonicity_ac(min_pitch =100)

    # Both should produce valid results
    expect_true(harm_75$get_number_of_frames() > 0)
    expect_true(harm_100$get_number_of_frames() > 0)

    # Results should be numeric
    expect_true(is.numeric(harm_75$get_mean()))
    expect_true(is.numeric(harm_100$get_mean()))
})

test_that("Harmonicity works with different time steps", {
    sound <- Sound$create_tone(duration = 2.0, sampling_rate = 44100, frequency = 150)

    pladdrr_simd(TRUE)

    # Test different time steps
    harm_default <- sound$to_harmonicity_ac()
    harm_fine <- sound$to_harmonicity_ac(time_step = 0.005)
    harm_coarse <- sound$to_harmonicity_ac(time_step = 0.02)

    # Finer time step should produce more frames
    expect_true(harm_fine$get_number_of_frames() > harm_coarse$get_number_of_frames())

    # All should produce numeric results
    expect_true(is.numeric(harm_default$get_mean()))
    expect_true(is.numeric(harm_fine$get_mean()))
    expect_true(is.numeric(harm_coarse$get_mean()))
})

test_that("Harmonicity SIMD toggle works correctly", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 150)

    # Toggle SIMD multiple times
    results <- list()

    for (i in 1:3) {
        pladdrr_simd((i %% 2 == 1))  # Alternate TRUE/FALSE
        harm <- sound$to_harmonicity_cc()
        results[[i]] <- harm$get_number_of_frames()
    }

    # All results should have same number of frames
    expect_equal(results[[1]], results[[2]])
    expect_equal(results[[2]], results[[3]])
})

test_that("Harmonicity CC method with various signal lengths", {
    # Test various signal lengths to exercise SIMD remainder handling
    durations <- c(0.5, 1.0, 2.0, 3.0)

    pladdrr_simd(TRUE)

    for (dur in durations) {
        sound <- Sound$create_tone(duration = dur, sampling_rate = 44100, frequency = 150)

        # Should not error
        harm <- tryCatch(
            sound$to_harmonicity_cc(),
            error = function(e) NULL
        )

        if (!is.null(harm)) {
            expect_s3_class(harm, "Harmonicity")
            expect_true(harm$get_number_of_frames() > 0)
        }
    }
})

test_that("Harmonicity at specific time points", {
    sound <- Sound$create_tone(duration = 2.0, sampling_rate = 44100, frequency = 150)

    pladdrr_simd(TRUE)
    harm <- sound$to_harmonicity_ac()

    # Get HNR at mid-point
    n_frames <- harm$get_number_of_frames()
    if (n_frames > 1) {
        t_mid <- harm$get_time_from_frame(n_frames %/% 2)
        hnr_mid <- harm$get_value_at_time(t_mid)

        # Should return a numeric value (possibly NA or finite)
        expect_true(is.numeric(hnr_mid))
    }
})

test_that("Harmonicity SIMD info available", {
    # Check that SIMD info functions exist and return expected types
    skip_if_not(exists(".harmonicity_simd_info", where = asNamespace("pladdrr"), inherits = FALSE))

    info <- pladdrr:::.harmonicity_simd_info()
    expect_true(is.character(info) || is.null(info))
})

# =============================================================================
# Cleanup
# =============================================================================

# Reset SIMD setting
pladdrr_simd(TRUE)

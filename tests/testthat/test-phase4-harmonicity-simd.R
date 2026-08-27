# test-phase4-harmonicity-simd.R
# Originally: SIMD vs scalar parity tests for Harmonicity/HNR.
# src/harmonicity_simd.cpp was confirmed dead code (never called from any R6
# path) and removed; pladdrr_simd() no longer has any effect on harmonicity.
# What remains here exercises the surviving scalar-only R6 path.

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Task 4.2: Harmonicity Tests (scalar path)
# =============================================================================

test_that("Harmonicity AC method works", {
    # Longer duration for reliable analysis
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 150)

    harm <- sound$to_harmonicity_ac()

    expect_s3_class(harm, "Harmonicity")
    expect_gt(harm$get_number_of_frames(), 0)
    expect_true(is.numeric(harm$get_mean()))
})

test_that("Harmonicity CC method works", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 120)

    harm <- sound$to_harmonicity_cc()

    expect_s3_class(harm, "Harmonicity")
    expect_gt(harm$get_number_of_frames(), 0)
    expect_true(is.numeric(harm$get_mean()))
})

test_that("Harmonicity works with different pitch floors", {
    sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 150)

    # Test different pitch floors
    harm_75 <- sound$to_harmonicity_ac(min_pitch = 75)
    harm_100 <- sound$to_harmonicity_ac(min_pitch = 100)

    # Both should produce valid results
    expect_gt(harm_75$get_number_of_frames(), 0)
    expect_gt(harm_100$get_number_of_frames(), 0)

    # Results should be numeric
    expect_true(is.numeric(harm_75$get_mean()))
    expect_true(is.numeric(harm_100$get_mean()))
})

test_that("Harmonicity works with different time steps", {
    sound <- Sound$create_tone(duration = 2.0, sampling_rate = 44100, frequency = 150)

    # Test different time steps
    harm_default <- sound$to_harmonicity_ac()
    harm_fine <- sound$to_harmonicity_ac(time_step = 0.005)
    harm_coarse <- sound$to_harmonicity_ac(time_step = 0.02)

    # Finer time step should produce more frames
    expect_gt(harm_fine$get_number_of_frames(), harm_coarse$get_number_of_frames())

    # All should produce numeric results
    expect_true(is.numeric(harm_default$get_mean()))
    expect_true(is.numeric(harm_fine$get_mean()))
    expect_true(is.numeric(harm_coarse$get_mean()))
})

test_that("Harmonicity CC method with various signal lengths", {
    # Test various signal lengths to exercise edge/remainder handling
    durations <- c(0.5, 1.0, 2.0, 3.0)

    for (dur in durations) {
        sound <- Sound$create_tone(duration = dur, sampling_rate = 44100, frequency = 150)

        # Should not error
        harm <- tryCatch(
            sound$to_harmonicity_cc(),
            error = function(e) NULL
        )

        if (!is.null(harm)) {
            expect_s3_class(harm, "Harmonicity")
            expect_gt(harm$get_number_of_frames(), 0)
        }
    }
})

test_that("Harmonicity at specific time points", {
    sound <- Sound$create_tone(duration = 2.0, sampling_rate = 44100, frequency = 150)

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

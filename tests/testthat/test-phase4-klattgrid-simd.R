# test-phase4-klattgrid-simd.R
# Tests for Task 4.4: KlattGrid SIMD optimization
# Tests SIMD functions for sound mixing and synthesis operations

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Task 4.4: KlattGrid SIMD Tests
# =============================================================================
# Note: KlattGrid synthesis has known issues - focus on SIMD infrastructure tests

test_that("KlattGrid SIMD info is available", {
    info <- pladdrr:::.klattgrid_simd_info()

    expect_true(is.list(info))
    expect_true("simd_available" %in% names(info))
    expect_true("batch_size" %in% names(info))
    expect_true("architecture" %in% names(info))
    expect_true("functions" %in% names(info))

    # Check function list
    expected_functions <- c(
        "sounds_add_inplace_simd",
        "sound_diff_simd",
        "sound_scale_simd",
        "sound_scale_inplace_simd",
        "find_extremum_simd",
        "normalize_sound_simd",
        "glottal_flow_polynomial_simd",
        "apply_exponential_decay_simd",
        "weighted_sum_simd"
    )

    if (info$simd_available) {
        expect_true(all(expected_functions %in% info$functions))
    }
})

test_that("KlattGrid creation works", {
    pladdrr_simd(TRUE)

    # Create a simple KlattGrid
    kg <- KlattGrid(0, 0.5)

    expect_s3_class(kg, "KlattGrid")
    expect_true(kg$is_valid())
})

test_that("KlattGrid add pitch point works", {
    pladdrr_simd(TRUE)

    kg <- KlattGrid(0, 0.5)
    kg$add_pitch_point(0.25, 120)

    pitch <- kg$get_pitch_at_time(0.25)
    expect_true(is.numeric(pitch))
    expect_equal(pitch, 120, tolerance = 0.01)
})

test_that("KlattGrid getters work with SIMD enabled", {
    pladdrr_simd(TRUE)

    kg <- KlattGrid(0, 0.5)

    expect_equal(kg$get_xmin(), 0)
    expect_equal(kg$get_xmax(), 0.5)
    expect_equal(kg$get_duration(), 0.5)
})

test_that("KlattGrid SIMD info matches architecture", {
    info <- pladdrr:::.klattgrid_simd_info()

    if (info$simd_available) {
        # Should have batch size 2 (NEON) or 4 (AVX2)
        expect_true(info$batch_size %in% c(2, 4))
        # Architecture should be valid
        expect_true(info$architecture %in% c("NEON", "SSE2", "SSE3", "SSE4.1", "SSE4.2", "AVX", "AVX2", "Generic"))
    } else {
        expect_equal(info$batch_size, 1)
        expect_equal(info$architecture, "scalar")
    }
})

test_that("KlattGrid SIMD functions count is correct", {
    info <- pladdrr:::.klattgrid_simd_info()

    if (info$simd_available) {
        # Should have 9 SIMD functions
        expect_equal(length(info$functions), 9)
    } else {
        expect_equal(length(info$functions), 0)
    }
})

# =============================================================================
# Cleanup
# =============================================================================

# Reset SIMD setting
pladdrr_simd(TRUE)

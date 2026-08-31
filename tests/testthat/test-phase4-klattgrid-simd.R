# test-phase4-klattgrid-simd.R
# Originally: SIMD infrastructure tests for KlattGrid sound mixing/synthesis
# helpers. src/klattgrid_simd.cpp was confirmed dead code (never called from
# any R6 path) and removed; pladdrr_simd() no longer has any effect here.
# What remains exercises the surviving scalar-only R6 KlattGrid path.

library(testthat)
library(pladdrr)

# Skip if package not available
if (!requireNamespace("pladdrr", quietly = TRUE)) {
    skip("pladdrr package not available")
}

# =============================================================================
# Task 4.4: KlattGrid Tests (scalar path)
# =============================================================================
# Note: KlattGrid synthesis has known issues - focus on basic R6 API

test_that("KlattGrid creation works", {
    # Create a simple KlattGrid
    kg <- KlattGrid(0, 0.5)

    expect_s3_class(kg, "KlattGrid")
    expect_true(kg$is_valid())
})

test_that("KlattGrid add pitch point works", {
    kg <- KlattGrid(0, 0.5)
    kg$add_pitch_point(0.25, 120)

    pitch <- kg$get_pitch_at_time(0.25)
    expect_true(is.numeric(pitch))
    expect_equal(pitch, 120, tolerance = 0.01)
})

test_that("KlattGrid getters work", {
    kg <- KlattGrid(0, 0.5)

    expect_equal(kg$get_xmin(), 0, tolerance = sqrt(.Machine$double.eps))
    expect_equal(kg$get_xmax(), 0.5)
    expect_equal(kg$get_duration(), 0.5)
})

# Extracted from test-cochleagram-r6.R:95

# test -------------------------------------------------------------------------
sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.2)
result <- cochlea$as_matrix()
expect_type(result, "list")
expect_true("values" %in% names(result))
expect_true(is.matrix(result$values))

# Extracted from test-cochleagram-r6.R:93

# test -------------------------------------------------------------------------
sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
cochlea <- sound$to_cochleagram(dt = 0.01, df = 0.2)
result <- cochlea$as_matrix()
expect_type(result, "list")

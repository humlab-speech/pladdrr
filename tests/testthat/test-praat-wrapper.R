test_that("praat_version returns a string", {
    version <- praat_version()
    expect_type(version, "character")
    expect_true(nchar(version) > 0)
})

test_that("sound_stats calculates correct statistics", {
    test_data <- c(1, 2, 3, 4, 5)
    stats <- sound_stats(test_data)
    
    expect_type(stats, "list")
    expect_equal(stats$mean, 3)
    expect_equal(stats$min, 1)
    expect_equal(stats$max, 5)
    expect_equal(stats$length, 5)
})

test_that("create_sound creates valid sound object", {
    values <- c(0.1, 0.2, 0.3, 0.4)
    freq <- 44100
    sound <- create_sound(values, freq)
    
    expect_type(sound, "list")
    expect_equal(sound$sampling_frequency, freq)
    expect_equal(sound$n_samples, 4)
    expect_s3_class(sound, "PraatSound")
    expect_true(sound$duration > 0)
})

test_that("get_sound_duration returns correct duration", {
    values <- seq(0, 1, length.out = 44100)
    sound <- create_sound(values, 44100)
    duration <- get_sound_duration(sound)
    
    expect_type(duration, "double")
    expect_true(duration > 0.99 && duration < 1.01)  # approximately 1 second
})

test_that("generate_sine_wave creates valid sine wave", {
    sound <- generate_sine_wave(440, 0.5, 44100)
    
    expect_true(is_praat_sound(sound))
    expect_equal(sound$sampling_frequency, 44100)
    expect_true(abs(get_sound_duration(sound) - 0.5) < 0.01)
})

test_that("is_praat_sound identifies sound objects correctly", {
    sound <- generate_sine_wave(440, 0.1)
    expect_true(is_praat_sound(sound))
    
    not_sound <- list(a = 1, b = 2)
    expect_false(is_praat_sound(not_sound))
})

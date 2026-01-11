test_that("TextGrid can be read from file", {
library(data.table)
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  expect_s3_class(tg, "TextGrid")
  expect_s3_class(tg, "PraatObject")
  expect_s3_class(tg, "R6")
})

test_that("TextGrid basic properties are correct", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Time properties
  expect_equal(tg$get_start_time(), 0)
  expect_equal(tg$get_end_time(), 3)
  expect_equal(tg$get_total_duration(), 3)
})

test_that("TextGrid tier properties are correct", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Tier count and names
  expect_equal(tg$get_number_of_tiers(), 3)
  tier_names <- tg$get_tier_names()
  expect_equal(length(tier_names), 3)
  expect_equal(tier_names[1], "words")
  expect_equal(tier_names[2], "phones")
  expect_equal(tier_names[3], "tones")
})

test_that("TextGrid can identify tier types", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Check tier types
  expect_true(tg$tier_is_interval_tier(1))
  expect_false(tg$tier_is_point_tier(1))
  
  expect_true(tg$tier_is_interval_tier("words"))
  expect_false(tg$tier_is_point_tier("words"))
  
  expect_true(tg$tier_is_interval_tier("phones"))
  expect_false(tg$tier_is_point_tier("phones"))
  
  expect_false(tg$tier_is_interval_tier("tones"))
  expect_true(tg$tier_is_point_tier("tones"))
})

test_that("TextGrid interval tier queries work", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Number of intervals
  expect_equal(tg$get_number_of_intervals("words"), 4)
  expect_equal(tg$get_number_of_intervals("phones"), 7)
  
  # Interval times
  expect_equal(tg$get_interval_start_time("words", 2), 0.5)
  expect_equal(tg$get_interval_end_time("words", 2), 1.5)
  
  # Interval text
  expect_equal(tg$get_interval_text("words", 2), "hello")
  expect_equal(tg$get_interval_text("words", 3), "world")
  
  # Empty intervals
  expect_equal(tg$get_interval_text("words", 1), "")
  expect_equal(tg$get_interval_text("words", 4), "")
})

test_that("TextGrid can get interval at time", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Get interval number at various times
  expect_equal(tg$get_interval_at_time("words", 0.2), 1)
  expect_equal(tg$get_interval_at_time("words", 1.0), 2)
  expect_equal(tg$get_interval_at_time("words", 2.0), 3)
  expect_equal(tg$get_interval_at_time("words", 2.8), 4)
})

test_that("TextGrid can get label at time", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Get label at various times
  expect_equal(tg$get_label_at_time("words", 0.2), "")
  expect_equal(tg$get_label_at_time("words", 1.0), "hello")
  expect_equal(tg$get_label_at_time("words", 2.0), "world")
  expect_equal(tg$get_label_at_time("words", 2.8), "")
  
  # Phone tier
  expect_equal(tg$get_label_at_time("phones", 0.6), "h")
  expect_equal(tg$get_label_at_time("phones", 1.0), "ɛ")
  expect_equal(tg$get_label_at_time("phones", 1.7), "w")
})

test_that("TextGrid point tier queries work", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Number of points
  expect_equal(tg$get_number_of_points("tones"), 2)
  
  # Point times
  expect_equal(tg$get_point_time("tones", 1), 1.0)
  expect_equal(tg$get_point_time("tones", 2), 2.2)
  
  # Point text
  expect_equal(tg$get_point_text("tones", 1), "H*")
  expect_equal(tg$get_point_text("tones", 2), "L-L%")
})

test_that("TextGrid can export to data frame", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Export all tiers
  df <- tg$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true("tier_name" %in% names(df))
  expect_true("tier_number" %in% names(df))
  expect_true("label" %in% names(df) || "text" %in% names(df))
  
  # Export specific tier
  df_words <- tg$as_data_frame(tiers = "words")
  expect_s3_class(df_words, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true(all(df_words$tier_name == "words"))
})

test_that("TextGrid can modify interval labels", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Modify interval text
  tg$set_interval_text("words", 2, "hi")
  expect_equal(tg$get_interval_text("words", 2), "hi")
  
  # Restore original
  tg$set_interval_text("words", 2, "hello")
  expect_equal(tg$get_interval_text("words", 2), "hello")
})

test_that("TextGrid can insert and remove boundaries", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Get initial interval count
  initial_count <- tg$get_number_of_intervals("words")
  
  # Insert boundary
  tg$insert_boundary("words", 1.0)
  expect_equal(tg$get_number_of_intervals("words"), initial_count + 1)
  
  # Remove boundary  
  tg$remove_boundary("words", 1.0)
  expect_equal(tg$get_number_of_intervals("words"), initial_count)
})

test_that("TextGrid can save to file", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Save to temporary file
  temp_file <- tempfile(fileext = ".TextGrid")
  tg$save(temp_file)
  
  # Verify file was created
  expect_true(file.exists(temp_file))
  
  # Read it back and verify
  tg2 <- TextGrid$new(temp_file)
  expect_equal(tg2$get_number_of_tiers(), 3)
  expect_equal(tg2$get_tier_names(), c("words", "phones", "tones"))
  
  # Clean up
  unlink(temp_file)
})

test_that("TextGrid can be created programmatically", {
  skip_on_cran()
  
  # Create empty TextGrid
  tg <- TextGrid$create(0, 5, tier_names = "segments", point_tiers = "events")
  
  expect_s3_class(tg, "TextGrid")
  expect_equal(tg$get_start_time(), 0)
  expect_equal(tg$get_end_time(), 5)
  expect_equal(tg$get_number_of_tiers(), 2)
})

test_that("TextGrid handles tier name/number conversion", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Both tier number and name should work
  expect_equal(tg$get_number_of_intervals(1), tg$get_number_of_intervals("words"))
  expect_equal(tg$get_interval_text(1, 2), tg$get_interval_text("words", 2))
  expect_equal(tg$tier_is_interval_tier(1), tg$tier_is_interval_tier("words"))
})

test_that("TextGrid handles errors gracefully", {
  skip_if_not(file.exists(system.file("extdata", "test.TextGrid", package = "speaker")),
              "Test TextGrid file not found")
  
  tg <- TextGrid$new(system.file("extdata", "test.TextGrid", package = "speaker"))
  
  # Invalid tier number
  expect_error(tg$get_number_of_intervals(99))
  
  # Invalid tier name
  expect_error(tg$get_number_of_intervals("nonexistent"))
  
  # Invalid interval number
  expect_error(tg$get_interval_text("words", 999))
  
  # Invalid point number
  expect_error(tg$get_point_text("tones", 999))
})

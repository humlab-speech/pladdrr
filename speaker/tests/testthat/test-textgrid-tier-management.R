# Test TextGrid tier management methods
# These tests verify the new duplicate_tier() and set_tier_name() methods

library(testthat)
library(speaker)

test_that("set_tier_name() works with tier number", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones", point_tiers = "")
  
  # Change tier name
  tg$set_tier_name(1, "WORDS")
  
  # Verify
  expect_equal(tg$get_tier_name(1), "WORDS")
  expect_equal(tg$get_tier_names(), c("WORDS", "phones"))
})

test_that("set_tier_name() works with tier name", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones", point_tiers = "")
  
  # Change tier name using name instead of number
  tg$set_tier_name("phones", "PHONES")
  
  # Verify
  expect_equal(tg$get_tier_name(2), "PHONES")
  expect_equal(tg$get_tier_names(), c("words", "PHONES"))
})

test_that("duplicate_tier() works for IntervalTier", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words", point_tiers = "")
  
  # Add some data
  tg$insert_boundary(1, 0.5)
  tg$set_interval_text(1, 1, "hello")
  tg$set_interval_text(1, 2, "world")
  
  # Duplicate
  tg$duplicate_tier(1, "words_copy")
  
  # Verify structure
  expect_equal(tg$get_number_of_tiers(), 2)
  expect_equal(tg$get_tier_names(), c("words", "words_copy"))
  
  # Verify both tiers have same number of intervals
  expect_equal(tg$get_number_of_intervals(1), tg$get_number_of_intervals(2))
  
  # Verify labels are copied
  expect_equal(tg$get_interval_text(2, 1), "hello")
  expect_equal(tg$get_interval_text(2, 2), "world")
})

test_that("duplicate_tier() works for PointTier", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "", point_tiers = "events")
  
  # Add some points
  tg$insert_point(1, 0.3, "tone1")
  tg$insert_point(1, 0.7, "tone2")
  
  # Duplicate
  tg$duplicate_tier(1, "events_copy")
  
  # Verify structure
  expect_equal(tg$get_number_of_tiers(), 2)
  expect_equal(tg$get_tier_names(), c("events", "events_copy"))
  
  # Verify both tiers have same number of points
  expect_equal(tg$get_number_of_points(1), tg$get_number_of_points(2))
  
  # Verify marks are copied
  expect_equal(tg$get_point_text(2, 1), "tone1")
  expect_equal(tg$get_point_text(2, 2), "tone2")
})

test_that("duplicate_tier() works with tier name", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words", point_tiers = "")
  
  # Duplicate using tier name
  tg$duplicate_tier("words", "words_backup")
  
  expect_equal(tg$get_number_of_tiers(), 2)
  expect_true("words_backup" %in% tg$get_tier_names())
})

test_that("Method chaining works with new methods", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "tier1", point_tiers = "")
  
  # Chain operations
  result <- tg$
    set_tier_name(1, "renamed")$
    duplicate_tier(1, "copy")$
    add_point_tier("events")
  
  # Verify chaining returned self
  expect_s3_class(result, "TextGrid")
  expect_identical(result, tg)
  
  # Verify operations were applied
  expect_equal(tg$get_number_of_tiers(), 3)
  expect_equal(tg$get_tier_names(), c("renamed", "copy", "events"))
})

test_that("duplicate_tier() creates independent copy", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words", point_tiers = "")
  
  tg$insert_boundary(1, 0.5)
  tg$set_interval_text(1, 1, "original")
  
  tg$duplicate_tier(1, "copy")
  
  # Modify original
  tg$set_interval_text(1, 1, "modified")
  
  # Verify copy is unchanged
  expect_equal(tg$get_interval_text(1, 1), "modified")
  expect_equal(tg$get_interval_text(2, 1), "original")
})

test_that("Error handling for invalid tier", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "tier1", point_tiers = "")
  
  # Out of range tier number
  expect_error(tg$set_tier_name(999, "new"), "out of range|not found")
  expect_error(tg$duplicate_tier(999, "copy"), "out of range|not found")
  
  # Non-existent tier name
  expect_error(tg$set_tier_name("nonexistent", "new"), "not found|does not exist")
  expect_error(tg$duplicate_tier("nonexistent", "copy"), "not found|does not exist")
})

test_that("Integration with existing benchmark TextGrid", {
  skip_if_not(file.exists("inst/extdata/benchmarkdata60min.TextGrid"),
              "Benchmark TextGrid file not found")
  
  tg <- TextGrid$new("inst/extdata/benchmarkdata60min.TextGrid")
  
  initial_tiers <- tg$get_number_of_tiers()
  initial_names <- tg$get_tier_names()
  
  # Rename first tier
  tg$set_tier_name(1, "TIER1_RENAMED")
  expect_equal(tg$get_tier_name(1), "TIER1_RENAMED")
  
  # Duplicate first tier
  tg$duplicate_tier(1, "TIER1_COPY")
  expect_equal(tg$get_number_of_tiers(), initial_tiers + 1)
  expect_true("TIER1_COPY" %in% tg$get_tier_names())
  
  # Verify original tier count can be restored
  tg$remove_tier("TIER1_COPY")
  expect_equal(tg$get_number_of_tiers(), initial_tiers)
})

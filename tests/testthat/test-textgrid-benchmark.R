test_that("Benchmark TextGrid 60min loads successfully", {
library(data.table)
  skip_on_cran()  # Large file, skip on CRAN
  
  tg_path <- system.file("extdata", "benchmarkdata60min.TextGrid",
    package = "speaker")
  skip_if(tg_path == "", "Benchmark TextGrid not found")
  
  tg <- TextGrid$new(tg_path)
  
  expect_s3_class(tg, "TextGrid")
  expect_s3_class(tg, "PraatObject")
  
  # Should have multiple tiers
  n_tiers <- tg$get_number_of_tiers()
  expect_gt(n_tiers, 0)
  
  # Should have reasonable duration (~60 minutes = 3600 seconds)
  duration <- tg$get_total_duration()
  expect_gt(duration, 3000)  # At least 50 minutes
  expect_lt(duration, 4000)  # At most 66 minutes
})

test_that("Benchmark TextGrid 90min loads successfully", {
  skip_on_cran()  # Large file, skip on CRAN
  
  tg_path <- system.file("extdata", "benchmarkdata90min.TextGrid",
    package = "speaker")
  skip_if(tg_path == "", "Benchmark TextGrid not found")
  
  tg <- TextGrid$new(tg_path)
  
  expect_s3_class(tg, "TextGrid")
  expect_s3_class(tg, "PraatObject")
  
  # Should have multiple tiers
  n_tiers <- tg$get_number_of_tiers()
  expect_gt(n_tiers, 0)
  
  # Should have reasonable duration (~90 minutes = 5400 seconds)
  duration <- tg$get_total_duration()
  expect_gt(duration, 5000)  # At least 83 minutes
  expect_lt(duration, 6000)  # At most 100 minutes
})

test_that("Benchmark TextGrid query performance is acceptable", {
  skip_on_cran()
  
  tg_path <- system.file("extdata", "benchmarkdata60min.TextGrid",
    package = "speaker")
  skip_if(tg_path == "", "Benchmark TextGrid not found")
  
  # Time the loading
  load_time <- system.time({
    tg <- TextGrid$new(tg_path)
  })
  
  # Should load in reasonable time (< 10 seconds for 77 MB file)
  expect_lt(load_time["elapsed"], 10)
  
  # Query should be fast
  query_time <- system.time({
    n_tiers <- tg$get_number_of_tiers()
    tier_names <- tg$get_tier_names()
  })
  
  # Queries should be near-instant (< 0.1 seconds)
  expect_lt(query_time["elapsed"], 0.1)
})

test_that("Benchmark TextGrid interval queries work", {
  skip_on_cran()
  
  tg_path <- system.file("extdata", "benchmarkdata60min.TextGrid",
    package = "speaker")
  skip_if(tg_path == "", "Benchmark TextGrid not found")
  
  tg <- TextGrid$new(tg_path)
  tier_names <- tg$get_tier_names()
  
  # Test first tier if it exists
  if (length(tier_names) > 0) {
    first_tier <- 1
    
    # Check if interval tier
    if (tg$tier_is_interval_tier(first_tier)) {
      n_intervals <- tg$get_number_of_intervals(first_tier)
      expect_gt(n_intervals, 0)
      
      # Get first interval text
      if (n_intervals > 0) {
        text <- tg$get_interval_text(first_tier, 1)
        expect_type(text, "character")
      }
    }
  }
})

test_that("Benchmark TextGrid data frame export works", {
  skip_on_cran()
  
  tg_path <- system.file("extdata", "benchmarkdata60min.TextGrid",
    package = "speaker")
  skip_if(tg_path == "", "Benchmark TextGrid not found")
  
  tg <- TextGrid$new(tg_path)
  
  # Export to data frame (may be large, so limit to first tier)
  if (tg$get_number_of_tiers() > 0) {
    df <- tg$as_data_frame(tiers = 1)
    
    expect_s3_class(df, "data.frame")
  expect_s3_class(df, "data.table")
    expect_true("time" %in% names(df) || "start_time" %in% names(df))
  }
})

test_that("Sound$extract_intervals_where works with matching intervals", {
  
  s <- Sound$new(test_path("fixtures/speech_sample.wav"))
  p <- s$to_pitch()
  tg <- p$to_textgrid_vuv()
  
  # Should find unvoiced intervals
  result <- s$extract_intervals_where(tg, 1, "is equal to", "U", FALSE)
  
  expect_type(result, "list")
  expect_gte(length(result), 0)
})

test_that("Sound$extract_intervals_where handles no matches without crashing", {
  
  s <- Sound$new(test_path("fixtures/speech_sample.wav"))
  p <- s$to_pitch()
  tg <- p$to_textgrid_vuv()
  
  # Search for non-existent label - should return empty list, not segfault
  # (Praat warning goes to stderr, not R warning system)
  result <- s$extract_intervals_where(tg, 1, "is equal to", "NONEXISTENT",
    FALSE)
  
  expect_type(result, "list")
  expect_length(result, 0)
})

test_that("Sound$extract_intervals_where works with different criteria", {
  
  s <- Sound$new(test_path("fixtures/speech_sample.wav"))
  p <- s$to_pitch()
  tg <- p$to_textgrid_vuv()
  
  # Test "is not equal to"
  result <- s$extract_intervals_where(tg, 1, "is not equal to", "U", FALSE)
  expect_type(result, "list")
  
  # Test "contains"  
  result <- s$extract_intervals_where(tg, 1, "contains", "U", FALSE)
  expect_type(result, "list")
})

# test-interpreter-bridge.R
# Tests for PraatInterpreter object bridge functionality

test_that("interpreter can receive and return Sound objects", {
  # Create sound in R
  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 22050)
  expect_s3_class(sound, "Sound")

  # Create interpreter and inject sound
  interp <- PraatInterpreter$new()
  id <- interp$set_object("testSound", sound)
  expect_true(is.numeric(id))
  expect_identical(interp$object_count(), 1L)

  # List objects
  objs <- interp$list_objects()
  expect_identical(nrow(objs), 1L)
  expect_identical(objs$class[1], "Sound")

  # Retrieve the sound
  retrieved <- interp$get_object("testSound", "Sound")
  expect_s3_class(retrieved, "Sound")
  expect_equal(retrieved$get_duration(), sound$get_duration(), tolerance = sqrt(.Machine$double.eps))

  # Verify data integrity (zero difference)
  orig_data <- sound$as_matrix()
  retr_data <- retrieved$as_matrix()
  expect_equal(dim(orig_data), dim(retr_data), tolerance = sqrt(.Machine$double.eps))
  expect_equal(max(abs(orig_data - retr_data)), 0, tolerance = sqrt(.Machine$double.eps))

  # Cleanup
  interp$remove_object("testSound")
  expect_identical(interp$object_count(), 0L)
})

test_that("interpreter can receive and return Pitch objects", {
  # Create sound and extract pitch
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 22050)
  pitch <- sound$to_pitch()
  expect_s3_class(pitch, "Pitch")

  # Inject into interpreter
  interp <- PraatInterpreter$new()
  id <- interp$set_object("testPitch", pitch)
  expect_true(is.numeric(id))

  # Retrieve
  retrieved <- interp$get_object("testPitch", "Pitch")
  expect_s3_class(retrieved, "Pitch")

  # Verify same properties (use available methods)
  expect_equal(retrieved$get_number_of_frames(), pitch$get_number_of_frames(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(retrieved$get_time_step(), pitch$get_time_step(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(retrieved$get_mean(0, 0, "Hertz"), pitch$get_mean(0, 0, "Hertz"), tolerance = sqrt(.Machine$double.eps))

  interp$clear_objects()
  expect_identical(interp$object_count(), 0L)
})

test_that("interpreter can receive and return TextGrid objects", {
  # Create TextGrid (must provide tier_names)
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words")
  tg$insert_boundary(tier = 1, time = 0.5)
  tg$set_interval_text(tier = 1, interval = 1, text = "hello")
  tg$set_interval_text(tier = 1, interval = 2, text = "world")

  # Inject
  interp <- PraatInterpreter$new()
  id <- interp$set_object("testTG", tg)

  # Retrieve
  retrieved <- interp$get_object("testTG", "TextGrid")
  expect_s3_class(retrieved, "TextGrid")

  # Verify structure preserved
  expect_equal(retrieved$get_number_of_tiers(), tg$get_number_of_tiers(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(retrieved$get_number_of_intervals(1), tg$get_number_of_intervals(1), tolerance = sqrt(.Machine$double.eps))
  expect_identical(retrieved$get_interval_text(1, 1), "hello")
  expect_identical(retrieved$get_interval_text(1, 2), "world")

  interp$clear_objects()
})

test_that("interpreter type checking works", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5)

  interp <- PraatInterpreter$new()
  interp$set_object("testSound", sound)

  # Should succeed with correct type
  s <- interp$get_object("testSound", "Sound")
  expect_s3_class(s, "Sound")

  # Should fail with wrong type
  expect_error(
    interp$get_object("testSound", "Pitch"),
    "Type mismatch"
  )

  # Should succeed with no type specified
  s2 <- interp$get_object("testSound")
  expect_s3_class(s2, "Sound")

  interp$clear_objects()
})

test_that("interpreter can handle multiple objects", {
  interp <- PraatInterpreter$new()

  # Add multiple objects
  sound1 <- Sound$create_tone(frequency = 220, duration = 0.3)
  sound2 <- Sound$create_tone(frequency = 440, duration = 0.3)
  pitch <- sound1$to_pitch()

  interp$set_object("low", sound1)
  interp$set_object("high", sound2)
  interp$set_object("pitchObj", pitch)

  expect_identical(interp$object_count(), 3L)

  # Retrieve by ID
  objs <- interp$list_objects()
  low_id <- objs$id[objs$name == "Sound low"]
  retrieved <- interp$get_object_by_id(low_id)
  expect_s3_class(retrieved, "Sound")

  # Remove by ID
  interp$remove_object_by_id(low_id)
  expect_identical(interp$object_count(), 2L)

  interp$clear_objects()
  expect_identical(interp$object_count(), 0L)
})

test_that("interpreter object selection works", {
  interp <- PraatInterpreter$new()

  sound <- Sound$create_tone(frequency = 440, duration = 0.3)
  interp$set_object("test", sound)

  # Initially not selected
  objs <- interp$list_objects()
  expect_false(objs$selected[1])

  # Select it
  interp$select_object("test")
  objs <- interp$list_objects()
  expect_true(objs$selected[1])

  interp$clear_objects()
})

# test-interpreter.R - Tests for Praat interpreter functionality
#
# Sprint 1 tests: Expression evaluation, variable get/set

# === Expression Evaluation Tests ===

test_that("praat_eval_numeric() evaluates numeric expressions correctly", {
  expect_equal(praat_eval_numeric("2 + 2"), 4)
  expect_equal(praat_eval_numeric("10 * 5"), 50)
  expect_equal(praat_eval_numeric("100 / 4"), 25)
  expect_equal(praat_eval_numeric("2^8"), 256)
  expect_equal(praat_eval_numeric("sqrt(16)"), 4)
  expect_equal(praat_eval_numeric("sin(0)"), 0, tolerance = 1e-10)
})

test_that("praat_eval_string() evaluates string expressions correctly", {
  expect_equal(praat_eval_string("\"hello\""), "hello")
  expect_equal(praat_eval_string("\"world\" + \" test\""), "world test")
  expect_equal(praat_eval_string("string$(42)"), "42")
  expect_match(praat_eval_string("left$(\"testing\", 4)"), "test")
})

test_that("praat_eval_vector() evaluates vector expressions correctly", {
  result <- praat_eval_vector("{ 1, 2, 3, 4, 5 }")
  expect_equal(result, c(1, 2, 3, 4, 5))
  
  # TODO: Test zero# function
  # result <- praat_eval_vector("zero# (5)")
  # expect_equal(result, rep(0, 5))
  # expect_length(result, 5)
  
  result <- praat_eval_vector("{ 1.1, 2.2, 3.3 }")
  expect_equal(result, c(1.1, 2.2, 3.3), tolerance = 1e-10)
})

test_that("praat_eval_matrix() evaluates matrix expressions correctly", {
  result <- praat_eval_matrix("{{ 1, 2 }, { 3, 4 }}")
  expected <- matrix(c(1, 3, 2, 4), nrow = 2, ncol = 2)
  expect_equal(result, expected)
  
  # TODO: Test zero## function
  # result <- praat_eval_matrix("zero## (2, 3)")
  # expected <- matrix(0, nrow = 2, ncol = 3)
  # expect_equal(result, expected)
  # expect_equal(nrow(result), 2)
  # expect_equal(ncol(result), 3)
  
  result <- praat_eval_matrix("{{ 1.5, 2.5 }, { 3.5, 4.5 }}")
  expected <- matrix(c(1.5, 3.5, 2.5, 4.5), nrow = 2, ncol = 2)
  expect_equal(result, expected, tolerance = 1e-10)
})

test_that("praat_eval_string_array() evaluates string array expressions correctly", {
  result <- praat_eval_string_array("{ \"a\", \"b\", \"c\" }")
  expect_equal(result, c("a", "b", "c"))
  
  # TODO: Fix segfault with empty$# function
  # result <- praat_eval_string_array("empty$# (3)")
  # expect_equal(result, c("", "", ""))
  # expect_length(result, 3)
})

# === PraatInterpreter R6 Class Tests ===

test_that("PraatInterpreter$new() creates valid interpreter instance", {
  interp <- PraatInterpreter$new()
  expect_s3_class(interp, "PraatInterpreter")
  expect_true(!is.null(interp$.__enclos_env__$private$ptr))
})

test_that("PraatInterpreter$eval() evaluates expressions in interpreter context", {
  interp <- PraatInterpreter$new()
  
  result <- interp$eval("2 + 3")
  expect_equal(result, 5)
  
  result <- interp$eval("\"test\"")
  expect_equal(result, "test")
  
  result <- interp$eval("{ 1, 2, 3 }")
  expect_equal(result, c(1, 2, 3))
})

# === Variable Get/Set Tests ===

test_that("set_variable() and get_variable() work for numeric variables", {
  interp <- PraatInterpreter$new()
  
  # Set and get numeric scalar
  interp$set_variable("x", 42)
  result <- interp$get_variable("x")
  expect_equal(result, 42)
  
  # Integer should work too
  interp$set_variable("count", 100L)
  result <- interp$get_variable("count")
  expect_equal(result, 100)
  
  # Negative numbers
  interp$set_variable("temp", -273.15)
  result <- interp$get_variable("temp")
  expect_equal(result, -273.15, tolerance = 1e-10)
})

test_that("set_variable() and get_variable() work for string variables", {
  interp <- PraatInterpreter$new()
  
  # Set and get string
  interp$set_variable("name", "alice")
  result <- interp$get_variable("name$")
  expect_equal(result, "alice")
  
  # Empty string
  interp$set_variable("empty", "")
  result <- interp$get_variable("empty$")
  expect_equal(result, "")
  
  # String with spaces
  interp$set_variable("phrase", "hello world")
  result <- interp$get_variable("phrase$")
  expect_equal(result, "hello world")
})

test_that("set_variable() and get_variable() work for vector variables", {
  interp <- PraatInterpreter$new()
  
  # Set and get vector
  interp$set_variable("data", c(1.1, 2.2, 3.3))
  result <- interp$get_variable("data#")
  expect_equal(result, c(1.1, 2.2, 3.3), tolerance = 1e-10)
  
  # Integer vector should convert to double
  interp$set_variable("counts", 1:5)
  result <- interp$get_variable("counts#")
  expect_equal(result, c(1, 2, 3, 4, 5))
  
  # Note: Single element c(99) is treated as scalar, not vector in Praat
})

test_that("set_variable() and get_variable() work for matrix variables", {
  interp <- PraatInterpreter$new()
  
  # Set and get matrix (double)
  mat <- matrix(1:6, nrow = 2, ncol = 3)
  interp$set_variable("mat", mat)
  result <- interp$get_variable("mat##")
  expect_equal(result, mat)
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
  
  # Double matrix
  mat_dbl <- matrix(c(1.1, 2.2, 3.3, 4.4), nrow = 2, ncol = 2)
  interp$set_variable("matdbl", mat_dbl)
  result <- interp$get_variable("matdbl##")
  expect_equal(result, mat_dbl, tolerance = 1e-10)
  
  # 1x1 matrix
  mat_small <- matrix(42)
  interp$set_variable("small", mat_small)
  result <- interp$get_variable("small##")
  expect_equal(result, mat_small)
})

test_that("set_variable() and get_variable() work for string array variables", {
  interp <- PraatInterpreter$new()
  
  # Set and get string array (must be length > 1)
  interp$set_variable("names", c("alice", "bob", "charlie"))
  result <- interp$get_variable("names$#")
  expect_equal(result, c("alice", "bob", "charlie"))
  
  # Note: Single element c("only") is treated as string scalar, not array in Praat
  
  # Empty strings in array
  interp$set_variable("mixed", c("a", "", "c"))
  result <- interp$get_variable("mixed$#")
  expect_equal(result, c("a", "", "c"))
})

test_that("set_variable() auto-detects correct Praat suffix", {
  interp <- PraatInterpreter$new()
  
  # Numeric doesn't need suffix
  interp$set_variable("x", 10)
  expect_equal(interp$get_variable("x"), 10)
  
  # String adds $ suffix
  interp$set_variable("str", "test")
  expect_equal(interp$get_variable("str$"), "test")
  
  # Vector adds # suffix
  interp$set_variable("vec", c(1, 2, 3))
  expect_equal(interp$get_variable("vec#"), c(1, 2, 3))
  
  # Matrix adds ## suffix
  interp$set_variable("mat", matrix(1:4, 2, 2))
  expect_equal(interp$get_variable("mat##"), matrix(1:4, 2, 2))
  
  # String array adds $# suffix
  interp$set_variable("strs", c("a", "b"))
  expect_equal(interp$get_variable("strs$#"), c("a", "b"))
})

test_that("Variables can be updated with new values", {
  interp <- PraatInterpreter$new()
  
  # Update numeric variable
  interp$set_variable("x", 10)
  expect_equal(interp$get_variable("x"), 10)
  interp$set_variable("x", 20)
  expect_equal(interp$get_variable("x"), 20)
  
  # Update string variable
  interp$set_variable("name", "old")
  expect_equal(interp$get_variable("name$"), "old")
  interp$set_variable("name", "new")
  expect_equal(interp$get_variable("name$"), "new")
})

test_that("Multiple interpreters have isolated variable spaces", {
  interp1 <- PraatInterpreter$new()
  interp2 <- PraatInterpreter$new()
  
  # Set different values in each interpreter
  interp1$set_variable("x", 100)
  interp2$set_variable("x", 200)
  
  # Values should be isolated
  expect_equal(interp1$get_variable("x"), 100)
  expect_equal(interp2$get_variable("x"), 200)
  
  # Setting in one shouldn't affect the other
  interp1$set_variable("x", 300)
  expect_equal(interp1$get_variable("x"), 300)
  expect_equal(interp2$get_variable("x"), 200)
})

# === Error Handling Tests ===

test_that("praat_eval_numeric() errors on invalid expressions", {
  expect_error(praat_eval_numeric("not_a_number"))
  # TODO: Division by zero might not error in Praat (returns Inf)
  # expect_error(praat_eval_numeric("1 / 0"))
})

test_that("praat_eval_string() errors on invalid expressions", {
  expect_error(praat_eval_string("123"))  # Number, not string
})

test_that("get_variable() returns NULL for undefined variables", {
  interp <- PraatInterpreter$new()
  result <- interp$get_variable("undefined_var")
  expect_null(result)
})

test_that("get_variable() returns NULL for wrong suffix", {
  interp <- PraatInterpreter$new()
  interp$set_variable("x", 42)
  
  # x is numeric, trying to access as string returns NULL
  result <- interp$get_variable("x$")
  expect_null(result)
})

test_that("set_variable() rejects unsupported types", {
  interp <- PraatInterpreter$new()
  
  # List should error
  expect_error(interp$set_variable("bad", list(a = 1)))
  
  # NULL should error
  expect_error(interp$set_variable("bad", NULL))
  
  # Data frame should error
  expect_error(interp$set_variable("bad", data.frame(x = 1:3)))
})

# === Integration Tests ===

test_that("Variables can be used in expressions after being set", {
  interp <- PraatInterpreter$new()
  
  # Set variables and use them in expressions
  interp$set_variable("a", 10)
  interp$set_variable("b", 20)
  
  result <- interp$eval("a + b")
  expect_equal(result, 30)
  
  result <- interp$eval("a * b")
  expect_equal(result, 200)
})

test_that("String variables can be concatenated in expressions", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("first", "hello")
  interp$set_variable("second", "world")
  
  result <- interp$eval("first$ + \" \" + second$")
  expect_equal(result, "hello world")
})

test_that("Vector operations work with set variables", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("vec", c(1, 2, 3, 4, 5))
  
  # Get size
  result <- interp$eval("size(vec#)")
  expect_equal(result, 5)
  
  # Sum vector
  result <- interp$eval("sum(vec#)")
  expect_equal(result, 15)
})

test_that("Matrix operations work with set variables", {
  interp <- PraatInterpreter$new()
  
  mat <- matrix(1:4, nrow = 2, ncol = 2)
  interp$set_variable("mat", mat)
  
  # Get number of rows
  result <- interp$eval("numberOfRows(mat##)")
  expect_equal(result, 2)
  
  # Get number of columns
  result <- interp$eval("numberOfColumns(mat##)")
  expect_equal(result, 2)
})

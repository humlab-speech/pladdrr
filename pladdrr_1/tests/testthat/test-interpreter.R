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

# === Object Management Tests ===

test_that("praat_object_count() returns integer count", {
  count <- praat_object_count()
  expect_type(count, "integer")
  expect_gte(count, 0)
})

test_that("praat_list_objects() returns data frame with correct structure", {
  objects <- praat_list_objects()
  expect_s3_class(objects, "data.frame")
  expect_named(objects, c("id", "name", "class", "selected"))
  expect_type(objects$id, "integer")
  expect_type(objects$name, "character")
  expect_type(objects$class, "character")
  expect_type(objects$selected, "logical")
})

test_that("PraatInterpreter object_count() method works", {
  interp <- PraatInterpreter$new()
  count <- interp$object_count()
  expect_type(count, "integer")
  expect_gte(count, 0)
})

test_that("PraatInterpreter list_objects() method works", {
  interp <- PraatInterpreter$new()
  objects <- interp$list_objects()
  expect_s3_class(objects, "data.frame")
  expect_named(objects, c("id", "name", "class", "selected"))
})

test_that("Object list is initially empty in library mode", {
  # In library mode without GUI, object list should be empty
  count <- praat_object_count()
  expect_equal(count, 0)
  
  objects <- praat_list_objects()
  expect_equal(nrow(objects), 0)
})

# === Complex Mathematical Expression Tests ===

test_that("Complex nested mathematical expressions evaluate correctly", {
  # Nested operations
  expect_equal(praat_eval_numeric("(2 + 3) * (4 - 1)"), 15)
  expect_equal(praat_eval_numeric("((10 + 5) / 3) * 2"), 10)
  
  # Order of operations
  expect_equal(praat_eval_numeric("2 + 3 * 4"), 14)
  expect_equal(praat_eval_numeric("10 - 2 * 3"), 4)
  
  # Multiple function calls
  expect_equal(praat_eval_numeric("sqrt(abs(-16))"), 4)
  expect_equal(praat_eval_numeric("round(sqrt(10))"), 3)
})

test_that("Trigonometric functions work correctly", {
  pi_val <- 3.14159265358979
  
  # Basic trig functions
  expect_equal(praat_eval_numeric("sin(pi/2)"), 1, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("cos(0)"), 1, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("tan(0)"), 0, tolerance = 1e-10)
  
  # Arc functions
  expect_equal(praat_eval_numeric("arcsin(1)"), pi_val/2, tolerance = 1e-6)
  expect_equal(praat_eval_numeric("arccos(1)"), 0, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("arctan(0)"), 0, tolerance = 1e-10)
})

test_that("Logarithmic and exponential functions work correctly", {
  # Natural log and exp
  expect_equal(praat_eval_numeric("ln(e)"), 1, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("exp(0)"), 1, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("exp(1)"), exp(1), tolerance = 1e-10)
  
  # Log base 10 and log base 2
  expect_equal(praat_eval_numeric("log10(100)"), 2, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("log10(1000)"), 3, tolerance = 1e-10)
  expect_equal(praat_eval_numeric("log2(8)"), 3, tolerance = 1e-10)
})

test_that("Statistical functions work correctly", {
  # Min and max
  expect_equal(praat_eval_numeric("min(5, 3)"), 3)
  expect_equal(praat_eval_numeric("max(5, 3)"), 5)
  
  # Absolute value
  expect_equal(praat_eval_numeric("abs(-42)"), 42)
  expect_equal(praat_eval_numeric("abs(42)"), 42)
  
  # Rounding functions
  expect_equal(praat_eval_numeric("round(3.7)"), 4)
  expect_equal(praat_eval_numeric("round(3.2)"), 3)
  expect_equal(praat_eval_numeric("floor(3.9)"), 3)
  expect_equal(praat_eval_numeric("ceiling(3.1)"), 4)
})

# === Advanced String Manipulation Tests ===

test_that("String manipulation functions work correctly", {
  # Length
  expect_equal(praat_eval_numeric("length(\"hello\")"), 5)
  expect_equal(praat_eval_numeric("length(\"\")"), 0)
  
  # Substring extraction
  expect_equal(praat_eval_string("mid$(\"testing\", 2, 4)"), "esti")
  expect_equal(praat_eval_string("right$(\"testing\", 3)"), "ing")
  
  # Case conversion
  result <- praat_eval_string("replace_regex$(\"Hello\", \"H\", \"h\", 0)")
  expect_true(is.character(result))
})

test_that("String concatenation with multiple parts works", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("a", "one")
  interp$set_variable("b", "two")
  interp$set_variable("c", "three")
  
  result <- interp$eval("a$ + \"-\" + b$ + \"-\" + c$")
  expect_equal(result, "one-two-three")
})

test_that("String array indexing works", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("names", c("alice", "bob", "charlie"))
  
  # Access first element (1-based indexing in Praat)
  result <- interp$eval("names$#[1]")
  expect_equal(result, "alice")
  
  # Access last element
  result <- interp$eval("names$#[3]")
  expect_equal(result, "charlie")
})

# === Vector and Matrix Operation Tests ===

test_that("Vector arithmetic operations work", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("v1", c(1, 2, 3))
  interp$set_variable("v2", c(4, 5, 6))
  
  # Vector sum
  result <- interp$eval("sum(v1#)")
  expect_equal(result, 6)
  
  # Vector mean
  result <- interp$eval("mean(v1#)")
  expect_equal(result, 2)
  
  # Vector size
  result <- interp$eval("size(v1#)")
  expect_equal(result, 3)
})

test_that("Vector element access works", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("data", c(10, 20, 30, 40, 50))
  
  # Access first element (1-based indexing)
  result <- interp$eval("data#[1]")
  expect_equal(result, 10)
  
  # Access middle element
  result <- interp$eval("data#[3]")
  expect_equal(result, 30)
  
  # Access last element
  result <- interp$eval("data#[5]")
  expect_equal(result, 50)
})

test_that("Matrix element access works", {
  interp <- PraatInterpreter$new()
  
  mat <- matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, ncol = 3)
  interp$set_variable("m", mat)
  
  # Access element [1,1]
  result <- interp$eval("m##[1, 1]")
  expect_equal(result, 1)
  
  # Access element [2,3]
  result <- interp$eval("m##[2, 3]")
  expect_equal(result, 6)
})

test_that("Matrix statistics work", {
  interp <- PraatInterpreter$new()
  
  mat <- matrix(1:9, nrow = 3, ncol = 3)
  interp$set_variable("m", mat)
  
  # Dimensions
  expect_equal(interp$eval("numberOfRows(m##)"), 3)
  expect_equal(interp$eval("numberOfColumns(m##)"), 3)
})

# === Cross-Type Variable Interaction Tests ===

test_that("Numeric variables can be converted to strings", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("num", 42)
  result <- interp$eval("string$(num)")
  expect_equal(result, "42")
  
  interp$set_variable("decimal", 3.14159)
  result <- interp$eval("fixed$(decimal, 2)")
  expect_match(result, "3\\.14")
})

test_that("Multiple variable types can coexist", {
  interp <- PraatInterpreter$new()
  
  # Set one of each type
  interp$set_variable("n", 42)
  interp$set_variable("s", "hello")
  interp$set_variable("v", c(1, 2, 3))
  interp$set_variable("m", matrix(1:4, 2, 2))
  interp$set_variable("a", c("a", "b"))
  
  # Verify all are accessible
  expect_equal(interp$get_variable("n"), 42)
  expect_equal(interp$get_variable("s$"), "hello")
  expect_equal(interp$get_variable("v#"), c(1, 2, 3))
  expect_equal(interp$get_variable("m##"), matrix(1:4, 2, 2))
  expect_equal(interp$get_variable("a$#"), c("a", "b"))
})

test_that("Variables can be used in mixed-type expressions", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("count", 5)
  interp$set_variable("label", "items")
  
  # Combine numeric and string
  result <- interp$eval("string$(count) + \" \" + label$")
  expect_equal(result, "5 items")
})

# === Interpreter State Persistence Tests ===

test_that("Variables persist across multiple eval() calls", {
  interp <- PraatInterpreter$new()
  
  # Set variable
  interp$set_variable("x", 10)
  
  # Use it in eval
  result <- interp$eval("x * 2")
  expect_equal(result, 20)
  
  # Update via set_variable and use again
  interp$set_variable("x", 15)
  result <- interp$eval("x")
  expect_equal(result, 15)
})

test_that("Computed results can be stored and reused", {
  interp <- PraatInterpreter$new()
  
  # Compute in eval and store via set_variable
  result_val <- interp$eval("sqrt(16) + sqrt(25)")
  interp$set_variable("result", result_val)
  
  # Retrieve
  result <- interp$get_variable("result")
  expect_equal(result, 9)
  
  # Use in further computation
  result <- interp$eval("result * 2")
  expect_equal(result, 18)
})

test_that("Interpreter maintains separate state per instance", {
  interp1 <- PraatInterpreter$new()
  interp2 <- PraatInterpreter$new()
  interp3 <- PraatInterpreter$new()
  
  # Set different values in each
  interp1$set_variable("value", 100)
  interp2$set_variable("value", 200)
  interp3$set_variable("value", 300)
  
  # Each should maintain its own state
  expect_equal(interp1$eval("value"), 100)
  expect_equal(interp2$eval("value"), 200)
  expect_equal(interp3$eval("value"), 300)
})

# === Error Recovery and Edge Cases ===

test_that("Interpreter recovers from errors gracefully", {
  interp <- PraatInterpreter$new()
  
  # Set valid variable
  interp$set_variable("x", 10)
  expect_equal(interp$get_variable("x"), 10)
  
  # Try invalid operation
  expect_error(interp$eval("invalid_function()"))
  
  # Verify interpreter still works
  expect_equal(interp$get_variable("x"), 10)
  result <- interp$eval("x + 5")
  expect_equal(result, 15)
})

test_that("Large vectors work correctly", {
  interp <- PraatInterpreter$new()
  
  # Create large vector
  large_vec <- 1:1000
  interp$set_variable("big", large_vec)
  
  # Verify size
  result <- interp$eval("size(big#)")
  expect_equal(result, 1000)
  
  # Verify sum
  result <- interp$eval("sum(big#)")
  expect_equal(result, sum(large_vec))
})

test_that("Large matrices work correctly", {
  interp <- PraatInterpreter$new()
  
  # Create 100x100 matrix
  large_mat <- matrix(1:10000, nrow = 100, ncol = 100)
  interp$set_variable("bigmat", large_mat)
  
  # Verify dimensions
  expect_equal(interp$eval("numberOfRows(bigmat##)"), 100)
  expect_equal(interp$eval("numberOfColumns(bigmat##)"), 100)
  
  # Access corner element
  result <- interp$eval("bigmat##[100, 100]")
  expect_equal(result, 10000)
})

test_that("Special numeric values are handled", {
  interp <- PraatInterpreter$new()
  
  # Zero
  interp$set_variable("zero", 0)
  expect_equal(interp$get_variable("zero"), 0)
  
  # Very small number
  interp$set_variable("tiny", 1e-10)
  expect_equal(interp$get_variable("tiny"), 1e-10, tolerance = 1e-15)
  
  # Very large number
  interp$set_variable("huge", 1e10)
  expect_equal(interp$get_variable("huge"), 1e10)
  
  # Negative numbers
  interp$set_variable("neg", -999.999)
  expect_equal(interp$get_variable("neg"), -999.999, tolerance = 1e-10)
})

test_that("Empty and single-element collections work", {
  interp <- PraatInterpreter$new()
  
  # Empty string
  interp$set_variable("empty", "")
  expect_equal(interp$get_variable("empty$"), "")
  
  # Single element vector treated as scalar
  interp$set_variable("single", 42)
  expect_equal(interp$get_variable("single"), 42)
  
  # 1x1 matrix
  mat_1x1 <- matrix(99)
  interp$set_variable("mat1x1", mat_1x1)
  result <- interp$get_variable("mat1x1##")
  expect_equal(result, mat_1x1)
})

# === Practical Statistical Workflow Tests ===

test_that("Mean and standard deviation workflow works", {
  interp <- PraatInterpreter$new()
  
  # Set data
  data <- c(2, 4, 4, 4, 5, 5, 7, 9)
  interp$set_variable("data", data)
  
  # Calculate mean
  mean_val <- interp$eval("mean(data#)")
  expect_equal(mean_val, mean(data))
  
  # Calculate standard deviation
  sd_val <- interp$eval("stdev(data#)")
  expect_equal(sd_val, sd(data), tolerance = 1e-10)
})

test_that("Data transformation workflow works", {
  interp <- PraatInterpreter$new()
  
  # Original data
  values <- c(10, 20, 30, 40, 50)
  interp$set_variable("original", values)
  
  # Get size for iteration
  n <- interp$eval("size(original#)")
  expect_equal(n, 5)
  
  # Access and transform individual elements
  first <- interp$eval("original#[1]")
  expect_equal(first, 10)
  
  last <- interp$eval("original#[5]")
  expect_equal(last, 50)
})

test_that("Matrix computation workflow works", {
  interp <- PraatInterpreter$new()
  
  # Create correlation-like matrix
  mat <- matrix(c(1.0, 0.8, 0.8, 1.0), nrow = 2, ncol = 2)
  interp$set_variable("corr", mat)
  
  # Verify symmetric properties
  val11 <- interp$eval("corr##[1, 1]")
  val22 <- interp$eval("corr##[2, 2]")
  expect_equal(val11, 1.0)
  expect_equal(val22, 1.0)
  
  val12 <- interp$eval("corr##[1, 2]")
  val21 <- interp$eval("corr##[2, 1]")
  expect_equal(val12, val21)
})

test_that("Conditional expressions work", {
  interp <- PraatInterpreter$new()
  
  # Simple conditional
  result <- interp$eval("if 5 > 3 then 1 else 0 fi")
  expect_equal(result, 1)
  
  result <- interp$eval("if 2 > 5 then 1 else 0 fi")
  expect_equal(result, 0)
  
  # With variables
  interp$set_variable("x", 10)
  result <- interp$eval("if x > 5 then x * 2 else x fi")
  expect_equal(result, 20)
})

test_that("String comparison and logic work", {
  interp <- PraatInterpreter$new()
  
  interp$set_variable("name", "test")
  
  # String equality uses string$ function
  result <- interp$eval("if name$ = \"test\" then 1 else 0 fi")
  expect_equal(result, 1)
  
  result <- interp$eval("if name$ = \"other\" then 1 else 0 fi")
  expect_equal(result, 0)
})

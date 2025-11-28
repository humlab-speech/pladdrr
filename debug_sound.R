library(pladdrr)

cat("Debugging Sound Class\n\n")

cat("Creating Sound from values...\n")
values <- c(0.1, 0.2, 0.3, 0.2, 0.1)
sound <- Sound$from_values(values, sampling_frequency = 1000)

cat("Sound class:", paste(class(sound), collapse=", "), "\n")
cat("\nFirst 20 method names:\n")
print(head(names(sound), 20))

cat("\n\nChecking specific methods:\n")
cat("Has get_total_duration:", "get_total_duration" %in% names(sound), "\n")
cat("Type:", typeof(sound$get_total_duration), "\n")
cat("Is function:", is.function(sound$get_total_duration), "\n")

# Try to understand the structure
cat("\n\nSound object structure:\n")
cat("Names in environment:\n")
print(ls(sound))

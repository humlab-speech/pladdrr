# Praat Script to speaker R Package Conversion Guide

**Version**: 1.0.0  
**Date**: 2025-11-19  
**Purpose**: Comprehensive guide for LLMs to convert Praat scripts to speaker R code

---

## Table of Contents

1. [Core Philosophy](#core-philosophy)
2. [Object Creation Patterns](#object-creation-patterns)
3. [Object Manipulation](#object-manipulation)
4. [Query Operations](#query-operations)
5. [Selection and Object Management](#selection-and-object-management)
6. [Control Flow](#control-flow)
7. [String Operations](#string-operations)
8. [File I/O](#file-io)
9. [Arrays and Collections](#arrays-and-collections)
10. [Common Workflows](#common-workflows)
11. [Complete Examples](#complete-examples)

---

## Core Philosophy

### Praat Approach
- **Procedural**: Commands operate on selected objects
- **Global State**: Selection-based workflow
- **String Dispatch**: Commands as strings
- **Modal UI**: Forms for input

### speaker Approach
- **Object-Oriented**: R6 classes with methods
- **Explicit References**: Direct object manipulation
- **Type-Safe**: Named parameters with validation
- **Functional**: R-style data processing

---

## Object Creation Patterns

### Pattern 1: Reading from Files

**Praat**:
```praat
Read from file: "audio.wav"
soundName$ = selected$("Sound")

Read from file: "annotations.TextGrid"

# Multiple files
Read Strings from raw text file: "file_list.txt"
```

**speaker**:
```r
# Sound objects use av package (humlab-speech/av fork)
library(av)
sound <- Sound$new("audio.wav")

# TextGrid
textgrid <- TextGrid$new("annotations.TextGrid")

# Multiple files
file_list <- readLines("file_list.txt")
sounds <- lapply(file_list, Sound$new)
```

### Pattern 2: Creating Objects from Scratch

**Praat**:
```praat
Create Sound from formula: "tone", 1, 0, 1, 44100, "sin(2*pi*440*x)"
Create TextGrid: 0, 1, "words phones", "phones"
Create PitchTier: "manipulation", 0, 1
```

**speaker**:
```r
# Sound creation (via av package)
# For synthetic sounds, create with av then load
tone <- Sound$create_tone(duration = 1, frequency = 440, sampling_rate = 44100)

# TextGrid
tg <- TextGrid$create(xmin = 0, xmax = 1, 
                      tier_names = c("words", "phones"),
                      point_tiers = character(0))

# PitchTier
pt <- PitchTier$create(xmin = 0, xmax = 1, name = "manipulation")
```

### Pattern 3: Conversion/Transformation

**Praat**:
```praat
selectObject: "Sound audio"
To Pitch: 0.01, 75, 600
To Formant (burg): 0.01, 5, 5500, 0.025, 50
To Intensity: 100, 0, "yes"
To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"
```

**speaker**:
```r
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(time_step = 0.01, max_formants = 5, 
                                  max_frequency = 5500, window_length = 0.025,
                                  pre_emphasis = 50)
intensity <- sound$to_intensity(min_pitch = 100, time_step = 0, subtract_mean = TRUE)
spectrogram <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000,
                                     time_step = 0.002, frequency_step = 20,
                                     window_shape = "Gaussian")
```

---

## Object Manipulation

### Pattern 4: Extracting Parts

**Praat**:
```praat
Extract part: 0.5, 1.5, "rectangular", 1, "no"
Extract one tier: 1
Extract intervals where: 1, "no", "is equal to", "vowel"
```

**speaker**:
```r
part <- sound$extract_part(from_time = 0.5, to_time = 1.5, 
                           window_shape = "rectangular",
                           relative_width = 1, preserve_times = FALSE)

tier <- textgrid$extract_tier(tier_number = 1)

vowel_intervals <- textgrid$extract_intervals_where(tier_number = 1,
                                                     match_type = "equal",
                                                     criterion = "vowel")
```

### Pattern 5: Modification

**Praat**:
```praat
Formula: "self * 0.5"
Scale intensity: 70
Override sampling frequency: 16000
Set label of interval: 1, 5, "vowel"
```

**speaker**:
```r
sound$apply_formula("self * 0.5")
sound$scale_intensity(new_intensity = 70)
sound$resample(new_frequency = 16000)
textgrid$set_interval_text(tier_number = 1, interval_number = 5, text = "vowel")
```

### Pattern 6: Combining Objects

**Praat**:
```praat
selectObject: "Sound part1", "Sound part2", "Sound part3"
Concatenate
Combine

plusObject: "TextGrid annotations"
```

**speaker**:
```r
# Concatenate sounds
combined <- Sound$concatenate(list(part1, part2, part3))

# Combine objects (context-dependent)
combined <- Object$combine(list(obj1, obj2, obj3))

# No "plusObject" needed - use list() for multiple objects
result <- process_multiple(list(sound, textgrid))
```

---

## Query Operations

### Pattern 7: Getting Values

**Praat**:
```praat
duration = Get total duration
mean_f0 = Get mean: 0, 0, "Hertz"
value_at_time = Get value at time: 0.5, "Hertz", "Linear"
number_of_intervals = Get number of intervals: 1
label$ = Get label of interval: 1, 3
```

**speaker**:
```r
duration <- sound$get_total_duration()
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
value_at_time <- pitch$get_value_at_time(time = 0.5, unit = "hertz", 
                                          interpolation = "linear")
n_intervals <- textgrid$get_number_of_intervals(tier_number = 1)
label <- textgrid$get_label_of_interval(tier_number = 1, interval_number = 3)
```

### Pattern 8: Statistical Queries

**Praat**:
```praat
minimum = Get minimum: 0, 0, "Hertz", "Parabolic"
maximum = Get maximum: 0, 0, "Hertz", "Parabolic"
std_dev = Get standard deviation: 0, 0, "Hertz"
quantile = Get quantile: 0, 0, 0.95, "Hertz"
```

**speaker**:
```r
minimum <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz",
                              interpolation = "parabolic")
maximum <- pitch$get_maximum(from_time = 0, to_time = 0, unit = "hertz",
                              interpolation = "parabolic")
std_dev <- pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
quantile <- pitch$get_quantile(from_time = 0, to_time = 0, quantile = 0.95,
                                unit = "hertz")
```

---

## Selection and Object Management

### Pattern 9: Object Selection (Praat's Global State)

**Praat**:
```praat
selectObject: "Sound audio"
plusObject: "TextGrid annotations"
minusObject: "Sound noise"
selectObject: soundID
soundName$ = selected$("Sound")
removeObject: soundID
```

**speaker**:
```r
# No global selection needed - use direct object references
# Store objects in variables:
sound <- Sound$new("audio.wav")
textgrid <- TextGrid$new("annotations.TextGrid")

# Pass objects directly to functions
result <- some_function(sound, textgrid)

# No removeObject needed - R's garbage collection handles cleanup
# To explicitly remove:
rm(sound, textgrid)
gc()  # Force garbage collection if needed
```

**Key Difference**: speaker uses **explicit object references** instead of Praat's implicit selection system. This is safer and more R-idiomatic.

---

## Control Flow

### Pattern 10: Loops

**Praat**:
```praat
# For loop
for i from 1 to numberOfFiles
    selectObject: "Sound file_'i'"
    pitch = To Pitch: 0.01, 75, 600
    mean_f0 = Get mean: 0, 0, "Hertz"
    appendFileLine: "results.txt", i, tab$, mean_f0
endfor

# While loop
while fileReadable("file_'counter'.wav")
    Read from file: "file_'counter'.wav"
    counter = counter + 1
endwhile
```

**speaker**:
```r
# For loop with lapply (R-idiomatic)
file_names <- paste0("file_", 1:numberOfFiles, ".wav")
results <- lapply(file_names, function(fname) {
    sound <- Sound$new(fname)
    pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
    mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
    data.frame(file = fname, mean_f0 = mean_f0)
})
results_df <- do.call(rbind, results)
write.table(results_df, "results.txt", sep = "\t", row.names = FALSE)

# While loop
counter <- 1
while (file.exists(paste0("file_", counter, ".wav"))) {
    sound <- Sound$new(paste0("file_", counter, ".wav"))
    # Process sound...
    counter <- counter + 1
}
```

### Pattern 11: Conditionals

**Praat**:
```praat
if duration > 1.0
    writeInfoLine: "Long file"
elsif duration > 0.5
    writeInfoLine: "Medium file"
else
    writeInfoLine: "Short file"
endif

# Inline conditional
result = if condition then value1 else value2 fi
```

**speaker**:
```r
if (duration > 1.0) {
    message("Long file")
} else if (duration > 0.5) {
    message("Medium file")
} else {
    message("Short file")
}

# Inline conditional (vectorized)
result <- ifelse(condition, value1, value2)
```

---

## String Operations

### Pattern 12: String Manipulation

**Praat**:
```praat
# String concatenation
fullPath$ = directory$ + "/" + fileName$ + ".wav"

# String replacement
cleaned$ = replace$(original$, ".wav", ".TextGrid", 0)

# String extraction
baseName$ = left$(fileName$, length(fileName$) - 4)
extension$ = right$(fileName$, 3)

# String search
index = index(fullString$, "pattern")
rindex = rindex(fullString$, "/")

# Case conversion
upper$ = replace_regex$(lower$, ".", "\U&", 0)
```

**speaker**:
```r
# String concatenation
full_path <- file.path(directory, paste0(file_name, ".wav"))

# String replacement
cleaned <- gsub("\\.wav$", ".TextGrid", original)

# String extraction
base_name <- tools::file_path_sans_ext(file_name)
extension <- tools::file_ext(file_name)

# String search
index <- regexpr("pattern", full_string)
rindex <- gregexpr("/", full_string)[[1]] |> tail(1)

# Case conversion
upper <- toupper(lower)
```

---

## File I/O

### Pattern 13: Reading and Writing Files

**Praat**:
```praat
# Read audio
Read from file: "audio.wav"

# Write audio
Save as WAV file: "output.wav"

# Read text
Read Strings from raw text file: "list.txt"

# Write text
writeFile: "output.txt", "Header", newline$
appendFileLine: "output.txt", "Line 1"
appendFile: "output.txt", "More text"
writeInfoLine: "Message to console"

# File operations
createDirectory: "output_folder"
fileReadable: "test.wav"
deleteFile: "temp.txt"

# Choose files (interactive)
fileName$ = chooseReadFile$: "Choose a sound file"
outFile$ = chooseWriteFile$: "Save results"
dirName$ = chooseDirectory$: "Choose output directory"
```

**speaker**:
```r
# Read audio (via av package)
library(av)
sound <- Sound$new("audio.wav")

# Write audio (via av package)
sound$save("output.wav")  # Uses av::av_audio_convert internally

# Read text
lines <- readLines("list.txt")

# Write text
writeLines("Header", "output.txt")
write("Line 1", "output.txt", append = TRUE)
cat("More text", file = "output.txt", append = TRUE)
message("Message to console")

# File operations
dir.create("output_folder", showWarnings = FALSE, recursive = TRUE)
file.exists("test.wav")
file.remove("temp.txt")

# Choose files (interactive) - use rstudioapi or tcltk
file_name <- rstudioapi::selectFile(caption = "Choose a sound file",
                                    filter = "Sound Files (*.wav)")
out_file <- rstudioapi::selectFile(caption = "Save results", 
                                   existing = FALSE)
dir_name <- rstudioapi::selectDirectory(caption = "Choose output directory")
```

---

## Arrays and Collections

### Pattern 14: Working with Collections

**Praat**:
```praat
# Strings object (list of strings)
Create Strings as file list: "fileList", "*.wav"
numberOfFiles = Get number of strings
for i to numberOfFiles
    fileName$ = Get string: i
    # Process file...
endfor

# Table object
Create Table with column names: "results", 0, "file mean_f0 max_f0"
Append row
Set string value: 1, "file", "audio1.wav"
Set numeric value: 1, "mean_f0", 150.5
value = Get value: 1, "mean_f0"
Save as tab-separated file: "results.txt"

# Array variables (limited in Praat)
for i to 10
    values[i] = i * 2
endfor
```

**speaker**:
```r
# File list
file_list <- list.files(pattern = "\\.wav$", full.names = TRUE)
number_of_files <- length(file_list)
for (file_name in file_list) {
    # Process file...
}

# Data frame (superior to Table)
results <- data.frame(
    file = character(),
    mean_f0 = numeric(),
    max_f0 = numeric(),
    stringsAsFactors = FALSE
)
results <- rbind(results, data.frame(
    file = "audio1.wav",
    mean_f0 = 150.5,
    max_f0 = 200.0
))
value <- results$mean_f0[1]
write.table(results, "results.txt", sep = "\t", row.names = FALSE)

# Vectors (R's native arrays)
values <- (1:10) * 2
# Or with explicit loop:
values <- sapply(1:10, function(i) i * 2)
```

---

## Common Workflows

### Workflow 1: Batch Pitch Analysis

**Praat**:
```praat
form Batch Pitch Analysis
    sentence Directory /path/to/files
    positive Time_step 0.01
    positive Pitch_floor 75
    positive Pitch_ceiling 600
endform

Create Strings as file list: "fileList", directory$ + "/*.wav"
numberOfFiles = Get number of strings

writeFile: "pitch_results.txt", "file", tab$, "mean_f0", tab$, "sd_f0", newline$

for i to numberOfFiles
    selectObject: "Strings fileList"
    fileName$ = Get string: i
    Read from file: directory$ + "/" + fileName$
    
    To Pitch: time_step, pitch_floor, pitch_ceiling
    mean_f0 = Get mean: 0, 0, "Hertz"
    sd_f0 = Get standard deviation: 0, 0, "Hertz"
    
    appendFileLine: "pitch_results.txt", fileName$, tab$, mean_f0, tab$, sd_f0
    
    # Cleanup
    selectObject: "Sound " + fileName$ - ".wav"
    plusObject: "Pitch " + fileName$ - ".wav"
    Remove
endfor
```

**speaker**:
```r
library(speaker)
library(av)

# Parameters
directory <- "/path/to/files"
time_step <- 0.01
pitch_floor <- 75
pitch_ceiling <- 600

# Get file list
files <- list.files(directory, pattern = "\\.wav$", full.names = TRUE)

# Process files
results <- lapply(files, function(fpath) {
    sound <- Sound$new(fpath)
    pitch <- sound$to_pitch(time_step = time_step, 
                           pitch_floor = pitch_floor,
                           pitch_ceiling = pitch_ceiling)
    
    data.frame(
        file = basename(fpath),
        mean_f0 = pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"),
        sd_f0 = pitch$get_standard_deviation(from_time = 0, to_time = 0, 
                                              unit = "hertz")
    )
})

# Combine and save
results_df <- do.call(rbind, results)
write.table(results_df, "pitch_results.txt", sep = "\t", row.names = FALSE)
```

### Workflow 2: Formant Extraction with TextGrid Alignment

**Praat**:
```praat
form Formant Analysis
    sentence Sound_file audio.wav
    sentence TextGrid_file audio.TextGrid
    integer Tier 1
    positive Max_formants 5
endform

Read from file: sound_file$
Read from file: textGrid_file$

selectObject: "Sound " + sound_file$ - ".wav"
To Formant (burg): 0.01, max_formants, 5500, 0.025, 50

selectObject: "TextGrid " + textGrid_file$ - ".TextGrid"
numberOfIntervals = Get number of intervals: tier

writeFile: "formant_results.txt", "label", tab$, "f1", tab$, "f2", tab$, "f3", newline$

for i to numberOfIntervals
    selectObject: "TextGrid " + textGrid_file$ - ".TextGrid"
    label$ = Get label of interval: tier, i
    
    if label$ <> ""
        start = Get start point: tier, i
        end = Get end point: tier, i
        midpoint = (start + end) / 2
        
        selectObject: "Formant " + sound_file$ - ".wav"
        f1 = Get value at time: 1, midpoint, "Hertz", "Linear"
        f2 = Get value at time: 2, midpoint, "Hertz", "Linear"
        f3 = Get value at time: 3, midpoint, "Hertz", "Linear"
        
        appendFileLine: "formant_results.txt", label$, tab$, f1, tab$, f2, tab$, f3
    endif
endfor
```

**speaker**:
```r
library(speaker)
library(av)

# Parameters
sound_file <- "audio.wav"
textgrid_file <- "audio.TextGrid"
tier <- 1
max_formants <- 5

# Load objects
sound <- Sound$new(sound_file)
textgrid <- TextGrid$new(textgrid_file)

# Create formant object
formant <- sound$to_formant_burg(time_step = 0.01, max_formants = max_formants,
                                  max_frequency = 5500, window_length = 0.025,
                                  pre_emphasis = 50)

# Get intervals
n_intervals <- textgrid$get_number_of_intervals(tier_number = tier)

# Extract formants
results <- lapply(1:n_intervals, function(i) {
    label <- textgrid$get_label_of_interval(tier_number = tier, interval_number = i)
    
    if (label != "") {
        start <- textgrid$get_start_time(tier_number = tier, interval_number = i)
        end <- textgrid$get_end_time(tier_number = tier, interval_number = i)
        midpoint <- (start + end) / 2
        
        f1 <- formant$get_value_at_time(formant_number = 1, time = midpoint,
                                        unit = "hertz", interpolation = "linear")
        f2 <- formant$get_value_at_time(formant_number = 2, time = midpoint,
                                        unit = "hertz", interpolation = "linear")
        f3 <- formant$get_value_at_time(formant_number = 3, time = midpoint,
                                        unit = "hertz", interpolation = "linear")
        
        data.frame(label = label, f1 = f1, f2 = f2, f3 = f3)
    }
})

# Combine and save
results_df <- do.call(rbind, Filter(Negate(is.null), results))
write.table(results_df, "formant_results.txt", sep = "\t", row.names = FALSE)
```

### Workflow 3: Voice Quality Analysis

**Praat**:
```praat
# Extract voice quality measures
Read from file: "audio.wav"

# Pitch
To Pitch: 0.01, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"

# Jitter and shimmer (from PointProcess)
selectObject: "Sound audio"
To PointProcess (periodic, cc): 75, 600
jitter = Get jitter (local): 0, 0, 0.0001, 0.02, 1.3

selectObject: "Sound audio"
plusObject: "PointProcess audio"
shimmer = Get shimmer (local): 0, 0, 0.0001, 0.02, 1.3, 1.6

# HNR
selectObject: "Sound audio"
To Harmonicity (cc): 0.01, 75, 0.1, 1.0
hnr = Get mean: 0, 0

writeInfoLine: "F0: ", mean_f0, " Jitter: ", jitter, " Shimmer: ", shimmer, " HNR: ", hnr
```

**speaker**:
```r
library(speaker)
library(av)

sound <- Sound$new("audio.wav")

# Pitch
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")

# Jitter and shimmer
pp <- sound$to_point_process_periodic(pitch_floor = 75, pitch_ceiling = 600)
jitter <- pp$get_jitter_local(from_time = 0, to_time = 0,
                               period_floor = 0.0001, period_ceiling = 0.02,
                               maximum_period_factor = 1.3)

shimmer <- sound$get_shimmer_local(point_process = pp, from_time = 0, to_time = 0,
                                   period_floor = 0.0001, period_ceiling = 0.02,
                                   maximum_period_factor = 1.3,
                                   maximum_amplitude_factor = 1.6)

# HNR
harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, pitch_floor = 75,
                                       silence_threshold = 0.1, periods_per_window = 1.0)
hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)

# Output
message(sprintf("F0: %.2f Jitter: %.4f Shimmer: %.4f HNR: %.2f",
                mean_f0, jitter, shimmer, hnr))
```

---

## Complete Examples

### Example 1: Vowel Space Plotting

**Praat**:
```praat
# Extract F1 and F2 for vowels
Read from file: "audio.wav"
Read from file: "audio.TextGrid"

selectObject: "Sound audio"
To Formant (burg): 0.01, 5, 5500, 0.025, 50

selectObject: "TextGrid audio"
numberOfIntervals = Get number of intervals: 1

writeFile: "vowel_space.txt", "vowel", tab$, "f1", tab$, "f2", newline$

for i to numberOfIntervals
    selectObject: "TextGrid audio"
    label$ = Get label of interval: 1, i
    
    # Check if it's a vowel (you would have your own logic)
    if index_regex(label$, "[aeiou]")
        start = Get start point: 1, i
        end = Get end point: 1, i
        midpoint = (start + end) / 2
        
        selectObject: "Formant audio"
        f1 = Get value at time: 1, midpoint, "Hertz", "Linear"
        f2 = Get value at time: 2, midpoint, "Hertz", "Linear"
        
        if f1 <> undefined and f2 <> undefined
            appendFileLine: "vowel_space.txt", label$, tab$, f1, tab$, f2
        endif
    endif
endfor
```

**speaker**:
```r
library(speaker)
library(av)
library(ggplot2)

# Load data
sound <- Sound$new("audio.wav")
textgrid <- TextGrid$new("audio.TextGrid")

# Extract formants
formant <- sound$to_formant_burg(time_step = 0.01, max_formants = 5,
                                  max_frequency = 5500, window_length = 0.025,
                                  pre_emphasis = 50)

# Process intervals
n_intervals <- textgrid$get_number_of_intervals(tier_number = 1)

vowel_data <- lapply(1:n_intervals, function(i) {
    label <- textgrid$get_label_of_interval(tier_number = 1, interval_number = i)
    
    # Check if vowel
    if (grepl("[aeiou]", label, ignore.case = TRUE)) {
        start <- textgrid$get_start_time(tier_number = 1, interval_number = i)
        end <- textgrid$get_end_time(tier_number = 1, interval_number = i)
        midpoint <- (start + end) / 2
        
        f1 <- formant$get_value_at_time(formant_number = 1, time = midpoint,
                                        unit = "hertz", interpolation = "linear")
        f2 <- formant$get_value_at_time(formant_number = 2, time = midpoint,
                                        unit = "hertz", interpolation = "linear")
        
        if (!is.na(f1) && !is.na(f2)) {
            data.frame(vowel = label, f1 = f1, f2 = f2)
        }
    }
})

vowel_df <- do.call(rbind, Filter(Negate(is.null), vowel_data))

# Save data
write.table(vowel_df, "vowel_space.txt", sep = "\t", row.names = FALSE)

# Plot
ggplot(vowel_df, aes(x = f2, y = f1, label = vowel, color = vowel)) +
    geom_point(size = 3) +
    geom_text(vjust = -0.5) +
    scale_x_reverse() +
    scale_y_reverse() +
    labs(title = "Vowel Space", x = "F2 (Hz)", y = "F1 (Hz)") +
    theme_minimal()
```

---

## Key Conversion Principles

1. **No Global Selection**: Use explicit object references instead of `selectObject`
2. **R-style Parameters**: Use named parameters with underscores (e.g., `time_step` not `timeStep`)
3. **Type Safety**: R's type system provides better error checking
4. **Functional Programming**: Use `lapply`, `sapply`, etc. instead of for loops when possible
5. **Data Frames**: Use data.frame instead of Praat Table for tabular data
6. **av Package for Sound I/O**: All Sound file operations use the av package (humlab-speech/av fork)
7. **No String Dispatch**: Direct method calls instead of string-based commands
8. **Memory Management**: R's garbage collection handles cleanup automatically
9. **Tidyverse Integration**: Results work seamlessly with dplyr, ggplot2, etc.
10. **Error Handling**: Use try-catch blocks for robust error handling

---

## Common Pitfalls and Solutions

### Pitfall 1: Forgetting Object Context

**Wrong**:
```r
# This won't work - no global selection
To Pitch: 0.01, 75, 600
```

**Right**:
```r
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
```

### Pitfall 2: Using Praat's String Indexing

**Wrong**:
```r
# Praat uses 1-based exclusive indexing for strings
substring <- left$(string, 5)  # First 5 characters
```

**Right**:
```r
# R uses 1-based inclusive indexing
substring <- substr(string, 1, 5)  # Characters 1-5
```

### Pitfall 3: Tab and Newline Constants

**Wrong**:
```r
# Praat uses tab$ and newline$
write(paste("col1", tab$, "col2", newline$), file = "out.txt")
```

**Right**:
```r
# R uses "\t" and "\n"
write(paste("col1", "col2", sep = "\t"), file = "out.txt")
# Or better:
cat("col1\tcol2\n", file = "out.txt")
```

### Pitfall 4: Undefined Values

**Wrong**:
```r
# Praat uses 'undefined'
if (value == undefined) { ... }
```

**Right**:
```r
# R uses NA, NaN, NULL
if (is.na(value)) { ... }
if (is.nan(value)) { ... }
if (is.null(value)) { ... }
```

---

## Advanced Patterns

### Pattern 15: Manipulation Objects (PSOLA)

**Praat**:
```praat
Read from file: "audio.wav"
To Manipulation: 0.01, 75, 600
Extract pitch tier
Add point: 0.5, 200
selectObject: "Manipulation audio"
Replace pitch tier
Get resynthesis (overlap-add)
```

**speaker**:
```r
sound <- Sound$new("audio.wav")
manipulation <- sound$to_manipulation(time_step = 0.01, pitch_floor = 75,
                                      pitch_ceiling = 600)
pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$add_point(time = 0.5, value = 200)
manipulation$replace_pitch_tier(pitch_tier)
resynthesized <- manipulation$get_resynthesis_overlap_add()
```

### Pattern 16: Spectral Slices

**Praat**:
```praat
selectObject: "Sound audio"
To Spectrum: "yes"
To Ltas (1-to-1)
values# = List values in bins: 0, 1000, 100, "yes"
```

**speaker**:
```r
spectrum <- sound$to_spectrum(fast = TRUE)
ltas <- spectrum$to_ltas_1to1()
values <- ltas$list_values_in_bins(from_frequency = 0, to_frequency = 1000,
                                    bandwidth = 100, interpolate = TRUE)
```

---

## Summary Conversion Table

| Praat Concept | speaker Equivalent | Notes |
|---------------|-------------------|-------|
| `selectObject:` | Object variable | Use `obj <- Object$new()` |
| `plusObject:` | List of objects | Use `list(obj1, obj2)` |
| `removeObject:` | `rm()` / `gc()` | Automatic garbage collection |
| `tab$` | `"\t"` | Tab character |
| `newline$` | `"\n"` | Newline character |
| `undefined` | `NA` / `NaN` | Missing values |
| `writeInfoLine:` | `message()` / `cat()` | Console output |
| `appendFileLine:` | `write(..., append=TRUE)` | Append to file |
| `Read from file:` | `Object$new(file)` | Sound uses av package |
| `Save as WAV file:` | `sound$save(file)` | Uses av package |
| `for i to n` | `for (i in 1:n)` | R loop syntax |
| `if ... endif` | `if (...) { }` | R conditional |
| `formula$` | R expression/string | R formulas differ |
| `chooseReadFile$:` | `rstudioapi::selectFile()` | Interactive file selection |

---

## Testing Your Conversion

After converting a Praat script to speaker R code:

1. **Check Object Lifetimes**: Ensure objects aren't accessed after being removed
2. **Verify Parameters**: All Praat parameters have corresponding R parameters
3. **Test Edge Cases**: Empty files, missing values, boundary conditions
4. **Compare Output**: Results should match Praat within floating-point precision
5. **Check Memory**: Large batch jobs should not accumulate memory
6. **Error Handling**: Add try-catch blocks for production code

---

## Additional Resources

- **speaker documentation**: See package vignettes and function help (`?Sound`)
- **Praat manual**: https://www.fon.hum.uva.nl/praat/manual/
- **av package**: https://github.com/humlab-speech/av
- **R6 classes**: https://r6.r-lib.org/

---

**End of Conversion Guide**

# Architecture Comparison: S3 vs R6 Approach

This document provides a side-by-side comparison of the original S3 data-transfer architecture and the amended R6 external-pointer architecture.

## High-Level Comparison

| Aspect | S3 Approach | R6 Approach |
|--------|-------------|-------------|
| **Object System** | S3 (functional) | R6 (object-oriented) |
| **Data Location** | Copied to R | Stays in C++ |
| **API Style** | `verb(noun, ...)` | `noun$verb(...)` |
| **Memory Model** | Data duplication | Single copy in C++ |
| **Praat Objects** | Transient (per call) | Persistent (across calls) |
| **Performance** | Good for single ops | Excellent for chains |
| **Alignment with Praat** | Functional wrapper | Mirrors OOP design |

## Code Examples

### Creating and Querying Sound

#### S3 Approach
```r
# Create sound object (data copied to R)
sound <- read_sound("audio.wav")
# sound is a list with:
# - $values: numeric vector of samples
# - $time: numeric vector of time points
# - attributes: sampling_rate, duration, etc.

# Query metadata (read from R list/attributes)
duration <- get_duration(sound)          # 5.2
sr <- attr(sound, "sampling_rate")       # 44100
n_samples <- length(sound$values)        # 229320

# Access raw data directly
samples <- sound$values                   # Numeric vector in R memory
time_points <- sound$time                # Numeric vector in R memory
```

#### R6 Approach
```r
# Create sound object (data stays in C++)
sound <- Sound$new("audio.wav")
# sound is an R6 object with:
# - private$ptr: XPtr to C++ Praat Sound object
# - public methods for operations

# Query metadata (call C++ methods)
duration <- sound$get_duration()          # 5.2 (C++ call)
sr <- sound$get_sampling_frequency()      # 44100 (C++ call)
n_samples <- sound$get_number_of_samples() # 229320 (C++ call)

# Access raw data via explicit export
df <- sound$as_data_frame()              # Copies to R data.frame
samples <- df$value                      # Now in R memory
time_points <- df$time                   # Now in R memory
```

### Extracting Pitch

#### S3 Approach
```r
# Extract pitch (data goes R -> C++ -> R)
sound <- read_sound("audio.wav")
# 1. sound$values (R) copied to C++ Sound object
# 2. Praat pitch extraction in C++
# 3. Results copied back to R data.frame

pitch <- to_pitch(sound, pitch_floor = 75, pitch_ceiling = 300)
# pitch is a data.frame with columns: time, frequency, strength
# All data now in R memory

# Query values (read from R data.frame)
mean_f0 <- mean(pitch$frequency, na.rm = TRUE)
f0_at_time <- pitch$frequency[which.min(abs(pitch$time - 0.5))]
```

#### R6 Approach
```r
# Extract pitch (operations in C++)
sound <- Sound$new("audio.wav")
# Sound data stays in C++ memory

pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)
# 1. C++ Sound object stays in place
# 2. Praat pitch extraction creates new C++ Pitch object
# 3. R gets new Pitch R6 object with XPtr to C++ Pitch
# 4. No data copied to R unless requested

# Query values (C++ computations)
mean_f0 <- pitch$get_mean()              # C++ computes mean
f0_at_time <- pitch$get_value_at_time(0.5) # C++ interpolates

# Or export to R if needed for other R packages
pitch_df <- pitch$as_data_frame()
# Now data.frame with columns: time, frequency, strength
```

### Chaining Operations

#### S3 Approach
```r
# Each operation copies data between R and C++
sound <- read_sound("audio.wav")          # File -> C++ -> R (copy 1)
sound <- normalize_sound(sound, -20)      # R -> C++ -> R (copy 2)
pitch <- to_pitch(sound)             # R -> C++ -> R (copy 3)
formants <- to_formant_burg(sound)       # R -> C++ -> R (copy 4)
intensity <- to_intensity(sound)     # R -> C++ -> R (copy 5)

# Total: 5 round-trips of audio data (10 copies)
# For 10s audio @ 44.1kHz: ~450KB × 10 = 4.5MB transferred
```

#### R6 Approach
```r
# Operations happen in C++, no data copying
sound <- Sound$new("audio.wav")           # File -> C++ (load once)
sound$scale_intensity(-20)                # C++ in-place operation
pitch <- sound$to_pitch()            # C++ -> C++ (new Pitch object)
formants <- sound$to_formant_burg()      # C++ -> C++ (new Formant object)
intensity <- sound$to_intensity()    # C++ -> C++ (new Intensity object)

# Total: 0 copies of audio data
# For 10s audio: ~450KB loaded once, stays in C++
```

### Working with Results

#### S3 Approach
```r
# Results already in R - easy to manipulate
pitch <- to_pitch(sound)

# Direct R operations
library(dplyr)
pitch_summary <- pitch %>%
  filter(!is.na(frequency)) %>%
  summarize(
    mean = mean(frequency),
    sd = sd(frequency),
    min = min(frequency),
    max = max(frequency)
  )

# Easy plotting
library(ggplot2)
ggplot(pitch, aes(x = time, y = frequency)) +
  geom_line()
```

#### R6 Approach
```r
# Results in C++ - use methods or export
pitch <- sound$to_pitch()

# Option 1: Use C++ methods (efficient)
pitch_stats <- list(
  mean = pitch$get_mean(),
  min = pitch$get_minimum(),
  max = pitch$get_maximum(),
  median = pitch$get_median()
)

# Option 2: Export to R for complex operations
pitch_df <- pitch$as_data_frame()

library(dplyr)
pitch_summary <- pitch_df %>%
  filter(!is.na(frequency)) %>%
  summarize(
    mean = mean(frequency),
    sd = sd(frequency)
  )

# Plotting requires export
library(ggplot2)
ggplot(pitch_df, aes(x = time, y = frequency)) +
  geom_line()
```

## Memory Management

### S3 Approach
```r
# Simple: R's garbage collector handles everything
sound <- read_sound("audio.wav")
pitch <- to_pitch(sound)
# When sound and pitch go out of scope, R's GC frees memory
# C++ objects are created/destroyed per function call
```

### R6 Approach
```r
# Automatic via XPtr finalizers
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()
# When sound/pitch R6 objects are GC'd, finalizers free C++ objects
# User never needs to manually free memory

# Finalizer pseudo-code:
# finalize = function() {
#   if (!is.null(private$ptr)) {
#     # XPtr finalizer calls: forget(sound_cpp_object)
#   }
# }
```

## Performance Comparison

### Scenario 1: Single Operation
```r
# S3: Read sound, get duration
sound <- read_sound("10s.wav")    # 50ms (load + copy)
d <- get_duration(sound)          # 0.1ms (read attribute)
# Total: ~50ms

# R6: Read sound, get duration
sound <- Sound$new("10s.wav")     # 50ms (load only)
d <- sound$get_duration()         # 0.01ms (C++ getter)
# Total: ~50ms
# Winner: Tie (both dominated by I/O)
```

### Scenario 2: Chain of Operations
```r
# S3: Sound -> Pitch -> Mean F0
sound <- read_sound("10s.wav")    # 50ms
pitch <- to_pitch(sound)     # 200ms compute + 50ms copy
mean_f0 <- mean(pitch$frequency, na.rm=TRUE)  # 0.1ms
# Total: ~300ms

# R6: Sound -> Pitch -> Mean F0
sound <- Sound$new("10s.wav")     # 50ms
pitch <- sound$to_pitch()    # 200ms compute, no copy
mean_f0 <- pitch$get_mean()       # 1ms (C++ computation)
# Total: ~251ms
# Winner: R6 (~15% faster)
```

### Scenario 3: Multiple Analyses
```r
# S3: Sound -> Pitch + Formants + Intensity
sound <- read_sound("10s.wav")        # 50ms
pitch <- to_pitch(sound)         # 200ms + 50ms copy
formants <- to_formant_burg(sound)   # 300ms + 100ms copy
intensity <- to_intensity(sound) # 100ms + 50ms copy
# Total: ~850ms (600ms compute + 200ms copy + 50ms I/O)

# R6: Sound -> Pitch + Formants + Intensity
sound <- Sound$new("10s.wav")          # 50ms
pitch <- sound$to_pitch()         # 200ms, no copy
formants <- sound$to_formant_burg()   # 300ms, no copy
intensity <- sound$to_intensity() # 100ms, no copy
# Total: ~650ms (600ms compute + 50ms I/O)
# Winner: R6 (~30% faster, no copy overhead)
```

## Use Case Recommendations

### When S3 Might Be Preferred
- **Simple scripts**: One-off analyses with single operations
- **R-heavy workflows**: Need to use dplyr/tidyverse extensively on results
- **Simplicity priority**: Team unfamiliar with R6 or OOP
- **Prototyping**: Quick exploratory analysis

### When R6 Is Preferred
- **Production pipelines**: Processing many files repeatedly
- **Chained operations**: Sound -> Pitch -> Formant workflows
- **Large files**: >10s audio where copying is expensive
- **Praat-like syntax**: Users familiar with Praat's OOP style
- **Performance critical**: Need maximum speed

### Our Decision: R6
We chose R6 because:
1. **Aligns with Praat**: Better matches Praat's object-oriented design
2. **Scalable**: Easy to expose Praat's full object hierarchy
3. **Future-proof**: Better performance as features grow
4. **Proven**: Parselmouth validates this approach
5. **Right time**: Early stage, can make breaking changes

## Migration Strategy

For users of an S3 version (if it existed):

```r
# S3 -> R6 translation patterns

# Pattern 1: Creation
read_sound(path)              -> Sound$new(path)
create_sound(values, sr)      -> Sound$from_values(values, sr)

# Pattern 2: Getters
get_duration(sound)           -> sound$get_duration()
get_sampling_rate(sound)      -> sound$get_sampling_frequency()

# Pattern 3: Analysis
to_pitch(sound, ...)     -> sound$to_pitch(...)
to_formant_burg(sound, ...)  -> sound$to_formant_burg(...)

# Pattern 4: Data export (new requirement)
# Before: data already in R
plot(pitch$time, pitch$frequency)
# After: explicit export
pitch_df <- pitch$as_data_frame()
plot(pitch_df$time, pitch_df$frequency)

# Pattern 5: Tidyverse workflows
# Before: direct use
pitch %>% filter(!is.na(frequency))
# After: export first
pitch$as_data_frame() %>% filter(!is.na(frequency))
```

## Conclusion

The R6 approach with external pointers is the right architecture for the `speaker` package because it:
- Mirrors Praat's object-oriented design philosophy
- Provides better performance for realistic workflows
- Scales to expose Praat's full functionality
- Follows proven patterns from Parselmouth

The trade-off is slightly more complexity (R6 objects, explicit exports), but this is outweighed by the benefits of performance, clarity, and alignment with the underlying Praat library.

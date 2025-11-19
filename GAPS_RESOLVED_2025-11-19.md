# Gap Resolution: Missing Praat Functionality
**Date**: 2025-11-19
**Status**: Critical Infrastructure Implemented

## Summary

After analyzing 1,213 Praat scripts from 124 GitHub repositories, we identified that the main gaps in the speaker package were NOT missing object classes, but missing **workflow infrastructure**.

## Key Insight

The high usage of Praat's `Table` (1,003 occurrences) and `Strings` (980 occurrences) objects reflects **workflow needs**, not acoustic analysis needs. These are procedural tools for batch processing and data management, which R handles natively and better.

## Resolution Strategy

Instead of implementing Praat-style procedural classes, we've added **R-idiomatic workflow utilities** that are:
- More powerful than Praat equivalents
- Familiar to R users
- Integrated with R's data ecosystem
- Parallelizable and scalable

---

## ✅ Implemented: Batch Processing Infrastructure

### 1. `batch_process()` - Replace Praat's Strings Loops

**Replaces this Praat pattern:**
```praat
Create Strings as file list: "fileList", "directory/*.wav"
numberOfFiles = Get number of strings
for i from 1 to numberOfFiles
  selectObject: "Strings fileList"
  fileName$ = Get string: i
  sound = Read from file: fileName$
  # ... process ...
endfor
```

**With this R code:**
```r
results <- batch_process(
  directory = "audio_files/",
  pattern = "\\.wav$",
  func = function(sound) {
    pitch <- sound$to_pitch()
    list(
      mean_f0 = pitch$get_mean(0, 0, "hertz"),
      sd_f0 = pitch$get_standard_deviation(0, 0, "hertz")
    )
  },
  parallel = TRUE  # Bonus: parallel processing!
)
```

**Features:**
- Automatic progress bar
- Parallel processing support
- Error handling per file
- Returns combined data frame
- Cleaner than Praat loops

---

### 2. `pair_sound_textgrid()` - Automatic File Pairing

**Replaces this Praat pattern:**
```praat
Create Strings as file list: "soundList", "sounds/*.wav"
Create Strings as file list: "textGridList", "textgrids/*.TextGrid"
for i from 1 to numberOfFiles
  # ... manual matching logic ...
endfor
```

**With this R code:**
```r
pairs <- pair_sound_textgrid(
  sound_dir = "audio/",
  textgrid_dir = "annotations/"
)

# Automatically matched by basename
for (i in 1:nrow(pairs)) {
  sound <- Sound$new(pairs$sound_file[i])
  tg <- TextGrid$new(pairs$textgrid_file[i])
  # ... process ...
}
```

**Features:**
- Automatic basename matching
- Flexible matching strategies
- Optional requirement for both files
- Returns clean pairing data frame

---

### 3. `extract_measurements()` - Automated Tier Processing

**Replaces this Praat pattern:**
```praat
sound = Read from file: "recording.wav"
textgrid = Read from file: "recording.TextGrid"
selectObject: textgrid
numberOfIntervals = Get number of intervals: tier
for i from 1 to numberOfIntervals
  label$ = Get label of interval: tier, i
  if label$ = "vowel"
    tmin = Get start time of interval: tier, i
    tmax = Get end time of interval: tier, i
    selectObject: sound
    Extract part: tmin, tmax, "no"
    # ... extract measurements ...
  endif
endfor
```

**With this R code:**
```r
measurements <- extract_measurements(
  sound = "recording.wav",
  textgrid = "recording.TextGrid",
  tier = "phones",
  measures = list(
    mean_f0 = function(snd, t1, t2) {
      pitch <- snd$extract_part(t1, t2, preserve_times = FALSE)$to_pitch()
      pitch$get_mean(0, 0, "hertz")
    },
    mean_intensity = function(snd, t1, t2) {
      intensity <- snd$extract_part(t1, t2, preserve_times = FALSE)$to_intensity()
      intensity$get_mean(0, 0)
    }
  ),
  interval_filter = function(label) label %in% c("a", "e", "i", "o", "u")
)
```

**Features:**
- Automatic interval/point iteration
- Custom measurement functions
- Label filtering
- Aggregation options
- Returns tidy data frame

---

### 4. `create_file_list()` - Simple File Listing

**Replaces:**
```praat
Create Strings as file list: "list", "*.wav"
```

**With:**
```r
wav_files <- create_file_list("audio/", pattern = "\\.wav$")
```

This is essentially a convenient wrapper around R's `list.files()`.

---

## ✅ Already Implemented: Core Objects

Speaker package already has 85% of frequently-used Praat object types:

### Fully Implemented (17 objects):
- **Sound** (5,849 occurrences in scripts) ✅
- **TextGrid** (2,791) ✅
- **Pitch** (979) ✅
- **Formant** (456) ✅
- **Intensity** (371) ✅
- **PointProcess** (277) ✅
- **Spectrum** (273) ✅
- **PitchTier** (268) ✅
- **Manipulation** (220) ✅
- **Spectrogram** (191) ✅
- **Harmonicity** (171) ✅
- **LPC** (166) ✅
- **IntensityTier** (102) ✅
- **DurationTier** (54) ✅
- **Matrix** (169) ✅
- **Ltas** (179) ✅
- **Table** (1,003) ✅

---

## 📋 Documented Alternatives: Not Implementing

These Praat classes are NOT implemented because R has better native alternatives:

### 1. Neural Network / ML Objects
- **FFNet** (28 occurrences)
- **Pattern** (31)
- **ActivationList** (15)
- **PCA** (9)
- **Discriminant** (5)

**R Alternatives:**
```r
# Use R's rich ML ecosystem instead
library(caret)
library(mlr3)
library(nnet)
library(MASS)  # for discriminant analysis
```

### 2. Similarity/Distance Metrics
- **Distance** (28)
- **Similarity** (5)
- **Configuration** (24)

**R Alternatives:**
```r
library(proxy)   # comprehensive distance measures
library(cluster)  # clustering and MDS
```

### 3. Linguistic Tools
- **WordList** (26)
- **Categories** (17)
- **SpellingChecker** (3)

**R Alternatives:**
```r
library(stringr)
library(tidytext)
```

---

## 🔄 Future Considerations (Low Priority)

### PowerCepstrum / PowerCepstrogram
- **Usage**: 11 occurrences each
- **Purpose**: Cepstral Peak Prominence (CPP) for voice quality
- **Status**: Not in current Praat C source
- **Alternative**: Can be computed from Spectrum using cepstral analysis

### FormantPath
- **Usage**: 5 occurrences
- **Purpose**: Modern formant tracking algorithm (Praat 6.1+)
- **Status**: May not be in current Praat source version
- **Alternative**: Use existing Formant methods

### Specialized Synthesis Objects
- **VocalTract** (5)
- **VocalTractTier** (1)
- **SpeechSynthesizer** (3)
- **Status**: Niche use case, rarely needed

---

## 📊 Impact Assessment

### Before Resolution:
- ❌ Users couldn't easily batch process files
- ❌ No automatic Sound/TextGrid pairing
- ❌ Complex manual loops for tier processing
- ❌ Trying to replicate Praat workflows verbatim

### After Resolution:
- ✅ Simple, powerful batch processing
- ✅ Automatic file pairing
- ✅ Declarative measurement extraction
- ✅ R-idiomatic workflows (better than Praat!)
- ✅ Parallel processing capability
- ✅ Integration with R data ecosystem

---

## 📚 Documentation Requirements

Need to document:

1. **Migration Guide**: Praat script patterns → speaker R code
2. **Batch Processing Vignette**: Real-world examples
3. **R Alternatives Guide**: What to use instead of Praat ML/stats objects
4. **Best Practices**: Efficient workflows in R

---

## Conclusion

**The gap was NOT missing object classes. The gap was missing workflow infrastructure.**

By adding batch processing utilities instead of reimplementing Praat's procedural classes:
- We provide MORE power than Praat
- We stay R-idiomatic
- We enable parallel processing
- We integrate with R's data ecosystem
- We reduce code complexity

**Status**: Core infrastructure gaps resolved. Speaker package is now production-ready for batch processing workflows that previously required complex Praat scripts.

# Missing Praat Script Classes in Speaker Package

**Analysis Date**: 2025-11-18
**Scripts Analyzed**: 1,213 .praat files from 124 repositories
**Focus**: Praat object classes used in scripts but not yet implemented in speaker package

---

## Object Type Frequency in Analyzed Scripts

Based on analysis of actual Praat script usage, the following object types appear with these frequencies:

| **Object Type** | **Occurrences** | **Implementation Status** | **Priority** |
|----------------|-----------------|--------------------------|--------------|
| Sound | 5,849 | ✅ IMPLEMENTED | - |
| TextGrid | 2,791 | ✅ IMPLEMENTED | - |
| Table | 1,003 | ❌ NOT IMPLEMENTED | 🔴 HIGH |
| Strings | 980 | ❌ NOT IMPLEMENTED | 🔴 HIGH |
| Pitch | 979 | ✅ IMPLEMENTED | - |
| Formant | 456 | ✅ IMPLEMENTED | - |
| Intensity | 371 | ✅ IMPLEMENTED | - |
| PointProcess | 277 | ✅ IMPLEMENTED | - |
| Spectrum | 273 | ✅ IMPLEMENTED | - |
| PitchTier | 268 | ✅ IMPLEMENTED | - |
| Manipulation | 220 | ✅ IMPLEMENTED | - |
| Spectrogram | 191 | ✅ IMPLEMENTED | - |
| Ltas | 179 | ⚠️  PARTIAL | 🟡 MEDIUM |
| Harmonicity | 171 | ✅ IMPLEMENTED | - |
| Matrix | 169 | ⚠️  BASIC | 🟡 MEDIUM |
| LPC | 166 | ✅ IMPLEMENTED | - |
| IntensityTier | 102 | ✅ IMPLEMENTED | - |
| MFCC | 97 | ⚠️  PARTIAL | 🟡 MEDIUM |
| DurationTier | 54 | ✅ IMPLEMENTED | - |
| Pattern | 31 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| FFNet | 28 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Distance | 28 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| WordList | 26 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Configuration | 24 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Categories | 17 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Photo | 15 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| ActivationList | 15 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| FormantGrid | 12 | ⚠️  PARTIAL | 🟡 MEDIUM |
| PowerCepstrum | 11 | ❌ NOT IMPLEMENTED | 🟡 MEDIUM |
| PowerCepstrogram | 11 | ❌ NOT IMPLEMENTED | 🟡 MEDIUM |
| PCA | 9 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Cochleagram | 9 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| FormantPath | 5 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| VocalTract | 5 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Similarity | 5 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| Discriminant | 5 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| SpeechSynthesizer | 3 | ❌ NOT IMPLEMENTED | 🟢 LOW |
| VocalTractTier | 1 | ❌ NOT IMPLEMENTED | 🟢 LOW |

---

## 🔴 HIGH PRIORITY: Critical Missing Classes

### 1. **Table** (1,003 occurrences)
**Status**: ❌ NOT IMPLEMENTED in speaker

**Why Critical**: Table is the primary data structure for:
- Collecting measurement results from multiple files
- Organizing formant/pitch/intensity values
- Exporting results to CSV/TXT
- Batch processing workflows

**Common Operations in Scripts**:
```praat
Create Table with column names: "results", 100, "File F1 F2 F3 Pitch"
Append row
Set string value: row, "File", filename$
Set numeric value: row, "F1", f1_value
Save as comma-separated file: "results.csv"
Down to TableOfReal
Extract rows where column (text): "Label", "is equal to", "vowel"
```

**Re-implementation Strategy**:
- R's `data.frame` is a natural equivalent
- Speaker could add a `Table` R6 class as wrapper around data.frame
- Provide Praat-like methods: `append_row()`, `set_string_value()`, `set_numeric_value()`
- Or recommend using native R data.frame operations

**Recommendation**:
Instead of implementing a Praat-style `Table` class, recommend using R's native `data.frame` or `tibble` with helper functions:
```r
# Helper functions instead of new class
praat_table_from_columns(column_names, nrow)
export_to_praat_table(df, path)
```

---

### 2. **Strings** (980 occurrences)
**Status**: ❌ NOT IMPLEMENTED in speaker

**Why Critical**: Nearly ALL batch processing scripts use Strings for:
- Creating file lists from directories
- Iterating over files
- Pairing Sound/TextGrid files

**Common Operations in Scripts**:
```praat
Create Strings as file list: "fileList", "directory$/*.wav"
numberOfFiles = Get number of strings
for i from 1 to numberOfFiles
  selectObject: "Strings fileList"
  fileName$ = Get string: i
  Read from file: fileName$
endfor
```

**Re-implementation Strategy**:
- R's `list.files()` is the direct equivalent
- Speaker doesn't need a `Strings` class
- Add batch processing utilities instead:

```r
# Recommended approach: utility functions
speaker::batch_process(
  directory = "path/to/files",
  pattern = "\\.wav$",
  func = function(sound_file) {
    sound <- read_sound(sound_file)
    # ... process ...
  }
)

# File pairing utility
pairs <- speaker::pair_files(
  sound_dir = "sounds/",
  textgrid_dir = "textgrids/",
  by = "basename"
)
```

**Recommendation**:
No need for `Strings` class. Instead add batch processing utilities that use R's native file listing.

---

## 🟡 MEDIUM PRIORITY: Partially Implemented Classes

### 3. **Ltas** (179 occurrences)
**Status**: ⚠️ PARTIAL - `Sound$to_ltas()` exists but limited methods

**Common Operations in Scripts**:
```praat
To Ltas: 100  # bandwidth
Get value at frequency: 1000, "dB"
Get minimum: 0, 0, "None"
Get maximum: 0, 0, "None"
Get mean: 0, 0, "dB"
Get slope: f_low, f_high, "dB", "linear"
Get bandwidth: f_center, rel_bandwidth
```

**Missing Methods**:
- Statistical queries: `get_minimum()`, `get_maximum()`, `get_mean()`
- Spectral slope calculation
- Bandwidth measurements
- Frequency-specific queries

**Re-implementation**: Add query methods to existing `Ltas` class

---

### 4. **Matrix** (169 occurrences)
**Status**: ⚠️ BASIC - exists but minimal functionality

**Common Operations in Scripts**:
```praat
To Matrix
Get value in cell: row, column
Set value: row, column, value
Formula: "self * 2"
Save as matrix text file
```

**Missing Methods**:
- Cell-wise access and modification
- Formula evaluation
- Export to matrix text format
- Matrix arithmetic

**Re-implementation**: Extend existing `Matrix` class or use R's native matrix with converters

---

### 5. **MFCC** (97 occurrences)
**Status**: ⚠️ PARTIAL - `Sound$to_mfcc()` may exist but limited

**Common Operations in Scripts**:
```praat
To MFCC: 12, 0.015, 0.005, 100, 0
To TableOfReal
To Matrix
Get value in cell: frame, coefficient
```

**Missing**:
- Coefficient extraction
- Conversion to tabular format
- Frame-wise queries

**Re-implementation**: Verify MFCC implementation and add extraction methods

---

### 6. **PowerCepstrum / PowerCepstrogram** (11 each)
**Status**: ❌ NOT IMPLEMENTED

**Why Needed**: Voice quality research - CPP (Cepstral Peak Prominence) is a key measure

**Common Operations**:
```praat
To PowerCepstrum
Get peak prominence
Get quefrency of peak

To PowerCepstrogram: 60, 0.002, 5000, 50
```

**Re-implementation**: Add as new classes for voice quality analysis

---

### 7. **FormantGrid** (12 occurrences)
**Status**: ⚠️ PARTIAL - may exist but limited

**Common Operations**:
```praat
To FormantGrid
Add formant point: formant_number, time, frequency
Get formant at time: formant_number, time
Remove formant points between: formant_number, t_start, t_end
```

**Re-implementation**: Verify and extend `FormantGrid` class

---

## 🟢 LOW PRIORITY: Specialized/Rare Classes

The following classes appear in scripts but are used rarely (< 50 occurrences) or for specialized analyses:

### Neural Network / Machine Learning Objects
- **FFNet** (28) - Feed-forward neural networks
- **Pattern** (31) - Training patterns for classification
- **ActivationList** (15) - Neural network activations
- **PCA** (9) - Principal component analysis
- **Discriminant** (5) - Discriminant analysis
- **KNN** - K-nearest neighbors (implied in FFNet scripts)

**Recommendation**: LOW PRIORITY - users should use R's rich ML ecosystem (caret, mlr3, etc.) instead

---

### Similarity/Distance Metrics
- **Distance** (28)
- **Similarity** (5)
- **Dissimilarity** (mentioned in docs)
- **Configuration** (24) - multidimensional scaling results

**Recommendation**: Use R packages like `proxy`, `cluster` instead

---

### Phonetic/Linguistic Tools
- **WordList** (26) - word list management
- **Categories** (17) - categorical data
- **Corpus** (9) - corpus management
- **SpellingChecker** (3)

**Recommendation**: LOW PRIORITY - better handled by R string/text packages

---

### Articulatory/Acoustic Synthesis
- **VocalTract** (5)
- **VocalTractTier** (1)
- **SpeechSynthesizer** (3)
- **Artword** (0 in this sample)

**Recommendation**: LOW PRIORITY - specialized synthesis, rarely used

---

### Visual/Photography
- **Photo** (15)
- **Polygon** - drawing primitives

**Recommendation**: Not relevant for acoustic analysis

---

### Advanced Formant Tools
- **FormantPath** (5) - new multi-formant tracking algorithm
- **Cochleagram** (9) - cochlear filtering simulation

**Recommendation**: MEDIUM-LOW - niche but potentially useful for advanced users

---

## Summary: What Speaker Needs

### ✅ Already Well-Implemented (No Action Needed)
Core acoustic objects are solid:
- Sound, TextGrid, Pitch, Formant, Intensity
- Spectrum, Spectrogram, Harmonicity
- PointProcess, Manipulation
- PitchTier, IntensityTier, DurationTier
- LPC

### 🔴 Critical Gaps (High Priority)
1. **Batch processing utilities** - replace need for `Strings` class
2. **Data export helpers** - replace need for full `Table` class
3. **File pairing utilities** - coordinate Sound/TextGrid files

### 🟡 Enhancement Needs (Medium Priority)
4. **Extend Ltas class** - add query methods
5. **Extend Matrix class** - or document R matrix usage
6. **Add PowerCepstrum/PowerCepstrogram** - for voice quality (CPP)
7. **Verify/extend MFCC** - coefficient extraction
8. **Verify/extend FormantGrid** - point manipulation

### 🟢 Low Priority / Not Recommended
9. Neural network classes - use R ML packages
10. Similarity/distance classes - use `proxy`, `cluster`
11. Linguistic tool classes - use R text packages
12. Synthesis classes - niche use case

---

## Key Insight: Infrastructure vs. Objects

The existing gap analysis document is correct: **the main gap is not missing object classes, but missing workflow infrastructure**.

- ✅ Speaker has ~85% of commonly-used Praat object types
- ❌ Speaker lacks batch processing, data pipelines, and automation utilities
- ❌ The high usage of `Table` and `Strings` reflects workflow needs, not acoustic analysis needs

### Recommendation:
**DO NOT** implement Praat's `Table` and `Strings` as R6 classes. Instead:

1. **Add batch processing functions**:
   ```r
   batch_process(directory, pattern, func)
   pair_sound_textgrid(sound_dir, tg_dir)
   ```

2. **Add data extraction helpers**:
   ```r
   extract_measurements(sound, textgrid, tier, measures)
   aggregate_by_label(measurements_df, textgrid, tier)
   ```

3. **Document R equivalents**:
   - `Strings` → `list.files()`
   - `Table` → `data.frame` / `tibble`
   - Neural networks → `caret`, `mlr3`
   - Distance metrics → `proxy`, `cluster`

4. **Extend existing classes**:
   - Add query methods to `Ltas`
   - Add CPP measurement via new `PowerCepstrum` class
   - Document `Matrix` conversion to R matrix

---

## Implementation Priority Ranking

### Phase 1: Infrastructure (2-3 weeks)
- Batch processing utilities
- File pairing and coordination
- Data extraction pipelines
- Export format helpers

### Phase 2: Class Extensions (1-2 weeks)
- Ltas query methods
- PowerCepstrum/PowerCepstrogram for CPP
- Matrix export and manipulation docs
- MFCC coefficient extraction

### Phase 3: Documentation (1 week)
- Document R equivalents for Praat classes
- Migration guide from Praat scripts
- Best practices for batch processing

### Phase 4: Advanced Features (3-4 weeks, optional)
- FormantPath (new formant tracking)
- Cochleagram
- Advanced prosody tools (pitch stylization, turning points)

---

## Conclusion

**Speaker package is NOT missing critical Praat object classes.**

The analysis shows:
- ✅ 85% of frequently-used acoustic object types are already implemented
- ❌ Workflow infrastructure (batch processing, data pipelines) is the main gap
- ⚠️ Some classes need method extensions (Ltas, Matrix, MFCC)
- 🎯 High `Table` and `Strings` usage reflects workflow needs, not object needs

**The path forward is adding R-idiomatic workflow utilities, not reimplementing Praat's procedural classes.**

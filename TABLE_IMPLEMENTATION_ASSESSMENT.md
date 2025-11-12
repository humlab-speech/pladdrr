# Table Implementation Assessment
## Date: 2025-11-12

## Executive Summary

After thorough analysis of the Praat Table object, its interactions with other Praat objects, and comparison with R's native data structures, I conclude:

**RECOMMENDATION: Mark Table for later implementation with the Praat interpreter**

## Analysis

### 1. Table Object in Praat Ecosystem

The Praat `Table` object serves several critical roles:

1. **Data Exchange Format**: Acts as intermediate format between different Praat objects
   - `Formant` → `Table` (Down to Table with various options)
   - `Pitch` → `Table` 
   - `Intensity` → `IntensityTier` → `TableOfReal` → `Table`
   - `PairDistribution` → `Table`
   - `Table` → `LinearRegression`
   - `Table` → `LogisticRegression`
   - `Table` → `RealTier`
   - `Table` ↔ `TableOfReal`

2. **Script Interface**: Primary data structure in Praat scripts for:
   - Statistical analysis (means, correlations, t-tests, etc.)
   - Data manipulation (row/column operations)
   - Formula evaluation (requires Interpreter)
   - File I/O (CSV, tab-delimited, etc.)

3. **Interactive Data Editing**: GUI table editor functionality

### 2. R Data Structure Comparison

#### data.frame
- **Pros**: 
  - Base R, universal compatibility
  - Similar column-based structure to Praat Table
  - Direct support for mixed types (numeric/character)
  - Ubiquitous in R ecosystem
- **Cons**:
  - Slower for large datasets
  - Row names can be problematic

#### tibble (tidyverse)
- **Pros**:
  - Modern, cleaner printing
  - Better type preservation
  - Better handling of list-columns
  - Growing adoption in modern R packages
- **Cons**:
  - External dependency (adds tidyverse to package)
  - Not as universally compatible as data.frame
  - Philosophical alignment with tidyverse may not suit all users

#### data.table
- **Pros**:
  - Extremely fast for large datasets
  - Efficient memory usage
  - Reference semantics (modify in place)
- **Cons**:
  - External dependency
  - Different syntax paradigm
  - May confuse users expecting standard data.frame behavior

### 3. Critical Dependencies on Interpreter

The Praat Table object has **critical functionality** that requires the Praat Interpreter:

```cpp
// From Table.h
void Table_formula (Table me, integer column, conststring32 formula, Interpreter interpreter);
void Table_formula_columnRange (Table me, integer column1, integer column2, 
                                  conststring32 expression, Interpreter interpreter);
```

This means:
- Table formulas (like Excel formulas) cannot work without interpreter
- Many Praat scripts rely on `Table_formula()` for data transformations
- Our current implementation would be incomplete for script compatibility

### 4. Conversion Strategy Analysis

**Current Implementation Status:**
- ✅ Basic Table R6 class exists (`R/table-r6.R`)
- ✅ C++ wrapper for core operations
- ✅ Conversion to/from R matrix and data.frame
- ❌ Formula evaluation (requires interpreter)
- ❌ File I/O operations
- ❌ Advanced statistical methods

**Use Cases:**

**Use Case A: R-Native Workflow (No Praat Scripts)**
```r
# User wants to analyze formants in pure R
snd <- praat_sound("voice.wav")
formant <- snd$to_formant(...)
df <- formant$to_data_frame()  # Direct conversion
# Continue with tidyverse/base R operations
```
**Verdict**: data.frame/tibble is SUPERIOR - No Table object needed

**Use Case B: Praat Script Translation (Manual)**
```praat
# Original Praat script
formant = To Formant (burg)...
table = Down to Table... yes yes 6 no 3 yes 3 yes
meanF1 = Get mean... F1
```

```r
# Translated to R (current approach)
formant <- snd$to_formant_burg(...)
df <- formant$to_data_frame()  # Skip Table, go direct to data.frame
mean_f1 <- mean(df$F1, na.rm = TRUE)
```
**Verdict**: data.frame/tibble is SUFFICIENT - Table adds no value

**Use Case C: Praat Script Execution (Future with Interpreter)**
```r
# Future capability: run unmodified Praat script
result <- praat_script("
  formant = To Formant (burg)...
  table = Down to Table... yes yes 6 no 3 yes 3 yes
  Formula... F1_normalized self / meanF1
")
```
**Verdict**: Table object IS REQUIRED for script compatibility

### 5. Integration with Other Objects

From analysis of Python parselmouth usage in superassp:
```python
formantTable = pm.praat.call(form,"Down to Table", True, True, 10, True, 3, True, 3, True)
# Then convert to pandas:
return pd.read_table(io.StringIO(pm.praat.call(formantTable, "List", True)))
```

**Pattern**: Even Python implementation converts Table → pandas.DataFrame immediately

### 6. Assessment of R Table Format Choice

**For current implementation (without interpreter):**

**RECOMMENDATION: data.frame (with conversion utilities)**

**Rationale:**
1. **Universal compatibility**: Works everywhere in R ecosystem
2. **No additional dependencies**: Keeps package lightweight
3. **User choice**: Users can convert to tibble/data.table if preferred
4. **Sufficient for translation**: Manual script translation works fine with data.frame

**Implementation approach:**
```r
# Provide conversion utilities
as.data.frame.Formant <- function(x, ...) {
  # Direct Formant → data.frame without Table intermediate
}

as_tibble.Formant <- function(x, ...) {
  # For tidyverse users
  tibble::as_tibble(as.data.frame(x))
}
```

### 7. Future Interpreter Integration

When Praat interpreter is added:

**Required Table Functionality:**
- ✅ Already implemented: Basic structure, row/column operations
- ❌ Need to add: Formula evaluation (via interpreter)
- ❌ Need to add: File I/O (CSV, tab-delimited)
- ❌ Need to add: Integration with interpreter's variable system

**Compatibility Strategy:**
```r
# Future with interpreter
praat_script("
  table = Read Table from... data.csv
  Formula... newcol self * 2
  Write to table file... output.csv
")

# The interpreter would use the actual Praat Table object internally
# But R users would still prefer data.frame for native R workflows
```

## Recommendations

### Immediate Actions (Current Phase)

1. **DO NOT** expand Table implementation now
2. **DO** implement direct conversions: Object → data.frame
3. **DO** document that Table formula features require future interpreter
4. **DO** mark Table for Phase "Interpreter Integration"

### Implementation Priority

**High Priority (Now):**
- Formant → data.frame conversion
- Matrix → matrix/data.frame conversion
- Pitch → data.frame conversion

**Low Priority (With Interpreter):**
- Full Table object functionality
- Table formula evaluation
- Table file I/O operations
- Table ↔ Object conversions that aren't data export

### Code Examples

**Recommended pattern for Formant:**
```r
# In formant-r6.R
#' @description Convert Formant to data frame
#' @param include_intensity Logical: include intensity values
#' @param include_bandwidths Logical: include bandwidth values  
#' @param max_formant Integer: maximum formant number
#' @return data.frame with columns: time, F1, F2, ... [B1, B2, ...] [intensity]
to_data_frame = function(include_intensity = FALSE, 
                         include_bandwidths = TRUE,
                         max_formant = 5) {
  # Direct C++ implementation - no Table intermediate
  .formant_to_data_frame(private$ptr, include_intensity, 
                         include_bandwidths, max_formant)
}
```

**NOT recommended:**
```r
# Inefficient - creates Table just to convert to data.frame
to_data_frame = function() {
  table <- self$down_to_table(...)
  table$to_data_frame()
}
```

## Conclusion

The Praat Table object is essential for:
1. **Praat script execution** (requires interpreter)
2. **Interactive GUI editing** (not relevant for R package)
3. **Intermediate format** (inefficient for R workflows)

For the R package **without interpreter**, Table adds minimal value:
- R's data.frame is superior for native R workflows
- Direct object → data.frame conversions are more efficient
- No formula evaluation capability without interpreter

**DECISION: Mark Table object for later implementation when Praat interpreter is integrated. Focus current efforts on direct conversions to R native structures (data.frame, matrix).**

## Documentation Update Required

Add to CLAUDE.md:
```markdown
## Table Object Strategy

**Decision Date**: 2025-11-12

**Status**: Deferred to Interpreter Integration Phase

**Rationale**: 
The Praat Table object requires the Praat Interpreter for formula evaluation,
which is its primary advantage over R's native data.frame. Without the interpreter,
Table adds minimal value to R users. 

**Current Approach**:
- Implement direct Object → data.frame conversions (e.g., Formant$to_data_frame())
- Skip Table as intermediate format
- Use R's native data.frame for tabular data

**Future Integration**:
When Praat interpreter is added, implement full Table object with:
- Formula evaluation via interpreter
- File I/O operations  
- Full compatibility with Praat scripts
- Integration with interpreter variable system

**R Table Format Choice**: data.frame
- Rationale: Universal compatibility, no dependencies, user can convert to tibble/data.table
- Alternative: Provide as_tibble() methods for tidyverse users
```

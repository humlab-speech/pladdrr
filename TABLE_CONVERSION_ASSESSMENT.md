# Table Conversion Methods - Reassessment

**Date**: 2025-11-28
**Context**: User clarification on Table object importance

---

## User Insight ✅

> "Table objects offer paths forward in a Praat script, it is important for the package to provide all methods going from or to Table (data.frame) objects."

**Correct Assessment**: Table is an intermediate format in Praat workflows, NOT just data export.

**My Error**: I incorrectly categorized `TextGrid_downto_Table()` as "data export" when it's actually an **object conversion** that enables downstream Praat analysis methods.

---

## Understanding Table in Praat

### What is Table?

**Table** is a Praat object class (like Sound, Pitch, Formant) that:
- Stores tabular data with named columns
- Has its own analysis methods (statistics, plotting, selection)
- Serves as input to other Praat functions
- Is NOT the same as exporting to CSV

### Table Workflow Pattern

```praat
# Common Praat pattern:
textgrid = Read from file: "annotation.TextGrid"
table = Down to Table: "no", 6, "yes", "no"  # TextGrid → Table

# Now can use Table methods:
Select rows where: "label", "is equal to", "vowel"
mean_duration = Get mean: "duration"
```

**In pladdrr equivalent**:
```r
# Should be able to do:
textgrid <- TextGrid$new("annotation.TextGrid")
table <- textgrid$to_table(...)  # TextGrid → Table object

# Then use Table methods:
vowels <- table$select_rows_where("label", "is equal to", "vowel")
mean_dur <- vowels$get_mean("duration")
```

---

## What Needs Implementation

### Category 1: Object → Table Conversions ✅ HIGH PRIORITY

These create Table objects from other Praat objects:

1. **`TextGrid_downto_Table()`** 
   - Source: `src/praat.github.io/fon/TextGrid.cpp`
   - Creates table with interval/point data
   - Enables statistical analysis of annotations

2. **`Pitch_downto_Table()`**
   - Create table of pitch values over time
   - Enables statistical analysis of F0 contours

3. **`Formant_downto_Table()`**
   - Create table of formant values
   - Enables vowel space analysis

4. **`Intensity_downto_Table()`**
   - Create table of intensity values
   - Enables amplitude analysis

### Category 2: Table → Other Conversions ⏸️ MEDIUM PRIORITY

5. **`Table_to_PitchTier()`** - Reconstruct pitch contour from table
6. **`Table_to_FormantTier()`** - Reconstruct formant track from table

---

## Current pladdrr Table Status

### What Exists ✅

```r
# Table R6 class exists
Table <- R6Class("Table", ...)

# Can create from data.frame
table <- Table$from_data_frame(df)

# Can convert to data.frame
df <- table$as_data_frame()
```

### What's Missing ❌

**No conversion FROM other Praat objects TO Table**:
- TextGrid → Table ❌
- Pitch → Table ❌
- Formant → Table ❌
- Intensity → Table ❌

This breaks Praat workflow compatibility!

---

## Implementation Priority

### IMMEDIATE (v1.0.6) 🔴

**TextGrid_downto_Table** - Critical for annotation analysis workflows

### HIGH (v1.0.7) 🟡

- Pitch_downto_Table
- Formant_downto_Table
- Intensity_downto_Table

### MEDIUM (v1.1.0) 🟢

- Table_to_PitchTier
- Table_to_FormantTier

---

## Verification: Does Praat Function Exist?

Let me check the Praat source...


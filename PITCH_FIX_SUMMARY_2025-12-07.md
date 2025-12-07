# Pitch Detection Fix - NUMfpp Linkage Issue (2025-12-07)

## Problem
Pitch extraction crashed with segfault at address 0x20 in `NUMminimize_brent()`:
```
const double sqrt_epsilon = sqrt (NUMfpp -> eps);  // NUMfpp was NULL
```

## Root Cause
`NUMfpp` declared as `inline machar_Table NUMfpp = nullptr;` in NUMmachar.h gave each compilation unit its own copy. When `pitch_wrappers.cpp` called `initialize_numfpp()` (from `num_stubs.cpp`), it initialized one copy. When `NUM2.cpp::NUMminimize_brent()` accessed `NUMfpp`, it saw a different copy (still NULL).

## Solution

### 1. Fixed NUMfpp Linkage
**File: `src/praat.github.io/dwsys/NUMmachar.h`**
- Changed `inline machar_Table NUMfpp = nullptr;` → `extern machar_Table NUMfpp;`
- Single declaration, definition in NUMmachar.cpp

**File: `src/praat.github.io/dwsys/NUMmachar.cpp`**
- Added: `machar_Table NUMfpp = nullptr;` (global definition)

### 2. Use Real NUMmachar() Function
**File: `src/pitch_wrappers.cpp`**
- Changed `initialize_numfpp()` → `NUMmachar()`
- Calls actual Praat initialization from NUMmachar.cpp

### 3. Build System
**File: `src/Makevars.in`** (already fixed in previous commit)
- Added `praat.github.io/dwsys/NUMmachar.cpp` to DWSYS_SRC

## Files Modified
- `src/pitch_wrappers.cpp` - Use NUMmachar() instead of stub
- `src/praat.github.io/dwsys/NUMmachar.h` - extern declaration
- `src/praat.github.io/dwsys/NUMmachar.cpp` - global definition
- `DESCRIPTION` - Version 1.1.4 → 1.1.5

## Result
NUMfpp now has single global instance, correctly initialized by NUMmachar(), accessible to all compilation units including NUM2.cpp.

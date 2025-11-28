# R6 Method Access Issue - Debugging Plan

**Date**: 2025-11-28
**Issue**: "attempt to apply non-function" when calling R6 methods
**Affects**: TextGrid methods (v1.0.5), Sound methods (v1.0.6)
**Impact**: Blocks ~95% coverage goal

---

## Symptoms

```r
library(pladdrr)
tg <- TextGrid$create(0, 5, "words")

# This fails:
tg$change_labels(1, "old", "new")
# Error: attempt to apply non-function

# But this shows it IS a function:
str(tg$change_labels)
# function (tier, search, replace, use_regexp = FALSE, from = 1, to = 0)
```

**Paradox**: The method exists, is a function, but throws "attempt to apply non-function" when called.

---

## Debugging Strategy

### Step 1: Check if issue is R6-specific or broader
- Test with working methods
- Compare method definitions
- Check inheritance chain

### Step 2: Inspect R6 class structure
- Check public/private sections
- Verify method binding
- Test active bindings

### Step 3: Test package loading
- Fresh R session
- Different loading methods
- Check for namespace issues

### Step 4: Minimal reproducible example
- Create simple R6 class with same pattern
- Test if issue reproduces
- Isolate root cause

---

## Investigation Points

1. **Inheritance**: TextGrid inherits from PraatObject
2. **Private members**: Uses `private$ptr` not `private$.xptr`
3. **Method location**: Methods in public section, before closing `}`
4. **Package loading**: Might be related to when/how R6 classes are instantiated

---

Let's start debugging...


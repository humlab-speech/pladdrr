# R7/S7 Prototypes for speaker v2.0.0

**Status**: Proof-of-concept only - Not included in v1.0.0  
**Purpose**: Research and development for future R7 migration  
**Target Release**: v2.0.0 (6+ months after v1.0.0)

## Contents

- `r7-praat-object.R` - Base PraatObject class in R7/S7
- `r7-harmonicity.R` - Complete Harmonicity implementation (20 methods)
- `R7_MIGRATION_SESSION_2025-11-12.md` - Migration strategy
- `R7_IMPLEMENTATION_PROGRESS_2025-11-12.md` - Implementation progress

## Current Status

✅ **Complete**:
- Base PraatObject_S7 class with external pointer management
- Full Harmonicity_S7 implementation with all methods
- Automatic S3 integration (print, summary, plot)

⏸ **Pending** (for v2.0.0):
- Remaining 18 objects (Sound, Pitch, Formant, etc.)
- Comprehensive testing
- Performance benchmarking
- Documentation updates

## Why R7?

**Advantages over R6**:
1. Automatic S3 generic integration
2. Cleaner code organization
3. Multiple dispatch support
4. Modern R ecosystem alignment
5. Better properties with validation

## Why Not in v1.0.0?

**Decision**: Use proven R6 for v1.0.0, migrate to R7 for v2.0.0

**Rationale**:
- R6 implementation complete and stable
- R7 ecosystem still maturing
- Faster path to stable release
- Learn from other packages' migrations
- Natural major version bump for breaking changes

## Architecture

Both R6 and R7 implementations use the same underlying pattern:

```
R Interface (R6 or R7)
    ↓
External Pointers (XPtr)
    ↓
C++ Wrappers (Rcpp)
    ↓
Praat C++ Objects
```

The migration only affects the R layer - C++ code remains unchanged.

## Usage Example (R7 Prototype)

```r
library(S7)
source("dev/r7-prototypes/r7-praat-object.R")
source("dev/r7-prototypes/r7-harmonicity.R")

# This would work in v2.0.0:
sound <- Sound_S7("audio.wav")
hnr <- to_harmonicity(sound, time_step = 0.01)

# Automatic S3 methods:
print(hnr)    # Pretty output
summary(hnr)  # Statistics
plot(hnr)     # Visualization

# Method calls:
mean_hnr <- get_mean(hnr)
```

## Timeline

- **Now**: Prototypes archived in dev/
- **v1.0.0** (4 weeks): R6 production release
- **Months 1-3**: Monitor R7 ecosystem
- **Months 4-5**: Full R7 migration
- **Month 6**: v2.0.0 release

## Notes for Future Development

1. Use Harmonicity_S7 as template for other objects
2. Keep C++ wrappers identical to R6 version
3. Ensure external pointer management is identical
4. Add comprehensive S3 methods for all objects
5. Performance benchmark against R6 before release

---

**Do not include these files in package builds.**  
**For research and future development only.**

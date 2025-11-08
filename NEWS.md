# speaker 0.2.1

## Major Changes

* **OOP AMENDMENT**: Complete redesign to fully embrace Praat's object-oriented architecture
* Established definitive roadmap for implementing 30+ Praat object types as R6 classes
* Shifted focus from isolated procedures to complete object hierarchy with 400+ methods

## Documentation

* Added `OOP_AMENDMENT_FINAL.md` - Master implementation plan
* Detailed 10-week roadmap for complete Praat functionality
* Method naming conventions aligned with Praat commands
* Migration paths from Praat scripts and Parselmouth

## Current Implementation (v0.1.0 baseline)

* Sound object: ~45/50 methods (90%)
* Pitch object: ~28/30 methods (93%)
* Formant object: ~20/25 methods (80%)
* Intensity object: ~15/18 methods (83%)
* Harmonicity object: ~15/15 methods (100%)
* TextGrid object: ~20/35 methods (57%, read-only)
* PointProcess object: ~5/25 methods (20%, partial)

**Total**: ~150/400 methods (37% of planned functionality)

## Planned Implementation

### Phase 1 (Weeks 1-3) - CRITICAL
* Complete PointProcess (jitter/shimmer)
* Implement PitchTier, DurationTier, IntensityTier
* Implement Manipulation object (PSOLA pitch/duration modification)

### Phase 2 (Weeks 4-6) - Spectral Analysis
* Spectrum, Spectrogram, LPC
* Ltas, Cochleagram, Excitation  
* MFCC, FormantPath

### Phase 3 (Weeks 7-8) - Advanced
* FormantGrid (formant synthesis)
* Matrix, Table (data structures)

### Phase 4 (Week 9) - TextGrid Completion
* Full annotation modification capabilities
* Tier management, boundary insertion, text editing

### Phase 5 (Week 10) - Utilities
* Collection, VoiceReport, AmplitudeTier

## Breaking Changes

None - this is a planning/documentation release. Implementation follows in subsequent versions.

## Next Release (0.2.2)

* Complete PointProcess implementation
* Add comprehensive voice quality analysis
* Update vignettes with jitter/shimmer examples

# speaker 0.2.0

## Major Changes

* Implemented R6 class-based object-oriented interface
* Added external pointer-based memory management  
* Established foundation for complete Praat object hierarchy

## New Objects

* Sound (R6 class with ~45 methods)
* Pitch (R6 class with ~28 methods)
* Formant (R6 class with ~20 methods)
* Intensity (R6 class with ~15 methods)
* Harmonicity (R6 class with ~15 methods)
* TextGrid (R6 class with ~20 methods, read-only)
* PointProcess (R6 class, partial implementation)

## Infrastructure

* C++17 support
* Praat source code integration as submodule
* Comprehensive test suite
* Vignette system

# speaker 0.1.0

* Initial release with procedural interface

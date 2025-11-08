# speaker 0.2.0.9000 (Development)

## Major Changes

* **COMPREHENSIVE OOP AMENDMENT**: Expanded plan to implement complete Praat object hierarchy
  - Plan to add 18 additional Praat objects (PointProcess, Manipulation, Spectrum, Spectrogram, etc.)
  - Target: 24 total objects with ~400 methods
  - Focus on object-oriented design mirroring Praat's C++ architecture
  
* **Implementation Roadmap**: 12-week phased approach
  - Phase 1 (Weeks 1-3): Critical objects (PointProcess, Manipulation, Tier objects)
  - Phase 2 (Weeks 4-5): Spectral analysis objects
  - Phase 3 (Weeks 6-7): Advanced objects (FormantPath, Table, Matrix)
  - Phase 4 (Week 8): Complete TextGrid implementation
  - Phase 5 (Weeks 9-10): Migrate 11 superassp Python examples to R
  - Phase 6 (Week 11): Comprehensive documentation and vignettes
  - Phase 7 (Week 12): Testing, validation, and CRAN preparation

* **Documentation**: Created comprehensive amendment and roadmap documents
  - `specs/001-praat-r-access/COMPREHENSIVE-OOP-AMENDMENT.md` - Detailed implementation plan
  - `COMPREHENSIVE_OOP_ROADMAP.md` - Project tracking and timeline

## Current Status

* 6 objects implemented: Sound, Pitch, Formant, Intensity, Harmonicity, TextGrid (partial)
* ~195 of ~408 planned methods (48% complete)
* Foundation established for complete Praat OOP interface

# speaker 0.1.0 (Development)

## Initial Development

This is the initial development version of the speaker package.

### Planned Features

* **Sound Object Operations**: Load audio files, create sound objects, query properties, compute statistics
* **Pitch Analysis**: Extract F0 contours, query pitch measurements (min, max, mean)
* **Formant Analysis**: Extract formants (F1-F5), query formant values and statistics
* **Intensity Analysis**: Compute intensity contours, measure loudness
* **Spectral Analysis**: Create spectrograms, query spectral power

### Development Status

- [x] Project structure initialized
- [x] Package metadata configured (DESCRIPTION, LICENSE, NEWS)
- [ ] Praat C source integration
- [ ] Rcpp wrapper implementation
- [ ] R function implementation
- [ ] Test suite with TDD
- [ ] Documentation and vignettes
- [ ] CRAN submission preparation

### Notes

This package provides direct access to Praat C functionality via Rcpp, enabling
phonetic analysis directly in R without external Praat software.

For detailed progress, see `specs/001-praat-r-access/tasks.md`.

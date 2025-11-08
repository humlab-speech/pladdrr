# Implementation Plan: Praat C Functionality Access from R

**Branch**: `001-praat-r-access` | **Date**: 2025-11-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-praat-r-access/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Provide direct access to Praat C phonetic analysis functionality from R using Rcpp integration. The package enables researchers to perform sound object operations, pitch analysis, formant extraction, intensity measurements, and spectral analysis directly in R without external Praat software. Technical approach focuses on wrapping Praat's C algorithms with Rcpp for type-safe, memory-managed integration while ensuring computational accuracy matches Praat desktop application output within 0.1% relative error.

## Technical Context

**Language/Version**: R 4.0+ with C++11 (minimum for Rcpp compatibility)
**Primary Dependencies**: Rcpp (>= 1.0.0), testthat (>= 3.0.0), roxygen2 (>= 7.0.0), Praat C source code (NEEDS CLARIFICATION: specific version/commit)
**Storage**: N/A (in-memory audio processing, no persistent storage)
**Testing**: testthat for R code, C++ unit tests via Rcpp, integration tests with reference Praat output files
**Target Platform**: Windows, macOS, Linux (cross-platform R package)
**Project Type**: single (R package with Rcpp extension)
**Performance Goals**: Load and extract properties from 5-minute audio in <10 seconds, process 10x faster than external Praat scripts
**Constraints**: Memory <500MB for 10-minute audio at 44.1kHz, numerical precision within 0.1% of Praat output for 95% of test cases
**Scale/Scope**: 20-30 exported R functions, 5 S3 object classes, 4 core analysis modules (sound, pitch, formant, intensity/spectral)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Scientific Accuracy & Reproducibility

- ✅ **Pass**: All algorithms wrap Praat C implementations directly
- ✅ **Pass**: Numerical precision requirements specified (0.1% relative error)
- ✅ **Pass**: Platform-independent deterministic computation (within floating-point limitations)
- ✅ **Pass**: No random number generation in phonetic analysis algorithms
- ✅ **Pass**: Breaking changes documented via NEWS.md and semantic versioning

### Principle II: R Package Standards Compliance

- ✅ **Pass**: DESCRIPTION file with proper dependencies and versioning
- ✅ **Pass**: roxygen2 documentation for all exported functions (FR-014)
- ✅ **Pass**: NAMESPACE auto-generated via roxygen2
- ✅ **Pass**: S3 classes for Praat objects with print methods (FR-013)
- ✅ **Pass**: No global state modification, R-standard error handling
- ✅ **Pass**: CRAN submission standards followed (SC-004)

### Principle III: C++ Integration via Rcpp

- ✅ **Pass**: All Praat C functionality accessed via Rcpp wrappers in `src/`
- ✅ **Pass**: Rcpp objects provide automatic memory management for R<->C++ interface
- ⚠️  **Needs Research**: Praat C code memory management strategy - requires RAII wrappers or smart pointers for Praat objects
- ✅ **Pass**: C++ exceptions caught and converted to R errors (FR-011)
- ✅ **Pass**: Rcpp attributes for function export registration
- ✅ **Pass**: Compiler warnings treated as errors in development
- ✅ **Pass**: Platform-portable C++11 code, no platform-specific dependencies

### Principle IV: Test-Driven Development

- ✅ **Pass**: TDD workflow mandated in constitution
- ✅ **Pass**: testthat tests for all exported R functions
- ✅ **Pass**: Coverage targets: >80% R code, >70% C++ code (SC-007)
- ✅ **Pass**: Integration tests verify against known-good Praat output (FR-012, SC-002)
- ✅ **Pass**: Test normal cases, edge cases, error conditions
- ⚠️  **Needs Research**: CI/CD platform selection for multi-platform testing (GitHub Actions recommended)

### Principle V: Documentation & Examples

- ✅ **Pass**: roxygen2 documentation with parameters, return values, examples (FR-014, SC-006)
- ✅ **Pass**: At least one working example per exported function
- ⚠️  **Needs Research**: Vignettes needed - basic workflow vignette, pitch analysis vignette, formant analysis vignette
- ✅ **Pass**: README.md with quick start (exists)
- ✅ **Pass**: NEWS.md for user-visible changes
- ✅ **Pass**: Code comments for complex algorithms

**Gate Status**: ✅ PASS with minor research items (Praat version, CI/CD, vignettes)

## Project Structure

### Documentation (this feature)

```text
specs/001-praat-r-access/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification (completed)
├── research.md          # Phase 0 output (to be generated)
├── data-model.md        # Phase 1 output (to be generated)
├── quickstart.md        # Phase 1 output (to be generated)
├── contracts/           # Phase 1 output (R function signatures)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# R Package Structure (standard R package layout)
R/
├── speaker-package.R    # Package documentation and imports
├── sound.R              # Sound object creation, I/O, properties
├── sound-generate.R     # Test signal generation
├── sound-stats.R        # Basic audio statistics
├── pitch.R              # Pitch extraction and queries
├── formant.R            # Formant extraction and queries
├── intensity.R          # Intensity computation
├── spectrogram.R        # Spectrogram creation
├── s3-methods.R         # Print, summary, plot methods for S3 classes
└── utils.R              # Internal utilities, parameter validation

src/
├── Makevars             # Build configuration
├── Makevars.win         # Windows build configuration
├── praat_wrapper.cpp    # Main Rcpp interface
├── sound_wrapper.cpp    # Sound object C++ wrappers
├── pitch_wrapper.cpp    # Pitch analysis C++ wrappers
├── formant_wrapper.cpp  # Formant analysis C++ wrappers
├── intensity_wrapper.cpp # Intensity C++ wrappers
├── spectrogram_wrapper.cpp # Spectrogram C++ wrappers
├── utils.cpp            # C++ utilities, error handling
├── RcppExports.cpp      # Auto-generated by Rcpp
└── praat/               # Praat C source code (to be determined in research)
    ├── sys/             # Praat system utilities
    ├── dwsys/           # Signal processing utilities
    ├── fon/             # Phonetic object implementations
    └── ...              # Other Praat modules as needed

tests/
├── testthat.R           # Test runner
└── testthat/
    ├── test-sound.R     # Sound object tests
    ├── test-pitch.R     # Pitch analysis tests
    ├── test-formant.R   # Formant analysis tests
    ├── test-intensity.R # Intensity tests
    ├── test-spectrogram.R # Spectrogram tests
    ├── test-integration.R # Integration tests vs Praat output
    └── fixtures/        # Test audio files, reference output

inst/
├── extdata/             # Example audio files for documentation
└── testdata/            # Reference Praat output for validation

man/                     # Auto-generated roxygen2 documentation

vignettes/               # Package vignettes (to be created)
├── basic-usage.Rmd
├── pitch-analysis.Rmd
└── formant-analysis.Rmd
```

**Structure Decision**: Standard R package structure with Rcpp integration. The `R/` directory contains user-facing R functions organized by analysis type. The `src/` directory contains C++ wrapper code that interfaces with embedded Praat C source. The `tests/` directory follows testthat conventions with test fixtures. This structure aligns with CRAN R package standards and Rcpp best practices.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations. All principles satisfied.


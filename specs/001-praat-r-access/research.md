# Research Findings: Praat C Integration for R

**Date**: 2025-11-02
**Context**: Technical research for integrating Praat C source code into R package via Rcpp

## Praat Version Selection

### Decision

Use **Praat 6.3.x or 6.4.x** (latest stable release from praat.org)

### Rationale

- Praat has maintained API stability for core phonetic objects (Sound, Pitch, Formant) across recent versions
- Version 6.3+ uses modern C++ features compatible with C++11
- GPL-2+ licensing confirmed and compatible with R package GPL-3
- The parselmouth project (Python bindings) successfully uses Praat 6.2+ as reference
- Praat source is available on GitHub: https://github.com/praat/praat

### Integration Approach

1. **Git submodule approach** (recommended):
   - Add Praat repository as git submodule in `src/praat/`
   - Pin to specific stable commit/tag for reproducibility
   - Update via submodule when needed

2. **Alternative - Vendored source**:
   - Copy required Praat source files into `src/praat/`
   - Document source version in README and DESCRIPTION
   - Easier for CRAN submission (no external dependencies)

3. **Build integration**:
   - Modify `src/Makevars` to compile Praat source files
   - Use `PKG_CPPFLAGS` to include Praat headers
   - Compile only required Praat modules (not entire Praat application)

**Recommendation**: Start with vendored source approach for initial implementation. Praat source files needed are ~50-100 files, manageable size. This approach is more CRAN-friendly.

## Memory Management Strategy

### Praat's Memory Model

Praat uses **manual memory management** with C-style allocation:
- Objects created via `Thing_new` or specific constructors (e.g., `Sound_create`)
- Objects inherit from base `Thing` class with reference counting
- Explicit cleanup via `forget()` macro or `Thing_free()`
- No automatic RAII in Praat C code itself

### Praat Object Lifecycle

```cpp
// Typical Praat pattern
autoSound sound = Sound_create(...);  // Creates object
// ... use sound
// autoXXX is Praat's smart pointer - automatically calls forget() at scope exit
```

Praat has its own smart pointer system (`autoSound`, `autoPitch`, etc.) that provides scope-based cleanup.

### Recommended RAII Wrapper Approach for Rcpp

**Strategy**: Use Rcpp external pointers with custom deleters

```cpp
// Example wrapper pattern
template<typename PraatType>
class PraatObjectWrapper {
private:
    PraatType* ptr_;

public:
    PraatObjectWrapper(PraatType* p) : ptr_(p) {}

    ~PraatObjectWrapper() {
        if (ptr_) {
            forget(ptr_);  // Praat's cleanup function
        }
    }

    PraatType* get() { return ptr_; }

    // Disable copy, enable move
    PraatObjectWrapper(const PraatObjectWrapper&) = delete;
    PraatObjectWrapper& operator=(const PraatObjectWrapper&) = delete;
};

// Rcpp interface
// [[Rcpp::export]]
Rcpp::XPtr<PraatObjectWrapper<structSound>> create_sound_internal(
    Rcpp::NumericVector samples, double sampling_freq) {

    // Create Praat object
    autoSound sound = Sound_create(
        1,  // nChannels
        0.0,  // xmin
        samples.size() / sampling_freq,  // xmax
        samples.size(),  // nx
        1.0 / sampling_freq,  // dx
        0.0   // x1
    );

    // Copy data
    for (long i = 0; i < samples.size(); i++) {
        sound->z[1][i + 1] = samples[i];  // Praat uses 1-indexed arrays
    }

    // Wrap in RAII wrapper and return as XPtr
    auto wrapper = new PraatObjectWrapper<structSound>(sound.releaseToAmbiguousOwner());
    return Rcpp::XPtr<PraatObjectWrapper<structSound>>(wrapper, true);
}
```

**Key Points**:
- Rcpp `XPtr` provides R garbage collection integration
- Custom deleter ensures `forget()` called when R object destroyed
- Wrapper class provides C++ RAII semantics
- Each Praat object type (Sound, Pitch, Formant) gets a wrapper

### Alternative: Use Praat's auto Types

Leverage Praat's existing `autoSound`, `autoPitch`, etc.:
- These are already RAII-compliant
- Store these in wrapper classes passed to R
- Simpler integration with existing Praat code patterns

**Recommended**: Use Praat's auto types where possible, wrap in Rcpp XPtr for R integration.

## Required Source Modules

### Core Praat Source Files Needed

Based on typical phonetic analysis requirements:

#### Essential System/Utility Modules

```
sys/
├── melder.cpp/h         # Core Praat utilities, error handling
├── Thing.cpp/h          # Base object system
├── Collection.cpp/h     # Collection containers
├── Graphics.cpp/h       # Minimal graphics for object infrastructure
└── Gui.cpp/h            # GUI stubs (may need minimal stubs)

dwsys/
├── NUM.cpp/h            # Numerical algorithms
├── NUMlinpack.cpp/h     # Linear algebra (for LPC)
└── NUMrandom.cpp/h      # Random number generation
```

#### Phonetic Object Modules

```
fon/
├── Sound.cpp/h                 # Sound object (REQUIRED)
├── Sound_and_Pitch.cpp/h       # Pitch extraction from Sound
├── Sound_to_Pitch.cpp/h        # Pitch algorithms (autocorrelation, etc.)
├── Pitch.cpp/h                 # Pitch object (REQUIRED)
├── Sound_to_Formant.cpp/h      # Formant extraction (LPC)
├── Formant.cpp/h               # Formant object (REQUIRED)
├── Sound_to_Intensity.cpp/h    # Intensity computation
├── Intensity.cpp/h             # Intensity object (REQUIRED)
├── Sound_to_Spectrogram.cpp/h  # Spectrogram creation
├── Spectrogram.cpp/h           # Spectrogram object (REQUIRED)
├── Sampled.cpp/h               # Base class for time-sampled objects
├── Matrix.cpp/h                # Matrix base class
└── Function.cpp/h              # Function base class
```

#### Dependency Graph

```
Thing (base)
  └─> Function
       └─> Sampled
            ├─> Sound
            ├─> Pitch
            ├─> Formant
            ├─> Intensity
            └─> Matrix
                 └─> Spectrogram
```

### Build Configuration

**Makevars** structure:

```makefile
# Praat source directories
PRAAT_SRC = praat

PKG_CPPFLAGS = -I$(PRAAT_SRC) \
               -I$(PRAAT_SRC)/sys \
               -I$(PRAAT_SRC)/dwsys \
               -I$(PRAAT_SRC)/fon

# Praat source files to compile
PRAAT_SOURCES = \
    $(PRAAT_SRC)/sys/melder.cpp \
    $(PRAAT_SRC)/sys/Thing.cpp \
    $(PRAAT_SRC)/fon/Sound.cpp \
    $(PRAAT_SRC)/fon/Pitch.cpp \
    $(PRAAT_SRC)/fon/Formant.cpp \
    # ... other sources

# Main package sources
PKG_SOURCES = praat_wrapper.cpp sound_wrapper.cpp pitch_wrapper.cpp

OBJECTS = $(PRAAT_SOURCES:.cpp=.o) $(PKG_SOURCES:.cpp=.o)
```

### Minimal Praat Subset

For initial MVP (User Story 1 - Basic Sound Operations):
- System: `melder`, `Thing`, `Collection`
- Numerics: `NUM`
- Phonetics: `Sound`, `Sampled`, `Function`, `Matrix`

Total: ~20-30 source files for basic functionality

For full feature set (all 4 user stories):
- Add: `Pitch`, `Formant`, `Intensity`, `Spectrogram`
- Add: Analysis algorithms (`Sound_to_*`)
- Total: ~50-80 source files

**Recommendation**: Start with minimal subset for MVP, incrementally add modules per user story.

## CI/CD Platform Recommendation

### Decision

Use **GitHub Actions** with **r-lib/actions**

### Rationale

- Industry standard for R packages (used by tidyverse, r-lib, most major R packages)
- Excellent R-specific actions maintained by r-lib team
- Free for public repositories
- Native GitHub integration (no external service needed)
- Matrix testing across platforms and R versions built-in
- Comprehensive documentation: https://github.com/r-lib/actions

### Configuration Approach

**Workflow file**: `.github/workflows/R-CMD-check.yaml`

```yaml
name: R-CMD-check

on: [push, pull_request]

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.config.os }}

    strategy:
      matrix:
        config:
          - {os: windows-latest, r: 'release'}
          - {os: macOS-latest, r: 'release'}
          - {os: ubuntu-latest, r: 'release'}
          - {os: ubuntu-latest, r: 'devel'}

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}

      - uses: r-lib/actions/setup-r-dependencies@v2

      - uses: r-lib/actions/check-r-package@v2
```

**Platform Matrix**:
- Windows (latest) + R release
- macOS (latest) + R release
- Linux (Ubuntu latest) + R release
- Linux (Ubuntu latest) + R devel (for CRAN readiness)

**R Version Strategy**:
- `release`: Current CRAN release
- `devel`: R development version (pre-release)
- Optional: `oldrel` for backward compatibility

### Coverage Integration

**Tool**: covr package

**Workflow**: `.github/workflows/test-coverage.yaml`

```yaml
name: test-coverage

on: [push, pull_request]

jobs:
  test-coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: covr

      - name: Test coverage
        run: covr::codecov()
        shell: Rscript {0}
```

**Reporting**:
- Use codecov.io (free for open source)
- Add badge to README.md
- Targets: >80% R code, >70% C++ code (per constitution)

### Additional Workflows

**pkgdown documentation**: `.github/workflows/pkgdown.yaml`
- Automatically build and deploy package website
- Hosts vignettes, function reference, news

**pr-commands**: Support `/document`, `/style` commands in PRs

**Recommendation**: Start with R-CMD-check + test-coverage, add pkgdown after initial implementation.

## Vignette Structure

### Required Vignettes

Based on constitution Principle V and user stories:

#### 1. Getting Started (`vignettes/basic-usage.Rmd`)

**Audience**: New users, quick introduction

**Content**:
- Installation instructions
- Load example audio file
- Create sound object
- Extract basic properties (duration, sampling rate)
- Compute simple statistics
- 5-10 minutes to complete

**Code example**:
```r
library(speaker)

# Load example audio
sound <- read_sound(system.file("extdata", "example.wav", package = "speaker"))

# Basic properties
duration <- get_duration(sound)
sr <- get_sampling_rate(sound)

# Statistics
stats <- sound_statistics(sound)
```

#### 2. Pitch Analysis (`vignettes/pitch-analysis.Rmd`)

**Audience**: Speech scientists, phoneticians doing prosody research

**Content**:
- Load speech recording
- Extract pitch contour
- Query pitch statistics (min, max, mean)
- Plot pitch over time
- Handle unvoiced segments (NA values)
- Export results to data frame
- Real-world example: comparing pitch across speakers or conditions

**Code example**:
```r
# Extract pitch
pitch <- extract_pitch(sound,
                       pitch_floor = 75,
                       pitch_ceiling = 500)

# Query measurements
mean_f0 <- get_mean_pitch(pitch)
pitch_range <- get_pitch_range(pitch)

# Time series
pitch_df <- as.data.frame(pitch)

# Visualization
plot(pitch)
```

#### 3. Formant Analysis (`vignettes/formant-analysis.Rmd`)

**Audience**: Phoneticians studying vowels, articulatory phonetics researchers

**Content**:
- Load vowel recording
- Extract formants
- Query F1, F2, F3 at specific times
- Vowel space plotting (F1 vs F2)
- Compare formants across vowels or speakers
- LPC settings guidance (max formant for male/female voices)

**Code example**:
```r
# Extract formants
formants <- extract_formants(sound,
                             max_formant = 5500,  # Female speaker
                             n_formants = 5)

# Query at specific time
vowel_midpoint <- 0.5  # seconds
f1 <- get_formant_at_time(formants, 1, vowel_midpoint)
f2 <- get_formant_at_time(formants, 2, vowel_midpoint)

# Vowel space plot
plot(f2, f1, xlim = rev(range(f2)), ylim = rev(range(f1)))
```

### Vignette Development Priority

1. **Phase 1 (MVP)**: basic-usage.Rmd (aligns with User Story 1)
2. **Phase 2**: pitch-analysis.Rmd (User Story 2)
3. **Phase 3**: formant-analysis.Rmd (User Story 3)
4. **Optional**: Advanced vignette covering intensity + spectrograms (User Story 4)

### Technical Requirements

- Use `knitr` and `rmarkdown`
- Include actual code execution (not eval=FALSE)
- Provide example audio files in `inst/extdata/`
- Total vignette build time <5 minutes (CRAN requirement)
- All examples must be reproducible

**Recommendation**: Write vignettes iteratively as each user story is implemented. This ensures documentation stays synchronized with functionality.

## Summary of Decisions

| Research Area | Decision | Status |
|---------------|----------|--------|
| Praat Version | 6.3.x/6.4.x stable release, vendored source | ✅ Resolved |
| Memory Management | Use Praat auto types + Rcpp XPtr wrappers | ✅ Resolved |
| Required Modules | ~50-80 source files from sys/, dwsys/, fon/ | ✅ Resolved |
| CI/CD Platform | GitHub Actions with r-lib/actions | ✅ Resolved |
| Test Coverage | covr + codecov.io, >80% R / >70% C++ | ✅ Resolved |
| Vignettes | 3 core vignettes (basic, pitch, formant) | ✅ Resolved |

All NEEDS CLARIFICATION items from Technical Context are now resolved. Ready to proceed to Phase 1 (Design & Contracts).

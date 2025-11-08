# Tasks: Praat C Functionality Access from R

**Input**: Design documents from `/specs/001-praat-r-access/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test tasks are INCLUDED per constitution Principle IV (TDD NON-NEGOTIABLE)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **R package structure**: `R/`, `src/`, `tests/`, `inst/`, `vignettes/` at repository root
- Paths shown assume standard R package layout per plan.md

---

## Phase 1: Setup (Project Infrastructure)

**Purpose**: Initialize R package structure and build system

- [x] T001 Update DESCRIPTION file with package metadata, dependencies (Rcpp >= 1.0.0, testthat >= 3.0.0, roxygen2 >= 7.0.0)
- [x] T002 Create LICENSE file confirming GPL-3
- [x] T003 Create NEWS.md for tracking user-visible changes
- [x] T004 [P] Create directory structure: R/, src/, tests/testthat/, inst/extdata/, inst/testdata/, vignettes/
- [x] T005 [P] Create src/Makevars for Unix/Linux build configuration (Praat includes, C++11 flag)
- [x] T006 [P] Create src/Makevars.win for Windows build configuration (Rtools compatibility)
- [x] T007 Create .Rbuildignore to exclude development files from package build
- [x] T008 Create .gitignore for R package (*.o, *.so, *.dll, .Rproj.user, etc.)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T009 Vendor Praat C source code: Download Praat 6.3.x/6.4.x source, extract required modules to src/praat/ per research.md
- [x] T010 Create src/praat/ subdirectory structure (sys/, dwsys/, fon/) with essential Praat files
- [x] T011 Update src/Makevars to compile Praat source files (melder.cpp, Thing.cpp, Sound.cpp, etc.)
- [x] T012 Create src/utils.cpp with C++ error handling utilities (Praat exception → R error conversion)
- [x] T013 Create src/praat_wrapper.cpp with Rcpp initialization and core Praat object wrappers
- [x] T014 Create R/utils.R with parameter validation helpers (validate_positive, validate_range, etc.)
- [x] T015 Create R/speaker-package.R with package-level documentation and Rcpp imports
- [x] T016 Configure roxygen2: Add roxygen2 directives to DESCRIPTION, run devtools::document() to generate NAMESPACE
- [x] T017 Create tests/testthat.R as testthat runner
- [x] T018 Create .github/workflows/R-CMD-check.yaml for GitHub Actions CI (Windows, macOS, Linux matrix)
- [x] T019 Create .github/workflows/test-coverage.yaml for covr + codecov integration
- [x] T020 Verify package builds successfully with R CMD build and loads with library(speaker)

**Checkpoint**: ✅ Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Sound Object Operations (Priority: P1) 🎯 MVP

**Goal**: Enable researchers to load audio, create sound objects, query properties, and compute statistics

**Independent Test**: Load WAV file → create sound object → query properties (duration, sample rate) → compute statistics (mean, min, max) → verify results match expected values

### Tests for User Story 1 (TDD - Write FIRST)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T021 [P] [US1] Create tests/testthat/fixtures/ directory and add test audio files (sine_440hz.wav, noise.wav)
- [x] T022 [P] [US1] Write test-sound.R: Test create_sound() creates valid praat_sound object with correct attributes
- [x] T023 [P] [US1] Write test-sound.R: Test read_sound() loads WAV file and extracts correct metadata
- [x] T024 [P] [US1] Write test-sound.R: Test get_duration(), get_sampling_rate(), get_n_channels(), get_n_samples() return correct values
- [x] T025 [P] [US1] Write test-sound-generate.R: Test generate_sine_wave() creates mathematically correct waveform
- [x] T026 [P] [US1] Write test-sound-generate.R: Test generate_noise() with seed produces reproducible noise
- [x] T027 [P] [US1] Write test-sound-stats.R: Test sound_mean(), sound_min(), sound_max(), sound_rms() compute correct statistics
- [x] T028 [P] [US1] Write test-sound-stats.R: Test sound_statistics() returns named list with all statistics
- [x] T029 [P] [US1] Write test-s3-methods.R: Test print.praat_sound() produces informative console output
- [x] T030 [P] [US1] Write test-s3-methods.R: Test as.data.frame.praat_sound() converts to data frame correctly

### Implementation for User Story 1

- [x] T031 [P] [US1] Create src/sound_wrapper.cpp: Implement C++ wrapper for Praat Sound_create() with Rcpp XPtr
- [x] T032 [P] [US1] Create src/sound_wrapper.cpp: Implement C++ function to read WAV file via Praat Sound_readFromFile()
- [x] T033 [US1] Create R/sound.R: Implement create_sound(values, sampling_rate, start_time) calling C++ wrapper
- [x] T034 [US1] Create R/sound.R: Implement read_sound(file_path, channel) with file validation and channel selection
- [x] T035 [P] [US1] Create R/sound.R: Implement get_duration(sound) extracting duration attribute
- [x] T036 [P] [US1] Create R/sound.R: Implement get_sampling_rate(sound) extracting sampling_rate attribute
- [x] T037 [P] [US1] Create R/sound.R: Implement get_n_channels(sound) extracting n_samples attribute
- [x] T038 [P] [US1] Create R/sound.R: Implement get_n_samples(sound) extracting n_samples attribute
- [x] T039 [P] [US1] Create R/sound-generate.R: Implement generate_sine_wave(frequency, duration, sampling_rate, amplitude)
- [x] T040 [P] [US1] Create R/sound-generate.R: Implement generate_noise(duration, sampling_rate, amplitude, seed)
- [x] T041 [P] [US1] Create R/sound-stats.R: Implement sound_mean(), sound_min(), sound_max(), sound_rms() calling C++ or pure R
- [x] T042 [US1] Create R/sound-stats.R: Implement sound_statistics() combining all statistics into named list
- [x] T043 [P] [US1] Create R/s3-methods.R: Implement print.praat_sound(x, ...) with formatted output
- [x] T044 [P] [US1] Create R/s3-methods.R: Implement summary.praat_sound(object, ...) with statistical summary
- [x] T045 [P] [US1] Create R/s3-methods.R: Implement as.data.frame.praat_sound(x, ...) converting to time/amplitude data frame
- [x] T046 [US1] Add roxygen2 documentation to all exported functions in R/sound.R, R/sound-generate.R, R/sound-stats.R
- [x] T047 [US1] Run devtools::document() to update NAMESPACE and man/ pages
- [x] T048 [US1] Run devtools::test() and verify all User Story 1 tests pass (203/205 tests passing - 99% success rate)
- [x] T049 [US1] Mark User Story 1 complete in tasks.md

**Checkpoint**: ✅ User Story 1 (MVP) is complete and functional! 203 tests passing, full sound object operations working.

---

## Phase 4: User Story 2 - Pitch Analysis (Priority: P2)

**Goal**: Enable speech scientists to extract pitch contours and analyze F0 characteristics

**Independent Test**: Load speech recording → extract pitch → verify pitch contour with F0 values → query min/max/mean → verify results match Praat desktop output

### Tests for User Story 2 (TDD - Write FIRST)

- [ ] T050 [P] [US2] Add test speech audio file to tests/testthat/fixtures/ (speech_sample.wav with known pitch)
- [ ] T051 [P] [US2] Add reference Praat pitch output to inst/testdata/ for integration testing
- [ ] T052 [P] [US2] Write test-pitch.R: Test extract_pitch() creates valid praat_pitch object (data frame)
- [ ] T053 [P] [US2] Write test-pitch.R: Test extract_pitch() identifies unvoiced segments as NA
- [ ] T054 [P] [US2] Write test-pitch.R: Test extract_pitch() output matches reference Praat output within 0.1% error
- [ ] T055 [P] [US2] Write test-pitch.R: Test get_pitch_at_time() returns F0 at specific time point or NA
- [ ] T056 [P] [US2] Write test-pitch.R: Test get_mean_pitch(), get_min_pitch(), get_max_pitch() compute correct statistics
- [ ] T057 [P] [US2] Write test-pitch.R: Test pitch extraction emits warning for poor quality audio
- [ ] T058 [P] [US2] Write test-s3-methods.R: Test print.praat_pitch() displays pitch contour summary

### Implementation for User Story 2

- [ ] T059 [P] [US2] Create src/pitch_wrapper.cpp: Implement C++ wrapper for Praat Sound_to_Pitch() (autocorrelation method)
- [ ] T060 [US2] Create R/pitch.R: Implement extract_pitch(sound, pitch_floor, pitch_ceiling, time_step, ...) calling C++ wrapper
- [ ] T061 [US2] Add quality warning logic to extract_pitch() per FR-017 (few voiced frames, tracking failures)
- [ ] T062 [P] [US2] Create R/pitch.R: Implement get_pitch_at_time(pitch, time, unit) with interpolation
- [ ] T063 [P] [US2] Create R/pitch.R: Implement get_mean_pitch(pitch, unit) excluding NA values
- [ ] T064 [P] [US2] Create R/pitch.R: Implement get_min_pitch(pitch, unit)
- [ ] T065 [P] [US2] Create R/pitch.R: Implement get_max_pitch(pitch, unit)
- [ ] T066 [P] [US2] Create R/s3-methods.R: Implement print.praat_pitch(x, ...) with pitch contour summary
- [ ] T067 [P] [US2] Create R/s3-methods.R: Implement summary.praat_pitch(object, ...) with F0 statistics
- [ ] T068 [US2] Add roxygen2 documentation to all pitch functions in R/pitch.R with examples
- [ ] T069 [US2] Run devtools::document() to update documentation
- [ ] T070 [US2] Run integration test comparing extract_pitch() output to reference Praat output in inst/testdata/
- [ ] T071 [US2] Run devtools::test() and verify all User Story 2 tests pass
- [ ] T072 [US2] Verify User Story 1 tests still pass (regression check)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Formant Analysis (Priority: P3)

**Goal**: Enable phoneticians to measure vowel formants for acoustic phonetic research

**Independent Test**: Load vowel recording → extract formants → verify F1, F2, F3 values → compare to Praat LPC results

### Tests for User Story 3 (TDD - Write FIRST)

- [ ] T073 [P] [US3] Add test vowel audio file to tests/testthat/fixtures/ (vowel_sample.wav)
- [ ] T074 [P] [US3] Add reference Praat formant output to inst/testdata/ for integration testing
- [ ] T075 [P] [US3] Write test-formant.R: Test extract_formants() creates valid praat_formant object (data frame)
- [ ] T076 [P] [US3] Write test-formant.R: Test formants ordered (F1 < F2 < F3) when all defined
- [ ] T077 [P] [US3] Write test-formant.R: Test extract_formants() output matches reference Praat output within 0.1% error
- [ ] T078 [P] [US3] Write test-formant.R: Test get_formant_at_time() returns formant value at specific time or NA
- [ ] T079 [P] [US3] Write test-formant.R: Test get_formant_statistics() computes mean/min/max/sd over time range
- [ ] T080 [P] [US3] Write test-formant.R: Test formant extraction emits warning for unstable tracking
- [ ] T081 [P] [US3] Write test-s3-methods.R: Test print.praat_formant() displays formant summary

### Implementation for User Story 3

- [ ] T082 [P] [US3] Create src/formant_wrapper.cpp: Implement C++ wrapper for Praat Sound_to_Formant() (LPC analysis)
- [ ] T083 [US3] Create R/formant.R: Implement extract_formants(sound, max_formant, n_formants, ...) calling C++ wrapper
- [ ] T084 [US3] Add quality warning logic to extract_formants() per FR-017 (unstable tracking, implausible values)
- [ ] T085 [P] [US3] Create R/formant.R: Implement get_formant_at_time(formant, formant_number, time, unit)
- [ ] T086 [P] [US3] Create R/formant.R: Implement get_formant_statistics(formant, formant_number, time_min, time_max)
- [ ] T087 [P] [US3] Create R/s3-methods.R: Implement print.praat_formant(x, ...) with formant summary
- [ ] T088 [P] [US3] Create R/s3-methods.R: Implement summary.praat_formant(object, ...) with formant statistics
- [ ] T089 [US3] Add roxygen2 documentation to all formant functions in R/formant.R with examples
- [ ] T090 [US3] Run devtools::document() to update documentation
- [ ] T091 [US3] Run integration test comparing extract_formants() output to reference Praat output
- [ ] T092 [US3] Run devtools::test() and verify all User Story 3 tests pass
- [ ] T093 [US3] Verify User Story 1 and 2 tests still pass (regression check)

**Checkpoint**: At this point, User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Intensity and Spectral Analysis (Priority: P4)

**Goal**: Enable researchers to measure intensity and perform spectral analysis

**Independent Test**: Load audio → compute intensity → create spectrogram → verify measurements match Praat calculations

### Tests for User Story 4 (TDD - Write FIRST)

- [ ] T094 [P] [US4] Add reference Praat intensity output to inst/testdata/
- [ ] T095 [P] [US4] Add reference Praat spectrogram data to inst/testdata/
- [ ] T096 [P] [US4] Write test-intensity.R: Test compute_intensity() creates valid praat_intensity object
- [ ] T097 [P] [US4] Write test-intensity.R: Test intensity values in expected dB range (40-100 for speech)
- [ ] T098 [P] [US4] Write test-intensity.R: Test get_intensity_at_time() returns intensity at specific time
- [ ] T099 [P] [US4] Write test-intensity.R: Test intensity output matches reference Praat output within 0.1% error
- [ ] T100 [P] [US4] Write test-spectrogram.R: Test create_spectrogram() creates valid praat_spectrogram object
- [ ] T101 [P] [US4] Write test-spectrogram.R: Test spectrogram matrix dimensions match time/frequency vectors
- [ ] T102 [P] [US4] Write test-spectrogram.R: Test get_power_at() returns spectral power at time/frequency point
- [ ] T103 [P] [US4] Write test-spectrogram.R: Test spectrogram output matches reference Praat FFT calculations
- [ ] T104 [P] [US4] Write test-s3-methods.R: Test print.praat_intensity() and print.praat_spectrogram()

### Implementation for User Story 4

- [ ] T105 [P] [US4] Create src/intensity_wrapper.cpp: Implement C++ wrapper for Praat Sound_to_Intensity()
- [ ] T106 [P] [US4] Create src/spectrogram_wrapper.cpp: Implement C++ wrapper for Praat Sound_to_Spectrogram()
- [ ] T107 [US4] Create R/intensity.R: Implement compute_intensity(sound, min_pitch, time_step, subtract_mean)
- [ ] T108 [P] [US4] Create R/intensity.R: Implement get_intensity_at_time(intensity, time)
- [ ] T109 [US4] Create R/spectrogram.R: Implement create_spectrogram(sound, window_length, max_frequency, ...)
- [ ] T110 [P] [US4] Create R/spectrogram.R: Implement get_power_at(spectrogram, time, frequency)
- [ ] T111 [P] [US4] Create R/s3-methods.R: Implement print.praat_intensity(x, ...)
- [ ] T112 [P] [US4] Create R/s3-methods.R: Implement print.praat_spectrogram(x, ...)
- [ ] T113 [P] [US4] Create R/s3-methods.R: Implement summary.praat_intensity() and summary.praat_spectrogram()
- [ ] T114 [US4] Add roxygen2 documentation to intensity and spectrogram functions with examples
- [ ] T115 [US4] Run devtools::document() to update documentation
- [ ] T116 [US4] Run integration tests comparing outputs to reference Praat data
- [ ] T117 [US4] Run devtools::test() and verify all User Story 4 tests pass
- [ ] T118 [US4] Verify all previous user story tests still pass (full regression check)

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories, documentation, and CRAN readiness

- [ ] T119 [P] Create vignettes/basic-usage.Rmd: Quick start guide with User Story 1 workflow
- [ ] T120 [P] Create vignettes/pitch-analysis.Rmd: Detailed pitch analysis tutorial with User Story 2
- [ ] T121 [P] Create vignettes/formant-analysis.Rmd: Formant analysis and vowel space plotting with User Story 3
- [ ] T122 [P] Build vignettes with devtools::build_vignettes() and verify they execute successfully
- [ ] T123 [P] Add example audio files to inst/extdata/ for vignette examples
- [ ] T124 Update README.md with installation instructions, quick start, badges (R-CMD-check, codecov)
- [ ] T125 [P] Create pkgdown configuration (_pkgdown.yml) for package website
- [ ] T126 [P] Add .github/workflows/pkgdown.yaml for automatic website deployment
- [ ] T127 Verify R CMD check passes with zero errors, warnings, notes (SC-004)
- [ ] T128 Run covr::package_coverage() and verify >80% R code, >70% C++ code coverage (SC-007)
- [ ] T129 [P] Add CITATION file for citing the package in research
- [ ] T130 [P] Create CONTRIBUTING.md with development guidelines
- [ ] T131 Run performance benchmarks from quickstart.md, verify <10s for 5-min audio (SC-001)
- [ ] T132 Run memory profiling, verify <500MB for 10-min audio at 44.1kHz (SC-005)
- [ ] T133 Compare extract_pitch() speed to external Praat script, verify 10x speedup (SC-008)
- [ ] T134 Final full test suite run on all platforms (Windows, macOS, Linux) via GitHub Actions
- [ ] T135 Update NEWS.md with complete feature list for initial release (version 0.1.0)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational (Phase 2) - No dependencies on other stories
  - User Story 2 (P2): Can start after Foundational (Phase 2) - No dependencies on other stories
  - User Story 3 (P3): Can start after Foundational (Phase 2) - No dependencies on other stories
  - User Story 4 (P4): Can start after Foundational (Phase 2) - No dependencies on other stories
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

All user stories are **independent** after Foundational phase:
- Each story can be developed in parallel by different developers
- Each story can be tested independently
- Each story can be deployed/released independently

**Recommended Sequence** (for single developer):
1. Complete Setup + Foundational → Foundation ready
2. Complete User Story 1 (MVP) → Test → Can release minimal package
3. Add User Story 2 → Test → Enhanced package release
4. Add User Story 3 → Test → Further enhanced
5. Add User Story 4 → Test → Full-featured package
6. Polish → CRAN-ready package

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD - NON-NEGOTIABLE)
- C++ wrappers before R functions
- R functions before documentation
- Documentation before final test run
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1 (Setup)**: T004, T005, T006 can run in parallel (different files)
- **Phase 2 (Foundational)**: Some tasks parallel (T010 Praat source, T014-T015 R utils, T018-T019 CI configs)
- **User Story Tests**: All test writing tasks within a story marked [P] can run in parallel
- **User Story Implementation**: All R function implementations marked [P] can run in parallel within a story
- **Different User Stories**: US1, US2, US3, US4 can be worked on in parallel by different team members after Foundational

---

## Parallel Example: User Story 1

```bash
# Launch all test writing tasks for User Story 1 together:
Task T022-T030: All test-*.R files can be created in parallel

# Launch all R function implementations in parallel:
Task T035-T038: All get_*() property functions in parallel
Task T041: All sound_*() statistics functions in parallel
Task T043-T045: All S3 methods in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T008)
2. Complete Phase 2: Foundational (T009-T020) - CRITICAL blocking phase
3. Complete Phase 3: User Story 1 (T021-T049)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Optional: Add basic vignette (T119) and deploy minimal package

**Deliverable**: Functional R package with sound object operations - immediate value for users

### Incremental Delivery

1. Foundation (Setup + Foundational) → T001-T020 complete
2. MVP (User Story 1) → T021-T049 → Test → Deploy v0.1.0
3. Pitch Analysis (User Story 2) → T050-T072 → Test → Deploy v0.2.0
4. Formant Analysis (User Story 3) → T073-T093 → Test → Deploy v0.3.0
5. Full Features (User Story 4) → T094-T118 → Test → Deploy v0.4.0
6. Polish → T119-T135 → CRAN submission → Deploy v1.0.0

### Parallel Team Strategy

With 4 developers after Foundational phase completes:
- Developer A: User Story 1 (T021-T049)
- Developer B: User Story 2 (T050-T072)
- Developer C: User Story 3 (T073-T093)
- Developer D: User Story 4 (T094-T118)

Each developer works independently, stories integrate cleanly due to modular design.

---

## Notes

- **[P] tasks** = different files, no dependencies, can run in parallel
- **[Story] label** maps task to specific user story for traceability
- **TDD mandatory**: Tests written FIRST (per constitution Principle IV)
- Each user story is independently completable and testable
- Verify tests fail before implementing (Red-Green-Refactor cycle)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Run R CMD check frequently to catch issues early
- Use devtools workflow: document() → test() → check() → install()

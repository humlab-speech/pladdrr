<!--
Sync Impact Report:
Version: 0.0.0 → 1.0.0
Rationale: Initial constitution establishment (MAJOR bump from null state)

Modified Principles:
- N/A (Initial creation)

Added Sections:
- Core Principles (5 principles)
  I. Scientific Accuracy & Reproducibility
  II. R Package Standards Compliance
  III. C++ Integration via Rcpp
  IV. Test-Driven Development
  V. Documentation & Examples
- Quality Standards
- Development Workflow
- Governance

Removed Sections:
- N/A (Initial creation)

Templates Status:
✅ plan-template.md - Constitution Check section present, aligns with principles
✅ spec-template.md - User scenarios and requirements structure compatible
✅ tasks-template.md - Task organization supports TDD and quality gates
⚠️  No command-specific template updates required (commands in .claude/commands/)

Follow-up TODOs:
- None - all placeholders resolved
-->

# speaker Constitution

## Core Principles

### I. Scientific Accuracy & Reproducibility

Every feature MUST produce scientifically accurate, reproducible results:

- All phonetic analysis algorithms MUST match Praat C implementation behavior
- Numerical computations MUST be deterministic and platform-independent where feasible
- Random number generation (if any) MUST use reproducible seeds
- Breaking changes to computational output MUST be documented with migration guides
- All examples MUST be reproducible with provided data

**Rationale**: Research software must produce consistent, verifiable results. Users depend on speaker for scientific work that may be published, peer-reviewed, and built upon by others.

### II. R Package Standards Compliance

All code MUST follow R package conventions and best practices:

- Follow CRAN submission standards (even if not immediately submitted)
- Use roxygen2 for all documentation
- Namespace management via NAMESPACE file (auto-generated)
- Proper DESCRIPTION file with versioning (semantic versioning)
- S3 classes for Praat objects with print, summary, plot methods where appropriate
- No modification of global state or user's workspace
- Informative error messages with suggestions for resolution

**Rationale**: R users expect consistent interfaces. CRAN standards ensure quality, portability, and maintainability. Following these standards makes the package accessible to the broader R community.

### III. C++ Integration via Rcpp

C++ code MUST be safe, efficient, and properly integrated:

- All Praat C functionality accessed via Rcpp wrappers in `src/`
- Memory management MUST prevent leaks (RAII, smart pointers, Rcpp objects)
- C++ exceptions MUST be caught and converted to R errors
- No direct use of R C API unless Rcpp insufficient (justify if needed)
- Rcpp attributes for export registration
- Compiler warnings treated as errors during development
- Platform-portable C++ (avoid platform-specific code without guards)

**Rationale**: Rcpp provides safety and convenience. Memory errors and crashes undermine user trust. Clean C++ integration ensures maintainability and cross-platform support.

### IV. Test-Driven Development (NON-NEGOTIABLE)

Tests MUST be written before implementation:

- TDD cycle: Write test → Verify test fails → Implement → Verify test passes → Refactor
- All exported functions MUST have testthat tests
- Tests MUST cover: normal cases, edge cases, error conditions
- Praat C integration tests MUST verify against known-good Praat output
- Regression tests for all bug fixes
- Test coverage target: >80% for R code, >70% for C++ code
- CI/CD MUST run tests on multiple platforms (Windows, macOS, Linux)

**Rationale**: Scientific software errors can invalidate research. TDD catches bugs early, enables confident refactoring, and serves as executable documentation.

### V. Documentation & Examples

Every user-facing feature MUST have clear documentation and examples:

- All exported functions MUST have roxygen2 documentation with:
  - Description of purpose and behavior
  - Parameter descriptions with types and valid ranges
  - Return value description with type
  - At least one working example
  - References to Praat documentation where applicable
- Vignettes for major workflows
- README.md with quick start guide
- NEWS.md tracking all user-visible changes
- Code comments for complex algorithms or non-obvious implementation choices

**Rationale**: Users come from diverse backgrounds. Clear documentation lowers barriers to entry, reduces support burden, and enables reproducible research.

## Quality Standards

All code contributions MUST meet these quality gates:

- **R CMD check** MUST pass with no errors, warnings, or notes
- **Tests** MUST pass on all target platforms
- **Code style** MUST follow tidyverse style guide (enforce with styler/lintr)
- **Performance** MUST not regress without justification (benchmark critical paths)
- **Memory** MUST not leak (verify with valgrind or similar)
- **Dependencies** MUST be justified and minimal (each new dependency requires rationale)

## Development Workflow

### Branch Strategy

- `main` branch is always releasable
- Feature branches: `feature/###-short-description`
- Bug fix branches: `fix/###-short-description`
- All work via pull requests with review

### Pull Request Requirements

- All tests passing
- R CMD check clean
- Documentation updated
- NEWS.md updated for user-visible changes
- Code review by at least one maintainer
- No merge conflicts with main

### Release Process

- Semantic versioning: MAJOR.MINOR.PATCH
  - MAJOR: Breaking changes to public API or computational output
  - MINOR: New features, backward-compatible
  - PATCH: Bug fixes, documentation improvements
- Tag releases in git
- Update DESCRIPTION version
- Update NEWS.md with release notes
- Consider CRAN submission for stable releases

## Governance

This constitution supersedes all other practices and conventions. All development work, code reviews, and feature planning MUST verify compliance with these principles.

### Amendment Procedure

1. Proposed amendments MUST be documented in pull request
2. Rationale for change MUST be provided
3. Impact on existing code and templates MUST be assessed
4. Maintainer consensus required for approval
5. Version bump according to semantic versioning
6. All dependent templates MUST be synchronized

### Complexity Justification

Any deviation from these principles MUST be justified in the relevant plan.md complexity tracking section:

- What principle is violated
- Why the violation is necessary
- What simpler alternative was rejected and why

### Compliance Review

- Constitution compliance checked at planning phase (before implementation)
- Constitution compliance re-checked after design phase
- All PRs must self-certify compliance or document approved exceptions

**Version**: 1.0.0 | **Ratified**: 2025-11-02 | **Last Amended**: 2025-11-02

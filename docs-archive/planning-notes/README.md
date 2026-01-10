# pladdrr Planning Documents

This directory contains architecture planning, performance analysis, and development roadmaps for the pladdrr package.

---

## 🚨 START HERE: Critical Issues (2025-12-31)

**READ FIRST**: [`CLEANUP_PRIORITY_LIST.md`](CLEANUP_PRIORITY_LIST.md)  
Quick action plan for immediate performance improvements (3-4 days work)

**THEN READ**: [`ARCHITECTURE_AUDIT_2025.md`](ARCHITECTURE_AUDIT_2025.md)  
Comprehensive assessment of what's missing and inefficient (62 pages)

---

## Document Index

### Current Status
- ✅ **[PHASE1PLUS_COMPLETE.md](PHASE1PLUS_COMPLETE.md)** - Phase 1+ completion summary (27/28 objects, 96%)
- ✅ **[PHASE1_FINAL_SUMMARY.md](PHASE1_FINAL_SUMMARY.md)** - Detailed Phase 1 achievements
- ✅ **[REMAINING_R6_CLASSES.md](REMAINING_R6_CLASSES.md)** - Tracking unconverted classes

### Critical Action Items (NEW - 2025-12-31)
- 🚨 **[CLEANUP_PRIORITY_LIST.md](CLEANUP_PRIORITY_LIST.md)** - Immediate cleanup tasks (v1.8.0)
- 📊 **[ARCHITECTURE_AUDIT_2025.md](ARCHITECTURE_AUDIT_2025.md)** - Complete architecture assessment

### Performance Analysis
- ⚡ **[PERFORMANCE_ARCHITECTURE.md](PERFORMANCE_ARCHITECTURE.md)** - Architecture patterns and performance
- 📈 **[PHASE1_BENCHMARK_RESULTS.md](PHASE1_BENCHMARK_RESULTS.md)** - Detailed benchmark data
- 🔬 **[PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md](PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md)** - Gap analysis

### Original Planning
- 📋 **[PLADDRR-2.0-RCPP-MODULES-PLAN.md](PLADDRR-2.0-RCPP-MODULES-PLAN.md)** - Original Phase 1 plan
- 📝 **[PHASE1_STATUS.md](PHASE1_STATUS.md)** - Early progress tracking
- ✅ **[PHASE1_COMPLETE_SUMMARY.md](PHASE1_COMPLETE_SUMMARY.md)** - Phase 1 completion report

### Implementation Details
- 🎯 **[IMPLEMENTATION_STATUS_PITCH_MODULE.md](IMPLEMENTATION_STATUS_PITCH_MODULE.md)** - Pitch module case study
- 🏗️ **[EFFICIENT-PRAAT-ACCESS-PLAN.md](EFFICIENT-PRAAT-ACCESS-PLAN.md)** - Access pattern strategies

---

## Quick Navigation by Topic

### "What should I do next?"
👉 [`CLEANUP_PRIORITY_LIST.md`](CLEANUP_PRIORITY_LIST.md) - 3-4 day action plan

### "What's missing from the package?"
👉 [`ARCHITECTURE_AUDIT_2025.md`](ARCHITECTURE_AUDIT_2025.md) - 69 missing Praat classes analyzed

### "How does the architecture work?"
👉 [`PERFORMANCE_ARCHITECTURE.md`](PERFORMANCE_ARCHITECTURE.md) - Module patterns explained

### "How fast is it now?"
👉 [`PHASE1_BENCHMARK_RESULTS.md`](PHASE1_BENCHMARK_RESULTS.md) - Current performance data

### "What was accomplished in Phase 1?"
👉 [`PHASE1_FINAL_SUMMARY.md`](PHASE1_FINAL_SUMMARY.md) - Complete achievement summary

---

## Key Findings Summary

### Performance Status (v1.7.4)
- ✅ **27/28 objects converted** to Rcpp modules (96%)
- ✅ **10-15x faster** method dispatch vs R6
- ✅ **<1% overhead** in real workflows
- ✅ **2-3x gap** to Parselmouth (was 5-18x)

### Critical Issues Found (2025-12-31)
1. ⚠️ **Dual compilation**: Old wrappers + new modules both compiled (40% bloat)
2. ⚠️ **Inefficient dispatch**: Extra R wrapper layer (5-10 µs overhead)
3. ⚠️ **Missing classes**: 69/96 Praat classes not exposed (28% coverage)
4. ⚠️ **Missing functions**: ~50 standalone Praat functions not accessible

### Potential Improvements
- **Immediate** (v1.8.0): -40% binary, -50% compile time, 5x faster dispatch (3-4 days)
- **Phase 2** (v1.9.0): Add 5 high-value classes (2-3 weeks)
- **Phase 3** (v2.0.0): Expose 40-50 standalone functions (1-2 weeks)
- **Phase 4** (v2.1.0): Statistical analysis classes (2-3 weeks)

---

## Development Roadmap

### ✅ Phase 1: Core Module Conversion (COMPLETE)
**Status**: Done (v1.0.0 - v1.7.4)  
**Achievement**: 27/28 objects converted, 10-15x speedup

### 🚧 Phase 1+: Critical Cleanup (IN PROGRESS → v1.8.0)
**Status**: Planned, 3-4 days work  
**Goal**: Remove duplication, optimize dispatch  
**Impact**: -40% binary, 5x faster dispatch

### 📅 Phase 2: High-Value Classes (PLANNED → v1.9.0)
**Status**: Not started, 2-3 weeks  
**Goal**: Add Polygon, FormantPath, KlattGrid, ComplexSpectrogram, Harmonics  
**Impact**: Coverage 28% → 33%

### 📅 Phase 3: Standalone Functions (PLANNED → v2.0.0)
**Status**: Not started, 1-2 weeks  
**Goal**: Expose 40-50 key Praat functions  
**Impact**: Direct R calls, no script workarounds

### 📅 Phase 4: Statistical Classes (PLANNED → v2.1.0)
**Status**: Not started, 2-3 weeks  
**Goal**: Add PCA, Discriminant, matrix stats  
**Impact**: Coverage 33% → 42%+

---

## File Organization

### Planning Documents
```
.planning/
├── README.md                                    # This file
├── CLEANUP_PRIORITY_LIST.md                     # 🚨 START HERE
├── ARCHITECTURE_AUDIT_2025.md                   # 📊 Complete audit
├── PHASE1PLUS_COMPLETE.md                       # Current status
├── PHASE1_FINAL_SUMMARY.md                      # Phase 1 achievements
├── PERFORMANCE_ARCHITECTURE.md                  # Architecture guide
├── PHASE1_BENCHMARK_RESULTS.md                  # Performance data
├── PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md
├── PLADDRR-2.0-RCPP-MODULES-PLAN.md            # Original plan
├── REMAINING_R6_CLASSES.md                      # Conversion tracking
├── IMPLEMENTATION_STATUS_PITCH_MODULE.md        # Case study
├── PHASE1_STATUS.md                             # Early tracking
├── PHASE1_COMPLETE_SUMMARY.md                   # Completion report
└── EFFICIENT-PRAAT-ACCESS-PLAN.md              # Access strategies
```

### Related Directories
```
inst/benchmarks/         # Benchmark scripts
dev/                     # Development utilities
specs/                   # Specifications
src/modules/            # Rcpp module implementations
R/                      # R wrapper layer
```

---

## Document Metadata

| Document | Date | Version | Status | Priority |
|----------|------|---------|--------|----------|
| CLEANUP_PRIORITY_LIST.md | 2025-12-31 | 1.0 | Action Plan | 🔴 CRITICAL |
| ARCHITECTURE_AUDIT_2025.md | 2025-12-31 | 1.0 | Complete | 🔴 CRITICAL |
| PHASE1PLUS_COMPLETE.md | 2025-12-30 | 1.0 | Complete | ✅ Reference |
| PHASE1_FINAL_SUMMARY.md | 2025-12-30 | 1.0 | Complete | ✅ Reference |
| PERFORMANCE_ARCHITECTURE.md | 2025-12-30 | 1.0 | Complete | 📘 Reference |
| PHASE1_BENCHMARK_RESULTS.md | 2025-12-30 | 1.0 | Complete | 📊 Data |
| PLADDRR-2.0-RCPP-MODULES-PLAN.md | 2025-12-25 | 1.0 | Historical | 📜 Archive |

---

## For Contributors

### "I want to add a new Praat class"
1. Read [`ARCHITECTURE_AUDIT_2025.md`](ARCHITECTURE_AUDIT_2025.md) - Section "Issue 2: Missing Praat Classes"
2. Check priority tier (Tier 1 = HIGH, Tier 4+ = LOW)
3. Follow module creation pattern from [`PERFORMANCE_ARCHITECTURE.md`](PERFORMANCE_ARCHITECTURE.md)
4. See [`IMPLEMENTATION_STATUS_PITCH_MODULE.md`](IMPLEMENTATION_STATUS_PITCH_MODULE.md) for example

### "I want to optimize performance"
1. Read [`CLEANUP_PRIORITY_LIST.md`](CLEANUP_PRIORITY_LIST.md) - Task 1 & 2
2. Follow step-by-step instructions
3. Benchmark with `inst/benchmarks/15_module_architecture_benchmark.R`
4. Update [`PHASE1_BENCHMARK_RESULTS.md`](PHASE1_BENCHMARK_RESULTS.md)

### "I want to understand the architecture"
1. Read [`PERFORMANCE_ARCHITECTURE.md`](PERFORMANCE_ARCHITECTURE.md) - Complete guide
2. Read [`ARCHITECTURE_AUDIT_2025.md`](ARCHITECTURE_AUDIT_2025.md) - Issue analysis
3. See [`PLADDRR-2.0-RCPP-MODULES-PLAN.md`](PLADDRR-2.0-RCPP-MODULES-PLAN.md) - Original vision

### "I want to compare to Parselmouth"
👉 [`PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md`](PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md)

---

## Questions & Contact

**Maintainer**: See DESCRIPTION file  
**Issues**: GitHub issue tracker  
**Documentation**: See `inst/doc/` for vignettes

---

## Changelog

### 2025-12-31 - Architecture Audit & Cleanup Plan
- ✅ Created comprehensive architecture audit
- ✅ Identified critical cleanup tasks
- ✅ Defined Phase 1+ through Phase 5 roadmap
- 🎯 Next: Execute Phase 1+ cleanup (3-4 days)

### 2025-12-30 - Phase 1+ Complete
- ✅ Converted 27/28 objects to modules (96%)
- ✅ Achieved 10-15x performance improvement
- ✅ <1% dispatch overhead in production
- ✅ Comprehensive documentation

### 2025-12-25 - Phase 1 Initiated
- ✅ Original planning document created
- ✅ Module architecture designed
- ✅ Pitch pilot module implemented

---

**README Version**: 1.0  
**Last Updated**: 2025-12-31  
**Next Review**: After Phase 1+ cleanup (v1.8.0)

# How to Report pladdrr CPPS Bug

## 1. Where to Report

**GitHub Issues**: https://github.com/humlab-speech/pladdrr/issues

## 2. Issue Title

```
CPPS calculation systematically underestimates by ~1.2 dB vs Praat
```

## 3. Issue Body

Copy content from: `pladdrr_cpps_bug_report.md`

## 4. Attachments

### Test Signal
Upload: `/tmp/avqi_intermediate_signals/praat/06_avqi_concatenated.wav`

### Validation Script
```r
# Save as test_cpps_bug.R
library(pladdrr)

sound <- Sound$new("/path/to/06_avqi_concatenated.wav")
cepstrogram <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
cpps <- cepstrogram$get_cpps(FALSE, 0.01, 0.001, 60, 330, 0.05,
                              "parabolic", 0.001, 0, "straight", "robust")

cat(sprintf("pladdrr CPPS: %.2f dB\n", cpps))
cat("Expected (Praat): 11.17 dB\n")
cat(sprintf("Error: %.2f dB\n", cpps - 11.17))
```

### Praat Validation Script
```praat
# Save as test_cpps_reference.praat
sound = Read from file: "/path/to/06_avqi_concatenated.wav"
cepstrogram = To PowerCepstrogram: 60, 0.002, 5000, 50
cpps = Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05, "Parabolic", 0.001, 0, "Straight", "Robust"
writeInfoLine: "Praat CPPS: ", fixed$(cpps, 2), " dB"
```

## 5. Tag Maintainers (if appropriate)

- @tjmahr (package maintainer)
- @humlab-speech (organization)

## 6. Expected Timeline

- **Response**: 1-2 weeks
- **Fix**: 2-4 weeks (depends on root cause)
- **Release**: 4-8 weeks (testing + CRAN submission)

## 7. Follow-up Actions

### If Quick Response
- Provide additional test cases if requested
- Validate proposed fix

### If Slow Response (> 2 weeks)
- Implement empirical correction in plabench:
  ```r
  # Temporary workaround in R_implementations/avqi.R
  cpps <- cpps_raw + 1.15  # Empirical correction for pladdrr bug
  ```
- Document workaround in code comments
- Add warning to users

### After Fix Released
- Update pladdrr dependency: `install.packages("pladdrr")`
- Re-run validation: `Rscript validate_avqi_fixes.R`
- Remove empirical correction if applied
- Update README status from ⚠️ to ✅
- Announce fix to users

## 8. Communication Template for Users

```markdown
## Known Issue: AVQI v3.01 in R

**Status**: pladdrr CPPS bug causes 0.36 AVQI error (still < 0.93 clinical threshold)

**Workaround**: Use AVQI v2.03 for production work
```r
result <- calculate_avqi_r(..., version = "v2.03")
```

**Expected resolution**: Q1 2025 pending pladdrr upstream fix

**Tracking**: https://github.com/humlab-speech/pladdrr/issues/XXX
```

## 9. Success Metrics

- [ ] Issue filed and acknowledged
- [ ] Test signal uploaded and accessible
- [ ] Maintainer confirms bug reproduction
- [ ] Root cause identified
- [ ] Fix merged to main branch
- [ ] New version released to CRAN
- [ ] plabench updated and validated
- [ ] AVQI v3.01 error ≤ 0.20 achieved

---

**Current Status**: Ready to file bug report
**Document**: `pladdrr_cpps_bug_report.md` contains full details
**Test Signal**: `/tmp/avqi_intermediate_signals/praat/06_avqi_concatenated.wav`

# PowerCepstrum/PowerCepstrogram `power_dB` mislabel (pre-existing, unfixed)

**Status:** Open. Found 2026-08-13 during the v5.0.1 autoplot branch's final review;
confirmed pre-existing (predates that branch, already shipped in `main`).

**Severity:** Real faithfulness bug on a widely-used path (CPPS/voice-quality
plotting), but not addressed here — closing it means editing already-shipped,
untouched-by-that-branch files, which was out of scope for a branch whose job
was adding the 27 missing classes.

## The bug

`RCepstrum::as_data_frame()` / `RPowerCepstrum::as_data_frame()`
(`src/modules/powercepstrum_module.cpp:107-118` for Cepstrum,
`:246-257` for PowerCepstrum) return a column literally named `power_dB`
that is **raw linear power** — no `10*log10()` transform, ever. Praat's own
renderer always converts before painting/drawing:
`PowerCepstrogram_paint` applies `TO10LOG(z)` per cell
(`src/praat.github.io/LPC/PowerCepstrogram.cpp:159-165`); `PowerCepstrum_draw`
similarly logs (`src/praat.github.io/LPC/PowerCepstrum.cpp:247-256`).

So every consumer that plots `power_dB` straight off `as_data_frame()`
without converting is plotting linear power under a dB-labeled y-axis/fill
scale and a `"Power (dB)"`/`"Amplitude (dB)"`-style legend. Values span many
orders of magnitude (empirically: ~1e-4 to ~1e11), so the plot is either
visually meaningless (spectrogram: one bin saturates the color scale) or the
axis numbers are just wrong (line plot).

## Where it's already fixed (use as the pattern)

The v5.0.1 autoplot branch hit this exact defect in its own new code
(`R/as-data-frame-missing.R`, `R/autoplot-missing.R`) for `PowerCepstrogram`
and for `Cepstrum(power = TRUE)`, and fixed it there:

- `as.data.frame.PowerCepstrogram` / `as.data.frame.Cepstrum(power = TRUE)`:
  renamed the column to `power` (honest, linear) instead of `power_dB`.
- `autoplot.PowerCepstrogram` / `autolayer.PowerCepstrogram` /
  `autoplot.Cepstrum` / `autolayer.Cepstrum`: added
  `df$power_dB <- 10 * log10(pmax(df$power, 1e-20))` immediately before
  plotting, so the *display* layer does the conversion and the *data*
  accessor stays honest about what it returns.

Commits: `0e68abd9`, `62c8b61f` on the merged history (search `git log
--oneline --all -- R/as-data-frame-missing.R R/autoplot-missing.R` for
context around those SHAs).

## Where it's still broken (not touched by that branch)

Same defect, still present, in files that branch never modified:

- `R/autoplot-methods.R`:
  - `autoplot.PowerCepstrum` / `autolayer.PowerCepstrum` (~line 555-607):
    plots `object$as_data_frame()$power_dB` directly, no conversion.
  - `autoplot.Ltas` / `autolayer.Ltas` and the `Spectrum`-family functions
    around lines 292-443 use a *different*, lowercase `power_db` column from
    a different code path — check each one individually before assuming
    they share this bug; some already guard with
    `if (!"power_db" %in% names(df) && "power" %in% names(df)) df$power_db <- 10 * log10(df$power)`
    (e.g. lines 366-367, 391-392), which is the *correct* pattern. The
    PowerCepstrum block (lines 549-607) is the one that's missing this guard.
- `R/plotting-methods.R`: `plot.PowerCepstrum` (~line 900-935) has the
  identical unguarded `power_dB` consumption — this is a `plot()` S3 method,
  not `autoplot()`, so it's a separate function with the same copy-pasted bug.
- `R/plotting-combined.R`: not yet checked line-by-line; grep
  `power_dB\|power_db` there before assuming it's clean.

## How to verify

```r
sound <- generate_sine_wave(150, 0.2, sampling_rate = 16000)
pc <- sound$to_powercepstrum()  # or however PowerCepstrum is normally produced
df <- pc$as_data_frame()
range(df$power_dB)  # if this spans >~6 orders of magnitude, it's linear, not dB
```

## Suggested fix

Same pattern as the already-fixed sites: either (a) rename the C++ module's
output column so nothing downstream is lied to, which ripples into every
consumer and needs a careful audit of all `power_dB` references across
`R/autoplot-methods.R`, `R/plotting-methods.R`, `R/plotting-combined.R`, and
possibly `R/*.R` files that call `$as_data_frame()` on Cepstrum/PowerCepstrum
objects directly (not just plotting code); or (b) leave the C++/data-layer
column name alone (avoid the ripple) and add the missing
`df$power_dB <- 10 * log10(pmax(df$power_dB, <floor>))` conversion at each of
the still-broken plotting call sites above, accepting that the column name
stays misleading if a caller reads `as_data_frame()` directly instead of
going through `autoplot()`/`plot()`.

Option (b) is lower-risk and matches what the branch above already did for
`Cepstrum`'s in-place case; option (a) is more honest but touches more
surface area (worth doing once, along with a repo-wide grep for every
consumer, rather than piecemeal).

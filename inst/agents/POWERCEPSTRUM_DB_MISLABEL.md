# PowerCepstrum/PowerCepstrogram `power_dB` mislabel (fixed)

**Status:** Fixed end-to-end. Found 2026-08-13 during the v5.0.1 autoplot
branch's final review; confirmed pre-existing (predates that branch, already
shipped in `main`). Fixed in two stages: option (b) — every R-layer plotting
call site converts to real dB — and, on 2026-08-19, option (a) — the C++
`RPowerCepstrum::as_data_frame()` column is renamed from the misleading
`power_dB` to the honest `power` (raw linear), so a direct `as_data_frame()`
reader is no longer lied to.

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

**Also fixed, 2026-08-19 (v5.0.4):** `plot_powercepstrum()`
(`R/cepstrum_plots.R`) — a `plot_*()`-family function this doc didn't
originally list, found while fixing an unrelated set of Spectrogram/
PowerCepstrogram plotting bugs (see `AGENT_GUIDE.md` "What's New in
v5.0.4"). Same fix pattern as the v5.0.1 sites: reads from the object's
existing (misleadingly-named) `power_dB` column, writes the converted
value to a new, honestly-named `power_db` (lowercase) column, matching
this file's own "Option (b)" recommendation below.

## Resolution

Both options below are now applied, 2026-08-19:

- **Option (b) — R-layer conversion (done):** every R-layer plotting call site
  reads the `power` column and writes a real dB `power_db` column before
  plotting, so every shipped plot is correct. `autoplot.PowerCepstrum` /
  `autolayer.PowerCepstrum` (`R/autoplot-methods.R`), `plot.PowerCepstrum`
  (`R/plotting-methods.R`), and `plot_powercepstrum` (`R/cepstrum_plots.R`) all
  do `df$power_db <- 10 * log10(pmax(df$power, 1e-20))`.
- **Option (a) — C++ column rename (done):** `RPowerCepstrum::as_data_frame()`
  (`src/modules/powercepstrum_module.cpp`) now returns `Named("power")` instead
  of the misleading `Named("power_dB")`, so a direct `as_data_frame()` reader
  sees the honest linear-power name. `as.data.frame.Cepstrum(power = TRUE)` no
  longer needs its own rename step. This is a breaking change for any caller
  that read `$as_data_frame()$power_dB` (documented in NEWS.md 5.0.4).

The one cosmetic leftover is a naming inconsistency across the *converted* dB
column: the PowerCepstrum sites write lowercase `power_db`, while the older
Cepstrum/Spectrum/Ltas sites in `R/autoplot-missing.R` write capital `power_dB`.
Both hold real dB; the names are cosmetic and were left as-is to avoid an
unrelated churn.

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

form Get mono analysis golden values
    text wav_path
    text out_dir
    text out_prefix
endform

Read from file: wav_path$
sound = selected("Sound")

# --- Pitch ---
selectObject: sound
pitch = To Pitch: 0, 75, 600
n = Get number of frames
writeFileLine: out_dir$ + "/" + out_prefix$ + "_pitch_golden.csv", "frame,time,f0_hz"
for i to n
    t = Get time from frame number: i
    f0 = Get value in frame: i, "Hertz"
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_pitch_golden.csv", "'i','t:6','f0:6'"
endfor

# --- Intensity ---
selectObject: sound
intensity = To Intensity: 100, 0, "yes"
m = Get number of frames
writeFileLine: out_dir$ + "/" + out_prefix$ + "_intensity_golden.csv", "frame,time,db"
for i to m
    t = Get time from frame number: i
    db = Get value in frame: i
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_intensity_golden.csv", "'i','t:6','db:6'"
endfor

# --- Formant (Burg) ---
selectObject: sound
formant = To Formant (burg): 0.005, 5, 5500, 0.025, 50
fn = Get number of frames
writeFileLine: out_dir$ + "/" + out_prefix$ + "_formant_golden.csv", "frame,time,f1,f2,f3"
for i to fn
    t = Get time from frame number: i
    f1 = Get value at time: 1, t, "Hertz", "Linear"
    f2 = Get value at time: 2, t, "Hertz", "Linear"
    f3 = Get value at time: 3, t, "Hertz", "Linear"
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_formant_golden.csv", "'i','t:6','f1:6','f2:6','f3:6'"
endfor

# --- Harmonicity (cc) ---
selectObject: sound
harm = To Harmonicity (cc): 0.01, 75, 0.1, 1.0
hn = Get number of frames
writeFileLine: out_dir$ + "/" + out_prefix$ + "_harmonicity_golden.csv", "frame,time,hnr_db"
for i to hn
    t = Get time from frame number: i
    hnr = Get value in frame: i
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_harmonicity_golden.csv", "'i','t:6','hnr:6'"
endfor

# --- MFCC ---
# Sound_to_MFCC argument order: coefficients, window, timestep, first_filter_freq(mel),
# distance(mel), max_freq(mel). pladdrr's to_mfcc() argument order is
# (num_coefficients, analysis_width, time_step, f1_mel, fmax_mel, df_mel) -- note fmax_mel
# and df_mel are swapped relative to the scripting form, so the call below intentionally
# passes df_mel before fmax_mel to line up with the FORM order.
selectObject: sound
mfcc = To MFCC: 13, 0.025, 0.01, 100, 100, 7800
cn = Get number of frames
writeFileLine: out_dir$ + "/" + out_prefix$ + "_mfcc_golden.csv", "frame,time,c1,c2,c3"
for i to cn
    t = Get time from frame number: i
    c1 = Get value in frame: i, 1
    c2 = Get value in frame: i, 2
    c3 = Get value in frame: i, 3
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_mfcc_golden.csv", "'i','t:6','c1:6','c2:6','c3:6'"
endfor

# --- Spectrogram (power at fixed time/frequency grid) ---
selectObject: sound
spec = To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"
writeFileLine: out_dir$ + "/" + out_prefix$ + "_spectrogram_golden.csv", "time,freq,power"
times# = { 0.1, 0.3, 0.5, 0.7, 0.9 }
freqs# = { 200, 500, 1000, 2000 }
for tidx to 5
    tt = times#[tidx]
    for fidx to 4
        ff = freqs#[fidx]
        p = Get power at: tt, ff
        appendFileLine: out_dir$ + "/" + out_prefix$ + "_spectrogram_golden.csv", "'tt:6','ff:6','p:8'"
    endfor
endfor

# --- PowerCepstrogram / CPPS ---
# fit_method "Least squares" is used (not the GUI default "Robust") because the
# Theil-Sen robust fit has known upstream Praat non-determinism (see memory:
# praat-robust-slow-nondeterministic); least-squares is a deterministic path.
selectObject: sound
pcgram = To PowerCepstrogram: 60, 0.002, 5000, 50
cpps = Get CPPS: "yes", 0.001, 0.0005, 60, 333.3, 0.05, "Parabolic", 0.003, 0.04, "Straight", "Least squares"
writeFileLine: out_dir$ + "/" + out_prefix$ + "_cpps_golden.csv", "cpps_db"
appendFileLine: out_dir$ + "/" + out_prefix$ + "_cpps_golden.csv", "'cpps:6'"

# --- Pre-emphasize (in-place), decimated samples ---
selectObject: sound
preemph = Copy: "preemph"
Pre-emphasize (in-place): 50
nx = Get number of samples
writeFileLine: out_dir$ + "/" + out_prefix$ + "_preemphasis_golden.csv", "sample,value"
si = 1
while si <= nx
    v = Get value at sample number: 1, si
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_preemphasis_golden.csv", "'si','v:8'"
    si = si + 50
endwhile

# --- Scale peak, decimated samples ---
selectObject: sound
scaled = Copy: "scaled"
Scale peak: 0.99
nsx = Get number of samples
writeFileLine: out_dir$ + "/" + out_prefix$ + "_scalepeak_golden.csv", "sample,value"
si = 1
while si <= nsx
    v = Get value at sample number: 1, si
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_scalepeak_golden.csv", "'si','v:8'"
    si = si + 50
endwhile

# --- Resample to 8000 Hz, decimated samples ---
selectObject: sound
resampled = Resample: 8000, 50
nrx = Get number of samples
writeFileLine: out_dir$ + "/" + out_prefix$ + "_resample_golden.csv", "sample,value"
si = 1
while si <= nrx
    v = Get value at sample number: 1, si
    appendFileLine: out_dir$ + "/" + out_prefix$ + "_resample_golden.csv", "'si','v:8'"
    si = si + 25
endwhile

# --- ComplexSpectrogram (validated indirectly via Down to Spectrogram: ---
# --- Praat.app 6.4.47 itself asserts/crashes on "ComplexSpectrogram: To ---
# --- Sound", so amplitude/phase resynthesis cannot be golden-tested. ---
selectObject: sound
cs = To ComplexSpectrogram: 0.005, 5000.0
csspec = Down to Spectrogram
writeFileLine: out_dir$ + "/" + out_prefix$ + "_complexspectrogram_golden.csv", "time,freq,power"
cst1 = 0.3
csf1 = 200
csp1 = Get power at: cst1, csf1
appendFileLine: out_dir$ + "/" + out_prefix$ + "_complexspectrogram_golden.csv", "'cst1:6','csf1:6','csp1:8'"
cst2 = 0.3
csf2 = 500
csp2 = Get power at: cst2, csf2
appendFileLine: out_dir$ + "/" + out_prefix$ + "_complexspectrogram_golden.csv", "'cst2:6','csf2:6','csp2:8'"
cst3 = 0.5
csf3 = 1000
csp3 = Get power at: cst3, csf3
appendFileLine: out_dir$ + "/" + out_prefix$ + "_complexspectrogram_golden.csv", "'cst3:6','csf3:6','csp3:8'"

# --- FormantPath (burg) ---
# parameters "1 1 1 1 1" and candidate 5 match pladdrr's to_formant_path()/
# get_stress_of_candidate() defaults (max_num_formants=5, parameters all 1s).
selectObject: sound
fp = To FormantPath (burg): 0.005, 5, 5500, 0.025, 50, 0.05, 4
fp_oc = Get optimal ceiling: 0, 0, "1 1 1 1 1", 1.25
fp_st = Get stress of candidate: 0, 0, 5, "1 1 1 1 1", 1.25
writeFileLine: out_dir$ + "/" + out_prefix$ + "_formantpath_golden.csv", "optimal_ceiling,stress_candidate5"
appendFileLine: out_dir$ + "/" + out_prefix$ + "_formantpath_golden.csv", "'fp_oc:6','fp_st:8'"

# --- TextGrid (silences), via Intensity ---
selectObject: sound
tgintens = To Intensity: 100, 0, "yes"
tg = To TextGrid (silences): -25.0, 0.1, 0.05, "silent", "sounding"
tgn = Get number of intervals: 1
tglab$ = Get label of interval: 1, 1
tgstart = Get start point: 1, 1
tgend = Get end point: 1, tgn
writeFileLine: out_dir$ + "/" + out_prefix$ + "_textgrid_silences_golden.csv", "n_intervals,label1,start,end"
appendFileLine: out_dir$ + "/" + out_prefix$ + "_textgrid_silences_golden.csv", "'tgn','tglab$','tgstart:6','tgend:6'"

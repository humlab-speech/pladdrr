form Get stereo-to-mono conversion golden values
    text wav_path
    text out_path
endform

Read from file: wav_path$
mono = Convert to mono
n = Get number of samples
writeFileLine: out_path$, "sample,value"
si = 1
while si <= n
    v = Get value at sample number: 1, si
    appendFileLine: out_path$, "'si','v:8'"
    si = si + 20
endwhile

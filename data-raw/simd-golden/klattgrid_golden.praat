form Get KlattGrid synthesis golden values
    text out_path
endform

Create KlattGrid from vowel: "a", 0.3, 125, 800, 80, 1200, 80, 2300, 100, 2800, 0.05, 1000
snd = To Sound
n = Get number of samples
writeFileLine: out_path$, "sample,value"
si = 100
while si <= n
    v = Get value at sample number: 1, si
    appendFileLine: out_path$, "'si','v:8'"
    si = si + 500
endwhile

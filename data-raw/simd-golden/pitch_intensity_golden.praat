form Get pitch and intensity golden values
    text wav_path
    text pitch_out
    text intensity_out
endform

Read from file: wav_path$
sound = selected("Sound")

selectObject: sound
pitch = To Pitch: 0, 75, 600
n = Get number of frames
writeFileLine: pitch_out$, "frame,time,f0_hz"
for i to n
    t = Get time from frame number: i
    f0 = Get value in frame: i, "Hertz"
    appendFileLine: pitch_out$, "'i','t:6','f0:6'"
endfor

selectObject: sound
intensity = To Intensity: 100, 0, "yes"
m = Get number of frames
writeFileLine: intensity_out$, "frame,time,db"
for i to m
    t = Get time from frame number: i
    db = Get value in frame: i
    appendFileLine: intensity_out$, "'i','t:6','db:6'"
endfor

if praatVersion >= 6036
    male_voice$ = "Male1"
    female_voice$ = "Female3"
    synth_language$ = "English (Great Britain)"
else
    male_voice$ = "default"
    female_voice$ = "f3"
    synth_language$ = "English"
endif

male_synth = Create SpeechSynthesizer: synth_language$, male_voice$
To Sound: "text", "yes"
male_sound = selected("Sound")

tmp = selected("TextGrid")
selectObject: tmp
male_label = Extract one tier: 1
Set tier name: 1, "awords"
removeObject: tmp

selectObject: male_sound
duration = Get total duration
overlap = 0.2
shift = duration * overlap
silence = Create Sound from formula: "silence", 1, 0, shift, 44100, "0"

female_synth = Create SpeechSynthesizer: synth_language$, female_voice$
To Sound: "text", "yes"
female_sound = selected("Sound")

tmp = selected("TextGrid")
selectObject: tmp
female_label = Extract one tier: 1
Set tier name: 1, "bwords"
removeObject: tmp

removeObject: male_synth, female_synth

tmp = female_sound
selectObject: silence, female_sound
female_sound = Concatenate
removeObject: tmp

selectObject: female_label
Extend time: shift, "Start"
Shift times by: shift

selectObject: male_label
Extend time: shift, "End"

selectObject: male_sound, female_sound
sound = Combine to stereo
Rename: "test"

selectObject: male_label, female_label
textgrid = Merge
Rename: "test"
Insert interval tier: 3, "amisc"
Insert interval tier: 4, "bmisc"

#removeObject: silence, male_sound, female_sound, male_label, female_label

selectObject: sound, textgrid

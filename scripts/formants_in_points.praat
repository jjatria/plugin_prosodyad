form Formants in points...
  integer Tier 1
  positive Number_of_formants 5
endform

formant = selected("Formant")
textgrid = selected("TextGrid")

selectObject: textgrid

points = !do("Is interval tier...", tier)
if !points
  exitScript: "Tier is not a point tier"
endif
total_points = Get number of points: tier

columns$ = "time "
for i to number_of_formants
  columns$ = columns$ + "F" + string$(i) + " "
endfor
table = Create Table with column names: selected$("TextGrid") + "_formants", 0,
  ... columns$

for point to total_points
  selectObject: textgrid
  time = Get time of point: tier, point

  selectObject: formant
  for f to number_of_formants
    f[f] = Get value at time: f, time, "Hertz", "Linear"
  endfor

  selectObject: table
  Append row
  row = Object_'table'.nrow
  Set numeric value: row, "time", time
  for f to number_of_formants
    Set numeric value: row, "F" + string$(f), f[f]
  endfor
endfor

selectObject: table

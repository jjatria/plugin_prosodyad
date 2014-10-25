# Generate Pitch object using utterance-specific thresholds
# Using Hirst and Delooze's s two-pass method
#
# Modified from https://github.com/jjatria/plugin_jjatools
#
# Author: Jose Joaquin Atria
# Last modified:   October 24, 2014
#
# This script is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.

include ../procedures/check_directory.proc
include ../procedures/pitch_twopass.proc

form To Pitch (two-pass)...
  positive Floor_factor   0.75
  positive Ceiling_factor 1.5 (=use 2.5 for expressive speech)
  comment From De Looze and Hirst (2008) and Hirst (2011)
endform

sounds =  numberOfSelected("Sound")

if !sounds
  exitScript: "No Sound objects selected"
endif

# Save selection
for i to sounds
  sound[i] = selected("Sound", i)
endfor

# Iterate through sounds
for i to sounds
  selectObject: sound[i]
  @pitchTwoPass(floor_factor, ceiling_factor)
  pitch[i] = selected("Pitch")
endfor

# Select newly created objects
nocheck selectObject: undefined
for i to sounds
  plusObject: pitch[i]
endfor

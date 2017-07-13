# This script is part of the ProsoDyad plugin for Praat.
# The latest version is available at
# <http://github.com/jjatria/plugin_prosodyad>
#
# The prosodyad plugin is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# The prosodyad plugin is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with utils. If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2014-2017 Peter Pressman, José Joaquín Atria

form Pressman Analysis
  comment  Leave paths empty for GUI selection
  sentence Sound_directory
  sentence TextGrid_directory
  positive Max_formant_(Hz)                       5500 (= adult male)
  boolean  Save_speaker_objects                   0
  sentence Save_objects_to
  comment  Two-pass pitch Detection (Hirst 2011)
  positive Floor_factor                           0.75
  positive Ceiling_factor                         1.5 (= 2.5 for expressive speech)
  comment  Automatic Syllable Detection
  real     Silence_threshold_(dB)                -25
  real     Minimum_dip_between_peaks_(dB)         1.5 (= up to 4 for clean and filtered)
  real     Minimum_pause_duration_(s)             0.1
  comment  Analysis resolution (windowing options)
  real     Window_overlap 0 (= 0 for no overlap; 0.5 for 50% overlap)
  real     Window_duration_(s) 0 (= entire segment)
endform

include ../../plugin_utils/procedures/check_directory.proc

snd_extension$ = "wav"
tgd_extension$ = "TextGrid"

# Main suffix for generated files
suffix$ = "_pressman"

@checkDirectory(sound_directory$, "Read sounds form...")
sound_directory$ = checkDirectory.name$

@checkDirectory(textGrid_directory$, "Read annotations form...")
textgrid_directory$ = checkDirectory.name$

if save_speaker_objects
  @checkDirectory(output_directory$, "Save objects to...")
  output_directory$ = checkDirectory.name$
endif

sounds = Create Strings as file list: "sounds",
  ... sound_directory$ + "*" + snd_extension$
total_sounds = Get number of strings

textgrids = Create Strings as file list: "textgrids",
  ... sound_directory$ + "*" + tgd_extension$
total_textgrids = Get number of strings

if total_sounds != total_textgrids
  exitScript: "Not the same number of Sound and TextGrid objects"
endif

for i to total_sounds
  selectObject: sounds
  sound_name$ = Get string: i
  sound = Read from file: sound_directory$ + sound_name$

  selectObject: textgrids
  textgrid_name$ = Get string: i
  textgrid = Read from file: textgrid_directory$ + textgrid_name$

  selectObject: sound, textgrid

  runScript: "main_analysis.praat",
    ... max_formant,
    ... floor_factor,
    ... ceiling_factor,
    ... silence_threshold,
    ... minimum_dip_between_peaks,
    ... minimum_pause_duration,
    ... window_overlap,
    ... window_duration

  table[i]    = selected("Table")
  sound[i]    = selected("Sound")
  textgrid[i] = selected("TextGrid")

  if save_speaker_objects
    selectObject: sound[i]
    Save as WAV file: output_directory$ +
      ... selected$("Sound") + ".wav"

    selectObject: textgrid[i]
    Save as short text file: output_directory$ +
      ... selected$("TextGrid") + ".TextGrid"
  endif

  # If you want to keep the speaker objects in the Object list,
  # comment the following line. Beware that a large number of large files
  # can quickly use too much memory, rendering the system unstable.
  removeObject: sound[i], textgrid[i]

  removeObject: sound, textgrid
endfor

removeObject: sounds,textgrids

for i to total_sounds
  plusObject: table[i]
endfor
table = Append
Rename: "pressman_analysis"
for i to total_sounds
  removeObject: table[i]
endfor

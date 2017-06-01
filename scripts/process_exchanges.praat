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
# Copyright 2016-2017 Peter Pressman, José Joaquín Atria

form Turn-taking analysis...
  positive Turn_taking_threshold_(ms) 0.01
  comment  Acoustic analysis parameters
  positive Max_formant_(Hz)                5500 (= adult male)
  comment  Two-pass pitch detection (Hirst 2011)
  positive Floor_factor                    0.75
  positive Ceiling_factor                  1.5 (= 2.5 for expressive speech)
  comment  Automatic syllable detection
  real     Silence_threshold_(dB)         -25
  real     Minimum_dip_between_peaks_(dB)  1.5 (= up to 4 for clean and filtered)
  real     Minimum_pause_duration_(s)      0.1
endform

sound = selected("Sound")
textgrid = selected("TextGrid")

selectObject: textgrid
runScript: "find_exchanges.praat"

selectObject: sound, textgrid

selectObject: sound
runScript: "syllable_nuclei.praat",
  ... 1, global.silence_threshold, global.min_dip, global.min_pause,
  ... tier.min_pitch, global.min_spread
tier.syllables = selected("TextGrid")
removeObject: selected("Table")

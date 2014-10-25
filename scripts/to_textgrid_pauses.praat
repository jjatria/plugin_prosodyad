# Extends automatic detection of silences with additional parameters for
# separating between simple silences and speech pauses
#
# Author: Jose Joaquin Atria
# Version: 0.9.1
# Last modified:   October 24, 2014
#
# This script is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.

form To TextGrid (pauses)...
  positive Minimum_pitch_(Hz)      60
  real     Silence_threshold_(dB) -25
  real     Minimum_pause_(s)       0.1
  real     Initial_margin_(s)      0.25
  real     Final_margin_(s)        0.25
endform

include ../procedures/to_textgrid_pauses.proc

@textgridPauses(minimum_pitch,
  ... silence_threshold,
  ... minimum_pause,
  ... initial_margin,
  ... final_margin)

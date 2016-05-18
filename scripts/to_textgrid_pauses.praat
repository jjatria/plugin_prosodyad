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
# Copyright 2014-2016 Peter Pressman, José Joaquín Atria

#! ~~~ params
#! in:
#!   Minimum pitch: >
#!     (positive) Minimum pitch of Sound, in Hertz
#!   Silence threshold: >
#!     (real) Threshold for silence detection (as dB below the peak)
#!   Minimum pause: >
#!     (real) Minimum length of silence/pause, in seconds
#!   Initial margin: >
#!     (real) Initial margin in voiced intervals. Pauses must start after this.
#!   Final margin: >
#!     (real) Final margin in voiced intervals. Pauses must end before this.
#! selection:
#!   in:
#!     sound: 1
#!   out:
#!     textgrid: 1
#! ~~~
#!
#! Extends automatic detection of silences with additional parameters for
#! separating between simple silences and speech pauses.
#!
#! Run on a single sound. Result is a TextGrid similar to that obtained from
#! To TextGrid (silences), but with a further discrimination between pauses and
#! silences.
#!
form To TextGrid (pauses)...
  positive Minimum_pitch_(Hz)      60
  real     Silence_threshold_(dB) -25
  real     Minimum_pause_(s)       0.1
  real     Initial_margin_(s)      0.25
  real     Final_margin_(s)        0.25
endform

include ../procedures/to_textgrid_pauses.proc

@textgridPauses:
  ... minimum_pitch,
  ... silence_threshold,
  ... minimum_pause,
  ... initial_margin,
  ... final_margin

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
# Copyright 2016 Peter Pressman, José Joaquín Atria

include ../../plugin_utils/procedures/utils.proc

# As returned by tgutils@toNonOverlappingIntervals
original = selected("TextGrid")
if do("Get number of tiers") != 1
  exitScript: "Input TextGrid has more than one tier"
endif
overlap_tier = 1

# Make sure no two contiguous intervals have the same labels
runScript: preferencesDirectory$ + "/plugin_tgutils/scripts/" +
  ... "merge_contiguous_labels.praat", overlap_tier

exchanges = selected("TextGrid")
Rename: selected$("TextGrid") - "_merged" + "_exchanges"
Insert point tier: 2, "exchanges"
exchange_tier = 2

total_intervals = Get number of intervals: overlap_tier

undefined$ = string$(undefined)

for current from 2 to total_intervals - 1
  previous  = current - 1
  next      = current + 1

  previous$ = undefined$
  current$  = undefined$
  next$     = undefined$

  previous$ = Get label of interval: overlap_tier, previous
  current$  = Get label of interval: overlap_tier, current
  next$     = Get label of interval: overlap_tier, next

  start     = Get start point: overlap_tier, current
  end       = Get end point:   overlap_tier, current

  duration  = end - start
  midpoint  = duration / 2 + start

  # Only process when current is between speakers' turns
  if !(previous$ == "" or previous$ == "0")

    if previous$ == next$
      # Interruption in the turn of a single speaker
      if current$ == ""
        # Pause within speaker
        Remove right boundary: overlap_tier, current
        Remove left boundary:  overlap_tier, current
        Set interval text:     overlap_tier, previous, previous$

        total_intervals -= 2
        current -= 1
      elsif current$ == "0"
        # Within-speaker overlap. Do nothing
      else
        # Perfect turn taking
        nocheck Insert point: exchange_tier, do("Get start point...", overlap_tier, current), "0"
        nocheck Insert point: exchange_tier, do("Get end point...",   overlap_tier, current), "0"
      endif
    else
      if current$ == ""
        # Gap between speakers
        nocheck Insert point: exchange_tier, midpoint, string$(duration)
      elsif current$ == "0"
        # Between-speaker overlap
        nocheck Insert point: exchange_tier, midpoint, string$(duration * -1)
      else
        # Perfect turn taking
        nocheck Insert point: exchange_tier, do("Get start point...", overlap_tier, current), "0"
      endif
    endif
  endif
endfor

selectObject: exchanges

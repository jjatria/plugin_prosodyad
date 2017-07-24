# Creates a Strings object which contains a subset of the strings
# of an original Strings object. Matching of strings is done through
# a regular expression.
#
# This script is part of the strutils CPrAN plugin for Praat.
# The latest version is available through CPrAN or at
# <http://cpran.net/plugins/strutils>
#
# The strutils plugin is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# The strutils plugin is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with strutils. If not, see <http://www.gnu.org/licenses/>.
#
# Copyright 2017 Jose Joaquin Atria

form Remove extraneous breaks...
  sentence Tier_pattern ^[AaBb]_?words$
endform

textgrid = selected("TextGrid")

total_tiers = Get number of tiers
matched = 0
for tier to total_tiers
  tier$ = Get tier name: tier
  if index_regex(tier$, tier_pattern$)
    tier[matched] = tier
    matched += 1
  endif
endfor

if matched == 2
  for i from 0 to matched-1
    tier       = tier[i]
    other_tier = tier[1-i]

    total_intervals = Get number of intervals: tier
    for j from 0 to total_intervals-1
      interval = total_intervals - j

      start = Get starting point: tier, interval
      end   = Get end point:      tier, interval

      previous = Get low interval at time:  tier, start
      next     = Get high interval at time: tier, end

      interval$ = Get label of interval: tier, interval
      previous$ = if previous then
        ... do$("Get label of interval...", tier, previous)
        ... else "" fi
      next$ = if next then
        ... do$("Get label of interval...", tier, next    )
        ... else "" fi

      if interval$ == "" and previous$ != "" and next$ != ""

        start_interval = Get high interval at time: other_tier, start
        end_interval   = Get low interval at time:  other_tier, end
        other_label$   = if start_interval == end_interval then
          ... do$("Get label of interval...",
            ... other_tier, start_interval) else "" fi

        if start_interval == end_interval and other_label$ == ""
          Remove right boundary: tier, interval
          Remove left boundary:  tier, interval
        endif

      endif
    endfor
  endfor
else
  appendInfoLine: "# Not enough tiers matched. Check pattern"
endif

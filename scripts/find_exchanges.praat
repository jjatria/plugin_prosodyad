include ../../plugin_utils/procedures/utils.proc
@normalPrefDir()

# As returned by tgutils@toNonOverlappingIntervals
original = selected("TextGrid")
if do("Get number of tiers") != 1
  exitScript: "Input TextGrid has more than one tier"
endif
overlap_tier = 1

# Make sure no two contiguous intervals have the same labels
runScript: preferencesDirectory$ + "plugin_tgutils/scripts/" +
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

  start    = Get start point: overlap_tier, current
  end      = Get end point:   overlap_tier, current
  duration = end - start
  midpoint = duration / 2 + start

  if previous$ - "0" != ""
    # Only process when current is between speakers' turns

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
        Insert point: exchange_tier, do("Get start point...", overlap_tier, current), "0"
        Insert point: exchange_tier, do("Get end point...",   overlap_tier, current), "0"
      endif
    else
      if current$ == ""
        # Gap between speakers
        Insert point: exchange_tier, midpoint, string$(duration)
      elsif current$ == "0"
        # Between-speaker overlap
        Insert point: exchange_tier, midpoint, string$(duration * -1)
      else
        exitScript: "Impossible case at interval ", current
      endif
    endif
  endif
endfor

selectObject: exchanges

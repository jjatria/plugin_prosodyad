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
# Copyright 2016 Peter Pressman, Jose Joaquin Atria

# Optional tracing, provided by the utils plugin
include ../../plugin_utils/procedures/trace.proc
trace.enable  = 0    ; Enable or disable tracing. Increase for tracing
trace.output$ = ""   ; Send trace messages to Info window (or file if filename)

include ../../plugin_tgutils/procedures/extract_tiers_by_name.proc
tgutils$ = preferencesDirectory$ + "/plugin_tgutils/scripts/"

#! ~~~ params
#! in:
#!   Turn taking threshold: >
#!     (positive) Maximum duration of a "perfect" turn exchange
#!   Tier regex: >
#!     (sentence) A regular expression pattern to identify relevant tiers
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
#!     textgrid: 1
#!   out:
#!     table: 2
#! ~~~
#!
#! Detect and label exchages and interruptions for an annotated dialogue.
#!
#! The script takes a Sound and a TextGrid objects. The annotation is expected
#! to have multiple (at least two) interval tiers whose names match the regular
#! expression provided, each of them with the speech of a different speaker.
#! Intervals with labels will be considered to be speech, intervals with no
#! labels are ignored.
#!
#! The script will produce two Table objects, one for exchanges, and one for
#! interruptions.
#!
#! Exchanges in the table will be coded as a continuous time variable, whose
#! value will be negative if the exchange was an overlap between the speakers,
#! or positive if the exchange was a gap between them. When the magnitude of
#! the value is lower than the specified threshold, it will be categorised as a
#! "perfect" exchange.
#!
#! Interruptions in the table will be of two types: pauses, when the turn of a
#! single speaker has a recognisable gap; and overlaps, when the turn of a
#! single speaker is interrupted by speech from a different one.
#!
#! Pauses are detected based on the definition by Rusz et al. (2013), only
#! occurring after the "initial margin" and before the "final margin",
#! specified in the script parameters; and never lasting less than the
#! specified minimum pause. The rest of the parameters are passed to the
#! internal `TextGrid (to silences)...` Praat command.
#!
form Turn-taking analysis...
  positive Turn_taking_threshold_(s) 0.01
  sentence Tier_regex                 ^[ab]words$
  comment Pause detection parameters
  positive Minimum_pitch_(Hz)         60
  real     Silence_threshold_(dB)    -25
  real     Minimum_pause_(s)          0.1
  real     Initial_margin_(s)         0.25
  real     Final_margin_(s)           0.25
endform

if    numberOfSelected()           != 2 or
  ... numberOfSelected("Sound")    != 1 or
  ... numberOfSelected("TextGrid") != 1

  exitScript: "Selection must be a Sound and a TextGrid object"
endif

# Register original selection
sound    = selected("Sound")
name$    = selected$("Sound")
textgrid = selected("TextGrid")

@trace: "Processing " + name$

# Extract only valid tiers, matching the provided regular expression
selectObject: textgrid
@extractTiersByName: tier_regex$, 0
if extractTiersByName.return
  valid_tiers = extractTiersByName.return
  Rename: "valid_tiers"
else
  selectObject: sound, textgrid
  exitScript: "TextGrid does not have any valid tiers"
endif

# Detect speaker overlaps
runScript: tgutils$ + "to_non-overlapping_intervals.praat"
overlap_tier = selected("TextGrid")

# Detect raw speaker exchanges
runScript: "find_exchanges.praat"
removeObject: overlap_tier
exchange_tier = selected("TextGrid")

# Index speaker interventions
# Each row in the resulting Table object will correspond to the intervention
# of a single speaker. This same table will be modified to become the exchanges
# table.
runScript: tgutils$ + "index_specified_labels.praat",
  ... 1, "[1-9]", "yes"
exchanges = selected("Table")
Rename: name$ + "_exchanges"
Set column label (label): "label", "speaker"
Insert column: Object_'exchanges'.ncol + 1, "exchange"
Insert column: Object_'exchanges'.ncol + 1, "type"

@trace: "  Preliminary interval check"
@preliminaryCheck: 6.4 / minimum_pitch
if preliminaryCheck.n
  @trace: "    " +
    ... "Removed " + string$(preliminaryCheck.n) + " " +
    ... "exchanges too short for intensity analysis"
endif

@trace: "  Processing " + string$(Object_'exchanges'.nrow) + " exchanges"

# For each intervention, tabulate pauses and exchanges. Overlaps (the other
# type of interruptions) are detected later, to prevent counting
# between-speaker overlaps as interruptions.
for i to Object_'exchanges'.nrow
  speaker$ = Object_'exchanges'$[i, "speaker"]
  start    = Object_'exchanges'[i, "start"]
  end      = Object_'exchanges'[i, "end"]

  @trace: "    [" + string$(i) + "] (" + fixed$(start, 3) + " - " + fixed$(end, 3) + ")"

  selectObject: sound
  @tabulatePauses: speaker$, start, end

  # Merge existing tables into a single exchanges table
  if !variableExists("interruptions")
    interruptions = selected("Table")
  else
    t1 = interruptions
    t2 = selected("Table")
    selectObject: t1, t2

    interruptions = Append
    Rename: name$ + "_interruptions"
    removeObject: t1, t2
  endif

  selectObject: exchange_tier, exchanges
  @tabulateExchanges: i
endfor

# By this point, all remaining overlaps in the overlap TextGrid correspond to
# within-speaker overlaps (= interruptions).
for i to Object_'exchanges'.nrow
  speaker$ = Object_'exchanges'$[i, "speaker"]
  start    = Object_'exchanges'[i, "start"]
  end      = Object_'exchanges'[i, "end"]

  selectObject: exchange_tier, interruptions
  @tabulateOverlaps: speaker$, start, end
endfor

# Finish clean up and prepare final selection
selectObject: exchanges
Remove column: "index"
removeObject: exchange_tier, valid_tiers
selectObject: interruptions
Sort rows: "turn_start start"

selectObject: interruptions, exchanges

#
# Procedures
#

#! ~~~ params
#! in:
#!   .speaker$: The current speaker
#!   .start: The start timestamp for the current turn
#!   .end: The end timestamp for the current turn
#! selection:
#!   in:
#!     sound: 1
#!   out:
#!     table: 1
#! ~~~
#!
#! Automatically detect pauses based on the script parameters
#!
procedure tabulatePauses: .speaker$, .start, .end
  .sound = selected("Sound")
  .turn = Extract part: .start, .end, "rectangular", 1, "yes"

  runScript: "to_textgrid_pauses.praat",
    ... minimum_pitch,
    ... silence_threshold,
    ... minimum_pause,
    ... initial_margin,
    ... final_margin
  .pause_tier = selected("TextGrid")

  runScript: tgutils$ + "index_specified_labels.praat",
    ... 1, "^pause$", "yes"
  .pauses = selected("Table")

  removeObject: .turn, .pause_tier

  Insert column: 1, "speaker"
  Insert column: 2, "turn_start"
  Insert column: 3, "turn_end"
  Remove column: "label"
  Remove column: "index"
  Insert column: Object_'.pauses'.ncol + 1, "type"

  for .i to Object_'.pauses'.nrow
    Set string value:  .i, "speaker",    .speaker$
    Set numeric value: .i, "turn_start", .start
    Set numeric value: .i, "turn_end",   .end
    Set string value:  .i, "type",       "pause"
  endfor
endproc

#! ~~~ params
#! in:
#!   .i: The index for the current turn
#! selection:
#!   in:
#!     textgrid: 1
#!     table: 1
#! ~~~
#!
#! Process the exchanges TextGrid (as returned by `find_exchanges.praat`) and
#! the current exchanges table (produced by this very script) to include and
#! label exchanges.
#!
procedure tabulateExchanges: .i
  .textgrid = selected("TextGrid")
  .table    = selected("Table")
  .start    = Object_'.table'[.i, "start"]
  .end      = Object_'.table'[.i, "end"]

  selectObject: .textgrid
  .index  = nocheck Get high index from time:  2, .end
  .time   = nocheck Get time of point:        2, .index
  .label$ = nocheck Get label of point:       2, .index
  .parent = nocheck Get low interval at time:
    ... 1, .time - abs(number(.label$) / 2)

  trace.level -= 1
  @trace: "      index: " + fixed$(.index, 0)
  @trace: "      time: " + fixed$(.time, 2)
  @trace: "      label: " + fixed$(number(.label$), 2)
  @trace: "      parent: " + fixed$(.parent, 0)
  trace.level += 1

  if .time != undefined
    selectObject: .table
    Set string value: .i, "exchange", .label$

    .duration = number(.label$)
    if abs(.duration) < turn_taking_threshold
      Set string value: .i, "type", "perfect"
    elsif .duration > 0
      Set string value: .i, "type", "gap"
    else
      Set string value: .i, "type", "overlap"
    endif

    # Remove label of read exchanges, so we can easily identify
    # within-speaker overlaps
    selectObject: .textgrid
    .interval = Get interval at time: 1, .time
    Set interval text: 1, .interval, ""
  endif

  selectObject: .textgrid, .table
endproc

#! ~~~ params
#! in:
#!   .speaker$: The current speaker
#!   .start: The start timestamp for the current turn
#!   .end: The end timestamp for the current turn
#! selection:
#!   in:
#!     textgrid: 1
#!     table: 1
#! ~~~
#!
#! Process the exchanges TextGrid (as returned by `find_exchanges.praat`) and
#! the current interruptions table (produced by this very script) to include
#! and label within-speaker overlaps.
#!
procedure tabulateOverlaps: .speaker$, .start, .end
  .textgrid = selected("TextGrid")
  .table    = selected("Table")

  selectObject: .textgrid
  runScript: tgutils$ + "index_specified_labels.praat",
    ... 1, "^0$", "yes"
  .overlaps = selected("Table")

  for .i to Object_'.overlaps'.nrow
    selectObject: .table
    Append row
    .r = Object_'.table'.nrow
    Set string value:  .r, "speaker",    .speaker$
    Set numeric value: .r, "turn_start", .start
    Set numeric value: .r, "turn_end",   .end
    Set numeric value: .r, "start",      Object_'.overlaps'[.i, "start"]
    Set numeric value: .r, "end",        Object_'.overlaps'[.i, "end"]
    Set string value:  .r, "type",       "overlap"
  endfor

  removeObject: .overlaps
  selectObject: .textgrid, .table
endproc

#! ~~~ params
#! in:
#!   .min: The minimum duration for an intervention
#! selection:
#!   in:
#!     table: 1
#! ~~~
#!
#! Process the exchanges Table (as derived from the exchanges TextGrid) to
#! disregard interventions shorter than a minimum length. This is used to
#! remove interventions shorter than `6.4 / min_pitch`, which is the shortest
#! interval for which intensity analysis is possible.
#!
procedure preliminaryCheck: .min
  .table = selected("Table")
  .n = 0
  for .i to Object_'.table'.nrow
    .speaker$ = Object_'.table'$[.i, "speaker"]
    .start    = Object_'.table'[.i, "start"]
    .end      = Object_'.table'[.i, "end"]

    if .end - .start < .min
      Remove row: .i
      .n += 1
    endif
  endfor
endproc

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

form ProsoDyad Analysis...
  positive Max_formant_(Hz)                5500 (= adult male)
  comment  Two-pass pitch detection (Hirst 2011)
  positive Floor_factor                    0.75
  positive Ceiling_factor                  1.5 (= 2.5 for expressive speech)
  comment  Automatic syllable detection
  real     Silence_threshold_(dB)         -25
  real     Minimum_dip_between_peaks_(dB)  1.5 (= up to 4 for clean and filtered)
  real     Minimum_pause_duration_(s)      0.1
endform

include ../../plugin_utils/procedures/trace.proc
include ../../plugin_tgutils/procedures/extract_tiers_by_name.proc

trace.enable = 1
trace.output$ = ""

tgutils$ = preferencesDirectory$ + "/plugin_tgutils/scripts/"
twopass$ = preferencesDirectory$ + "/plugin_twopass/scripts/"

# Main suffix for generated files
suffix$ = "_pressman"

# Pause thresholds
# A margin is placed at the beginning and end of every interval labeled as
# "voiced", and pauses are only detected within these margins. If a pause begins
# too close to the beginning of a voiced interval, or ends too close to its end,
# then that pause is discarded.
# Initial values of 250ms for both margins were taken from
# Rusz et al. (2013) "Objective acoustic [...]", PloS one 8(6): e65881
before_pause = 0.25
after_pause  = 0.25

# Shortened variable names
min_dip   = minimum_dip_between_peaks
min_pause = minimum_pause_duration

# Minimum spread for detected syllables
# Further coding is needed to properly implement this
# Specifically: what should be done with syllable nuclei that are closer?
# cf. syllable_nuclei.praat
min_spread = 0

# Original selection
sound    = selected("Sound")
name$    = selected$("Sound")
textgrid = selected("TextGrid")

@trace: "Processing " + name$

# Make sure all tiers have same length
selectObject: textgrid
# @equaliseTierDurations()
@extractTiersByName: "^silences$", 1
if extractTiersByName.return
  silence_tier = extractTiersByName.return
  # Do we need it?
  Remove
endif

# Detect segments with individual non-overlapping speakers
selectObject: textgrid
@extractTiersByName: "^[ab]words$", 0
if extractTiersByName.return
  speaker_tiers = extractTiersByName.return
  Rename: "speaker_tiers"
  @trace: "  Speaker tiers: " + string$(selected()) + ". " + selected$()
endif

runScript: tgutils$ + "to_non-overlapping_intervals.praat"
overlap_tier = selected("TextGrid")
@trace: "  Overlap tier: " + string$(selected()) + ". " + selected$()

selectObject: overlap_tier
flattened_intervals = Get number of intervals: 1

##
## Begin main tier loop
##

# Loop over each tier in original TextGrid
selectObject: speaker_tiers
total_tiers = Get number of tiers
@trace: "  Processing " + string$(total_tiers) + " tiers"

for i to total_tiers
  selectObject: speaker_tiers
  speaker$ = Get tier name: i
  if speaker$ = ""
    speaker$ = string$(i)
  endif

  # For this tier we work on a copy of the original Sound
  selectObject: sound
  speaker_sound = Convert to mono
  Rename: name$ + "_" + speaker$

  # Run analysis for this speaker, using this iteration's mono copy
  # The analysis is run only if there are non-overlapping intervals.
  selectObject: overlap_tier
  single_speaker_intervals = Count labels: 1, string$(i)

  if single_speaker_intervals
    selectObject: speaker_sound, overlap_tier
    @trace: "  Working on tier " + string$(i) + "..."
    @processSpeakerTier(i)
  else
    @trace: "  No speaker intervals in tier " + string$(i)
    removeObject: speaker_sound
  endif

  @trace: "  Done with tier " + string$(i)
endfor

removeObject: speaker_tiers, overlap_tier
selectObject: output_table
Rename: name$ + suffix$
Sort rows: "start"

# ##
# ## End main tier loop
# ##

##
## Procedures
##

#
# Process individual speaker
# Each tier is expected to hold (speech or non-speech) data for one single
# speaker. All analysis is performed in this procedure, once per tier.
#
procedure processSpeakerTier (.tier)
  .sound = selected("Sound")
  .overlaps = selected("TextGrid")

  selectObject: .overlaps
  .overlap_intervals = Get number of intervals: 1

  # Silence all intervals during which speaker is not speaking on their own.
  .n = 0
  for .i to .overlap_intervals
    selectObject: .overlaps
    .label$ = Get label of interval: 1, .i

    if .label$ != string$(.tier)
      .start = Get start point: 1, .i
      .end   = Get end point:   1, .i

      selectObject: .sound
      Formula (part): .start, .end, 1, 1, "0"
    else
      .n += 1
    endif
  endfor
  @trace: "    Working on " + string$(.n) + " intervals for current speaker"

  # Pitch detection, based on this silenced copy with a single speaker
  selectObject: .sound
  runScript: twopass$ + "to_pitch_two-pass.praat",
    ... floor_factor, ceiling_factor
  .pitch = selected("Pitch")
  .min_pitch = Get minimum: 0, 0, "Hertz", "Parabolic"
  .max_pitch = Get maximum: 0, 0, "Hertz", "Parabolic"

  # Syllable detection, for only this speaker
  selectObject: .sound
  runScript: "syllable_nuclei.praat",
    ... 1, silence_threshold, min_dip, min_pause,
    ... .min_pitch, min_spread
  .syllables = selected("TextGrid")
  removeObject: selected("Table")

  selectObject: .syllables
  Set tier name: 1, "syllables"

  selectObject: .overlaps
  runScript: "find_exchanges.praat"
  .exchanges = selected("TextGrid")

  selectObject: .syllables, .exchanges
  .textgrid = Merge
  Rename: "overlaps_and_exchanges"
  removeObject: .syllables, .exchanges

  # Create main analysis objects for this speaker's entire sound
  # These are to be re-used in later stages of analysis
  selectObject: .sound, .pitch
  .point_process = To PointProcess (cc)

  selectObject: .sound
  .intensity = To Intensity: .min_pitch, 0, "yes"

  selectObject: .sound
  .formant = To Formant (burg): 0, 5, max_formant, 0.025, 50

  .n = 0
  for .i to .overlap_intervals
    selectObject: .overlaps
    .label$ = Get label of interval: 1, .i

    if .label$ == string$(.tier)
      .n += 1
      @trace: "    Processing interval " + string$(.n) + "..."

      .start = Get start point: 1, .i
      .end   = Get end point:   1, .i

      selectObject: .pitch, .sound, .textgrid,
        ... .point_process, .formant, .intensity

      runScript: "utterance_analysis.praat", .start, .end, max_formant,
        ... floor_factor, ceiling_factor

      Set string value: 1, "conversation", name$
      Set string value: 1, "speaker",      speaker$
      if !variableExists("output_table")
        output_table = selected("Table")
      else
        t1 = output_table
        t2 = selected("Table")
        selectObject: t1, t2
        output_table = Append
        removeObject: t1, t2
      endif
    endif
  endfor

  removeObject: .pitch, .sound, .textgrid,
    ... .point_process, .formant, .intensity

endproc

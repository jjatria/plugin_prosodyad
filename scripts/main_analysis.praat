# Voice analysis
#
# Design:  Peter Pressman, Jose Joaquin Atria
# Coding:  Jose Joaquin Atria
#
# Version: 0.9.2
# Initial release: October 21, 2014
# Last modified:   December 8, 2014
#
# This script is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.

form Pressman Analysis...
  positive Max_formant_(Hz)                5500 (= adult male)
  comment  Two-pass pitch Detection (Hirst 2011)
  positive Floor_factor                    0.75
  positive Ceiling_factor                  1.5 (= 2.5 for expressive speech)
  comment  Automatic Syllable Detection
  real     Silence_threshold_(dB)         -25
  real     Minimum_dip_between_peaks_(dB)  1.5 (= up to 4 for clean and filtered)
  real     Minimum_pause_duration_(s)      0.1
endform

include ../../plugin_tgutils/procedures/count_points_in_range.proc
tgutils$ = preferencesDirectory$ + "/plugin_tgutils/scripts/"
twopass$ = preferencesDirectory$ + "/plugin_twopass/scripts/"

# Main suffix for generated files
global.suffix$ = "_pressman"

# Pause thresholds
# A margin is placed at the beginning and end of every interval labeled as
# "voiced", and pauses are only detected within these margins. If a pause begins
# too close to the beginning of a voiced interval, or ends too close to its end,
# then that pause is discarded.
# Initial values of 250ms for both margins were taken from
# Rusz et al. (2013) "Objective acoustic [...]", PloS one 8(6): e65881
global.before_pause = 0.25
global.after_pause  = 0.25

# Shortened variable names
global.min_dip           = minimum_dip_between_peaks
global.min_pause         = minimum_pause_duration
global.ceiling_factor    = ceiling_factor
global.floor_factor      = floor_factor
global.silence_threshold = silence_threshold
global.max_formant       = max_formant

# Minimum spread for detected syllables
# Further coding is needed to properly implement this
# Specifically: what should be done with syllable nuclei that are closer?
# cf. syllable_nuclei.praat
global.min_spread = 0

# Original selection
global.sound    = selected("Sound")
global.name$    = selected$("Sound")
global.textgrid = selected("TextGrid")

# Make sure all tiers have same length
selectObject: global.textgrid
@equaliseTierDurations()

# Detect segments with individual non-overlapping speakers
selectObject: global.textgrid
runScript: tgutils$ + "to_non-overlapping_intervals.praat"
global.overlap = selected("TextGrid")

selectObject: global.overlap
global.flat_intervals = Get number of intervals: 1

@createOutputTable()
final.table = selected("Table")

##
## Begin main tier loop
##

# Loop over each tier in original TextGrid
selectObject: global.textgrid
global.tiers = Get number of tiers
for tier to global.tiers
  selectObject: global.textgrid
  tier.speaker$ = Get tier name: tier
  if tier.speaker$ = ""
    tier.speaker$ = string$(tier)
  endif

  # For this tier we work on a copy of the original Sound
  selectObject: global.sound
  tier.sound = Convert to mono
  Rename: global.name$ + "_" + tier.speaker$

  # Run analysis for this speaker, using this iteration's mono copy
  # The analysis is run only if there are non-overlapping intervals.
  selectObject: global.overlap
  single_speaker_intervals = Count labels: 1, string$(tier)
  if single_speaker_intervals
    @processSpeakerTier(tier)
  else
    removeObject: tier.sound
  endif
endfor

##
## End main tier loop
##

nocheck selectObject: undefined
for tier to global.tiers
  nocheck plusObject: sound[tier]
endfor
final.sound = Combine to stereo
Rename: global.name$ + global.suffix$

selectObject: global.overlap
for tier to global.tiers
  nocheck plusObject: textgrid[tier]
endfor
final.textgrid = Merge
Rename: global.name$ + global.suffix$

removeObject: global.overlap
for tier to global.tiers
  nocheck removeObject: sound[tier]
  nocheck removeObject: textgrid[tier]
endfor

# Select created objects
selectObject: final.table, final.sound, final.textgrid

##
## Procedures
##

#
# Process individual speaker
# Each tier is expected to hold (speech or non-speech) data for one single
# speaker. All analysis is performed in this procedure, once per tier.
#
procedure processSpeakerTier (.tier)
  # Silence all intervals during which speaker is not speaking on their own.
  selectObject: tier.sound
  for .i to global.flat_intervals
    selectObject: global.overlap
    .label$ = Get label of interval: 1, .i

    if .label$ != string$(.tier)
      .start = Get start point: 1, .i
      .end   = Get end point:   1, .i

      selectObject: tier.sound
      Formula (part): .start, .end, 1, 1, "0"
    endif
  endfor

  # Pitch detection, based on this silenced copy with a single speaker
  selectObject: tier.sound
  runScript: twopass$ + "to_pitch_two-pass.praat",
    ... global.floor_factor, global.ceiling_factor
  tier.pitch = selected("Pitch")
  tier.min_pitch = Get minimum: 0, 0, "Hertz", "Parabolic"
  tier.max_pitch = Get maximum: 0, 0, "Hertz", "Parabolic"

  # Syllable detection, for only this speaker
  selectObject: tier.sound
  runScript: "syllable_nuclei.praat",
    ... 1, global.silence_threshold, global.min_dip, global.min_pause,
    ... tier.min_pitch, global.min_spread
  tier.syllables = selected("TextGrid")
  removeObject: selected("Table")

  selectObject: tier.syllables
  Set tier name: 1, tier.speaker$

  # Create main analysis objects for this speaker's entire sound
  # These are to be re-used in later stages of analysis
  selectObject: tier.sound, tier.pitch
  tier.point_process = To PointProcess (cc)

  selectObject: tier.sound
  tier.intensity = To Intensity: tier.min_pitch, 0, "yes"

  selectObject: tier.sound
  tier.formant = To Formant (burg): 0, 5, global.max_formant, 0.025, 50

  for .i to global.flat_intervals
    selectObject: global.overlap
    interval.label$ = Get label of interval: 1, .i

    if interval.label$ = string$(.tier)
      interval.start = Get start point: 1, .i
      interval.end   = Get end point:   1, .i
      selectObject:
        ... tier.pitch,
        ... tier.sound,
        ... tier.syllables,
        ... tier.point_process,
        ... tier.formant,
        ... tier.intensity
      @processInterval(interval.start, interval.end)
    endif
  endfor

  # After processing each interval, get measurements for entire tier
  selectObject: tier.sound
  tier.start = Object_'tier.sound'.xmin
  tier.end   = Object_'tier.sound'.xmax

  # This requires recalculation of the intensity object, discarding all silent
  # parts in the tier copy of the original sound.
  selectObject: tier.sound
  .textgrid = To TextGrid (silences): tier.min_pitch, 0,
    ... global.silence_threshold, 0.1, 0.01, "uv", "v"
  plusObject: tier.sound
  Extract intervals where: 1, 0, "is equal to", "v"
  @mergeSounds()
  plusObject: mergeSounds.id
  .intensity = To Intensity: tier.min_pitch, 0, "yes"
  removeObject: .textgrid, mergeSounds.id

  selectObject:
    ... tier.pitch,
    ... tier.sound,
    ... tier.syllables,
    ... tier.point_process,
    ... tier.formant,
    ... .intensity
  @processInterval(tier.start, tier.end)

  # Clean up workspace
  @tierCleanUp()

  sound[.tier] = tier.sound
  textgrid[.tier] = tier.syllables
endproc

procedure mergeSounds ()
  .parts = numberOfSelected("Sound")
  for .p to .parts
    .part[.p] = selected("Sound", .p)
  endfor
  .id = Concatenate
  nocheck selectObject: undefined
  for .p to .parts
    removeObject: .part[.p]
  endfor
  selectObject: .id
endproc

procedure processInterval (.start, .end)
  .pitch         = selected("Pitch")
  .sound         = selected("Sound")
  .syllables     = selected("TextGrid")
  .point_process = selected("PointProcess")
  .formant       = selected("Formant")
  .intensity     = selected("Intensity")

  .duration = .end - .start

  # Calculate pitch-related measures
  selectObject: .pitch
  .pitch_floor = Get quantile:           .start, .end, 0.05, "Hertz"
  .pitch_sd    = Get standard deviation: .start, .end, "Hertz"
  .min_pitch   = Get minimum:            .start, .end, "Hertz", "Parabolic"
  .max_pitch   = Get maximum:            .start, .end, "Hertz", "Parabolic"

  # Calculate spectrum-related variables
  selectObject: .sound
  .part = Extract part: .start, .end, "rectangular", 1, 0
  .spectrum = To Spectrum: "yes"
  @getHF(500)
  .hf500 = getHF.return

  # Calculate speech rate-related measures
  # This requires some more detailed pause-detection, since the script for
  # syllable nuclei assumes a single speaker
  selectObject: .syllables
  @countPointsInRange(1, .start, .end)
  .total_syllables = countPointsInRange.return
  .speech_rate = .total_syllables / .duration

  # Pauses are understood as breaks in voicing (as detected by Praat)
  # which begin no less than 250ms before the beginning of modal voice,
  # and end no later than 250ms before the end of phonation.
  if .duration >= (global.before_pause + global.after_pause)
    selectObject: .part
    runScript: "to_textgrid_pauses.praat",
      ... if .min_pitch = undefined then
      ...   tier.min_pitch else .min_pitch
      ... fi,
      ... global.silence_threshold,
      ... global.min_pause, global.before_pause, global.after_pause
    .total_pauses = Count labels: 1, "pause"
    Remove
  else
    .total_pauses = 0
  endif

  # Calculate jitter
  selectObject: .point_process
  @getJitter(.start, .end, 0.0001, 1 / tier.min_pitch, 1.3)
  .jitter = getJitter.return

  # Calculate formant values
  selectObject: .formant
  .mean_f1 = Get mean: 1, .start, .end, "Hertz"

  # Calculate intensity-related measures
  selectObject: .intensity
  .mean_intensity = Get mean:               .start, .end, "dB"
  .min_intensity  = Get minimum:            .start, .end, "Parabolic"
  .max_intensity  = Get maximum:            .start, .end, "Parabolic"
  .sd_intensity   = Get standard deviation: .start, .end

  # Write output to results Table
  @writeOutput()

  # Clean up workspace
  @intervalCleanUp()
endproc

procedure createOutputTable ()
# Create Table object for output
  Create Table with column names: "pressman_analysis", 0,
    ... "conversation"            + " " +
    ... "speaker"                 + " " +
    ... "start"                   + " " +
    ... "end"                     + " " +
    ... "pitch_floor"     + "_Hz" + " " +
    ... "pitch_min"       + "_Hz" + " " +
    ... "pitch_max"       + "_Hz" + " " +
    ... "pitch_sd"        + "_Hz" + " " +
    ... "hf500"           + "_dB" + " " +
    ... "jitter"          + ""    + " " +
    ... "f1_mean"         + "_Hz" + " " +
    ... "intensity_min"   + "_dB" + " " +
    ... "intensity_max"   + "_dB" + " " +
    ... "intensity_mean"  + "_dB" + " " +
    ... "intensity_sd"    + "_dB" + " " +
    ... "syllables"       + ""    + " " +
    ... "speech_rate"     + ""    + " " +
    ... "pauses"
endproc

#
# Write output to results Table
#
procedure writeOutput ()
  selectObject: final.table
  Append row
  .r = Object_'final.table'.nrow

  Set string value:  .r, "conversation",           global.name$
  Set string value:  .r, "speaker",                tier.speaker$
  Set numeric value: .r, "start",                  processInterval.start
  Set numeric value: .r, "end",                    processInterval.end
  Set numeric value: .r, "f1_mean"        + "_Hz", processInterval.mean_f1
  Set numeric value: .r, "pitch_floor"    + "_Hz", processInterval.pitch_floor
  Set numeric value: .r, "pitch_min"      + "_Hz", processInterval.min_pitch
  Set numeric value: .r, "pitch_max"      + "_Hz", processInterval.max_pitch
  Set numeric value: .r, "pitch_sd"       + "_Hz", processInterval.pitch_sd
  Set numeric value: .r, "hf500"          + "_dB", processInterval.hf500
  Set numeric value: .r, "jitter"         + "",    processInterval.jitter
  Set numeric value: .r, "intensity_min"  + "_dB", processInterval.min_intensity
  Set numeric value: .r, "intensity_max"  + "_dB", processInterval.max_intensity
  Set numeric value: .r, "intensity_mean" + "_dB", processInterval.mean_intensity
  Set numeric value: .r, "intensity_sd"   + "_dB", processInterval.sd_intensity
  Set numeric value: .r, "syllables"      + "",    processInterval.total_syllables
  Set numeric value: .r, "speech_rate"    + "",    processInterval.speech_rate
  Set numeric value: .r, "pauses"         + "",    processInterval.total_pauses
endproc

#
# Remove unnecessary objects - per tier
#
procedure tierCleanUp ()
  removeObject:
    ...   tier.point_process
    ... , tier.formant
    ... , tier.intensity
    ... , tier.pitch
    ... , tier.syllables
    ... , processSpeakerTier.intensity
endproc

#
# Remove unnecessary objects - per interval
#
procedure intervalCleanUp ()
  removeObject:
    ...   processInterval.part
    ... , processInterval.spectrum
endproc

# Calculate jitter
procedure getJitter (.start, .end, .floor, .ceiling, .max_factor)
  .return = undefined
  if numberOfSelected("PointProcess") = 1
    .return = Get jitter (local): .start, .end, .floor, .ceiling, .max_factor
  else
    exitScript: "Selection must be a single PointProcess object"
  endif
endproc

# Calculate high-frequency ratio, providing a cut-off point
procedure getHF (.cutoff)
  .return = undefined
  if numberOfSelected("Spectrum") = 1
    .top = Get highest frequency
    .lo  = Get band energy: 0, .cutoff
    .hi  = Get band energy: .cutoff, .top
    @int2db(.hi, .lo)
    .return = int2db.return
  else
    exitScript: "Selection must be a single Spectrum object"
  endif
endproc

# Convert between air pressure values to dB values
# For dB SPL use a reference value of (2*10^-5)^2
procedure int2db (.n, .ref)
  .return = 10 * log10(.n / .ref)
endproc

procedure equaliseTierDurations ()
  runScript: tgutils$ + "make_tier_times_equal.praat"
  .name$ = selected$("TextGrid")
  if index(.name$, "_equalised")
    removeObject: global.textgrid
    global.textgrid = selected()
  elsif index(.name$, "_unchanged")
    removeObject: selected()
    selectObject: global.textgrid
  endif
  Rename: global.name$
endproc

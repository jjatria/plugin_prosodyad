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

include ../../plugin_selection/procedures/tables.proc
include ../../plugin_tgutils/procedures/count_points_in_range.proc
include ../../plugin_tgutils/procedures/extract_tiers_by_name.proc

include ../../plugin_utils/procedures/trace.proc
include ../../plugin_tgutils/procedures/extract_tiers_by_name.proc

trace.enable = 0
trace.output$ = ""

form ProsoDyad utterance analysis...
  real     Start_(s)                       0 (= all)
  real     End_(s)                         0 (= all)
  positive Max_formant_(Hz)                5500 (= adult male)
  comment  Two-pass pitch detection (Hirst 2011)
  positive Floor_factor                    0.75
  positive Ceiling_factor                  1.5 (= 2.5 for expressive speech)
endform

@saveSelectionTable()
original_selection = saveSelectionTable.table

@parseSelection()
@saveSelectionTable()
full_selection = saveSelectionTable.table

@createOutputTable()
output_table = selected("Table")

@restoreSavedSelection: full_selection
@analysis: start, end

@restoreSavedSelection: full_selection
@minusSavedSelection: original_selection
nocheck Remove

removeObject: full_selection, original_selection
selectObject: output_table

procedure analysis: .start, .end
  .pitch         = selected("Pitch")
  .sound_full    = selected("Sound")
  .textgrid      = selected("TextGrid")
  .point_process = selected("PointProcess")
  .formant       = selected("Formant")
  .intensity     = selected("Intensity")

  selectObject: .sound_full
  if !.start and !.end
    .start = Object_'.sound'.xmin
    .end   = Object_'.sound'.xmax
    .process_part = 0
    .sound_part = .sound_full
    @trace: "    Working on full sound"
  else
    .process_part = 1
    .sound_part = Extract part: .start, .end, "rectangular", 1, 0
    @trace: "    Working on a fragment of the sound"
  endif
  .name$ = selected$("Sound")

  selectObject: .textgrid
  @extractTiersByName: "^syllables$", 0
  if !numberOfSelected("TextGrid")
    exitScript: "Selected TextGrid does not have a syllable nuclei tier"
  endif
  .syllables = selected("TextGrid")

  selectObject: .textgrid
  @extractTiersByName: "^(overlap|exchanges)$", 0
  if !numberOfSelected("TextGrid")
    exitScript: "Selected TextGrid does not have speaker exchange tiers"
  endif
  .exchanges = selected("TextGrid")

  .duration = .end - .start

  # Calculate pitch-related measures
  selectObject: .pitch
  .pitch_floor = Get quantile:           .start, .end, 0.05, "Hertz"
  .pitch_sd    = Get standard deviation: .start, .end, "Hertz"
  .min_pitch   = Get minimum:            .start, .end, "Hertz", "Parabolic"
  .max_pitch   = Get maximum:            .start, .end, "Hertz", "Parabolic"

  # Calculate spectrum-related variables
  selectObject: .sound_part
  .spectrum = To Spectrum: "yes"
  @getHF: 500
  .hf500 = getHF.return
  @trace: "    Jitter: " + string$(getHF.return)

  # Calculate speech rate-related measures
  # This requires some more detailed pause-detection, since the script for
  # syllable nuclei assumes a single speaker
  selectObject: .syllables
  @countPointsInRange(1, .start, .end)
  .total_syllables = countPointsInRange.return
  .speech_rate = .total_syllables / .duration

#   # Pauses are understood as breaks in voicing (as detected by Praat)
#   # which begin no less than 250ms before the beginning of modal voice,
#   # and end no later than 250ms before the end of phonation.
#   if .duration >= (global.before_pause + global.after_pause)
#     selectObject: .part
#     runScript: "to_textgrid_pauses.praat",
#       ... .min_pitch = undefined then
#       ...   tier.min_pitch else .min_pitch
#       ... fi,
#       ... global.silence_threshold,
#       ... global.min_pause, global.before_pause, global.after_pause
#     .total_pauses = Count labels: 1, "pause"
#     Remove
#   else
    .total_pauses = undefined
#   endif

  # Calculate jitter
  selectObject: .point_process
  @getJitter: .start, .end, 0.0001, 1 / .min_pitch, 1.3
  .jitter = getJitter.return

  # Calculate formant values
  selectObject: .formant
  .mean_f1 = Get mean: 1,               .start, .end, "Hertz"
  .mean_f2 = Get mean: 2,               .start, .end, "Hertz"
  .sd_f1   = Get standard deviation: 1, .start, .end, "Hertz"
  .sd_f2   = Get standard deviation: 2, .start, .end, "Hertz"

  # Calculate intensity-related measures
  selectObject: .intensity
  .mean_intensity = Get mean:               .start, .end, "dB"
  .min_intensity  = Get minimum:            .start, .end, "Parabolic"
  .max_intensity  = Get maximum:            .start, .end, "Parabolic"
  .sd_intensity   = Get standard deviation: .start, .end

  # Write output to results Table
  selectObject: output_table
  @trace: "    Writing to output table"
  @writeOutput()

  removeObject: .spectrum, .syllables, .exchanges

  if .process_part
    removeObject: .sound_part
  endif

  selectObject: output_table
  @trace: ""
endproc

procedure ensureTiers ()
  .textgrid = selected("TextGrid")

  selectObject: .textgrid
  @extractTiersByName: "^syllables$", 0
  if !numberOfSelected("TextGrid")
    exitScript: "Selected TextGrid does not have a syllable nuclei tier"
  endif
  .syllables = selected("TextGrid")

  selectObject: .textgrid
  @extractTiersByName: "^(overlap|exchanges)$", 0
  if !numberOfSelected("TextGrid")
    exitScript: "Selected TextGrid does not have speaker exchange tiers"
  endif
  .exchanges = selected("TextGrid")

endproc

# Calculate jitter
procedure getJitter: .start, .end, .floor, .ceiling, .max_factor
  .id = selected("PointProcess")
  .return = nocheck Get jitter (local): .start, .end, .floor, .ceiling, .max_factor
endproc

# Calculate high-frequency ratio, providing a cut-off point
procedure getHF: .cutoff
  .return = undefined
  if numberOfSelected("Spectrum") = 1
    .top = Get highest frequency
    .lo  = Get band energy: 0, .cutoff
    .hi  = Get band energy: .cutoff, .top
    @int2db: .hi, .lo
    .return = int2db.return
  else
    exitScript: "Selection must be a single Spectrum object"
  endif
endproc

# Convert between air pressure values to dB values
# For dB SPL use a reference value of (2e-5)^2
procedure int2db: .n, .ref
  .return = 10 * log10(.n / .ref)
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
    ... "f1_sd"           + "_Hz" + " " +
    ... "f2_mean"         + "_Hz" + " " +
    ... "f2_sd"           + "_Hz" + " " +
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
  .table = selected("Table")
  Append row
  .r = Object_'.table'.nrow

# Set string value:  .r, "conversation",           .name$
# Set string value:  .r, "speaker",                .speaker$
  Set numeric value: .r, "start",                  analysis.start
  Set numeric value: .r, "end",                    analysis.end
  Set numeric value: .r, "f1_mean"        + "_Hz", analysis.mean_f1
  Set numeric value: .r, "f1_sd"          + "_Hz", analysis.sd_f1
  Set numeric value: .r, "f2_mean"        + "_Hz", analysis.mean_f2
  Set numeric value: .r, "f2_sd"          + "_Hz", analysis.sd_f2
  Set numeric value: .r, "pitch_floor"    + "_Hz", analysis.pitch_floor
  Set numeric value: .r, "pitch_min"      + "_Hz", analysis.min_pitch
  Set numeric value: .r, "pitch_max"      + "_Hz", analysis.max_pitch
  Set numeric value: .r, "pitch_sd"       + "_Hz", analysis.pitch_sd
  Set numeric value: .r, "hf500"          + "_dB", analysis.hf500
  Set numeric value: .r, "jitter"         + "",    analysis.jitter
  Set numeric value: .r, "intensity_min"  + "_dB", analysis.min_intensity
  Set numeric value: .r, "intensity_max"  + "_dB", analysis.max_intensity
  Set numeric value: .r, "intensity_mean" + "_dB", analysis.mean_intensity
  Set numeric value: .r, "intensity_sd"   + "_dB", analysis.sd_intensity
  Set numeric value: .r, "syllables"      + "",    analysis.total_syllables
  Set numeric value: .r, "speech_rate"    + "",    analysis.speech_rate
  Set numeric value: .r, "pauses"         + "",    analysis.total_pauses
endproc

procedure parseSelection ()
  if !numberOfSelected("Sound")
    exitScript: "Need Sound object"
  endif
  sound = selected("Sound")

  @restoreSavedSelection: original_selection
  if !numberOfSelected("TextGrid")
    exitScript: "Need TextGrid object"
  endif
  textgrid = selected("TextGrid")

  @restoreSavedSelection: original_selection
  if !numberOfSelected("Pitch")
    @prosodyad.makePitch()
  endif
  pitch = selected("Pitch")

  @restoreSavedSelection: original_selection
  if !numberOfSelected("PointProcess")
    @prosodyad.makePointProcess()
  endif
  pointprocess = selected("PointProcess")

  @restoreSavedSelection: original_selection
  if !numberOfSelected("Formant")
    @prosodyad.makeFormant()
  endif
  formant = selected("Formant")

  @restoreSavedSelection: original_selection
  if !numberOfSelected("Intensity")
    @prosodyad.makeIntensity()
  endif
  intensity = selected("Intensity")

  selectObject: sound, textgrid, pitch, pointprocess, formant, intensity
endproc

procedure prosodyad.makePitch ()
  selectObject: sound
  runScript: twopass$ + "to_pitch_two-pass.praat",
    ... floor_factor, ceiling_factor
  min_pitch = Get minimum: 0, 0, "Hertz", "Parabolic"
  max_pitch = Get maximum: 0, 0, "Hertz", "Parabolic"
endproc

procedure prosodyad.makePointProcess ()
  selectObject: sound, pitch
  To PointProcess (cc)
endproc

procedure prosodyad.makeIntensity ()
  if !variableExists("min_pitch")
    selectObject: pitch
    min_pitch = Get minimum: 0, 0, "Hertz", "Parabolic"
  endif

  selectObject: sound
  To Intensity: min_pitch, 0, "yes"
endproc

procedure prosodyad.makeFormant ()
  selectObject: sound
  To Formant (burg): 0, 5, max_formant, 0.025, 50
endproc

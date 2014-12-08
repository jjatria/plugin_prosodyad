###########################################################################
#                                                                         #
#  Praat Script Syllable Nuclei                                           #
#  Copyright (C) 2008  Nivja de Jong and Ton Wempe                        #
#                                                                         #
#    This program is free software: you can redistribute it and/or modify #
#    it under the terms of the GNU General Public License as published by #
#    the Free Software Foundation, either version 3 of the License, or    #
#    (at your option) any later version.                                  #
#                                                                         #
#    This program is distributed in the hope that it will be useful,      #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
#    GNU General Public License for more details.                         #
#                                                                         #
#    You should have received a copy of the GNU General Public License    #
#    along with this program.  If not, see http://www.gnu.org/licenses/   #
#                                                                         #
###########################################################################
#
# modified 2014.12.04 by José Joaquín Atria
# + Changed applicable object queries to direct attribute queries
#
# modified 2014.09.23 by José Joaquín Atria
# + Updated syntax
# + Major code clean-up
# + Added minimum spread between peaks
# + Output now uses Table objects instead of Info screen
# + Script uses selected objects instead of filesystem
#
# modified 2010.09.17 by Hugo Quené, Ingrid Persoon, & Nivja de Jong
# Overview of changes:
# + change threshold-calculator: rather than using median, use the almost maximum
#     minus 25dB. (25 dB is in line with the standard setting to detect silence
#     in the "To TextGrid (silences)" function.
#     Almost maximum (.99 quantile) is used rather than maximum to avoid using
#     irrelevant non-speech sound-bursts.
# + add silence-information to calculate articulation rate and ASD (average syllable
#     duration.
#     NB: speech rate = number of syllables / total time
#         articulation rate = number of syllables / phonation time
# + remove max number of syllable nuclei
# + refer to objects by unique identifier, not by name
# + keep track of all created intermediate objects, select these explicitly,
#     then Remove
# + provide summary output in Info window
# + do not save TextGrid-file but leave it in Object-window for inspection
#     (if requested in startup-form)
# + allow Sound to have starting time different from zero
#      for Sound objects created with Extract (preserve times)
# + programming of checking loop for minimum_dip adjusted
#      in the orig version, precedingtime was not modified if the peak was rejected !!
#      var precedingtime and precedingint renamed to currenttime and currentint
#
# + bug fixed concerning summing total pause, feb 28th 2011
###########################################################################

form Counting syllables in Sound utterances...
  boolean Generate_summary no
  real Silence_threshold_(dB) -25 (= or -20?)
  real Minimum_dip_between_peaks_(dB) 2 (= up to 4 for clean and filtered)
  real Minimum_pause_duration_(s) 0.3
  positive Minimum_pitch 50 (=ignored if reusing Pitch objects)
  real Minimum_syllable_spread_(s) 0.08
  comment Note: unstressed syllables are sometimes overlooked
  comment For better results, filter noisy sounds beforehand.
endform

minimum_dip      = minimum_dip_between_peaks
minimum_pause    = minimum_pause_duration
minimum_spread   = if minimum_syllable_spread < 0 then 0 else minimum_syllable_spread fi
voiced_string$   = "sounding"
unvoiced_string$ = "silent"

# Save selection of sounds
total_sounds = numberOfSelected("Sound")
for i to total_sounds
  sound[i] = selected("Sound", i)
endfor

if total_sounds
  final_selection = Create Table with column names: "selection", 0, "id"
  if generate_summary
    @prepareSummary()
  endif
endif

for this_sound to total_sounds
  selectObject: sound[this_sound]
  sound          = selected()
  sound_name$    = selected$("Sound")
  sound_start    = Object_'sound'.xmin
  sound_duration = Object_'sound'.xmax - sound_start

  intensity = To Intensity: minimum_pitch, 0, "yes"

  noise_floor = Get minimum: 0, 0, "Parabolic"
  noise_peak  = Get maximum: 0, 0, "Parabolic"

  almost_peak = Get quantile: 0, 0, 0.99

  # The silence threshold represents the minimum intensity below the peak that
  # is to be considered sounding. In order to avoid non-speech sound bursts,
  # however, the 0.99 quantile is used instead of the absolute intensity peak.
  # The silence threshold then needs to be adjusted, so that it takes this
  # information into account.
  # This is done by substracting the difference between the real and the
  # estimated peak.
  lowest_peak = almost_peak + silence_threshold
  if lowest_peak < noise_floor
    lowest_peak = noise_floor
  endif
  silence_threshold -= (noise_peak - almost_peak)

  # Use improved silence detection using minimum pitch
  selectObject: sound
  silence_textgrid = To TextGrid (silences): minimum_pitch, 0,
    ... silence_threshold, minimum_pause, 0.01, unvoiced_string$, voiced_string$

  # Basic pause detection.
  # Consider everything in it to be the turn of a single speaker, and any
  # automatically detected interruption to be a pause, regardless of other
  # contextual information.
  total_pauses = Count labels: 1, voiced_string$
  total_pauses -= 1

  @calculatePhonationTime(silence_textgrid, voiced_string$)
  phonation_time = calculatePhonationTime.return

  selectObject: intensity
  matrix = Down to Matrix
  intensity_curve = To Sound (slice): 1
  Rename: sound_name$ + "_intensity"

  intensity_duration =
    ... Object_'intensity_curve'.xmax - Object_'intensity_curve'.xmin

  time_correction = sound_duration / intensity_duration

  selectObject: intensity_curve
  point_process = To PointProcess (extrema): 1, "yes", "no", "Sinc70"
  total_points = Get number of points

  peaks_table = Create Table with column names: "peaks", 0,
    ... "time value"

  for p to total_points
    selectObject: point_process
    time = Get time from index: p

    selectObject: intensity
    value = Get value at time: time, "Cubic"

    if value >= lowest_peak
      selectObject: peaks_table
      Append row
      row = Object_'peaks_table'.nrow
      Set numeric value: row, "time",  time
      Set numeric value: row, "value", value
    endif
  endfor

  @removeSmallDips(peaks_table, sound, intensity)

  @mergeClosePeaks(peaks_table)

  selectObject: peaks_table
  total_syllables = Object_'peaks_table'.nrow

  selectObject: sound
  nuclei_textgrid = To TextGrid: "nuclei", "nuclei"
  @populateTextGrid(nuclei_textgrid, peaks_table)

  if generate_summary
    @writeSummary()
  endif

  @cleanUp()

  @addToFinalSelection (nuclei_textgrid)

  # End of main sound loop
endfor

@restoreFinalSelection()

procedure calculatePhonationTime (.textgrid, .voiced$)
  selectObject: .textgrid
  .intervals = Get number of intervals: 1

  .return = 0
  for .i to .intervals
    .label$ = Get label of interval: 1, .i
    if .label$ = .voiced$
      .start = Get start point: 1, .i
      .end = Get end point: 1, .i
      .return += (.end - .start)
    endif
  endfor
endproc

procedure populateTextGrid (.textgrid, .table)
  selectObject: .table
  .rows = Object_'.table'.nrow

  selectObject: .textgrid
  for .r to .rows
    .time = Object_'.table'[.r, "time"]
    Insert point: 1, .time, string$(.r)
  endfor
endproc

procedure mergeClosePeaks (.table)
  selectObject: .table
  .rows = Object_'.table'.nrow
  for .r to .rows-1
    .ta  = Object_'.table'[.r,   "time"]
    .tb  = Object_'.table'[.r+1, "time"]

    .ia  = Object_'.table'[.r,   "value"]
    .ib  = Object_'.table'[.r+1, "value"]

    if minimum_spread > (.tb - .ta)
      Remove row: .r
      Remove row: .r
      Insert row: .r
      Set numeric value: .r, "time",  .ta + ((.tb - .ta) / 2)
      Set numeric value: .r, "value", (.ia + .ib) / 2
      .rows -= 1
    endif
  endfor
endproc

procedure removeSmallDips (.table, .sound, .intensity)
  selectObject: .sound
  .pitch = To Pitch (ac): 0.02, 30, 4, "no", 0.03, 0.25, 0.01, 0.35, 0.25, 450

  selectObject: .table
  .total_rows = Object_'.table'.nrow
  for .p to .total_rows-1
    # Iterate through table from the bottom
    .row = .total_rows - .p
    selectObject: .table

    .time_a      = Object_'.table'[.row, "time"]
    .intensity_a = Object_'.table'[.row, "value"]

    .time_b      = Object_'.table'[.row+1, "time"]
    .intensity_b = Object_'.table'[.row+1, "value"]

    selectObject: .intensity
    .dip = Get minimum: .time_a, .time_b, "None"

    if abs(.intensity_a - .dip) <= minimum_dip
      selectObject: .table
      Remove row: .row
    else
      selectObject: .pitch
      .pitch_a = Get value at time: .time_a, "Hertz", "Linear"
      if .pitch_a = undefined
        selectObject: .table
        Remove row: .row
      endif
    endif
  endfor

  removeObject: .pitch
endproc

procedure cleanUp ()
  removeObject:
    ...   matrix
    ... , silence_textgrid
    ... , peaks_table
    ... , point_process
    ... , intensity
    ... , intensity_curve
endproc

procedure prepareSummary ()
  .id = Create Table with column names: "syllable_nuclei_summary", 0,
    ... "soundname"         + " " +
    ... "nsyll"             + " " +
    ... "npause"            + " " +
    ... "dur"               + " " +
    ... "phonationtime"     + " " +
    ... "speechrate"        + " " +
    ... "articulation_rate" + " " +
    ... "ASD"
  @addToFinalSelection(.id)
endproc

procedure writeSummary ()

  speech_rate       = total_syllables / sound_duration
  articulation_rate = total_syllables / phonation_time
  asd               = 1 / articulation_rate

  selectObject: prepareSummary.id
  Append row
  row = Object_'prepareSummary.id'.nrow
  Set string value:  row, "soundname",         sound_name$
  Set numeric value: row, "nsyll",             total_syllables
  Set numeric value: row, "npause",            total_pauses
  Set numeric value: row, "dur",               sound_duration
  Set numeric value: row, "phonationtime",     phonation_time
  Set numeric value: row, "speechrate",        speech_rate
  Set numeric value: row, "articulation_rate", articulation_rate
  Set numeric value: row, "ASD",               asd
endproc

procedure addToFinalSelection (.id)
    selectObject: final_selection
    Append row
    .row = Object_'final_selection'.nrow
    Set numeric value: .row, "id", .id
endproc

procedure restoreFinalSelection ()
  selectObject: final_selection
  .rows = Object_'final_selection'.nrow
  for .r to .rows
    .id[.r] = Object_'final_selection'[.r, "id"]
  endfor
  for .r to .rows
    plusObject: .id[.r]
  endfor
  removeObject: final_selection
endproc

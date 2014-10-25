# Setup for Voice Analysis plugin
#
# Design:  Peter Pressman, Jose Joaquin Atria
# Coding:  Jose Joaquin Atria
# Version: 0.9.1
# Initial release: October 21, 2014
# Last modified:   October 24, 2014
#
# This script is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.

## Static commands:

# Base menu
Add menu command: "Objects", "Praat", "Pressman",                           "",         0, ""
Add menu command: "Objects", "Praat", "Equalize tier durations (batch)...", "Pressman", 1, "scripts/batch_make_tier_times_equal.praat"
Add menu command: "Objects", "Praat", "Run analysis (batch)...",            "Pressman", 1, "scripts/batch_analysis.praat"

## Dynamic commands
Add action command: "TextGrid", 0, "",         0, "", 0, "Equalise tier durations",      "Synthesize -",          1, "scripts/make_tier_times_equal.praat"
Add action command: "TextGrid", 0, "",         0, "", 0, "To non-overlapping intervals", "Synthesize -",          1, "scripts/to_non-overlapping_intervals.praat"
Add action command: "TextGrid", 1, "",         0, "", 0, "Count points in range...",     "Query point tier",      2, "scripts/count_points_in_range.praat"
Add action command: "TextGrid", 1, "",         0, "", 0, "Find label from start...",     "Query -",               1, "scripts/find_label_from_start.praat"
Add action command: "TextGrid", 1, "",         0, "", 0, "Find label from end...",       "Query -",               1, "scripts/find_label_from_end.praat"
Add action command: "Sound",    1, "TextGrid", 1, "", 0, "Pressman analysis...",         "",                      0, "scripts/main_analysis.praat"
Add action command: "Sound",    1, "",         0, "", 0, "To TextGrid (pauses)...",      "Annotate -",            1, "scripts/to_textgrid_pauses.praat"
Add action command: "Sound",    0, "",         0, "", 0, "To Pitch (two-pass)...",       "Analyse periodicity -", 1, "scripts/to_pitch_twopass.praat"

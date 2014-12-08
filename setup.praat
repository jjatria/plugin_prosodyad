# Setup for Voice Analysis plugin
#
# Design:  Peter Pressman, Jose Joaquin Atria
# Coding:  Jose Joaquin Atria
# Version: 0.9.2
# Initial release: October 21, 2014
# Last modified:   November 6, 2014
#
# This plugin requires the JJATools plugin
# the latest version of which can be downloaded from
# https://github.com/jjatria/plugin_jjatools
#
# This script is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.

if !fileReadable("../plugin_jjatools/")
  exitScript: "Pressman plugin requires a copy of the JJATools plugin, " +
    ... "available at https://github.com/jjatria/plugin_jjatools" +
    ... newline$
endif

## Static commands:

# Base menu
Add menu command: "Objects", "Praat", "Pressman",                           "",         0, ""
Add menu command: "Objects", "Praat", "Run analysis (batch)...",            "Pressman", 1, "scripts/batch_analysis.praat"

## Dynamic commands
Add action command: "Sound",    1, "TextGrid", 1, "", 0, "Pressman analysis...",         "",                      0, "scripts/main_analysis.praat"
Add action command: "Sound",    1, "",         0, "", 0, "To TextGrid (pauses)...",      "Annotate -",            1, "scripts/to_textgrid_pauses.praat"

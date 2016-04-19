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

if !fileReadable("../plugin_tgutils/")
  exitScript:
    ... "Prosodyad requires a copy of the tgutils CPrAN plugin." + newline$ +
    ... "Please see http://cpran.net/plugins/tgutils" + newline$
endif

## Static commands:

# Base menu
Add menu command: "Objects", "Praat", "Prosodyad",               "CPrAN",     1, ""
Add menu command: "Objects", "Praat", "Run analysis (batch)...", "Prosodyad", 2, "scripts/batch_analysis.praat"

## Dynamic commands
Add action command: "Sound",    1, "TextGrid", 1, "", 0, "Prosodyad - ", "", 0, ""
Add action command: "Sound",    1, "TextGrid", 1, "", 0, "Prosodyad analysis...",   "Prosodyad -", 1, "scripts/main_analysis.praat"
Add action command: "Sound",    1, "TextGrid", 1, "", 0, "Turn-taking analysis...", "Prosodyad -", 1, "scripts/exchanges_and_interruptions.praat"
Add action command: "Sound",    1, "",         0, "", 0, "To TextGrid (pauses)...", "Annotate -",  1, "scripts/to_textgrid_pauses.praat"

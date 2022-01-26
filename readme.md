Voice analysis
==============

The purpose of the scripts contained in this Praat plugin is to obtain
acoustic data from long casual speech recordings. It is expected that these data
might eventually help in the diagnosis of some specific neurological
pathologies.

The current version of these scripts make measurements for each spoken interval.
Future versions might improve the resolution of these measurements, so they can
be obtained from smaller windows.

The script tries to identify parts of the recording during which a single
speaker is speaking, and uses these as units of analysis. From each of these,
the following measures are taken:

* Start

* End

* Pitch floor (lowest 5%, in Hertz)

* Pitch minimum (in Hertz)

* Pitch maximum (in Hertz)

* Pitch standard deviation (in Hertz)

* HF500 (in dB)

* Jitter

* F1 mean (in Hertz)

* Intensity minimum (in dB)

* Intensity maximum (in dB)

* Intensity mean (in dB)

* Intensity standard deviation (in dB)

* Number of pauses

It also includes results of a modified version of de Jong and Wempe's syllable
nuclei detection script. Changes to that script should not generate substantial
changes to the scripts results (if any at all), but do improve the script's
speed and output format, which now uses Praat's internal Table object.

From this script, the following two measures are obtained:

* Number of syllables (or an approximation thereof)

* Speech rate

This is a work in progress.

Requirements
------------

This set of scripts makes extensive (albeit not exclusive) use of the new
"variable-substitution-free" Praat syntax. **[Praat][] v5.4+** is recommended
(although immediately preceding versions up to a certain point should work).

[praat]: http://www.praat.org

A large number of operations rely on functionality provided by some of the
plugins distributed via [CPrAN]. Without those plugins, this one will not work.
Please refer to this plugin's `cpran.yaml` file for the list of dependencies.

[CPrAN]: http://cpran.net

Installation
------------

 1. Install [Praat][]

 2. Install the plugin and all of its dependencies.

    Currently, the simplest way to do so is by downloading the plugin bundle
    in the latest release, and extracting that directly into your Praat
    preferences directory. Please check the [Praat documentation]
    for its location on your system.

    The result of this operation should be a number of directories with names
    starting with the `plugin_` prefix being directly under your preferences
    directory.

 3. The plugin should now be available under Praat -> CPrAN -> Prosodyad, or
    by selecting a Sound and a TextGrid objects and using the commands in the
    "Prosodyad" menu.

Authors
-------

* **Peter Pressman** (design)

* José Joaquín Atria (design and coding)

License
-------

This plugin and the scripts herein are free software: you can redistribute them
and/or modify them under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

A copy of the GNU General Public License is available at
<http://www.gnu.org/licenses/>.

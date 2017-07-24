include ../../plugin_tap/procedures/more.proc
include ../../plugin_utils/procedures/try.proc

@no_plan()

base = Create TextGrid: 0, 1, "awords bwords", ""
Insert boundary: 1, 0.33
Insert boundary: 1, 0.66
Rename: "base"

verbose = 0

scripts$ = preferencesDirectory$ + "/plugin_prosodyad/scripts/"

@diag: "Test removal of intervals on tier 1"
@run_tests: 1

# Test warning if not enough tiers matched
Set tier name: 1, "unmatched"
@mytest: 0, 1, "x", "",  "z", 0, 0, ""
@diag: "Do not remove if tiers did not match"
Set tier name: 1, "awords"
@like: info$(), "Not enough tiers matched",
  ... "Notify user if not enough tiers matched"

# Make sure it dies without a TextGrid selected
selectObject()
call try
  ... runScript: "'scripts$'" + "remove_added_breaks.praat", "[ab]words"
@is_true: try.catch, "Died without TextGrid selected"

# Invert tiers
selectObject: base
@invert_tiers()
base = selected()

@diag: "Test removal of intervals on tier 2"
@run_tests: 2
removeObject: base

@ok_selection()

@done_testing()

procedure invert_tiers ()
  .id = selected()
  .tier = Extract one tier: 1
  selectObject: .id
  Remove tier: 1
  selectObject: .tier, .id
  .temp = Merge
  removeObject: .id, .tier
  .id = .temp
endproc

procedure run_tests: .tier
  .msg$ = "tier " + string$(.tier)

  for .a from -1 to 1
    for .b from -1 to 1
      .ok = if .a > 0 then 0 else if .b < 0 then 0 else 1 fi fi

      @mytest: 1 * .ok, .tier, "x", "",  "z", .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "x", "",  "",  .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "x", "y", "z", .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "x", "y", "",  .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "",  "y", "z", .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "",  "y", "",  .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "",  "",  "z", .a, .b, .msg$
      @mytest: 0 * .ok, .tier, "",  "",  "",  .a, .b, .msg$
    endfor
  endfor
endproc

procedure mytest: .ok, .tier, .alab$, .blab$, .clab$, .ashift, .bshift, .msg$
  selectObject: base
  .id = Copy: "test"
  .delta = 0.1

  .other_tier = (1 - (.tier - 1)) + 1

  Set interval text: .tier, 1, .alab$
  Set interval text: .tier, 2, .blab$
  Set interval text: .tier, 3, .clab$

  if .ashift != undefined
    Insert boundary: .other_tier, 0.33 + (.delta * .ashift)
  endif
  if .bshift != undefined
    Insert boundary: .other_tier, 0.66 + (.delta * .bshift)
  endif

  runScript: scripts$ + "remove_added_breaks.praat", "[ab]words"


  .name$ = if .ok then "Remove interval" else "Do not remove interval" fi
  .name$ = .name$ + if .msg$ != "" then ": " + .msg$ else "" fi

  .expected = if .ok then 1 else 3 fi

  @is: do("Get number of intervals...", .tier), .expected, .name$

  if verbose
    .first$  = if .alab$ != "" then .alab$ else " " fi + "  |  " +
      ...      if .blab$ != "" then .blab$ else " " fi + "  |  " +
      ...      if .clab$ != "" then .clab$ else " " fi

    .second$ = "  " +
      ...      if .ashift < 0 then "|  "
      ... else if .ashift > 0 then "  |"
      ... else                     " | " fi fi
      ... + "   " +
      ...      if .bshift < 0 then "|  "
      ... else if .bshift > 0 then "  |"
      ... else                     " | " fi fi

    @diag: .first$
    @diag: .second$
  endif

  removeObject: .id
  selectObject: base
endproc

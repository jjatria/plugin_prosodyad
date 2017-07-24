include ../../plugin_tap/procedures/more.proc

@no_plan()

base = Create TextGrid: 0, 1, "awords bwords", ""
Insert boundary: 1, 0.33
Insert boundary: 1, 0.66
Rename: "base"

for a from -1 to 1
  for b from -1 to 1
    ok = if a > 0 then 0 else if b < 0 then 0 else 1 fi fi

    @mytest: 1 * ok, "x", "",  "z", a, b
    @mytest: 0 * ok, "x", "",  "",  a, b
    @mytest: 0 * ok, "",  "",  "z", a, b
    @mytest: 0 * ok, "",  "",  "",  a, b
    @mytest: 0 * ok, "x", "y", "z", a, b
    @mytest: 0 * ok, "x", "y", "",  a, b
    @mytest: 0 * ok, "",  "y", "z", a, b
    @mytest: 0 * ok, "",  "y", "",  a, b
  endfor
endfor


procedure mytest: .ok, .alab$, .blab$, .clab$, .ashift, .bshift
  selectObject: base
  .id = Copy: "test"
  .delta = 0.1

  Set interval text: 1, 1, .alab$
  Set interval text: 1, 2, .blab$
  Set interval text: 1, 3, .clab$

  if .ashift != undefined
    Insert boundary: 2, 0.33 + (.delta * .ashift)
  endif
  if .bshift != undefined
    Insert boundary: 2, 0.66 + (.delta * .bshift)
  endif

  runScript: "../../plugin_prosodyad/scripts/" +
    ... "remove_added_breaks.praat", "[ab]words"

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

  if .ok
    @is: do("Get number of intervals...", 1), 1, "Remove"
  else
    @is: do("Get number of intervals...", 1), 3, "Do not remove"
  endif

  @diag: .first$
  @diag: .second$

  removeObject: .id
  selectObject: base
endproc

removeObject: base

@ok_selection()

@done_testing()

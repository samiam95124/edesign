# ICD Pascaline port

Port of the ICD graphics/windowing system (SVS Pascal, 1992, direct to
VGA hardware) to Pascaline / Pascal-P6 over the Ami `graphics` library.

## Status

The entire ICD source set is ported and builds into one executable
(`pc icd`). Working: the full windowed interface
(beveled frame, title bar, auto-arranged mode/tool menus, target view),
xor rubber-band drawing, wire drawing with net creation into the
schematic database, zoom/pan/view navigation, Symbol/Schematic/Layout/
Simulate mode switching with per-mode menus, cell file read/write and
the file/cell/library dialogs, keyboard field editing, and printing to
a portable pixmap. Interface geometry scales from the character cell
(14 point font) per the Ami convention. See the wave sections below for
detail and the known-issues list for follow-ups.

## Build

    pc icd            # builds icddef, icdui, and the icd main; needs the
                      # Pascal-P6 toolchain on PATH and PASCALP6 set
    ./icd             # run (X11)

Three source files, one module each layer:

| File | Role |
|---|---|
| `icd.pas` | program module: the event pump (mouse/keyboard/redraw/resize -> icdui entries) |
| `icddef.pas` | types + globals (port of the original define.pas + common.pas) |
| `icdui.pas` | the graphics/windowing/command/file/print layers, ported from icda-icdh + icdb + icde-g. One module because the original files call each other mutually and Pascaline forbids module dependency cycles; section banners inside mark the code from each original file. |

`docs/porting-spec.md` records the conversion rules; `toolchain/` holds the
minimal reproductions for the three Pascal-P6 compiler issues found and fixed
during the port (#592, #593, #597).

## Port design points

- **Display-density scaling (Ami convention)**: the interface font is
  set at 11 points (`setpoints`), so the character cell tracks the
  physical display density; every legacy pixel dimension of the 1992
  layout (16px cells, 23px buttons, frame bands, cursor figures,
  autoarranger gaps, fixed button positions) is scaled through
  `uiscl(n) = n*chrsizy/16` in the base layer. Verified at simulated
  4K (3840x2160 @ 220dpi: 43px cells) and standard density. The window
  is left at the Ami default size (itself density-derived). Note:
  `setsizg` at startup blanked the display and returned stale
  `maxxg`/`maxyg` — avoided; may merit an Ami look someday. The 2px
  bevel lines are deliberately not scaled (see the sweep notes in
  frag_b) — cosmetic candidate for a later linewidth-based pass.

- `joins graphics` (qualified names) so ICD keeps its own `line`, `block`,
  `frame`, `color` (16-color EGA enum, reproduced exactly via `fcolorg`).
- Save-under rubber-banding (getpix/linesav/linerst/arcsav) replaced by
  xor draw/redraw pairs; ~1000 lines of save-under arc code deleted.
- The 16x16 bitmap font and width tables replaced by graphics fonts and
  `strsiz` metrics; the stroked/rotated vector font (vchar) ported as-is.
- The tablet/keyboard poll loop replaced by the graphics event loop; the
  puck communication flags (`puck.b[n].a/.d/.ap/.dp`, `puck.m`) are
  emulated in the `ev*` entries so ported chkbut/movcur logic is unchanged.
- Several instances of stale-field source damage in the originals (fields
  renamed/moved after the code was written, tolerated by SVS) were
  repaired; all are marked with `{ port: ... }` comments.
- New subrange `btslen = 0..butlen` for length-valued uses of `btsinx`
  (SVS did not range-check; P6 does — zero lengths are legitimate).

## Pascal-P6 toolchain issues found (both FIXED upstream)

1. **pcom `maxtrk` capacity** — error 227 on large type digests (ICD's
   `winrec` digest is 4656 chars vs the old 4000 cap). Filed as
   [Pascal-P6 #592](https://github.com/samiam95124/Pascal-P6/issues/592),
   fixed (maxtrk now 20000).

2. **Importer stores to nested record fields of module globals
   miscompiled** (all stores collapsed to one wrong offset; loads and
   owner-module stores were correct). Filed as
   [Pascal-P6 #593](https://github.com/samiam95124/Pascal-P6/issues/593),
   fixed. Reproduction kept in `toolchain/repro*.pas`.

Both fixes are verified against this port; the module split (`icddef` as
a separate module) and the stock toolchain are in use.

> Note: the wave sections below are a record of how the port was built.
> The `frag_*` names refer to porting fragments that have since been
> consolidated into the single `icdui.pas` module (section banners inside
> it mark the code from each original ICD file). There is no longer an
> assemble step -- the build is `pc icd`.

## Wave 2 (ported): command + drawing layers

The second wave is integrated and builds clean: the schematic database
core (frag_n: nodes/buses/wires, attwire/plcjun/crtnod...), the full
icdd figure/selection layer (frag_f: drwfig and the device drawers,
distance-based selection, delete/smash, save/paste block), the icdc
command layer (frag_g: doline/dobox/docircle/doarc/dotext, mode
switching, dobutton, the original `command` loop converted to a
per-event `dispatch`, dokeyboard converted to per-character), and the
icdf target-view module (frag_i, including the original sign-on logo
and intro). Sheets are created on demand by dispcell exactly as in the
original.

**Interaction verified end-to-end** (after the
[#597](https://github.com/samiam95124/Pascal-P6/issues/597) Ami event
fix): the full right-side menu arranges and renders, wire mode
rubber-bands with the mouse, wire segments place and chain, the
database creates nets (the Name field shows the auto-generated net
name), and the target-view thumbnail tracks the drawing. Two more
original-source defects were found and repaired during this
verification, both marked `{ port: }`:

- the window/screen viewports carried `s = m = 1`, which is coherent
  for the draw transform (`viewx`, scaled by m/s) but not the
  real-coordinate converter (`viewc`, scaled by scalem/s); the shipped
  1992 executable predates these sources (the sources were frozen
  mid-refactor, and `plcwin` only ever worked because SVS leaked value
  record parameters by reference). Window viewports now use
  `s = m = scalem`, making both transforms identity.
- `drwfig`'s twire arm read the tline variant field `l` on a twire
  entry (free-union punning under SVS, caught by P6 variant checking);
  the guard now reads the wire's own `w` field.

## Wave 3 (ported): file I/O, layout, simulate, printer

The final wave completes every phase. All four fragments are integrated
and the program builds clean (`pc icd`, one 14 MB executable):

- **frag_o** (icda remainder): cell file read/write (readsht/wrtsht,
  loadcell/savecell), the file/cell/library browser dialogs. The DOS
  directory search is replaced by the Pascaline `services` directory
  API (module header is now `joins graphics, services;`); the SVS
  byte-file hack (`file of boolean` + convert) became a proper
  `file of byte`.
- **frag_p** (icdg): layout mode -- setlayout, the layer draw command,
  layer/insides visibility toggles, and the intersection generator.
- **frag_q** (icdh): simulate mode -- setsimulate, the digital/analog
  trace renderers (dtrace/atrace), waveform edit (dowave).
- **frag_r** (icde): the complete print pipeline. The raster primitives
  (p-variants into the print strip buffer) port intact; the Fujitsu
  DL3400 port-write back end is replaced by a portable pixmap writer --
  printing produces `icdprint.ppm` (P3, the same EGA palette).

**Verified interactively** (headless Xvfb + xdotool):

- Layout mode: clicking Layout switches the right menu to the IC layer
  set (Met1/Met2/Poly/Via/Cont/Ndiff/Pdiff/Nwell/Pwell/Ccut with per-
  layer Vis toggles, Insides, Place, Drc).
- Simulate mode: clicking Simulate switches to the waveform tools
  (Dwave/Awave) and the oscilloscope-style top controls (Postime/
  Posvolt/Orgtime/Orgvolt/Rultime/Rulvolt).
- Keyboard field entry: clicking a field enters edit mode, typed
  characters update the field, and the edit cursor renders in the
  correct proportional position (the original's `b.r.s.x*16` cursor
  cell-math -- pre-existing damage that drew the cursor off screen --
  is repaired to proportional positioning via strwidth).
- Print: the pipeline runs end to end and emits a structurally valid
  `icdprint.ppm`.

## More original-source defects repaired this wave (all marked `{ port: }`)

- `tcont` was omitted from the `drwety` variant list though dolayer/
  dointer store a region on tcont entries (same free-union class as the
  documented twire fix); moved into the rectangle variant group.
- `fndbound` read the tcont/tinter rectangle field on the wrong variant
  arm; tinter given its own arm reading `ir`.
- `dmenu` is a dangling external (defined only in the pre-refactor
  icdc.sav; the menu redraw moved into dispwin when the sources froze);
  setlayout/setsimulate converted to the setschema/setsymbol pattern.
- `loadlib`'s sheet-skip advanced past 8 figure lists per sheet while
  readsht/wrtsht handle 11 -- library loads would desync against files
  this program writes; aligned to 11.

## Known issues / follow-ups

- Print finalize (`pagprt`) copies the raster temp to the PPM
  character by character -- correct but slow for a full 2520-wide page;
  a block copy would help. `outbuf` emits rows `0..pbymax` while the
  buffer clear uses `pmax.y`, which can leave dark margin rows; both are
  print-pixel polish, not pipeline defects.
- The print temp `icdprint.tmp` is left on disk: Pascaline's predefined
  file `delete` is shadowed module-wide by ICD's delete-figure command,
  so `pagprt` cannot name it.
- A pgen "out of registers" abort on a 12-argument call with variant-
  checked member arguments (icdg `intfig`) was worked around by hoisting
  `p^.b` to a local; may merit an upstream Pascal-P6 report.
- The simulate top menu can overflow to a second row at small window
  sizes (cosmetic autoarranger geometry).

## Not ported

Nothing remains unported from the original ICD source set. `scnprt`
(print-screen) is present but prints blank -- it needs pixel readback
(`getpix`), which the graphics library does not provide; the structure
is kept for a future readback path.

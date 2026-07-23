# Modularizing the ICD Pascaline port

## Why this document

The port currently lives in one big module, `icdui`, plus the `icddef`
definitions leaf and the `icd` program. That is the correct *interim* state:
the original ICD source was cut into files (`icda`..`icdh`) arbitrarily, and
those files call each other in every direction. SVS tolerated that with a flat
`external` namespace where any unit can name any other. Pascaline's `uses` /
`joins` is a strict acyclic graph, so the arbitrary cross-calls cannot be
expressed as module dependencies — which is exactly why the port collapsed
them into one module.

Un-collapsing is not a matter of running the call tree and cutting. The call
tree tells you the *legal* layering (what is allowed to depend on what); it
does not tell you the *right* grouping by function. This document records:

1. the target layer stack (a forward DAG),
2. the **back-edges** — the places where low-level code reaches back up — and
   how each converts to an **exception** or an **override** so the DAG stays
   acyclic while control still "loops back to the top", and
3. a sequencing that lets the split happen incrementally without a flag day.

Modules link with `joins` (qualified names, e.g. `icdwin.redraw`) rather than
`uses` (merged namespace). The flat namespace is what produced the original's
name collisions — the port already had to rename `setbox`/`resbox` twice where
independent layers reused the name. Qualified identifiers make the layer
visible at every call site and remove the collisions by construction.

## Target layer stack (leaves at the bottom)

```
  icd                 program: the event pump
  ────────────────────────────────────────────────
  icdschema  icdlayout  icdsim        mode behavior (override icdedit)
  icdedit                             common editing / command dispatch
  icdfile    icdprint                 persistence, hardcopy (side branches)
  ────────────────────────────────────────────────
  icdwin                              window frame, layout, zoom/pan, redraw
  icdbut                              buttons, menus, autoarranger, field edit
  icdtarg                             target view, sign-on
  ────────────────────────────────────────────────
  icdfig                              figures: drwfig, device drawers, select
  icddb                              schematic database: nodes/buses/wires
  ────────────────────────────────────────────────
  icdview                            coordinate transforms, clip, rubber-band
  icddraw                            line/block/pixel/arc/font over graphics
  ────────────────────────────────────────────────
  icderr                             exception declarations (leaf)
  icddef                             types + shared state (dissolving; see end)
  graphics   services                Ami libraries (external leaves)
```

Every arrow in that stack points downward (a module `joins` only modules below
it). The four horizontal rules are the natural cut lines. The back-edges below
are the arrows that would otherwise point *up*.

## The back-edges and their conversions

### 1. Program termination — general exception

Original: `goto 88 / 99`. Port today: a `terminate` boolean plus `termreq`
(which also tests `button[bexit].act`), polled by the event loop. The exit
condition is set deep inside `dobutton` (the Exit button) and by the
window-close event.

A boolean polled at the top is the degenerate form of an exception. Pascaline's
`halt` *is* the general exception, program-wide and visible everywhere without
declaration:

```pascal
{ deep in the command layer }
if button[bexit].act then halt;   { was: terminate := true }

{ icd program main }
begin
   iniicd;
   try
      repeat graphics.event(er); dispatch(er) until false
   except { general exception: normal shutdown }
   end
end.
```

No module names a higher one; `halt` unwinds to the program's implicit outer
handler. The `terminate`/`termreq` globals disappear.

### 2. Input parse errors — named exceptions

Original and port: `getint` / `getrnm` carry a `var err: boolean` out-parameter,
use a local `goto 99` to bail out of the parse, and call `plcmsg` to paint the
error banner themselves. That threads an error channel and a presentation call
through a leaf-ward routine.

Declare the exceptions in the `icderr` leaf so both thrower and catcher see
them, throw from the parser, and let the *caller* — the field-edit handler in
`icdbut` — decide how to report:

```pascal
module icderr;
   var InvalidNumber, NumberOverflow: exception;
begin end. begin end.

{ icdbut: getrnm throws instead of returning err + goto }
if not digit then throw(icderr.InvalidNumber);

{ icdbut: the field-edit caller catches and reports }
try getrnm(b, n)
on icderr.InvalidNumber except plcmsg(minvn, lred)
on icderr.NumberOverflow except plcmsg(movfn, lred)
end;
```

The `var err` parameter, the `goto 99`, and the parser's own `plcmsg` calls all
go away. `plcmsg` becomes a pure `icdbut` concern reached only at the catch.

### 3. Cancel / stop the current activity — exception at the deep site

`canact` / `stopact` / `stopview` are called from ~51 sites to unwind an
in-progress operation (a rubber-band line, a trace, a placement) and reset the
cursor and mode. Some calls are proactive (the button-3 cancel in `dispatch`)
and stay as ordinary downward calls to cleanup routines that live in `icdedit`.
The problematic ones are the *deep* bail-outs — a figure or database routine
discovering it cannot continue and needing to abort the whole gesture.

Those become an `OperationCancelled` exception thrown at the deep site and
caught by the command dispatch, which runs the cleanup:

```pascal
{ icderr } var OperationCancelled: exception;

{ deep in icdfig / icddb }
if degenerate then throw(icderr.OperationCancelled);

{ icdedit dispatch }
try docmd
on icderr.OperationCancelled except stopact { local cleanup }
end;
```

`canact`/`stopact`/`stopview` themselves stay in `icdedit` as normal routines;
only the up-reaching *trigger* becomes an exception.

### 4. Repaint after an edit — override (virtual hook)

This is the largest edge: low-level edits call up into the presentation layer to
refresh — `redraw` (40 sites), `updbut` (119), `chktar` (17), `dispwin` (16),
`dispcell` (15). A figure or database change in `icdfig`/`icddb` must not name
`icdwin`/`icdbut`.

`icddb`/`icdfig` declare virtual no-op hooks and call *those*; `icdwin`/`icdbut`
override them to repaint. The low module never mentions the high one — this is
the clean "loop back to the top":

```pascal
{ icdfig: declare the hook, default does nothing }
virtual procedure figurechanged(r: region); begin end;

{ ...any edit... }
attwire(a, b); figurechanged(bound);   { was: ... ; chktar; redraw }

{ icdwin: override to repaint (must be a different module) }
override procedure figurechanged(r: region);
begin inherited figurechanged(r); rregion(r.s.x, r.s.y, r.e.x, r.e.y) end;
```

For button state specifically, the edit layer sets `button[b].act` (data) and
raises a `buttonchanged(b)` hook that `icdbut` overrides with `updbut(b)`. The
119 direct `updbut` calls collapse to state-changes plus one hook.

### 5. Figure drawer to mode-specific renderers — override

`drwfig` (in `icdfig`) draws `ttrc` / `tatrc` entries by calling `dtrace` /
`atrace`, which are simulate-mode code (higher). Low calling high again.

`icdfig` declares `virtual procedure drawspecial(d: drwptr; r: region)` (empty),
and `drwfig` calls it for the trace figure types. `icdsim` overrides
`drawspecial` to render the waveforms. Layout/schema modes simply never
override it, so those figure types draw as nothing outside simulate — which is
the correct behavior and removes `drwfig`'s knowledge of simulate entirely.

### 6. The mode hierarchy — override, not dependency (the organic one)

`curscm` and `button[b<mode>].act` are tested at ~203 sites to branch on
Symbol / Schematic / Layout / Simulate. This is not a dependency to be layered;
it is a type hierarchy expressed as data. It is the case the call tree cannot
derive — the functional grouping you flagged.

The shape: a base `icdedit` module declares the per-mode operations `virtual`
(the menu set, the sheet selection, the layer/figure semantics), and
`icdschema` / `icdlayout` / `icdsim` are override modules — one per mode — that
`extends`-style override the pieces that differ. `setschema` / `setlayout` /
`setsimulate` become the act of selecting which override set is live (today
they already differ only in `dmenu`/`dispcell` vs `dispwin`). The 203
`curscm` tests dissolve into dynamic dispatch:

```pascal
{ icdedit } virtual procedure buildmenu; begin { common buttons } end;
{ icdlayout } override procedure buildmenu;
begin inherited buildmenu; { add Met1/Met2/Poly/Via/... layer buttons } end;
```

Once Pascal-P6 grows classes, the mode set is more naturally an object family
than override modules; until then, override modules are the available idiom and
map cleanly. This is the last and largest step — do it after the mechanical
layers are separated, because it is judgment, not extraction.

## The `icddef` end-state: dissolve the shared state

`icddef` today is both the type leaf (good) and a bag of ~100 globals
(`curwin`, `button[]`, `screen`, `puck`, the sheet/database roots, ...). Shared
mutable globals are the thing that makes every layer depend on every layer, so
the final move is to migrate each global into the module that owns it —
`screen`/`curwin` into `icdwin`, `button[]` into `icdbut`, `puck` into the input
handling, the sheet/db roots into `icddb` — reached by others through that
module's procedures rather than by direct global access. What remains in
`icddef` is only the genuinely shared *types* (`point`, `region`, `color`,
`viewport`, `drwptr`, `buttyp`, ...), which is a proper leaf. This is a large
lift and comes last; it is what turns the layering from "legal" into "enforced".

## Sequencing (incremental, no flag day)

1. **Carve leaves first.** `icddraw` and `icdview` have only downward calls
   already; split them out with `joins`, qualify their call sites. `icderr` is
   a trivial new leaf holding the exception vars.
2. **Convert the two cheap back-edges** while carving: termination (#1) to
   `halt`, and parse errors (#2) to `icderr` exceptions. Both are local and
   remove code.
3. **Split `icdfig` / `icddb`**, introducing the `figurechanged` /
   `buttonchanged` / `drawspecial` virtual hooks (#4, #5) at the seam. The
   overrides stay temporarily in whatever module still holds the window code.
4. **Split `icdbut` / `icdwin` / `icdtarg`**, moving the overrides in.
5. **Split `icdfile` / `icdprint`** as side branches off `icdedit`.
6. **Last: the mode hierarchy (#6)** — extract `icdedit` and the three mode
   override modules, dissolving the `curscm` tests.
7. **Ongoing: dissolve `icddef` globals** into their owning modules as each
   layer stabilizes.

Each step leaves the program building and running; the single `icdui` module
shrinks as modules peel off the bottom and the sides.

## Pascaline idioms used here

- **Exception**: `var e: exception;` in a module both parties see (`icderr`,
  or program-wide via `halt`); `throw(e)` at the deep site; `try S on e except
  H end` at the catch. Exceptions do not cross process/monitor boundaries, so
  all of the above stays within the single-task program.
- **Override**: a low module declares `virtual procedure h;` (default may be a
  no-op or `throw(notimplemented)`); a *different, higher* module declares
  `override procedure h;` and may call `inherited h`. The virtual must be
  external to the overriding module and both live at module outer level. This
  is the mechanism that lets control return to the top without an upward
  `joins`.
- **`joins` + qualident**: `joins icdwin;` then `icdwin.redraw` — qualified,
  collision-free, and self-documenting about which layer a call crosses into.

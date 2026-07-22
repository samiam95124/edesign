# ICD → Pascaline port: conversion specification

Target: Pascal-P6 / Pascaline with the `graphics` library module
(`~/projects/pascal/pascal-p6/libs/graphics.pas`). The port lives in
`icd/pascaline/`. Sources being ported are in `icd/` (lowercase filenames).

## Module structure

- `icddef.pas` — module: all types and shared globals (port of `define.pas`
  + the `var` section of `common.pas`).
- `icdui.pas` — module: the graphics/windowing layer (ported from
  `icdb.pas` plus the UI parts of `icda.pas` and `icdc.pas`), built on a
  small hand-written adapter ("base layer") over `graphics`.
- `icd.pas` — demo main program: window + buttons + grid + rubber-band
  drawing + event loop.

`icdui.pas` begins with `joins graphics; uses icddef;`. All calls into the
library are qualified: `graphics.line(...)`, `graphics.frect(...)`, etc.
This lets ICD keep its own `line`, `block`, `frame`, `color`, `arc` names.

## Language conversions

1. Delete `integer = longint;` and `real = double;` redefinitions.
2. Delete ALL `external` / `cexternal` declarations. Cross-module
   visibility comes from `uses icddef` / being in the same module.
3. `private` is supported: public procedures are declared
   `procedure x(...); forward;` before the `private` divider; bodies come
   after it with the parameter list repeated. For the first port pass, DO
   NOT use private — everything public. (We can tighten later.)
4. Identifiers that are Pascaline reserved words must be renamed with a
   trailing `_`: watch for `out`, `view`, `result`, `class`, `fixed`,
   `property`, `process`, `monitor`, `share`, `overload`, `override`,
   `static`, `virtual`, `self`, `is`, `xor`, `try`, `except`, `on`,
   `operator`, `start`, `task`, `atom`, `channel`, `stream`, `extends`,
   `inherited`, `joins`, `reference`, `module`, `uses`.
5. Keep formatting/comment style of the original code.
6. `otherwise` in case statements (SVS) → `else` (Pascaline).
7. `{$...}` SVS compiler directives: delete.

## Base layer (hand-written, already present in icdui.pas)

Fragments call ONLY these for physical output; never call graphics.*
directly except through them (exception: text metrics helpers may be added
if needed following the same pattern).

    procedure setfcolor(c: color);            { ICD 16-color -> RGB }
    procedure scrsetpix(x, y: integer; c: color);
    procedure scrline(x1, y1, x2, y2: integer; c: color);
    procedure scrblock(x1, y1, x2, y2: integer; c: color);
    procedure xormode;                        { enter xor draw mode }
    procedure ovrmode;                        { return to overwrite mode }
    procedure plchr(x, y: integer; ch: char; c: color);
    function  chrwidth(ch: char): integer;    { replaces alphal[] }
    function  strwidth(view s: butstr; l: btsinx): integer;
    function  chrheight: integer;             { replaces constant 16 }

Globals `scnmaxx`, `scnmaxy` replace the old `maxx`, `maxy` queries.

## Hardware-replacement rules

1. `getpix` DOES NOT EXIST. Any save-under logic (linesav/linerst,
   boxsav/boxrst, arcsavc/arcrstc, cursav buffers) is replaced by xor
   rubber-banding: the `setX` draw routine draws the figure in xor mode
   (`xormode` ... draw ... `ovrmode`), and the matching `resX` routine
   draws the IDENTICAL figure in xor mode again to remove it. Delete the
   save buffers, indices and `linarr` parameters. The set/res pairing and
   the `Xdwn` flags in icddef are kept unchanged.
2. `setpix(vp, x, y, c)` (viewport version) keeps its per-viewport clip
   test (`vp.c`) and coordinate transform, then calls `scrsetpix`.
3. The assembly `line`, `linesav`, `linerst`, `block`, `setchr` (viewport
   versions) are reimplemented in Pascal: transform endpoints with the
   existing viewx/viewy math, clip with the existing Cohen–Sutherland
   `clip`, then call `scrline` / `scrblock`. Reference implementations
   exist in `icd/video/drawa.pas` — port those, replacing `rsetpix` with
   `scrsetpix` etc.
4. `setchr`/`plcchr`/`plcstr`: replace the 16x16 bitmap font with
   `plchr`/`chrwidth`/`strwidth`. Where the code reads `alphal[ord(ch)]`
   use `chrwidth(ch)`; the constant 16 for character height/width cells
   becomes `chrheight`/`chrwidth`. Kill `vchar`'s bitmap path but keep the
   stroked/rotated vector char logic (it draws through `liner`, which
   survives).
5. Keyboard/pointer/timer externals (`kbdrdy`, `kbdinp`, `gettim`,
   `updptr`, serial aux routines) are deleted. The event loop in the main
   program replaces them. `gettim`/`elapsed`/`wait` port to
   `graphics.timer`-based logic in the main program only; inside icdui any
   `wait()` calls are deleted or commented `{ port: wait removed }`.
6. Printer code (`pagprt`, `strprt`, `outbuf`, prtarr users) is NOT ported
   in this pass — omit, marking `{ port: printer pass deferred }`.

## Semantics that do NOT change

The viewport records and their rational scale math (`viewc`, `realc`,
`scndist`, `realdist`, `viewx`, `viewy`), region/point types, the button
record layout and state machine, the autoarranger algorithms, snap logic,
zoom/pan math, and all display-list logic port verbatim.

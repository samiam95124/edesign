# ICD `.cel` cell file format

No written specification of the `.cel` format ever existed; the format was
defined only by the read/write code. This document is reconstructed from the
writer (`savecell` / `wrtsht` / `wrtfigs` in `icdui.pas`, ported verbatim from
the original `icda.pas`), which is authoritative, and cross-checked against the
reader (`loadcell` / `readsht` / `readfigs`). It describes the format the
program actually reads and writes.

Byte offsets are not fixed — the format is a marker-delimited, length-counted
byte stream, parsed sequentially.

## Primitive encodings

### byte
A single 8-bit unsigned byte (`writebyt`/`readbyt`). In the original SVS
sources the file was `file of boolean` with a `convert` hack; the port uses
`file of byte`. The bytes on disk are identical.

### int32 — 32-bit big-endian sign-magnitude
Written by `write32`, four bytes, most-significant first. The sign is the top
bit of the **high** byte (0x80 = negative); the remaining 31 bits are the
magnitude:

```
byte0 = (|v| div 2^24) + (v<0 ? 128 : 0)     { 7-bit high magnitude + sign }
byte1 =  (|v| div 2^16) mod 256
byte2 =  (|v| div 2^8)  mod 256
byte3 =   |v|           mod 256
```

This is **not** two's complement. `-5` encodes as `80 00 00 05`. The magnitude
occupies 31 bits, so the representable range is `-(2^31-1) .. 2^31-1`.

### counted name
Object names (cells, nodes, buses) are at most 8 characters (`butlen`). Trailing
spaces are stripped on write. Encoded as:

```
count : byte            { number of non-space characters, 0..8 }
chars : count × byte    { the characters (ASCII) }
```

A `count` of **0** doubles as the terminator for name lists (see below).

## Enumerated codes (on-disk values are the ordinals)

### Section markers (`celseg`)
| Value | Name       | Meaning                         |
|------:|------------|---------------------------------|
| 0     | `ccfterm`  | file terminator                 |
| 1     | `ccterm`   | cell terminator                 |
| 2     | `cceldir`  | cell directory follows          |
| 3     | `ccell`    | a cell follows                  |
| 4     | `ccschema` | schematic sheet section         |
| 5     | `cclayout` | layout sheet section            |
| 6     | `ccwave`   | waveform section (never written)|
| 7     | `ccsymbol` | symbol sheet section            |

### Figure type (`figtyp`) — first byte of every figure record
| 0 `tend` (list end) | 1 `tline` | 2 `tbox` | 3 `tarc` | 4 `tchar` | 5 `twire` | 6 `tbus` | 7 `tjunction` |
|---|---|---|---|---|---|---|---|
| 8 `tbline` | 9 `tbbox` | 10 `tcell` | 11 `tconnect` | 12 `tnmos` | 13 `tpmos` | 14 `tcap` | 15 `tres` |
| 16 `tdiode` | 17 `tvdd` | 18 `tvss` | 19 `tmet1` | 20 `tmet2` | 21 `tpoly` | 22 `tvia` | 23 `tndiff` |
| 24 `tpdiff` | 25 `tnwell` | 26 `tpwell` | 27 `tccut` | 28 `tinter` | 29 `tcont` | 30 `ttrc` | 31 `tatrc` |

### Layer (`laytyp`)
| 0 `ltcell` | 1 `ltfig` | 2 `ltovg` | 3 `ltvia` | 4 `ltism2` | 5 `ltism1` | 6 `ltisply` | 7 `ltmet2` | 8 `ltcont` | 9 `ltpmd` | 10 `ltwell` |
|---|---|---|---|---|---|---|---|---|---|---|

### Rotation (`rotmod`)
| 0 `rm0` | 1 `rm90` | 2 `rm180` | 3 `rm270` | 4 `rmm0` | 5 `rmm90` | 6 `rmm180` | 7 `rmm270` |
|---|---|---|---|---|---|---|---|

`rm*` are rotations; `rmm*` are mirrored rotations (0/90/180/270 degrees).

### Cell reference type (`celtyp`)
| 0 `ctsch` | 1 `ctsym` | 2 `ctlay` |
|---|---|---|

### Color (`color`) — only stored for `tinter` figures
| 0 black | 1 blue | 2 green | 3 cyan | 4 red | 5 magenta | 6 brown | 7 dwhite |
|---|---|---|---|---|---|---|---|
| 8 gray | 9 lblue | 10 lgreen | 11 lcyan | 12 lred | 13 lmagenta | 14 yellow | 15 white |

Every other figure's display color is **derived from its layer/type at load
time** (by `drwfig`) and is not stored in the file.

## File structure

```
file        := signature cceldir directory ccell-list ccfterm
signature   := 'M' 'C' 'F'            { 0x4D 0x43 0x46 }
cceldir     := byte(2)                { the cceldir marker }
directory   := { name } byte(0)       { one counted name per cell, then 0 }
ccell-list  := { cell } 
cell        := byte(3)                { ccell marker }
               [ byte(4) sheet ]      { ccschema + schematic sheet, if present }
               [ byte(7) sheet ]      { ccsymbol + symbol sheet, if present }
               [ byte(5) sheet ]      { cclayout + layout sheet, if present }
               byte(1)                { ccterm }
```

Notes:
- The **cell directory** lists the names of all cells in the file, in order,
  each as a counted name, terminated by a zero count byte.
- Each **cell** then appears in the same order, introduced by `ccell`. Its
  schematic, symbol, and layout sheets are written **only if present**, each
  introduced by its section marker; a cell ends with `ccterm`.
- The order of sections within a cell is always schematic, symbol, layout.
- `ccwave` (simulate/waveform) is defined but **never written** by `savecell`;
  the simulate sheet is not persisted.
- The file ends with `ccfterm`.

## Sheet structure (`wrtsht`)

```
sheet       := bbox nodelist buslist figures
bbox        := byte(bs)  int32(bbsx) int32(bbex) int32(bbsy) int32(bbey)
               byte(sbs) int32(sbbsx) int32(sbbex) int32(sbbsy) int32(sbbey)
nodelist    := { node } byte(0)
node        := name byte(nord) byte(tmp)
buslist     := { bus } byte(0)
bus         := name byte(tmp) byte(nodecount) { int32(nodenum) }
figures     := 11 × figurelist   { in the fixed layer order below }
```

- `bs`, `sbs`, `tmp` are booleans written as a byte (0 or 1). `bs`/`sbs` flag
  whether the drawing / symbol bounding box is valid; `bbsx..bbey` and
  `sbbsx..sbbey` are the box corners.
- A **node** has a name, an ordinal byte (`nord`), and a temp flag.
- A **bus** has a name, a temp flag, a node count byte, then that many `int32`
  node references (1-based indices into this sheet's node list — see
  References).
- Node and bus lists are terminated by a **zero name-count byte** (an entry
  with an empty name). Temp objects always have generated non-empty names, so
  this is unambiguous.
- The **11 figure lists** are written in this exact order (note it is *not* the
  `laytyp` enum order — the reader must match it):

  1. `ltcell` (0) 2. `ltfig` (1) 3. `ltovg` (2) 4. `ltvia` (3) 5. `ltmet2` (7)
  6. `ltcont` (8) 7. `ltpmd` (9) 8. `ltwell` (10) 9. `ltism2` (4)
  10. `ltism1` (5) 11. `ltisply` (6)

## Figure lists (`wrtfigs`)

Each figure list is a sequence of figure records terminated by a `tend` byte
(0). Every record starts with a `figtyp` byte, followed by type-specific
fields:

| figtyp | Fields (in order) |
|---|---|
| `tline`, `tbline` | int32 ×4: start x,y, end x,y |
| `twire` | int32 ×4: start x,y, end x,y; int32: node number |
| `tbus` | int32 ×4: start x,y, end x,y; int32: bus number |
| `tbox`, `tbbox`, `tmet1`, `tmet2`, `tpoly`, `tvia`, `tndiff`, `tpdiff`, `tnwell`, `tpwell`, `tccut`, `tcont` | int32 ×4: box start x,y, end x,y |
| `tinter` | int32 ×4: region; byte: color; byte: top figtyp; byte: top layer; int32: top figure number; byte: bottom figtyp; byte: bottom layer; int32: bottom figure number |
| `tarc` | int32 ×7: start x,y, end x,y, center x,y, radius |
| `tchar` | int32 ×4: enclosure box; byte: char count; count × byte: characters; int32: scale; byte: rotation |
| `tjunction`, `tconnect` | int32 ×2: center x,y; int32: node number |
| `tcell` | int32 ×2: origin x,y; int32: cell number; byte: cell type (`celtyp`); byte: rotation (`rotmod`) |
| `tnmos`, `tpmos`, `tcap`, `tres`, `tdiode`, `tvdd`, `tvss` | int32 ×2: origin x,y; byte: rotation (`rotmod`) |

All coordinates are ICD "virtual pixel" integer units (the real-space grid;
see `pixsiz`, `scalem` in the sources). Box/line corners are stored as written,
not normalized.

## References (1-based indices)

Where a figure or bus refers to another object, it stores a **1-based index**,
counted by position in the relevant list (`nodenum`, `busnum`, `celnum`,
`fignum`):

- **node number** — position of the node in the sheet's node list.
- **bus number** — position of the bus in the sheet's bus list.
- **cell number** — position of the referenced cell in the file's cell list
  (`cellst`), matched against its schematic/symbol/layout sheet.
- **figure number** — `fignum` returns a `(layer, index)` pair: it scans the
  sheet's layers in `laytyp` order (`ltcell` first) and returns the first layer
  containing the figure plus its 1-based position within that layer's list.
  `tinter` uses this to reference the two figures it bridges.

## Caveats (found during the port)

- **Color is not stored** except for `tinter`. Reloaded figures are recolored
  from their layer, so hand-set colors on schematic figures do not survive a
  save/load.
- **Layer write order** in a sheet differs from the `laytyp` enum order (list
  above); a reader must use the write order, while `fignum` uses the enum order
  for its indices — these are deliberately different and both must be honored.
- **`loadlib` disagreed with `readsht`/`wrtsht`**: the original library loader
  skipped only 8 figure lists per sheet while the sheet reader/writer handle 11
  (the sources were frozen mid-refactor). The port aligned `loadlib` to 11;
  files written by an older tool that emitted 8 will not load correctly.
- **`cif2cel` is a separate, unported SVS tool** whose output the CIF docs call
  an "ICD/.ICD" file. Its exact byte layout has **not** been verified against
  this `readsht`; confirm agreement before trusting CIF→CEL round-trips.
- The **simulate sheet is not persisted** (`ccwave` is never written).
- `int32` is sign-magnitude, so a value could in principle encode as negative
  zero (`80 00 00 00`); the writer never produces it (it sets sign 0 for
  `i >= 0`), and the reader treats it as 0.

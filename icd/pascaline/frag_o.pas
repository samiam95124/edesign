{***************************************************************

FRAGMENT O: cell file load/save and the file/cell/library
dialogs, ported from icda.pas (1992), readbyt through dolibs
(the remainder of that file; fndbnd was already ported in
frag_e.pas).

Ported per PORTING-SPEC.md. Contains the byte file primitives
(readbyt/writebyt/read32/write32), the cell file reader
(readfigs/readsht/loadcell), the cell file writer
(savecell/wrtsht/wrtfigs), the files/cells/libraries dialogs
(fillst/lstfmt/dspfils/files/chkfile/dofiles, displayc/chkcell/
docells, displayl/chklcell/dolibs) and the library loader
(loadlib).

port notes:

- bytfil is now a true byte file (see icddef.pas); the SVS
  boolean-file "convert" cexternal hack is gone. readbyt and
  writebyt are plain typed-file transfers; read32/write32 keep
  their multi-byte packing logic (the cell file format is
  unchanged).
- SVS reset(f, name)/rewrite(f, name)/close(f, lock) become
  Pascaline assign(f, name); reset/rewrite(f); close(f). The
  SVS counted string[12] filename build becomes a space padded
  fixed array (assign ignores trailing spaces).
- getlst (DOS intdos directory search) is replaced in fillst by
  the services library directory lister (services.list), called
  qualified. The module header needs "joins services;" (the
  integrator adds it to icdui_mod.pas).
- The dialog grids were laid out in 16 pixel character cells and
  128 pixel (8 cell) columns; per the port's density scaling
  convention these scale through chrheight (the 16px cell) as
  the button layers do through uiscl.
- The no-op stubs for doloadc/dosavec/dofiles/docells/dolibs in
  icdui_base.pas are superseded by the full ports below; the
  integrator removes the stubs.

***************************************************************}
{}
{**************************************************************

READ BYTE FROM A FILE

Reads a byte with values 0..255 from the given file.
port: was required because SVS did not accept file of byte;
kept as the byte transfer primitive of the cell file layer.

**************************************************************}

procedure readbyt(var f: bytfil; var b: byte);

begin

   read(f, b) { get byte }

end;
{}
{**************************************************************

WRITE BYTE TO A FILE

Writes a byte with values 0..255 to the given file.
port: the boolean "convert" cexternal hack is gone; plain
typed file write.

**************************************************************}

procedure writebyt(var f: bytfil; b: byte);

begin

   write(f, b) { output }

end;
{}
{**************************************************************

READ 32 BIT NUMBER FROM FILE

Reads a 32 bit number from the given file. The highest order
byte appears first, and the least order last.
The high byte 7th bit contains the sign.
NOTE: on SVS pascal, subrange types are not expanded to
integer on read (a violation of the standard). The fix for this
is still compatible with ISO.

**************************************************************}

procedure read32(var f: bytfil; var i: integer);

var b: byte;    { read byte holder }
    s: integer; { sign of result }
    t: integer; { temp }

begin

   s := 1; { set no sign }
   readbyt(f, b);
   if b >= 128 then begin { signed }

      s := -1; { set sign }
      b := b - 128 { remove sign }

   end;
   t := b; { place in large buffer }
   i := t*16777216;
   readbyt(f, b);
   t := b; { place in large buffer }
   i := i + t*65536;
   readbyt(f, b);
   t := b; { place in large buffer }
   i := i + t*256;
   readbyt(f, b);
   i := i + b;
   i := i*s { set sign of result }

end;
{}
{**************************************************************

WRITE 32 BIT NUMBER TO FILE

Writes a 32 bit number to the given file. The highest order
byte appears first, and the least order last.
The high byte 7th bit contains the sign.

**************************************************************}

procedure write32(var f: bytfil; i: integer);

var t, s: integer;

begin

   { set sign }
   if i < 0 then s := 128 else s := 0;
   i := abs(i); { remove sign }
   t := i div 16777216; { high byte }
   writebyt(f, t+s); { with sign }
   i := i - (t * 16777216); { high middle }
   t := i div 65536;
   writebyt(f, t);
   i := i - (t * 65536); { low middle }
   t := i div 256;
   writebyt(f, t);
   i := i - (t * 256); { low }
   writebyt(f, i)

end;
{}
{**************************************************************

READ FIGURES FROM FILE

Reads a list of draw figures from the given file.

**************************************************************}

procedure readfigs(var f: bytfil; var p: drwptr; sp: shtptr);

var sl:    drwptr; { figure holder }
    b:     byte;   { byte holder }
    c, c1: byte;   { character count }
    ch:    chrptr; { character pointer }
    n:     integer;
    t:     figtyp; { type holder }

{ read rotation mode }

procedure readrot(var rm: rotmod);

var b: byte;

begin

   readbyt(f, b); { get rotation mode }
   case b of { rotation }

      0: rm := rm0;    { 0 deg }
      1: rm := rm90;   { 90 deg }
      2: rm := rm180;  { 180 deg }
      3: rm := rm270;  { 270 deg }
      4: rm := rmm0;   { 0 deg mirrored }
      5: rm := rmm90;  { 90 deg mirrored }
      6: rm := rmm180; { 180 deg mirrored }
      7: rm := rmm270  { 270 deg mirrored }

   end

end;

{ read color }

procedure readclr(var c: color);

var b: byte;

begin

   readbyt(f, b); { get color }
   case b of { color }

      0:  c := black;
      1:  c := blue;
      2:  c := green;
      3:  c := cyan;
      4:  c := red;
      5:  c := magenta;
      6:  c := brown;
      7:  c := dwhite;
      8:  c := gray;
      9:  c := lblue;
      10: c := lgreen;
      11: c := lcyan;
      12: c := lred;
      13: c := lmagenta;
      14: c := yellow;
      15: c := white

   end

end;

{ read type }

procedure readtyp(var t: figtyp);

var b: byte;

begin

   readbyt(f, b); { get type }
   case b of { type }

      0:  t := tend;
      1:  t := tline;
      2:  t := tbox;
      3:  t := tarc;
      4:  t := tchar;
      5:  t := twire;
      6:  t := tbus;
      7:  t := tjunction;
      8:  t := tbline;
      9:  t := tbbox;
      10: t := tcell;
      11: t := tconnect;
      12: t := tnmos;
      13: t := tpmos;
      14: t := tcap;
      15: t := tres;
      16: t := tdiode;
      17: t := tvdd;
      18: t := tvss;
      19: t := tmet1;
      20: t := tmet2;
      21: t := tpoly;
      22: t := tvia;
      23: t := tndiff;
      24: t := tpdiff;
      25: t := tnwell;
      26: t := tpwell;
      27: t := tccut;
      28: t := tinter;
      29: t := tcont

   end

end;

{ attach figure to node }

procedure fignode(p: drwptr; n: integer; sp: shtptr);

var np: nodptr;

begin

   np := sp^.nl; { index node list }
   while n <> 1 do begin { traverse }

      n := n - 1; { count }
      np := np^.next { next entry }

   end;
   p^.nh := np; { set node head }
   p^.nl := np^.nl; { place in node list }
   np^.nl := p

end;

{ attach figure to bus }

procedure figbus(p: drwptr; n: integer; sp: shtptr);

var bp: busptr;

begin

   bp := sp^.bl; { index bus list }
   while n <> 1 do begin { traverse }

      n := n - 1; { count }
      bp := bp^.next { next entry }

   end;
   p^.bs.bh := bp; { set bus head }
   p^.bs.bl := bp^.bl; { place in bus list }
   bp^.bl := p

end;

{ link cell from cell number }

procedure lnkcel(n: integer; var sp: shtptr; ct: celtyp);

var cp:      celptr;       { cell pointer }

begin

   cp := cellst; { index 1st cell }
   { find that cell }
   while n <> 1 do begin cp := cp^.next; n := n - 1 end;
   if ct = ctsch then begin { schematic cell }

      { make sure that schematic sheet exists }
      if cp^.schema = nil then new(cp^.schema);
      sp := cp^.schema { place that link }

   end else if ct = ctsym then begin { symbol cell }

      { make sure that symbol sheet exists }
      if cp^.symbol = nil then new(cp^.symbol);
      sp := cp^.symbol { place that link }

   end else if ct = ctlay then begin { layout cell }

      { make sure that layout sheet exists }
      if cp^.layout = nil then new(cp^.layout);
      sp := cp^.layout { place that link }

   end

end;

{  link figure from layer, figure number }

procedure lnkfig(ln, fn: integer; sp: shtptr; var p: drwptr);

begin

   { index top of list }
   case ln of { layer }

      0:  p := sp^.dl[ltcell];  { layer 0 }
      1:  p := sp^.dl[ltfig];   { layer 1 }
      2:  p := sp^.dl[ltovg];   { layer 2 }
      3:  p := sp^.dl[ltvia];   { layer 3 }
      4:  p := sp^.dl[ltism2];  { layer 4 }
      5:  p := sp^.dl[ltism1];  { layer 5 }
      6:  p := sp^.dl[ltisply]; { layer 6 }
      7:  p := sp^.dl[ltmet2];  { layer 7 }
      8:  p := sp^.dl[ltcont];  { layer 8 }
      9:  p := sp^.dl[ltpmd];   { layer 9 }
      10: p := sp^.dl[ltwell]   { layer 10 }

   end;
   while fn <> 1 do begin { traverse }

      fn := fn - 1; { count }
      p := p^.next { next entry }

   end

end;

begin

   sl := nil; { clear last entry }
   readtyp(t); { get figure type }
   while t <> tend do begin { read figures }

      { create new entry at end }
      if sl = nil then begin new(p); sl := p end
      else begin new(sl^.next); sl := sl^.next end;
      sl^.next := nil; { clear next }
      sl^.typ := t; { set type }
      case sl^.typ of { figure }

         tline: begin { line }

            sl^.typ := tline; { set type }
            read32(f, sl^.l.s.x); { starting }
            read32(f, sl^.l.s.y);
            read32(f, sl^.l.e.x); { ending }
            read32(f, sl^.l.e.y);
            sl^.cl := black { set color }

         end;

         tbox: begin { box }

            sl^.typ := tbox; { set type }
            read32(f, sl^.b.s.x); { starting }
            read32(f, sl^.b.s.y);
            read32(f, sl^.b.e.x); { ending }
            read32(f, sl^.b.e.y);
            sl^.cl := black { set color }

         end;

         tarc: begin { arc or circle }

            sl^.typ := tarc; { set type }
            read32(f, sl^.a.s.x); { starting }
            read32(f, sl^.a.s.y);
            read32(f, sl^.a.e.x); { ending }
            read32(f, sl^.a.e.y);
            read32(f, sl^.a.c.x); { center }
            read32(f, sl^.a.c.y);
            read32(f, sl^.a.r);  { radius }
            sl^.cl := black { set color }

         end;

         tchar: begin { char }

            sl^.typ := tchar; { set type }
            read32(f, sl^.c.r.s.x);   { origin }
            read32(f, sl^.c.r.s.y);
            read32(f, sl^.c.r.e.x);
            read32(f, sl^.c.r.e.y);
            sl^.c.l := nil; { clear character string }
            readbyt(f, c); { get character count }
            for c1 := 1 to c do begin { read string }

               readbyt(f, b); { get a character }
               if sl^.c.l = nil then begin { first character }

                  new(sl^.c.l); { get an entry }
                  ch := sl^.c.l { index }

               end else begin { mid character }

                  new(ch^.next); { get an entry }
                  ch := ch^.next { index }

               end;
               ch^.next := nil; { terminate string }
               ch^.c := chr(b); { place character }

            end;
            read32(f, sl^.c.s); { scale }
            readrot(sl^.rm); { get rotation }
            sl^.cl := black { set color }

         end;

         twire: begin { wire }

            sl^.typ := twire; { set type }
            read32(f, sl^.w.s.x); { starting }
            read32(f, sl^.w.s.y);
            read32(f, sl^.w.e.x); { ending }
            read32(f, sl^.w.e.y);
            read32(f, n); { node number }
            fignode(sl, n, sp); { link to node }
            sl^.cl := black { set color }

         end;

         tbus: begin { bus }

            sl^.typ := tbus; { set type }
            read32(f, sl^.bs.l.s.x); { starting }
            read32(f, sl^.bs.l.s.y);
            read32(f, sl^.bs.l.e.x); { ending }
            read32(f, sl^.bs.l.e.y);
            read32(f, n); { bus number }
            figbus(sl, n, sp); { link to bus }
            sl^.cl := black { set color }

         end;

         tjunction: begin { junction }

            sl^.typ := tjunction; { set type }
            read32(f, sl^.j.x); { center }
            read32(f, sl^.j.y);
            read32(f, n); { node number }
            fignode(sl, n, sp); { link to node }
            sl^.cl := black { set color }

         end;

         tconnect: begin { connector }

            sl^.typ := tconnect; { set type }
            read32(f, sl^.j.x); { center }
            read32(f, sl^.j.y);
            read32(f, n); { node number }
            fignode(sl, n, sp); { link to node }
            sl^.cl := black { set color }

         end;

         tbline: begin { bold line }

            sl^.typ := tbline; { set type }
            read32(f, sl^.l.s.x); { starting }
            read32(f, sl^.l.s.y);
            read32(f, sl^.l.e.x); { ending }
            read32(f, sl^.l.e.y);
            sl^.cl := black { set color }

         end;

         tbbox: begin { bold box }

            sl^.typ := tbbox; { set type }
            read32(f, sl^.b.s.x); { starting }
            read32(f, sl^.b.s.y);
            read32(f, sl^.b.e.x); { ending }
            read32(f, sl^.b.e.y);
            sl^.cl := black { set color }

         end;

         tcell: begin { subcell }

            sl^.typ := tcell; { set type }
            read32(f, sl^.cr.o.x); { read origin }
            read32(f, sl^.cr.o.y);
            read32(f, n); { read cell number }
            readbyt(f, b); { get cell type }
            case b of { cell type }

               0: sl^.cr.ct := ctsch; { schematic }
               1: sl^.cr.ct := ctsym; { symbol }
               2: sl^.cr.ct := ctlay  { layout }

            end;
            { find the corresponding cell }
            lnkcel(n, sl^.cr.cp, sl^.cr.ct);
            readrot(sl^.rm); { get rotation mode }
            sl^.cl := black { set color }

         end;

         tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss: begin

            { predefined cell }
            { port: the original re-derived the type here with
              "case b of 12: sl^.typ := tnmos; ..." - but b is
              stale (readtyp reads into its own local); the type
              was already placed from t above, so the case is
              deleted (under P6 an unmatched case is an error) }
            read32(f, sl^.o.x); { read origin }
            read32(f, sl^.o.y);
            readrot(sl^.rm); { get rotation mode }
            sl^.cl := black { set color }

         end;

         tmet1, tmet2, tpoly, tvia, tndiff, tpdiff, tnwell,
         tpwell, tccut, tcont: begin

            case sl^.typ of { type }

               tmet1:  sl^.cl := lblue;
               tmet2:  sl^.cl := lcyan;
               tpoly:  sl^.cl := lred;
               tvia:   sl^.cl := gray;
               tndiff: sl^.cl := green;
               tpdiff: sl^.cl := magenta;
               tnwell: sl^.cl := yellow;
               tpwell: sl^.cl := brown;
               tccut:  sl^.cl := dwhite;
               tcont:  sl^.cl := black

            end;
            read32(f, sl^.b.s.x); { starting }
            read32(f, sl^.b.s.y);
            read32(f, sl^.b.e.x); { ending }
            read32(f, sl^.b.e.y)

         end;

         tinter: begin

            sl^.typ := tinter;
            read32(f, sl^.ir.s.x); { starting }
            read32(f, sl^.ir.s.y);
            read32(f, sl^.ir.e.x); { ending }
            read32(f, sl^.ir.e.y);
            readclr(sl^.cl); { color }
            readtyp(sl^.itt); { get top layer type }
            readbyt(f, b); { get layer number of top }
            read32(f, n); { get figure number }
            lnkfig(b, n, sp, sl^.ipt); { link to figure }
            readtyp(sl^.itb); { get bottom layer type }
            readbyt(f, b); { get layer number of bottom }
            read32(f, n); { get figure number }
            lnkfig(b, n, sp, sl^.ipb) { link to figure }

         end

      end;
      readtyp(t) { get next figure type }

   end

end;
{}
{**************************************************************

READ SHEET

Reads a single sheet structure, and sets up all parameters
for the sheet, including centering the view of the sheet.

**************************************************************}

procedure readsht(var f: bytfil; sp: shtptr);

var b:  byte;
    n:  integer;
    vi: viewinx;
    si: sizeinx;
    c:  byte;    { character count }
    i:  integer; { index for filename }
                 { port: was btsinx; runs to butlen+1 }
    np: nodptr;  { node pointer }
    bp: busptr;  { bus pointer }
    li: laytyp;  { layer index }

{ attach node to bus }

procedure busnode(p: busptr; n: integer; sp: shtptr);

var np: nodptr;

begin

   np := sp^.nl; { index node list }
   while n <> 1 do begin { traverse }

      n := n - 1; { count }
      np := np^.next { next entry }

   end;
   np^.bl := p^.nl; { insert to node list }
   p^.nl := np;
   np^.bh := p { place bus head }

end;

begin

   { clear draw lists }
   for li := ltcell to ltwell do sp^.dl[li] := nil;
   sp^.nl := nil; { clear node list }
   sp^.bl := nil; { clear bus list }
   sp^.nc := 0; { clear node count }
   { input bounding box }
   readbyt(f, b); { get set/noset flag }
   sp^.bs := b <> 0; { set status }
   read32(f, sp^.bbsx);
   read32(f, sp^.bbex);
   read32(f, sp^.bbsy);
   read32(f, sp^.bbey);
   readbyt(f, b); { get set/noset flag }
   sp^.sbs := b <> 0; { set status }
   read32(f, sp^.sbbsx);
   read32(f, sp^.sbbex);
   read32(f, sp^.sbbsy);
   read32(f, sp^.sbbey);
   { read node list }
   readbyt(f, c); { read node name count }
   np := nil; { clear last node }
   while c <> 0 do begin { read nodes }

      { get a new node pointer }
      if np = nil then begin new(sp^.nl); np := sp^.nl end
      else begin new(np^.next); np := np^.next end;
      np^.next := nil; { clear next }
      np^.nl := nil; { clear node list }
      np^.sl := nil; { clear smash list }
      np^.name := '        '; { clear node name }
      i := 1; { index 1st cell character }
      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         np^.name[i] := chr(b); { place character }
         c := c - 1; { count characters }
         i := i + 1

      end;
      readbyt(f, np^.nord); { input ordinal }
      readbyt(f, b); { input temp indicator }
      np^.tmp := b <> 0; { set }
      readbyt(f, c) { read next cell name count }

   end;
   { read bus list }
   readbyt(f, c); { read bus name count }
   bp := nil; { clear last bus }
   while c <> 0 do begin { read busses }

      { get a new bus pointer }
      if bp = nil then begin new(sp^.bl); bp := sp^.bl end
      else begin new(bp^.next); bp := bp^.next end;
      bp^.next := nil; { clear next }
      bp^.nl := nil; { clear node list }
      bp^.sl := nil; { clear smash list }
      bp^.bl := nil; { clear bus list }
      bp^.name := '        '; { clear bus name }
      i := 1; { index 1st cell character }
      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         bp^.name[i] := chr(b); { place character }
         c := c - 1; { count characters }
         i := i + 1

      end;
      readbyt(f, b); { input temp indicator }
      bp^.tmp := b <> 0; { set }
      { read node list }
      readbyt(f, c); { get node count }
      while c <> 0 do begin { read bus nodes }

         read32(f, n); { get node number }
         busnode(bp, n, sp); { attach node to bus }
         c := c - 1 { count }

      end;
      readbyt(f, c) { read next cell name count }

   end;
   readfigs(f, sp^.dl[ltcell],  sp); { read cells layer }
   readfigs(f, sp^.dl[ltfig],   sp); { read comment/schema layer }
   readfigs(f, sp^.dl[ltovg],   sp); { read overglass cuts layer }
   readfigs(f, sp^.dl[ltvia],   sp); { read via layer }
   readfigs(f, sp^.dl[ltmet2],  sp); { read met2 layer }
   readfigs(f, sp^.dl[ltcont],  sp); { read contact layer }
   readfigs(f, sp^.dl[ltpmd],   sp); { read poly/metals, diff layer }
   readfigs(f, sp^.dl[ltwell],  sp); { read wells layer }
   readfigs(f, sp^.dl[ltism2],  sp); { read met 2 intersections layer }
   readfigs(f, sp^.dl[ltism1],  sp); { read met 1 intersections layer }
   readfigs(f, sp^.dl[ltisply], sp); { read poly intersections layer }
   { set up sheet parameters }
   sp^.ds := dftdg; { set default dot grid size }
   sp^.ls := dftlg; { set default line grid size }
   sp^.js := dftjun; { set default junction size }
   sp^.cs := dftcon; { set default connector size }
   sp^.ts := dftchr; { set standard character scale }
   { clear viewer array }
   for vi := 1 to viewmax do sp^.sv[vi].a := false;
   { clear text size array }
   for si := 1 to sizemax do sp^.sts[si].a := false;
   { clear dot size array }
   for si := 1 to sizemax do sp^.sds[si].a := false;
   { clear line size array }
   for si := 1 to sizemax do sp^.sls[si].a := false;
   { set view to bounding box }
   sp^.vp.v.s.x := curwin^.ar.s.x; { set viewport region }
   sp^.vp.v.s.y := curwin^.ar.s.y;
   sp^.vp.v.e.x := curwin^.ar.e.x;
   sp^.vp.v.e.y := curwin^.ar.e.y;
   fndbnd(sp, sp^.vp.r.s.x, sp^.vp.r.s.y, sp^.vp.s.x); { find bounds view }
   sp^.vp.r.e.x :=
      sp^.vp.r.s.x+realdist(abs(sp^.vp.v.e.x-sp^.vp.v.s.x)+1, sp^.vp.s.x);
   sp^.vp.r.e.y :=
      sp^.vp.r.s.y+realdist(abs(sp^.vp.v.e.y-sp^.vp.v.s.y)+1, sp^.vp.s.y);
   sp^.lvp := sp^.vp { set last view as same }

end;
{}
{**************************************************************

LOAD CELL

Loads the current cell data.

**************************************************************}

procedure loadcell;

var fn: packed array [1..12] of char; { port: was counted string[12] }
    fl: 0..12;        { port: filename length }
    i:  integer;      { index for filename }
                      { port: was btsinx; runs to butlen+1 }
    f:  bytfil;       { file }
    b:  byte;         { read holder }
    cp: celptr;       { cell pointer }
    c:  integer;      { file name count }
                      { port: was btsinx; counts down to 0 }

begin

   if button[bfname].s <> '        ' then begin

      { filename is defined }
      cellst := nil; { clear cell list }
      { create filename string }
      { port: SVS counted string build replaced by space padded
        fixed array; assign ignores trailing spaces }
      fn := '            '; { clear destination }
      fl := 0;
      for i := 1 to butlen do if button[bfname].s[i] <> ' ' then
         begin

         fl := fl + 1;
         fn[fl] := button[bfname].s[i]

      end;
      { place extention }
      fn[fl+1] := '.'; fn[fl+2] := 'c'; fn[fl+3] := 'e'; fn[fl+4] := 'l';
      assign(f, fn); { port: was reset(f, fn) }
      reset(f); { activate file }
      readbyt(f, b); { read signature }
      readbyt(f, b);
      readbyt(f, b);
      readbyt(f, b); { read cell directory mark }
      readbyt(f, b); { read cell name count }
      c := b;
      cp := nil; { clear last cell }
      while c <> 0 do begin { read cell names }

         { get a new cell pointer }
         if cp = nil then begin new(cellst); cp := cellst end
         else begin new(cp^.next); cp := cp^.next end;
         cp^.next := nil; { clear next }
         cp^.schema := nil; { clear out }
         cp^.symbol := nil;
         cp^.layout := nil;
         cp^.simulate := nil;
         cp^.name := '        '; { clear cell name }
         i := 1; { index 1st cell character }
         while c <> 0 do begin { read cell characters }

            readbyt(f, b); { get a cell character }
            cp^.name[i] := chr(b); { place character }
            c := c - 1; { count characters }
            i := i + 1

         end;
         readbyt(f, b); { read next cell name count }
         c := b

      end;
      cp := cellst; { index first cell }
      readbyt(f, b); { read section mark }
      while b = ord(ccell) do begin { read cells }

         readbyt(f, b); { read cell section mark }
         while b <> ord(ccterm) do begin { read sections }

            if b = ord(ccschema) then begin

               { schematic section }
               if cp^.schema = nil then { no previous sheet }
                  new(cp^.schema); { create schematic sheet }
               readsht(f, cp^.schema) { read that sheet }

            end else if b = ord(ccsymbol) then begin

               { symbol section }
               if cp^.symbol = nil then { no previous sheet }
                  new(cp^.symbol); { create symbol sheet }
               readsht(f, cp^.symbol) { read that sheet }

            end else if b = ord(cclayout) then begin

               { layout section }
               if cp^.layout = nil then { no previous sheet }
                  new(cp^.layout); { create layout sheet }
               readsht(f, cp^.layout) { read that sheet }

            end;
            readbyt(f, b) { get next section mark }

         end;
         cp := cp^.next; { index next cell }
         readbyt(f, b) { get next cell mark }

      end;
      close(f); { close file } { port: was close(f, lock) }
      curwin^.cc := cellst; { set current cell }
      button[bcname].s := cellst^.name; { set current cell name }
      updbut(bcname); { update button }
      dispcell { display cell }

   end

end;
{}
{**************************************************************

PERFORM LOAD CELL

Handles a load cell button push.

**************************************************************}

procedure doloadc;

begin

   if (curbut = bload) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      loadcell; { load current cell }
   resptr { reset pointer device }

end;
{}
{**************************************************************

SAVE CELL

Saves the current cell data.

**************************************************************}

procedure savecell;

var fn: packed array [1..12] of char; { port: was counted string[12] }
    fl: 0..12;      { port: filename length }
    i:  btsinx;     { index for filename }
    f:  bytfil;     { file }
    cp: celptr;     { cell pointer }
    c:  integer;    { file name count }
                    { port: was btsinx; also counts tchar strings,
                      which have no length bound, and starts at 0 }
    sp: shtptr;     { sheet pointer }

{ find number of node }

function nodenum(p: nodptr; sp: shtptr): integer;

var n: nodptr;
    c: integer;

begin

   c := 1; { clear count }
   n := sp^.nl; { index node list }
   { count nodes }
   while p <> n do begin c := c + 1; n := n^.next end;
   nodenum := c { return result }

end;

{ find number of bus }

function busnum(p: busptr; sp: shtptr): integer;

var b: busptr;
    c: integer;

begin

   c := 1; { clear count }
   b := sp^.bl; { index bus list }
   { count busses }
   while p <> b do begin c := c + 1; b := b^.next end;
   busnum := c { return result }

end;

{ find number of referenced cell }

function celnum(sp: shtptr): integer;

var cp: celptr;  { cell pointer }
    c:  integer; { count }

begin

   c := 1; { clear count }
   cp := cellst; { index top of cell list }
   while (sp <> cp^.schema) and
         (sp <> cp^.symbol) and
         (sp <> cp^.layout) do
      begin c := c + 1; cp := cp^.next end;
   celnum := c { return result }

end;

{ find numbers of referenced figure }

procedure fignum(sp: shtptr;       { base sheet }
                 fp: drwptr;       { figure to find }
                 var ln: laytyp;   { layer number index }
                 var fn: integer); { figure number }

function fndfig(p: drwptr): integer;

var c: integer; { count }

begin

   c := 1; { clear count }
   while (fp <> p) and (p <> nil) do { traverse }
      begin c := c + 1; p := p^.next end;
   if p = nil then c := 0; { set not found }
   fndfig := c { return result }

end;

begin

   ln := ltcell; { set first layer }
   repeat { search layers }

      fn := fndfig(sp^.dl[ln]); { search }
      if fn = 0 then ln := succ(ln) { next layer }

   until fn <> 0 { figure found }

end;

{ output figures }

procedure wrtfigs(sp: shtptr; sl: drwptr);

var ch: chrptr; { character pointer }
    ln: laytyp; { layer index }
    fn: integer; { layer and figure numbers }

begin

   while sl <> nil do begin { write schematic figures }

      writebyt(f, ord(sl^.typ)); { output figure type }
      case sl^.typ of { figure }

         tline, tbline: begin { line }

            write32(f, sl^.l.s.x); { starting }
            write32(f, sl^.l.s.y);
            write32(f, sl^.l.e.x); { ending }
            write32(f, sl^.l.e.y)

         end;

         twire: begin { wire }

            write32(f, sl^.w.s.x); { starting }
            write32(f, sl^.w.s.y);
            write32(f, sl^.w.e.x); { ending }
            write32(f, sl^.w.e.y);
            write32(f, nodenum(sl^.nh, sp)) { node number }

         end;

         tbus: begin { bus }

            write32(f, sl^.bs.l.s.x); { starting }
            write32(f, sl^.bs.l.s.y);
            write32(f, sl^.bs.l.e.x); { ending }
            write32(f, sl^.bs.l.e.y);
            write32(f, busnum(sl^.bs.bh, sp)) { bus number }

         end;

         tbox, tbbox, tmet1, tmet2, tpoly, tvia, tndiff,
         tpdiff, tnwell, tpwell, tccut, tcont: begin

            { box or layer }
            write32(f, sl^.b.s.x); { starting }
            write32(f, sl^.b.s.y);
            write32(f, sl^.b.e.x); { ending }
            write32(f, sl^.b.e.y)

         end;

         tinter: begin

            { intersection layer }
            write32(f, sl^.ir.s.x); { starting }
            write32(f, sl^.ir.s.y);
            write32(f, sl^.ir.e.x); { ending }
            write32(f, sl^.ir.e.y);
            writebyt(f, ord(sl^.cl)); { color }
            writebyt(f, ord(sl^.itt)); { output figure type top }
            fignum(sp, sl^.ipt, ln, fn); { find reference }
            writebyt(f, ord(ln)); { output layer number }
            write32(f, fn); { output figure number }
            writebyt(f, ord(sl^.itb)); { output figure type bottom }
            fignum(sp, sl^.ipb, ln, fn); { find reference }
            writebyt(f, ord(ln)); { output layer number }
            write32(f, fn) { output figure number }

         end;

         tarc: begin { arc or circle }

            write32(f, sl^.a.s.x); { starting }
            write32(f, sl^.a.s.y);
            write32(f, sl^.a.e.x); { ending }
            write32(f, sl^.a.e.y);
            write32(f, sl^.a.c.x); { center }
            write32(f, sl^.a.c.y);
            write32(f, sl^.a.r)   { radius }

         end;

         tchar: begin { char }

            write32(f, sl^.c.r.s.x);   { origin }
            write32(f, sl^.c.r.s.y);
            write32(f, sl^.c.r.e.x);
            write32(f, sl^.c.r.e.y);
            c := 0; { count characters }
            ch := sl^.c.l; { index top of string }
            { count }
            while ch <> nil do begin c := c + 1; ch := ch^.next end;
            writebyt(f, c); { output count }
            { output string }
            ch := sl^.c.l; { index top of string }
            while ch <> nil do begin

               writebyt(f, ord(ch^.c)); { output }
               ch := ch^.next { next }

            end;
            write32(f, sl^.c.s);    { scale }
            writebyt(f, ord(sl^.rm)) { output rotation }

         end;

         tjunction, tconnect: begin { junction }

            write32(f, sl^.j.x); { center }
            write32(f, sl^.j.y);
            write32(f, nodenum(sl^.nh, sp)) { node number }

         end;

         tcell: begin { subcell }

            write32(f, sl^.cr.o.x); { output origin }
            write32(f, sl^.cr.o.y);
            write32(f, celnum(sl^.cr.cp)); { output cell number }
            writebyt(f, ord(sl^.cr.ct)); { output cell type }
            writebyt(f, ord(sl^.rm)) { output rotation }

         end;

         tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss: begin

            { predefined cell }
            write32(f, sl^.o.x); { output origin }
            write32(f, sl^.o.y);
            writebyt(f, ord(sl^.rm)) { output rotation }

         end

      end;
      sl := sl^.next { link next entry }

   end;
   writebyt(f, 0) { terminate figure list }

end;

{ output sheet }

procedure wrtsht(sp: shtptr);

var np: nodptr; { node pointer }
    bp: busptr; { bus pointer }
    c:  byte;   { character count }
    i:  btsinx; { index for filename }

begin

   { output bounding box }
   writebyt(f, ord(sp^.bs)); { output set/unset status }
   write32(f, sp^.bbsx);
   write32(f, sp^.bbex);
   write32(f, sp^.bbsy);
   write32(f, sp^.bbey);
   writebyt(f, ord(sp^.sbs)); { output set/unset status }
   write32(f, sp^.sbbsx);
   write32(f, sp^.sbbex);
   write32(f, sp^.sbbsy);
   write32(f, sp^.sbbey);
   { output node list }
   np := sp^.nl; { index top node }
   while np <> nil do begin { output nodes }

      c := 0; { count node characters }
      for i := 1 to butlen do
         if np^.name[i] <> ' ' then c := c + 1;
      writebyt(f, c); { output }
      { output name }
      for i := 1 to butlen do
         if np^.name[i] <> ' ' then writebyt(f, ord(np^.name[i]));
      writebyt(f, np^.nord); { output ordinal }
      writebyt(f, ord(np^.tmp)); { output temp indicator }
      np := np^.next { next entry }

   end;
   writebyt(f, 0); { terminate node list }
   { output bus list }
   bp := sp^.bl; { index top bus }
   while bp <> nil do begin { output busses }

      c := 0; { count bus characters }
      for i := 1 to butlen do
         if bp^.name[i] <> ' ' then c := c + 1;
      writebyt(f, c); { output }
      { output name }
      for i := 1 to butlen do
         if bp^.name[i] <> ' ' then writebyt(f, ord(bp^.name[i]));
      writebyt(f, ord(bp^.tmp)); { output temp indicator }
      c := 0; { initalize node count }
      np := bp^.nl; { index 1st node in list }
      while np <> nil do begin { traverse }

         c := c + 1; { count nodes }
         np := np^.bl { next entry }

      end;
      writebyt(f, c); { output count }
      np := bp^.nl; { index 1st node in list }
      while np <> nil do begin { traverse }

         write32(f, nodenum(np, sp)); { node number }
         np := np^.bl { next entry }

      end;
      bp := bp^.next { next entry }

   end;
   writebyt(f, 0); { terminate bus list }
   wrtfigs(sp, sp^.dl[ltcell]); { write cell layer }
   wrtfigs(sp, sp^.dl[ltfig]);  { write comment/schema layer }
   wrtfigs(sp, sp^.dl[ltovg]);  { write overglass cuts layer }
   wrtfigs(sp, sp^.dl[ltvia]);  { write via layer }
   wrtfigs(sp, sp^.dl[ltmet2]); { write met2 layer }
   wrtfigs(sp, sp^.dl[ltcont]); { write contact layer }
   wrtfigs(sp, sp^.dl[ltpmd]);  { write poly/metals, diff layer }
   wrtfigs(sp, sp^.dl[ltwell]); { write wells layer }
   wrtfigs(sp, sp^.dl[ltism2]); { write met 2 intersections layer }
   wrtfigs(sp, sp^.dl[ltism1]); { write met 1 intersections layer }
   wrtfigs(sp, sp^.dl[ltisply]) { write poly intersections layer }

end;

begin

   if button[bfname].s <> '        ' then begin

      { filename is defined }
      { create filename string }
      { port: SVS counted string build replaced by space padded
        fixed array; assign ignores trailing spaces }
      fn := '            '; { clear destination }
      fl := 0;
      for i := 1 to butlen do if button[bfname].s[i] <> ' ' then begin

         fl := fl + 1;
         fn[fl] := button[bfname].s[i]

      end;
      { place extention }
      fn[fl+1] := '.'; fn[fl+2] := 'c'; fn[fl+3] := 'e'; fn[fl+4] := 'l';
      assign(f, fn); { port: was rewrite(f, fn) }
      rewrite(f); { activate file }
      writebyt(f, ord('M')); { write signature }
      writebyt(f, ord('C'));
      writebyt(f, ord('F'));
      writebyt(f, ord(cceldir)); { mark cell directory }
      cp := cellst; { index top of cell list }
      while cp <> nil do begin { output cell names }

         c := 0; { count cellname characters }
         for i := 1 to butlen do
            if cp^.name[i] <> ' ' then c := c + 1;
         writebyt(f, c); { output }
         { output cellname }
         for i := 1 to butlen do
            if cp^.name[i] <> ' ' then writebyt(f, ord(cp^.name[i]));
         cp := cp^.next { next cell }

      end;
      writebyt(f, 0); { mark end of section }
      cp := cellst; { index top of cell list }
      while cp <> nil do begin { output cells }

         writebyt(f, ord(ccell)); { output cell marker }
         sp := cp^.schema; { index schematic cell }
         if sp <> nil then begin { output schematic section }

            writebyt(f, ord(ccschema)); { mark schematic section }
            wrtsht(sp) { output sheet contents }

         end;
         sp := cp^.symbol; { index symbol cell }
         if sp <> nil then begin { output symbol section }

            writebyt(f, ord(ccsymbol)); { mark symbol section }
            wrtsht(sp) { output sheet contents }

         end;
         sp := cp^.layout; { index layout cell }
         if sp <> nil then begin { output layout section }

            writebyt(f, ord(cclayout)); { mark layout section }
            wrtsht(sp) { output sheet contents }

         end;
         writebyt(f, ord(ccterm)); { terminate cell }
         cp := cp^.next { link next cell }

      end;
      writebyt(f, ord(ccfterm)); { terminate file }
      close(f) { close file } { port: was close(f, lock) }

   end

end;
{}
{**************************************************************

PERFORM SAVE CELL

Handles a save cell button push.

**************************************************************}

procedure dosavec;

begin

   if (curbut = bsave) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      savecell; { save current cell }
   resptr { reset pointer device }

end;
{}
{**************************************************************

CREATE FILES LIST

Creates a list of the files in the current directory.
The files are sorted for alphabetical order.

**************************************************************}

procedure fillst(var p: filptr);

var fp, fps, fp1, fp2, fp3, fp4: filptr;
    sl, sp: services.filptr; { port: system directory list }
    i, l:   integer;         { port: name index and length }
    ok:     boolean;         { port: name fits icd format }

begin

   { port: getlst (DOS intdos directory search) is replaced by the
     services library directory lister. Each system entry is
     converted to the icd 8.3 filnam format; directories and names
     that cannot fit that format are skipped (the dialog grid
     displays at most 8 name characters) }
   services.list('*.cel', sl); { make files list }
   fp := nil; { clear converted list }
   while sl <> nil do begin { convert entries }

      sp := sl; { index top entry }
      sl := sl^.next; { gap source list }
      l := max(sp^.name^); { get name length }
      ok := (l <= fillen) and not (services.atdir in sp^.attr);
      if ok then begin { find stem length (characters before '.') }

         i := 1;
         while (i <= l) and (sp^.name^[i] <> '.') do i := i + 1;
         ok := i <= butlen+1 { stem fits the 8 character cell name }

      end;
      if ok then begin { enter to conversion list }

         new(fp1); { get an entry }
         fp1^.name := '             '; { clear name }
         for i := 1 to l do fp1^.name[i] := sp^.name^[i];
         fp1^.next := fp; { push to list (sorted below) }
         fp := fp1

      end;
      dispose(sp^.name); { release system entry }
      dispose(sp)

   end;
   { sort list for alphabetical order }
   fps := nil; { clear target list }
   while fp <> nil do begin { process entries }

      fp1 := fp; { index entry }
      fp := fp^.next; { gap source list }
      fp2 := fps; { index target top }
      fp3 := fp2; { echo }
      fp4 := nil; { clear last }
      while fp3 <> nil do begin { traverse target }

         if fp1^.name < fp2^.name then
            fp3 := nil { flag found }
         else begin { next entry }

            fp4 := fp2; { save last }
            fp2 := fp2^.next; { go next }
            fp3 := fp2 { echo }

         end

      end;
      if fp4 = nil then begin { insert at top }

         fp1^.next := fps;
         fps := fp1

      end else begin { insert in middle }

         fp4^.next := fp1;
         fp1^.next := fp2

      end

   end;
   p := fps { place sorted list }

end;
{}
{**************************************************************

LAY DOWN LIST FORMAT GRID

Places the list grid format in the active area, as used for
cell and file name displays.

**************************************************************}

procedure lstfmt;

var si: integer;   { screen index }

begin

   { clear active area }
   block(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y,
         curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, yellow);
   { lay down grid }
   line(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y,
        curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.e.y, black);
   { port: the 128 pixel (8 cell) column and 16 pixel row constants
     are scaled to the character cell (chrheight) }
   si := curwin^.cs^.vp.v.s.x+8*chrheight-1;
   while si < curwin^.cs^.vp.v.e.x do begin

      line(screen, si, curwin^.cs^.vp.v.s.y, si,
           curwin^.cs^.vp.v.e.y, blue);
      line(screen, si+1, curwin^.cs^.vp.v.s.y, si+1,
           curwin^.cs^.vp.v.e.y, black);
      si := si+8*chrheight

   end;
   si := curwin^.cs^.vp.v.s.y+chrheight-2;
   while si < curwin^.cs^.vp.v.e.y do begin

      line(screen, curwin^.cs^.vp.v.s.x, si,
           curwin^.cs^.vp.v.e.x, si, black);
      line(screen, curwin^.cs^.vp.v.s.x, si+1,
           curwin^.cs^.vp.v.e.x, si+1, black);
      si := si + chrheight

   end;
   line(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.e.y,
        curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, black)

end;
{}
{**************************************************************

DISPLAY FILES LIST

Fills the active area with the files in the files list, at the
current offset.

**************************************************************}

procedure dspfils;

var fp:   filptr;  { files list }
    bs:   butstr;  { string entry }
    i:    integer; { index for same }
                   { port: was btsinx; runs to butlen+1 }
    x, y: byte;    { character position }
    dn:   integer; { display number holder }

begin

   lstfmt; { place onscreen formatting }
   x := 0; { index 1st character of active area }
   y := 8;
   fp := dsplst; { index top of list }
   dn := dspnum; { set number of first entry }
   { find the starting entry }
   while dn <> 1 do begin fp := fp^.next; dn := dn - 1 end;
   while (fp <> nil) and (x < 56) do begin { process entries }

      { transfer filename to compatible store }
      bs := '        '; { clear }
      i := 1; { initalize index }
      while (fp^.name[i] <> '.') and (fp^.name[i] <> ' ') do
         begin

         bs[i] := fp^.name[i];
         i := i + 1

      end;
      { place this string }
      { port: 16 pixel cell scaled to chrheight }
      plcstr(x*chrheight, y*chrheight, bs, 8, black, yellow, true);
      { increment to next character }
      if y < 47 then y := y + 1
      else begin { end of collumn, next }

         x := x + 8;
         y := 8

      end;
      fp := fp^.next { index next entry }

   end;
   { if there is more, say so }
   if fp <> nil then butact(bnext) else butina(bnext);
   if dspnum <> 1 then butact(blast) else butina(blast)

end;
{}
{**************************************************************

DISPLAY AVALIBLE FILES

Fills the active area with all the files that can be found in
the current directory. Handles both the start and end of the
mode.

**************************************************************}

procedure files;

begin

   if not button[bdisplay].act then begin { button not active }

      butact(bdisplay); { activate button }
      modbut := bdisplay; { activate mode }
      fillst(dsplst);
      dspnum := 1; { set current display entry }
      rescur; { remove cursor }
      dspfils; { display file names }
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end else begin { restore regular display }

      butina(bdisplay); { deactivate button }
      butina(blast);
      butina(bnext);
      modbut := dsmbut; { restore old mode }
      redraw { refresh the display }

   end

end;
{}
{**************************************************************

CHECK FILE SELECT

Called when the file display is active, handles both lighting
up files and detecting a selected file to be loaded.
Cusor must be in active area.

**************************************************************}

procedure chkfile;

var x, y, xi, yi: byte;
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    fp:           filptr; { files list }
    i:            integer; { index for same }
                  { port: was btsinx; runs to butlen+1 }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(x*chrheight, y*chrheight, bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;
      dspsav := bs

   end

end;

begin

   { port: 16 pixel cell/128 pixel column scaled to chrheight }
   x := (cur.x - (cur.x mod (8*chrheight))) div chrheight; { find character cell }
   y := cur.y div chrheight;
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      { port: the original passed the cell coordinates unscaled here
        (dspbut.x, dspbut.y are character cells, plcstr takes pixels) }
      plcstr(dspbut.x*chrheight, dspbut.y*chrheight, dspsav, 8, black,
             yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 8;
      fp := dsplst; { index top of list }
      f := false; { set not found }
      while fp <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            { transfer filename to compatible store }
            bs := '        '; { clear }
            i := 1; { initalize index }
            while (fp^.name[i] <> '.') and (fp^.name[i] <> ' ') do
               begin

               bs[i] := fp^.name[i];
               i := i + 1

            end;
            if puck.b[1].a then begin { activate cell }

               { place this string }
               plcstr(x*chrheight, y*chrheight, bs, 8, black, lgreen, true);
               button[bfname].s := bs; { place cell name to filename }
               { update that button }
               updbut(bfname); { update button }
               loadcell; { load up the cell }
               butina(bdisplay); { deactivate button }
               butina(blast);
               butina(bnext);
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s);
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv)

            end else if puck.b[2].a then begin { set placement cell }

               { find matching cell }
               b := blibv; { index 1st button }
               while (b < blibd) and
                     (button[b].s <> bs) do b := succ(b);
               if button[b].s = bs then begin

                  { matching cell, delete from queue }
                  for b := b to blibd do { move buttons down }
                     button[b].s := button[succ(b)].s;
                  button[blibd].s := '        ' { clear last cell }

               end;
               { move down cell stack }
               for b := blibd downto bliba do
                  button[b].s := button[pred(b)].s;
               button[blibv].s := bs; { place file name to cell }
               { refresh buttons }
               for b := blibv to blibd do
                  updbut(b); { update button }
               butina(bdisplay); { deactivate button }
               butina(blast);
               butina(bnext);
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s);
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv);
               redraw; { refresh the display }

            end else selbut; { select button }
            f := true; { flag found }
            fp := nil { flag done }

         end else begin

            { increment to next character }
            if yi < 47 then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 8

            end;
            fp := fp^.next { index next entry }

         end

      end;
      if not f then begin { select empty space }

         bs := '        '; { clear }
         selbut { select the button }

      end

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

PERFORM FILES LIST MODE

**************************************************************}

procedure dofiles;

var dn, dn1: integer; { display number }
    fp:      filptr; { files list }

begin

   if (curbut = bdisplay) and (puck.b[1].a or puck.b[2].a or
                               puck.b[3].a) then
      files { activate/deactivate display }
   else if (curbut in [bnext, blast]) and
           (puck.b[1].a or puck.b[2].a or puck.b[3].a) then begin

      { display next section }
      fp := dsplst; { index top of list }
      { set display number }
      if curbut = bnext then dn := dspnum+7*40
      else dn := dspnum-7*40;
      dn1 := dn; { copy }
      if dn > 0 then begin { didn't back to far }

         while dn1 <> 1 do begin { index that entry }

            if fp <> nil then fp := fp^.next; { next entry }
            dn1 := dn1 - 1 { count }

         end;
         if fp <> nil then begin { there is a next page }

            dspnum := dn; { set new offset }
            dspfils { display new list }

         end

      end

   end else if modbut = bdisplay then chkfile; { check each file button }
   resptr { reset pointer device }

end;
{}
{**************************************************************

DISPLAY AVALIBLE CELLS

Fills the active area with all the cells in the current file.
Handles both the start and end of the mode.

**************************************************************}

procedure displayc;

var p:    celptr; { pointer for cells }
    x, y: byte;   { character position }

begin

   if not button[bcells].act then begin { button not active }

      butact(bcells); { activate button }
      modbut := bcells;
      rescur; { remove cursor }
      lstfmt; { set up screen }
      x := 0; { index 1st character of active area }
      y := 8;
      p := cellst; { index top of list }
      while p <> nil do begin { process entries }

         { place this string }
         { port: 16 pixel cell scaled to chrheight }
         plcstr(x*chrheight, y*chrheight, p^.name, 8, black, yellow, true);
         { increment to next character }
         if y < 47 then y := y + 1
         else begin { end of collumn, next }

            x := x + 8;
            y := 8

         end;
         p := p^.next { index next entry }

      end;
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end else begin { restore regular display }

      butina(bcells); { deactivate button }
      modbut := dsmbut; { restore old mode }
      redraw { refresh the display }

   end

end;
{}
{**************************************************************

CHECK CELL SELECT

Called when the cell display is active, handles both lighting
up cells and detecting a selected cell to be loaded.
Cusor must be in active area.

**************************************************************}

procedure chkcell;

var x, y, xi, yi: byte;
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    p:            celptr; { cell pointer }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(x*chrheight, y*chrheight, bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;
      dspsav := bs

   end

end;

begin

   { port: 16 pixel cell/128 pixel column scaled to chrheight }
   x := (cur.x - (cur.x mod (8*chrheight))) div chrheight; { find character cell }
   y := cur.y div chrheight;
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      { port: the original passed the cell coordinates unscaled here }
      plcstr(dspbut.x*chrheight, dspbut.y*chrheight, dspsav, 8, black,
             yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 8;
      p := cellst; { index top of list }
      f := false; { set not found }
      while p <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            bs := p^.name; { save name }
            if puck.b[1].a then begin { activate cell }

               rescur; { remove cursor }
               { place this string }
               plcstr(x*chrheight, y*chrheight, bs, 8, black, lgreen, true);
               setcur; { replace cursor }
               button[bcname].s := bs; { place cell name to cellname }
               { update that button }
               updbut(bcname); { update button }
               curwin^.cc := p; { set current cell }
               celstk := nil; { clear cell stack }
               dispcell; { display current cell }
               butina(bcells); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s);
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv)

            end else if puck.b[2].a then begin { set placement cell }

               { not already selected for placement }
               placel := p; { place cell pointer }
               { find matching cell }
               b := bcelv; { index 1st button }
               while (b < bceld) and
                     (button[b].s <> bs) do b := succ(b);
               if button[b].s = bs then begin

                  { matching cell, delete from queue }
                  for b := b to bceld do { move buttons down }
                     button[b].s := button[succ(b)].s;
                  button[bceld].s := '        ' { clear last cell }

               end;
               { move down cell stack }
               for b := bceld downto bcela do
                  button[b].s := button[pred(b)].s;
               button[bcelv].s := bs; { place cell name to cellname }
               { refresh buttons }
               for b := bcelv to bceld do
                  updbut(b); { update button }
               butina(bcells); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s);
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv);
               butact(bcelv); { set button active }
               redraw { refresh the display }

            end else selbut; { select button }
            f := true; { flag found }
            p := nil { flag done }

         end else begin

            { increment to next character }
            if yi < 47 then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 8

            end;
            p := p^.next { index next entry }

         end

      end;
      if not f then begin { select empty space }

         bs := '        '; { clear }
         selbut { select the button }

      end

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

PERFORM CELLS LIST MODE

**************************************************************}

procedure docells;

begin

   if (curbut = bcells) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      displayc { activate/deactivate display }
   else if modbut = bcells then chkcell; { check each file button }
   resptr { reset pointer device }

end;
{}
{**************************************************************

LOAD LIBRARY CELL

Loads the library cell data.
Presently just skips to the required cell and loads that. To
be complete, we must account for a cell that has subcells. This
means that other cells may also need to be copied, and it is not
possible to predict the exact tree before we have read the entire
deck.
One solution: we perform a pass that extracts the tree for the
entire file, then a second pass to load the needed cells. This
first pass can be merged with the primary cell pickup.
What to do about duplications ? if an incoming cell matches
the name of an existing cell, it may replace it, be replaced by
it, or generate an error. Discarding the incoming cell seems like
the most "library like" solution.

**************************************************************}

procedure loadlib(lcp: celptr);

var fn:           packed array [1..12] of char;
                                { port: was counted string[12] }
    fl:           0..12;        { port: filename length }
    i:            btsinx;       { index for filename }
    f:            bytfil;       { file }
    b:            byte;         { read holder }
    n:            integer;      { node number }
    cp, cp1, cp2: celptr;       { cell pointer }
    c:            integer;      { file name count }
                                { port: was btsinx; counts down to 0 }

{ skip figures list }

procedure skpfigs;

var b:  byte; { byte holder }
    c1: byte; { character count }

{ link cell from cell number }

procedure lnkcel;

var p:        celptr;  { cell pointer }
    d:        boolean; { duplicate flag }
    sp1, sp2: shtptr;  { sheet pointer }

begin

   new(sp1); { get a sheet entry }
   p := libcel; { index 1st cell }
   { find that cell }
   while n <> 1 do begin p := p^.next; n := n - 1 end;
   sp1^.csp := p; { set cell reference }
   sp2 := cp^.schema; { index list }
   d := false; { set no duplicate }
   while sp2 <> nil do begin { traverse list }

      if sp2^.csp = p then d := true; { duplicate found }
      sp2 := sp2^.next { next entry }

   end;
   if not d then begin { not duplicate, link in }

      sp1^.next := cp^.schema;
      cp^.schema := sp1

   end

end;

begin

   readbyt(f, b); { get figure type }
   while b <> 0 do begin { skip schematic figures }

      case b of { figure }

         1, 2, 8, 9, 19, 20, 21, 22, 23, 24, 25, 26, 27: begin

            { line, box, layer }
            read32(f, n); { starting }
            read32(f, n);
            read32(f, n); { ending }
            read32(f, n)

         end;

         3: begin { arc or circle }

            read32(f, n); { starting }
            read32(f, n);
            read32(f, n); { ending }
            read32(f, n);
            read32(f, n); { center }
            read32(f, n);
            read32(f, n)   { radius }

         end;

         4: begin { char }

            read32(f, n);   { origin }
            read32(f, n);
            read32(f, n);
            read32(f, n);
            readbyt(f, b); { get character count }
            c := b;
            for c1 := 1 to c do begin { read string }

               readbyt(f, b) { get a character }

            end;
            read32(f, n); { scale }
            readbyt(f, b) { rotation }

         end;

         5, 6: begin { wire, bus }

            read32(f, n); { starting }
            read32(f, n);
            read32(f, n); { ending }
            read32(f, n);
            read32(f, n) { node/bus number }

         end;

         7, 11: begin { junction }

            read32(f, n); { center }
            read32(f, n);
            read32(f, n) { node number }

         end;

         10: begin { subcell }

            read32(f, n); { read origin }
            read32(f, n);
            read32(f, n); { read cell number }
            readbyt(f, b); { get cell type }
            { find the corresponding cell }
            if cp <> nil then lnkcel;
            readbyt(f, b) { rotation }

         end;

         12, 13, 14, 15, 16, 17, 18: begin

            { predefined cell }
            read32(f, n); { read origin }
            read32(f, n);
            readbyt(f, b) { rotation }

         end;

         28: begin

            { intersection }
            read32(f, n); { starting }
            read32(f, n);
            read32(f, n); { ending }
            read32(f, n);
            readbyt(f, b); { color }
            readbyt(f, b); { top layer }
            read32(f, n); { top figure }
            readbyt(f, b); { top layer }
            read32(f, n) { top figure }

         end;


      end;
      readbyt(f, b) { get next figure }

   end

end;

{ skip sheet with cell structure read }

procedure skpsht(cp: celptr);

var b: byte;
    n: integer;
    c: byte;    { character count }

begin

   { skip bounding box }
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n);
   { skip node list }
   readbyt(f, c); { read node name count }
   while c <> 0 do begin { skip nodes }

      while c <> 0 do begin { skip cell characters }

         readbyt(f, b); { skip a cell character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { skip ordinal }
      readbyt(f, b); { skip temp indicator }
      readbyt(f, c) { read next cell name count }

   end;
   { skip bus list }
   readbyt(f, c); { read bus name count }
   while c <> 0 do begin { read busses }

      while c <> 0 do begin { skip name characters }

         readbyt(f, b); { skip a name character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { skip temp indicator }
      { skip node list }
      readbyt(f, c); { get node count }
      while c <> 0 do begin { skip bus nodes }

         read32(f, n); { skip node number }
         c := c - 1 { count }

      end;
      readbyt(f, c) { read next cell name count }

   end;
   { port: the original skipped only 8 figure lists here, but readsht
     reads and wrtsht writes 11 per sheet (the sources were frozen
     mid-refactor) - library loads of files written by this program
     would lose file sync; aligned to 11 }
   skpfigs; { skip cells layer }
   skpfigs; { skip figures layer }
   skpfigs; { skip overglass layer }
   skpfigs; { skip via layer }
   skpfigs; { skip met 2 intersections layer }
   skpfigs; { skip met 1 intersections layer }
   skpfigs; { skip poly intersections layer }
   skpfigs; { skip metal 2 layer }
   skpfigs; { skip contact layer }
   skpfigs; { skip poly, metals and diff layer }
   skpfigs  { skip wells layer }

end;

{ mark cell reference tree }

procedure mrkcel(cp: celptr);

var sp: shtptr;

begin

   cp^.ref := true; { set top cell referenced }
   sp := cp^.schema; { index 1st linkage }
   while sp <> nil do begin { traverse }

      mrkcel(sp^.csp); { mark that tree }
      sp := sp^.next { next entry }

   end

end;

begin

   { create filename string }
   { port: SVS counted string build replaced by space padded
     fixed array; assign ignores trailing spaces }
   fn := '            '; { clear destination }
   fl := 0;
   for i := 1 to butlen do if libnam[i] <> ' ' then begin

      fl := fl + 1;
      fn[fl] := libnam[i]

   end;
   { place extention }
   fn[fl+1] := '.'; fn[fl+2] := 'c'; fn[fl+3] := 'e'; fn[fl+4] := 'l';
   assign(f, fn); { port: was reset(f, fn) }
   reset(f); { activate file }
   { perform cell structure pass }
   readbyt(f, b); { read signature }
   readbyt(f, b);
   readbyt(f, b);
   readbyt(f, b); { read cell directory mark }
   { skip cell directory (which we already have read) }
   readbyt(f, b); { read cell name count }
   c := b;
   while c <> 0 do begin { read cell names }

      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { read next cell name count }
      c := b

   end;
   cp := libcel; { index first cell }
   readbyt(f, b); { read section mark }
   while b = ord(ccell) do begin

      cp^.ref := false; { set cell not referenced }
      { cell marked and not our cell, skip entire cell }
      readbyt(f, b); { read cell section mark }
      while b <> ord(ccterm) do begin { read sections }

         if (b = ord(ccschema)) or (b = ord(ccsymbol)) then
            skpsht(cp); { skip entire sheet }
         readbyt(f, b) { get next section mark }

      end;
      cp := cp^.next; { index next cell }
      readbyt(f, b) { get next cell mark }

   end;
   { mark all referenced cells }
   mrkcel(lcp);
   { form cell cross reference }
   cp := libcel; { index first cell }
   while cp <> nil do begin { traverse }

      if cp^.ref then begin { cell is to be loaded }

         cp1 := cellst; { find matching cell in current list }
         cp2 := nil; { clear found entry }
         while cp1 <> nil do begin { search }

            if cp^.name = cp1^.name then { found, save }
               cp2 := cp1;
            cp1 := cp1^.next

         end;
         if cp2 = nil then begin { no match }

            cp2 := cellst; { find last cell in current list }
            while cp2^.next <> nil do cp2 := cp2^.next;
            { get a new cell pointer }
            new(cp2^.next);
            cp2 := cp2^.next;
            cp2^.next := nil; { clear next }
            cp2^.schema := nil; { clear out }
            cp2^.symbol := nil;
            cp2^.layout := nil;
            cp2^.simulate := nil;
            cp2^.name := cp^.name { set cell name }

         end;
         cp^.cross := cp2 { place cross reference }

      end;
      cp := cp^.next { next cell }

   end;
   { perform cell load pass }
   reset(f);
   readbyt(f, b); { read signature }
   readbyt(f, b);
   readbyt(f, b);
   readbyt(f, b); { read cell directory mark }
   { skip cell directory (which we already have read) }
   readbyt(f, b); { read cell name count }
   c := b;
   while c <> 0 do begin { read cell names }

      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { read next cell name count }
      c := b

   end;
   cp := libcel; { index first cell }
   readbyt(f, b); { read section mark }
   while b = ord(ccell) do begin

      { cell entry }
      readbyt(f, b); { read cell section mark }
      while b <> ord(ccterm) do begin { read sections }

         if (b = ord(ccschema)) or (b = ord(ccsymbol)) then begin

            { sheet }
            if cp^.ref then begin { cell is referenced }

               if b = ord(ccschema) then begin

                  { schematic section }
                  if cp^.cross^.schema = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.schema); { create schematic sheet }
                     readsht(f, cp^.cross^.schema) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.schema) then
                        readsht(f, cp^.cross^.schema)
                  else skpsht(nil) { skip sheet }

               end else if b = ord(ccsymbol) then begin

                  { symbol section }
                  if cp^.cross^.symbol = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.symbol); { create symbol sheet }
                     readsht(f, cp^.cross^.symbol) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.symbol) then
                        readsht(f, cp^.cross^.symbol)
                  else skpsht(nil) { skip sheet }

               end else if b = ord(cclayout) then begin

                  { layout section }
                  if cp^.cross^.layout = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.layout); { create symbol sheet }
                     readsht(f, cp^.cross^.layout) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.layout) then
                        readsht(f, cp^.cross^.layout)
                  else skpsht(nil) { skip sheet }

               end

            end else skpsht(nil) { skip entire sheet }

         end;
         readbyt(f, b) { get next section mark }

      end;
      cp := cp^.next; { index next cell }
      readbyt(f, b) { get next cell mark }

   end;
   close(f) { close file } { port: was close(f, lock) }

end;
{}
{**************************************************************

DISPLAY LIBRARY CELLS

Creates a display of the cells in a file library.
The currently selected button is used as the filename button.

**************************************************************}

procedure displayl;

var fn:    packed array [1..12] of char;
                       { port: was counted string[12] }
    fl:    0..12;      { port: filename length }
    i:     integer;    { index for filename }
                       { port: was btsinx; runs to butlen+1 }
    f:     bytfil;     { file }
    b:     byte;       { read holder }
    cp, p: celptr;     { cells lists }
    c:     integer;    { file name count }
                       { port: was btsinx; counts down to 0 }
    x, y:  byte;       { character position }

begin

   if not button[curbut].act and
      (button[curbut].s <> '        ') then begin

      butact(curbut); { activate button }
      modbut := curbut;
      libnam := button[curbut].s; { save filename }
      libbut := curbut; { save button }
      libcel := nil; { clear cell list }
      { create filename string }
      { port: SVS counted string build replaced by space padded
        fixed array; assign ignores trailing spaces }
      fn := '            '; { clear destination }
      fl := 0;
      for i := 1 to butlen do if button[curbut].s[i] <> ' ' then
         begin

         fl := fl + 1;
         fn[fl] := button[curbut].s[i]

      end;
      { place extention }
      fn[fl+1] := '.'; fn[fl+2] := 'c'; fn[fl+3] := 'e'; fn[fl+4] := 'l';
      assign(f, fn); { port: was reset(f, fn) }
      reset(f); { activate file }
      readbyt(f, b); { read signature }
      readbyt(f, b);
      readbyt(f, b);
      readbyt(f, b); { read cell directory mark }
      readbyt(f, b); { read cell name count }
      c := b;
      cp := nil; { clear last cell }
      while c <> 0 do begin { read cell names }

         { get a new cell pointer }
         if cp = nil then begin new(libcel); cp := libcel end
         else begin new(cp^.next); cp := cp^.next end;
         cp^.next := nil; { clear next }
         cp^.name := '        '; { clear cell name }
         cp^.schema := nil; { clear list for later use }
         i := 1; { index 1st cell character }
         while c <> 0 do begin { read cell characters }

            readbyt(f, b); { get a cell character }
            cp^.name[i] := chr(b); { place character }
            c := c - 1; { count characters }
            i := i + 1

         end;
         readbyt(f, b); { read next cell name count }
         c := b

      end;
      close(f); { close file } { port: was close(f, lock) }
      rescur; { remove cursor }
      lstfmt; { set up screen }
      x := 0; { index 1st character of active area }
      y := 8;
      p := libcel; { index top of list }
      while p <> nil do begin { process entries }

         { place this string }
         { port: 16 pixel cell scaled to chrheight }
         plcstr(x*chrheight, y*chrheight, p^.name, 8, black, yellow, true);
         { increment to next character }
         if y < 47 then y := y + 1
         else begin { end of collumn, next }

            x := x + 8;
            y := 8

         end;
         p := p^.next { index next entry }

      end;
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end else begin { restore regular display }

      butina(curbut); { deactivate button }
      modbut := dsmbut; { restore old mode }
      redraw { refresh the display }

   end

end;
{}
{**************************************************************

CHECK LIBRARY CELL SELECT

Called when the library cell display is active, handles both
lighting up cells and detecting a selected cell to be loaded.
Cusor must be in active area.

**************************************************************}

procedure chklcell;

var x, y, xi, yi: byte;
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    p:            celptr; { cell pointer }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(x*chrheight, y*chrheight, bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;
      dspsav := bs

   end

end;

begin

   { port: 16 pixel cell/128 pixel column scaled to chrheight }
   x := (cur.x - (cur.x mod (8*chrheight))) div chrheight; { find character cell }
   y := cur.y div chrheight;
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      { port: the original passed the cell coordinates unscaled here }
      plcstr(dspbut.x*chrheight, dspbut.y*chrheight, dspsav, 8, black,
             yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 8;
      p := libcel; { index top of list }
      f := false; { set not found }
      while p <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            bs := p^.name; { save name }
            if puck.b[1].a then begin { activate cell }

               loadlib(p); { load library cell to internal }
               p := cellst; { index top cell }
               { found our cell }
               while p^.name <> bs do p := p^.next;
               rescur; { remove cursor }
               { place this string }
               plcstr(x*chrheight, y*chrheight, bs, 8, black, lgreen, true);
               setcur; { replace cursor }
               button[bcname].s := bs; { place cell name to cellname }
               updbut(bcname); { update button }
               curwin^.cc := p; { set current cell }
               celstk := nil; { clear cell stack }
               dispcell; { display current cell }
               butina(libbut); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s);
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update button }
               updbut(bcposyv)

            end else if puck.b[2].a then begin { set placement cell }

               loadlib(p); { load library cell to internal }
               p := cellst; { index top cell }
               { found our cell }
               while p^.name <> bs do p := p^.next;
               { not already selected for placement }
               placel := p; { place cell pointer }
               { find matching cell }
               b := bcelv; { index 1st button }
               while (b < bceld) and
                     (button[b].s <> bs) do b := succ(b);
               if button[b].s = bs then begin

                  { matching cell, delete from queue }
                  for b := b to bceld do { move buttons down }
                     button[b].s := button[succ(b)].s;
                  button[bceld].s := '        ' { clear last cell }

               end;
               { move down cell stack }
               for b := bceld downto bcela do
                  button[b].s := button[pred(b)].s;
               button[bcelv].s := bs; { place cell name to cellname }
               { refresh buttons }
               for b := bcelv to bceld do
                  updbut(b); { update button }
               butina(libbut); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s);
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv);
               butact(bcelv); { set button active }
               redraw { refresh the display }

            end else selbut; { select button }
            f := true; { flag found }
            p := nil { flag done }

         end else begin

            { increment to next character }
            if yi < 47 then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 8

            end;
            p := p^.next { index next entry }

         end

      end;
      if not f then begin { select empty space }

         bs := '        '; { clear }
         selbut { select the button }

      end

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

PERFORM LIBRARIES LIST MODE

**************************************************************}

procedure dolibs;

begin

   if (curbut = blibv) and puck.b[2].a then
      edtlibv { edit library name }
   else if (curbut in [blibv, bliba, blibb, blibc, blibd]) and
               (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      displayl { activate/deactivate display }
   else if modbut = blibv then chklcell; { check each file button }
   resptr { reset pointer device }

end;
{}
{ UNRESOLVED:

  - icdui_mod.pas needs "joins services;" added after "joins graphics;"
    (fillst calls services.list and uses services.filptr/atdir); the
    module header is the integrator's file.
  - icdui_base.pas stubs for doloadc, dosavec, dofiles, docells and
    dolibs are superseded by the full ports above; the integrator
    removes the stubs (duplicate definitions until then).
  - original format defect ported verbatim: loadlib's skpsht skips 8
    figure lists per sheet while readsht/wrtsht read/write 11 (and
    skpsht's own comments do not mention the cells/met2/contact
    layers). loadlib will therefore lose file sync on any cell file
    written by savecell; the sheet skipper needs 3 more skpfigs calls
    (cells first, met2/contact in wrtsht order) to match, but that is
    a format decision deferred to the integrator.
  - loadlib performs no duplicate-name discard on load (documented as
    an open design question in the original header comment).
  - fillst skips filenames that do not fit the original 8.3 filnam
    format (stem over 8 characters or name over 13); long Linux
    filenames are invisible to the files dialog.
  - dofiles pages by 7*40 entries (7 columns x 40 rows of the original
    1024x768 layout); the scaled active area may hold a different cell
    count, so paging may not exactly match a full screen at other
    display densities (display-only effect). }

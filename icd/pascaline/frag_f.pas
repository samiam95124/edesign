{******************************************************************************

FRAGMENT F: FIGURE DRAWING AND SELECTION

Ported from icdd.pas. Contains the figure rationalizers, distance
and selection routines, the rotation/transform helpers for
predefined figures, the device drawers, the figure/cell/list
drawing engine, bounding calculation, region refresh, node/bus
smashing, delete operations, cell traversal, net tracing/naming,
and block save/cut/paste.

Port notes:

1. All external declarations deleted per the conversion spec;
   the names resolve within the module.

2. intersect is declared external in icdd.pas but its definition
   lives in icdg.pas; it is ported here (verbatim from icdg.pas)
   because saveblk depends on it.

3. The lgridsx/lgridsy/dgridsx/dgridsy grid position vectors (which
   were filled by the deleted assembly grid placer in drawa.pas) do
   not exist in the port. The grid refreshes in drwfigs and rregion
   are redone in terms of the real coordinate dogrid/do10sgrid
   (ported in fragment d), matching the pattern used by redraw.

4. Partial case statements over figtyp gain empty else branches
   (P6 checks case coverage at runtime; SVS fell through silently).

******************************************************************************}
{}
{**************************************************************

RATIONALIZE LINE

"rationalizes" a line. This means to eliminate duplicate
versions of the same line.
The resulting line will have x1 <= x2 allways, and where
x1 = x2, there will be y1 <= y2.

**************************************************************}

procedure ratlin(var x1, y1, x2, y2: integer);

var t: integer;

begin

   { rationalize the line }
   if (x1 > x2) or ((x1 = x2) and (y1 > y2)) then begin

      t := x1; x1 := x2; x2 := t;
      t := y1; y1 := y2; y2 := t

   end

end;
{}
{**************************************************************

RATIONALIZE BOX

"rationalizes" a box. This means to eliminate duplicate
versions of the same box.
The resulting box will have x1 <= x2, y1 <= y2.

**************************************************************}

{ port: this is the original; the interim copy in the base layer
  is to be removed at integration }

procedure ratbox(var x1, y1, x2, y2: integer);

var t: integer;

begin

   { rationalize box }
   if x1 > x2 then
      begin t := x1; x1 := x2; x2 := t end;
   if y1 > y2 then
      begin t := y1; y1 := y2; y2 := t end

end;
{}
{**************************************************************

DRAW REAL BLOCK

Draws a real block with clipping.

**************************************************************}

procedure blockr(x1, y1, x2, y2: integer; { ends of box }
                 c:              color;   { color }
                 r:              region); { clip region }

var b: region;
    t: integer;

begin

   b.s.x := x1;
   b.s.y := y1;
   b.e.x := x2;
   b.e.y := y2;
   { rationalize box }
   if b.s.x > b.e.x then
      begin t := b.s.x; b.s.x := b.e.x; b.e.x := t end;
   if b.s.y > b.e.y then
      begin t := b.s.y; b.s.y := b.e.y; b.e.y := t end;
   viewc(b.s, curwin^.cs^.vp); { convert coordinates }
   viewc(b.e, curwin^.cs^.vp);
   { clip to viewport }
   if (b.s.x <= r.e.x) and (b.e.x >= r.s.x) and
      (b.s.y <= r.e.y) and (b.e.y >= r.s.y) then begin

      { block overlays viewport at some point }
      { clip to viewport }
      if b.s.x < r.s.x then b.s.x := r.s.x;
      if b.e.x > r.e.x then b.e.x := r.e.x;
      if b.s.y < r.s.y then b.s.y := r.s.y;
      if b.e.y > r.e.y then b.e.y := r.e.y;
      block(screen, b.s.x, b.s.y, b.e.x, b.e.y, c) { draw block }

   end

end;
{}
{**************************************************************

DRAW REAL BOX

Draws the real coordinate box with clipping.

**************************************************************}

{ port: declared external in icdd.pas but no definition survives in
  the sources; reconstructed from the printer analogue pboxr
  (icde.pas) over liner, following the bboxr/bliner pattern }

procedure boxr(x1, y1, x2, y2: integer; { ends of box }
               c:              color;   { color }
               r:              region); { clip region }

begin

   liner(x1, y1, x2, y1, c, r); { top }
   liner(x1, y2, x2, y2, c, r); { bottom }
   liner(x1, y1, x1, y2, c, r); { left }
   liner(x2, y1, x2, y2, c, r) { right }

end;
{}
{**************************************************************

CONNECTOR DRAW REAL

Draws a connector at the given location and size.

**************************************************************}

{ port: declared external in icdd.pas but no definition survives in
  the sources; reconstructed from the printer analogue pconr
  (icde.pas) and the viewport connector con (icdb.pas) over liner }

procedure conr(x, y,          { center }
               r:  integer;   { radius (actually width) }
               c:  color;     { color }
               cr: region);   { clip region }

begin

   liner(x-r, y-r, x-r, y+r, c, cr); { draw left side }
   liner(x+r, y-r, x+r, y+r, c, cr); { right side }
   liner(x-r, y-r, x+r, y-r, c, cr); { top side }
   liner(x-r, y+r, x+r, y+r, c, cr); { bottom side }
   liner(x-r, y, x+r, y, c, cr); { cross }
   liner(x, y-r, x, y+r, c, cr)

end;
{}
{**************************************************************

FIND INTERSECTION

This routine finds the
"intersection" of the given layer rectangle with another
rectangle. An intersection is an overlapping region of two
rectangles.

**************************************************************}

{ port: declared external in icdd.pas; ported here from icdg.pas }

procedure intersect(
              ax1, ay1, ax2, ay2,          { 1st rectangle }
              bx1, by1, bx2, by2: integer; { 2nd rectangle }
          var rx1, ry1, rx2, ry2: integer; { result rectangle }
          var rf:                 boolean); { found flag }

var r1, r2: boolean; { point define flags }

{ define an included point }

procedure defpnt(x, y: integer);

begin

   if not r1 then begin { 1st point not defined }

      rx1 := x; { set point }
      ry1 := y;
      r1 := true { set defined }

   end else if (rx1 <> x) and (ry1 <> y) then begin

      { new point is a direct opposite, enter as 2nd }
      rx2 := x; { set point }
      ry2 := y;
      r2 := true { set defined }

   end

end;

{ find included orthongonal line }

procedure lincl(x1, y1, x2, y2, { 1st region }
                cx1, cy1, cx2, cy2: integer); { line }

var x, y: integer; { point holders }

begin

   if ((x1 <= cx2) and (x2 >= cx1) and
       (y1 <= cy1) and (y2 >= cy1)) then begin

      { horizonal included line }
      x := cx1; { set x }
      if x < x1 then x := x1;
      defpnt(x, cy1); { enter points }
      x := cx2; { set x }
      if x > x2 then x := x2;
      defpnt(x, cy1)

   end else if ((y1 <= cy2) and (y2 >= cy1) and
            (x1 <= cx1) and (x2 >= cx1)) then begin

      { vertical included line }
      y := cy1; { set y }
      if y < y1 then y := y1;
      defpnt(cx1, y); { enter points }
      y := cy2; { set y }
      if y > y2 then y := y2;
      defpnt(cx1, y)

   end

end;

begin

   r1 := false; { clear points }
   r2 := false;
   { test 2nd inclusion in 1st }
   lincl(ax1, ay1, ax2, ay2, bx1, by1, bx1, by2); { left }
   lincl(ax1, ay1, ax2, ay2, bx2, by1, bx2, by2); { right }
   lincl(ax1, ay1, ax2, ay2, bx1, by1, bx2, by1); { top }
   lincl(ax1, ay1, ax2, ay2, bx1, by2, bx2, by2); { bottom }
   { test 1st inclusion in 2nd }
   lincl(bx1, by1, bx2, by2, ax1, ay1, ax1, ay2); { left }
   lincl(bx1, by1, bx2, by2, ax2, ay1, ax2, ay2); { right }
   lincl(bx1, by1, bx2, by2, ax1, ay1, ax2, ay1); { top }
   lincl(bx1, by1, bx2, by2, ax1, ay2, ax2, ay2); { bottom }
   rf := r1 and r2; { set intersection found }
   if rf then ratbox(rx1, ry1, rx2, ry2) { rationalize }

end;
{}
{**************************************************************

FIND DISTANCE TO FIGURE

Finds the real distance to the nearest point on the given
figure.

**************************************************************}

function mindist(x, y: integer; p: drwptr): integer;

var d, d1:          integer;
    x1, y1, x2, y2: integer;
    an1, an2, an3:  real;
    inc:            boolean;

{ find distance to line }

function lindist(x1, y1, x2, y2, x3, y3: integer): integer;

var d:               integer; { result }
    an1, an2, an3:   real; { angles }

begin

   { find figure angle }
   an1 := angle(x1, y1, x2, y2);
   { find both sides of the triangle formed between the
     line and our reference point }
   an2 := angle(x1, y1, x3, y3);
   an3 := angle(x2, y2, x3, y3);
   if abs(angdif(an1, an2)) > pi/2 then
      { oblique, closest point is that endpoint }
      d := dist(x1, y1, x3, y3)
   else if abs(angdif(an1-pi, an3)) > pi /2 then
      { same }
      d := dist(x2, y2, x3, y3)
   else begin

      { acute triangle, here we calculate the distance
        by means of right triangles to the perpendicular
        intersection with the line }
      d := dist(x1, y1, x3, y3); { find one side }
      d := round(d*sin(abs(angdif(an1, an2)))) { find perp }

   end;
   lindist := d { return result }

end;

{ find distance to box }

function boxdist(x1, y1, x2, y2, x3, y3: integer): integer;

var d, d1: integer; { result }

begin

   { right side }
   d := lindist(x1, y1, x1, y2, x3, y3);
   { left side }
   d1 := lindist(x2, y1, x2, y2, x3, y3);
   if d1 < d then d := d1; { set minimum }
   { top }
   d1 := lindist(x1, y1, x2, y1, x3, y3);
   if d1 < d then d := d1; { set minimum }
   { bottom }
   d1 := lindist(x1, y2, x2, y2, x3, y3);
   if d1 < d then d := d1; { set minimum }
   boxdist := d { return result }

end;

{ find distance to block }

function blockdist(x1, y1, x2, y2, x3, y3: integer): integer;

var d: integer;

begin

   if (x >= x1) and (x <= x2) and (y >= y1) and (y <= y2) then
      d := 0 { inside square }
   else { outside, calculate as for box }
      d := boxdist(x1, y1, x2, y2, x, y);
   blockdist := d { return result }

end;

{ find distance to predefined cell }

function pdcdist(o: point; rm: rotmod; xl, yl, m: integer): integer;

var d: integer;

begin

   { cells are treated as if they were filled boxes }
   if rm in [rm0, rm180, rmm0, rmm180] then { normal }
      d := blockdist(o.x, o.y, o.x+xl*1500, o.y+yl*1500, x, y)
   else { on side }
      d := blockdist(o.x, o.y, o.x+yl*1500, o.y+xl*1500, x, y);
   pdcdist := d { return result }

end;

begin

   with p^ do case typ of { figure type }

      tline, tbline: { line }
         d := lindist(l.s.x, l.s.y, l.e.x, l.e.y, x, y);

      twire: { wire }
         d := lindist(w.s.x, w.s.y, w.e.x, w.e.y, x, y);

      tbus: { bus }
         d := lindist(bs.l.s.x, bs.l.s.y, bs.l.e.x, bs.l.e.y, x, y);

      tbox, tbbox, tccut: { box }
         d := boxdist(b.s.x, b.s.y, b.e.x, b.e.y, x, y);

      { arc or circle }
      tarc: begin { arc or circle }

         { find angles of vectors }
         an1 := angle(a.c.x, a.c.y, a.s.x, a.s.y);
         an2 := angle(a.c.x, a.c.y, a.e.x, a.e.y);
         an3 := angle(a.c.x, a.c.y, x, y);
         if angdif(an1, an2) < 0 then begin { end is ccw }

            if angdif(an1, an3) >= 0 then inc := false
            else inc := (angdif(an1, an3)*angdif(an2, an3)) < 0

         end else begin { end is cw }

            if angdif(an1, an3) < 0 then inc := true
            else inc := (angdif(an1, an3)*angdif(an2, an3)) >= 0;

         end;
         if inc then begin { process included }

            { find distance to reference }
            d1 := dist(a.c.x, a.c.y, x, y);
            if d1 > a.r then d := d1 - a.r { outside }
            else d := a.r - d1 { inside }

         end else begin { process excluded }

            if abs(angdif(an3, an1)) < abs(angdif(an3, an2)) then
               { start is closer }
               d := dist(x, y, a.s.x, a.s.y)
            else
               { end is closer }
               d := dist(x, y, a.e.x, a.e.y)

         end

      end;

      tchar: { vector character }
         { characters are treated as filled blocks }
         d := blockdist(c.r.s.x, c.r.s.y, c.r.e.x, c.r.e.y,
                        x, y);

      tjunction: begin { wire junction }

         { junctions are treated as filled circles }
         d := dist(j.x, j.y, x, y);
         if d <= curwin^.cs^.js then d := 0 { inside the circle }
         else d := d - curwin^.cs^.js { distance to circle }

      end;

      tconnect: { connector }
         { connectors are treated as if they were filled boxes }
         d := blockdist(j.x-curwin^.cs^.cs, j.y-curwin^.cs^.cs,
                        j.x+curwin^.cs^.cs, j.y+curwin^.cs^.cs,
                        x, y);

      tcell: with cr do { subcell }
         { cells are treated as if they were filled boxes }
         if rm in [rm0, rm180, rmm0, rmm180] then { normal }
            d := blockdist(o.x, o.y,
                           o.x+abs(cp^.bbex-cp^.bbsx),
                           o.y+abs(cp^.bbey-cp^.bbsy),
                           x, y)
         else { on side }
            d := blockdist(o.x, o.y,
                           o.x+abs(cp^.bbey-cp^.bbsy),
                           o.y+abs(cp^.bbex-cp^.bbsx),
                           x, y);

      tnmos, tpmos:  { xstrs }
         d := pdcdist(o, rm, 7, 8, 1500); { find distance }

      tcap: { capacitor }
         d := pdcdist(o, rm, 4, 5, 1500); { find distance }

      tres: { resistor }
         d := pdcdist(o, rm, 4, 20, 750); { find distance }

      tdiode: { diode }
         d := pdcdist(o, rm, 4, 8, 1500); { find distance }

      tvdd, tvss: { power connectors }
         d := pdcdist(o, rm, 2, 4, 1500); { find distance }

      tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
      tnwell, tpwell, tcont: { filled layer }
         d := blockdist(b.s.x, b.s.y, b.e.x, b.e.y, x, y);

      else d := maxint { port: unmatched figure types never selected }

   end;
   mindist := d { return result }

end;
{}
{**************************************************************

FIND CLOSEST FIGURE

Finds the figure which has the closest point to the given
point. It is quite possible for there to be none, one, some
or all such figures. Only the first such figure is returned,
and is a random selection of equidistant figures.
A flag indicates that only wires or junctions are to be considered.

**************************************************************}

procedure nearest(x, y:  integer;  { point location }
                  var p: drwptr;   { returns the figure }
                  var d: integer;  { returns the distance }
                  w:     boolean;  { wires only flag }
                  c:     boolean); { cells only flag }

var min: integer;
    mp:  drwptr;

{ search individual list }

procedure schlst(p: drwptr);

begin

   while p <> nil do begin { traverse list }

      if (((p^.typ = twire) or (p^.typ = tjunction) or
         (p^.typ = tconnect) or (p^.typ = tbus) or not w) and
         not c) or
         (((p^.typ in [tcell, tnmos, tpmos, tcap, tres, tdiode,
                       tvdd, tvss]) or not c) and not w) then begin

         d := mindist(x, y, p); { find distance to figure }
         if (mp = nil) or (d < min) then begin

            { 1st entry or new low }
            min := d; { set distance }
            mp := p { set figure }

         end

      end;
      p := p^.next { next entry }

   end

end;

begin

   mp := nil; { set no entry }
   min := 0;
   schlst(curwin^.cs^.dl[ltcell]); { search all lists but intersections }
   schlst(curwin^.cs^.dl[ltfig]);
   schlst(curwin^.cs^.dl[ltovg]);
   schlst(curwin^.cs^.dl[ltvia]);
   schlst(curwin^.cs^.dl[ltmet2]);
   schlst(curwin^.cs^.dl[ltcont]);
   schlst(curwin^.cs^.dl[ltpmd]);
   schlst(curwin^.cs^.dl[ltwell]);
   p := mp; { return result }
   d := min

end;
{}
{**************************************************************

ROTATE SINGLE POINT X

Rotate a single point for predefined figures.

**************************************************************}

function rotx(sx, sy, ex, ey: integer; { figure region }
              ox:             integer; { destination origin x }
              x, y:           integer; { point to rotate }
              r:              rotmod)  { rotation mode }
              : integer;               { rotated x }

begin

   case r of { rotate }

      rm0:    rotx := x-sx+ox;
      rm90:   rotx := abs(ey-sy)-(y-sy)+ox;
      rm180:  rotx := abs(ex-sx)-(x-sx)+ox;
      rm270:  rotx := y-sy+ox;
      rmm0:   rotx := abs(ex-sx)-(x-sx)+ox;
      rmm90:  rotx := abs(ey-sy)-(y-sy)+ox;
      rmm180: rotx := x-sx+ox;
      rmm270: rotx := y-sy+ox

   end

end;
{}
{**************************************************************

ROTATE SINGLE POINT Y

Rotate a single point for predefined figures.

**************************************************************}

function roty(sx, sy, ex, ey: integer; { figure region }
              oy:             integer; { destination origin y }
              x, y:           integer; { point to rotate }
              r:              rotmod)  { rotation mode }
              : integer;               { rotated y }

begin

   case r of { rotate }

      rm0:    roty := y-sy+oy;
      rm90:   roty := x-sx+oy;
      rm180:  roty := abs(ey-sy)-(y-sy)+oy;
      rm270:  roty := abs(ex-sx)-(x-sx)+oy;
      rmm0:   roty := y-sy+oy;
      rmm90:  roty := abs(ex-sx)-(x-sx)+oy;
      rmm180: roty := abs(ey-sy)-(y-sy)+oy;
      rmm270: roty := x-sx+oy

   end

end;
{}
{**************************************************************

DRAW ROTATED LINE

Draws a rotated line for predefined figures.

**************************************************************}

{ draw rotated real line }

procedure linerr(x1, y1, x2, y2: integer; { line coordinates }
                 ox, oy:         integer; { origin }
                 sx, sy:         integer; { size }
                 s:              integer; { scale }
                 c:              color;   { color }
                 r:              rotmod;  { rotation mode }
                 cr:             region); { clip region }

begin

   liner(rotx(ox, oy, sx*s+ox, sy*s+oy, ox, x1*s+ox, y1*s+oy, r),
         roty(ox, oy, sx*s+ox, sy*s+oy, oy, x1*s+ox, y1*s+oy, r),
         rotx(ox, oy, sx*s+ox, sy*s+oy, ox, x2*s+ox, y2*s+oy, r),
         roty(ox, oy, sx*s+ox, sy*s+oy, oy, x2*s+ox, y2*s+oy, r),
         c, cr)

end;
{}
{**************************************************************

DRAW NMOS TRANSISTOR

Draws a NMOS transistor at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwnmos(ox, oy: integer; { origin }
                  s:      integer; { scale }
                  c:      color;   { color }
                  r:      rotmod;  { rotation mode }
                  cr:     region); { clip region }

begin

   linerr(0, 4, 2, 4, ox, oy, 7, 8, s, c, r, cr);
   linerr(2, 2, 2, 6, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 2, 3, 6, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 2, 5, 2, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 6, 5, 6, ox, oy, 7, 8, s, c, r, cr);
   linerr(5, 0, 5, 2, ox, oy, 7, 8, s, c, r, cr);
   linerr(5, 6, 5, 8, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 4, 4, 3, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 4, 4, 5, ox, oy, 7, 8, s, c, r, cr);
   linerr(4, 3, 4, 5, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 4, 7, 4, ox, oy, 7, 8, s, c, r, cr)

end;
{}
{**************************************************************

DRAW PMOS TRANSISTOR

Draws a PMOS transistor at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwpmos(ox, oy: integer; { origin }
                  s:      integer; { scale }
                  c:      color;   { color }
                  r:      rotmod;  { rotation mode }
                  cr:     region); { clip region }

begin

   linerr(0, 4, 2, 4, ox, oy, 7, 8, s, c, r, cr);
   linerr(2, 2, 2, 6, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 2, 3, 6, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 2, 5, 2, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 6, 5, 6, ox, oy, 7, 8, s, c, r, cr);
   linerr(5, 0, 5, 2, ox, oy, 7, 8, s, c, r, cr);
   linerr(5, 6, 5, 8, ox, oy, 7, 8, s, c, r, cr);
   linerr(5, 4, 4, 3, ox, oy, 7, 8, s, c, r, cr);
   linerr(5, 4, 4, 5, ox, oy, 7, 8, s, c, r, cr);
   linerr(4, 3, 4, 5, ox, oy, 7, 8, s, c, r, cr);
   linerr(3, 4, 7, 4, ox, oy, 7, 8, s, c, r, cr)

end;
{}
{**************************************************************

DRAW CAPACITOR

Draws a capacitor at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwcap(ox, oy: integer; { origin }
                 s:      integer; { scale }
                 c:      color;   { color }
                 r:      rotmod;  { rotation mode }
                 cr:     region); { clip region }

begin

   linerr(2, 0, 2, 2, ox, oy, 4, 5, s, c, r, cr);
   linerr(2, 3, 2, 5, ox, oy, 4, 5, s, c, r, cr);
   linerr(0, 2, 4, 2, ox, oy, 4, 5, s, c, r, cr);
   linerr(0, 3, 4, 3, ox, oy, 4, 5, s, c, r, cr)

end;
{}
{**************************************************************

DRAW DIODE

Draws a diode at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwdiode(ox, oy: integer; { origin }
                   s:      integer; { scale }
                   c:      color;   { color }
                   r:      rotmod;  { rotation mode }
                   cr:     region); { clip region }

begin

   linerr(2, 0, 2, 2, ox, oy, 4, 8, s, c, r, cr);
   linerr(0, 2, 4, 2, ox, oy, 4, 8, s, c, r, cr);
   linerr(2, 2, 0, 6, ox, oy, 4, 8, s, c, r, cr);
   linerr(2, 2, 4, 6, ox, oy, 4, 8, s, c, r, cr);
   linerr(0, 6, 4, 6, ox, oy, 4, 8, s, c, r, cr);
   linerr(2, 6, 2, 8, ox, oy, 4, 8, s, c, r, cr)

end;
{}
{**************************************************************

DRAW VDD

Draws a VDD connector at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwvdd(ox, oy: integer; { origin }
                 s:      integer; { scale }
                 c:      color;   { color }
                 r:      rotmod;  { rotation mode }
                 cr:     region); { clip region }

begin

   linerr(1, 0, 0, 2, ox, oy, 2, 4, s, c, r, cr);
   linerr(1, 0, 2, 2, ox, oy, 2, 4, s, c, r, cr);
   linerr(0, 2, 2, 2, ox, oy, 2, 4, s, c, r, cr);
   linerr(1, 2, 1, 4, ox, oy, 2, 4, s, c, r, cr)

end;
{}
{**************************************************************

DRAW VSS

Draws a VSS connector at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwvss(ox, oy: integer; { origin }
                 s:      integer; { scale }
                 c:      color;   { color }
                 r:      rotmod;  { rotation mode }
                 cr:     region); { clip region }

begin

   linerr(1, 0, 1, 2, ox, oy, 2, 4, s, c, r, cr);
   linerr(0, 2, 2, 2, ox, oy, 2, 4, s, c, r, cr);
   linerr(0, 2, 1, 4, ox, oy, 2, 4, s, c, r, cr);
   linerr(2, 2, 1, 4, ox, oy, 2, 4, s, c, r, cr)

end;
{}
{**************************************************************

DRAW RESISTOR

Draws a resistor at the given origin, scale and color,
and rotation.

**************************************************************}

procedure drwres(ox, oy: integer; { origin }
                 s:      integer; { scale }
                 c:      color;   { color }
                 r:      rotmod;  { rotation mode }
                 cr:     region); { clip region }

begin

   linerr(2, 0,  2, 4,  ox, oy, 4, 20, s, c, r, cr);
   linerr(2, 4,  0, 5,  ox, oy, 4, 20, s, c, r, cr);
   linerr(0, 5,  4, 7,  ox, oy, 4, 20, s, c, r, cr);
   linerr(4, 7,  0, 9,  ox, oy, 4, 20, s, c, r, cr);
   linerr(0, 9,  4, 11, ox, oy, 4, 20, s, c, r, cr);
   linerr(4, 11, 0, 13, ox, oy, 4, 20, s, c, r, cr);
   linerr(0, 13, 4, 15, ox, oy, 4, 20, s, c, r, cr);
   linerr(4, 15, 2, 16, ox, oy, 4, 20, s, c, r, cr);
   linerr(2, 16, 2, 20, ox, oy, 4, 20, s, c, r, cr)

end;
{}
{**************************************************************

FIND NET MIRROR ON CELL

Finds the net product of two transforms.
This is for when a cell with any given transform
is placed into another cell with it's own transform.
I suspect that the product is associative, but have not
tried the experiment.

**************************************************************}

function netmir(rt,         { containing cell }
                rm: rotmod) { cell contained }
                : rotmod;   { net rotation }

var rc:     rotmod;
    ra, rb: 0..7;

begin

   ra := ord(rm); { find unmirrored equivalents }
   if rm > rm270 then ra := ra - ord(rmm0);
   rb := ord(rt);
   if rt > rm270 then rb := rb - ord(rmm0);
   rb := ra+rb; { find net rotation }
   { adjust for wraparound }
   if rb > ord(rm270) then rb := rb - ord(rmm0);
   { check net mirroring effect }
   if (rm in [rm0, rm90, rm180, rm270]) =
      (rt in [rm0, rm90, rm180, rm270]) then
         case rb of { normal rotation }

      0: rc := rm0;
      1: rc := rm90;
      2: rc := rm180;
      3: rc := rm270

   end else case rb of { mirrored rotation }

      0: rc := rmm0;
      1: rc := rmm90;
      2: rc := rmm180;
      3: rc := rmm270

   end;
   netmir := rc { return result }

end;
{}
{**************************************************************

FIND CELL ORIGIN CORRECTION FOR ROTATION

Finds the origin of a cell to be included in another cell,
considering the rotations of both.

**************************************************************}

procedure corrot(
                 { region of container cell }
                     x1, y1, x2, y2: integer;
                 { origin of container cell }
                     ox, oy:        integer;
                 { included cell origin }
                 var co:             point;
                 { lengths of cell sides }
                     lx, ly:         integer;
                 { rotation of container cell }
                     rt:             rotmod;
                 { rotation of included cell }
                     cr:             rotmod);

var sx, sy: integer;

begin

   sx := co.x; { save coordinates }
   sy := co.y;
   co.x := rotx(x1, y1, x2, y2, ox, sx, sy, rt); { find rotated coordinates }
   co.y := roty(x1, y1, x2, y2, oy, sx, sy, rt);
   { add corrections }
   if cr in [rm0, rm180, rmm0, rmm180] then
      case rt of { rotation }

      rm0:    ;
      rm90:   co.x := co.x-ly;
      rm180:  begin co.x := co.x-lx; co.y := co.y-ly end;
      rm270:  co.y := co.y-lx;
      rmm0:   co.x := co.x-lx;
      rmm90:  begin co.x := co.x-ly; co.y := co.y-lx end;
      rmm180: co.y := co.y-ly;
      rmm270:

   end else case rt of { rotation }

      rm0:    ;
      rm90:   co.x := co.x-lx;
      rm180:  begin co.x := co.x-ly; co.y := co.y-lx end;
      rm270:  co.y := co.y-ly;
      rmm0:   co.x := co.x-ly;
      rmm90:  begin co.x := co.x-lx; co.y := co.y-ly end;
      rmm180: co.y := co.y-lx;
      rmm270:

   end

end;
{}
{**************************************************************

DRAW CELL FIGURE

Draws the given figure with bounding per the cell and origin.

**************************************************************}

{ this is declared ahead }

procedure drwcell(p: shtptr; ct: celtyp; ox, oy: integer; r: rotmod;
                  cl: color; co: boolean; ln: laytyp;
                  cpr: region); forward;

procedure drwfigc(d:      drwptr;  { figure to draw }
                  p:      shtptr;  { cell sheet }
                  ct:     celtyp;  { cell type }
                  ox, oy: integer; { cell origin }
                  rt:     rotmod;  { cell rotation }
                  clr:    color;   { override color }
                  cov:    boolean; { override flag }
                  ln:     laytyp;  { draw layer }
                  cpr:    region); { clip region }

var x1, y1, x2, y2: integer;
    x, y, xa:       integer;
    cp:             chrptr;
    tr:             boolean;
    rc:             rotmod;
    ra, rb:         0..7;
    co:             point; { cell origin }
    te, be:         boolean; { layer flags }

begin

   if ct in [ctsch, ctlay] then begin

      { set bounds schematic or layout }
      x1 := p^.bbsx;
      y1 := p^.bbsy;
      x2 := p^.bbex;
      y2 := p^.bbey

   end else begin

      { symbol }
      x1 := p^.sbbsx;
      y1 := p^.sbbsy;
      x2 := p^.sbbex;
      y2 := p^.sbbey

   end;
   { set normal color if not overridden }
   if not cov then clr := d^.cl;
   with d^ do case typ of { figure }

      { line }
      tline: if (l.s.x = l.e.x) or (l.s.y = l.e.y) then
                { orthogonal line, use critical region }
                liner(rotx(x1, y1, x2, y2, ox, l.s.x, l.s.y, rt),
                      roty(x1, y1, x2, y2, oy, l.s.x, l.s.y, rt),
                      rotx(x1, y1, x2, y2, ox, l.e.x, l.e.y, rt),
                      roty(x1, y1, x2, y2, oy, l.e.x, l.e.y, rt),
                      clr, cpr)
             else
                { else use viewport }
                liner(rotx(x1, y1, x2, y2, ox, l.s.x, l.s.y, rt),
                      roty(x1, y1, x2, y2, oy, l.s.x, l.s.y, rt),
                      rotx(x1, y1, x2, y2, ox, l.e.x, l.e.y, rt),
                      roty(x1, y1, x2, y2, oy, l.e.x, l.e.y, rt),
                      clr, curwin^.cs^.vp.v);
      { wire }
      { port: original read the tline variant field l on a twire entry
        (harmless under SVS free-union semantics, caught by P6 variant
        checking); the guard now reads the wire's own field w }
      twire: if (w.s.x = w.e.x) or (w.s.y = w.e.y) then
                { orthogonal line, use critical region }
                liner(rotx(x1, y1, x2, y2, ox, w.s.x, w.s.y, rt),
                      roty(x1, y1, x2, y2, oy, w.s.x, w.s.y, rt),
                      rotx(x1, y1, x2, y2, ox, w.e.x, w.e.y, rt),
                      roty(x1, y1, x2, y2, oy, w.e.x, w.e.y, rt),
                      clr, cpr)
             else
                { else use viewport }
                liner(rotx(x1, y1, x2, y2, ox, w.s.x, w.s.y, rt),
                      roty(x1, y1, x2, y2, oy, w.s.x, w.s.y, rt),
                      rotx(x1, y1, x2, y2, ox, w.e.x, w.e.y, rt),
                      roty(x1, y1, x2, y2, oy, w.e.x, w.e.y, rt),
                      clr, curwin^.cs^.vp.v);
      { bold line }
      tbline: bliner(rotx(x1, y1, x2, y2, ox, l.s.x, l.s.y, rt),
                     roty(x1, y1, x2, y2, oy, l.s.x, l.s.y, rt),
                     rotx(x1, y1, x2, y2, ox, l.e.x, l.e.y, rt),
                     roty(x1, y1, x2, y2, oy, l.e.x, l.e.y, rt),
                     clr, cpr);
      { bus }
      tbus: bliner(rotx(x1, y1, x2, y2, ox, bs.l.s.x, bs.l.s.y, rt),
                   roty(x1, y1, x2, y2, oy, bs.l.s.x, bs.l.s.y, rt),
                   rotx(x1, y1, x2, y2, ox, bs.l.e.x, bs.l.e.y, rt),
                   roty(x1, y1, x2, y2, oy, bs.l.e.x, bs.l.e.y, rt),
                   clr, cpr);
      { box }
      tbox: boxr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                 clr, cpr);
      { bold box }
      tbbox: bboxr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                   roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                   rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                   roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                   clr, cpr);
      { arc or circle }
      tarc: with a do if rt in [rm0, rm90, rm180, rm270] then { normal }
                 arcr(rotx(x1, y1, x2, y2, ox, s.x, s.y, rt),
                      roty(x1, y1, x2, y2, oy, s.x, s.y, rt),
                      rotx(x1, y1, x2, y2, ox, e.x, e.y, rt),
                      roty(x1, y1, x2, y2, oy, e.x, e.y, rt),
                      rotx(x1, y1, x2, y2, ox, c.x, c.y, rt),
                      roty(x1, y1, x2, y2, oy, c.x, c.y, rt),
                      r, clr, cpr)
            else { mirrored, swap end and start }
                 arcr(rotx(x1, y1, x2, y2, ox, e.x, e.y, rt),
                      roty(x1, y1, x2, y2, oy, e.x, e.y, rt),
                      rotx(x1, y1, x2, y2, ox, s.x, s.y, rt),
                      roty(x1, y1, x2, y2, oy, s.x, s.y, rt),
                      rotx(x1, y1, x2, y2, ox, c.x, c.y, rt),
                      roty(x1, y1, x2, y2, oy, c.x, c.y, rt),
                      r, clr, cpr);
      { vector character }
      tchar: begin

         { determine overall width of x }
         cp := c.l; { index 1st character }
         xa := 0; { clear total }
         while cp <> nil do begin { count }

               xa := xa+chrwdt*c.s;
               if cp^.next <> nil then { count intercharacter space }
                  xa := xa+chrspc*c.s;
               cp := cp^.next { next character }

         end;
         { set starting coordinates }
         x := rotx(x1, y1, x2, y2, ox, c.r.s.x, c.r.s.y, rt);
         y := roty(x1, y1, x2, y2, oy, c.r.s.x, c.r.s.y, rt);
         cp := c.l; { index 1st character }
         { determine rotation of text }
         if d^.rm = rm90 then begin { rotated }

            case rt of { cell rotation }

               rm0:    ;
               rm90:   x := x-xa;
               rm180:  begin x := x-chrhdt*c.s; y := y-xa end;
               rm270:  y := y-chrhdt*c.s;
               rmm0:   x := x-chrhdt*c.s;
               rmm90:  begin x := x-xa; y := y-chrhdt*c.s end;
               rmm180: y := y-xa;
               rmm270: ;

            end

         end else begin { normal }

            case rt of { cell rotation }

               rm0:    ;
               rm90:   x := x-chrhdt*c.s;
               rm180:  begin x := x-xa; y := y-chrhdt*c.s end;
               rm270:  y := y-xa;
               rmm0:   x := x-xa;
               rmm90:  begin x := x-chrhdt*c.s; y := y-xa end;
               rmm180: y := y-chrhdt*c.s;
               rmm270: ;

            end

         end;
         tr := (rm = rm90) <> ((rt = rm90) or (rt = rm270) or
                               (rt = rmm90) or (rt = rmm270));
         while cp <> nil do begin { draw characters }

            if cp^.c <> ' ' then { not space }
               vchar(x, y, cp^.c, c.s, clr, tr, cpr);
            { move intercharacter gap }
            if tr then { rotated text }
               y := y+chrwdt*c.s+chrspc*c.s
            else { normal text }
               x := x+chrwdt*c.s+chrspc*c.s;
            cp := cp^.next { next character }

         end

      end;
      { wire junction }
      tjunction: pier(rotx(x1, y1, x2, y2, ox, j.x, j.y, rt),
                      roty(x1, y1, x2, y2, oy, j.x, j.y, rt),
                      curwin^.cs^.js, clr, cpr);
      { connector (appears in schematic cells only ) }
      tconnect: if ct in [ctsch, ctlay] then { schematic }
         conr(rotx(x1, y1, x2, y2, ox, j.x, j.y, rt),
              roty(x1, y1, x2, y2, oy, j.x, j.y, rt),
              curwin^.cs^.cs, clr, cpr);
      { subcell }
      tcell: begin

         co := cr.o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, abs(cr.cp^.bbex-cr.cp^.bbsx)+1,
                abs(cr.cp^.bbey-cr.cp^.bbsy)+1, rt, rm);
         { draw with net rotation }
         drwcell(cr.cp, cr.ct, co.x, co.y, netmir(rt, rm), clr,
                 cov, ln, cpr)

      end;

      { nmos transistor }
      tnmos: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 7*1500, 8*1500, rt, rm);
         { draw with net rotation }
         drwnmos(co.x, co.y, 1500, clr, netmir(rt, rm), cpr)

      end;

      { pmos transistor }
      tpmos: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 7*1500, 8*1500, rt, rm);
         { draw with net rotation }
         drwpmos(co.x, co.y, 1500, clr, netmir(rt, rm), cpr)

      end;

      { capacitor }
      tcap: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 4*1500, 5*1500, rt, rm);
         { draw with net rotation }
         drwcap(co.x, co.y, 1500, clr, netmir(rt, rm), cpr)

      end;

      { diode }
      tdiode: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 4*1500, 8*1500, rt, rm);
         { draw with net rotation }
         drwdiode(co.x, co.y, 1500, clr, netmir(rt, rm), cpr)

      end;

      { vdd connector }
      tvdd: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 2*1500, 4*1500, rt, rm);
         { draw with net rotation }
         drwvdd(co.x, co.y, 1500, clr, netmir(rt, rm), cpr)

      end;

      { vss connector }
      tvss: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 2*1500, 4*1500, rt, rm);
         { draw with net rotation }
         drwvss(co.x, co.y, 1500, clr, netmir(rt, rm), cpr)

      end;

      { resistor }
      tres: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 4*750, 20*750, rt, rm);
         { draw with net rotation }
         drwres(co.x, co.y, 750, clr, netmir(rt, rm), cpr)

      end;

      { layers }
      tmet1: if button[bmet1vis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tmet2: if button[bmet2vis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tpoly: if button[bpolyvis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tvia:  if button[bviavis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tcont: if button[bcontvis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tndiff: if button[bndiffvis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tpdiff: if button[bpdiffvis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tnwell: if button[bnwellvis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tpwell: if button[bpwellvis].act then { layer enabled }
         blockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
                roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
                roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
                clr, cpr);
      tinter: begin { intersection }

         case itt of { top layer }

            { find layer statuses }
            tmet1:  te := button[bmet1vis].act;
            tmet2:  te := button[bmet2vis].act;
            tpoly:  te := button[bpolyvis].act;
            tndiff: te := button[bndiffvis].act;
            tpdiff: te := button[bpdiffvis].act;
            tcont:  te := button[bcontvis].act;

            else { port: partial case; unmatched types ignored }

         end;
         case itb of { buttom layer }

            { find layer statuses }
            tmet1:  be := button[bmet1vis].act;
            tmet2:  be := button[bmet2vis].act;
            tpoly:  be := button[bpolyvis].act;
            tndiff: be := button[bndiffvis].act;
            tpdiff: be := button[bpdiffvis].act;
            tcont:  be := button[bcontvis].act;

            else { port: partial case; unmatched types ignored }

         end;
         if te and be then { both layers enabled }
         blockr(rotx(x1, y1, x2, y2, ox, ir.s.x, ir.s.y, rt),
                roty(x1, y1, x2, y2, oy, ir.s.x, ir.s.y, rt),
                rotx(x1, y1, x2, y2, ox, ir.e.x, ir.e.y, rt),
                roty(x1, y1, x2, y2, oy, ir.e.x, ir.e.y, rt),
                clr, cpr);

      end;

      { contact cut }
      tccut: if button[bccutvis].act then { layer enabled }
         boxr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt),
              roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
              rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt),
              roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt),
              clr, cpr);

      else { port: partial case; unmatched types ignored }

   end

end;
{}
{**************************************************************

DRAW SUBCELL

Draws a given subsheet, with border adjustment.

**************************************************************}

{ port: the parameter list is repeated on resolution of the
  forward (Pascaline allows this; the original commented it out) }

procedure drwcell(p:      shtptr;
                  ct:     celtyp;
                  ox, oy: integer;
                  r:      rotmod;
                  cl:     color;
                  co:     boolean;
                  ln:     laytyp;
                  cpr:    region);

var d: drwptr;
    cr: region; { cell region }

begin

   if (button[binsides].act) or (ln = ltfig) then begin

      { if show insides is true, or is figures layer }
      { find bounds of cell }
      cr.s.x := ox;
      cr.s.y := oy;
      if r in [rm0, rm180, rmm0, rmm180] then begin { normal }

         cr.e.x := ox + abs(p^.bbex - p^.bbsx);
         cr.e.y := oy + abs(p^.bbey - p^.bbsy)

      end else begin { on side }

         cr.e.x := ox + abs(p^.bbey - p^.bbsy);
         cr.e.y := oy + abs(p^.bbex - p^.bbsx)

      end;
      viewc(cr.s, curwin^.cs^.vp); { convert to screen }
      viewc(cr.e, curwin^.cs^.vp);
      { check cell lies within viewport }
      if (cr.e.x >= cpr.s.x) and
         (cr.s.x <= cpr.e.x) and
         (cr.e.y >= cpr.s.y) and
         (cr.s.y <= cpr.e.y) then begin

         { do requested layer }
         d := p^.dl[ln]; { index top of draw list }
         while d <> nil do begin { draw from list }

            drwfigc(d, p, ct, ox, oy, r, cl, co, ln, cpr); { draw }
            d := d^.next { next entry }

         end;
         { do subcells }
         d := p^.dl[ltcell]; { index top of draw list }
         while d <> nil do begin { draw from list }

            drwfigc(d, p, ct, ox, oy, r, cl, co, ln, cpr); { draw }
            d := d^.next { next entry }

         end

      end

   end

end;
{}
{**************************************************************

DRAW FIGURE

Draws the given figure in the given color. We have the ability
to "override" the color of figures drawn, to any given color.
This includes all subcell references.
The screen region to draw into is given.

**************************************************************}

procedure drwfig(p:   drwptr;  { entry to draw }
                 clr: color;   { override color }
                 co:  boolean; { override flag }
                 ln:  laytyp;  { layer to draw }
                 r:   region); { clip region }

var x, y:   integer;
    cp:     chrptr;
    te, be: boolean; { layer flags }

begin

   { if not color override then set normal color }
   if not co then clr := p^.cl;
   with p^ do case typ of { figure }

      { line }
      tline: if (l.s.x = l.e.x) or (l.s.y = l.e.y) then
                { orthogonal line, use critical region }
                liner(l.s.x, l.s.y, l.e.x, l.e.y, clr, r)
             else
                { else use viewport }
                liner(l.s.x, l.s.y, l.e.x, l.e.y, clr, curwin^.cs^.vp.v);

      { wire }
      { port: original read the tline variant field l on a twire entry
        (harmless under SVS free-union semantics, caught by P6 variant
        checking); the guard now reads the wire's own field w }
      twire: if (w.s.x = w.e.x) or (w.s.y = w.e.y) then
                { orthogonal line, use critical region }
                liner(w.s.x, w.s.y, w.e.x, w.e.y, clr, r)
             else
                { else use viewport }
                liner(w.s.x, w.s.y, w.e.x, w.e.y, clr, curwin^.cs^.vp.v);

      { bold line }
      tbline: bliner(l.s.x, l.s.y, l.e.x, l.e.y, clr, r);

      { bus }
      tbus: bliner(bs.l.s.x, bs.l.s.y, bs.l.e.x, bs.l.e.y, clr, r);

      { box }
      tbox: boxr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);

      { bold box }
      tbbox: bboxr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);

      { arc or circle }
      tarc: arcr(a.s.x, a.s.y, a.e.x, a.e.y,
                 a.c.x, a.c.y, a.r, clr, r);

      { vector character }
      tchar: begin

         x := c.r.s.x; { set starting coordinates }
         y := c.r.s.y;
         cp := c.l; { index 1st character }
         while cp <> nil do begin { draw characters }

            if cp^.c <> ' ' then { not space }
               vchar(x, y, cp^.c, c.s, clr, rm = rm90, r);
            { move intercharacter gap }
            if rm = rm90 then { rotated text }
               y := y+chrwdt*c.s+chrspc*c.s
            else { normal text }
               x := x+chrwdt*c.s+chrspc*c.s;
            cp := cp^.next { next character }

         end

      end;

      { wire junction }
      tjunction: pier(j.x, j.y, curwin^.cs^.js, clr, r);

      { connector }
      tconnect: conr(j.x, j.y, curwin^.cs^.cs, clr, r);

      { subcell }
      tcell: drwcell(cr.cp, cr.ct, cr.o.x, cr.o.y, rm, clr, co, ln, r);

      { nmos transistor }
      tnmos: drwnmos(o.x, o.y, 1500, clr, rm, r);

      { pmos transistor }
      tpmos: drwpmos(o.x, o.y, 1500, clr, rm, r);

      { capacitor }
      tcap: drwcap(o.x, o.y, 1500, clr, rm, r);

      { diode }
      tdiode: drwdiode(o.x, o.y, 1500, clr, rm, r);

      { vdd connector }
      tvdd: drwvdd(o.x, o.y, 1500, clr, rm, r);

      { vss connector }
      tvss: drwvss(o.x, o.y, 1500, clr, rm, r);

      { resistor }
      tres: drwres(o.x, o.y, 750, clr, rm, r);

      { layers }
      tmet1: if button[bmet1vis].act then { layer enabled }
                blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tmet2: if button[bmet2vis].act then { layer enabled }
                blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tpoly: if button[bpolyvis].act then { layer enabled }
                blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tvia:  if button[bviavis].act then { layer enabled }
                blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tcont: if button[bcontvis].act then { layer enabled }
                blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tndiff: if button[bndiffvis].act then { layer enabled }
                 blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tpdiff: if button[bpdiffvis].act then { layer enabled }
                 blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tnwell: if button[bnwellvis].act then { layer enabled }
                 blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tpwell: if button[bpwellvis].act then { layer enabled }
                 blockr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);
      tinter: begin { intersection }

         case itt of { top layer }

            { find layer statuses }
            tmet1:  te := button[bmet1vis].act;
            tmet2:  te := button[bmet2vis].act;
            tpoly:  te := button[bpolyvis].act;
            tndiff: te := button[bndiffvis].act;
            tpdiff: te := button[bpdiffvis].act;
            tcont:  te := button[bcontvis].act;

            else { port: partial case; unmatched types ignored }

         end;
         if (ipt^.typ = tcell) and not button[binsides].act then
            te := false; { in cell, and insides off }
         case itb of { buttom layer }

            { find layer statuses }
            tmet1:  be := button[bmet1vis].act;
            tmet2:  be := button[bmet2vis].act;
            tpoly:  be := button[bpolyvis].act;
            tndiff: be := button[bndiffvis].act;
            tpdiff: be := button[bpdiffvis].act;
            tcont:  be := button[bcontvis].act;

            else { port: partial case; unmatched types ignored }

         end;
         if (ipb^.typ = tcell) and not button[binsides].act then
            be := false; { in cell, and insides off }
         if te and be then { both layers enabled }
            blockr(ir.s.x, ir.s.y, ir.e.x, ir.e.y, clr, r)

      end;

      { contact cut }
      tccut: if button[bccutvis].act then { layer enabled }
                boxr(b.s.x, b.s.y, b.e.x, b.e.y, clr, r);

      ttrc: dtrace(ts, tl, r); { draw trace }

      tatrc: atrace(as, al, r) { draw analog trace }

      else { port: partial case; unmatched types ignored }

   end

end;
{}
{**************************************************************

DRAW FIGURES

Draws the entire figures list. Also draws in the grids, which
are placed in front of the layers and behind all line figures.

**************************************************************}

procedure drwfigs;

var ln: laytyp; { layer index }

{ draw single list }

procedure drwlist(p: drwptr);

begin

   while p <> nil do begin { draw from list }

      drwfig(p, p^.cl, false, ln, curwin^.cs^.vp.v); { draw }
      p := p^.next { next entry }

   end

end;

begin

   { port: the grid indicator vectors are deleted; the grids are
     drawn over the real extent of the view as in redraw }
   if button[blines].act then { line grid active }
      do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                yellow); { place grid lines }
   { draw layers }
   for ln := ltwell downto ltfig do begin

      drwlist(curwin^.cs^.dl[ln]); { draw standard }
      drwlist(curwin^.cs^.dl[ltcell]) { draw cells }

   end;
   if button[bdots].act then { dot grid active }
      dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
             curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
             black); { place dots }

end;
{}
{**************************************************************

CALCULATE FIGURE BOUNDS

Finds the bounding box for a figure. Note that the overlap
from bold figures is not considered. The bounding box returned
is "correct", in that x1 < x2, y1 < y2.

**************************************************************}

procedure fndbound(p: drwptr; var x1, y1, x2, y2: integer);

var t: integer;

begin

   { find the figures' bounding box }
   with p^ do case typ of { figure }

      tline, tbline: begin

         x1 := l.s.x;
         y1 := l.s.y;
         x2 := l.e.x;
         y2 := l.e.y

      end;

      twire: begin

         x1 := w.s.x;
         y1 := w.s.y;
         x2 := w.e.x;
         y2 := w.e.y

      end;

      tbus: begin

         x1 := bs.l.s.x;
         y1 := bs.l.s.y;
         x2 := bs.l.e.x;
         y2 := bs.l.e.y

      end;

      tbox, tbbox, tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
      tnwell, tpwell, tccut, tcont: begin

         x1 := b.s.x;
         y1 := b.s.y;
         x2 := b.e.x;
         y2 := b.e.y

      end;

      { port: the original read b on tinter entries (free-union punning
        under SVS - ir sits at the same offset); P6 variant checking
        requires the tinter member ir }
      tinter: begin

         x1 := ir.s.x;
         y1 := ir.s.y;
         x2 := ir.e.x;
         y2 := ir.e.y

      end;

      tarc: begin

         x1 := a.c.x-a.r;
         y1 := a.c.y-a.r;
         x2 := a.c.x+a.r;
         y2 := a.c.y+a.r

      end;

      tjunction: begin

         x1 := j.x-curwin^.cs^.js;
         y1 := j.y-curwin^.cs^.js;
         x2 := j.x+curwin^.cs^.js;
         y2 := j.y+curwin^.cs^.js

      end;

      tconnect: begin

         x1 := j.x-curwin^.cs^.cs;
         y1 := j.y-curwin^.cs^.cs;
         x2 := j.x+curwin^.cs^.cs;
         y2 := j.y+curwin^.cs^.cs

      end;

      tchar: begin

         x1 := c.r.s.x;
         y1 := c.r.s.y;
         x2 := c.r.e.x;
         y2 := c.r.e.y

      end;

      tcell: begin

         x1 := cr.o.x; { calculate box }
         y1 := cr.o.y;
         if rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

            x2 := cr.o.x + abs(cr.cp^.bbex - cr.cp^.bbsx);
            y2 := cr.o.y + abs(cr.cp^.bbey - cr.cp^.bbsy)

         end else begin { on side }

            x2 := cr.o.x + abs(cr.cp^.bbey - cr.cp^.bbsy);
            y2 := cr.o.y + abs(cr.cp^.bbex - cr.cp^.bbsx)

         end

      end;

      tnmos, tpmos: begin

         x1 := o.x; { calculate box }
         y1 := o.y;
         if rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

            x2 := o.x+7*1500;
            y2 := o.y+8*1500

         end else begin { on side }

            x2 := o.x+8*1500;
            y2 := o.y+7*1500

         end

      end;

      tcap: begin

         x1 := o.x; { calculate box }
         y1 := o.y;
         if rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

            x2 := o.x+4*1500;
            y2 := o.y+5*1500

         end else begin { on side }

            x2 := o.x+5*1500;
            y2 := o.y+4*1500

         end

      end;

      tres: begin

         x1 := o.x; { calculate box }
         y1 := o.y;
         if rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

            x2 := o.x+4*750;
            y2 := o.y+20*750

         end else begin { on side }

            x2 := o.x+20*750;
            y2 := o.y+4*750

         end

      end;

      tdiode: begin

         x1 := o.x; { calculate box }
         y1 := o.y;
         if rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

            x2 := o.x+4*1500;
            y2 := o.y+8*1500

         end else begin { on side }

            x2 := o.x+8*1500;
            y2 := o.y+4*1500

         end

      end;

      tvdd, tvss: begin

         x1 := o.x; { calculate box }
         y1 := o.y;
         if rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

            x2 := o.x+2*1500;
            y2 := o.y+4*1500

         end else begin { on side }

            x2 := o.x+4*1500;
            y2 := o.y+2*1500

         end

      end

      else { port: partial case; unmatched types ignored }

   end;
   { swap region for proper order }
   if x1 > x2 then begin t := x1; x1 := x2; x2 := t end;
   if y1 > y2 then begin t := y1; y1 := y2; y2 := t end

end;
{}
{**************************************************************

REDRAW REAL REGION

Accepts a rectangular real region, and redraws the grids in that
region, and any figures that bound that region.
The region must be "correct" that is, x1 <= x2, and y1 < y2.

**************************************************************}

procedure rregion(x1, y1, x2, y2: integer);

var r:                  region;  { screen coordinates }
    { port: xi/yi/yis grid vector indexes deleted with the grid
      vectors }
    p:                  drwptr;  { drawing list pointer }
    ln:                 laytyp;  { layer index }

{ refresh figures as needed from drawing list }

procedure refresh(p: drwptr);

begin

   while p <> nil do begin { draw from list }

      drwfig(p, p^.cl, false, ln, r); { draw }
      p := p^.next { next entry }

   end

end;

{ refresh line grid }

{ port: the lgridsx/lgridsy grid position vectors are gone; the
  line grid is redrawn with the real coordinate do10sgrid over
  the region, clamped to the view }

procedure linegrid;

var gx1, gy1, gx2, gy2: integer; { clamped real region }

begin

   if button[blines].act then begin { line grid is active }

      gx1 := x1; { clamp region to view }
      gy1 := y1;
      gx2 := x2;
      gy2 := y2;
      if gx1 < curwin^.cs^.vp.r.s.x then gx1 := curwin^.cs^.vp.r.s.x;
      if gy1 < curwin^.cs^.vp.r.s.y then gy1 := curwin^.cs^.vp.r.s.y;
      if gx2 > curwin^.cs^.vp.r.e.x then gx2 := curwin^.cs^.vp.r.e.x;
      if gy2 > curwin^.cs^.vp.r.e.y then gy2 := curwin^.cs^.vp.r.e.y;
      do10sgrid(gx1, gy1, gx2, gy2, yellow) { place grid lines }

   end

end;

{ refresh dot grid }

{ port: as linegrid; the dgridsx/dgridsy vectors are replaced by
  the real coordinate dogrid }

procedure dotgrid;

var gx1, gy1, gx2, gy2: integer; { clamped real region }

begin

   if button[bdots].act then begin { dot grid is active }

      gx1 := x1; { clamp region to view }
      gy1 := y1;
      gx2 := x2;
      gy2 := y2;
      if gx1 < curwin^.cs^.vp.r.s.x then gx1 := curwin^.cs^.vp.r.s.x;
      if gy1 < curwin^.cs^.vp.r.s.y then gy1 := curwin^.cs^.vp.r.s.y;
      if gx2 > curwin^.cs^.vp.r.e.x then gx2 := curwin^.cs^.vp.r.e.x;
      if gy2 > curwin^.cs^.vp.r.e.y then gy2 := curwin^.cs^.vp.r.e.y;
      dogrid(gx1, gy1, gx2, gy2, black) { place grid dots }

   end

end;

begin

   { find equivalent screen region }
   r.s.x := x1;
   r.s.y := y1;
   viewc(r.s, curwin^.cs^.vp);
   r.e.x := x2;
   r.e.y := y2;
   viewc(r.e, curwin^.cs^.vp);
   if (r.s.x <= curwin^.cs^.vp.v.e.x) and
      (r.e.x >= curwin^.cs^.vp.v.s.x) and
      (r.s.y <= curwin^.cs^.vp.v.e.y) and
      (r.e.y >= curwin^.cs^.vp.v.s.y) then begin

      { overlaps viewport at some point }
      { clip to viewport }
      if r.s.x < curwin^.cs^.vp.v.s.x then r.s.x := curwin^.cs^.vp.v.s.x;
      if r.e.x > curwin^.cs^.vp.v.e.x then r.e.x := curwin^.cs^.vp.v.e.x;
      if r.s.y < curwin^.cs^.vp.v.s.y then r.s.y := curwin^.cs^.vp.v.s.y;
      if r.e.y > curwin^.cs^.vp.v.e.y then r.e.y := curwin^.cs^.vp.v.e.y;
      linegrid; { refresh line grid }
      { draw layers }
      for ln := ltwell downto ltcell do begin

         refresh(curwin^.cs^.dl[ln]); { refresh normal }
         refresh(curwin^.cs^.dl[ltcell]); { refresh cells }

      end;
      dotgrid { refresh dot grid }

   end

end;
{}
{**************************************************************

DRAW REAL REGION WITH FUDGE

Accepts a real region and redraws as in rregion, but adds
"fudge" to it, which the real equivalent of 3 screen pixels
at the current scale.

**************************************************************}

procedure frregion(x1, y1, x2, y2: integer);

var f: integer; { fudge factor }

begin

   f := realdist(3, curwin^.cs^.vp.s.x); { find the fudge factor }
   { apply fudge }
   x1 := x1 - f;
   x2 := x2 + f;
   y1 := y1 - f;
   y2 := y2 + f;
   rregion(x1, y1, x2, y2) { redraw region }

end;
{}
{**************************************************************

CLEAR OUT FIGURE

Accepts a draw figure, and clears it to white, then redraws
all other screen elements that could be erased also.
The area to be cleared is based on the bounding of the figure.
In the case of bold figures, we must use a 'fudge factor', based
the length of a screen pixel in real demensions.

**************************************************************}

procedure clrfig(p: drwptr);

var f:              integer; { fudge factor }
var x1, y1, x2, y2: integer; { bounding box }
    ln:             laytyp; { layer index }

begin

   rescur; { remove cursor }
   for ln := ltcell to ltwell do { layers }
      { draw the figure out (in white) }
      drwfig(p, white, true, ln, curwin^.cs^.vp.v);
   fndbound(p, x1, y1, x2, y2); { find object bounding box }
   if (p^.typ = tbline) or (p^.typ = tbbox) then
      frregion(x1, y1, x2, y2) { redraw region fudged }
   else
      rregion(x1, y1, x2, y2); { redraw region }
   setcur { reset cursor }

end;
{}
{**************************************************************

RECALCULATE BOUNDING BOX

Recalculates the bounding box based on the current figure list.
Note that overlap due to bold lines/boxes is not considered.

**************************************************************}

procedure rebound;

var p:              drwptr;
    x1, y1, x2, y2: integer;

{ bound given list }

procedure boundlst(p: drwptr);

begin

   while p <> nil do begin { traverse list }

      fndbound(p, x1, y1, x2, y2); { find object bounding box }
      setbound(x1, y1); { set bounds }
      setbound(x2, y2);
      if p^.typ <> tconnect then begin { not a connector }

         setsbound(x1, y1); { set bounds }
         setsbound(x2, y2);

      end;
      p := p^.next { next entry }

   end

end;

begin

   curwin^.cs^.bbsx := 0; { flag bounding box inactive }
   curwin^.cs^.bbex := 0;
   curwin^.cs^.bbsy := 0;
   curwin^.cs^.bbey := 0;
   curwin^.cs^.bs := false;
   curwin^.cs^.sbbsx := 0; { flag symbol bounding box inactive }
   curwin^.cs^.sbbex := 0;
   curwin^.cs^.sbbsy := 0;
   curwin^.cs^.sbbey := 0;
   curwin^.cs^.sbs := false;
   boundlst(curwin^.cs^.dl[ltcell]); { bound all lists }
   boundlst(curwin^.cs^.dl[ltfig]);
   boundlst(curwin^.cs^.dl[ltovg]);
   boundlst(curwin^.cs^.dl[ltvia]);
   boundlst(curwin^.cs^.dl[ltmet2]);
   boundlst(curwin^.cs^.dl[ltcont]);
   boundlst(curwin^.cs^.dl[ltpmd]);
   boundlst(curwin^.cs^.dl[ltwell]);
   chktar { check target change }

end;
{}
{**************************************************************

SMASH NODE

"smashes" the given node, or removes all the wires and junctions
composing the node, and reenters them all. This is done when
the composition of the node is in doubt, such as after one of
its members has been deleted. This throws the entire connectivity
of the node into question, since that member may have been
bridging sections of the node.

**************************************************************}

procedure smash(n: nodptr);

var p, p1, ps, pj: drwptr;
    ns:            butstr; { node name save }
    ts:            boolean; { node temp flag save }
    os:            byte; { node ordinal save }

begin

   { reestablish all node wires }
   ns := n^.name; { save parameters }
   ts := n^.tmp;
   os := n^.nord;
   p := n^.nl; { index 1st entry }
   ps := nil; { keep a list of such wires }
   pj := nil; { and junctions }
   while p <> nil do begin { delete all wires }

      p1 := p^.nl; { save next wire }
      delwire(p); { delete that wire }
      if p^.typ = twire then begin

         p^.nl := ps; { insert to wire holding list }
         ps := p

      end else begin

         p^.nl := pj; { insert to junction holding list }
         pj := p

      end;
      p := p1 { set next }

   end;
   { this next deserves explanation. We must insert all
     junctions before the wires. This is so that we do not
     duplicate junctions that get formed automatically
     during wire placement.  }
   while pj <> nil do begin { reinsert junctions }

      p := pj; { index that entry }
      pj := pj^.nl; { pop from list }
      lnkjun(p); { link junction }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      p^.nh^.name := ns; { replace node parameters }
      p^.nh^.tmp := ts;
      p^.nh^.nord := os

   end;
   while ps <> nil do begin { reinsert wires }

      p := ps; { index that entry }
      ps := ps^.nl; { pop from list }
      lnkwire(p); { link wire }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      p^.nh^.name := ns; { replace node parameters }
      p^.nh^.tmp := ts;
      p^.nh^.nord := os

   end

end;
{}
{**************************************************************

SMASH BUS

As smash node, but works on a bus and all associated nodes.
Note that the local storage of ordinals is limited to 256,
for a total of 256 junctions, connectors and wires in the
entire bus net. This error is not caught, but should be.

**************************************************************}

procedure smashb(b: busptr);

var p:   drwptr;
    p1:  drwptr;
    ps:  drwptr;  { wire save list }
    psb: drwptr;  { bus save list }
    pj:  drwptr;  { junction save list }
    n:   nodptr;
    ns:  butstr;  { bus name save }
    ts:  boolean; { bus temp flag save }
    jos: array [byte] of byte; { junction ordinal save }
    ji:  byte; { index for same }
    wos: array [byte] of byte; { wire ordinal save }
    wi:  byte; { index for same }

begin

   ns := b^.name; { save parameters }
   ts := b^.tmp;
   ji := 0; { initalize save indexes }
   wi := 0;
   ps := nil; { clear destination wire list }
   psb := nil; { clear destination bus list }
   pj := nil; { and junction list }
   { remove wire entries from database }
   n := b^.nl; { index 1st node }
   while n <> nil do begin { delete all node lists }

      p := n^.nl; { index 1st entry }
      while p <> nil do begin { delete all wires }

         if p^.typ = twire then begin { wire }

            p1 := p^.nl; { save next wire }
            wos[wi] := p^.nh^.nord;
            wi := wi + 1

         end else begin { junction or connector }

            p1 := p^.nl; { save next wire }
            jos[ji] := p^.nh^.nord;
            ji := ji + 1

         end;
         delwire(p); { delete that wire }
         if p^.typ = twire then begin

            p^.nl := ps; { insert to wire holding list }
            ps := p

         end else begin

            p^.nl := pj; { insert to junction holding list }
            pj := p

         end;
         p := p1 { set next }

      end;
      n := n^.bl { next node entry }

   end;
   { remove bus entries from database }
   p := b^.bl; { index 1st bus entry }
   while p <> nil do begin { delete all busses }

      p1 := p^.bs.bl; { save next bus }
      delwire(p); { delete that bus }
      p^.bs.bl := psb; { insert to wire holding list }
      psb := p;
      p := p1 { set next }

   end;
   ji := 0; { initalize save indexes }
   wi := 0;
   { this next deserves explanation. We must insert all
     junctions before the wires. This is so that we do not
     duplicate junctions that get formed automatically
     during wire placement.  }
   while pj <> nil do begin { reinsert junctions }

      p := pj; { index that entry }
      pj := pj^.nl; { pop from list }
      lnkjun(p); { link junction }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      p^.nh^.name := ns; { replace node parameters }
      p^.nh^.tmp := ts;
      p^.nh^.nord := jos[ji]; { place ordinal }
      ji := ji + 1 { next }

   end;
   while psb <> nil do begin { reinsert busses }

      p := psb; { index that entry }
      psb := psb^.bs.bl; { pop from list }
      lnkbus(p); { link bus }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      p^.bs.bh^.name := ns; { replace bus parameters }
      p^.bs.bh^.tmp := ts

   end;
   while ps <> nil do begin { reinsert wires }

      p := ps; { index that entry }
      ps := ps^.nl; { pop from list }
      lnkwire(p); { link wire }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      p^.nh^.name := ns; { replace node parameters }
      p^.nh^.tmp := ts;
      p^.nh^.nord := wos[ji]; { place ordinal }
      wi := wi + 1 { next }

   end

end;
{}
{**************************************************************

DELETE FIGURE

The given figure is removed from all drawing and node lists.
Does not insure that nodes have connectivity, or handle
redraws.

**************************************************************}

procedure deletef(p: drwptr);

{ delete from individual list }

procedure dellst(var lp: drwptr);

var p1, ps: drwptr; { figure pointer }

begin

   ps := nil; { clear entry save }
   if p = lp then lp := lp^.next { delete top of list }
   else begin { delete mid list }

      p1 := lp; { index list top }
      while p1 <> nil do begin { traverse list }

         if p1^.next = p then ps := p1; { save matching entry }
         p1 := p1^.next { next entry }

      end;
      if ps <> nil then ps^.next := p^.next { gap over list }

   end

end;

{ delete from intersection list }

procedure delint(var lp: drwptr);

var p1, pl: drwptr; { figure pointer }

begin

   pl := nil; { clear last }
   p1 := lp; { index list top }
   while p1 <> nil do begin { traverse }

      if (p1^.ipt = p) or (p1^.ipb = p) then begin

         { entry found, gap over }
         if pl = nil then begin

            { top entry }
            lp := p1^.next; { gap list }
            p1 := lp { index top }

         end else begin

            pl^.next := p1^.next; { gap list }
            p1 := p1^.next { index next entry }

         end

      end else begin { next entry }

         pl := p1; { set last entry }
         p1 := p1^.next { index next }

      end

   end

end;

begin

   { delete figure from draw list }
   if (p^.typ = twire) or (p^.typ = tjunction) or (p^.typ = tbus) or
      (p^.typ = tconnect) then delwire(p) { delete wire or junction }
   else begin { ordinary figure }

      dellst(curwin^.cs^.dl[ltcell]); { delete from all lists }
      dellst(curwin^.cs^.dl[ltfig]);
      dellst(curwin^.cs^.dl[ltovg]);
      dellst(curwin^.cs^.dl[ltvia]);
      dellst(curwin^.cs^.dl[ltmet2]);
      dellst(curwin^.cs^.dl[ltcont]);
      dellst(curwin^.cs^.dl[ltpmd]);
      dellst(curwin^.cs^.dl[ltwell]);
      delint(curwin^.cs^.dl[ltism2]); { delete from intersections }
      delint(curwin^.cs^.dl[ltism1]);
      delint(curwin^.cs^.dl[ltisply])

   end

end;
{}
{**************************************************************

DELETE CLOSEST FIGURE

Finds the closest figure to the cursor and deletes that.

**************************************************************}

procedure delete;

var p, p1, ps, pj: drwptr;  { figure pointer }
    mx:            integer; { maximum distance to accept }
    d:             integer; { distance to figure }

begin

   if (curbut = bdelete) and
      (puck.b[1].a or puck.b[2].a or puck.b[3].a) then begin

      { set delete mode }
      stopact; { stop all modes }
      butact(bdelete); { set delete mode active }
      drmbut := bdelete;
      modbut := bdelete;
      dsmbut := bdelete

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { delete }
      { find screen pixels in real terms }
      mx := realdist(selrng, curwin^.cs^.vp.s.x);
      { find nearest figure }
      nearest(rcur.x, rcur.y, p, d, false, false);
      if (p <> nil) and (d <= mx) then begin { delete }

         deletef(p); { delete figure }
         clrfig(p); { clear the figure off screen }
         rescur; { lift cursor }
         rebound; { recalculate bounds }
         setcur; { replace cursor }
         if p^.typ = twire then begin

            if p^.nh <> nil then
               smash(p^.nh) { reestablish all node wires }

         end else if (p^.typ = tjunction) or
                     (p^.typ = tconnect) then begin

            if p^.nh <> nil then
               smash(p^.nh) { reestablish all node wires }

         end else if p^.typ = tbus then
            if p^.bs.bh <> nil then
               smashb(p^.bs.bh) { reestablish all bus sections }

      end;

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

DELETE NETWORK

Finds the closest wire figure to the cursor and deletes that,
and all wires in that node group.

**************************************************************}

procedure deletenet;

var p, p1: drwptr;  { figure pointer }
    n:     nodptr;  { node pointer }
    b:     busptr;  { bus pointer }
    mx:    integer; { maximum distance to accept }
    d:     integer; { distance to figure }

begin

   if (curbut = bdeleten) and
      (puck.b[1].a or puck.b[2].a or puck.b[3].a) then begin

      { set delete net mode }
      stopact; { stop all modes }
      butact(bdeleten); { set delete net mode active }
      drmbut := bdeleten;
      modbut := bdeleten;
      dsmbut := bdeleten

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { find screen pixels in real terms }
      mx := realdist(selrng, curwin^.cs^.vp.s.x);
      nearest(rcur.x, rcur.y, p, d, true, false); { find nearest wire }
      if (p <> nil) and (d <= mx) then begin

         { a wire, bus, junction or connector was found, and
           is close enough }
         { check if a wire, junction or connector, and is part
           of a bus. In this case, the rip becomes the bus. }
         { change to bus reference if on a bus }
         if p^.typ <> tbus then { wire, junction or connector }
            if p^.nh^.bh <> nil then p := p^.nh^.bh^.bl;
         if p^.typ = tbus then begin { bus }

            b := p^.bs.bh; { save bus }
            p := b^.bl; { index 1st bus segment }
            while p <> nil do begin { delete all bus segments }

               p1 := p^.bs.bl; { save next bus }
               delwire(p); { delete that bus }
               clrfig(p); { clear the bus off the screen }
               p := p1 { set next }

            end;
            n := b^.nl; { index top of node list }
            while n <> nil do begin { traverse nodes }

               p := n^.nl; { index 1st node in node list }
               while p <> nil do begin { delete all wires or junctions }

                  if p^.typ = twire then p1 := p^.nl; { save next wire }
                  delwire(p); { delete that wire or junction }
                  clrfig(p); { clear the wire off the screen }
                  p := p1 { set next }

               end;
               n := n^.bl { next node }

            end

         end else begin { wire, junction or connector }

            { index 1st node in node list }
            p := p^.nh^.nl;
            while p <> nil do begin { delete all wires or junctions }

               p1 := p^.nl; { save next wire }
               delwire(p); { delete that wire or junction }
               clrfig(p); { clear the wire off the screen }
               p := p1 { set next }

            end

         end;
         rescur; { lift cursor }
         rebound; { recalculate bounds }
         setcur { drop cursor }

      end

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

POP SUBCELL

Returns to the last cell in the cell stack.

**************************************************************}

procedure upcell;

begin

   if (celstk <> nil) and (puck.b[1].a or puck.b[2].a) then begin

      { stack is not empty, up cell }
      curwin^.cc := celstk^.cp; { place cell }
      celstk := celstk^.next; { pop }
      button[bcname].s := curwin^.cc^.name; { place cell name }
      rescur; { lift cursor }
      updbut(bcname); { update }
      setcur; { drop cursor }
      dispcell { display current cell }

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

ENTER SUBCELL

Finds the nearest subcell, and sets that as the active cell.

**************************************************************}

procedure downcell;

var p:  drwptr;  { figure pointer }
    mx: integer; { maximum distance to accept }
    d:  integer; { distance to figure }
    cp: celptr;  { cell pointer }
    cs: csvptr;  { cell save pointer }

begin

   if (curbut = bdown) and
      (puck.b[1].a or puck.b[2].a or puck.b[3].a) then begin

      { set enter cell mode }
      stopact; { stop all modes }
      butact(bdown); { set delete net mode active }
      drmbut := bdown;
      modbut := bdown;
      dsmbut := bdown

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { find screen pixels in real terms }
      mx := realdist(selrng, curwin^.cs^.vp.s.x);
      { find nearest cell }
      nearest(rcur.x, rcur.y, p, d, false, true);
      if (p <> nil) and (d <= mx) then begin

         { a cell was found, and is close enough }
         { save current cell on cell stack }
         new(cs); { get new save entry }
         cs^.cp := curwin^.cc; { place save }
         cs^.next := celstk; { push onto stack }
         celstk := cs;
         cp := cellst; { index top cell }
         while cp <> nil do begin { search cells }

            if (cp^.schema = p^.cr.cp) or (cp^.symbol = p^.cr.cp) then
               curwin^.cc := cp; { found, place cell as current }
            cp := cp^.next { next cell }

         end;
         button[bcname].s := curwin^.cc^.name; { place cell name }
         rescur; { lift cursor }
         updbut(bcname); { update }
         setcur; { drop cursor }
         dispcell; { display current cell }

      end

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

CLEAR COLOR

Clears a given color from the draw database.
Works on the figure layer only.

**************************************************************}

procedure clrclr(c: color);

var p: drwptr; { figure pointer }

begin

   p := curwin^.cs^.dl[ltfig]; { index top of draw list }
   while p <> nil do begin { traverse }

      if p^.cl = c then begin { found a color }

         drwfig(p, black, false, ltfig, curwin^.cs^.vp.v); { restore figure }
         p^.cl := black

      end;
      p := p^.next { next figure }

   end

end;
{}
{**************************************************************

COLOR NODE

Colors all figures in a given node.

**************************************************************}

procedure clrnode(n: nodptr; c: color);

var p: drwptr; { figure pointer }

begin

   p := n^.nl; { index 1st figure }
   while p <> nil do begin { traverse }

      drwfig(p, c, true, ltfig, curwin^.cs^.vp.v); { color figure }
      p^.cl := c;
      p := p^.nl { next }

   end

end;
{}
{**************************************************************

COLOR BUS

Colors all figures in a given bus.

**************************************************************}

procedure clrbus(b: busptr; c: color);

var p: drwptr; { figure pointer }
    n: nodptr; { node pointer }

begin

   p := b^.bl; { index 1st figure }
   while p <> nil do begin { traverse }

      drwfig(p, c, true, ltfig, curwin^.cs^.vp.v); { color figure }
      p^.cl := c;
      p := p^.bs.bl { next }

   end;
   n := b^.nl; { index 1st node }
   while n <> nil do begin { color all subnodes }

      clrnode(n, c); { color node }
      n := n^.bl { next node in bus }

   end

end;
{}
{**************************************************************

INCREMENT TRACE COLOR

Finds the next valid trace color.

**************************************************************}

procedure nxtclr;

{ increment trace color }

procedure inctrc;

begin

   if trcclr <> white then trcclr := succ(trcclr) { next }
   else trcclr := black { reset to start }

end;

begin

   inctrc; { next trace color }
   { ensure on valid color }
   while not (trcclr in trcclrs) do inctrc

end;
{}
{**************************************************************

ACTIVATE NODE TRACE

Activates tracing on the given node. Also places the node name
in the name button.

**************************************************************}

procedure trcnod(n: nodptr; first: boolean);

var ci: color;   { index for colors }
    f:  boolean; { search flag }
    i:  btsinx;

begin

   if n^.nl^.cl = black then begin { not already being traced }

      rescur; { remove cursor }
      if trctrk[trcclr] and first then { clear old color }
         clrclr(trcclr); { back in black }
      trctrk[trcclr] := true; { set this color in use }
      { color bus }
      if n^.bh <> nil then clrbus(n^.bh, trcclr)
      else clrnode(n, trcclr); { color node }
      { place traced name in display }
      button[bnamev].s := n^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      intstr(n^.nord, button[bnord].s); { place ordinal }
      trmzer(button[bnord].s); { trim zeros }
      { move back }
      for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
      updbut(bnord); { update }
      setcur { set cursor }

   end

end;
{}
{**************************************************************

ACTIVATE BUS TRACE

Activates tracing on the given bus. Also places the bus name
in the name button.

**************************************************************}

procedure trcbus(b: busptr; first: boolean);

var ci: color;   { index for colors }
    f:  boolean; { search flag }
    i:  btsinx;

begin

   if b^.bl^.cl = black then begin { not already being traced }

      rescur; { remove cursor }
      if trctrk[trcclr] and first then { clear old color }
         clrclr(trcclr); { back in black }
      trctrk[trcclr] := true; { set this color in use }
      clrbus(b, trcclr); { color bus }
      { place traced name in display }
      button[bnamev].s := b^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      button[bnord].s := '        '; { clear }
      updbut(bnord); { update }
      setcur { set cursor }

   end

end;
{}
{**************************************************************

TRACE NETWORK

Selects the closest wire figure to the cursor, and lights that
up in a color that changes for each traced net.

**************************************************************}

procedure tracenet;

var p, p1: drwptr;  { figure pointer }
    mx:    integer; { maximum distance to accept }
    d:     integer; { distance to figure }
    np:    nodptr;
    bp:    busptr;
    f:     boolean;

begin

   if (curbut = btrace) and puck.b[1].a then begin

      { set trace mode }
      stopact; { stop current activities }
      butact(btrace); { trace node }
      modbut := btrace; { set trace mode }
      drmbut := btrace;
      dsmbut := btrace

   end else if (curbut = btrace) and puck.b[2].a then begin

      { trace node by name }
      f := false; { set no nodes found }
      { search busses }
      bp := curwin^.cs^.bl; { index top of bus list }
      while bp <> nil do begin { traverse }

         if bp^.name = button[bnamev].s then begin { found }

            trcbus(bp, not f); { trace that bus }
            f := true { set node found }

         end;
         bp := bp^.next { next node }

      end;
      if not f then begin { not found }

         { search nodes }
         np := curwin^.cs^.nl; { index top of node list }
         while np <> nil do begin { traverse }

            if np^.name = button[bnamev].s then begin { found }

               trcnod(np, not f); { trace that node }
               f := true { set node found }

            end;
            np := np^.next { next node }

         end

      end;
      if f then nxtclr { increment trace color }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { find 5 screen pixels in real terms }
      mx := realdist(selrng, curwin^.cs^.vp.s.x);
      nearest(rcur.x, rcur.y, p, d, true, false); { find nearest wire }
      if (p <> nil) and (d <= mx) then begin { within limit }

         if p^.typ = tbus then trcbus(p^.bs.bh, true) { trace bus }
         else trcnod(p^.nh, true); { trace node }
         nxtclr { next trace color }

      end

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

SHOW NODE NAME

Finds the nearest wire figure to the cursor, and retrives the
attached node name to the name button.

**************************************************************}

procedure shownode;

var p:  drwptr;  { figure pointer }
    mx: integer; { maximum distance to accept }
    d:  integer; { distance to figure }
    i: btsinx;

begin

   { find 5 screen pixels in real terms }
   mx := realdist(selrng, curwin^.cs^.vp.s.x);
   nearest(rcur.x, rcur.y, p, d, true, false); { find nearest wire }
   if (p <> nil) and (d <= mx) then begin

      rescur; { lift cursor }
      if p^.typ = tbus then { bus }
         button[bnamev].s := p^.bs.bh^.name { place bus name }
      else { wire, junction or connector }
         button[bnamev].s := p^.nh^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      if p^.typ = tbus then { bus }
         button[bnord].s := '        ' { set no ordinal }
      else begin { wire, junction or connector }

         intstr(p^.nh^.nord, button[bnord].s); { place ordinal }
         trmzer(button[bnord].s); { trim zeros }
         { move back }
         for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4]

      end;
      updbut(bnord); { update }
      setcur { drop cursor }


   end

end;
{}
{**************************************************************

SET NODE NAME

Finds the nearest wire figure to the cursor, and sets the node
name to the name button.

**************************************************************}

procedure setnode;

var p:  drwptr;  { figure pointer }
    mx: integer; { maximum distance to accept }
    d:  integer; { distance to figure }
    n:  integer;
    e:  boolean; { error flag }

{ rename bus }

procedure renbus(b: busptr);

var np: nodptr;  { pointer for node list }

begin

   b^.name := button[bnamev].s; { place node name }
   b^.tmp := false; { set name is not a temp }
   np := b^.nl; { index top of node list }
   while np <> nil do begin { traverse node list }

      np^.name := button[bnamev].s; { place node name }
      np^.tmp := false; { set name is not a temp }
      np := np^.bl { link next }

   end

end;

begin

   if button[bnamev].s <> '        ' then begin

      { name has been set }
      { find 5 screen pixels in real terms }
      mx := realdist(selrng, curwin^.cs^.vp.s.x);
      nearest(rcur.x, rcur.y, p, d, true, false); { find nearest wire }
      if (p <> nil) and (d <= mx) then begin

         if p^.typ = tbus then renbus(p^.bs.bh) { rename bus }
         else begin { wire, junction or connector }

            { if part of bus, rename all other members
              NOTE: may want to issue a warning here }
            if p^.nh^.bh <> nil then renbus(p^.nh^.bh);
            p^.nh^.name := button[bnamev].s; { place node name }
            { note: there should be no reason for an error in
              getint to not already be found. Parsing it
              again isn't the smartest way to go. }
            getint(button[bnord], n, e); { get ordinal }
            p^.nh^.nord := n; { place }
            p^.nh^.tmp := false { set name is not a temp }

         end

      end

   end

end;
{}
{**************************************************************

DO NODE

Either sets or shows the node name and ordinal.

**************************************************************}

procedure doname;

begin

   if (curbut = bname) and (puck.b[1].a or puck.b[2].a) then begin

      { set name mode }
      stopact; { stop current activities }
      butact(bname); { trace node }
      modbut := bname; { set name mode }
      drmbut := bname;
      dsmbut := bname

   end else if inactive(cur) and puck.b[1].a then shownode { show node name }
   else if inactive(cur) and puck.b[2].a then setnode; { set node name }
   resptr { reset pointer device }

end;
{}
{**************************************************************

PERFORM CUT CLIPPING

Accepts a line specification. This line is clipped to the save
region. The pieces that result outside of the region are reentered
to the draw base.
The clipped "interior" portion of the line is inserted onto the
save list.
If any part of the line is placed in the save list, the original
figure given is deleted and the pointer returned nil to
indicate that this has been done.
Note that this clip procedure uses "big" arithmetic because it
operates on real lines.

**************************************************************}

procedure clplin(x1, y1, x2, y2: integer;  { line to clip }
                 tf:             figtyp;   { type of line }
                 var p:          drwptr;   { figure to delete }
                 var df:         boolean;  { delete flag }
                 var s:          drwptr);  { save list }

var inside, outside:    boolean;
    ocu1, ocu2:         byte;
    t:                  integer;
    tb:                 byte;
    l:                  drwptr;
    x1s, y1s, x2s, y2s: integer; { coordinate saves }
    np:                 namptr;
    t1, t2:             real; { large arithmetic buffers }

procedure setoutcodes(var u: byte; x, y: integer);

begin

   u := 0;
   if x < savb.s.x then u := u + 1;
   if y < savb.s.y then u := u + 2;
   if x > savb.e.x then u := u + 4;
   if y > savb.e.y then u := u + 8

end;

begin

   x1s := x1; { save original coordinates }
   y1s := y1;
   x2s := x2;
   y2s := y2;
   setoutcodes(ocu1, x1, y1); { initial 4-bit codes }
   setoutcodes(ocu2, x2, y2);
   inside := (ocu1 or ocu2) = 0;
   outside := (ocu1 and ocu2) <> 0;
   while not outside and not inside do begin

      if ocu1 = 0 then begin

         { swap endpoints if nessary so
           that (x1, y1) needs to be clipped }
         t := x1; x1 := x2; x2 := t;
         t := y1; y1 := y2; y2 := t;
         tb := ocu1; ocu1 := ocu2; ocu2 := tb;

      end;
      if (ocu1 and 1) <> 0 then begin { clip left }

         t := y2-y1;
         y1 := y1 + round(t*(savb.s.x-x1) / (x2-x1));
         x1 := savb.s.x

      end else if (ocu1 and 2) <> 0 then begin { clip above }

         t := x2-x1;
         x1 := x1 + round(t*(savb.s.y-y1) / (y2-y1));
         y1 := savb.s.y

      end else if (ocu1 and 4) <> 0 then begin { clip right }

         t := y2-y1;
         y1 := y1 + round(t*(savb.e.x-x1) / (x2-x1));
         x1 := savb.e.x

      end else if (ocu1 and 8) <> 0 then begin { clip below }

         t := x2-x1;
         x1 := x1 + round(t*(savb.e.y-y1) / (y2-y1));
         y1 := savb.e.y

      end;
      setoutcodes(ocu1, x1, y1); { update for (x1, y1) }
      inside := (ocu1 or ocu2) = 0; { update }
      outside := (ocu1 and ocu2) <> 0 { 4-bit codes }

   end;
   if inside then begin { ok, enter that line }

      if p <> nil then begin

         if p^.typ = twire then begin { enter wire name }

            new(np); { get a new naming entry }
            np^.next := namlst; { insert to list }
            namlst := np;
            np^.name := p^.nh^.name; { save name }
            np^.nord := p^.nh^.nord; { save ordinal }
            np^.tmp := p^.nh^.tmp { save temp flag }

         end else if p^.typ = tbus then begin { enter bus name }

            new(np); { get a new naming entry }
            np^.next := namlst; { insert to list }
            namlst := np;
            np^.name := p^.bs.bh^.name; { save name }
            np^.tmp := p^.bs.bh^.tmp { save temp flag }

         end

      end;
      { rationalize the lines }
      ratlin(x1s, y1s, x2s, y2s);
      ratlin(x1, y1, x2, y2);
      if button[bcutb].act and (p <> nil) then begin

         { delete original figure }
         if p^.typ = twire then begin

            { figure is node component, add node to smash list }
            if p^.nh^.sl = nil then begin { not already on list }

               p^.nh^.sl := smslst; { link into our list }
               smslst := p^.nh

            end

         end else if p^.typ = tbus then begin

            { figure is bus component, add bus to smash list }
            if p^.bs.bh^.sl = nil then begin { not already on list }

               p^.bs.bh^.sl := bsmlst; { link into our list }
               bsmlst := p^.bs.bh

            end

         end;
         deletef(p); { delete }
         { process line remainders }
         if (x1 <> x1s) or (y1 <> y1s) then begin

            { enter left hand remainder }
            new(l); { get new draw entry }
            l^.typ := tf; { set type }
            if l^.typ = twire then with l^.w do begin

               s.x  := x1; { place coordinates }
               s.y  := y1;
               e.x  := x1s;
               e.y  := y1s

            end else if l^.typ = tbus then with l^.bs.l do begin

               s.x  := x1; { place coordinates }
               s.y  := y1;
               e.x  := x1s;
               e.y  := y1s

            end else with l^.l do begin

               s.x  := x1; { place coordinates }
               s.y  := y1;
               e.x  := x1s;
               e.y  := y1s

            end;
            l^.cl  := black; { set color }
            { link wire into node }
            if l^.typ = twire then lnkwire(l)
            else if l^.typ = tbus then lnkbus(l);
            l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
            curwin^.cs^.dl[ltfig] := l

         end;
         if (x2 <> x2s) or (y2 <> y2s) then begin

            { enter right hand remainder }
            new(l); { get new draw entry }
            l^.typ := tf; { set type }
            if l^.typ = twire then with l^.w do begin

               s.x  := x2s; { place coordinates }
               s.y  := y2s;
               e.x  := x2;
               e.y  := y2;

            end else if l^.typ = tbus then with l^.bs.l do begin

               s.x  := x2s; { place coordinates }
               s.y  := y2s;
               e.x  := x2;
               e.y  := y2;

            end else with l^.l do begin

               s.x  := x2s; { place coordinates }
               s.y  := y2s;
               e.x  := x2;
               e.y  := y2;

            end;
            l^.cl  := black; { set color }
            { link wire into node }
            if l^.typ = twire then lnkwire(l)
            else if l^.typ = tbus then lnkbus(l);
            l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
            curwin^.cs^.dl[ltfig] := l

         end;
         p := nil; { flag figure is no more }
         df := true

      end;
      new(l); { get new draw entry }
      l^.typ := tf; { set type }
      if l^.typ = twire then with l^.w do begin

         s.x := x1-savb.s.x; { place coordinates }
         s.y := y1-savb.s.y;
         e.x := x2-savb.s.x;
         e.y := y2-savb.s.y;

      end else if l^.typ = tbus then with l^.bs.l do begin

         s.x := x1-savb.s.x; { place coordinates }
         s.y := y1-savb.s.y;
         e.x := x2-savb.s.x;
         e.y := y2-savb.s.y;

      end else with l^.l do begin

         s.x := x1-savb.s.x; { place coordinates }
         s.y := y1-savb.s.y;
         e.x := x2-savb.s.x;
         e.y := y2-savb.s.y;

      end;
      l^.cl := black; { set color }
      l^.next := s; { enter to save list }
      s := l

   end

end;
{}
{**************************************************************

SAVE OR CUT BLOCK

Clips out or copies and saves a block.

**************************************************************}

procedure saveblk;

var p, p1, l:       drwptr;
    v:              boolean; { clipping flag }
    t:              integer;
    x1, y1, x2, y2: integer; { box coordinates }
    tf:             figtyp;  { type of figure }
    nl:             nodptr;  { node "smash" list }
    bl:             busptr;  { bus "smash" list }
    df:             boolean; { figures deleted flag }
    cp, cp1:        chrptr;  { character pointers }
    f:              integer; { fudge factor }
    np:             namptr;  { name pointer }
    li:             laytyp;  { layer index }

{ check point in region }

function included(px, py: integer): boolean;

begin

   included := (px >= savb.s.x) and (px <= savb.e.x) and
               (py >= savb.s.y) and (py <= savb.e.y)

end;

function inregion(p: drwptr): boolean;

var x1, y1, x2, y2: integer;

begin

   fndbound(p, x1, y1, x2, y2); { find object bounds }
   inregion := included(x1, y1) and included(x2, y2)

end;

{ find "puzzle" block breakage }

procedure puzzle(p: drwptr; var dl: drwptr);

var l:                  drwptr;
    rx1, ry1, rx2, ry2: integer; { result intersection }
    r:                  boolean; { intersection flag }

procedure enter;

begin

   new(l); { get new draw entry }
   l^.typ := p^.typ; { set type }
   l^.b.s.x := rx1; { place coordinates }
   l^.b.s.y := ry1;
   l^.b.e.x := rx2;
   l^.b.e.y := ry2;
   l^.cl := p^.cl; { set color }
   l^.next := dl; { enter to list }
   dl := l;
   if p^.typ in [tmet1, tmet2, tpoly, tndiff, tpdiff, tcont] then
      { in poly, metals, and diff layer }
      dointer(l) { enter to intersection list }

end;

begin

   { check top }
   intersect(p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y,
             rw.s.x, rw.s.y, rw.e.x, savb.s.y,
             rx1, ry1, rx2, ry2, r);
   if r then enter; { piece exists, enter }
   { check left }
   intersect(p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y,
             rw.s.x, savb.s.y, savb.s.x, savb.e.y,
             rx1, ry1, rx2, ry2, r);
   if r then enter; { piece exists, enter }
   { check right }
   intersect(p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y,
             savb.e.x, savb.s.y, rw.e.x, savb.e.y,
             rx1, ry1, rx2, ry2, r);
   if r then enter; { piece exists, enter }
   { check bottom }
   intersect(p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y,
             rw.s.x, savb.e.y, rw.e.x, rw.e.y,
             rx1, ry1, rx2, ry2, r);
   if r then enter { piece exists, enter }

end;

{ save from list }

procedure lstsav(var sp: drwptr;  { source list }
                 var s:  drwptr); { destination list }

var p1, p:              drwptr;
    rx1, ry1, rx2, ry2: integer; { result intersection }
    r:                  boolean; { intersection flag }

begin

   p := sp; { index top }
   while p <> nil do begin { add figures }

      p1 := p^.next; { save next in case of delete }
      case p^.typ of { figure }

         tline, tbline: { line }
            { enter as clipped }
            clplin(p^.l.s.x, p^.l.s.y, p^.l.e.x, p^.l.e.y, p^.typ,
                   p, df, s);

         twire: { wire }
            { enter as clipped }
            clplin(p^.w.s.x, p^.w.s.y, p^.w.e.x, p^.w.e.y,
                   p^.typ, p, df, s);

         tbus: { wire }
            { enter as clipped }
            clplin(p^.bs.l.s.x, p^.bs.l.s.y, p^.bs.l.e.x, p^.bs.l.e.y,
                   p^.typ, p, df, s);

         tbox, tbbox: begin { box }

            { check entire box is contained }
            if inregion(p) then begin

               { box is contained, may be passed whole }
               new(l); { get new draw entry }
               l^.typ := p^.typ; { set type }
               l^.b.s.x := p^.b.s.x-savb.s.x; { place coordinates }
               l^.b.s.y := p^.b.s.y-savb.s.y;
               l^.b.e.x := p^.b.e.x-savb.s.x;
               l^.b.e.y := p^.b.e.y-savb.s.y;
               l^.cl := black; { set color }
               l^.next := s; { enter to save list }
               s := l;
               { delete on cut }
               if button[bcutb].act then begin

                  deletef(p); { delete }
                  df := true { set object deleted }

               end

            end else begin { must break up into lines }

               x1 := p^.b.s.x; { save box corners }
               y1 := p^.b.s.y;
               x2 := p^.b.e.x;
               y2 := p^.b.e.y;
               { set type of line according to type of box }
               if p^.typ = tbox then
                  tf := tline else tf := tbline;
               { clip left }
               clplin(x1, y1, x1, y2, tf, p, df, s);
               { clip right }
               clplin(x2, y1, x2, y2, tf, p, df, s);
               { clip top }
               clplin(x1, y1, x2, y1, tf, p, df, s);
               { clip bottom }
               clplin(x1, y2, x2, y2, tf, p, df, s)

            end

         end;

         { arc or circle }

         tarc: if inregion(p) then begin { included }

            new(l); { get new draw entry }
            l^.typ := tarc; { set type }
            l^.a.c.x := p^.a.c.x-savb.s.x; { place parameters }
            l^.a.c.y := p^.a.c.y-savb.s.y;
            l^.a.s.x := p^.a.s.x-savb.s.x;
            l^.a.s.y := p^.a.s.y-savb.s.y;
            l^.a.e.x := p^.a.e.x-savb.s.x;
            l^.a.e.y := p^.a.e.y-savb.s.y;
            l^.a.r := p^.a.r;
            l^.cl := black; { set color }
            l^.next := s; { enter to list }
            s := l;
            { delete on cut }
            if button[bcutb].act then begin

               deletef(p); { delete }
               df := true { set object deleted }

            end

         end;

         { vector character }

         tchar: if inregion(p) then begin { included }

            new(l); { get new draw entry }
            l^.typ := tchar; { set type }
            l^.c.r.s.x  := p^.c.r.s.x-savb.s.x; { place coordinates }
            l^.c.r.s.y  := p^.c.r.s.y-savb.s.y;
            l^.c.r.e.x  := p^.c.r.e.x-savb.s.x;
            l^.c.r.e.y  := p^.c.r.s.y-savb.s.y;
            l^.c.l  := nil; { set no characters }
            l^.c.s  := p^.c.s; { place scale }
            l^.cl  := black; { set color }
            l^.rm  := p^.rm; { set rotate mode }
            l^.next := s; { enter to draw list }
            s := l;
            cp := p^.c.l; { index 1st character }
            while cp <> nil do begin { copy characters }

               if l^.c.l = nil then begin { insert 1st character }

                  new(l^.c.l); { get an entry }
                  cp1 := l^.c.l { index }

               end else begin { insert next character }

                  new(cp1^.next); { get an entry }
                  cp1 := cp1^.next { index }

               end;
               cp1^.next := nil; { terminate }
               cp1^.c := cp^.c; { copy character }
               cp := cp^.next { next character }

            end;
            { delete on cut }
            if button[bcutb].act then begin

               deletef(p); { delete }
               df := true { set object deleted }

            end

         end;

         { wire junction }

         tjunction: if inregion(p) then begin { included }

            new(l); { get new draw entry }
            l^.typ := tjunction; { set type }
            l^.j.x := p^.j.x-savb.s.x; { place coordinates }
            l^.j.y := p^.j.y-savb.s.y;
            l^.cl := black; { set color }
            l^.next := s; { enter to draw list }
            s := l;
            new(np); { get a new naming entry }
            np^.next := namlst; { insert to list }
            namlst := np;
            np^.name := p^.nh^.name; { save name }
            np^.nord := p^.nh^.nord; { save ordinal }
            np^.tmp := p^.nh^.tmp; { save temp flag }
            { delete on cut }
            if button[bcutb].act then begin

               deletef(p); { delete }
               df := true { set object deleted }

            end

         end;

         { connector }

         tconnect: if inregion(p) then begin { included }

            new(l); { get new draw entry }
            l^.typ := tconnect; { set type }
            l^.j.x := p^.j.x-savb.s.x; { place coordinates }
            l^.j.y := p^.j.y-savb.s.y;
            l^.cl := black; { set color }
            l^.next := s; { enter to draw list }
            s := l;
            new(np); { get a new naming entry }
            np^.next := namlst; { insert to list }
            namlst := np;
            np^.name := p^.nh^.name; { save name }
            np^.nord := p^.nh^.nord; { save ordinal }
            np^.tmp := p^.nh^.tmp; { save temp flag }
            { delete on cut }
            if button[bcutb].act then begin

               deletef(p); { delete }
               df := true { set object deleted }

            end

         end;

         { cell }

         tcell: if inregion(p) then begin { included }

            new(l); { get new draw entry }
            l^.typ := tcell; { set type }
            l^.cr.o.x  := p^.cr.o.x-savb.s.x; { place coordinates }
            l^.cr.o.y  := p^.cr.o.y-savb.s.y;
            l^.cr.cp  := p^.cr.cp; { place cell pointer }
            l^.cr.ct  := p^.cr.ct; { place cell type }
            l^.rm  := p^.rm; { place rotate mode }
            l^.cl  := black; { set color }
            l^.next := s; { enter to draw list }
            s := l;
            { delete on cut }
            if button[bcutb].act then begin

               deletef(p); { delete }
               df := true { set object deleted }

            end

         end;

         { predefined cells }

         tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss:
            if inregion(p) then begin { included }

            new(l); { get new draw entry }
            l^.typ := p^.typ; { set type }
            l^.o.x  := p^.o.x-savb.s.x; { place coordinates }
            l^.o.y  := p^.o.y-savb.s.y;
            l^.rm  := p^.rm; { place rotate mode }
            l^.cl  := black; { set color }
            l^.next := s; { enter to draw list }
            s := l;
            { delete on cut }
            if button[bcutb].act then begin

               deletef(p); { delete }
               df := true { set object deleted }

            end

         end;

         tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
         tnwell, tpwell, tccut, tcont: begin { solid layer }

            { find intersection }
            intersect(p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y,
                      savb.s.x, savb.s.y, savb.e.x, savb.e.y,
                      rx1, ry1, rx2, ry2, r);
            if r then begin { there is an intersection }

               new(l); { get new draw entry }
               l^.typ := p^.typ; { set type }
               l^.b.s.x := rx1-savb.s.x; { place coordinates }
               l^.b.s.y := ry1-savb.s.y;
               l^.b.e.x := rx2-savb.s.x;
               l^.b.e.y := ry2-savb.s.y;
               l^.cl := p^.cl; { set color }
               l^.next := s; { enter to save list }
               s := l;
               { delete on cut }
               if button[bcutb].act then begin

                  deletef(p); { delete }
                  df := true; { set object deleted }
                  puzzle(p, sp) { find "puzzle" pieces }

               end

            end

         end

         else { port: partial case; unmatched types ignored }

      end;
      p := p1 { link next figure }

   end

end;

begin

   if (curbut in [bsaveb, bcutb]) and
      (puck.b[1].a or puck.b[2].a or puck.b[3].a) then begin

      { set save mode }
      stopact; { stop all modes }
      butact(curbut); { set save mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut = bsaveb) and inactive(cur) and
                (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
                 (puck.b[2].d and puck.b[2].dg)) then begin

      { enter saved region }
      rescur; { remove cursor }
      endp := cur; { make sure end is established }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y);
      resbox; { remove box }
      cruler; { clear ruler }
      { clear save lists }
      for li := ltcell to ltwell do savlst[li] := nil;
      savb.s := str; { set save bounds }
      savb.e := endp;
      { rationalize region }
      ratbox(savb.s.x, savb.s.y, savb.e.x, savb.e.y);
      smslst := nil; { clear smash list }
      bsmlst := nil; { clear bus smash list }
      df := false; { clear delete flag }
      { save layers }
      lstsav(curwin^.cs^.dl[ltcell],  savlst[ltcell]);
      lstsav(curwin^.cs^.dl[ltfig],   savlst[ltfig]);
      lstsav(curwin^.cs^.dl[ltovg],   savlst[ltovg]);
      lstsav(curwin^.cs^.dl[ltvia],   savlst[ltvia]);
      lstsav(curwin^.cs^.dl[ltmet2],  savlst[ltmet2]);
      lstsav(curwin^.cs^.dl[ltcont],  savlst[ltcont]);
      lstsav(curwin^.cs^.dl[ltpmd],   savlst[ltpmd]);
      lstsav(curwin^.cs^.dl[ltwell],  savlst[ltwell]);
      if button[bcutb].act and df then begin

         { operation is cut, and there was a deletion }
         { smash all busses affected }
         while bsmlst <> nil do begin

            bl := bsmlst; { remove from smash list }
            bsmlst := bsmlst^.sl;
            bl^.sl := nil; { clear from list }
            smashb(bl) { smash it }

         end;
         { smash all nodes affected }
         { note that this could be redundant with the bus
           smash }
         while smslst <> nil do begin

            nl := smslst; { remove from smash list }
            smslst := smslst^.sl;
            nl^.sl := nil; { clear from list }
            smash(nl) { smash it }

         end;
         f := realdist(3, curwin^.cs^.vp.s.x); { find the fudge factor }
         { clear region }
         blockr(savb.s.x-f, savb.s.y-f, savb.e.x+f, savb.e.y+f, white, curwin^.cs^.vp.v);
         { redraw region }
         rregion(savb.s.x-f, savb.s.y-f, savb.e.x+f, savb.e.y+f);
         rebound { recalculate bounds }

      end;
      drmbut := bnull; { remove save mode }
      dsmbut := bnull;
      setcur  { replace cursor }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin { in active area }

      { start save mode }
      rescur; { remove cursor }
      if drmbut = bsaveb then resbox; { erase existing zoom box }
      str := cur; { set start of box }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      tstr := str; { save as true start }
      tstr := str;
      snapto(str.x, str.y); { snap that }
      endp := str; { set end of box }
      setbox; { set line to screen }
      setcur; { replace cursor }
      zruler; { update ruler }
      drmbut := bsaveb; { set save mode }
      dsmbut := bsaveb

   end;
   resptr { reset pointer device }

end;
{}
{**************************************************************

PASTE BLOCK

Pastes the contents of the block save list into the present
cursor location.

**************************************************************}

procedure pasteblk;

var rp:      point;
    cp, cp1: chrptr;  { character pointers }
    np:      namptr;
    n:       nodptr;
    li:      laytyp;  { layer index }
    e:       boolean; { save empty flag }

{ add figure to bounds }

procedure addbound(p: drwptr);

var x1, y1, x2, y2: integer;

begin

   fndbound(p, x1, y1, x2, y2); { find bounds of figure }
   setbound(x1, y1); { modify bounding box }
   setbound(x2, y2);
   if p^.typ <> tconnect then begin { modify symbol bounding box }

      setsbound(x1, y1);
      setsbound(x2, y2)

   end

end;

{ paste from list }

procedure lstpst(    p:  drwptr;  { source list }
                 var dl: drwptr); { destination list }

var l: drwptr; { list entry holder }

begin

   np := namlst; { index name save list }
   while p <> nil do begin { add figures }

      case p^.typ of { figure }

         tline, tbline, twire, tbus: begin { line }

            new(l); { get new draw entry }
            l^.typ := p^.typ; { set type }
            if l^.typ = twire then with l^.w do begin

               s.x := p^.w.s.x+rp.x; { place coordinates }
               s.y := p^.w.s.y+rp.y;
               e.x := p^.w.e.x+rp.x;
               e.y := p^.w.e.y+rp.y

            end else if l^.typ = tbus then with l^.bs.l do begin

               s.x := p^.bs.l.s.x+rp.x; { place coordinates }
               s.y := p^.bs.l.s.y+rp.y;
               e.x := p^.bs.l.e.x+rp.x;
               e.y := p^.bs.l.e.y+rp.y

            end else with l^.l do begin

               s.x := p^.l.s.x+rp.x; { place coordinates }
               s.y := p^.l.s.y+rp.y;
               e.x := p^.l.e.x+rp.x;
               e.y := p^.l.e.y+rp.y

            end;
            l^.cl := black; { set color }
            addbound(l); { modify bounding box }
            { link wire into node }
            if p^.typ = twire then lnkwire(l)
            else if p^.typ = tbus then lnkbus(l);
            l^.next := dl; { enter to draw list }
            dl := l;
            if l^.typ = twire then begin { name wire }

               if l^.nh^.tmp and not np^.tmp then begin

                  { is a temp name }
                  l^.nh^.name := np^.name; { place name }
                  l^.nh^.nord := np^.nord; { place ordinal }
                  l^.nh^.tmp := np^.tmp { place temp flag }

               end;
               np := np^.next { next name entry }

            end else if l^.typ = tbus then begin { name bus }

               if l^.bs.bh^.tmp and not np^.tmp then begin

                  { is a temp name }
                  l^.bs.bh^.name := np^.name; { place name }
                  l^.bs.bh^.tmp := np^.tmp; { place temp flag }
                  n := l^.bs.bh^.nl; { index 1st node }
                  while n <> nil do begin { rename nodes }

                     n^.name := np^.name; { place name }
                     n^.tmp := np^.tmp; { place temp flag }
                     n := n^.bl { next node }

                  end

               end;
               np := np^.next { next name entry }

            end

         end;

         tbox, tbbox: begin { box }

            new(l); { get new draw entry }
            l^.typ := p^.typ; { set type }
            l^.b.s.x := p^.b.s.x+rp.x; { place coordinates }
            l^.b.s.y := p^.b.s.y+rp.y;
            l^.b.e.x := p^.b.e.x+rp.x;
            l^.b.e.y := p^.b.e.y+rp.y;
            l^.cl := p^.cl; { set color }
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to list }
            dl := l

         end;

         tarc: begin { arc or circle }

            new(l); { get new draw entry }
            l^.typ := tarc; { set type }
            l^.a.c.x := p^.a.c.x+rp.x; { place parameters }
            l^.a.c.y := p^.a.c.y+rp.y;
            l^.a.s.x := p^.a.s.x+rp.x;
            l^.a.s.y := p^.a.s.y+rp.y;
            l^.a.e.x := p^.a.e.x+rp.x;
            l^.a.e.y := p^.a.e.y+rp.y;
            l^.a.r := p^.a.r;
            l^.cl := black; { set color }
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to draw list }
            dl := l

         end;

         tchar: begin { vector character }

            new(l); { get new draw entry }
            l^.typ := tchar; { set type }
            l^.c.r.s.x  := p^.c.r.s.x+rp.x; { place coordinates }
            l^.c.r.s.y  := p^.c.r.s.y+rp.y;
            l^.c.r.e.x  := p^.c.r.e.x+rp.x;
            l^.c.r.e.y  := p^.c.r.e.y+rp.y;
            l^.c.l  := nil; { set no characters }
            l^.c.s  := p^.c.s; { place scale }
            l^.cl  := black; { set color }
            l^.rm  := p^.rm; { set rotate mode }
            cp := p^.c.l; { index 1st character }
            while cp <> nil do begin { copy characters }

               if l^.c.l = nil then begin { insert 1st character }

                  new(l^.c.l); { get an entry }
                  cp1 := l^.c.l { index }

               end else begin { insert next character }

                  new(cp1^.next); { get an entry }
                  cp1 := cp1^.next { index }

               end;
               cp1^.next := nil; { terminate }
               cp1^.c := cp^.c; { copy character }
               cp := cp^.next { next character }

            end;
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to draw list }
            dl := l

         end;

         tjunction: begin { wire junction }

            plcjun(p^.j.x+rp.x, p^.j.y+rp.y, l); { place new junction }
            lnkjun(l); { place junction at location }
            if l^.nh^.tmp and not np^.tmp then begin

               { is a temp name }
               l^.nh^.name := np^.name; { place name }
               l^.nh^.nord := np^.nord; { place ordinal }
               l^.nh^.tmp := np^.tmp { place temp flag }

            end;
            np := np^.next { next name entry }

         end;

         tconnect: begin { connector }

            new(l); { get new draw entry }
            l^.typ := tconnect; { set type }
            l^.j.x  := p^.j.x+rp.x; { place coordinates }
            l^.j.y  := p^.j.y+rp.y;
            l^.cl  := black; { set color }
            lnkjun(l); { place junction at location }
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to draw list }
            dl := l;
            if l^.nh^.tmp and not np^.tmp then begin

               { is a temp name }
               l^.nh^.name := np^.name; { place name }
               l^.nh^.nord := np^.nord; { place ordinal }
               l^.nh^.tmp := np^.tmp { place temp flag }

            end;
            np := np^.next { next name entry }

         end;

         tcell: begin { cell }

            new(l); { get new draw entry }
            l^.typ := tcell; { set type }
            l^.cr.o.x  := p^.cr.o.x+rp.x; { place coordinates }
            l^.cr.o.y  := p^.cr.o.y+rp.y;
            l^.cr.cp  := p^.cr.cp; { place cell pointer }
            l^.cr.ct  := p^.cr.ct; { place cell type }
            l^.rm  := p^.rm; { place rotate mode }
            l^.cl  := black; { set color }
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to draw list }
            dl := l

         end;

         { predefined cell }

         tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss: begin

            new(l); { get new draw entry }
            l^.typ := p^.typ; { set type }
            l^.o.x  := p^.o.x+rp.x; { place coordinates }
            l^.o.y  := p^.o.y+rp.y;
            l^.rm  := p^.rm; { place rotate mode }
            l^.cl  := black; { set color }
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to draw list }
            dl := l

         end;

         tmet1, tmet2, tpoly, tvia, tndiff,
         tpdiff, tnwell, tpwell, tccut, tcont: begin { layer }

            new(l); { get new draw entry }
            l^.typ := p^.typ; { set type }
            l^.b.s.x := p^.b.s.x+rp.x; { place coordinates }
            l^.b.s.y := p^.b.s.y+rp.y;
            l^.b.e.x := p^.b.e.x+rp.x;
            l^.b.e.y := p^.b.e.y+rp.y;
            l^.cl := p^.cl; { set color }
            addbound(l); { modify bounding box }
            l^.next := dl; { enter to list }
            dl := l;
            if p^.typ in [tmet1, tmet2, tpoly, tndiff,
                          tpdiff, tcont] then
               { in poly, metals, and diff layer }
               dointer(l) { enter to intersection list }

         end

         else { port: partial case; unmatched types ignored }

      end;
      p := p^.next { link next figure }

   end;

end;

begin

   e := true; { set save empty }
   { check layers empty }
   for li := ltcell to ltwell do if savlst[li] <> nil then
      e := false;
   if (curbut = bpasteb) and
      (puck.b[1].a or puck.b[2].a or puck.b[3].a) and
      not e then begin

      { select paste mode }
      { if there is something to paste, start now }
      stopact; { stop all modes }
      butact(bpasteb); { set paste mode active }
      str := rcur; { set start of box }
      snapto(str.x, str.y); { snap }
      endp.x := str.x + abs(savb.e.x - savb.s.x); { set end of box }
      endp.y := str.y + abs(savb.e.y - savb.s.y);
      modbut := bpasteb; { set paste mode active }
      drmbut := bpasteb;
      dsmbut := bpasteb

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { paste block }
      rescur; { remove cursor }
      resbox; { remove paste box }
      rp := cur; { find our location }
      realc(rp, curwin^.cs^.vp); { convert coordinates }
      snapto(rp.x, rp.y);
      { paste layers }
      lstpst(savlst[ltcell],  curwin^.cs^.dl[ltcell]);
      lstpst(savlst[ltfig],   curwin^.cs^.dl[ltfig]);
      lstpst(savlst[ltovg],   curwin^.cs^.dl[ltovg]);
      lstpst(savlst[ltvia],   curwin^.cs^.dl[ltvia]);
      lstpst(savlst[ltmet2],  curwin^.cs^.dl[ltmet2]);
      lstpst(savlst[ltcont],  curwin^.cs^.dl[ltcont]);
      lstpst(savlst[ltpmd],   curwin^.cs^.dl[ltpmd]);
      lstpst(savlst[ltwell],  curwin^.cs^.dl[ltwell]);
      frregion(str.x, str.y, endp.x, endp.y); { redraw region }
      setbox; { reset paste box }
      chktar; { check target change }
      setcur  { replace cursor }

   end;
   resptr { reset pointer device }

end;
{}
{ UNRESOLVED: names used here that are defined outside this fragment
  or in later phases:

  frag_n (icda db core):  delwire, lnkwire, lnkbus, lnkjun, plcjun -
                          this fragment must be concatenated AFTER
                          frag_n.
  icdg (rules, later):    dointer - create intersections; called by
                          saveblk/pasteblk. (intersect, also from
                          icdg.pas, IS ported here since icdd only
                          declared it external.)
  icdh (simulate, later): dtrace, atrace - trace drawing; called by
                          drwfig (ttrc/tatrc figure types).
  boxr and conr had no surviving definitions anywhere in the sources;
  they are RECONSTRUCTED here from their printer analogues (pboxr/
  pconr in icde.pas) - see the "port:" notes on each.
  Integrator: replace the interim ratbox copy in icdui_base.pas with
     procedure ratbox(var x1, y1, x2, y2: integer); forward;
  (frag_b calls it first; the original is ported here and resolves
  the forward). Verified to build with this fragment concatenated
  between frag_n and frag_i, with temporary empty-body stubs for
  dointer/dtrace/atrace placed ahead of it. redraw and stopact in
  frag_d can now call drwfigs/drwfig in place of their "port: cell
  drawing deferred" stubs; frag_g's frag_f expectations (drwfig,
  drwfigs, ratlin, rregion, frregion, delete, deletenet, saveblk,
  pasteblk, doname, upcell, downcell, tracenet) are all provided. }

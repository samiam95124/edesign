{ port: fragment b - viewport graphics layer, ported from icdb.pas (with
  the low level line/block/setpix/setchr routines reconstructed from
  video/drawa.pas). Save-under rubber banding is replaced by xor mode
  drawing throughout. }
{}
{**************************************************************

FIND VIEW COORDINATES X

Finds the equvalent screen region coordinates to the given real
coordinates.

**************************************************************}

procedure viewx(var vp: viewport; { viewport into realspace }
                var x:  integer); { point to be converted (real) }

var t: integer;

begin

   t := (x-vp.r.s.x)*vp.m.x;
   x := (t div vp.s.x)+vp.v.s.x; { find x }
   if (t mod vp.s.x) > vp.s.x div 2 then x := x + 1;

end;
{}
{**************************************************************

FIND VIEW COORDINATES Y

Finds the equvalent screen region coordinates to the given real
coordinate x.

**************************************************************}

procedure viewy(var vp: viewport; { viewport into realspace }
                var y:  integer); { point to be converted (real) }

var t: integer;

begin

   t := (y-vp.r.s.y)*vp.m.y;
   y := (t div vp.s.y)+vp.v.s.y; { find y }
   if (t mod vp.s.y) > vp.s.y div 2 then y := y + 1

end;
{}
{**************************************************************

FIND ANGLE TANGENT

Finds the tangent function (which is not in standard pascal).

**************************************************************}

function tan(r: real): real;

begin

   tan := sin(r)/cos(r)

end;
{}
{**************************************************************

FIND VIEW COORDINATES

Finds the equvalent screen region coordinates to the given real
coordinates. The coordinates are not clipped.

**************************************************************}

procedure viewc(var p:  point;     { point to be converted (real) }
                var vp: viewport); { viewport into realspace }

var t: integer;

begin

   t := (p.x-vp.r.s.x)*scalem;
   p.x := (t div vp.s.x)+vp.v.s.x; { find x }
   if (t mod vp.s.x) > vp.s.x div 2 then p.x := p.x + 1;
   t := (p.y-vp.r.s.y)*scalem;
   p.y := (t div vp.s.y)+vp.v.s.y; { find y }
   if (t mod vp.s.y) > vp.s.y div 2 then p.y := p.y + 1

end;
{}
{**************************************************************

FIND REAL COORDINATES

Finds the equvalent real coordinates to the given screen region
coordinates.

**************************************************************}

procedure realc(var p:  point;     { point to be converted (screen) }
                var vp: viewport); { viewport into realspace
                                    to contain point }

var t: integer;

begin

   t := (p.x-vp.v.s.x)*vp.s.x;
   p.x := (t div scalem)+vp.r.s.x; { find x }
   if (t mod scalem) > scalem div 2 then p.x := p.x + 1;
   t := (p.y-vp.v.s.y)*vp.s.y;
   p.y := (t div scalem)+vp.r.s.y;  { find y }
   if (t mod scalem) > scalem div 2 then p.y := p.y + 1

end;
{}
{**************************************************************

CALCULATE SCREEN DISTANCE

Given a real distance and scale, calculates the nearest screen
equivalent distance.

**************************************************************}

function scndist(d, s: integer): integer;

var t: integer;

begin

   t := d*scalem;
   d := t div s;
   if (t mod s) > s div 2 then d := d + 1;
   scndist := d { return result }

end;
{}
{**************************************************************

CACULATE REAL DISTANCE

Given a screen distance and scale, calculates the nearest real
equivalent distance.

**************************************************************}

function realdist(d, s: integer): integer;

var t: integer;

begin

   t := d*s;
   d := t div scalem;
   if (t mod scalem) > scalem div 2 then d := d + 1;
   realdist := d { return result }

end;
{}
{**************************************************************

CLIP LINE

Accepts a line specification, and converts said line to a line
clipped to the viewport. Returns indication if the entire line
is to be clipped.

**************************************************************}

procedure clip(var x1, y1, x2, y2: integer; { line coordinates }
               var inside: boolean;         { "clipout" flag }
               r: region);                  { window }

var outside:    boolean;
    ocu1, ocu2: byte;
    t:          integer;
    tb:         byte;

procedure setoutcodes(var u: byte; x, y: integer);

begin

   u := 0;
   if x < r.s.x then u := u + 1;
   if y < r.s.y then u := u + 2;
   if x > r.e.x then u := u + 4;
   if y > r.e.y then u := u + 8

end;

begin

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

         y1 := y1 + ((y2-y1)*(r.s.x-x1) div (x2-x1));
         x1 := r.s.x

      end else if (ocu1 and 2) <> 0 then begin { clip above }

         x1 := x1 + ((x2-x1)*(r.s.y-y1) div (y2-y1));
         y1 := r.s.y

      end else if (ocu1 and 4) <> 0 then begin { clip right }

         y1 := y1 + ((y2-y1)*(r.e.x-x1) div (x2-x1));
         x1 := r.e.x

      end else if (ocu1 and 8) <> 0 then begin { clip below }

         x1 := x1 + ((x2-x1)*(r.e.y-y1) div (y2-y1));
         y1 := r.e.y

      end;
      setoutcodes(ocu1, x1, y1); { update for (x1, y1) }
      inside := (ocu1 or ocu2) = 0; { update }
      outside := (ocu1 and ocu2) <> 0 { 4-bit codes }

   end

end;
{}
{**************************************************************

SET PIXEL

Sets a single pixel.
The point is clipped to the viewport clipping rectangle.

port: was cexternal; reimplemented over the base layer

***************************************************************}

procedure setpix(vp:   viewport; { viewport }
                 x, y: integer;  { point coordinates }
                 c:    color);   { color }

begin

   { clip }
   if (x >= vp.c.s.x) and (x <= vp.c.e.x) and
      (y >= vp.c.s.y) and (y <= vp.c.e.y) then
      scrsetpix(x, y, c) { set true pixel }

end;
{}
{**************************************************************

PLACE CHARACTER ONSCREEN

Places a character at the given position, in the given color.
The position is transformed and clipped to the viewport.

port: was assembly; reimplemented over the base layer

***************************************************************}

procedure setchr(vp:   viewport; { viewport }
                 x, y: integer;  { position }
                 ch:   char;     { character to place }
                 cl:   color);   { color }

begin

   viewx(vp, x); { find screen coordinates }
   viewy(vp, y);
   { clip }
   if (x >= vp.c.s.x) and (x <= vp.c.e.x) and
      (y >= vp.c.s.y) and (y <= vp.c.e.y) then
      plchr(x, y, ch, cl) { place character }

end;
{}
{**************************************************************

LINE DRAW

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The coordinates are converted to screen coordinates and the line
is clipped and drawn.

port: was assembly; endpoints are transformed and clipped, then
  the line is drawn with a single base layer call

***************************************************************}

procedure line(vp:             viewport; { viewport }
               x1, y1, x2, y2: integer;  { line start and end }
               c:              color);   { color }

var draw: boolean; { draw flag }

begin

   viewx(vp, x1); { find screen coordinates }
   viewy(vp, y1);
   viewx(vp, x2);
   viewy(vp, y2);
   clip(x1, y1, x2, y2, draw, vp.c); { clip line }
   if draw then { line still exists }
      scrline(x1, y1, x2, y2, c) { draw via base layer }

end;
{}
{**************************************************************

DRAW FILLED BOX

Draws the indicated box, with solid color.

port: was assembly; corners are transformed and clipped, then
  the box is drawn with a single base layer call

**************************************************************}

procedure block(vp:             viewport; { viewport }
                x1, y1, x2, y2: integer;  { start and end }
                c:              color);   { color }

var t: integer;

begin

   viewx(vp, x1); { find screen coordinates }
   viewy(vp, y1);
   viewx(vp, x2);
   viewy(vp, y2);
   { rationalize box }
   if x1 > x2 then
      begin t := x1; x1 := x2; x2 := t end;
   if y1 > y2 then
      begin t := y1; y1 := y2; y2 := t end;
   { clip to viewport }
   if (x1 <= vp.c.e.x) and (x2 >= vp.c.s.x) and
      (y1 <= vp.c.e.y) and (y2 >= vp.c.s.y) then begin

      { block overlays viewport at some point }
      { clip to viewport }
      if x1 < vp.c.s.x then x1 := vp.c.s.x;
      if x2 > vp.c.e.x then x2 := vp.c.e.x;
      if y1 < vp.c.s.y then y1 := vp.c.s.y;
      if y2 > vp.c.e.y then y2 := vp.c.e.y;
      { draw }
      scrblock(x1, y1, x2, y2, c) { draw via base layer }

   end

end;
{}
{**************************************************************

SET PIXEL CLIPPED

Sets a single screen pixel, clipped to the given region.

port: was assembly; reimplemented over the base layer

**************************************************************}

procedure setpixc(x, y: integer; { point coordinates }
                  c:    color;   { color }
                  cr:   region); { clip region }

begin

   { clip }
   if (x >= cr.s.x) and (x <= cr.e.x) and
      (y >= cr.s.y) and (y <= cr.e.y) then
      scrsetpix(x, y, c) { set true pixel }

end;
{}
{**************************************************************

LINE DRAW CLIPPED

Draws a line in screen coordinates, clipped to the given region.

port: was assembly; reimplemented over the base layer

**************************************************************}

procedure linec(x1, y1, x2, y2: integer; { line start and end }
                c:              color;   { color }
                cr:             region); { clip region }

var draw: boolean; { draw flag }

begin

   clip(x1, y1, x2, y2, draw, cr); { clip line }
   if draw then { line still exists }
      scrline(x1, y1, x2, y2, c) { draw via base layer }

end;
{}
{**************************************************************

BOX DRAW CLIPPED

Draws a box outline in screen coordinates, clipped to the given
region.

port: replaces the assembly boxsavc/boxrstc save-under pair.
  Each pixel of the outline is drawn exactly once, so that the
  box may be used in xor mode

**************************************************************}

procedure boxc(x1, y1, x2, y2: integer; { bounding }
               c:              color;   { color }
               cr:             region); { clip region }

var t: integer;

begin

   { rationalize box }
   if x1 > x2 then
      begin t := x1; x1 := x2; x2 := t end;
   if y1 > y2 then
      begin t := y1; y1 := y2; y2 := t end;
   linec(x1, y1, x2, y1, c, cr); { top }
   if y2 > y1 then
      linec(x1, y2, x2, y2, c, cr); { bottom }
   if y2-y1 > 1 then begin { draw sides, less corners }

      linec(x1, y1+1, x1, y2-1, c, cr); { left }
      if x2 > x1 then
         linec(x2, y1+1, x2, y2-1, c, cr) { right }

   end

end;
{}
{**************************************************************

BOLD LINE DRAW REAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
Bold lines are created by drawing three lines, of which the
indicated line is the middle line..
The line is clipped to the viewport.
Note that bold lines MUST be orthogonal.

***************************************************************}

procedure bliner(x1, y1, x2, y2: integer; { line start and end }
                 c:              color;   { line color }
                 r:              region); { clipping region }

var draw: boolean;
    s, e, ss, es: point;

begin

   s.x := x1; { place coordinates }
   s.y := y1;
   e.x := x2;
   e.y := y2;
   viewc(s, curwin^.cs^.vp); { convert coordinates }
   viewc(e, curwin^.cs^.vp);
   ss := s; { save original coordinates }
   es := e;
   { draw middle line }
   clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
   if draw then line(screen, s.x, s.y, e.x, e.y, c);
   s := ss; { restore original coordinates }
   e := es;
   if s.x = e.x then begin { line is vertical }

      s.x := s.x - 1; { move left }
      e.x := s.x;
      { draw left line }
      clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
      if draw then line(screen, s.x, s.y, e.x, e.y, c);
      s := ss; { restore original coordinates }
      e := es;
      s.x := s.x + 1; { move right }
      e.x := s.x;
      { draw left line }
      clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
      if draw then line(screen, s.x, s.y, e.x, e.y, c)

   end else begin

      s.y := s.y - 1; { move up }
      e.y := s.y;
      { draw top line }
      clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
      if draw then line(screen, s.x, s.y, e.x, e.y, c);
      s := ss; { restore original coordinates }
      e := es;
      s.y := s.y + 1; { move down }
      e.y := s.y;
      { draw bottom line }
      clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
      if draw then line(screen, s.x, s.y, e.x, e.y, c)

   end

end;
{}
{**************************************************************

DRAW BOX

Draws the indicated box.

**************************************************************}

procedure box(vp: viewport;            { viewport to draw to }
              x1, y1, x2, y2: integer; { bounding }
              c:              color);  { color }

begin

   line(vp, x1, y1, x2, y1, c); { top }
   line(vp, x1, y2, x2, y2, c); { bottom }
   line(vp, x1, y1, x1, y2, c); { left }
   line(vp, x2, y1, x2, y2, c) { right }

end;
{}
{**************************************************************

DRAW BOLD BOX REAL

Draws the real coordinate box with clipping.

**************************************************************}

procedure bboxr(x1, y1, x2, y2: integer; { ends of box }
                c:              color;   { color }
                r:              region); { clip region }

begin

   bliner(x1, y1, x2, y1, c, r); { top }
   bliner(x1, y2, x2, y2, c, r); { bottom }
   bliner(x1, y1, x1, y2, c, r); { left }
   bliner(x2, y1, x2, y2, c, r) { right }

end;
{}
{**************************************************************

ARC DRAW CLIPPED

Draws an arc between the points indicated by the start and end,
with the given center point and radius.
The figure is clipped.

**************************************************************}

procedure arcc(xs, ys,          { start }
               xe, ye,          { end }
               xc, yc,          { center }
               r:      integer; { radius }
               c:      color;   { color }
               cr:     region); { clip region }

var di, xi, yi: integer;
    m:          integer; { clipping line slope*100 }
    b:          integer; { y - intercept }
    as, ae:     real;

procedure setpixcs(x, y: integer);

var a: real;

begin

   a := angle(xc, yc, x, y);
   if ((ae >= as) and ((a > ae) or (a < as))) or
      ((as > ae) and ((as > a) and (a > ae))) then
      setpixc(x, y, c, cr)

end;

begin

   as := angle(xc, yc, xs, ys); { find angle of start }
   ae := angle(xc, yc, xe, ye); { find angle of end }
   if (xc+r >= curwin^.cs^.vp.v.s.x) and (xc-r <= curwin^.cs^.vp.v.e.x) and
      (yc+r >= curwin^.cs^.vp.v.s.y) and (yc-r <= curwin^.cs^.vp.v.e.y) then begin

      xi := 0; { setup quadrant draw }
      yi := r;
      di := 2*(1-r);
      repeat { find circle points }

         { lower right oct }
         setpixcs(xi+xc, yi+yc);
         { upper right }
         setpixcs(xi+xc, -yi+yc);
         { upper left }
         setpixcs(-xi+xc, -yi+yc);
         { lower left }
         setpixcs(-xi+xc, yi+yc);
         { find next point on circle }
         if di < 0 then begin { in 1st octant }

            if (2*di + 2*yi - 1) <= 0 then begin

               { move horizontal }
               xi := xi + 1;
               di := di + 2*xi + 1

            end else begin

               { move diagonal }
               xi := xi + 1;
               yi := yi - 1;
               di := di + 2*xi - 2*yi + 2

            end

         end else if di > 0 then begin { in second octant }

            if (2*di - 2*xi - 1) <= 0 then begin

               { move diagonal }
               xi := xi + 1;
               yi := yi - 1;
               di := di + 2*xi - 2*yi + 2

            end else begin

               { move vertical }
               yi := yi - 1;
               di := di - 2*yi + 1

            end

         end else begin

               { move diagonal }
               xi := xi + 1;
               yi := yi - 1;
               di := di + 2*xi - 2*yi + 2

         end

      until yi < 0 { past limit }

   end

end;
{}
{**************************************************************

ARC DRAW REAL

Draws an arc between the points indicated by the start and end,
with the given center point and radius.
The coordinates are real, and the figure is clipped.

**************************************************************}

procedure arcr(xs, ys,          { start }
               xe, ye,          { end }
               xc, yc,          { center }
               r:      integer; { radius }
               cl:     color;   { color }
               cr:     region); { clip region }

var s, e, c: point;

begin

   s.x := xs;
   s.y := ys;
   e.x := xe;
   e.y := ye;
   c.x := xc;
   c.y := yc;
   viewc(s, curwin^.cs^.vp); { convert coordinates }
   viewc(e, curwin^.cs^.vp); { convert coordinates }
   viewc(c, curwin^.cs^.vp); { convert coordinates }
   r := scndist(r, curwin^.cs^.vp.s.x); { convert radius }
   if (c.x+r >= cr.s.x) and (c.x-r <= cr.e.x) and
      (c.y+r >= cr.s.y) and (c.y-r <= cr.e.y) then
      { within active area }
      arcc(s.x, s.y, e.x, e.y, c.x, c.y, r, cl, cr) { draw arc }

end;
{}
{**************************************************************

PIE DRAW REAL

Draws a filled circle with the given center and radius.
The figure is clipped.

**************************************************************}

procedure pier(xc, yc,          { center }
               r:      integer; { radius }
               cl:     color;   { color }
               cr:     region); { clip region }

var di, xi, yi: integer;
    c: point;

procedure mh; { move horizontal }

begin

   xi := xi + 1;
   di := di + 2*xi + 1

end;

procedure mv; { move vertical }

begin

   yi := yi - 1;
   di := di - 2*yi + 1

end;

procedure md; { move diagonaly }

begin

   xi := xi + 1;
   yi := yi - 1;
   di := di + 2*xi - 2*yi + 2;

end;

begin

   c.x := xc;
   c.y := yc;
   viewc(c, curwin^.cs^.vp); { convert coordinates }
   r := scndist(r, curwin^.cs^.vp.s.x); { convert radius }
   if (c.x+r >= cr.s.x) and (c.x-r <= cr.e.x) and
      (c.y+r >= cr.s.y) and (c.y-r <= cr.e.y) then begin

      { some part lies within active area }
      xi := 0; { draw quadrant }
      yi := r;
      di := 2*(1-r);
      repeat { find circle points }

         linec(-xi+c.x, -yi+c.y, xi+c.x, -yi+c.y, cl, cr);
         linec(-xi+c.x, yi+c.y, xi+c.x, yi+c.y, cl, cr);
         { find next point on circle }
         if di < 0 then begin { in 1st octant }

            if (2*di + 2*yi - 1) <= 0 then mh { horizontal }
            else md { diagonal }

         end else if di > 0 then begin { in second octant }

            if (2*di - 2*xi - 1) <= 0 then md { diagonal }
            else mv { vertical }

         end else md

      until yi < 0 { past limit }

   end

end;
{}
{**************************************************************

CONNECTOR DRAW

Draws a connector at the given location and size.

**************************************************************}

procedure con(vp:   viewport; { viewport to draw to }
              x, y,           { center }
              r:    integer;  { radius (actually width) }
              c:    color;    { color }
              cr:   region);  { clip region }

{ port: clip region parameter retained but unused; line clips to vp.c }

begin

   line(vp, x-r, y-r, x-r, y+r, c); { draw left side }
   line(vp, x+r, y-r, x+r, y+r, c); { right side }
   line(vp, x-r, y-r, x+r, y-r, c); { top side }
   line(vp, x-r, y+r, x+r, y+r, c); { bottom side }
   line(vp, x-r, y, x+r, y, c); { cross }
   line(vp, x, y-r, x, y+r, c)

end;
{}
{**************************************************************

FIND SNAP COORDINATES

If the snap to grid mode is on, the given coordinates are
converted to the nearest grid points, otherwise are unchanged.
The coordinates specified are real.

**************************************************************}

procedure snapto(var x, y: integer);

var i: integer;

begin

   if button[bawave].act then begin

      { use analog trace rules }
      if y < 0 then y := 0; { fix negatives }
      if x < 0 then x := 0

   end else if button[bdwave].act then begin

      { use digital trace rules }
      if y < 0 then y := 0; { fix negatives }
      if x < 0 then x := 0;
      i := y mod trcsiz; { find within trace }
      y := y - i; { find base }
      if i <= 1650 then i := 900
      else if i <= 3150 then i := 2400
      else i := 3900;
      y := y + i; { find final y }
      x := ((x+(stpsiz div 2)) div stpsiz) * stpsiz

   end;
   if not cntdrw then
     if button[bsnap].act and not button[bdwave].act then begin

      { use grid rules }
      if x >= 0 then i := curwin^.cs^.ds div 2
      else i := -(curwin^.cs^.ds div 2);
      x := ((x+i) div curwin^.cs^.ds) * curwin^.cs^.ds;
      if y >= 0 then i := curwin^.cs^.ds div 2
      else i := -(curwin^.cs^.ds div 2);
      y := ((y+i) div curwin^.cs^.ds) * curwin^.cs^.ds;

   end

end;
{}
{**************************************************************

CHECK COORDINATES IN ACTIVE AREA

Checks if the given coordinates lie in the active drawing area.

**************************************************************}

function inactive(p: point): boolean;

begin

   inactive := (p.x >= curwin^.cs^.vp.v.s.x) and (p.x <= curwin^.cs^.vp.v.e.x) and
               (p.y >= curwin^.cs^.vp.v.s.y) and (p.y <= curwin^.cs^.vp.v.e.y)

end;
{}
{**************************************************************

CHECK COORDINATES IN TARGET AREA

Checks if the given coordinates lie in the target drawing area.

**************************************************************}

function intarget(p: point): boolean;

begin

   intarget := (p.x >= curwin^.tr.s.x) and
               (p.x <= curwin^.tr.e.x) and
               (p.y >= curwin^.tr.s.y) and
               (p.y <= curwin^.tr.e.y)

end;
{}
{**************************************************************

SET LINE ENDPOINT

Sets the true line endpoint based on the current restriction
mode. This is determined from the line start and current
cursor position parameters.

*************************************************************}

procedure setend;

var dx, dy: real;
    d:      integer;
    a, b:   real;
    lc:     integer;
    y1, y2: integer;

begin

   dx := abs(str.x - rcur.x); { find difference to new point }
   dy := abs(str.y - rcur.y);
   if button[bawave].act then begin { analog waveform mode }

      endp.x := rcur.x; { set same as cursor }
      endp.y := rcur.y;
      y1 := (endp.y div trcsiz) * trcsiz;
      y2 := (str.y div trcsiz) * trcsiz;
      if (y1 <> y2) or (endp.y < 0) then begin

         { not in same trace }
         if endp.y < str.y then endp.y := y2
         else endp.y := y2 + trcsiz

      end;
      snapto(endp.x, endp.y) { snap to grid }

   end else if button[bdwave].act then begin { digital waveform mode }

      { limit to 90 deg }
      if dy > dx then begin { closer to y axis }

         endp.x := str.x; { set x same as original }
         endp.y := rcur.y  { set y same as new }

      end else begin { closer to x axis (and decisions for 45 deg) }

         endp.x := rcur.x; { set x same as new }
         endp.y := str.y  { set y same as original }

      end;
      y1 := (endp.y div trcsiz) * trcsiz;
      y2 := (str.y div trcsiz) * trcsiz;
      if (y1 <> y2) or (endp.y < 0) then begin

         { not in same trace }
         if endp.y < str.y then endp.y := y2 + 900
         else endp.y := y2 + 3900

      end;
      snapto(endp.x, endp.y) { snap to grid }

   end else if button[b90].act or (drmbut in [bbline, bbus]) then begin { 90 deg }

      if dy > dx then begin { closer to y axis }

         endp.x := str.x; { set x same as original }
         endp.y := rcur.y  { set y same as new }

      end else begin { closer to x axis (and decisions for 45 deg) }

         endp.x := rcur.x; { set x same as new }
         endp.y := str.y  { set y same as original }

      end;
      snapto(endp.x, endp.y) { snap to grid }

   end else if button[b45].act then begin { 45 deg }

      if dy < dx then begin { closer to x axis }

         a := arctan(dy/dx); { find angle }
         if a < (pi/8) then begin { on axis }

            endp.x := rcur.x; { set x same as new }
            endp.y := str.y;  { set y same as original }
            snapto(endp.x, endp.y) { snap to grid }

         end else begin { on 45 deg }

            b := (pi/4) - a; { find remaining angle }
            { find true length to cursor }
            lc := round(sqrt(sqr(dy)+sqr(dx)));
            lc := round(lc * cos(b)); { find length to 45 deg }
            d := round(lc * cos(pi/4)); { find length of legs }
            if rcur.x < str.x then endp.x := str.x - d { find new x }
            else endp.x := str.x + d;
            { snap and recalcuate distance }
            if button[bsnap].act then
               endp.x := ((endp.x+(curwin^.cs^.ds div 2)) div curwin^.cs^.ds) *
                         curwin^.cs^.ds;
            d := abs(endp.x-str.x);
            if rcur.y < str.y then endp.y := str.y - d { find new y }
            else endp.y := str.y + d

         end

      end else begin { closer to y axis }

         if dy <> 0 then a := arctan(dx/dy); { find angle }
         if (a < (pi/8)) or (dy = 0) then begin { on axis }

            endp.x := str.x; { set x same as original }
            endp.y := rcur.y;  { set y same as new }
            snapto(endp.x, endp.y) { snap to grid }

         end else begin { on 45 deg }

            b := (pi/4) - a; { find remaining angle }
            { find true length to cursor }
            lc := round(sqrt(sqr(dy)+sqr(dx)));
            lc := round(lc * cos(b)); { find length to 45 deg }
            d := round(lc * cos(pi/4)); { find length of legs }
            if rcur.x < str.x then endp.x := str.x - d { find new x }
            else endp.x := str.x + d;
            { snap and recalcuate distance }
            if button[bsnap].act then
               endp.x := ((endp.x+(curwin^.cs^.ds div 2)) div curwin^.cs^.ds) *
                         curwin^.cs^.ds;
            d := abs(endp.x-str.x);
            if rcur.y < str.y then endp.y := str.y - d { find new y }
            else endp.y := str.y + d

         end

      end

   end else begin { any }

      endp.x := rcur.x; { set same as cursor }
      endp.y := rcur.y;
      snapto(endp.x, endp.y) { snap to grid }

   end

end;
{}
{**************************************************************

SET ASPECT BOX

Sets the aspect or zoom box according to the marked box.
Finds the closest fitting box to the indicator box that matches
the screen aspect ratio.

**************************************************************}

procedure setasp;

var an:                          real;
    d:                           integer;
    x1, y1, x2, y2, x2r, y2r, s: integer;
    rdw, rde, rdn, rds:          integer; { NEWS to world edge }
    t:                           integer;
    t1:                          integer;
    tr:                          real;
    p:                           point;

begin

   x1 := mrk.x; { get indicator box parameters }
   y1 := mrk.y;
   x2 := cur.x;
   y2 := cur.y;
   ratbox(x1, y1, x2, y2); { rationalize box }
   { find box diagonal }
   if (x1 <> x2) and (y1 <> y2) then
      an := arctan(abs(x2-x1)/abs(y2-y1));
   if ((an < curwin^.aa) or (x1 = x2)) and (y1 <> y2) then begin { y dominated }

      zb.s.y := y1; { set y's }
      zb.e.y := y2;
      { find offset distance to x's }
      d := round(((abs(y2-y1)/2)/tan((pi/2)-curwin^.aa))-(abs(x2-x1)/2));
      zb.s.x := x1 - d; { set x's }
      zb.e.x := x2 + d

   end else begin { x dominated }

      zb.s.x := x1; { set x's }
      zb.e.x := x2;
      { find offset distance to y's }
      d := round(((abs(x2-x1)/2)/tan(curwin^.aa))-(abs(y2-y1)/2));
      zb.s.y := y1 - d; { set y's }
      zb.e.y := y2 + d

   end;
   if vimbut = bin then begin { determine the minimum box size }

      { find x and y minimum lengths }
      x1 := scndist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1,
                    curwin^.cs^.vp.s.x);
      y1 := scndist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1,
                    curwin^.cs^.vp.s.y);
      if abs(zb.e.x-zb.s.x)+1 < x1 then begin { expand to proper size }

         x2 := zb.s.x+((abs(zb.e.x-zb.s.x)+1) div 2);
         zb.s.x := x2 - x1 div 2;
         zb.e.x := x2 + x1 div 2

      end;
      if abs(zb.e.y-zb.s.y)+1 < y1 then begin { expand to proper size }

         y2 := zb.s.y+((abs(zb.e.y-zb.s.y)+1) div 2);
         zb.s.y := y2 - y1 div 2;
         zb.e.y := y2 + y1 div 2

      end;
      { validate for real bounds }
      p := zb.s;
      if inactive(cur) then realc(p, curwin^.cs^.vp) { convert coordinates }
      else realc(p, targvp);
      x1 := p.x;
      y1 := p.y;
      p := zb.e;
      if inactive(cur) then realc(p, curwin^.cs^.vp) { convert coordinates }
      else realc(p, targvp);
      x2 := p.x;
      y2 := p.y;
      if (x1 < rw.s.x) or (y1 < rw.s.y) or
         (x2 > rw.e.x) or (y2 > rw.e.y) then begin

         { set zoom box to no-op }
         zb.s.x := curwin^.cs^.vp.v.s.x;
         zb.e.x := curwin^.cs^.vp.v.e.x;
         zb.s.y := curwin^.cs^.vp.v.s.y;
         zb.e.y := curwin^.cs^.vp.v.e.y

      end

   end else if vimbut = bout then begin { determine maximum box size }

      if (zb.s.x = zb.e.x) or (zb.s.y = zb.e.y) then begin

         { zoom box null, set zoom box to no-op }
         zb.s.x := curwin^.cs^.vp.v.s.x;
         zb.e.x := curwin^.cs^.vp.v.e.x;
         zb.s.y := curwin^.cs^.vp.v.s.y;
         zb.e.y := curwin^.cs^.vp.v.e.y

      end else begin { ok }

         { find new scale }
         tr := curwin^.cs^.vp.s.x*(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/abs(zb.e.y-zb.s.y));
         if tr > (maxint div scalem) then begin

            { set zoom box to no-op }
            zb.s.x := curwin^.cs^.vp.v.s.x;
            zb.e.x := curwin^.cs^.vp.v.e.x;
            zb.s.y := curwin^.cs^.vp.v.s.y;
            zb.e.y := curwin^.cs^.vp.v.e.y

         end else begin { scale ok }

            s := round(tr); { place scale }
            { find NEWS distance from present screen to real limits }
            p := curwin^.cs^.vp.v.e; { get screen end }
            realc(p, curwin^.cs^.vp); { convert coordinates }
            rdw := abs(curwin^.cs^.vp.r.s.x-rw.s.x)*scalem div s;
            rde := abs(rw.e.x - p.x)*scalem div s;
            rdn := abs(curwin^.cs^.vp.r.s.y-rw.s.y)*scalem div s;
            rds := abs(rw.e.y - p.y)*scalem div s;
            { find NEWS distance from present screen to new screen }
            x1 := abs(zb.s.x-curwin^.cs^.vp.v.s.x);
            x2 := abs(curwin^.cs^.vp.v.e.x-zb.e.x);
            y1 := abs(zb.s.y-curwin^.cs^.vp.v.s.y);
            y2 := abs(curwin^.cs^.vp.v.e.y-zb.e.y);
            { check valid distances }
            if (x1 > rdw) or (x2 > rde) or
               (y1 > rdn) or (y2 > rds) then begin

               { set zoom box to no-op }
               zb.s.x := curwin^.cs^.vp.v.s.x;
               zb.e.x := curwin^.cs^.vp.v.e.x;
               zb.s.y := curwin^.cs^.vp.v.s.y;
               zb.e.y := curwin^.cs^.vp.v.e.y

            end

         end

      end

   end

end;
{}
{**************************************************************

SET ZOOM BOX TO SCREEN

Sets the zoom indicator boxes to screen. This consists of the
indicator box nested inside the ratio box.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setzoom;

var x1, y1, x2, y2: integer;
    t:              integer;
    r:              region;

begin

   if not zbxdwn and puck.v then begin { not already down }

      if not blank then begin { screen not blank }

         { assign what region to draw }
         if inactive(mrk) then r := curwin^.cs^.vp.v else r := targvp.v;
         x1 := mrk.x; { get indicator box parameters }
         y1 := mrk.y;
         x2 := cur.x;
         y2 := cur.y;
         ratbox(x1, y1, x2, y2); { rationalize }
         xormode; { draw in xor mode }
         boxc(x1, y1, x2, y2, lmagenta, r);
         { left side }
         if zb.s.x <> x1 then
            linec(zb.s.x, zb.s.y+1, zb.s.x, zb.e.y-1, lgreen, r)
         else if (y1 - zb.s.y) > 1 then begin { split line }

            linec(zb.s.x, zb.s.y+1, zb.s.x, y1-1, lgreen, r);
            linec(zb.s.x, y2+1, zb.s.x, zb.e.y-1, lgreen, r)

         end;
         { right side }
         if zb.e.x <> x2 then
            linec(zb.e.x, zb.s.y+1, zb.e.x, zb.e.y-1, lgreen, r)
         else if (y1 - zb.s.y) > 1 then begin { split line }

            linec(zb.e.x, zb.s.y+1, zb.e.x, y1-1, lgreen, r);
            linec(zb.e.x, y2+1, zb.e.x, zb.e.y-1, lgreen, r)

         end;
         { top side }
         if zb.s.y <> y1 then
            linec(zb.s.x, zb.s.y, zb.e.x, zb.s.y, lgreen, r)
         else if (x1 - zb.s.x) > 1 then begin { split line }

            linec(zb.s.x, zb.s.y, x1-1, zb.s.y, lgreen, r);
            linec(x2+1, zb.s.y, zb.e.x, zb.s.y, lgreen, r)

         end;
         { bottom side }
         if zb.e.y <> y2 then
            linec(zb.s.x, zb.e.y, zb.e.x, zb.e.y, lgreen, r)
         else if (x1 - zb.s.x) > 1 then begin { split line }

            linec(zb.s.x, zb.e.y, x1-1, zb.e.y, lgreen, r);
            linec(x2+1, zb.e.y, zb.e.x, zb.e.y, lgreen, r)

         end;
         ovrmode { return to overwrite mode }

      end;
      zbxdwn := true { flag zoom box down }

   end

end;
{}
{**************************************************************

RESET ZOOM BOX FROM SCREEN

Removes the zoom box combination from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure reszoom;

var x1, y1, x2, y2: integer;
    t:              integer;
    r:              region;

begin

   if zbxdwn then begin { zoom box onscreen }

      if not blank then begin { screen not blank }

         { assign what region to draw }
         if inactive(mrk) then r := curwin^.cs^.vp.v else r := targvp.v;
         x1 := mrk.x; { get indicator box parameters }
         y1 := mrk.y;
         x2 := cur.x;
         y2 := cur.y;
         ratbox(x1, y1, x2, y2); { rationalize }
         xormode; { draw in xor mode }
         boxc(x1, y1, x2, y2, lmagenta, r);
         { left side }
         if zb.s.x <> x1 then
            linec(zb.s.x, zb.s.y+1, zb.s.x, zb.e.y-1, lgreen, r)
         else if (y1 - zb.s.y) > 1 then begin { split line }

            linec(zb.s.x, zb.s.y+1, zb.s.x, y1-1, lgreen, r);
            linec(zb.s.x, y2+1, zb.s.x, zb.e.y-1, lgreen, r)

         end;
         { right side }
         if zb.e.x <> x2 then
            linec(zb.e.x, zb.s.y+1, zb.e.x, zb.e.y-1, lgreen, r)
         else if (y1 - zb.s.y) > 1 then begin { split line }

            linec(zb.e.x, zb.s.y+1, zb.e.x, y1-1, lgreen, r);
            linec(zb.e.x, y2+1, zb.e.x, zb.e.y-1, lgreen, r)

         end;
         { top side }
         if zb.s.y <> y1 then
            linec(zb.s.x, zb.s.y, zb.e.x, zb.s.y, lgreen, r)
         else if (x1 - zb.s.x) > 1 then begin { split line }

            linec(zb.s.x, zb.s.y, x1-1, zb.s.y, lgreen, r);
            linec(x2+1, zb.s.y, zb.e.x, zb.s.y, lgreen, r)

         end;
         { bottom side }
         if zb.e.y <> y2 then
            linec(zb.s.x, zb.e.y, zb.e.x, zb.e.y, lgreen, r)
         else if (x1 - zb.s.x) > 1 then begin { split line }

            linec(zb.s.x, zb.e.y, x1-1, zb.e.y, lgreen, r);
            linec(x2+1, zb.e.y, zb.e.x, zb.e.y, lgreen, r)

         end;
         ovrmode { return to overwrite mode }

      end;
      zbxdwn := false { set zoom box up }

   end

end;
{}
{**************************************************************

SET CURSOR TO SCREEN

Places the crosshair cursor on the screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setcur; { draw cursor into place }

{ port: uiscl - cross arm lengths scaled to character cell }

var lx, ly, mx, my, y1, y2: integer;

begin

   if not curdwn and puck.v and not blank then begin

      { cursor not already down, and is valid }
      mcur.x := cur.x; { place cursor mark coords }
      mcur.y := cur.y;
      lx := cur.x-uiscl(10); { find extremes of cross }
      ly := cur.y-uiscl(10);
      mx := cur.x+uiscl(10);
      my := cur.y+uiscl(10);
      y1 := cur.y-1;
      y2 := cur.y+1;
      { clip }
      if lx < minx then lx := minx;
      if ly < miny then ly := miny;
      if mx > maxx then mx := maxx;
      if my > maxy then my := maxy;
      xormode; { draw in xor mode }
      line(screen, lx, cur.y, mx, cur.y, lmagenta);
      if y1 >= miny then
         line(screen, cur.x, ly, cur.x, y1, lmagenta);
      if y2 <= maxy then
         line(screen, cur.x, y2, cur.x, my, lmagenta);
      ovrmode; { return to overwrite mode }
      curdwn := true { set cursor on screen }

   end

end;
{}
{**************************************************************

RESET CURSOR FROM SCREEN

Removes the crosshair cursor from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure rescur; { remove cursor }

{ port: uiscl - cross arm lengths scaled to character cell }

var lx, ly, mx, my, y1, y2: integer;

begin

   if curdwn and not blank then begin { cursor is down }

      lx := mcur.x-uiscl(10); { find extremes of cross }
      ly := mcur.y-uiscl(10);
      mx := mcur.x+uiscl(10);
      my := mcur.y+uiscl(10);
      y1 := mcur.y-1;
      y2 := mcur.y+1;
      { clip }
      if lx < minx then lx := minx;
      if ly < miny then ly := miny;
      if mx > maxx then mx := maxx;
      if my > maxy then my := maxy;
      xormode; { draw in xor mode }
      line(screen, lx, mcur.y, mx, mcur.y, lmagenta);
      if y1 >= miny then
         line(screen, mcur.x, ly, mcur.x, y1, lmagenta);
      if y2 <= maxy then
         line(screen, mcur.x, y2, mcur.x, my, lmagenta);
      ovrmode; { return to overwrite mode }
      curdwn := false { set cursor not on screen }

   end

end;
{}
{**************************************************************

SET MARKER TO SCREEN

Places the marker cross on the screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setmrk;

var r: region;

begin

   if not mrkdwn then begin { marker not already down }

      if not blank then begin { screen not blank }

         { assign what region to draw }
         if inactive(mrk) then r := curwin^.cs^.vp.v else r := targvp.v;
         xormode; { draw in xor mode }
         { cross }
         { port: uiscl - arm/arrowhead/box geometry scaled to character
           cell (1 pixel center skips and corner steps kept exact) }
         linec(mrk.x-uiscl(10), mrk.y, mrk.x+uiscl(10), mrk.y, lgreen, r);
         linec(mrk.x, mrk.y-uiscl(10), mrk.x, mrk.y-1, lgreen, r);
         linec(mrk.x, mrk.y+1, mrk.x, mrk.y+uiscl(10), lgreen, r);
         { arrowheads, east/west }
         linec(mrk.x-uiscl(9), mrk.y-1, mrk.x-uiscl(7), mrk.y-uiscl(3), lgreen, r);
         linec(mrk.x-uiscl(9), mrk.y+1, mrk.x-uiscl(7), mrk.y+uiscl(3), lgreen, r);
         linec(mrk.x+uiscl(9), mrk.y-1, mrk.x+uiscl(7), mrk.y-uiscl(3), lgreen, r);
         linec(mrk.x+uiscl(9), mrk.y+1, mrk.x+uiscl(7), mrk.y+uiscl(3), lgreen, r);
         { arrowheads, north, south }
         linec(mrk.x-1, mrk.y-uiscl(9), mrk.x-uiscl(3), mrk.y-uiscl(7), lgreen, r);
         linec(mrk.x+1, mrk.y-uiscl(9), mrk.x+uiscl(3), mrk.y-uiscl(7), lgreen, r);
         linec(mrk.x-1, mrk.y+uiscl(9), mrk.x-uiscl(3), mrk.y+uiscl(7), lgreen, r);
         linec(mrk.x+1, mrk.y+uiscl(9), mrk.x+uiscl(3), mrk.y+uiscl(7), lgreen, r);
         { box around that }
         linec(mrk.x-uiscl(12), mrk.y-uiscl(12), mrk.x+uiscl(12), mrk.y-uiscl(12), lgreen, r);
         linec(mrk.x-uiscl(12), mrk.y-uiscl(12)+1, mrk.x-uiscl(12), mrk.y+uiscl(12)-1, lgreen, r);
         linec(mrk.x+uiscl(12), mrk.y-uiscl(12)+1, mrk.x+uiscl(12), mrk.y+uiscl(12)-1, lgreen, r);
         linec(mrk.x-uiscl(12), mrk.y+uiscl(12), mrk.x+uiscl(12), mrk.y+uiscl(12), lgreen, r);
         ovrmode { return to overwrite mode }

      end;
      mrkdwn := true { set marker down }

   end

end;
{}
{**************************************************************

RESET MARKER FROM SCREEN

Erases the marker from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure resmrk;

var r: region;

begin

   if mrkdwn then begin { marker is down }

      if not blank then begin { screen not blank }

         { assign what region to draw }
         if inactive(mrk) then r := curwin^.cs^.vp.v else r := targvp.v;
         xormode; { draw in xor mode }
         { cross }
         { port: uiscl - arm/arrowhead/box geometry scaled to character
           cell (1 pixel center skips and corner steps kept exact) }
         linec(mrk.x-uiscl(10), mrk.y, mrk.x+uiscl(10), mrk.y, lgreen, r);
         linec(mrk.x, mrk.y-uiscl(10), mrk.x, mrk.y-1, lgreen, r);
         linec(mrk.x, mrk.y+1, mrk.x, mrk.y+uiscl(10), lgreen, r);
         { arrowheads, east/west }
         linec(mrk.x-uiscl(9), mrk.y-1, mrk.x-uiscl(7), mrk.y-uiscl(3), lgreen, r);
         linec(mrk.x-uiscl(9), mrk.y+1, mrk.x-uiscl(7), mrk.y+uiscl(3), lgreen, r);
         linec(mrk.x+uiscl(9), mrk.y-1, mrk.x+uiscl(7), mrk.y-uiscl(3), lgreen, r);
         linec(mrk.x+uiscl(9), mrk.y+1, mrk.x+uiscl(7), mrk.y+uiscl(3), lgreen, r);
         { arrowheads, north, south }
         linec(mrk.x-1, mrk.y-uiscl(9), mrk.x-uiscl(3), mrk.y-uiscl(7), lgreen, r);
         linec(mrk.x+1, mrk.y-uiscl(9), mrk.x+uiscl(3), mrk.y-uiscl(7), lgreen, r);
         linec(mrk.x-1, mrk.y+uiscl(9), mrk.x-uiscl(3), mrk.y+uiscl(7), lgreen, r);
         linec(mrk.x+1, mrk.y+uiscl(9), mrk.x+uiscl(3), mrk.y+uiscl(7), lgreen, r);
         { box around that }
         linec(mrk.x-uiscl(12), mrk.y-uiscl(12), mrk.x+uiscl(12), mrk.y-uiscl(12), lgreen, r);
         linec(mrk.x-uiscl(12), mrk.y-uiscl(12)+1, mrk.x-uiscl(12), mrk.y+uiscl(12)-1, lgreen, r);
         linec(mrk.x+uiscl(12), mrk.y-uiscl(12)+1, mrk.x+uiscl(12), mrk.y+uiscl(12)-1, lgreen, r);
         linec(mrk.x-uiscl(12), mrk.y+uiscl(12), mrk.x+uiscl(12), mrk.y+uiscl(12), lgreen, r);
         ovrmode { return to overwrite mode }

      end;
      mrkdwn := false { set marker up }

   end

end;
{}
{**************************************************************

SET RULER MARK

Places the ruler mark to screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setrlm;

begin

   if not rlmdwn then begin { ruler mark not down }

      if not blank then begin { screen not blank }

         xormode; { draw in xor mode }
         { cross }
         { port: uiscl - arm lengths and circle radius scaled }
         linec(mrk.x-uiscl(10), mrk.y, mrk.x+uiscl(10), mrk.y, lgreen,
               curwin^.cs^.vp.v);
         linec(mrk.x, mrk.y-uiscl(10), mrk.x, mrk.y-1, lgreen,
               curwin^.cs^.vp.v);
         linec(mrk.x, mrk.y+1, mrk.x, mrk.y+uiscl(10), lgreen,
               curwin^.cs^.vp.v);
         { circle around that }
         arcc(mrk.x, mrk.y+uiscl(10), mrk.x-1, mrk.y+uiscl(10), mrk.x, mrk.y,
              uiscl(11), lgreen, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      rlmdwn := true { set ruler mark down }

   end

end;
{}
{**************************************************************

RESET RULER MARK

Resets the ruler mark from screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure resrlm;

begin

   if rlmdwn then begin { ruler is down }

      if not blank then begin { screen not blank }

         xormode; { draw in xor mode }
         { cross }
         { port: uiscl - arm lengths and circle radius scaled }
         linec(mrk.x-uiscl(10), mrk.y, mrk.x+uiscl(10), mrk.y, lgreen,
               curwin^.cs^.vp.v);
         linec(mrk.x, mrk.y-uiscl(10), mrk.x, mrk.y-1, lgreen,
               curwin^.cs^.vp.v);
         linec(mrk.x, mrk.y+1, mrk.x, mrk.y+uiscl(10), lgreen,
               curwin^.cs^.vp.v);
         { circle around that }
         arcc(mrk.x, mrk.y+uiscl(10), mrk.x-1, mrk.y+uiscl(10), mrk.x, mrk.y,
              uiscl(11), lgreen, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      rlmdwn := false { set ruler mark up }

   end

end;
{}
{**************************************************************

SET LINE

Sets the in-progress line to the screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setline;

var l: region; { line coordiantes }

begin

   if not lindwn then begin { line not down }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         l.s := str;
         viewc(l.s, curwin^.cs^.vp);
         l.e := endp;
         viewc(l.e, curwin^.cs^.vp);
         { place line }
         xormode; { draw in xor mode }
         linec(l.s.x, l.s.y, l.e.x, l.e.y, lmagenta, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      lindwn := true { set line down }

   end

end;
{}
{**************************************************************

RESET LINE

Resets the in-progress line from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure resline;

var l: region;

begin

   if lindwn then begin { line on screen }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         l.s := str;
         viewc(l.s, curwin^.cs^.vp);
         l.e := endp;
         viewc(l.e, curwin^.cs^.vp);
         { place line }
         xormode; { draw in xor mode }
         linec(l.s.x, l.s.y, l.e.x, l.e.y, lmagenta, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      lindwn := false { set line not down }

   end

end;
{}
{**************************************************************

SET BOX

Sets the in-progress box to the screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setbox;

var b: region; { box coordinates }

begin

   if not boxdwn then begin { box not onscreen }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         b.s := str;
         viewc(b.s, curwin^.cs^.vp);
         b.e := endp;
         viewc(b.e, curwin^.cs^.vp);
         { place box }
         xormode; { draw in xor mode }
         boxc(b.s.x, b.s.y, b.e.x, b.e.y, lmagenta, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      boxdwn := true { set box down }

   end

end;
{}
{**************************************************************

RESET BOX

Resets the in-progress box from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure resbox;

var b: region; { box coordinates }

begin

   if boxdwn then begin { box cursor onscreen }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         b.s := str;
         viewc(b.s, curwin^.cs^.vp);
         b.e := endp;
         viewc(b.e, curwin^.cs^.vp);
         { place box }
         xormode; { draw in xor mode }
         boxc(b.s.x, b.s.y, b.e.x, b.e.y, lmagenta, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      boxdwn := false { set box up }

   end

end;
{}
{**************************************************************

SET CIRCLE

Sets the in-progress circle to the screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setcircle;

var r:    integer;
    s, c: point;

begin

   if not cirdwn then begin { circle not down }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         c := cen;
         viewc(c, curwin^.cs^.vp);
         s := str;
         viewc(s, curwin^.cs^.vp);
         { convert radius }
         r := scndist(rad, curwin^.cs^.vp.s.x);
         { place circle }
         xormode; { draw in xor mode }
         arcc(s.x, s.y, s.x-1, s.y, c.x, c.y, r, lmagenta,
              curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      cirdwn := true { set circle down }

   end

end;
{}
{**************************************************************

RESET CIRCLE

Resets the in-progress circle from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure rescircle;

var r:    integer;
    s, c: point;

begin

   if cirdwn then begin { circle is down }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         c := cen;
         viewc(c, curwin^.cs^.vp);
         s := str;
         viewc(s, curwin^.cs^.vp);
         { convert radius }
         r := scndist(rad, curwin^.cs^.vp.s.x);
         { place circle }
         xormode; { draw in xor mode }
         arcc(s.x, s.y, s.x-1, s.y, c.x, c.y, r, lmagenta,
              curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      cirdwn := false { set circle up }

   end

end;
{}
{**************************************************************

SET ARC

Sets the in-progress arc to the screen.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure setarc;

var a: sarc;

begin

   if not arcdwn then begin { arc not down }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         a.s := str;
         viewc(a.s, curwin^.cs^.vp);
         a.e := endp;
         viewc(a.e, curwin^.cs^.vp);
         a.c := cen;
         viewc(a.c, curwin^.cs^.vp);
         { convert radius }
         a.r := scndist(rad, curwin^.cs^.vp.s.x);
         { place arc }
         xormode; { draw in xor mode }
         arcc(a.s.x, a.s.y, a.e.x, a.e.y, a.c.x, a.c.y, a.r, lmagenta,
              curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      arcdwn := true { set arc down }

   end

end;
{}
{**************************************************************

RESET ARC

Resets the in-progress arc from the screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure resarc;

var a: sarc;

begin

   if arcdwn then begin { arc is down }

      if not blank then begin { screen not blank }

         { find screen coordinates }
         a.s := str;
         viewc(a.s, curwin^.cs^.vp);
         a.e := endp;
         viewc(a.e, curwin^.cs^.vp);
         a.c := cen;
         viewc(a.c, curwin^.cs^.vp);
         { convert radius }
         a.r := scndist(rad, curwin^.cs^.vp.s.x);
         { place arc }
         xormode; { draw in xor mode }
         arcc(a.s.x, a.s.y, a.e.x, a.e.y, a.c.x, a.c.y, a.r, lmagenta,
              curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      arcdwn := false { set arc up }

   end

end;
{}
{**************************************************************

SET TEXT CURSOR

Sets the text (box) cursor to screen. This cursor is a box
with the same height and width as the a character in the
current size.

port: converted from save-under to xor rubber banding

**************************************************************}

procedure settcur;

var b: region; { box coordinates }

begin

   if not tcrdwn then begin { text cursor down }

      if not blank then begin { screen not blank }

         { place cursor block (whose height and width equals a char) }
         if textrot then begin { rotated }

            b.s.x := tcur.x; { place coordinates }
            b.s.y := tcur.y;
            b.e.x := tcur.x+chrhdt*curwin^.cs^.ts;
            b.e.y := tcur.y+chrwdt*curwin^.cs^.ts

         end else begin { normal }

            b.s.x := tcur.x; { place coordinates }
            b.s.y := tcur.y-chrhdt*curwin^.cs^.ts;
            b.e.x := tcur.x+chrwdt*curwin^.cs^.ts;
            b.e.y := tcur.y

         end;
         viewc(b.s, curwin^.cs^.vp); { convert to screen }
         viewc(b.e, curwin^.cs^.vp);
         { place box }
         xormode; { draw in xor mode }
         boxc(b.s.x, b.s.y, b.e.x, b.e.y, lmagenta, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      tcrdwn := true { set text cursor down }

   end

end;
{}
{**************************************************************

RESET TEXT CURSOR

Resets the text (box) cursor from screen.

port: converted from save-under to xor rubber banding; draws
  the identical figure to remove it

**************************************************************}

procedure restcur;

var b: region; { box coordinates }

begin

   if tcrdwn then begin { text cursor down }

      if not blank then begin { screen not blank }

         { remove cursor block }
         if textrot then begin { rotated }

            b.s.x := tcur.x; { place coordinates }
            b.s.y := tcur.y;
            b.e.x := tcur.x+chrhdt*curwin^.cs^.ts;
            b.e.y := tcur.y+chrwdt*curwin^.cs^.ts

         end else begin { normal }

            b.s.x := tcur.x; { place coordinates }
            b.s.y := tcur.y-chrhdt*curwin^.cs^.ts;
            b.e.x := tcur.x+chrwdt*curwin^.cs^.ts;
            b.e.y := tcur.y

         end;
         viewc(b.s, curwin^.cs^.vp); { convert to screen }
         viewc(b.e, curwin^.cs^.vp);
         { remove box }
         xormode; { draw in xor mode }
         boxc(b.s.x, b.s.y, b.e.x, b.e.y, lmagenta, curwin^.cs^.vp.v);
         ovrmode { return to overwrite mode }

      end;
      tcrdwn := false { set text cursor up }

   end

end;
{}
{**************************************************************

CHECK CURSOR OVERLAYS BUTTON

Checks if the cursor overlays the given button at any point.

**************************************************************}

function onbutton(b: buttyp): boolean;

begin

   { port: uiscl - cursor arm overlap distance scaled }
   onbutton := (mcur.x+uiscl(10) >= button[b].r.s.x) and
               (mcur.x-uiscl(10) <= button[b].r.e.x) and
               (mcur.y+uiscl(10) >= button[b].r.s.y) and
               (mcur.y-uiscl(10) <= button[b].r.e.y)

end;
{}
{**************************************************************

CHECK CURSOR IN BUTTON

Checks if the cursor is in the given button.

**************************************************************}

function inbutton(b: buttyp): boolean;

begin

   inbutton := (cur.x >= button[b].r.s.x) and
               (cur.x <= button[b].r.e.x) and
               (cur.y >= button[b].r.s.y) and
               (cur.y <= button[b].r.e.y)

end;
{}
{**************************************************************

PLACE MENU CHARACTER

Places a menu character. The menu is divided into character
cell blocks, each of which contains a character. The given
character is placed at the address of it's block, with the
backround and foreground colors.
Note that only the characters '0'..'9' and 'A'..'Z' (uppercase
only) may be placed.

port: the 16 pixel cell constant is replaced by chrheight

***************************************************************}

procedure plcchr(x, y: integer;  { origin }
                 c:    char;     { character to place }
                 f:    color;    { foreground color }
                 b:    color;    { backround color }
                 p:    color;    { perimeter color }
                 l:    boolean;  { place left perimeter flag }
                 r:    boolean); { place right perimeter flag }

var ix, iy: integer; { index }

begin

   { place backround block }
   block(screen, x, y, x+chrheight-1, y+chrheight-1, b);
   for ix := 1 to chrheight do { place top perimeter }
      setpix(screen, x+ix-1, y+1-1, p);
   setchr(screen, x+uiscl(3), y+uiscl(3), c, f); { port: uiscl offsets }
   if l then { left perimeter on }
      for iy := 2 to chrheight-1 do { place left perimeter }
         setpix(screen, x+1-1, y+iy-1, p);
   if r then { right perimeter on }
      for iy := 2 to chrheight-1 do { place left perimeter }
         setpix(screen, x+chrheight-1, y+iy-1, p);
   for ix := 1 to chrheight do { place bottom perimeter }
      setpix(screen, x+ix-1, y+chrheight-1, p)

end;
{}
{**************************************************************

PLACE STRING

Places a short string of characters on the screen. Used to
change multicharacter buttons onscreen.

**************************************************************}

procedure plcstr(x, y: integer;  { address of block }
                 s:    butstr;   { characters to place }
                 l:    btslen;   { port: was btsinx; may be 0 }
                 f:    color;    { foreground color }
                 b:    color;    { backround color }
                 p:    boolean); { perimeter placement flag }

var i: 1..8; { string index }
    w: integer;

begin

   { find total pixel width of string }
   { port: uiscl - margin/spacing/cell height scaled to character cell }
   w := uiscl(7); { set margin }
   for i := 1 to l do w := w + chrwidth(s[i])+uiscl(1);
   if not blank then begin { screen not blank }

      if p then begin { place perimeter }

         { draw button frame }
         block(screen, x, y, x+w-1, y+uiscl(23)-1, dwhite);
         line(screen, x, y, x+w-1, y, white);
         line(screen, x, y+1, x+w-1-1, y+1, white);
         line(screen, x, y, x, y+uiscl(23)-1, white);
         line(screen, x+1, y, x+1, y+uiscl(23)-1-1, white);
         line(screen, x+1, y+uiscl(23)-1, x+w-1, y+uiscl(23)-1, gray);
         line(screen, x+2, y+uiscl(23)-1-1, x+w-1, y+uiscl(23)-1-1, gray);
         line(screen, x+w-1-1, y+2, x+w-1-1, y+uiscl(23)-1, gray);
         line(screen, x+w-1, y+1, x+w-1, y+uiscl(23)-1, gray)

      end else { no perimeter }
         { clear backround }
         block(screen, x, y, x+w-1, y+uiscl(23)-1, b); { clear backround }
      for i := 1 to l do begin { place characters }

         setchr(screen, x+uiscl(6), y+uiscl(6), s[i], f);
         x := x + chrwidth(s[i])+uiscl(1) { next collumn }

      end

   end

end;
{}
{**************************************************************

DRAW FRAME

Draws a button or field frame. The colors define whether the
appearance will be a raised button, depressed button, or
frame.

**************************************************************}

procedure frame(vp: viewport; x1, y1, x2, y2: integer; { rectangle }
                tc1, tc2, bc1, bc2: color);

begin

   { top edge }
   line(screen, x1, y1, x2, y1, tc1);
   line(screen, x1, y1+1, x2-1, y1+1, tc2);
   { left edge }
   line(screen, x1, y1, x1, y2, tc1);
   line(screen, x1+1, y1+1, x1+1, y2-1, tc2);
   { bottom edge }
   line(screen, x1+2, y2-1, x2, y2-1, bc1);
   line(screen, x1+1, y2, x2, y2, bc2);
   { right edge }
   line(screen, x2-1, y1+2, x2-1, y2-1, bc1);
   line(screen, x2, y1+1, x2, y2, bc2)

end;
{}
{**************************************************************

PLACE BUTTON

Draws the given button onscreen.
Places a short string of characters on the screen. Used to
change multicharacter buttons onscreen.

**************************************************************}

procedure plcbut(b: buttyp);

var i:                      1..8; { string index }
    w:                      integer;
    x:                      integer;
    tc1, tc2, bc1, bc2, cc: color; { button part colors }

begin

   if button[b].typ <> cust then with button[b] do begin

      { find total pixel width of string }
      { port: uiscl - margin/spacing/text offsets scaled to character cell }
      w := uiscl(7); { set margin }
      for i := 1 to l do w := w + chrwidth(s[i])+uiscl(1);
      if not blank then begin { screen not blank }

         { draw button frame }
         { backround }
         block(screen, r.s.x+2, r.s.y+2, r.e.x-2, r.e.y-2, curwin^.bc);
         if typ = fld then begin { field button }

            tc1 := curwin^.sc;
            tc2 := curwin^.lc;
            bc1 := curwin^.sc;
            bc2 := curwin^.lc

         end else if act then begin { button active }

            tc1 := curwin^.sc;
            tc2 := curwin^.sc;
            bc1 := curwin^.lc;
            bc2 := curwin^.lc

         end else begin { button inactive }

            tc1 := curwin^.lc;
            tc2 := curwin^.lc;
            bc1 := curwin^.sc;
            bc2 := curwin^.sc

         end;
         frame(screen, r.s.x, r.s.y, r.e.x, r.e.y,
               tc1, tc2, bc1, bc2); { draw frame }
         { set disabled button color }
         if dis then cc := gray else cc := black;
         x := r.s.x+uiscl(6); { set screen index }
         for i := 1 to l do begin { place characters }

            setchr(screen, x, r.s.y+uiscl(6), s[i], cc);
            x := x + chrwidth(s[i])+uiscl(1) { next collumn }

         end

      end

   end

end;
{}
{**************************************************************

DISPLAY BUTTON

Draws the given button onscreen. Also detects cursor on button,
and lifts and drops the cursor as required.

**************************************************************}

procedure updbut(b: buttyp);

var ob: boolean;

begin

   if curscm * button[b].sm <> [] then begin

      { button applies to mode }
      ob := onbutton(b); { get on button status }
      if ob then rescur; { lift cursor if on it }
      { place the characters }
      plcbut(b);
      if ob then setcur { set it back down }

   end

end;
{}
{**************************************************************

PLACE ACTIVE BUTTON

Places a button in the active colors.
Note that the active colors are defined per the button.

**************************************************************}

procedure butact(b: buttyp);

begin

   if not button[b].act then begin

      button[b].act := true; { set status }
      updbut(b) { draw }

   end

end;
{}
{**************************************************************

PLACE INACTIVE BUTTON

Places a button in the inactive colors.

**************************************************************}

procedure butina(b: buttyp);

begin

   if button[b].act then begin

      button[b].act := false; { set status }
      updbut(b) { draw }

   end

end;
{}
{**************************************************************

PLACE UNAVALIBLE BUTTON

Places a button in the unavalible colors.

**************************************************************}

procedure butuna(b: buttyp);

begin

   if not button[b].dis then begin

      button[b].dis := true; { set status }
      updbut(b) { draw }

   end

end;
{}
{**************************************************************

PLACE ALERT BUTTON

Places a button in the alert colors.

**************************************************************}

procedure butalt(b: buttyp);

begin

   if not button[b].alt then begin

      button[b].alt := true; { set status }
      updbut(b) { draw }

   end

end;
{}
{**************************************************************

RESET ALERT BUTTON

Removes the alert status on a button.

**************************************************************}

procedure butdlt(b: buttyp);

begin

   if button[b].alt then begin

      button[b].alt := false; { set status }
      updbut(b) { draw }

   end

end;
{}
{**************************************************************

PLACE MESSAGE

Places the given message in the message box, by the given color.

**************************************************************}

procedure plcmsg(m: msgtyp; { message to display }
                 c: color); { backround color }

var i: msginx; { string index }
    s: msgstr; { message string holder }
    x: byte;   { x screen coordinate }

begin

   rescur; { lift cursor }
   { load message string }
   case m of { message }

      mnone: s := '                                   ';
      minvn: s := '       INVALID NUMBER FORMAT       ';
      movfn: s := '         NUMBER TOO LARGE          ';

   end;
   x := 8; { set 1st message character }
   { place left character }
   plcchr(x*chrheight, 7*chrheight, s[1], black, c, black, true, false);
   x := x + 1;
   for i := 2 to msglen-1 do begin { place characters }

      plcchr(x*chrheight, 7*chrheight, s[i], black, c, black, false, false);
      x := x + 1 { next collumn }

   end;
   { place right character }
   plcchr(x*chrheight, 7*chrheight, s[msglen], black, c, black, false, true);
   errmsg := m <> mnone; { set error onscreen status }
   setcur { drop cursor }

end;
{}
{ UNRESOLVED: angle ratbox }

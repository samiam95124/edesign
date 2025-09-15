module icde;

uses {$U common.j} common;

function getpix(vp: viewport; x, y: integer): color; cexternal; { get pixel value }
procedure stopact; external; { stop current activities }
procedure butact(b: buttyp); external; { set button active }
procedure butina(b: buttyp); external; { set button inactive }
{ place string }
procedure plcstr(x, y: integer; s: butstr; l: btsinx; f: color;
                 b: color; p: boolean); external;
procedure box(x1, y1, x2, y2: integer; c: color); external; { draw box }
procedure updpuck; external; { update cursor pointer }
{ redraw real region }
procedure rregion(x1, y1, x2, y2: integer); external; 
{ draw filled block }
procedure block(vp: viewport; x1, y1, x2, y2: integer; c: color); external;
procedure setcur; external; { draw cursor into place }
procedure rescur; external; { remove cursor }
{ edit button string (primitive) }
procedure edit(var b: butrec; var p: btsinx; c: char; cs: char); 
          external;
{ edit button string }
procedure edtbut(var b: butrec); external;
{ get real number from button string }
procedure getrnm(var b: butrec; var n: real; var e: boolean); 
          external;
{ convert real to string }
procedure realstr(r: real; var s: butstr); external;
{ calculate real distance }
function realdist(d, s: integer): integer; external;
{ clip line segment }
procedure clip(var x1, y1, x2, y2: integer; var inside: boolean;     
               r: region); external;   
procedure resptr; external; { reset puck }
{ find real coordinates }
procedure realc(var p: point; var vp: viewport); external;
{ find rotated point x }
function rotx(sx, sy, ex, ey: integer; ox: integer; x, y: integer; 
              r: rotmod): integer; external;
{ find rotated point y }
function roty(sx, sy, ex, ey: integer; oy: integer; x, y: integer; 
              r: rotmod): integer; external;
{ update button }
procedure updbut(b: buttyp); external;
{ find net mirror product }
function netmir(rt, rm: rotmod): rotmod; external;
{ find cell origin correction for rotation }
procedure corrot(x1, y1, x2, y2: integer; ox, oy: integer;
                 var co: point; lx, ly: integer; rt: rotmod; 
                 cr: rotmod); external;
{ output printer page }
procedure pagprt; external;
{ move printer in y direction }
procedure offy(c: integer); external;
{ start up printer }
procedure strprt; external;
{ output buffer to printer }
procedure outbuf(var prtbuf: prtarr; pmaxx: integer); external; 
{}
{**************************************************************

PRINT SCREEN

Outputs the screen as is to the printer. The screen image
is doubled in X and Y in order to get around dithering
limitations and to create an acceptable size image. This may
have to be rethought later.
We are limited to printing an image that, doubled, will fit
in the printer's X limit.

**************************************************************}

procedure scnprt;

var x, y:   integer; { printer buffer indexes }
    sy:     integer; { screen bit coordinates }
    l:      byte;    { line counter }
    c:      color;   { color holder }

begin   

   strprt; { start printer }
   sy := 0; { set 1st y }
   for l := 1 to (maxy+1) div ((pmax.y+1) div 2) do begin 

      { print lines }
      { load line to buffer }
      for x := 0 to maxx do { traverse X }
         for y := 0 to pmax.y div 2 do begin { traverse Y }

            c := getpix(screen, x, sy+y); { get screen color }
            prtbuf[x*2, y*2] := c; { place upper left }
            prtbuf[x*2+1, y*2] := c; { place upper right }
            prtbuf[x*2, y*2+1] := c; { place lower left }
            prtbuf[x*2+1, y*2+1] := c { place lower right }

      end;
      outbuf(prtbuf, 2*(maxx+1)); { output buffer }
      sy := sy + 12 { next screen position }

   end;
   pagprt { next page }

end;   
{}
{**************************************************************

FIND PRINTER BUFFER COORDINATES

Finds the equvalent buffer coordinates to the given real 
coordinates. The coordinates are not clipped.

**************************************************************}

procedure prtcrd(var x, y: integer);

var t: integer;

begin

   t := (x-curwin^.cs^.bbsx)*scalem;
   x := t div pscl; { find x }
   if (t mod pscl) > pscl div 2 then x := x + 1;
   t := (y-curwin^.cs^.bbsy)*scalem;
   y := t div pscl;  { find y }
   if (t mod pscl) > pscl div 2 then y := y + 1

end;
{}
{**************************************************************

PRINTER SET PIXEL CLIPPED

Sets the value of a given pixel. If the pixel is out of the
active area, no action occurs.
Operates on the printer buffer.

**************************************************************}

procedure psetpixc(x, y: integer; c: color);

begin

   if (x >= 0+poff.x) and (x <= pmax.x+poff.x) and 
      (y >= 0+poff.y) and (y <= pmax.y+poff.y) then { access ok }
      prtbuf[x-poff.x, y-poff.y] := c { set pixel }

end;    
{}
{**************************************************************

PRINTER LINE DRAW CLIPPED

Draws a line between points indicated by coordinate pairs
expressed as screen coordinates, in the given color.
The line is clipped to the print buffer.
Operates on the printer buffer.

***************************************************************}

procedure plinec(x1, y1, x2, y2: integer; c: color);

var d, dx, dy:                  integer;
    aincr, bincr, yincr, xincr: integer;
    x, y:                       integer;

begin
   
   { find differences }
   dx := abs(x1-x2);
   dy := abs(y1-y2);
   if dx > dy then begin { left and right quadrants }

      { force x1 < x2 }
      if x1 > x2 then begin 

         x := x1; x1 := x2; x2 := x;
         y := y1; y1 := y2; y2 := y

      end;
      { determine increment for y}
      if y2 > y1 then yincr := 1 else yincr := -1;
      d := 2 * dy - dx;
      aincr := 2 * (dy - dx);
      bincr := 2 * dy;
      x := x1; { initial x and y }
      y := y1;
      psetpixc(x, y, c); { set pixel at (x1, y1) }
      for x := x1+1 to x2 do begin { do from x1+1 to x2 }

         if d >= 0 then begin

            y := y + yincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         psetpixc(x, y, c)

      end

   end else begin { top and bottom quadrants }

      { force y1 < y2 }
      if y1 > y2 then begin 

         x := x1; x1 := x2; x2 := x;
         y := y1; y1 := y2; y2 := y

      end;
      { determine increment for x }
      if x2 > x1 then xincr := 1 else xincr := -1;
      d := 2 * dx - dy;
      aincr := 2 * (dx - dy);
      bincr := 2 * dx;
      x := x1; { initial x and y }
      y := y1;
      psetpixc(x, y, c); { set pixel at (x1, y1) }
      for y := y1+1 to y2 do begin { do from y1+1 to y2 }

         if d >= 0 then begin

            x := x + xincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         psetpixc(x, y, c)

      end

   end

end;
{}
{**************************************************************

PRINTER LINE DRAW SPECIAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
Operates on the printer buffer.
Special in that clipping is done using intelegent clipping only
for orthogonal lines. This, again, is to prevent "choping" 
effects in the printout.

***************************************************************}

procedure plines(x1, y1, x2, y2: integer; c: color);

var draw: boolean;
    x1s, y1s, x2s, y2s: integer;
    r: region;

begin

   x1s := x1; { copy }
   y1s := y1;
   x2s := x2;
   y2s := y2;
   { clip line }
   r.s.x := 0+poff.x;
   r.s.y := 0+poff.y;
   r.e.x := pmax.x+poff.x;
   r.e.y := pmax.y+poff.y;
   clip(x1s, y1s, x2s, y2s, draw, r);
   if draw then begin { line is within space }

      if (x1s <> x2s) and (y1s <> y2s) then
         { not orthogonal, use original line }
         plinec(x1, y1, x2, y2, c)
      else
         { orthogonal, clipped version use ok }
         plinec(x1s, y1s, x2s, y2s, c)

   end

end;
{}
{**************************************************************

PRINTER LINE DRAW REAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The line is clipped to the viewport.
Operates on the printer buffer.

***************************************************************}

procedure pliner(x1, y1, x2, y2: integer; c: color);

var draw: boolean;
    x1s, y1s, x2s, y2s: integer;

begin

   { find transformed coordinates }
   x1s := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, x1, y1, trnfrm);
   y1s := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, x1, y1, trnfrm);
   x2s := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, x2, y2, trnfrm);
   y2s := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, x2, y2, trnfrm);
   prtcrd(x1s, y1s); { convert coordinates }
   prtcrd(x2s, y2s);
   plines(x1s, y1s, x2s, y2s, c)

end;
{}
{**************************************************************

PRINTER BOLD LINE DRAW REAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
Bold lines are created by drawing three lines, of which the
indicated line is the middle line..
The line is clipped to the viewport.
Note that bold lines MUST be orthogonal.
Operates on the printer buffer.

***************************************************************}

procedure pbliner(x1, y1, x2, y2: integer; c: color);

var draw: boolean;
    x1s, x2s, y1s, y2s: integer; { coordinate saves }

begin

   { find transformed coordinates }
   x1s := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, x1, y1, trnfrm);
   y1s := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, x1, y1, trnfrm);
   x2s := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, x2, y2, trnfrm);
   y2s := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, x2, y2, trnfrm);
   prtcrd(x1s, y1s); { convert coordinates }
   prtcrd(x2s, y2s);
   x1 := x1s; { save original coordinates }
   x2 := x2s;
   y1 := y1s;
   y2 := y2s;
   { draw middle line }
   plines(x1, y1, x2, y2, c);
   x1 := x1s; { restore original coordinates }
   x2 := x2s;
   y1 := y1s;
   y2 := y2s;
   if x1 = x2 then begin { line is vertical }

      x1 := x1 - 1; { move left }
      x2 := x1;
      { draw left line }
      plines(x1, y1, x2, y2, c);
      x1 := x1s; { restore original coordinates }
      x2 := x2s;
      y1 := y1s;
      y2 := y2s;
      x1 := x1 + 1; { move right }
      x2 := x1;
      { draw left line }
      plines(x1, y1, x2, y2, c)

   end else begin

      y1 := y1 - 1; { move up }
      y2 := y1;
      { draw top line }
      plines(x1, y1, x2, y2, c);
      x1 := x1s; { restore original coordinates }
      x2 := x2s;
      y1 := y1s;
      y2 := y2s;
      y1 := y1 + 1; { move down }
      y2 := y1;
      { draw bottom line }
      plines(x1, y1, x2, y2, c)

   end      

end;
{}
{**************************************************************

PRINTER DRAW BOX REAL

Draws the real coordinate box with clipping.
Operates on the printer buffer.

**************************************************************}

procedure pboxr(x1, y1, x2, y2: integer; c: color);

begin

   pliner(x1, y1, x2, y1, c); { top }
   pliner(x1, y2, x2, y2, c); { bottom }
   pliner(x1, y1, x1, y2, c); { left }
   pliner(x2, y1, x2, y2, c) { right }

end;
{}
{**************************************************************

PRINTER DRAW BOLD BOX REAL

Draws the real coordinate box with clipping.
Operates on the printer buffer.

**************************************************************}

procedure pbboxr(x1, y1, x2, y2: integer; c: color);

begin

   pbliner(x1, y1, x2, y1, c); { top }
   pbliner(x1, y2, x2, y2, c); { bottom }
   pbliner(x1, y1, x1, y2, c); { left }
   pbliner(x2, y1, x2, y2, c) { right }

end;
{}
{**************************************************************

DRAW REAL BLOCK

Draws a real block with clipping.

**************************************************************}

procedure pblockr(x1, y1, x2, y2: integer; { ends of box }
                  c:              color);   { color }

var b: region;
    t: integer;
    i: integer;

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
   prtcrd(b.s.x, b.s.y); { convert coordinates }
   prtcrd(b.e.x, b.e.y); 
   { clip to buffer }
   if (b.s.x <= pmax.x+poff.x) and (b.e.x >= 0+poff.x) and
      (b.s.y <= pmax.y+poff.y) and (b.e.y >= 0+poff.y) then begin

      { block overlays buffer at some point }
      { clip to viewport }
      if b.s.x < 0+poff.x then b.s.x := 0+poff.x;
      if b.e.x > pmax.x+poff.x then b.e.x := pmax.x+poff.x;
      if b.s.y < 0+poff.y then b.s.y := 0+poff.y;
      if b.e.y > pmax.y+poff.y then b.e.y := pmax.y+poff.y;
      { draw block }
      for i := b.s.y to b.e.y do plinec(b.s.x, i, b.e.x, i, c)

   end

end;
{}
{**************************************************************

PRINTER ARC DRAW CLIPPED

Draws an arc between the points indicated by the start and end,
with the given center point and radius. 
The figure is clipped.
Operates on the printer buffer.

**************************************************************}

procedure parcc(xs, ys, xe, ye, xc, yc, r: integer; c: color); 

var di, xi, yi: integer;
    qs, qe: 0..3; { quadrants }
    ef, sf: boolean;
    move: array [0..3] of record 

             h, d, v: record

                x, y: integer; { direction to move }
                c:    (lx, ly, gx, gy) { compare type }

             end

          end;

procedure mh; { move horizontal }

begin

   xs := xs + move[qs].h.x;
   ys := ys + move[qs].h.y;
   if not sf then case move[qs].h.c of { compare }

      lx: ef := (xs < xe) and (qs = qe);
      gx: ef := (xs > xe) and (qs = qe);
      ly: ef := (ys < ye) and (qs = qe);
      gy: ef := (ys > ye) and (qs = qe)

   end;
   xi := xi + 1;
   di := di + 2*xi + 1

end;

procedure mv; { move vertical }

begin

   xs := xs + move[qs].v.x;
   ys := ys + move[qs].v.y;
   if not sf then case move[qs].v.c of { compare }

      lx: ef := (xs < xe) and (qs = qe);
      gx: ef := (xs > xe) and (qs = qe);
      ly: ef := (ys < ye) and (qs = qe);
      gy: ef := (ys > ye) and (qs = qe)

   end;
   if yi <> 0 then begin { not at end }

      yi := yi - 1;
      di := di - 2*yi + 1

   end else begin { at end, set up next quadrant }

      qs := (qs + 1) mod 4; { find next quadrant }
      yi := xi; xi := 1; { set up next quad }
      di := sqr(xi+1)+sqr(yi-1)-sqr(r);
      sf := false { turn off startup flag }

   end 

end;

procedure md; { move diagonaly }

begin

   xs := xs + move[qs].d.x;
   ys := ys + move[qs].d.y;
   if not sf then case qs of { compare }

      0: ef := (xs > xe) and (ys < ye) and (qs = qe);
      1: ef := (xs < xe) and (ys < ye) and (qs = qe);
      2: ef := (xs < xe) and (ys > ye) and (qs = qe);
      3: ef := (xs > xe) and (ys > ye) and (qs = qe)

   end;
   xi := xi + 1;
   yi := yi - 1;
   di := di + 2*xi - 2*yi + 2

end;

begin

   { initalize move data }
   move[0].h.x := +1; move[0].h.y :=  0; move[0].h.c := gx;
   move[0].d.x := +1; move[0].d.y := -1;
   move[0].v.x :=  0; move[0].v.y := -1; move[0].v.c := ly;  
   move[1].h.x :=  0; move[1].h.y := -1; move[1].h.c := ly;
   move[1].d.x := -1; move[1].d.y := -1;
   move[1].v.x := -1; move[1].v.y :=  0; move[1].v.c := lx;  
   move[2].h.x := -1; move[2].h.y :=  0; move[2].h.c := lx;
   move[2].d.x := -1; move[2].d.y := +1; 
   move[2].v.x :=  0; move[2].v.y := +1; move[2].v.c := gy;  
   move[3].h.x :=  0; move[3].h.y := +1; move[3].h.c := gy;
   move[3].d.x := +1; move[3].d.y := +1;
   move[3].v.x := +1; move[3].v.y :=  0; move[3].v.c := gx;  
   if (xs <> xc) or (ys <> yc) then begin { not single point }

      { find quadrant of origin }
      if ((xs-xc) >= 0) and ((ys-yc) >= 0) then qs := 0
      else if ((xs-xc) >= 0) and ((ys-yc) < 0) then qs := 1
      else if ((xs-xc) < 0) and ((ys-yc) < 0) then qs := 2
      else qs := 3;
      { find end quadrant }
      if ((xe-xc) >= 0) and ((ye-yc) >= 0) then qe := 0
      else if ((xe-xc) >= 0) and ((ye-yc) < 0) then qe := 1
      else if ((xe-xc) < 0) and ((ye-yc) < 0) then qe := 2
      else qe := 3;
      if (qs = 0) or (qs = 2) then begin

         xi := abs(xs-xc); { set starting point }
         yi := abs(ys-yc)

      end else begin

         yi := abs(xs-xc); { set starting point }
         xi := abs(ys-yc)

      end;
      sf := false; { set no startup flag }
      ef := false; { set end flag }
      if qs = qe then { end and start are in the same quad }
         case qs of { quadrant }

            0: sf := (xs > xe) or (ys < ye);
            1: sf := (xs < xe) or (ys < ye);
            2: sf := (xs < xe) or (ys > ye);
            3: sf := (xs > xe) or (ys > ye)

         end;
      di := sqr(xi+1)+sqr(yi-1)-sqr(r);
      repeat { find circle points }

         psetpixc(xs, ys, c); { set point }
         { find next point on circle }
         if di < 0 then begin { in 1st octant }

            if (2*di + 2*yi - 1) <= 0 then mh { horizontal } 
            else md { diagonal }

         end else if di > 0 then begin { in second octant }

            if (2*di - 2*xi - 1) <= 0 then md { diagonal } 
            else mv { vertical }

         end else md

      until ef { past limit }

   end

end;
{}
{**************************************************************

PRINTER ARC DRAW REAL

Draws an arc between the points indicated by the start and end,
with the given center point and radius. 
The coordinates are real, and the figure is clipped.
Operates on the printer buffer.

**************************************************************}

procedure parcr(xs, ys, xe, ye, xc, yc, r: integer; c: color); 

var xss, yss, xes, yes, xcs, ycs, t: integer;

begin

   { find transformed coordinates }
   xss := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, xs, ys, trnfrm);
   yss := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, xs, ys, trnfrm);
   xes := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, xe, ye, trnfrm);
   yes := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, xe, ye, trnfrm);
   xcs := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, xc, yc, trnfrm);
   ycs := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, xc, yc, trnfrm);
   if trnfrm in [rmm0, rmm90, rmm180, rmm270] then begin

      { mirrored, swap start and end }
      t := xss; xss := xes; xes := t;
      t := yss; yss := yes; yes := t

   end;
   prtcrd(xss, yss); { convert coordinates }
   prtcrd(xes, yes);
   prtcrd(xcs, ycs);
   r := (r*scalem) div pscl; { convert radius }
   { prevent rounding to closed circle }
   if (xss = xes) and (yss = yes) then xes := xes - 1;
   if (xcs+r >= 0+poff.x) and (xcs-r <= pmax.x+poff.x) and
      (ycs+r >= 0+poff.y) and (ycs-r <= pmax.y+poff.y) then
      { within active area }
      parcc(xss, yss, xes, yes, xcs, ycs, r, c) { draw arc }

end;
{}
{**************************************************************

PRINTER PIE DRAW REAL

Draws a filled circle with the given center and radius.
The figure is clipped.
Operates on the printer buffer.

**************************************************************}

procedure ppier(xc, yc, r: integer; c: color); 

var di, xi, yi, sx, sy: integer;
    xcs, ycs: integer;

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

   xcs := rotx(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsx, xc, yc, trnfrm);
   ycs := roty(curwin^.cs^.bbsx, curwin^.cs^.bbsy, 
               curwin^.cs^.bbex, curwin^.cs^.bbey, 
               curwin^.cs^.bbsy, xc, yc, trnfrm);
   prtcrd(xcs, ycs); { convert coordinates }
   r := (r*scalem) div pscl; { convert radius }
   if (xcs+r >= 0+poff.x) and (xcs-r <= pmax.x+poff.x) and
      (ycs+r >= 0+poff.y) and (ycs-r <= pmax.y+poff.y) then begin

      { some part lies within active area }
      xi := 0; { draw quadrant }
      yi := r;
      di := 2*(1-r);
      repeat { find circle points }

         plinec(-xi+xcs, -yi+ycs, xi+xcs, -yi+ycs, c);
         plinec(-xi+xcs, yi+ycs, xi+xcs, yi+ycs, c);
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
{}
{**************************************************************

PRINTER CONNECTOR DRAW REAL

Draws a connector at the given location and size.
Operates on the printer buffer.

**************************************************************}

procedure pconr(x, y, r: integer; c: color); 

begin

   pliner(x-r, y-r, x-r, y+r, c); { draw left side }
   pliner(x+r, y-r, x+r, y+r, c); { right side }
   pliner(x-r, y-r, x+r, y-r, c); { top side }
   pliner(x-r, y+r, x+r, y+r, c); { bottom side }
   pliner(x-r, y, x+r, y, c); { cross }
   pliner(x, y-r, x, y+r, c)

end;
{}
{**************************************************************

PRINTER PLACE VECTOR CHARACTER 

Draws a single character in vector form. The characters were
planned on a 4x8 grid, with upper left as 0,0. They may be
scaled to any given size. 
Obviously, there is a minimum size possible to give reasonable
representation.
Operates on the printer buffer.

**************************************************************}

procedure pvchar(x, y: integer;  { location }
                c:    char;     { character to place }
                s:    integer;  { scale factor }
                cl:   color;    { color }
                r:    boolean); { rotate 90 deg }


var f: integer; { fudge factor }

{ rotate single point x }

function rotx(px, py: integer): integer;

begin

   if r then rotx := chrhdt*s-py*s+x
   else rotx := px*s+x

end;

{ rotate single point y }

function roty(px, py: integer): integer;

begin

   if r then roty := px*s+y 
   else roty := py*s+y

end;

{ draw rotated real line }

procedure plinerr(x1, y1, x2, y2: integer);

begin

   pliner(rotx(x1, y1), roty(x1, y1), rotx(x2, y2), roty(x2, y2), cl)
                
end;

{ draw rotated real arc }

procedure parcrr(sx, sy, ex, ey, cx, cy, r: integer; c: color);

begin

   parcr(rotx(sx, sy), roty(sx, sy), rotx(ex, ey), roty(ex, ey),
        rotx(cx, cy), roty(cx, cy), r*s, c)

end;

begin

   f := realdist(1, pscl); { find single pixel width }
   { check in active area }
   if ((trnfrm in [rm0, rm180, rmm0, rmm180]) and
      (x+chrwdt*s >= curwin^.cs^.bbsx+realdist(0+poff.x, pscl)-f) and 
      (x <= curwin^.cs^.bbsx+realdist(pmax.x+poff.x, pscl)+f) and
      (y+chrhdt*s >= curwin^.cs^.bbsy+realdist(0+poff.y, pscl)-f) and 
      (y <= curwin^.cs^.bbsy+realdist(pmax.y+poff.y, pscl)+f)) or
      ((trnfrm in [rm90, rm270, rmm90, rmm270]) and
      (x+chrwdt*s >= curwin^.cs^.bbsx+realdist(0+poff.y, pscl)-f) and 
      (x <= curwin^.cs^.bbsx+realdist(pmax.y+poff.y, pscl)+f) and
      (y+chrhdt*s >= curwin^.cs^.bbsy+realdist(0+poff.x, pscl)-f) and 
      (y <= curwin^.cs^.bbsy+realdist(pmax.x+poff.x, pscl)+f)) then
      case c of { character }

      '0': begin

              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 7);
              plinerr(0, 8, 4, 0)

           end;

      '1': begin

              plinerr(2, 0, 2, 8);
              plinerr(0, 2, 2, 0);
              plinerr(0, 8, 4, 8)

           end;

      '2': begin

              plinerr(0, 1, 1, 0);
              plinerr(0, 5, 1, 4);
              plinerr(0, 5, 0, 8);
              plinerr(0, 8, 4, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 4, 3, 4);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(4, 1, 4, 3)

           end;

      '3': begin

              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(2, 4, 3, 4);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 3);
              plinerr(4, 5, 4, 7)

           end;

      '4': begin

              plinerr(3, 0, 3, 8);
              plinerr(0, 4, 3, 0);
              plinerr(0, 4, 4, 4);
              plinerr(2, 8, 4, 8)

           end;

      '5': begin

              plinerr(0, 0, 0, 4);
              plinerr(0, 0, 4, 0);
              plinerr(0, 4, 3, 4);
              plinerr(3, 4, 4, 5);
              plinerr(0, 8, 3, 8);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 7)

           end;

      '6': begin

              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 7)

           end;

      '7': begin

              plinerr(0, 0, 4, 0);
              plinerr(0, 8, 4, 0)

           end;

      '8': begin

              plinerr(0, 1, 0, 3);
              plinerr(0, 5, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 3, 1, 4);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 3);
              plinerr(4, 5, 4, 7)

           end;

      '9': begin

              plinerr(0, 1, 0, 3);
              plinerr(0, 1, 1, 0);
              plinerr(0, 3, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 7)

           end;

      'A': begin

              plinerr(0, 1, 0, 8);
              plinerr(4, 1, 4, 8);
              plinerr(1, 0, 3, 0);
              plinerr(0, 4, 4, 4);
              plinerr(0, 1, 1, 0);
              plinerr(3, 0, 4, 1)

           end;

      'B': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 3, 0);
              plinerr(0, 4, 3, 4);
              plinerr(0, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 3);
              plinerr(4, 5, 4, 7)

           end;

      'C': begin

              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 8, 4, 7)

           end;

      'D': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 3, 0);
              plinerr(0, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 7)

           end;

      'E': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 4, 0);
              plinerr(0, 4, 2, 4);
              plinerr(0, 8, 4, 8)

           end;

      'F': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 4, 0);
              plinerr(0, 4, 2, 4)

           end;

      'G': begin
   
              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 8, 4, 7);
              plinerr(2, 4, 4, 4);
              plinerr(4, 4, 4, 7)

           end;

      'H': begin

              plinerr(0, 0, 0, 8);
              plinerr(4, 0, 4, 8);
              plinerr(0, 4, 4, 4)

           end;

      'I': begin

              plinerr(0, 0, 4, 0);
              plinerr(0, 8, 4, 8);
              plinerr(2, 0, 2, 8)

           end;

      'J': begin

              plinerr(0, 6, 0, 7);
              plinerr(0, 7, 1, 8);
              plinerr(1, 8, 3, 8);
              plinerr(3, 8, 4, 7);
              plinerr(4, 0, 4, 7)

           end;

      'K': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 4, 1, 4);
              plinerr(1, 4, 4, 0);
              plinerr(1, 4, 4, 8)

           end;

      'L': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 8, 4, 8)

           end;

      'M': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 2, 4);
              plinerr(2, 4, 4, 0);
              plinerr(4, 0, 4, 8)

           end;

      'N': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 4, 8);
              plinerr(4, 8, 4, 0)

           end;
           
      'O': begin

              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 7)

           end;

      'P': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 3, 0);
              plinerr(0, 4, 3, 4);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(4, 1, 4, 3)

           end;

      'Q': begin

              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 8, 4, 7);
              plinerr(4, 1, 4, 7);
              plinerr(2, 6, 4, 8)

           end;

      'R': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 0, 3, 0);
              plinerr(0, 4, 3, 4);
              plinerr(2, 4, 4, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 3);
              plinerr(4, 1, 4, 3)

           end;

      'S': begin

              plinerr(0, 1, 0, 3);
              plinerr(0, 1, 1, 0);
              plinerr(0, 3, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 3, 0);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 4, 1);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 7)

           end;

      'T': begin

              plinerr(0, 0, 4, 0);
              plinerr(2, 0, 2, 8)

           end;

      'U': begin

              plinerr(0, 0, 0, 7);
              plinerr(0, 7, 1, 8);
              plinerr(1, 8, 3, 8);
              plinerr(3, 8, 4, 7);
              plinerr(4, 0, 4, 7)

           end;

      'V': begin

              plinerr(0, 0, 2, 8);
              plinerr(2, 8, 4, 0)

           end;

      'W': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 8, 2, 4);
              plinerr(2, 4, 4, 8);
              plinerr(4, 0, 4, 8)

           end;

      'X': begin

              plinerr(0, 0, 4, 8);
              plinerr(0, 8, 4, 0)

           end;

      'Y': begin

              plinerr(0, 0, 2, 4);
              plinerr(2, 4, 4, 0);
              plinerr(2, 4, 2, 8)

           end;

      'Z': begin

              plinerr(0, 0, 4, 0);
              plinerr(4, 0, 0, 8);
              plinerr(0, 8, 4, 8)

           end;

      'a': begin

              plinerr(0, 5, 0, 7);
              plinerr(1, 4, 0, 5);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 8)

           end;

      'b': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 4, 3, 4);
              plinerr(0, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 7)

           end;

      'c': begin

              plinerr(0, 5, 0, 7);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7)
             
           end;

      'd': begin

              plinerr(0, 5, 0, 7);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 0, 4, 8)

           end;

      'e': begin

              plinerr(0, 5, 0, 7);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(0, 6, 4, 6);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 6);
              plinerr(1, 8, 3, 8)

           end;

      'f': begin

              plinerr(0, 4, 2, 4);
              plinerr(1, 1, 1, 8);
              plinerr(1, 1, 2, 0);
              plinerr(2, 0, 3, 0);
              plinerr(3, 0, 4, 1)

           end;

      'g': begin

              plinerr(0, 5, 0, 7);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(0, 10, 1, 11);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(1, 11, 3, 11);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(3, 11, 4, 10);
              plinerr(4, 5, 4, 10)

           end;

      'h': begin

              plinerr(0, 0, 0, 8);
              plinerr(0, 5, 1, 4);
              plinerr(1, 4, 3, 4);
              plinerr(3, 4, 4, 5);
              plinerr(4, 5, 4, 8)

           end;

      'i': begin

              plinerr(1, 4, 2, 4);
              plinerr(1, 8, 3, 8);
              plinerr(2, 2, 2, 3);
              plinerr(2, 4, 2, 8)

           end;

      'j': begin

              plinerr(0, 10, 1, 11);
              plinerr(1, 11, 3, 11);
              plinerr(3, 4, 4, 4);
              plinerr(3, 11, 4, 10);
              plinerr(4, 2, 4, 3);
              plinerr(4, 4, 4, 10)

           end;

      'k': begin

              plinerr(1, 0, 1, 8);
              plinerr(1, 6, 4, 4);
              plinerr(1, 6, 4, 8)

           end;

      'l': begin

              plinerr(1, 0, 2, 0);
              plinerr(1, 8, 3, 8);
              plinerr(2, 0, 2, 8)

           end;

      'm': begin

              plinerr(0, 4, 0, 8);
              plinerr(0, 4, 2, 6);
              plinerr(2, 6, 4, 4);
              plinerr(4, 4, 4, 8)

           end;

      'n': begin

              plinerr(0, 4, 0, 8);
              plinerr(0, 5, 1, 4);
              plinerr(1, 4, 3, 4);
              plinerr(3, 4, 4, 5);
              plinerr(4, 5, 4, 8)

           end;

      'o': begin

              plinerr(0, 5, 0, 7);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 7)

           end;

      'p': begin

              plinerr(0, 4, 0, 11);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 7)

           end;

      'q': begin

              plinerr(0, 5, 0, 7);
              plinerr(0, 5, 1, 4);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 8, 4, 7);
              plinerr(4, 5, 4, 11)

           end;

      'r': begin

              plinerr(0, 4, 0, 8);
              plinerr(0, 5, 1, 4);
              plinerr(1, 4, 3, 4);
              plinerr(3, 4, 4, 5)

           end;

      's': begin

              plinerr(0, 5, 1, 4);
              plinerr(0, 5, 1, 6);
              plinerr(0, 7, 1, 8);
              plinerr(1, 4, 3, 4);
              plinerr(1, 6, 3, 6);
              plinerr(1, 8, 3, 8);
              plinerr(3, 4, 4, 5);
              plinerr(3, 6, 4, 7);
              plinerr(3, 8, 4, 7)

           end;

      't': begin

              plinerr(0, 2, 4, 2);
              plinerr(2, 0, 2, 8);
              plinerr(2, 8, 3, 8)

           end;

      'u': begin

              plinerr(0, 4, 0, 7);
              plinerr(0, 7, 1, 8);
              plinerr(1, 8, 3, 8);
              plinerr(3, 8, 4, 7);
              plinerr(4, 4, 4, 8)

           end;

      'v': begin

              plinerr(0, 4, 2, 8);
              plinerr(2, 8, 4, 4)

           end;

      'w': begin

              plinerr(0, 4, 0, 8);
              plinerr(0, 8, 2, 6);
              plinerr(2, 6, 4, 8);
              plinerr(4, 4, 4, 8)

           end;

      'x': begin

              plinerr(0, 4, 4, 8);
              plinerr(0, 8, 4, 4)

           end;

      'y': begin

              plinerr(0, 4, 0, 7);
              plinerr(0, 7, 1, 8);
              plinerr(1, 8, 3, 8);
              plinerr(3, 8, 4, 7);
              plinerr(0, 10, 1, 11);
              plinerr(1, 11, 3, 11);
              plinerr(3, 11, 4, 10);
              plinerr(4, 4, 4, 10)

           end;

      'z': begin

              plinerr(0, 4, 4, 4);
              plinerr(0, 8, 4, 4);
              plinerr(0, 8, 4, 8)

           end;

      '!': begin

              plinerr(2, 0, 2, 5);
              plinerr(2, 7, 2, 8)

           end;

      '@': begin

              plinerr(0, 1, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 7, 1, 8);
              plinerr(1, 2, 1, 6);
              plinerr(1, 0, 3, 0);
              plinerr(1, 2, 3, 2);
              plinerr(1, 6, 4, 6);
              plinerr(1, 8, 4, 8);
              plinerr(3, 2, 3, 6);
              plinerr(3, 0, 4, 1);
              plinerr(4, 1, 4, 6)

           end;

      '#': begin

              plinerr(1, 0, 1, 8);
              plinerr(3, 0, 3, 8);
              plinerr(0, 3, 4, 3);
              plinerr(0, 5, 4, 5)

           end;

      '$': begin

              plinerr(0, 2, 0, 3);
              plinerr(0, 2, 1, 1);
              plinerr(0, 3, 1, 4);
              plinerr(0, 6, 1, 7);
              plinerr(1, 1, 3, 1);
              plinerr(1, 4, 3, 4);
              plinerr(1, 7, 3, 7);
              plinerr(2, 0, 2, 8);
              plinerr(3, 1, 4, 2);
              plinerr(3, 4, 4, 5);
              plinerr(3, 7, 4, 6);
              plinerr(4, 5, 4, 6)

           end;

      '%': begin

              plinerr(0, 1, 0, 2);
              plinerr(0, 1, 1, 1);
              plinerr(0, 2, 1, 2);
              plinerr(1, 1, 1, 2);
              plinerr(0, 8, 4, 0);
              plinerr(3, 6, 3, 7);
              plinerr(3, 6, 4, 6);
              plinerr(3, 7, 4, 7);
              plinerr(4, 6, 4, 7)

           end;

      '^': begin

              plinerr(0, 2, 2, 0);
              plinerr(2, 0, 4, 2)

           end;

      '&': begin

              plinerr(0, 1, 0, 3);
              plinerr(0, 5, 0, 7);
              plinerr(0, 1, 1, 0);
              plinerr(0, 3, 4, 8);
              plinerr(0, 5, 3, 3);
              plinerr(0, 7, 1, 8);
              plinerr(1, 0, 2, 0);
              plinerr(1, 8, 3, 8);
              plinerr(2, 0, 3, 1);
              plinerr(3, 1, 3, 3);
              plinerr(3, 8, 4, 7);
              plinerr(4, 6, 4, 7)

           end;

      '*': begin

              plinerr(2, 0, 2, 8);
              plinerr(0, 4, 4, 4);
              plinerr(0, 1, 4, 7);
              plinerr(0, 7, 4, 1)

           end;

      '(': begin

              plinerr(3, 0, 2, 1);
              plinerr(2, 1, 1, 3);
              plinerr(1, 3, 1, 5);
              plinerr(1, 5, 2, 7);
              plinerr(2, 7, 3, 8)

           end;

      ')': begin

              plinerr(1, 0, 2, 1);
              plinerr(2, 1, 3, 3);
              plinerr(3, 3, 3, 5);
              plinerr(3, 5, 2, 7);
              plinerr(2, 7, 1, 8)

           end;

      '-': begin

              plinerr(0, 4, 4, 4)

           end;

      '_': begin

              plinerr(0, 8, 4, 8)

           end;

      '+': begin

              plinerr(0, 4, 4, 4);
              plinerr(2, 2, 2, 6)

           end;

      '=': begin

              plinerr(0, 3, 4, 3);
              plinerr(0, 5, 4, 5)

           end;

      '\\': begin

              plinerr(0, 0, 4, 8)

           end;

      '/': begin

              plinerr(0, 8, 4, 0)

           end;

      '|': begin

              plinerr(2, 0, 2, 3);
              plinerr(2, 5, 2, 8)

           end;

      '[': begin

              plinerr(1, 0, 1, 8);
              plinerr(1, 0, 2, 0);
              plinerr(1, 8, 2, 8)

           end;

      ']': begin

              plinerr(1, 0, 3, 0);
              plinerr(1, 8, 3, 8);
              plinerr(3, 0, 3, 8)

           end;

      '{': begin

              plinerr(0, 4, 1, 4);
              plinerr(1, 4, 2, 3);
              plinerr(1, 4, 2, 5);
              plinerr(2, 1, 2, 3);
              plinerr(2, 5, 2, 7);
              plinerr(2, 1, 3, 0);
              plinerr(2, 7, 3, 8);
              plinerr(3, 0, 4, 0);
              plinerr(3, 8, 4, 8)

           end;

      '}': begin

              plinerr(0, 0, 1, 0);
              plinerr(0, 8, 1, 8);
              plinerr(1, 0, 2, 1);
              plinerr(1, 8, 2, 7);
              plinerr(2, 1, 2, 3);
              plinerr(2, 5, 2, 7);
              plinerr(2, 3, 3, 4);
              plinerr(2, 5, 3, 4);
              plinerr(3, 4, 4, 4)

           end;

      ':': begin

              plinerr(2, 4, 2, 5);
              plinerr(2, 7, 2, 8)

           end;

      ';': begin

              plinerr(2, 4, 2, 5);
              plinerr(2, 7, 2, 8);
              plinerr(1, 9, 2, 8)

           end;

      '"': begin

              plinerr(1, 0, 1, 1);
              plinerr(3, 0, 3, 1)

           end;

      '''': begin

              plinerr(1, 1, 2, 0)

           end;

      ',': begin

              plinerr(2, 7, 2, 8);
              plinerr(1, 9, 2, 8)

           end;

      '.': begin

              plinerr(2, 7, 2, 8)

           end;

      '<': begin

              plinerr(1, 4, 3, 0);
              plinerr(1, 4, 3, 8)

           end;

      '>': begin

              plinerr(1, 0, 3, 4);
              plinerr(1, 8, 3, 4)

           end;

      '?': begin

              plinerr(0, 1, 0, 2);
              plinerr(0, 1, 1, 0);
              plinerr(1, 0, 3, 0);
              plinerr(3, 0, 4, 1);
              plinerr(4, 1, 4, 3);
              plinerr(4, 3, 3, 4);
              plinerr(3, 4, 2, 4);
              plinerr(2, 4, 2, 5);
              plinerr(2, 7, 2, 8)

           end;

      '`': begin

              plinerr(2, 0, 3, 1)

           end;

      '~': begin

              plinerr(0, 2, 1, 0);
              plinerr(1, 0, 3, 2);
              plinerr(3, 2, 4, 0)

           end

   end

end;
{}
{**************************************************************

PRINTER DRAW ROTATED LINE

Draws a rotated line for predefined figures.
Operates on the printer buffer.

**************************************************************}

{ draw rotated real line }

procedure plinerr(x1, y1, x2, y2: integer; { line coordinates }
                  ox, oy:         integer; { origin }
                  sx, sy:         integer; { size }
                  s:              integer; { scale }
                  c:              color;   { color }
                  r:              rotmod); { rotation mode }

begin

   pliner(rotx(ox, oy, sx*s+ox, sy*s+oy, ox, x1*s+ox, y1*s+oy, r), 
          roty(ox, oy, sx*s+ox, sy*s+oy, oy, x1*s+ox, y1*s+oy, r), 
          rotx(ox, oy, sx*s+ox, sy*s+oy, ox, x2*s+ox, y2*s+oy, r), 
          roty(ox, oy, sx*s+ox, sy*s+oy, oy, x2*s+ox, y2*s+oy, r), c)
                
end;
{}
{**************************************************************

PRINTER DRAW NMOS TRANSISTOR

Draws a NMOS transistor at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwnmos(ox, oy: integer; { origin }
                   s:      integer; { scale }
                   c:      color;   { color }
                   r:      rotmod); { rotation mode }

begin

   plinerr(0, 4, 2, 4, ox, oy, 7, 8, s, c, r);
   plinerr(2, 2, 2, 6, ox, oy, 7, 8, s, c, r);
   plinerr(3, 2, 3, 6, ox, oy, 7, 8, s, c, r);
   plinerr(3, 2, 5, 2, ox, oy, 7, 8, s, c, r);
   plinerr(3, 6, 5, 6, ox, oy, 7, 8, s, c, r);
   plinerr(5, 0, 5, 2, ox, oy, 7, 8, s, c, r);
   plinerr(5, 6, 5, 8, ox, oy, 7, 8, s, c, r);
   plinerr(3, 4, 4, 3, ox, oy, 7, 8, s, c, r);
   plinerr(3, 4, 4, 5, ox, oy, 7, 8, s, c, r);
   plinerr(4, 3, 4, 5, ox, oy, 7, 8, s, c, r);
   plinerr(3, 4, 7, 4, ox, oy, 7, 8, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW PMOS TRANSISTOR

Draws a PMOS transistor at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwpmos(ox, oy: integer;   { origin }
                   s:      integer; { scale }
                   c:      color;   { color }
                   r:      rotmod); { rotation mode }

begin

   plinerr(0, 4, 2, 4, ox, oy, 7, 8, s, c, r);
   plinerr(2, 2, 2, 6, ox, oy, 7, 8, s, c, r);
   plinerr(3, 2, 3, 6, ox, oy, 7, 8, s, c, r);
   plinerr(3, 2, 5, 2, ox, oy, 7, 8, s, c, r);
   plinerr(3, 6, 5, 6, ox, oy, 7, 8, s, c, r);
   plinerr(5, 0, 5, 2, ox, oy, 7, 8, s, c, r);
   plinerr(5, 6, 5, 8, ox, oy, 7, 8, s, c, r);
   plinerr(5, 4, 4, 3, ox, oy, 7, 8, s, c, r);
   plinerr(5, 4, 4, 5, ox, oy, 7, 8, s, c, r);
   plinerr(4, 3, 4, 5, ox, oy, 7, 8, s, c, r);
   plinerr(3, 4, 7, 4, ox, oy, 7, 8, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW CAPACITOR

Draws a capacitor at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwcap(ox, oy: integer; { origin }
                  s:      integer; { scale }
                  c:      color;   { color }
                  r:      rotmod); { rotation mode }

begin

   plinerr(2, 0, 2, 2, ox, oy, 4, 5, s, c, r);
   plinerr(2, 3, 2, 5, ox, oy, 4, 5, s, c, r);
   plinerr(0, 2, 4, 2, ox, oy, 4, 5, s, c, r);
   plinerr(0, 3, 4, 3, ox, oy, 4, 5, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW DIODE

Draws a diode at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwdiode(ox, oy: integer; { origin }
                   s:      integer; { scale }
                   c:      color;   { color }
                   r:      rotmod); { rotation mode }

begin

   plinerr(2, 0, 2, 2, ox, oy, 4, 8, s, c, r);
   plinerr(0, 2, 4, 2, ox, oy, 4, 8, s, c, r);
   plinerr(2, 2, 0, 6, ox, oy, 4, 8, s, c, r);
   plinerr(2, 2, 4, 6, ox, oy, 4, 8, s, c, r);
   plinerr(0, 6, 4, 6, ox, oy, 4, 8, s, c, r);
   plinerr(2, 6, 2, 8, ox, oy, 4, 8, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW VDD

Draws a VDD connector at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwvdd(ox, oy: integer; { origin }
                 s:      integer; { scale }
                 c:      color;   { color }
                 r:      rotmod); { rotation mode }

begin

   plinerr(1, 0, 0, 2, ox, oy, 2, 4, s, c, r);
   plinerr(1, 0, 2, 2, ox, oy, 2, 4, s, c, r);
   plinerr(0, 2, 2, 2, ox, oy, 2, 4, s, c, r);
   plinerr(1, 2, 1, 4, ox, oy, 2, 4, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW VSS

Draws a VSS connector at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwvss(ox, oy: integer; { origin }
                 s:      integer; { scale }
                 c:      color;   { color }
                 r:      rotmod); { rotation mode }

begin

   plinerr(1, 0, 1, 2, ox, oy, 2, 4, s, c, r);
   plinerr(0, 2, 2, 2, ox, oy, 2, 4, s, c, r);
   plinerr(0, 2, 1, 4, ox, oy, 2, 4, s, c, r);
   plinerr(2, 2, 1, 4, ox, oy, 2, 4, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW RESISTOR

Draws a resistor at the given origin, scale and color,
and rotation.
Operates on the printer buffer.

**************************************************************}

procedure pdrwres(ox, oy: integer; { origin }
                  s:      integer; { scale }
                  c:      color;   { color }
                  r:      rotmod); { rotation mode }

begin

   plinerr(2, 0,  2, 4,  ox, oy, 4, 20, s, c, r);
   plinerr(2, 4,  0, 5,  ox, oy, 4, 20, s, c, r);
   plinerr(0, 5,  4, 7,  ox, oy, 4, 20, s, c, r);
   plinerr(4, 7,  0, 9,  ox, oy, 4, 20, s, c, r);
   plinerr(0, 9,  4, 11, ox, oy, 4, 20, s, c, r);
   plinerr(4, 11, 0, 13, ox, oy, 4, 20, s, c, r);
   plinerr(0, 13, 4, 15, ox, oy, 4, 20, s, c, r);
   plinerr(4, 15, 2, 16, ox, oy, 4, 20, s, c, r);
   plinerr(2, 16, 2, 20, ox, oy, 4, 20, s, c, r)

end;
{}
{**************************************************************

PRINTER DRAW CELL FIGURE

Draws the given figure with bounding per the cell and origin.
Operates on the printer buffer.

**************************************************************}

{ this is declared ahead }

procedure pdrwcell(p:      shtptr; 
                   ct:     celtyp; 
                   ox, oy: integer; 
                   r:      rotmod; 
                   ln:     laytyp); 
                   forward;

procedure pdrwfigc(d:      drwptr;  { figure to draw }
                   p:      shtptr;  { cell sheet }
                   ct:     celtyp;  { cell type }
                   ox, oy: integer; { cell origin }
                   rt:     rotmod;  { cell rotation }
                   ln:     laytyp); { draw layer }

var x1, y1, x2, y2: integer;
    x, y, xa:       integer;
    cp:             chrptr;
    tr:             boolean;
    rc:             rotmod;
    ra, rb:         0..7;
    co:             point; { cell origin }
    te, be:         boolean; { layer flags }

begin

   if ct = ctsch then begin { set bounds schematic }

      x1 := p^.bbsx;
      y1 := p^.bbsy;
      x2 := p^.bbex;
      y2 := p^.bbey

   end else begin { symbol }

      x1 := p^.sbbsx;
      y1 := p^.sbbsy;
      x2 := p^.sbbex;
      y2 := p^.sbbey

   end;
   with d^ do case typ of { figure }

      { line }
      tline: pliner(rotx(x1, y1, x2, y2, ox, l.s.x, l.s.y, rt), 
                    roty(x1, y1, x2, y2, oy, l.s.x, l.s.y, rt),
                    rotx(x1, y1, x2, y2, ox, l.e.x, l.e.y, rt), 
                    roty(x1, y1, x2, y2, oy, l.e.x, l.e.y, rt), cl);
      { wire }
      twire: pliner(rotx(x1, y1, x2, y2, ox, w.s.x, w.s.y, rt), 
                    roty(x1, y1, x2, y2, oy, w.s.x, w.s.y, rt),
                    rotx(x1, y1, x2, y2, ox, w.e.x, w.e.y, rt), 
                    roty(x1, y1, x2, y2, oy, w.e.x, w.e.y, rt), cl);
      { bold line }
      tbline: pbliner(rotx(x1, y1, x2, y2, ox, l.s.x, l.s.y, rt), 
                      roty(x1, y1, x2, y2, oy, l.s.x, l.s.y, rt),
                      rotx(x1, y1, x2, y2, ox, l.e.x, l.e.y, rt), 
                      roty(x1, y1, x2, y2, oy, l.e.x, l.e.y, rt), cl);
      { bus }
      tbus: pbliner(rotx(x1, y1, x2, y2, ox, bs.l.s.x, bs.l.s.y, rt), 
                    roty(x1, y1, x2, y2, oy, bs.l.s.x, bs.l.s.y, rt),
                    rotx(x1, y1, x2, y2, ox, bs.l.e.x, bs.l.e.y, rt), 
                    roty(x1, y1, x2, y2, oy, bs.l.e.x, bs.l.e.y, rt), cl);
      { box }
      tbox: pboxr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                  roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                  rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                  roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), cl);
      { bold box }
      tbbox: pbboxr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                    roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                    rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                    roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), cl);
      { arc or circle }
      tarc: with a do if rt in [rm0, rm90, rm180, rm270] then { normal }
                 parcr(rotx(x1, y1, x2, y2, ox, s.x, s.y, rt), 
                       roty(x1, y1, x2, y2, oy, s.x, s.y, rt),
                       rotx(x1, y1, x2, y2, ox, e.x, e.y, rt), 
                       roty(x1, y1, x2, y2, oy, e.x, e.y, rt),
                       rotx(x1, y1, x2, y2, ox, c.x, c.y, rt), 
                       roty(x1, y1, x2, y2, oy, c.x, c.y, rt), r, cl)
            else { mirrored, swap end and start }   
                 parcr(rotx(x1, y1, x2, y2, ox, e.x, e.y, rt), 
                       roty(x1, y1, x2, y2, oy, e.x, e.y, rt),
                       rotx(x1, y1, x2, y2, ox, s.x, s.y, rt), 
                       roty(x1, y1, x2, y2, oy, s.x, s.y, rt),
                       rotx(x1, y1, x2, y2, ox, c.x, c.y, rt), 
                       roty(x1, y1, x2, y2, oy, c.x, c.y, rt), r, cl);
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
               pvchar(x, y, cp^.c, c.s, cl, tr); 
            { move intercharacter gap }
            if tr then { rotated text }
               y := y+chrwdt*c.s+chrspc*c.s
            else { normal text }
               x := x+chrwdt*c.s+chrspc*c.s;
            cp := cp^.next { next character }

         end

      end;
      { wire junction }
      tjunction: ppier(rotx(x1, y1, x2, y2, ox, j.x, j.y, rt), 
                       roty(x1, y1, x2, y2, oy, j.x, j.y, rt),
                       curwin^.cs^.js, cl);
      { connector (appears in schematic cells only ) }
      tconnect: if ct = ctsch then { schematic }
         pconr(rotx(x1, y1, x2, y2, ox, j.x, j.y, rt), 
               roty(x1, y1, x2, y2, oy, j.x, j.y, rt), curwin^.cs^.cs, cl);
      { subcell }
      tcell: begin

         co := cr.o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, abs(cr.cp^.bbex-cr.cp^.bbsx)+1, 
                abs(cr.cp^.bbey-cr.cp^.bbsy)+1, rt, rm);
         { draw with net rotation }
         pdrwcell(cr.cp, cr.ct, co.x, co.y, netmir(rt, rm), ln)

      end;

      { nmos transistor }
      tnmos: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 7*1500, 8*1500, rt, rm);
         { draw with net rotation }
         pdrwnmos(co.x, co.y, 1500, cl, netmir(rt, rm))

      end;

      { pmos transistor }
      tpmos: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 7*1500, 8*1500, rt, rm);
         { draw with net rotation }
         pdrwpmos(co.x, co.y, 1500, cl, netmir(rt, rm))

      end;

      { capacitor }
      tcap: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 4*1500, 5*1500, rt, rm);
         { draw with net rotation }
         pdrwcap(co.x, co.y, 1500, cl, netmir(rt, rm))

      end;

      { diode }
      tdiode: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 4*1500, 8*1500, rt, rm);
         { draw with net rotation }
         pdrwdiode(co.x, co.y, 1500, cl, netmir(rt, rm))

      end;

      { vdd connector }
      tvdd: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 2*1500, 4*1500, rt, rm);
         { draw with net rotation }
         pdrwvdd(co.x, co.y, 1500, cl, netmir(rt, rm))

      end;

      { vss connector }
      tvss: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 2*1500, 4*1500, rt, rm);
         { draw with net rotation }
         pdrwvss(co.x, co.y, 1500, cl, netmir(rt, rm))

      end;

      { resistor }
      tres: begin

         co := o; { find net origin }
         corrot(x1, y1, x2, y2, ox, oy, co, 4*750, 20*750, rt, rm);
         { draw with net rotation }
         pdrwres(co.x, co.y, 750, cl, netmir(rt, rm))

      end;

      { layers }
      tmet1: if button[bmet1vis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tmet2: if button[bmet2vis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tpoly: if button[bpolyvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tvia:  if button[bviavis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tcont: if button[bcontvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tndiff: if button[bndiffvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tpdiff: if button[bpdiffvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tnwell: if button[bnwellvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tpwell: if button[bpwellvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);
      tinter: begin { intersection }

         case itt of { top layer }
    
            { find layer statuses }
            tmet1:  te := button[bmet1vis].act;
            tmet2:  te := button[bmet2vis].act;
            tpoly:  te := button[bpolyvis].act;
            tndiff: te := button[bndiffvis].act;
            tpdiff: te := button[bpdiffvis].act;
            tcont:  te := button[bcontvis].act

         end;
         case itb of { buttom layer }
    
            { find layer statuses }
            tmet1:  be := button[bmet1vis].act;
            tmet2:  be := button[bmet2vis].act;
            tpoly:  be := button[bpolyvis].act;
            tndiff: be := button[bndiffvis].act;
            tpdiff: be := button[bpdiffvis].act;
            tcont:  be := button[bcontvis].act

         end;
         if te and be then { both layers enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, ir.s.x, ir.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, ir.s.x, ir.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, ir.e.x, ir.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, ir.e.x, ir.e.y, rt), 
                 cl);

      end;   

      { contact cut }
      tccut: if button[bccutvis].act then { layer enabled }
         pblockr(rotx(x1, y1, x2, y2, ox, b.s.x, b.s.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.s.x, b.s.y, rt),
                 rotx(x1, y1, x2, y2, ox, b.e.x, b.e.y, rt), 
                 roty(x1, y1, x2, y2, oy, b.e.x, b.e.y, rt), 
                 cl);

   end

end;
{}
{**************************************************************

PRINTER DRAW SUBCELL

Draws a given subsheet, with border adjustment.
Operates on the printer buffer.

**************************************************************}

procedure pdrwcell;
                  { (p:      shtptr; 
                     ct:     celtyp; 
                     ox, oy: integer; 
                     r:      rotmod; 
                     ln:     laytyp); forward; }

var d: drwptr;

begin

   { do requested layer }
   d := p^.dl[ln]; { index top of draw list }
   while d <> nil do begin { draw from list }

      pdrwfigc(d, p, ct, ox, oy, r, ln); { draw }
      d := d^.next { next entry }

   end;
   { do subcells }
   d := p^.dl[ltcell]; { index top of draw list }
   while d <> nil do begin { draw from list }

      pdrwfigc(d, p, ct, ox, oy, r, ln); { draw }
      d := d^.next { next entry }

   end

end;
{}
{**************************************************************

PRINTER DRAW FIGURE

Draws the given figure in the given color.
Operates on the printer buffer.

**************************************************************}

procedure pdrwfig(p: drwptr; ln: laytyp);

var x, y:   integer;
    cp:     chrptr;
    te, be: boolean; { layer flags }

begin

   with p^ do case typ of { figure }

      { line }
      tline: pliner(l.s.x, l.s.y, l.e.x, l.e.y, cl); 

      { line }
      twire: pliner(w.s.x, w.s.y, w.e.x, w.e.y, cl); 

      { bold line }
      tbline: pbliner(l.s.x, l.s.y, l.e.x, l.e.y, cl); 

      { bus }
      tbus: pbliner(bs.l.s.x, bs.l.s.y, bs.l.e.x, bs.l.e.y, cl); 

      { box }
      tbox: pboxr(b.s.x, b.s.y, b.e.x, b.e.y, cl);

      { bold box }
      tbbox: pbboxr(b.s.x, b.s.y, b.e.x, b.e.y, cl);

      { arc or circle }
      tarc: parcr(a.s.x, a.s.y, a.e.x, a.e.y, 
                  a.c.x, a.c.y, a.r, cl);

      { vector character }
      tchar: begin 

         x := c.r.s.x; { set starting coordinates }
         y := c.r.s.y;
         cp := c.l; { index 1st character }
         while cp <> nil do begin { draw characters }

            if cp^.c <> ' ' then { not space }
               pvchar(x, y, cp^.c, c.s, cl, rm = rm90); 
            { move intercharacter gap }
            if rm = rm90 then { rotated text }
               y := y+chrwdt*c.s+chrspc*c.s
            else { normal text }
               x := x+chrwdt*c.s+chrspc*c.s;
            cp := cp^.next { next character }

         end

      end;

      { wire junction }
      tjunction: ppier(j.x, j.y, curwin^.cs^.js, cl);

      { connector }
      tconnect: pconr(j.x, j.y, curwin^.cs^.cs, cl);

      { subcell }
      tcell: pdrwcell(cr.cp, cr.ct, cr.o.x, cr.o.y, rm, ln);

      { nmos transistor }
      tnmos: pdrwnmos(o.x, o.y, 1500, cl, rm);

      { pmos transistor }
      tpmos: pdrwpmos(o.x, o.y, 1500, cl, rm);

      { capacitor }
      tcap: pdrwcap(o.x, o.y, 1500, cl, rm);

      { diode }
      tdiode: pdrwdiode(o.x, o.y, 1500, cl, rm);

      { vdd connector }
      tvdd: pdrwvdd(o.x, o.y, 1500, cl, rm);

      { vss connector }
      tvss: pdrwvss(o.x, o.y, 1500, cl, rm);

      { resistor }
      tres: pdrwres(o.x, o.y, 750, cl, rm);

      { layers }
      tmet1: if button[bmet1vis].act then { layer enabled }
                pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tmet2: if button[bmet2vis].act then { layer enabled }
                pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tpoly: if button[bpolyvis].act then { layer enabled }
                pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tvia:  if button[bviavis].act then { layer enabled }
                pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tcont:  if button[bcontvis].act then { layer enabled }
                pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tndiff: if button[bndiffvis].act then { layer enabled }
                 pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tpdiff: if button[bpdiffvis].act then { layer enabled }
                 pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tnwell: if button[bnwellvis].act then { layer enabled }
                 pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tpwell: if button[bpwellvis].act then { layer enabled }
                 pblockr(b.s.x, b.s.y, b.e.x, b.e.y, cl);
      tinter: begin { intersection }

         case itt of { top layer }
    
            { find layer statuses }
            tmet1:  te := button[bmet1vis].act;
            tmet2:  te := button[bmet2vis].act;
            tpoly:  te := button[bpolyvis].act;
            tndiff: te := button[bndiffvis].act;
            tpdiff: te := button[bpdiffvis].act;
            tcont:  te := button[bcontvis].act

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
            tcont:  be := button[bcontvis].act

         end;
         if (ipb^.typ = tcell) and not button[binsides].act then
            be := false; { in cell, and insides off }
         if te and be then { both layers enabled }
            pblockr(ir.s.x, ir.s.y, ir.e.x, ir.e.y, cl)

      end;   

      { contact cut }
      tccut: if button[bccutvis].act then { layer enabled }
                pboxr(b.s.x, b.s.y, b.e.x, b.e.y, cl);

   end

end;
{}
{**************************************************************

PRINTER DRAW FIGURES

Draws the entire figures list.
Operates on the printer buffer.

**************************************************************}

procedure pdrwfigs;

var ln: laytyp; { layer index }

{ draw single list }

procedure drwlist(p: drwptr);

begin

   while p <> nil do begin { draw from list }

      pdrwfig(p, ln); { draw }
      p := p^.next { next entry }

   end

end;

begin

   { draw layers }
   for ln := ltwell downto ltfig do begin

      drwlist(curwin^.cs^.dl[ln]); { draw standard }
      drwlist(curwin^.cs^.dl[ltcell]) { draw cells }

   end

end;
{}
{**************************************************************

PRINT CURRENT SHEET

Prints the currently selected sheet.

**************************************************************}

procedure prtsht;

var x, y:       integer;
    bc:         integer; { buffers printed count }
    bufno:      integer; { total number of buffers in y }
    bufspn:     integer; { buffer y span length in real }
    t:          integer;
    lenx, leny: integer; { lengths of plot }
    poffx:      integer; { offset x (in printer dots) }
    pwidx:      integer; { net width of x (in printer dots) }
    pwidxr:     integer; { net width of x (in virtual pixels) }

begin

   { bounds have been set, and plot is 2d }
   if (curwin^.cs^.bbsx <> curwin^.cs^.bbex) and
      (curwin^.cs^.bbsy <> curwin^.cs^.bbey) then begin { bounds set }

      stopact; { stop all modes }
      butact(bprint); { set print mode active }
      strprt; { start up printer }
      { find total points x (y does not change) }
      pmax.x := round(ptrmax.x*ptrdpm)-1; 
      { find number of points to offset }
      poffx := round(ptroff.x*ptrdpm);
      { find width of resulting plot }
      pwidx := pmax.x+1-poffx;

      { determine scale and origin of inital buffer }
      if trnfrm in [rm0, rm180, rmm0, rmm180] then begin { normal }

         lenx := abs(curwin^.cs^.bbex-curwin^.cs^.bbsx);
         leny := abs(curwin^.cs^.bbey-curwin^.cs^.bbsy)

      end else begin { sideways }

         lenx := abs(curwin^.cs^.bbey-curwin^.cs^.bbsy);
         leny := abs(curwin^.cs^.bbex-curwin^.cs^.bbsx)

      end;
      pscl := round((lenx/(pwidx-1))*scalem);
      { find buffer y span }
      bufspn := realdist(pmax.y+1, pscl);
      { determine number of buffers in y }
      bufno := leny div bufspn;  
      { round up }
      if (leny mod bufspn) <> 0 then
         bufno := bufno + 1;  
      { add a buffer for slop }
      bufno := bufno + 1;
      { find real offset in x }
      poff.x := -poffx;
      poff.y := 0; { clear frame offset }
      offy(round(ptroff.y*ptrdpm)); { offset in y }
      for bc := 1 to bufno do begin { print buffers }

         for y := 0 to pmax.y do { clear buffer }
            for x := 0 to pmax.x do prtbuf[x, y] := white;
         pdrwfigs; { load current slice to buffer }
         outbuf(prtbuf, pmax.x); { sent buffer to printer }
         poff.y := poff.y + pmax.y + 1 { advance buffer position }

      end;
      pagprt; { next page }
      butina(bprint) { deactivate print button }

   end
      
end;      
{}
{**************************************************************

UPDATE "SYMPATHETIC" BUTTONS IN PRINTER POPUP.

Updates all the buttons that rely on other buttons in the
printer pop-menu. This makes sure that all values are 
correct when one is changed (something like a spreadsheet).

**************************************************************}

procedure update;

var bs: butstr; { temp string }

begin

   { print x, y }
   realstr(ptrmax.x-ptroff.x, bs); { place value }
   plcstr(28*16,   32*16, bs, 8, black, yellow, true);
   if abs(curwin^.cs^.bbex-curwin^.cs^.bbsx) <> 0 then begin

      if trnfrm in [rm0, rm180, rmm0, rmm180] then { normal }
         realstr((ptrmax.x-ptroff.x)*abs(curwin^.cs^.bbey-curwin^.cs^.bbsy)/
                 abs(curwin^.cs^.bbex-curwin^.cs^.bbsx), bs)
      else { rotated }
         realstr((ptrmax.x-ptroff.x)*abs(curwin^.cs^.bbex-curwin^.cs^.bbsx)/
                 abs(curwin^.cs^.bbey-curwin^.cs^.bbsy), bs)

   end else realstr(0.0, bs);
   plcstr(28*16,   33*16, bs, 8, black, yellow, true);
   { max x, y }
   realstr(ptrmax.x, button[bmaxx].s); { place value }
   updbut(bmaxx); { update }
   realstr(ptrmax.y, button[bmaxy].s); { place value }
   updbut(bmaxy); { update }
   { off x, y }
   realstr(ptroff.x, button[boffx].s); { place value }
   updbut(boffx); { update }
   realstr(ptroff.y, button[boffy].s); { place value }
   updbut(boffy) { update }

end;
{}
{**************************************************************

START PRINTER POP-UP EDIT

The contents of the current button is
saved, the button is set in edit mode, and the edit started.

**************************************************************}

procedure strpedt; 

begin

   if (curbut in [bjuncv, bconnv, bdotsv, blinev, btsizv,
                  bnamev, bnord, bfname, bcname, borgxv, borgyv,
                  bsclv, bmaxx, bmaxy, boffx, boffy]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { cancel in-progress edits }
      if cedbut <> bnull then begin

         button[cedbut].s := butsav; { restore from save }
         { update screen }
         updbut(cedbut) { update }

      end;
      butsav := button[curbut].s; { save button }
      edtbut(button[curbut]); { kick off edit }
      cedbut := curbut { set edit in progress }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

PERFORM PRINTER POP-UP EDIT

Performs each character of printer pop-up paramter edits.

**************************************************************}

procedure dopedt(c, cs: char; b: buttyp; var r: real);

var e: boolean;

begin

   edit(button[b], edtpos, c, cs);
   if c = chr(13) then begin { done }

      cedbut := bnull; { cancel edit }
      getrnm(button[b], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[b].s); { place value }
         rescur; { reset cursor }
         updbut(b); { update }
         update; { update "sympathetic" buttons }
         setcur { replace cursor }

      end

   end

end;
{}
{**************************************************************

PROCESS PRINT CONFIGURATION MENU

Presents the printer configuration menu popup, and handles
all entries thereby.

**************************************************************}

procedure printpop;

var bs: butstr; { temp string }

begin

   stopact; { stop all modes }
   butact(bprint); { set print mode active }
   curscm := curscm + [smprint]; { add overlay screen mode }
   { draw print menu }
   updbut(bmaxx); { maximum demension printer x }     
   updbut(bmaxy); { maximum demension printer y }
   updbut(boffx); { offset demension x }
   updbut(boffy); { offset demension y }
   updbut(bseta); { print setup saves }
   updbut(bsetb);
   updbut(bsetc);
   updbut(bsetd);
   updbut(bsete);
   updbut(bsetf);
   updbut(bsetg);
   updbut(bseth); 
   rescur; { lift cursor }
   { place popup onscreen }
   plcstr(20*16,   22*16, '        ', 8, black, yellow, false);
   plcstr((20+8)*16, 22*16, '        ', 8, black, yellow, false);
   plcstr(20*16,   23*16, '    PRIN', 8, black, yellow, false);
   plcstr((20+8)*16, 23*16, 'TER     ', 8, black, yellow, false);
   plcstr(20*16,   24*16, '    CONT', 8, black, yellow, false);
   plcstr((20+8)*16, 24*16, 'ROL     ', 8, black, yellow, false);
   plcstr(20*16,   25*16, '        ', 8, black, yellow, false);
   plcstr((20+8)*16, 25*16, '        ', 8, black, yellow, false);
   box(20*16*16, 22*16, (20+16)*16-1, (22+4)*16-1, black);
   plcstr(20*16,   26*16, 'MAX    X', 8, black, yellow, true);
   plcstr(20*16,   27*16, '       Y', 8, black, yellow, true);
   plcstr(20*16,   28*16, 'OFFSET X', 8, black, yellow, true);
   plcstr(20*16,   29*16, '       Y', 8, black, yellow, true);
   plcstr(20*16,   30*16, 'SHEET  X', 8, black, yellow, true);
   if abs(curwin^.cs^.bbex-curwin^.cs^.bbsx) <> 0 then
      realstr((abs(curwin^.cs^.bbex-curwin^.cs^.bbsx)+1)*pixsiz, bs)
   else realstr(0.0, bs);
   plcstr(28*16,   30*16, bs, 8, black, yellow, true);
   plcstr(20*16,   31*16, '       Y', 8, black, yellow, true);
   if abs(curwin^.cs^.bbey-curwin^.cs^.bbsy) <> 0 then
      realstr((abs(curwin^.cs^.bbey-curwin^.cs^.bbsy)+1)*pixsiz, bs)
   else realstr(0.0, bs);
   plcstr(28*16,   31*16, bs, 8, black, yellow, true);
   plcstr(20*16,   32*16, 'PRINT  X', 8, black, yellow, true);
   plcstr(20*16,   33*16, '       Y', 8, black, yellow, true);
   plcstr(20*16,   34*16, 'SETS    ', 8, black, yellow, true);
   update; { update buttons }
   box(20*16-1, 22*16-1, (20+16)*16, (22+13)*16, black);
   setcur { drop cursor }

end;
{}
{**************************************************************

REMOVE PRINTER POP-UP MENU

Removes the printer pop-menu from the screen.

**************************************************************}

procedure printstop;

var s, e: point; { menu area bounds }

begin

   rescur; { reset cursor }
   { clear menu off screen }
   block(screen, 20*16-1, 22*16-1, (20+16)*16, (22+13)*16, white);
   s.x := 20*16-1-1; { set bounds with slop }
   s.y := 22*16-1-1;
   e.x := (20+16)*16+1;
   e.y := (22+15)*16+1;
   realc(s, curwin^.cs^.vp); { convert to real }
   realc(e, curwin^.cs^.vp); { convert coordinates }
   rregion(s.x, s.y, e.x, e.y); { redraw }
   setcur; { drop cursor }
   curscm := curscm - [smprint]; { add overlay screen mode }
   butina(bprint) { deactivate print button }

end;
{}
{**************************************************************

PRINT PROCESS

Handles the print button. Either the current sheet is printed,
or the printer configure popup is presented.

**************************************************************}

procedure doprint;

begin

   if (curbut = bprint) and puck.b[1].a then prtsht { print sheet }
   else if (curbut = bprint) and puck.b[2].a then 
      printpop; { present popup }
   resptr { reset buttons }

end;
{} 
end. { module }

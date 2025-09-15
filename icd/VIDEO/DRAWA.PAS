!!!!! Warning: this module not up to date !!!!!
module drawa;

uses {$U ..\common.j} common;

function rgetpix(x, y: integer): color; external; { get pixel value }
procedure rsetpix(x, y: integer; c: color); external; { set pixel value }
{}
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
{}
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
{}
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
{}
{**************************************************************

GET PIXEL

Gets a single pixel with real coordinates.
Has virtually no meaning unless real and screen coordinates
correspond.

***************************************************************}

function getpix(var vp:   viewport; { viewport }
                x, y: integer)  { point coordinates }
                : color;        { returned color }

begin

   viewx(vp, x); { find screen coordinates }
   viewy(vp, y);
   { clip }
   if (x >= vp.c.s.x) and (x <= vp.c.e.x) and
      (y >= vp.c.s.y) and (x <= vp.c.e.y) then
      getpix := rgetpix(x, y) { get true pixel }
   else 
      getpix := white { set nowhere color }

end;
{}
{**************************************************************

SET PIXEL

Sets a single pixel with real coordinates.
Has virtually no meaning unless real and screen coordinates
correspond.

***************************************************************}

procedure setpix(var vp:   viewport; { viewport }
                 x, y:     integer;  { point coordinates }
                 c:        color);   { returned color }

begin

   viewx(vp, x); { find screen coordinates }
   viewy(vp, y);
   { clip }
   if (x >= vp.c.s.x) and (x <= vp.c.e.x) and
      (y >= vp.c.s.y) and (x <= vp.c.e.y) then
      rsetpix(x, y, c) { set true pixel }

end;
{}
{**************************************************************

LINE DRAW

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The coordinates are converted to screen coordinates and the line
is clipped and drawn.

***************************************************************}

procedure line(var vp:         viewport; { viewport }
               x1, y1, x2, y2: integer;  { line start and end }
               c:              color);   { color }

var d, dx, dy:                  integer;
    aincr, bincr, yincr, xincr: integer;
    x, y:                       integer;
    draw:                       boolean; { draw flag }

begin
   
   viewx(vp, x1); { find screen coordinates }
   viewy(vp, y1);
   viewx(vp, x2);
   viewy(vp, y2);
   clip(x1, y1, x2, y2, draw, vp.c); { clip line }
   if draw then begin { line still exists }

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
         rsetpix(x, y, c); { set pixel at (x1, y1) }
         for x := x1+1 to x2 do begin { do from x1+1 to x2 }
   
            if d >= 0 then begin
   
               y := y + yincr; { set pixel A }
               d := d + aincr
   
            end else d := d + bincr; { set pixel B }
            rsetpix(x, y, c)
   
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
         rsetpix(x, y, c); { set pixel at (x1, y1) }
         for y := y1+1 to y2 do begin { do from y1+1 to y2 }
   
            if d >= 0 then begin
   
               x := x + xincr; { set pixel A }
               d := d + aincr
   
            end else d := d + bincr; { set pixel B }
            rsetpix(x, y, c)
   
         end
   
      end

   end
   
end;
{}
{**************************************************************

LINE DRAW WITH SAVE

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The pixels under the line are saved in the line buffer.
The coordinates are converted to screen and the line is clipped.

***************************************************************}

procedure linesav(var vp:         viewport; { viewport }
                  x1, y1, x2, y2: integer;  { start and end coordinates }
                  c:              color;    { color of line } 
                  var lines:      linarr;   { pixel save buffer }
                  var i:          lininx);  { pixel save index }

var d, dx, dy:                  integer;
    aincr, bincr, yincr, xincr: integer;
    x, y:                       integer;
    draw:                       boolean; { draw flag }

begin
   
   viewx(vp, x1); { find screen coordinates }
   viewy(vp, y1);
   viewx(vp, x2);
   viewy(vp, y2);
   clip(x1, y1, x2, y2, draw, vp.c); { clip line }
   if draw then begin { line still exists }

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
         lines[i] := rgetpix(x, y); { save pixel value }
         i := i + 1; { next }
         rsetpix(x, y, c); { set pixel at (x1, y1) }
         for x := x1+1 to x2 do begin { do from x1+1 to x2 }
   
            if d >= 0 then begin
   
               y := y + yincr; { set pixel A }
               d := d + aincr
   
            end else d := d + bincr; { set pixel B }
            lines[i] := rgetpix(x, y); { save pixel value }
            i := i + 1; { next }
            rsetpix(x, y, c)
   
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
         lines[i] := rgetpix(x, y); { save pixel value }
         i := i + 1; { next }
         rsetpix(x, y, c); { set pixel at (x1, y1) }
         for y := y1+1 to y2 do begin { do from y1+1 to y2 }
   
            if d >= 0 then begin
   
               x := x + xincr; { set pixel A }
               d := d + aincr
   
            end else d := d + bincr; { set pixel B }
            lines[i] := rgetpix(x, y); { save pixel value }
            i := i + 1; { next }
            rsetpix(x, y, c)
   
         end
   
      end

   end
   
end;
{}
{**************************************************************

LINE RESTORE

Draws a line between points indicated by coordinate pairs
expressed as real coordinates. The colors are retrived
from the line save buffer, resulting in a restore of the
screen state before the line was drawn.
The coordinates are converted to screen and the line is clipped.

***************************************************************}

procedure linerst(var vp:         viewport; { viewport }
                  x1, y1, x2, y2: integer;  { start and end coordinates }
                  var lines:      linarr;   { pixel save buffer }
                  var i:          lininx);  { pixel save index }

var d, dx, dy:                  integer;
    aincr, bincr, yincr, xincr: integer;
    x, y:                       integer;
    draw:                       boolean; { draw flag }

begin
   
   viewx(vp, x1); { find screen coordinates }
   viewy(vp, y1);
   viewx(vp, x2);
   viewy(vp, y2);
   clip(x1, y1, x2, y2, draw, vp.c); { clip line }
   if draw then begin { line still exists }

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
         rsetpix(x, y, lines[i]); { set pixel at (x1, y1) }
         i := i + 1; { next }
         for x := x1+1 to x2 do begin { do from x1+1 to x2 }
   
            if d >= 0 then begin
   
               y := y + yincr; { set pixel A }
               d := d + aincr
   
            end else d := d + bincr; { set pixel B }
            rsetpix(x, y, lines[i]);
            i := i + 1 { next }
   
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
         rsetpix(x, y, lines[i]); { set pixel at (x1, y1) }
         i := i + 1; { next }
         for y := y1+1 to y2 do begin { do from y1+1 to y2 }
   
            if d >= 0 then begin
   
               x := x + xincr; { set pixel A }
               d := d + aincr
   
            end else d := d + bincr; { set pixel B }
            rsetpix(x, y, lines[i]);
            i := i + 1 { next }
   
         end
   
      end

   end
   
end;
{}
{**************************************************************

PERFORM DOT PLACEMENT

Accepts a pair of index vectors, and draws the corresponding 
dot grid. The coordinates are given in screen.

**************************************************************}

{procedure dogrid(xl, yl: dotvec; c: color);

var xi, yi: dotinx; { indexes }

{begin

   yi := 1; { index 1st y point }
{   while yl[yi] <> -1 do begin

      xi := 1; { index 1st x point }
{      while xl[xi] <> -1 do 
         begin setpix(xl[xi], yl[yi], c); xi := xi + 1 end;
      yi := yi + 1

   end

end;
}
{}
{**************************************************************

DRAW FILLED BOX

Draws the indicated box, with solid color.

**************************************************************}

procedure block(var vp:         viewport; { viewport }
                x1, y1, x2, y2: integer;  { start and end }
                c:              color);   { color }

var x, y: integer;
    t: integer;

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
      for y := y1 to y2 do
         for x := x1 to x2 do rsetpix(x, y, c)

   end

end;
{}
end. { module }

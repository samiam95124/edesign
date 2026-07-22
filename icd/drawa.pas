module drawa;

uses {$U ..\common.j} common;

function getpix(x, y: integer): color; cexternal; { get pixel value }
procedure setpix(x, y: integer; c: color); cexternal; { set pixel value }
{}
{**************************************************************

LINE DRAW

Draws a line between points indicated by coordinate pairs
expressed as screen coordinates, in the given color.

***************************************************************}

procedure line(x1, y1, x2, y2: integer; c: color);

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
      setpix(x, y, c); { set pixel at (x1, y1) }
      for x := x1+1 to x2 do begin { do from x1+1 to x2 }

         if d >= 0 then begin

            y := y + yincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         setpix(x, y, c)

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
      setpix(x, y, c); { set pixel at (x1, y1) }
      for y := y1+1 to y2 do begin { do from y1+1 to y2 }

         if d >= 0 then begin

            x := x + xincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         setpix(x, y, c)

      end

   end

end;
{}
{**************************************************************

LINE DRAW WITH SAVE

Draws a line between points indicated by coordinate pairs
expressed as screen coordinates, in the given color.
The pixels under the line are saved in the line buffer.

***************************************************************}

procedure linesav(x1, y1, x2, y2: integer; { start and end coordinates }
                  c: color;                { color of line } 
                  var lines: linarr;       { pixel save buffer }
                  var i: lininx);          { pixel save index }

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
      lines[i] := getpix(x, y); { save pixel value }
      i := i + 1; { next }
      setpix(x, y, c); { set pixel at (x1, y1) }
      for x := x1+1 to x2 do begin { do from x1+1 to x2 }

         if d >= 0 then begin

            y := y + yincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         lines[i] := getpix(x, y); { save pixel value }
         i := i + 1; { next }
         setpix(x, y, c)

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
      lines[i] := getpix(x, y); { save pixel value }
      i := i + 1; { next }
      setpix(x, y, c); { set pixel at (x1, y1) }
      for y := y1+1 to y2 do begin { do from y1+1 to y2 }

         if d >= 0 then begin

            x := x + xincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         lines[i] := getpix(x, y); { save pixel value }
         i := i + 1; { next }
         setpix(x, y, c)

      end

   end

end;
{}
{**************************************************************

LINE RESTORE

Draws a line between points indicated by coordinate pairs
expressed as screen coordinates. The colors are retrived
from the line save buffer, resulting in a restore of the
screen state before the line was drawn.

***************************************************************}

procedure linerst(x1, y1, x2, y2: integer; { start and end coordinates }
                  var lines: linarr;       { pixel save buffer }
                  var i: lininx);          { pixel save index }

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
      setpix(x, y, lines[i]); { set pixel at (x1, y1) }
      i := i + 1; { next }
      for x := x1+1 to x2 do begin { do from x1+1 to x2 }

         if d >= 0 then begin

            y := y + yincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         setpix(x, y, lines[i]);
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
      setpix(x, y, lines[i]); { set pixel at (x1, y1) }
      i := i + 1; { next }
      for y := y1+1 to y2 do begin { do from y1+1 to y2 }

         if d >= 0 then begin

            x := x + xincr; { set pixel A }
            d := d + aincr

         end else d := d + bincr; { set pixel B }
         setpix(x, y, lines[i]);
         i := i + 1 { next }

      end

   end

end;
{}
{**************************************************************

PERFORM DOT PLACEMENT

Accepts a pair of index vectors, and draws the corresponding 
dot grid.

**************************************************************}

procedure dogrid(xl, yl: dotvec; c: color);

var xi, yi: dotinx; { indexes }

begin

   yi := 1; { index 1st y point }
   while yl[yi] <> -1 do begin

      xi := 1; { index 1st x point }
      while xl[xi] <> -1 do 
         begin setpix(xl[xi], yl[yi], c); xi := xi + 1 end;
      yi := yi + 1

   end

end;
{}
{**************************************************************

DRAW FILLED BOX

Draws the indicated box, with solid color.

**************************************************************}

procedure block(x1, y1, x2, y2: integer; c: color);

var i: integer;

begin

   { swap so that box is drawn down }
   if y1 > y2 then begin i := y1; y1 := y2; y2 := i end;
   for i := y1 to y2 do line(x1, i, x2, i, c)

end;
{}
end. { module }

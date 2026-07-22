{ port: fragment i - target view display, ported from icdf.pas. The
  updtar stub in the base layer is replaced by the real routine here.
  The stale external declarations for box and frame in the original
  (missing the viewport parameter of the real routines) are repaired
  at the call sites; each repair is marked with a "port:" comment.
  The alphal width table and the 16 pixel character cell constant are
  replaced by chrwidth/chrheight per the base layer. }
{}
{**************************************************************

FIND ASPECT RATIO

Finds the aspect ratio of the given rectangle.

**************************************************************}

function ratio(r: region): real;

begin

   ratio := abs(r.e.x-r.s.x)/abs(r.e.y-r.s.y)

end;
{}
{**************************************************************

UPDATE TARGET DISPLAY

Calculates and redraws the targeting display.

**************************************************************}

procedure updtar;

var vp: region; { real bounds of viewport }
    tb: region; { real bounds of target display }
    r:  region; { point region holder }

begin

   { port: guard added — no current sheet means no target to update
     (the original was only reached with a sheet in edit) }
   if curwin^.cs <> nil then begin


   targbnd.s.x := curwin^.cs^.bbsx; { save bounds }
   targbnd.s.y := curwin^.cs^.bbsy;
   targbnd.e.x := curwin^.cs^.bbex;
   targbnd.e.y := curwin^.cs^.bbey;
   vp := curwin^.cs^.vp.r; { set target bounding box }
   if boundset(curwin^.cs) then begin { bounds are set }

      { determine largest minimum containment }
      if vp.s.x < curwin^.cs^.bbsx then tb.s.x := vp.s.x
      else tb.s.x := curwin^.cs^.bbsx;
      if vp.s.y < curwin^.cs^.bbsy then tb.s.y := vp.s.y
      else tb.s.y := curwin^.cs^.bbsy;
      if vp.e.x > curwin^.cs^.bbex then tb.e.x := vp.e.x
      else tb.e.x := curwin^.cs^.bbex;
      if vp.e.y > curwin^.cs^.bbey then tb.e.y := vp.e.y
      else tb.e.y := curwin^.cs^.bbey

   end else { bounds not set }
      { just set super box equivalent to viewer box }
      tb := vp;
   { determine scale, and final adjust for border and center }
   if ratio(targvp.v) < ratio(tb) then begin { x dominated }

      targvp.s.x := round((abs(tb.e.x-tb.s.x)/
                    (abs(targvp.v.e.x-targvp.v.s.x)-(2*tgborder)))*scalem);
      targvp.s.y := round((abs(tb.e.x-tb.s.x)/
                    (abs(targvp.v.e.x-targvp.v.s.x)-(2*tgborder)))*scalem);
      targvp.r.s.x := tb.s.x-realdist(tgborder, targvp.s.x); { set x origin }
      { set y origin }
      targvp.r.s.y := round((tb.s.y+abs(tb.e.y-tb.s.y)/2)-
                      (realdist(targvp.v.e.y-targvp.v.s.y, targvp.s.y)/2))

   end else begin { y dominated }

      targvp.s.x := round((abs(tb.e.y-tb.s.y)/
                    (abs(targvp.v.e.y-targvp.v.s.y)-(2*tgborder)))*scalem);
      targvp.s.y := round((abs(tb.e.y-tb.s.y)/
                    (abs(targvp.v.e.y-targvp.v.s.y)-(2*tgborder)))*scalem);
      { set x origin }
      targvp.r.s.x := round((tb.s.x+abs(tb.e.x-tb.s.x)/2)-
                      (realdist(targvp.v.e.x-targvp.v.s.x, targvp.s.x)/2));
      targvp.r.s.y := tb.s.y-realdist(tgborder, targvp.s.y) { set y origin }

   end;
   { clear target display }
   block(screen, targvp.v.s.x, targvp.v.s.y, targvp.v.e.x, targvp.v.e.y, white);
   if boundset(curwin^.cs) then begin { bounds set }

      r.s.x := curwin^.cs^.bbsx; { set bounding box }
      r.s.y := curwin^.cs^.bbsy;
      r.e.x := curwin^.cs^.bbex;
      r.e.y := curwin^.cs^.bbey;
      viewc(r.s, targvp); { convert coordinates }
      viewc(r.e, targvp);
      block(screen, r.s.x, r.s.y, r.e.x, r.e.y, dwhite)

   end;
   viewc(vp.s, targvp); { convert coordinates }
   viewc(vp.e, targvp);
   { port: added screen viewport (the original external declaration of
     box was stale; the real box takes a viewport first) }
   box(screen, vp.s.x, vp.s.y, vp.e.x, vp.e.y, brown)

   end

end;
{}
{**************************************************************

PERFORM SIGN-ON DISPLAY

**************************************************************}

procedure logo(x, y: integer;  { location of upper left }
               s:    integer;  { scale*10 }
               b:    boolean;  { blackout flag }
               bc:   color);   { blackout color }

procedure lines(xs, ys, xe, ye, o: integer;
                cl:                color);

begin

    if b then cl := bc; { process blackout }
    line(screen, (xs*100+o*100)*s div 10000+x,
         ys*100*s div 10000+y,
         (xe*100+o*100)*s div 10000+x,
         ye*100*s div 10000+y, cl)

end;

begin

   { logo }
   lines(0, 3, 2, 3, 0, lred);
   lines(0, 3, 0, 5, 0, lred);
   lines(0, 5, 2, 5, 0, lred);
   lines(2, 1, 2, 3, 0, lred);
   lines(2, 5, 2, 7, 0, lred);
   lines(2, 1, 6, 1, 0, lred);
   lines(2, 7, 6, 7, 0, lred);
   lines(3, 2, 6, 2, 0, lred);
   lines(3, 6, 6, 6, 0, lred);
   lines(3, 2, 3, 6, 0, lred);
   lines(4, 0, 5, 0, 0, green);
   lines(4, 3, 5, 3, 0, green);
   lines(4, 0, 4, 3, 0, green);
   lines(5, 0, 5, 3, 0, green);
   lines(4, 5, 5, 5, 0, lblue);
   lines(4, 8, 5, 8, 0, lblue);
   lines(4, 5, 4, 8, 0, lblue);
   lines(5, 5, 5, 8, 0, lblue);
   lines(6, 1, 6, 2, 0, lred);
   lines(6, 6, 6, 7, 0, lred);
   { M }
   lines(0, 0, 0, 8, 8, lblue);
   lines(0, 0, 2, 4, 8, lblue);
   lines(2, 4, 4, 0, 8, lblue);
   lines(4, 0, 4, 8, 8, lblue);
   { O }
   lines(0, 1, 0, 7, 14, lblue);
   lines(0, 1, 1, 0, 14, lblue);
   lines(0, 7, 1, 8, 14, lblue);
   lines(1, 0, 3, 0, 14, lblue);
   lines(1, 8, 3, 8, 14, lblue);
   lines(3, 0, 4, 1, 14, lblue);
   lines(3, 8, 4, 7, 14, lblue);
   lines(4, 1, 4, 7, 14, lblue);
   { O }
   lines(0, 1, 0, 7, 20, lblue);
   lines(0, 1, 1, 0, 20, lblue);
   lines(0, 7, 1, 8, 20, lblue);
   lines(1, 0, 3, 0, 20, lblue);
   lines(1, 8, 3, 8, 20, lblue);
   lines(3, 0, 4, 1, 20, lblue);
   lines(3, 8, 4, 7, 20, lblue);
   lines(4, 1, 4, 7, 20, lblue);
   { R }
   lines(0, 0, 0, 8, 26, lblue);
   lines(0, 0, 3, 0, 26, lblue);
   lines(0, 4, 3, 4, 26, lblue);
   lines(2, 4, 4, 8, 26, lblue);
   lines(3, 0, 4, 1, 26, lblue);
   lines(3, 4, 4, 3, 26, lblue);
   lines(4, 1, 4, 3, 26, lblue);
   { E }
   lines(0, 0, 0, 8, 32, lblue);
   lines(0, 0, 4, 0, 32, lblue);
   lines(0, 4, 2, 4, 32, lblue);
   lines(0, 8, 4, 8, 32, lblue);
   { / }
   lines(0, 8, 4, 0, 38, lblue);
   { I }
   lines(0, 0, 4, 0, 44, lblue);
   lines(0, 8, 4, 8, 44, lblue);
   lines(2, 0, 2, 8, 44, lblue);
   { C }
   lines(0, 1, 0, 7, 50, lblue);
   lines(0, 1, 1, 0, 50, lblue);
   lines(0, 7, 1, 8, 50, lblue);
   lines(1, 0, 3, 0, 50, lblue);
   lines(1, 8, 3, 8, 50, lblue);
   lines(3, 0, 4, 1, 50, lblue);
   lines(3, 8, 4, 7, 50, lblue);
   { D }
   lines(0, 0, 0, 8, 56, lblue);
   lines(0, 0, 3, 0, 56, lblue);
   lines(0, 8, 3, 8, 56, lblue);
   lines(3, 0, 4, 1, 56, lblue);
   lines(3, 8, 4, 7, 56, lblue);
   lines(4, 1, 4, 7, 56, lblue)

end;
{}
{**************************************************************

PERFORM SIGN-ON DISPLAY

**************************************************************}

procedure intro;

type string40 = packed array [1..40] of char;

var i:    integer;
    s:    integer; { scale * 100 }
    x, y: integer;
    st:   array [1..12] of string40;
    max:  integer; { maximum string length }

{ place string onscreen }

procedure plcstr(y: integer; var s: string40);

var i:  1..40; { string index }
    l:  integer; { length of string in pixels }
    x:  integer;
    sl: 1..40; { string length }

begin

   sl := 40; { set maximum }
   while (sl > 1) and (s[sl] = ' ') do sl := sl - 1;
   l := 0; { clear length }
   { find total length }
   { port: alphal width table replaced by chrwidth }
   for i := 1 to sl do l := l+chrwidth(s[i])+1;
   { find center of string }
   x := ((maxx-minx) div 2) - (l div 2);
   for i := 1 to sl do begin

      setchr(screen, x, y, s[i], black);
      x := x + chrwidth(s[i])+1 { next collumn }

   end

end;

{ find maximum string length }

procedure maxstr(var s: string40);

var i: 1..40; { string index }
    l: integer; { length of string in pixels }

begin

   i := 40; { set maximum }
   while (i > 1) and (s[i] = ' ') do i := i - 1;
   l := 0; { clear length }
   { find total length }
   { port: alphal width table replaced by chrwidth }
   for i := 1 to i do l := l+chrwidth(s[i])+1;
   if l > max then max := l { set new maximum }

end;

begin

   { perform lit run }
   s := 10; { set initial size (.1) }
   y := maxy div 2;
   for i := 1 to 50 do begin

      { set x to screen center }
      x := (maxx div 2)-((62*100)*s div 10000 div 2);
      y := y - 4; { interate y }
      s := s + 20; { next scale (.1) }
      logo(x, y, s, false, bakclr)

   end;
   { perform blackout run }
   s := 10; { set initial size (.1) }
   y := maxy div 2;
   for i := 1 to 50 do begin

      { set x to screen center }
      x := (maxx div 2)-((62*100)*s div 10000 div 2);
      y := y - 4; { interate y }
      s := s + 20; { next scale (.1) }
      logo(x, y, s, i <> 100, bakclr)

   end;
   x := x + 1; { intensify it }
   logo(x, y, s, false, bakclr);
   x := x - 1;
   y := y + 1;
   logo(x, y, s, false, bakclr);
   x := x + 1;
   logo(x, y, s, false, bakclr);
   { place copyright notice }
   st[1]  := 'MOORE/ICD                               ';
   st[2]  := 'INTEGRATED CIRCUIT DESIGN SYSTEM        ';
   st[3]  := '                                        ';
   st[4]  := 'PROGRAM COPYRIGHT C 1991 S A MOORE      ';
   st[5]  := 'THIS PROGRAM AND ANY SUPPORTING         ';
   st[6]  := 'HARDWARE MAY NOT BE COPIED,             ';
   st[7]  := 'DUPLICATED OR REPRODUCED IN ANY         ';
   st[8]  := 'FORM, OR DISASSEMBLED, OR               ';
   st[9]  := 'DECOMPILED. THIS PROGRAM AND ANY        ';
   st[10] := 'SUPPORTING HARDWARE MAY NOT BE          ';
   st[11] := 'TRANSFERRED TO ANY UNLICENCED           ';
   st[12] := 'PERSON.                                 ';
   max := 0; { clear string maximum }
   for i := 1 to 12 do { find maximum string }
      maxstr(st[i]);
   max := max + 32; { add border space }
   y := (maxy-miny) div 2; { set origin }
   { port: added screen viewport (the original external declaration of
     frame was stale; the real frame takes a viewport first); the 16
     pixel character cell constant is replaced by chrheight }
   frame(screen, ((maxx-minx) div 2)-(max div 2), y,
         ((maxx-minx) div 2)+(max div 2), y+chrheight+(12*chrheight)+chrheight,
         baklgt, baklgt, bakshw, bakshw);
   block(screen, ((maxx-minx) div 2)-(max div 2)+2, y+2,
         ((maxx-minx) div 2)+(max div 2)-2, y+chrheight+(12*chrheight)+chrheight-2,
         bakclr);
   for i := 1 to 12 do begin { print string block }

      plcstr(y+chrheight+4, st[i]); { port: was y+20 (16 cell + 4) }
      y := y + chrheight

   end

end;
{}
{**************************************************************

INITALIZE BLANK ANIMATOR

Initalizes the blank animation mode.

**************************************************************}

procedure aniini;

begin

   aniloc.x := 1; { clear animator location }
   aniloc.y := 1;
   aninxt.x := +1; { set increments }
   aninxt.y := +1

end;
{}
{**************************************************************

ANIMATE BLANKING DISPLAY

Either starts off the logo display, or moves it to a different
location. This is designed to keep it from burning into the
screen.

**************************************************************}

procedure aniblank;

var x, y: integer; { origin save }
    s:    integer; { scale }

begin

   s := maxx; { set logo scale }
   x := aniloc.x + aninxt.x; { find next location }
   y := aniloc.y + aninxt.y;
   { check past side }
   if (x < minx) or
      (((62*100)*s div 10000+x+1) > maxx) then
         aninxt.x := -aninxt.x; { change x direction }
   if (y < miny) or
      (((8*100)*s div 10000+y+1) > maxy) then
         aninxt.y := -aninxt.y; { change x direction }
   x := aniloc.x; { save present origin }
   y := aniloc.y;
   aniloc.x := x + aninxt.x; { find next location }
   aniloc.y := y + aninxt.y;
   { draw in at new location }
   logo(aniloc.x, aniloc.y, s, false, black);
   { blank out last location }
   logo(x, y, s, true, black)

end;
{}
{ UNRESOLVED: none }

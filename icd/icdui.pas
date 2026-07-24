{******************************************************************************
*                                                                             *
*                        ICD USER INTERFACE MODULE                            *
*                                                                             *
* Pascaline port of the ICD graphics/windowing/command layers. This is one    *
* module because the original ICD source files (icda..icdh) call each other   *
* mutually, and Pascaline forbids dependency cycles between modules; the       *
* original resolved this with external declarations across separately         *
* compiled units. Section banners below mark the code ported from each         *
* original file. Built directly: pc icd (pulls in icddef, graphics, services).*
*                                                                             *
******************************************************************************}

{******************************************************************************
*                                                                             *
*                        ICD USER INTERFACE MODULE                            *
*                                                                             *
* Pascaline port of the ICD graphics/windowing layer. This module replaces    *
* the direct-to-hardware display stack of the original (pixel.asm,           *
* drawa/drawb.asm, the card drivers and the bitmap font) with the Pascaline   *
* graphics library, and carries the ported viewport, rubber-band, button     *
* and window-management layers from icdb.pas, icda.pas and icdc.pas.         *
*                                                                             *
* The base layer below is the only place that calls the graphics library     *
* directly. Everything above it is ported ICD code.                          *
*                                                                             *
******************************************************************************}

module icdui(output);

joins graphics, services;

uses icddef;

var scnmaxx: integer; { physical screen size x (pixels) }
    scnmaxy: integer; { physical screen size y (pixels) }

{******************************************************************************

BASE LAYER

Adapts the ICD drawing vocabulary to the Pascaline graphics library.
The 16 EGA colors of ICD are reproduced exactly via ratioed RGB.

******************************************************************************}

{ Drawing subwindow.

  The sheet drawing area is an Ami child window placed over the lower
  left of the main (frame) window. Any drawing that falls within the
  subwindow region routes to it, in subwindow relative coordinates,
  and Ami clips it at the subwindow bounds automatically. The frame
  (title, menus, buttons, target, messages) draws to the main window
  exactly as before; nothing but sheet content ever draws inside the
  drawing area, so routing by position needs no call site changes.
  chksub opens the subwindow when the drawing area first exists and
  re-places it whenever the layout changes (window resize etc). }

var subin, subout: text;    { subwindow file pair }
    subon:         boolean; { subwindow is open }
    subr:          region;  { subwindow region, main window coords }

{ check point lies in the drawing subwindow }

function insub(x, y: integer): boolean;

begin

   insub := subon and
            (x >= subr.s.x) and (x <= subr.e.x) and
            (y >= subr.s.y) and (y <= subr.e.y)

end;

{ set foreground color from ICD color code, given window }

procedure setfcolorf(var f: text; c: color);

var third: integer; { 1/3 of full scale }

begin

   third := maxint div 3;
   case c of

      black:    graphics.fcolorg(f, 0, 0, 0);
      blue:     graphics.fcolorg(f, 0, 0, third*2);
      green:    graphics.fcolorg(f, 0, third*2, 0);
      cyan:     graphics.fcolorg(f, 0, third*2, third*2);
      red:      graphics.fcolorg(f, third*2, 0, 0);
      magenta:  graphics.fcolorg(f, third*2, 0, third*2);
      brown:    graphics.fcolorg(f, third*2, third, 0);
      dwhite:   graphics.fcolorg(f, third*2, third*2, third*2);
      gray:     graphics.fcolorg(f, third, third, third);
      lblue:    graphics.fcolorg(f, third, third, maxint);
      lgreen:   graphics.fcolorg(f, third, maxint, third);
      lcyan:    graphics.fcolorg(f, third, maxint, maxint);
      lred:     graphics.fcolorg(f, maxint, third, third);
      lmagenta: graphics.fcolorg(f, maxint, third, maxint);
      yellow:   graphics.fcolorg(f, maxint, maxint, third);
      white:    graphics.fcolorg(f, maxint, maxint, maxint)

   end

end;

{ set foreground color from ICD color code (main window) }

procedure setfcolor(c: color);

begin

   setfcolorf(output, c)

end;

{ set single pixel, screen coordinates }

procedure scrsetpix(x, y: integer; c: color);

begin

   if insub(x, y) then begin { drawing area: route to subwindow }

      setfcolorf(subout, c);
      graphics.setpixel(subout, x-subr.s.x+1, y-subr.s.y+1)

   end else begin

      setfcolor(c);
      graphics.setpixel(x, y)

   end

end;

{ draw line, screen coordinates }

procedure scrline(x1, y1, x2, y2: integer; c: color);

begin

   if insub(x1, y1) and insub(x2, y2) then begin

      { drawing area: route to subwindow }
      setfcolorf(subout, c);
      graphics.line(subout, x1-subr.s.x+1, y1-subr.s.y+1,
                            x2-subr.s.x+1, y2-subr.s.y+1)

   end else begin

      setfcolor(c);
      graphics.line(x1, y1, x2, y2)

   end

end;

{ draw filled rectangle, screen coordinates }

procedure scrblock(x1, y1, x2, y2: integer; c: color);

begin

   if insub(x1, y1) and insub(x2, y2) then begin

      { drawing area: route to subwindow }
      setfcolorf(subout, c);
      graphics.frect(subout, x1-subr.s.x+1, y1-subr.s.y+1,
                             x2-subr.s.x+1, y2-subr.s.y+1)

   end else begin

      setfcolor(c);
      graphics.frect(x1, y1, x2, y2)

   end

end;

{ enter xor drawing mode (rubber band figures) }

procedure xormode;

begin

   graphics.fxor;
   if subon then graphics.fxor(subout)

end;

{ return to overwrite drawing mode }

procedure ovrmode;

begin

   graphics.fover;
   if subon then graphics.fover(subout)

end;

{ find width of single character, pixels }

function chrwidth(ch: char): integer;

var s: packed array [1..1] of char;

begin

   s[1] := ch;
   chrwidth := graphics.strsiz(s)

end;

{ find height of character cell, pixels }

function chrheight: integer;

begin

   chrheight := graphics.chrsizy

end;

{ place single character at pixel location }

procedure plchr(x, y: integer; ch: char; c: color);

begin

   if insub(x, y) then begin { drawing area: route to subwindow }

      setfcolorf(subout, c);
      graphics.cursorg(subout, x-subr.s.x+1, y-subr.s.y+1);
      write(subout, ch)

   end else begin

      setfcolor(c);
      graphics.cursorg(x, y);
      write(ch)

   end

end;

{ Check drawing subwindow placement.

  Opens the subwindow over the drawing area when that area first
  exists, and re-places it when the layout has changed. Called from
  the event pump after each event is dispatched. }

procedure chksub;

var r: region;

begin

   if curwin <> nil then if curwin^.cs <> nil then begin

      r := curwin^.cs^.vp.v; { the drawing area, main window coords }
      if not subon then begin

         if (r.e.x > r.s.x) and (r.e.y > r.s.y) then begin

            { open the subwindow as a child of the main window }
            graphics.openwin(subin, subout, output, 2);
            graphics.frame(subout, 0); { no adornments }
            graphics.auto(subout, false); { free the character grid }
            graphics.curvis(subout, false); { no text cursor }
            graphics.font(subout, 3); { sign font, as the main window }
            { match the interface font size }
            graphics.fontsiz(subout, graphics.chrsizy);
            graphics.binvis(subout); { text draws foreground only }
            graphics.buffer(subout, 0); { unbuffered, as the main window }
            graphics.setposg(subout, r.s.x, r.s.y);
            graphics.setsizg(subout, r.e.x-r.s.x+1, r.e.y-r.s.y+1);
            graphics.front(subout); { above the frame }
            subr := r;
            subon := true

         end

      end else if (r.s.x <> subr.s.x) or (r.s.y <> subr.s.y) or
                  (r.e.x <> subr.e.x) or (r.e.y <> subr.e.y) then begin

         { layout changed: re-place the subwindow }
         graphics.setposg(subout, r.s.x, r.s.y);
         graphics.setsizg(subout, r.e.x-r.s.x+1, r.e.y-r.s.y+1);
         subr := r

      end

   end

end;

{ find width of counted button string, pixels }

function strwidth(view s: butstr; l: btslen): integer;

var i: btsinx;
    w: integer;

begin

   w := 0;
   for i := 1 to l do w := w+chrwidth(s[i]);
   strwidth := w

end;

{ scale legacy interface dimension.

  The original interface was laid out in pixels against a 16 pixel
  character cell on a fixed-resolution display. Following the Ami
  convention, the port sets the font in points (11 point), so the
  character cell size in pixels follows the physical display density;
  all legacy interface pixel dimensions are scaled by the ratio of the
  real character cell height to the original 16 pixel cell. }

function uiscl(n: integer): integer;

begin

   uiscl := n*graphics.chrsizy div 16

end;

{ initialize display: graphical mode, font, screen parameters }

procedure initscreen;

begin

   graphics.auto(false);      { free the character grid }
   graphics.curvis(false);    { no text cursor }
   graphics.font(3);          { sign (sans-serif) font, as ICD look }
   graphics.setpoints(14.0);  { 14 point interface font;
                                all interface dimensions derive from
                                the resulting character cell (uiscl).
                                The window itself is left at the Ami
                                default size, which is also derived
                                from the display density }
   graphics.binvis;           { text draws foreground only }
   graphics.buffer(0);        { port: unbuffered mode -- the drawing surface
                                tracks the window size, and the Ami backend
                                updates maxxg/maxyg on resize only when
                                unbuffered (graphics.c: if (!win->bufmod)).
                                ICD repaints on etredraw so this is fine }
   scnmaxx := graphics.maxxg;
   scnmaxy := graphics.maxyg;
   maxx := scnmaxx;           { set the ICD globals }
   maxy := scnmaxy;
   minx := 1;
   miny := 1

end;

{******************************************************************************

COMPATIBILITY LAYER

Small routines whose originals live in modules not yet ported (icdd/icdf/
icde), plus stubs for deferred subsystems, and forwards for routines
defined late in the assembly order.

******************************************************************************}

{ rationalize box (real version ported in the icdd fragment) }

procedure ratbox(var x1, y1, x2, y2: integer); forward;

{ figure drawing (real versions ported in the icdd fragment; forwarded
  here because the window layer calls them first) }

procedure drwfig(p: drwptr; clr: color; co: boolean; ln: laytyp;
                 r: region); forward;
procedure drwfigs; forward;

{ ----- forwards for late-fragment routines -----
  port: these were no-op stubs while the icda file I/O, icdg layout,
  icdh simulate and icde printer layers were unported; all are now
  real and defined in later fragments, forwarded here because earlier
  fragments call them. }

procedure doloadc; forward;
procedure dosavec; forward;
procedure dofiles; forward;
procedure docells; forward;
procedure dolibs; forward;
procedure setlayout; forward;
procedure setsimulate; forward;
procedure togvis; forward;
procedure togins; forward;
procedure dolayer; forward;
procedure dowave; forward;
procedure dointer(ip: drwptr); forward;
procedure dtrace(ts: point; tl: trcptr; r: region); forward;
procedure atrace(ts: point; tl: atrcptr; r: region); forward;
procedure printstop; forward;
procedure iniprt; forward;
procedure doprint; forward;
procedure strpedt; forward;
procedure dopedt(c, cs: char; b: buttyp; var r: real); forward;

{ reset pointer communication flags (real version ported in the database
  core fragment; forwarded here because the window layer calls it first) }

procedure resptr; forward;

{ update target area contents (real version ported in the icdf fragment;
  forwarded here because the window layer calls it first) }

procedure updtar; forward;

{ find bounding box view of sheet (from icda.pas); defined after the
  viewport and bounds layers it depends on }

procedure fndbnd(sp: shtptr; var x, y, s: integer); forward;

{ find angle of point about center (from icdc.pas); defined in the
  window management layer, forwarded here because the arc code in the
  viewport layer uses it }

function angle(x1, y1, x2, y2: integer): real; forward;
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
              c:    color);   { color }

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
    x1, y1, x2, y2, s: integer;
    rdw, rde, rdn, rds:          integer; { NEWS to world edge }
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

procedure frame(x1, y1, x2, y2: integer; { rectangle }
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
         frame(r.s.x, r.s.y, r.e.x, r.e.y,
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
{***************************************************************

FRAGMENT C: UI support routines ported from icda.pas (1992)

Ported per PORTING-SPEC.md. This fragment contains the screen
level draw/text helpers (liner, plcchr, plcstr), the button
initializer and autoarrangers, the vector character generator,
number formatting, and the in-button editor and parsers.

Omitted from the original (see spec):

   elapsed, wait  - timer externals, replaced by graphics.timer
                    logic in the main program.
   getlst, entnam - DOS directory search (intdos), not ported.
   resptr         - pointer (puck) hardware, not ported.

***************************************************************}
{}
{**************************************************************

LINE DRAW REAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The line is clipped to the given region.

port: the original liner was assembly; reconstructed here
from the bliner (bold line real) pattern in icdb.pas, using
the ported viewc/clip/line routines.

***************************************************************}

procedure liner(x1, y1, x2, y2: integer; { line start and end }
                c:              color;   { line color }
                r:              region); { clipping region }

var draw: boolean;
    s, e: point;

begin

   s.x := x1; { place coordinates }
   s.y := y1;
   e.x := x2;
   e.y := y2;
   viewc(s, curwin^.cs^.vp); { convert coordinates }
   viewc(e, curwin^.cs^.vp);
   clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
   if draw then line(screen, s.x, s.y, e.x, e.y, c)

end;
{ port: the plcchr/plcstr copies that were here duplicated the icdb layer
  versions and were removed at integration }
{**************************************************************

INITALIZE BUTTON ARRAY

Loads all the button descriptors into the button array.

**************************************************************}

procedure inibut;

var i: buttyp; { index for buttons }

{ set up single botton entry }

{ port: uiscl - interface pixel constants scaled to character cell }

procedure plcbut(ox, oy: integer;  { screen location }
                 st:     butstr;   { string }
                 ln:     btslen;   { port: was btsinx; may be 0 }
                 b:      buttyp;   { button code }
                 ms:     modset;   { applicable screen set }
                 caf:    color;    { "active" color foreground }
                 cab:    color;    { "active" color backround }
                 cif:    color;    { "inactive" color foreground }
                 cib:    color;    { "inactive" color backround }
                 lc:     loctyp;   { location }
                 t:      distyp;   { appearance }
                 fm:     formset); { placement format }

var w: integer;
    i: btsinx;

begin

   { find total pixel width of string }
   w := uiscl(11); { set margin width }
   for i := 1 to ln do w := w+chrwidth(st[i])+uiscl(1);
   with button[b] do begin

      r.s.x   := ox; { place origin }
      r.s.y   := oy;
      r.e.x   := ox+w-1; { place end }
      r.e.y   := oy+uiscl(23)-1;
      s   := st; { place button string }
      l   := ln; { place button length }
      m   := w;     { place minimum width }
      act := false; { set button inactive }
      dis := false; { set button not disabled }
      alt := false; { set not on alert }
      sm  := ms;    { set screen modes }
      acf := caf;   { set "active" color foreground }
      acb := cab;   { set "active" color backround }
      icf := cif;   { set "inactive" color foreground }
      icb := cib;   { set "inactive" color backround }
      loc := lc;    { set location }
      typ := t;     { appearance mode }
      fmt := fm     { placement mode }

   end

end;
   
begin   

   { clear unused buttons }
   for i := bnull to bdisplay do 
      begin button[i].r.s.x := 0; button[i].r.s.y := 0 end;
   { define right side buttons }
   plcbut(uiscl(909),  uiscl(156), 'In      ', 2, bin,
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);       
   plcbut(uiscl(936),  uiscl(156), 'Out     ', 3, bout,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);      
   plcbut(uiscl(916),  uiscl(131), 'Pan     ', 3, bpan,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(uiscl(982),  uiscl(131), 'Full    ', 4, bbound, 
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);    
   plcbut(uiscl(976),  uiscl(156), 'Back    ', 4, bback,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(915),  uiscl(181), 'A       ', 1, bviewa, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(181), 'B       ', 1, bviewb, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(964),  uiscl(181), 'C       ', 1, bviewc, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(988),  uiscl(181), 'D       ', 1, bviewd, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(160), 'E       ', 1, bviewe, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(160), 'F       ', 1, bviewf, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(160), 'G       ', 1, bviewg, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(160), 'H       ', 1, bviewh, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(905),  uiscl(206), 'Dots    ', 4, bdots,  
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []); 
   plcbut(uiscl(951),  uiscl(206), '+000.00M', 8, bdotsv, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);    
   plcbut(uiscl(915),  uiscl(232), 'A       ', 1, bdotsva, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(232), 'B       ', 1, bdotsvb,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(965),  uiscl(232), 'C       ', 1, bdotsvc,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(988),  uiscl(232), 'D       ', 1, bdotsvd,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(208), 'E       ', 1, bdotsve,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(208), 'F       ', 1, bdotsvf,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(208), 'G       ', 1, bdotsvg,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(208), 'H       ', 1, bdotsvh,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(904),  uiscl(257), 'Lines   ', 5, blines,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []); 
   plcbut(uiscl(951),  uiscl(257), '+000.00M', 8, blinev,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);   
   plcbut(uiscl(915),  uiscl(282), 'A       ', 1, blineva,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(282), 'B       ', 1, blinevb,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(965),  uiscl(282), 'C       ', 1, blinevc,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(988),  uiscl(282), 'D       ', 1, blinevd,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(256), 'E       ', 1, blineve,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(256), 'F       ', 1, blinevf,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(256), 'G       ', 1, blinevg,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(256), 'H       ', 1, blinevh,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(904),  uiscl(307), 'Undo    ', 4, bundo,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);     
   plcbut(uiscl(904),  uiscl(332), 'Redo    ', 4, bredo,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(899),  uiscl(357), 'Save    ', 4, bsaveb,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);    
   plcbut(uiscl(943),  uiscl(357), 'Cut     ', 3, bcutb,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(976),  uiscl(357), 'Paste   ', 5, bpasteb,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);   
   plcbut(uiscl(915),  uiscl(382), 'A       ', 1, bblka,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(382), 'B       ', 1, bblkb,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(964),  uiscl(382), 'C       ', 1, bblkc,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(989),  uiscl(382), 'D       ', 1, bblkd,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(352), 'E       ', 1, bblke,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(352), 'F       ', 1, bblkf,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(352), 'G       ', 1, bblkg,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(352), 'H       ', 1, bblkh,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(900),  uiscl(532), 'Del     ', 3, bdelete,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);   
   plcbut(uiscl(952),  uiscl(532), 'Rip     ', 3, bdeleten,   
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, []);   
   plcbut(uiscl(900),  uiscl(582), 'Up      ', 2, bup,        
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, [ftlnxt]);
   plcbut(uiscl(932),  uiscl(582), 'Dwn     ', 3, bdown,      
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(908),  uiscl(557), 'Mir     ', 3, birmir,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(986),  uiscl(532), '0       ', 1, bir0,       
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(997),  uiscl(557), '90      ', 2, bir90,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(982),  uiscl(582), '180     ', 3, bir180,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(962),  uiscl(557), '270     ', 3, bir270,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(967),  uiscl(657), 'Name    ', 4, bname,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]);     
   plcbut(uiscl(912),  uiscl(657), 'Trc     ', 3, btrace,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);    
   plcbut(uiscl(910),  uiscl(682), '        ', 8, bnamev,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, fld, [ftlnxt]);
   plcbut(uiscl(981),  uiscl(682), '000     ', 3, bnord,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(uiscl(907),  uiscl(707), 'Cel     ', 3, bplsym,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(uiscl(907),  uiscl(732), 'Psch    ', 4, bplsch,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(uiscl(981),  uiscl(708), 'Erc     ', 3, berc,       
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);      
   plcbut(uiscl(949),  uiscl(307), 'Snap    ', 4, bsnap,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(949),  uiscl(332), 'Any     ', 3, bany,       
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(uiscl(992),  uiscl(307), '45      ', 2, b45,        
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);       
   plcbut(uiscl(992),  uiscl(332), '90      ', 2, b90,        
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);       
   plcbut(uiscl(902),  uiscl(457), 'Line    ', 4, bline,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);     
   plcbut(uiscl(900),  uiscl(507), 'Bline   ', 5, bbline,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(941),  uiscl(457), 'Box     ', 3, bbox,       
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);      
   plcbut(uiscl(961),  uiscl(507), 'Bbox    ', 4, bbbox,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(903),  uiscl(482), 'Cir     ', 3, bcircle,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);   
   plcbut(uiscl(946),  uiscl(482), 'Arc     ', 3, barc,       
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(uiscl(979),  uiscl(457), 'Wire    ', 4, bwire,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]);     
   plcbut(uiscl(984),  uiscl(482), 'Bus     ', 3, bbus,       
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);      
   plcbut(uiscl(908),  uiscl(607), 'Junc    ', 4, bjunction,  
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]); 
   plcbut(uiscl(950),  uiscl(607), '+000.00M', 8, bjuncv,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(uiscl(908),  uiscl(632), 'Conn    ', 4, bconnect,   
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(uiscl(950),  uiscl(632), '+000.00M', 8, bconnv,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(uiscl(905),  uiscl(407), 'Text    ', 4, btext,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(951),  uiscl(407), '+000.00M', 8, btsizv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);     
   plcbut(uiscl(916),  uiscl(432), 'A       ', 1, btexta,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(432), 'B       ', 1, btextb,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(965),  uiscl(432), 'C       ', 1, btextc,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(989),  uiscl(432), 'D       ', 1, btextd,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(400), 'E       ', 1, btexte,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(400), 'F       ', 1, btextf,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(400), 'G       ', 1, btextg,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(400), 'H       ', 1, btexth,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   { layout specific buttons }
   plcbut(uiscl(896),  uiscl(560), 'Met 1   ', 5, bmet1,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(560), 'Vis     ', 3, bmet1vis,   
          [smlayout], black, lblue,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(576), 'Met 2   ', 5, bmet2,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(576), 'Vis     ', 3, bmet2vis,   
          [smlayout], black, lcyan,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(592), 'Poly    ', 4, bpoly,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(592), 'Vis     ', 3, bpolyvis,   
          [smlayout], black, lred,   black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(608), 'Via     ', 3, bvia,       
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(608), 'Vis     ', 3, bviavis,    
          [smlayout], black, gray,   black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(624), 'Cont    ', 4, bcont,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(624), 'Vis     ', 3, bcontvis,   
          [smlayout], white, black,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(640), 'Ndiff   ', 5, bndiff,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(640), 'Vis     ', 3, bndiffvis,  
          [smlayout], black, green,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(656), 'Pdiff   ', 5, bpdiff,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(656), 'Vis     ', 3, bpdiffvis,  
          [smlayout], black, magenta, black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(672), 'Nwell   ', 5, bnwell,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(672), 'Vis     ', 3, bnwellvis,  
          [smlayout], black, yellow, black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(688), 'Pwell   ', 5, bpwell,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(688), 'Vis     ', 3, bpwellvis,  
          [smlayout], black, brown,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(704), 'Ccut    ', 4, bccut,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(704), 'Vis     ', 3, bccutvis,   
          [smlayout], black, dwhite, black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(720), 'Insides ', 7, binsides,   
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(896),  uiscl(736), 'Place   ', 5, bplace,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(896),  uiscl(752), 'Drc     ', 3, bdrc,       
          [smlayout], black, lgreen, black, yellow, right, but, []);
   { simulator specific buttons }
   plcbut(uiscl(896),  uiscl(496), 'Dwave   ', 5, bdwave,     
          [smsimulate], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(896),  uiscl(512), 'Awave   ', 5, bawave,     
          [smsimulate], black, lgreen, black, yellow, right, but, []);
   { define top side buttons }
   plcbut(uiscl(256),  0,   'Symbol  ', 6, bsymbol,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(352),  0,   'Schemat ', 7, bschema,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);   
   plcbut(uiscl(464),  0, 'Layout  ', 6, blayout,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);   
   plcbut(uiscl(560),  0, 'Simulate', 8, bsimulate,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []); 
   plcbut(0,    uiscl(32), 'Load    ', 4, bload,  
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(uiscl(64),   uiscl(32), 'Save    ', 4, bsave,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(uiscl(128),  uiscl(32), '        ', 8, bfname,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(0,    uiscl(48), 'Newfile ', 7, bnew,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);      
   plcbut(uiscl(128),  uiscl(48), '        ', 8, bcname, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(0,    uiscl(64), 'Files   ', 5, bdisplay,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);  
   plcbut(uiscl(128),  uiscl(64), 'Newcell ', 7, bnewc,   
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(128),  uiscl(80), 'Print   ', 5, bprint,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(0,    uiscl(80), 'Cells   ', 5, bcells,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(0,    uiscl(96), 'Exit    ', 4, bexit,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(0,    uiscl(112), 'LAST    ', 4, blast,   
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(64),   uiscl(112), 'NEXT    ', 4, bnext,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(32), '        ', 8, blibv,    
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(48), '        ', 8, bliba, 
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(64), '        ', 8, blibb,  
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(80), '        ', 8, blibc,  
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(96), '        ', 8, blibd,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(32), '        ', 8, bcelv,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(48), '        ', 8, bcela,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(64), '        ', 8, bcelb,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(80), '        ', 8, bcelc,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(96), '        ', 8, bceld,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(16), 'Proximty', 8, bprox,      
          [{smschema, smsymbol, smlayout, smsimulate}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(512),  uiscl(32), 'Nmos    ', 4, bnmos,      
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(592),  uiscl(32), 'Pmos    ', 4, bpmos,      
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(512),  uiscl(48), 'Res     ', 3, bres,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(560),  uiscl(48), 'Cap     ', 3, bcap,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(608),  uiscl(48), 'Diode   ', 5, bdiode,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(512),  uiscl(64), 'Vdd     ', 3, bvdd,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(592),  uiscl(64), 'Vss     ', 3, bvss,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(651),  uiscl(52), 'Ruler   ', 5, bruler,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);    
   plcbut(uiscl(703),  uiscl(52), '+000.00M', 8, brulerv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(651),  uiscl(77), '    X   ', 5, brulx,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(703),  uiscl(77), '+000.00M', 8, brulxv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(651),  uiscl(102), '    Y   ', 5, bruly,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(703),  uiscl(102), '+000.00M', 8, brulyv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(771),  uiscl(10), 'Pos X   ', 5, bcposx,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(10), '+000.00M', 8, bcposxv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(31), '    Y   ', 5, bcposy,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(31), '+000.00M', 8, bcposyv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(52), 'Org X   ', 5, borgx,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(52), '+000.00M', 8, borgxv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(77), '    Y   ', 5, borgy,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(77), '+000.00M', 8, borgyv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(102), 'Scale   ', 5, bscl,       
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(102), '00000   ', 8, bsclv,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(16), 'Rul time', 8, brtime,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(16), '+000.00M', 8, brtimev,   
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(32), 'Rul volt', 8, brvolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(32), '+000.00M', 8, brvoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(48), 'Pos time', 8, bctime,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(48), '+000.00M', 8, bctimev,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(64), 'Pos volt', 8, bcvolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(64), '+000.00M', 8, bcvoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(80), 'Org time', 8, botime,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(80), '+000.00M', 8, botimev,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(96), 'Org volt', 8, bovolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(96), '+000.00M', 8, bovoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   { buttons for printer control pop-up }
   plcbut(uiscl(448),  uiscl(416), '+000.00M', 8, bmaxx,      
          [smprint], black, lgreen, black, yellow, none, fld, []);      
   plcbut(uiscl(448),  uiscl(432), '+000.00M', 8, bmaxy,  
          [smprint], black, lgreen, black, yellow, none, fld, []); 
   plcbut(uiscl(448),  uiscl(448), '+000.00M', 8, boffx,   
          [smprint], black, lgreen, black, yellow, none, fld, []);
   plcbut(uiscl(448),  uiscl(464), '+000.00M', 8, boffy,   
          [smprint], black, lgreen, black, yellow, none, fld, []); 
   plcbut(uiscl(448),  uiscl(544), 'A       ', 1, bseta, 
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(464),  uiscl(544), 'B       ', 1, bsetb,   
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(480),  uiscl(544), 'C       ', 1, bsetc,  
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(496),  uiscl(544), 'D       ', 1, bsetd,     
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(512),  uiscl(544), 'E       ', 1, bsete,    
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(528),  uiscl(544), 'F       ', 1, bsetf,    
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(544),  uiscl(544), 'G       ', 1, bsetg,   
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(560),  uiscl(544), 'H       ', 1, bseth,  
          [smprint], black, lgreen, black, yellow, none, but, []); 
   plcbut(0,    0,   '        ', 0, bmbtop,    
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbleft,   
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbright,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbottom, 
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtoplt,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtopll,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtoprt,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtoprr,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotlb,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotll,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotrb,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotrr,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bctrl,     
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmovew,    
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmin,      
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmax,      
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 

end;
{}
{**************************************************************

PLACE MOVE BUTTONS

Places the location of the move buttons for the present
window, and initalizes these buttons.

**************************************************************}

procedure plcmovb;

{ set up single botton entry }

procedure plcbut(b:              buttyp;   { button to place }
                 x1, y1, x2, y2: integer); { button rectangle }

begin

   with button[b] do begin

      r.s.x   := x1; { place origin }
      r.s.y   := y1;
      r.e.x   := x2; { place end }
      r.e.y   := y2

   end

end;

begin

   { port: uiscl - interface pixel constants scaled to character cell }
   plcbut(bmbtop,    curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.s.y,
                     curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.s.y+uiscl(2+5)-1);
   plcbut(bmbleft,   curwin^.wv.r.s.x,       curwin^.wv.r.s.y+uiscl(25),
                     curwin^.wv.r.s.x+uiscl(2+5)-1, curwin^.wv.r.e.y-uiscl(25));
   plcbut(bmbright,  curwin^.wv.r.e.x-uiscl(2+5)+1, curwin^.wv.r.s.y+uiscl(25),
                     curwin^.wv.r.e.x,       curwin^.wv.r.e.y-uiscl(25));
   plcbut(bmbbottom, curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.e.y-uiscl(2+5)+1,
                     curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.e.y);
   plcbut(bmbtoplt,  curwin^.wv.r.s.x,       curwin^.wv.r.s.y,
                     curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.s.y+uiscl(2+5)-1);
   plcbut(bmbtopll,  curwin^.wv.r.s.x,       curwin^.wv.r.s.y,
                     curwin^.wv.r.s.x+uiscl(2+5)-1, curwin^.wv.r.s.y+uiscl(25));
   plcbut(bmbtoprt,  curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.s.y,
                     curwin^.wv.r.e.x,       curwin^.wv.r.s.y+uiscl(2+5)-1);
   plcbut(bmbtoprr,  curwin^.wv.r.e.x-uiscl(2+5)+1, curwin^.wv.r.s.y,
                     curwin^.wv.r.e.x,       curwin^.wv.r.s.y+uiscl(25));
   plcbut(bmbbotlb,  curwin^.wv.r.s.x,       curwin^.wv.r.e.y-uiscl(2+5)+1,
                     curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.e.y);
   plcbut(bmbbotll,  curwin^.wv.r.s.x,       curwin^.wv.r.e.y-uiscl(25),
                     curwin^.wv.r.s.x+uiscl(2+5)-1, curwin^.wv.r.e.y);
   plcbut(bmbbotrb,  curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.e.y-uiscl(2+5)+1,
                     curwin^.wv.r.e.x,       curwin^.wv.r.e.y);
   plcbut(bmbbotrr,  curwin^.wv.r.e.x-uiscl(2+5)+1, curwin^.wv.r.e.y-uiscl(25),
                     curwin^.wv.r.e.x,       curwin^.wv.r.e.y);
   plcbut(bctrl,     curwin^.wv.r.s.x+uiscl(2+5+2),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.s.x+uiscl(2+5+2+19)-1,
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);
   plcbut(bmovew,    curwin^.wv.r.s.x+uiscl(2+5+2+19+2),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.e.x-uiscl(29+19)-uiscl(2)-1,
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);
   plcbut(bmin,      curwin^.wv.r.e.x-uiscl(29+19),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.e.x-uiscl(29)-1,
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);
   plcbut(bmax,      curwin^.wv.r.e.x-uiscl(29)+uiscl(2),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.e.x-uiscl(2+5+2),
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);

end;
{}
{**************************************************************

ARRANGE BUTTONS TOP

Arranges the buttons for the current window. Called after
a window size change.

**************************************************************}

{ port: uiscl - button cell height/spacing scaled to character cell
  (also marginr/tfit/arrbutr/adjlin below) }

procedure arrbutt(lm, tm, rm, bm: integer); { margins }

var b:    buttyp;  { button index }
    x, y: integer; { screen indexes }

begin

   x := lm; { find position of 1st button }
   y := tm;
   b := succ(bnull); { index 1st button }
   while b <> bnull do begin { while valid buttons to place }

      if ((curscm - [smprint]) * button[b].sm <> []) and
         (button[b].loc = top) then begin

         if x+button[b].m > rm then begin

            { overflow, next line }
            x := lm; { reset collumn to start }
            y := y+uiscl(23)+uiscl(1+2); { next row }       
            if y > bm then begin { error, overflow }

               writeln('Error: window overflow');
               while true do

            end

         end;
         button[b].r.s.x := x; { set button position }
         button[b].r.s.y := y;
         button[b].r.e.x := x+button[b].m;
         button[b].r.e.y := y+uiscl(23);
         x := x+button[b].m+uiscl(1+2) { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end;
   y := y+uiscl(23); { next row }
   { find proper margin }
   curwin^.tm.s.x := lm;   
   curwin^.tm.s.y := tm;
   curwin^.tm.e.x := rm;
   curwin^.tm.e.y := y
   
end;
{}
{**************************************************************

SET MARGIN RIGHT

Sets the minimum margin for the right menu.

**************************************************************}

procedure marginr(rm, tm, bm, lm: integer); { margins }

var mm:   integer; { minimum margin }
    b:    buttyp;  { button index }
    fg:   boolean; { fit good flag }
    nm:   integer; { minimum move distance }
    l:    integer; { button length }
    b1:   buttyp;  { button index }

{ perform trial fit }

procedure tfit;

var b:    buttyp;  { button index }
    x, y: integer; { screen indexes }
    t:    integer;
    o:    boolean; { overflow flag }
    b1:   buttyp;  { button index }
    x1:   integer; { index }
    l:    integer; { button length }

begin

   fg := true; { set fit ok }
   nm := maxint; { set no minimum move }
   x := rm-mm; { find position of 1st button }
   y := tm;
   b := succ(bnull); { index 1st button }
   while b <> bnull do begin { while valid buttons to place }

      if ((curscm - [smprint]) * button[b].sm <> []) and
         (button[b].loc = right) then begin

         l := button[b].m; { set length of button }
         o := x+button[b].m > rm;
         if (ftlnxt in button[b].fmt) and not o then begin 

            { check next linkage }
            x1 := x; { get copy x }
            b1 := b; { get copy button }
            repeat

               x1 := x1+button[b1].m+uiscl(1+2); { find next button position }
               b1 := succ(b1);
               l := l+button[b1].m+uiscl(1+2); { find virtual button length }
               if x1+button[b1].m > rm then o := true { test overflow }

            until not (ftlnxt in button[b1].fmt) { no more linkage }
            
         end;
         if o then begin

            { overflow, next line }
            { find minimum n }
            t := l-(rm-x);
            if t < nm then 
               nm := t; { set minimum }
            x := rm-mm; { reset collumn to start }
            y := y+uiscl(23)+uiscl(1+2); { next row }       
            if y+uiscl(23)+uiscl(1+2) > bm then begin 

               { overlow, end }
               fg := false; { set bad fit }
               b := bnull

            end

         end;
         x := x+button[b].m+uiscl(1+2) { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end
   
end;

begin

   { search for initial minimum margin }
   mm := 0; { clear minimum }
   { find maximum button applicable button width }
   for b := succ(bnull) to bdisplay do
      if ((curscm - [smprint]) * button[b].sm <> []) and 
         (button[b].loc = right) then begin

      l := button[b].m; { set length of button }
      if ftlnxt in button[b].fmt then begin 

         { check next linkage }
         b1 := b; { get copy button }
         repeat

            b1 := succ(b1);
            l := l+button[b1].m+uiscl(1+2) { find virtual button length }

         until not (ftlnxt in button[b1].fmt) { no more linkage }
            
      end;
      if l > mm then mm := l

   end;
   repeat

      tfit; { try trail fit at this size }
      if not fg then mm := mm+nm; { find new margin }
      if rm-mm < lm then begin { error, overflow }

         writeln('Error: window overflow');
         while true do

      end

   until fg; { fit is good }
   { find proper margin }
   curwin^.rm.s.x := rm-mm;   
   curwin^.rm.s.y := tm;
   curwin^.rm.e.x := rm;
   curwin^.rm.e.y := bm
   
end;
{}
{**************************************************************

ARRANGE BUTTONS RIGHT

Arranges the buttons for the current window. Called after
a window size change.

**************************************************************}

procedure arrbutr; { margins }

var b:    buttyp;  { button index }
    fb:   buttyp;  { first button on line }
    bc:   integer; { buttons on line count }
    x, y: integer; { screen indexes }
    xl:   integer; { screen index for line }
    o:    boolean; { overflow flag }
    b1:   buttyp;  { button index }
    x1:   integer; { index }

{ adjust line }

procedure adjlin;

var i:   integer;
    al:  integer; { adjustment length }
    rmd: integer; { adjustment remainder }
    add: integer; { addition holder }

begin

   al := (curwin^.rm.e.x-(x-uiscl(1+2))) div bc; { find adjustment length }
   rmd := (curwin^.rm.e.x-(x-uiscl(1+2))) mod bc; { find adjustment remainder }
   for i := 1 to bc do begin { proportion button spacing }

      { distribute remainder among buttons, starting left }
      if rmd <> 0 then begin add := 1; rmd := rmd-1 end
      else add := 0;
      button[fb].r.s.x := xl; { set button position }
      button[fb].r.s.y := y;
      button[fb].r.e.x := xl+button[fb].m+al+add;
      button[fb].r.e.y := y+uiscl(23);
      { find next button position }
      xl := xl+button[fb].m+al+add+uiscl(1+2);
      repeat if fb <> bdisplay then fb := succ(fb) { next button }
      until (((curscm - [smprint]) * button[fb].sm <> []) and
            (button[fb].loc = right)) or
            (fb = bdisplay)

   end

end;

begin

   x := curwin^.rm.s.x; { find position of 1st button }
   y := curwin^.rm.s.y;
   b := succ(bnull); { index 1st button }
   fb := b; { set first button on line }
   bc := 1; { count }
   xl := x; { set first on line index }
   while b <> bnull do begin { while valid buttons to place }

      if ((curscm - [smprint]) * button[b].sm <> []) and
         (button[b].loc = right) then begin

         o := x+button[b].m > curwin^.rm.e.x;
         if (ftlnxt in button[b].fmt) and not o then begin 

            { check next linkage }
            x1 := x; { get copy x }
            b1 := b; { get copy button }
            repeat

               x1 := x1+button[b1].m+uiscl(1+2); { find next button position }
               b1 := succ(b1);
               if x1+button[b1].m > curwin^.rm.e.x then o := true { test overflow }

            until not (ftlnxt in button[b1].fmt) { no more linkage }
            
         end;
         if o then begin

            { overflow, next line }
            { justify buttons on last line }
            bc := bc - 1; { remove last button from line }
            adjlin; { adjust line }
            fb := b; { set first button on line }
            x := curwin^.rm.s.x; { reset collumn to start }
            y := y+uiscl(23)+uiscl(1+2); { next row }       
            xl := x; { set first on line index }
            bc := 1 { set first count }

         end;
         bc := bc + 1; { count buttons on line }
         x := x+button[b].m+uiscl(1+2) { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end;
   bc := bc - 1; { back out last count }
   if bc <> 0 then adjlin { adjust last line }
   
end;
{}
{**************************************************************

PLACE VECTOR CHARACTER 

Draws a single character in vector form. The characters were
planned on a 4x8 grid, with upper left as 0,0. They may be
scaled to any given size. 
Obviously, there is a minimum size possible to give reasonable
representation.

**************************************************************}

procedure vchar(x, y: integer; { location (real space) }
                c:    char;    { character to place }
                s:    integer; { scale factor (real units) }
                cl:   color;   { color }
                r:    boolean; { rotate 90 deg }
                cr:   region); { clip region (screen space, unused:
                                 the drawing subwindow clips } 

{ port: the original drew each glyph as line strokes on a 4x11 unit
  grid (the 1993 vector font). Glyphs are rendered with the Ami sign
  (sans-serif) scalable font, sized to the character cell as it
  appears on screen, so all metrics (pitch, bounds, cursor math,
  stored .cel enclosure boxes) are unchanged. The 90 degree case uses
  the Ami path() api (angle in circle units, maxint = full circle;
  the default path is maxint div 4 = normal upright text).

  Sheet text draws into the drawing subwindow, which Ami clips at its
  bounds automatically - a glyph partially outside the drawing area
  is clipped by the window system, so no region clipping is needed
  here. }

var h0: integer;     { interface font height }
    w:  integer;     { rendered glyph width }
    hs: integer;     { screen cell height }
    s1, e1: point;   { character cell, converted to screen }
    sc: packed array [1..1] of char; { measurement holder }

begin

   if subon then begin { drawing subwindow exists }

      { find the character cell in real space }
      s1.x := x;
      s1.y := y;
      if r then begin

         e1.x := x+chrhdt*s;
         e1.y := y+(chrwdt+chrspc)*s

      end else begin

         e1.x := x+(chrwdt+chrspc)*s;
         e1.y := y+chrhdt*s

      end;
      { convert to screen coordinates }
      viewc(s1, curwin^.cs^.vp);
      viewc(e1, curwin^.cs^.vp);
      { skip when the cell misses the subwindow entirely }
      if (e1.x >= subr.s.x) and (s1.x <= subr.e.x) and
         (e1.y >= subr.s.y) and (s1.y <= subr.e.y) then begin

         { find cell height as displayed }
         if r then hs := e1.x-s1.x else hs := e1.y-s1.y;
         if hs > 1 then begin { skip degenerate sizes }

            h0 := graphics.chrsizy; { interface font height }
            graphics.fontsiz(subout, hs); { scale to the cell height }
            setfcolorf(subout, cl);
            sc[1] := c; { find glyph width at this size }
            w := graphics.strsiz(subout, sc);
            { rebase to subwindow coordinates }
            s1.x := s1.x-subr.s.x+1;
            s1.y := s1.y-subr.s.y+1;
            e1.x := e1.x-subr.s.x+1;
            e1.y := e1.y-subr.s.y+1;
            if r then begin { rotated 90 degrees }

               graphics.path(subout, 0);
               { center the glyph across the rotated cell }
               graphics.cursorg(subout, s1.x,
                                s1.y + ((e1.y-s1.y) - w) div 2);
               write(subout, c);
               { restore normal }
               graphics.path(subout, maxint div 4)

            end else begin

               { center the glyph on the stroke cell (chrwdt of the
                 chrwdt+chrspc pitch) }
               graphics.cursorg(subout, s1.x +
                  ((e1.x-s1.x)*chrwdt div (chrwdt+chrspc) - w) div 2,
                  s1.y);
               write(subout, c)

            end;
            { restore the interface font size }
            graphics.fontsiz(subout, h0)

         end

      end

   end

end;
{}
{**************************************************************

CONVERT INTEGER

Convert unsigned integer to string.
Note: only converts an 8 digit number.

**************************************************************}

procedure intstr(n: integer; var s: butstr);

var i: btsinx; { index for string }
    p: integer;

begin

   s := '        '; { clear target string }
   for i := 1 to 8 do begin { extract digits }

      case i of { power }
    
         1: p := 10000000;
         2: p := 1000000;
         3: p := 100000;
         4: p := 10000;
         5: p := 1000;
         6: p := 100;
         7: p := 10;
         8: p := 1

      end;
      s[i] := chr(n div p + ord('0')); { extract that digit }
      n := n mod p { remove digit }

   end
   
end;
{}
{**************************************************************

ELIMINATE LEADING SPACES

Erases leading spaces in a number string.

**************************************************************}

procedure trmzer(var s: butstr);

var i: btsinx; { index for string }

begin

   i := 1; { set 1st character }
   repeat

      if s[i] = '0' then begin 

         s[i] := ' '; { clear digit }
         i := i + 1 { next digit }

      end else i := butlen

   until i = butlen { end of string }
   
end;
{}
{**************************************************************

CONVERT REAL

Convert real to string. The resulting format is:

   999.000xx to 1.000xx where "xx" is um, cm, dm etc.

Note that we should never really have to represent 1 meter and
above (but 1-999m was included anyways).

**************************************************************}

procedure realstr(r: real; var s: butstr);

var ec:  packed array [1..13] of char;
    e:   1..13;
    n:   integer;
    i:   btsinx;
    sgn: char; { sign character }

begin

   sgn := ' '; { set not signed }
   if r < 0.0 then begin { signed }

      sgn := '-'; { set signed }
      r := -r { convert to positive }

   end;
   ec := 'EPTGMk munpfa'; { set exponent characters }
   ec[9] := chr(microchr); { set special for micro }
   e := 7; { intialize exponent }
   r := r * 1000; { scale to our decimal point }
   { scale downwards (done in two parts to avoid integer
     accuracy limits) }
   while r >= 1000000000 do begin r := r / 1000; e := e-1 end;
   while round(r) >= 1000000 do begin r := r / 1000; e := e-1 end;
   { scale upwards }
   if r <> 0 then
      while round(r) < 1000 do begin r := r * 1000; e := e+1 end;
   n := round(r); { scale for decimal placement }
   intstr(n, s); { convert }
   trmzer(s); { eliminate zeros }
   for i := 2 to 4 do s[i] := s[i+1]; { move 1st part of number }
   if s[7] <> ' ' then s[5] := '.'; { place decimal }
   { preserve 0 case }
   if (s[7] = ' ') and (s[8] = '0') then s[7] := '0';
   s[8] := ec[e]; { place exponent }
   s[1] := sgn { place sign }

end; 
{}
{**************************************************************

PERFORM EDIT FUNCTION

Performs the given edit character on a screen displayed screen.
The routine is pretty much self contained. To activate the edit,
(and lay down the inital cursor), call with a null character.
To terminate the edit, call with return.
The following controls are implemented:

   <left arrow>  - move cursor left
   <right arrow> - move cursor right
   home          - move cursor to line start 
   end           - move cursor to line end
   <backspace>   - delete last character
   del           - delete next character
   ins           - clear string and home cursor
   enter         - terminate edit

**************************************************************}

procedure edit(var b:  butrec; { button to edit }
               var p:  btslen; { port: was btsinx; edit drives to 0 }
                   c:  char;   { primary input character }
                   cs: char);  { secondary input character }  

var i: btsinx;
    cx, cy1, cy2: integer; { port: edit cursor pixel coordinates }

begin

   if errmsg then plcmsg(mnone, yellow); { clear error message }
   if c in ['A'..'Z', 'a'..'z', '0'..'9', '.', ' '] then begin

      { insert normal character }
      if (p <> b.l) and (b.s[b.l] = ' ') then 
         begin { line not full }

         { move characters right to make space }
         for i := b.l downto p+2 do
            b.s[i] := b.s[i-1];
         p := p + 1; { move cursor right }
         b.s[p] := c { place character }

      end
      
   end else if c = chr(8) then begin

      { backspace (erase last) }
      if p <> 0 then begin { not already at left }
  
         { move characters left to gap }
         for i := p to b.l-1 do b.s[i] := b.s[i+1]; 
         b.s[b.l] := ' '; { clear last character }
         p := p - 1 { move cursor left }

      end         

   end else if (c = chr(0)) and (cs = chr(83)) then begin

      if p <> b.l then begin { not at extreme right }

         { delete (erase next) }
         { move characters left to gap }
         for i := p+1 to b.l-1 do b.s[i] := b.s[i+1]; 
         b.s[b.l] := ' ' { clear last character }

      end

   end else if (c = chr(0)) and (cs = chr(75)) then begin

      { left arrow }
       if p > 0 then p := p - 1 { move cursor left }

   end else if (c = chr(0)) and (cs = chr(77)) then begin

      { right arrow }
      if p < b.l then p := p + 1 { move cursor right }

   end else if (c = chr(0)) and (cs = chr(71)) then begin

      { home }
      p := 0 { set cursor to left side }
      
   end else if (c = chr(0)) and (cs = chr(79)) then begin

      { end }
      p := b.l { set cursor to right side }

   end else if (c = chr(0)) and (cs = chr(82)) then begin

      { insert (clear) }
      b.s := '        '; { clear string }
      p := 0 { set cursor to left side }

   end;
   rescur; { reset cursor }
   if true{b.sel} and (c = chr(13)) then { update button }
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, yellow, true)
   else 
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, b.icb, true);
   if c <> chr(13) then begin { not end, replace cursor }

      { port: the original positioned the edit cursor with b.r.s.x*16
        cell math, treating the button's pixel origin as a character
        cell (pre-existing source damage - the cursor drew off screen).
        The cursor x is now the button text origin plus the proportional
        pixel width of the characters left of the cursor, matching how
        plcstr lays the string out; y spans the button cell }
      cx := b.r.s.x+uiscl(7)+strwidth(b.s, p); { text margin + prefix }
      cy1 := b.r.s.y+uiscl(1);
      cy2 := b.r.s.y+uiscl(23)-1-1;
      if p = 0 then begin { draw left side cursor }

         line(screen, cx+1, cy1, cx+1, cy2, lmagenta);
         line(screen, cx+2, cy1, cx+2, cy2, lmagenta)

      end else if p = b.l then begin { draw right side cursor }

         line(screen, cx-1, cy1, cx-1, cy2, lmagenta);
         line(screen, cx, cy1, cx, cy2, lmagenta)

      end else begin { draw between characters cursor }

         line(screen, cx-1, cy1, cx-1, cy2, lmagenta);
         line(screen, cx, cy1, cx, cy2, lmagenta)

      end

   end;
   setcur { replace cursor }

end;
{}
{**************************************************************

BEGIN BUTTON EDIT

Begins an edit on the given button.

**************************************************************}

procedure edtbut(var b: butrec);

var i: integer;

begin

   { set cursor position based on where cross cursor landed }
   i := cur.x - b.r.s.x; { find dot offset of cursor }
   edtpos := i div 16; { find character offset }
   if (i mod 16) > 8 then edtpos := edtpos + 1; { round up }
   edit(b, edtpos, chr(0), chr(0))

end;
{}
{**************************************************************

GET INTEGER

Reads and converts the decimal numeric in the given string.
Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getint(var b:   butrec;   { button to parse }
                 var n:   integer;  { returned value }
                 var err: boolean); { error status }

var i:   btsinx;  { current position in string }
    e:   boolean; { end of string flag }

function chkchr: char; { check next character }

begin

   if e then chkchr := ' ' { at end }
   else chkchr := b.s[i]

end;

procedure getchr; { get next character }

begin

   if i <> b.l then i := i + 1 { advance } 
   else e := true { set end }

end;

procedure skpspc; { skip spaces }

begin

   while not e and (chkchr = ' ') do getchr { skip spaces }

end;

begin

   i := 1; { set 1st character }
   e := false; { set not end }
   err := false; { set no error }
   n := 0; { initalize number }
   skpspc; { skip leading spaces }
   { check any digits }
   while chkchr in ['0'..'9'] do begin

      { check overflow }
      if n > maxint div 10 - 10 then begin err := true; n := 0 end;
      n := n * 10; { scale }
      n := n + ord(chkchr) - ord('0'); { add new digit }
      getchr { next }

   end;
   if err then plcmsg(movfn, lred) { overflow occurred }
   else begin

      skpspc; { skip trailing spaces }
      if chkchr <> ' ' then begin 

         plcmsg(minvn, lred); { invalid integer }
         err := true { flag error }

      end

   end;
   if err then begin { highlight position of error }

      rescur; { reset cursor }
      { set button back to normal }
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, b.icb, true);
      plcchr((b.r.s.x+(i*16)-16), b.r.s.y, b.s[i], black, lred, black, 
             i = 1, i = b.l);
      setcur { replace cursor }

   end

end;
{}
{**************************************************************

GET REAL

Reads and converts the decimal numeric at the command line
position. Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getrnm(var b:   butrec;   { button to parse from }
                 var n:   real;     { returned value }
                 var err: boolean); { error flag }

label 99; { terminate on error }

var dp:  boolean; { decimal point flag }
    p:   real;    { scaling factor }
    i:   btsinx;  { current position in string }
    e:   boolean; { end of string flag }
    c:   char; 
    sgn: real;    { sign }

function chkchr: char; { check next character }

begin

   if e then chkchr := ' ' { at end }
   else chkchr := b.s[i]

end;

procedure getchr; { get next character }

begin

   if i <> b.l then i := i + 1 { advance } 
   else e := true { set end }

end;

procedure skpspc; { skip spaces }

begin

   while not e and (chkchr = ' ') do getchr { skip spaces }

end;

begin

   i := 1; { set 1st character }
   e := false; { set not end }
   n := 0.0; { initalize number }
   p := 1.0; { set scaling factor }
   dp := false; { set decimal point not scanned }
   sgn := 1.0; { set positive sign }
   err := false; { set no error }
   skpspc; { skip spaces }
   { check any signs }
   if chkchr = '+' then getchr { skip }
   else if chkchr = '-' then begin { negative }

      sgn := -1.0;
      getchr { skip }

   end;
   { check any digits }
   if not (chkchr in ['0'..'9', '.']) then 
      begin plcmsg(minvn, lred); err := true; goto 99 end;
   while chkchr in ['0'..'9', '.'] do begin

      if chkchr = '.' then begin { decimal point }

         if dp then { decimal point already passed }
            begin plcmsg(minvn, lred); err := true; goto 99 end;
         getchr; { skip '.' }
         dp := true { set decimal passed }

      end else begin { parse digit }

         if dp then begin { after decimal point }

            p := p / 10.0; { find next scale }
            n := n + (p * (ord(chkchr) - ord('0'))) { add new digit }

         end else begin { before decimal point }

            n := n * 10.0; { scale }
            n := n + ord(chkchr) - ord('0') { add new digit }

         end;
         getchr { next }

      end

   end;
   c := chkchr; { get next }
   { convert micro character }
   if c = chr(microchr) then c := 'u';
   if c in ['a', 'f', 'p', 'n', 'u', 'm', 'k', 'M', 'G', 'T',
            'P', 'E'] then
      case c of

      'a': begin n := n * 1e-18; getchr end; { atto }
      'f': begin n := n * 1e-15; getchr end; { femto }
      'p': begin n := n * 1e-12; getchr end; { pico }
      'n': begin n := n * 1e-9;  getchr end; { nano }
      'u': begin n := n * 1e-6;  getchr end; { micro }
      'm': begin n := n * 1e-3;  getchr end; { mili }
      'k': begin n := n * 1e+3;  getchr end; { kilo }
      'M': begin n := n * 1e+6;  getchr end; { mega }
      'G': begin n := n * 1e+9;  getchr end; { giga }
      'T': begin n := n * 1e+12; getchr end; { tera }
      'P': begin n := n * 1e+15; getchr end; { peta }
      'E': begin n := n * 1e+18; getchr end  { exa }

   end;
   n := n * sgn; { establish sign }
   skpspc; { skip spaces }
   if chkchr <> ' ' then { invalid format } 
      begin plcmsg(minvn, lred); err := true; goto 99 end;

   99: { error }

   if err then begin { highlight position of error }

      rescur; { reset cursor }
      { set button back to normal }
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, b.icb, true);
      plcchr((b.r.s.x+(i*16)-16), b.r.s.y, b.s[i], black, lred, black, 
             i = 1, i = b.l);
      setcur { replace cursor }

   end

end;
{}
{ UNRESOLVED: identifiers referenced by this fragment but defined
  elsewhere:

  From the base layer (hand-written adapter in icdui.pas):

     plchr      - place single character (replaces bitmap setchr)
     chrwidth   - character pixel width (replaces alphal[])
     chrheight  - character pixel height (replaces constant 16)

  From the ported icdb.pas fragment (appears before this one):

     viewc      - convert real point to screen point (used by liner)
     clip       - Cohen-Sutherland line clipper (used by liner)
     line       - viewport level line draw
     block      - viewport level filled block draw
     setpix     - viewport level set pixel
     setcur     - draw cursor into place (used by edit/getint/getrnm)
     rescur     - remove cursor (used by edit/getint/getrnm)

  From other fragments (icdc.pas port):

     plcmsg     - place message string (used by edit/getint/getrnm)

  From icddef (types and globals, all assumed visible):

     color, region, point, viewport, buttyp, butrec, butstr,
     btsinx, modset, formset, loctyp, distyp, msgtyp, button,
     curwin, screen, curscm, cur, edtpos, errmsg, blank,
     chrwdt, chrhdt, scalem, butlen, microchr

  Notes:

  - No keyboard externals are referenced: edit/edtbut take the
    already-read character(s) as parameters in the original code,
    so no uigetchar/uicharrdy hooks were needed.
  - elapsed/wait were not ported (spec rule 5); no ported routine
    in this fragment called wait.
  - getlst/entnam (DOS intdos directory search) and resptr (puck
    hardware) were not ported. }
{******************************************************************************

FRAGMENT D: WINDOW MANAGEMENT AND VIEW NAVIGATION

Ported from icdc.pas. Contains the window layout engine, view
navigation (zoom/pan/ruler/bounds), grid drawing, sheet and cell
display control, and assorted math helpers.

Port notes:

1. Save-under logic (boxsav/boxrst) is replaced by xor rubber-banding
   per the conversion spec; the linarr/lininx save buffer parameters
   are deleted. boxrst gains the color parameter so it can redraw the
   identical figure in xor mode.
2. Obvious source damage in the original (missing '^.ds'/'^.ls' field
   selections in the grid routines, 'wp^.r' for 'wp^.wv.r', stray
   braces after dispose calls, 'curwin^.wv.cr' for 'curwin^.cr') is
   repaired mechanically; each repair is marked with a "port:" comment.
3. Figure rendering (drwfig/drwfigs) is deferred to a later phase and
   stubbed with "port: cell drawing deferred" comments.

******************************************************************************}

{ port: the var vp frame version that was here was a duplicate of the
  frame in the icdb layer and has been removed at integration }

{ box draw with save }
{ port: save-under replaced by xor rubber-banding; linarr index
  parameter deleted. The box is drawn in xor mode, and boxrst
  removes it by drawing the identical box in xor mode again }

procedure boxsav(x1, y1, x2, y2: integer; c: color);

begin

   xormode; { enter xor mode }
   { draw box outline, screen coordinates }
   scrline(x1, y1, x2, y1, c);
   scrline(x2, y1, x2, y2, c);
   scrline(x2, y2, x1, y2, c);
   scrline(x1, y2, x1, y1, c);
   ovrmode { return to overwrite mode }

end;
{}
{ box restore }
{ port: pixel restore replaced by identical xor redraw; linarr index
  parameter deleted, color parameter added (must match the boxsav
  draw color) }

procedure boxrst(x1, y1, x2, y2: integer; c: color);

begin

   xormode; { enter xor mode }
   { redraw identical box outline, screen coordinates }
   scrline(x1, y1, x2, y1, c);
   scrline(x2, y1, x2, y2, c);
   scrline(x2, y2, x1, y2, c);
   scrline(x1, y2, x1, y1, c);
   ovrmode { return to overwrite mode }

end;
{}
{**************************************************************

FIND TRUE DISTANCE

Finds the direct line distance between two points.

**************************************************************}

function dist(x1, y1, x2, y2: integer): integer;

var xr1, yr1, xr2, yr2: real; { precision holders }

begin

   xr1 := x1; { place parameters in holding }
   yr1 := y1;
   xr2 := x2;
   yr2 := y2;
   dist := round(sqrt(sqr(abs(xr2-xr1))+sqr(abs(yr2-yr1))))

end;
{}
{**************************************************************

FIND ANGLE OF VECTOR

Given a vector, gives the angle of incidence, considering the
first point as the center point.
The angle is clockwise, with 0 as up.

**************************************************************}

function angle(x1, y1, x2, y2: integer): real;

var a: real;

begin

   if y2 = y1 then a := pi/2 { 90 deg }
   else a := arctan(abs(x2-x1)/abs(y2-y1)); { find base angle }
   if x2 > x1 then begin { in right hand half }

      if y2 > y1 then a := pi - a { move to lower right hand quadrant }

   end else begin { in left hand half }

      if y2 > y1 then a := a + pi { move to lower left hand quadrant }
      else a := 2*pi - a { move to upper left hand quadrant }

   end;
   angle := a { return final angle }

end;
{}
{**************************************************************

FIND ANGULAR DIFFERENCE

Finds the shortest angular difference between the given
angles.

**************************************************************}

function angdif(a, b: real): real;

var t: real;
    s: integer;

begin

   s := 1; { set sign }
   { swap to lower }
   if a > b then begin t := a; a := b; b :=  t; s := -s end;
   if b > (a+pi) then b := b - 2*pi; { adjust upper }
   angdif := (b-a)*s { place result }

end;
{}
{**************************************************************

FIND CIRCLE CENTER

Given three points on a circle, will find the center of that
circle.
Note: unfortunately, I thought the answer to this one up
myself.

**************************************************************}

procedure center(x1, y1, x2, y2, x3, y3: integer; { the three points }
                 var xc, yc: integer); { the center }

var an, ana, anb: real;
    lna, lnb:     integer;
    c:            real;
    x, y:         real;

procedure vecend(xs, ys,            { starting point }
                 d:          real;  { distance }
                 an:         real;  { angle }
                 var xe, ye: real); { end point }

begin

   xe := xs + d * sin(an); { find x }
   ye := ys - d * cos(an) { find y }

end;

begin

   { find angles and lengths of vectors }
   ana := angle(x1, y1, x2, y2);
   anb := angle(x1, y1, x3, y3);
   lna := dist(x1, y1, x2, y2);
   lnb := dist(x1, y1, x3, y3);
   { find difference between vectors }
   an := abs(angdif(ana, anb));
   { check dead axial }
   if (an > pi/2-0.005) and (an < pi/2+0.005) then begin

      { determine crossing }
      vecend(x1, y1, lnb/2, anb, x, y);
      vecend(x, y, lna/2, ana, x, y);

   end else begin { do normal }

      c := (lnb/2)/cos(an); { find dist to 2nd intercept }
      vecend(x1, y1, c, ana, x, y); { find that point }
      { find distance from that to center }
      c := (lna/2 - c)/cos(pi/2-an);
      vecend(x, y, c, ana-(pi/2-an), x, y) { find center }

   end;
   xc := round(x); { return }
   yc := round(y)

end;
{}
{**************************************************************

CHECK BUTTON

Checks if the cursor overlays a button, and selects that if
so.

**************************************************************}

procedure chkbut;

var i: buttyp;

begin

   if not inbutton(curbut) or (curbut = bnull) then begin

      { not in the last select }
      curbut := bnull; { clear current button }
      for i := succ(bnull) to bdisplay do
         if inbutton(i) and (curscm * button[i].sm <> []) then
         { inside button and mode matches }
         curbut := i; { set button found }

   end

end;
{}
{**************************************************************

UPDATE CURSOR POSITION DISPLAY

Updates the cursor position display.

**************************************************************}

procedure updcps;

begin

   { update cursor position display }
   if inactive(cur) or intarget(cur) and puck.v and
      not (button[bdisplay].act or
           button[bcells].act or
           button[blibv].act or
           button[bliba].act or
           button[blibb].act or
           button[blibc].act or
           button[blibd].act) then begin

      { in active area, and not in a menu mode }
      realstr(rcur.x*pixsiz, button[bcposxv].s); { place value }
      realstr(rcur.y*pixsiz, button[bcposyv].s); { convert and output }
      if smsimulate in curscm then begin

         { simulate, also do time and voltage }
         realstr(rcur.x*timesiz, button[bctimev].s); { place value }
         realstr((trcsiz*voltsiz)-((rcur.y mod trcsiz)*voltsiz)-1.5,
                 button[bcvoltv].s) { convert and output }

      end

   end else begin { out of active area }

      button[bcposxv].s := '        '; { clear strings }
      button[bcposyv].s := '        ';
      button[bctimev].s := '        ';
      button[bcvoltv].s := '        '

   end;
   updbut(bcposxv); { update }
   updbut(bcposyv);
   updbut(bctimev);
   updbut(bcvoltv)

end;
{}
{**************************************************************

UPDATE RULER DISPLAY

Updates the ruler display. The ruler is active whenever the
ruler mode is active, or some other mode that can be measured
is active. These include line, wire, bus, box, and boldbox
placements, block saves, and zooms and pans.
The relivant x and y are gathered from the coordinates appropriate
to the mode and displayed.

**************************************************************}

procedure updrul;

var xd, yd: real;

begin

   if (drmbut in [bline, bbline, bwire, bbus, bbox, bbbox, bsaveb,
                  bmet1, bmet2, bpoly, bvia, bndiff, bpdiff,
                  bnwell, bpwell, bccut, bcont, bdwave, bawave]) or
      (vimbut in [bin, bpan, bruler]) then begin

      { ruler mode is active }
      if inactive(cur) then begin { in active area }

         if drmbut in [bline, bbline, bwire, bbus, bbox,
                       bbbox, bsaveb, bmet1, bmet2, bpoly,
                       bvia, bndiff, bpdiff, bnwell, bpwell,
                       bccut, bcont, bdwave, bawave] then begin

            { wire or line }
            xd := endp.x-str.x;
            yd := endp.y-str.y

         end else begin { ruler, zoom or pan }

            xd := rcur.x-rmrk.x;
            yd := rcur.y-rmrk.y

         end;
         realstr(sqrt(sqr(xd)+sqr(yd))*pixsiz, button[brulerv].s);
         realstr(abs(xd)*pixsiz, button[brulxv].s);
         realstr(abs(yd)*pixsiz, button[brulyv].s);
         if smsimulate in curscm then begin

            { simulate, also do time and voltage }
            realstr(abs(xd)*timesiz, button[brtimev].s); { place value }
            realstr(abs(yd)*voltsiz, button[brvoltv].s) { convert and output }

         end

      end else begin { out of active area }

         button[brulerv].s := '        '; { clear strings }
         button[brulxv].s := '        ';
         button[brulyv].s := '        ';
         button[brtimev].s := '        ';
         button[brvoltv].s := '        '

      end;
      if not cntdrw then begin

         updbut(brulerv); { update }
         updbut(brulxv);
         updbut(brulyv);
         updbut(brtimev);
         updbut(brvoltv)

      end

   end

end;
{}
{**************************************************************

MOVE CURSOR

Moves the cursor to a new location.
The cursor is removed from the present position, and replaced
at the new position.
Any "in progress" drawn shape is also removed and replaced.

**************************************************************}

procedure movcur(newx, newy: integer); { move cursor }

{ port: line save index variable deleted (save-under removed) }
var t:      integer;
    dx, dy: integer;

begin

   dx := newx-cur.x; { find movement deltas }
   dy := newy-cur.y;
   if inactive(cur) or intarget(cur) then begin { in active area }

      { reset cursor if any "mobile" onscreen }
      if zbxdwn or lindwn or boxdwn or cirdwn or arcdwn then rescur;
      reszoom; { reset all onscreens }
      resline;
      resbox;
      rescircle;
      resarc;

   end;
   cur.x := newx; { place new coordinates }
   cur.y := newy;
   chkbut; { check button select }
   if inactive(cur) or intarget(cur) then begin

      { in active or target area }
      rcur := cur; { find real cursor position }
      if inactive(cur) then
         realc(rcur, curwin^.cs^.vp) { convert coordinates }
      else realc(rcur, targvp);
      if (vimbut in [bin, bout]) and
         ((inactive(cur) and inactive(mrk)) or
          (intarget(cur) and intarget(mrk))) then begin

         rescur; { remove cursor }
         setasp; { set aspect box }
         setzoom { set zoom box }

      end;
      if inactive(cur) then begin { in active }

         if not button[bpan].act and not button[bin].act and
            not button[bout].act and not button[bruler].act then begin

            if drmbut in [bline, bbline, bwire, bbus, bdwave,
                          bawave] then begin

               { place line }
               rescur; { remove cursor }
               setend; { set new end coordinates }
               setline { place line }

            end else if drmbut in [bbox, bbbox, bsaveb, bmet1,
                                   bmet2, bpoly, bvia, bndiff,
                                   bpdiff, bnwell, bpwell,
                                   bccut, bcont] then begin

               { place box }
               rescur; { remove cursor }
               endp := cur; { set new end coordinates }
               realc(endp, curwin^.cs^.vp); { convert coordinates }
               snapto(endp.x, endp.y);
               setbox { place box }

            end else if drmbut = bpasteb then begin { place paste box }

               rescur; { remove cursor }
               str := rcur; { set start of box }
               snapto(str.x, str.y); { snap }
               endp.x := str.x + (savb.e.x - savb.s.x); { set end of box }
               endp.y := str.y + (savb.e.y - savb.s.y);
               setbox { place box }

            end else if drmbut in [bplsch, bplsym, bplace] then begin

               { display placement box }
               rescur; { remove cursor }
               str := rcur; { set start of box }
               snapto(str.x, str.y); { snap }
               { set end of box }
               endp.x := str.x+plcsiz.x;
               endp.y := str.y+plcsiz.y;
               setbox { place box }

            end else if drmbut = bcircle then begin { place circle }

               rescur; { remove cursor }
               str := cur; { make sure end is established }
               realc(str, curwin^.cs^.vp); { convert coordinates }
               { find radius }
               rad := dist(cen.x, cen.y, str.x, str.y);
               str.x := cen.x; { project to x axis }
               str.y := cen.y + rad;
               snapto(str.x, str.y);
               { recalculate radius }
               rad := abs(str.y-cen.y);
               setcircle { place circle }

            end else if (drmbut = barc) and not arcsph then begin

               { place 1st phase arc }
               rescur; { remove cursor }
               endp := cur; { set end }
               realc(endp, curwin^.cs^.vp); { convert coordinates }
               snapto(endp.x, endp.y);
               setline { place flat arc(line) }

            end else if (drmbut = barc) and arcsph then begin

               { place 2nd phase arc }
               rescur; { remove cursor }
               { check which "hand: the cursor is on, and
                 reverse the draw direction as required }
               if angdif(angle(str.x, str.y, endp.x, endp.y),
                  angle(str.x, str.y, rcur.x, rcur.y)) < 0 then begin

                  { swap end and start }
                  t := str.x; str.x := endp.x; endp.x := t;
                  t := str.y; str.y := endp.y; endp.y := t

               end;
               { check points are colinear or nearly so. In this case,
                 the circle calculation climbs to infinity. We substitue
                 a line instead. }
               if (abs(angdif(angle(str.x, str.y, rcur.x, rcur.y),
                   angle(str.x, str.y, endp.x, endp.y))) > pi/50) and
                   (abs(angdif(angle(str.x, str.y, rcur.x, rcur.y),
                   angle(endp.x, endp.y, str.x, str.y))) > pi/10) and
                   (abs(angdif(angle(endp.x, endp.y, rcur.x, rcur.y),
                   angle(str.x, str.y, endp.x, endp.y))) > pi/10) then begin

                  { set the center }
                  center(str.x, str.y, endp.x, endp.y, rcur.x, rcur.y, cen.x, cen.y);
                  rad := dist(cen.x, cen.y, str.x, str.y); { find radius }
                  setarc; { place arc }
                  arcflat := false { set arc not flat }

               end else begin

                  setline; { substitue line }
                  arcflat := true { set arc is flat }

               end

            end

         end

      end

   end;
   updcps; { update cursor position display }
   updrul; { update ruler display }
   rescur; { ensure cursor is up }
   setcur { replace cursor }

end;
{}
{**************************************************************

CANCEL CURRENT ACTIVITIES

Resets indicators and markers from the screen, and cancels
active modes.

**************************************************************}

procedure canact;

begin

   rescur; { lift cursor }
   { reset any onscreen cursor }
   reszoom; { reset zoom box }
   resmrk; { reset marker }
   resrlm; { reset ruler mark }
   resline; { reset line cursor }
   resbox; { reset box cursor }
   rescircle; { reset circle cursor }
   resarc; { reset arc cursor }
   restcur; { reset text cursor }
   setcur; { drop cursor }
   { negate in process modes }
   modbut := bnull;
   drmbut := bnull;
   dsmbut := bnull;
   vimbut := bnull;
   { cancel in-progress edits }
   if cedbut <> bnull then begin

      button[cedbut].s := butsav; { restore from save }
      { update screen }
      updbut(cedbut) { update }

   end;
   if errmsg then plcmsg(mnone, yellow); { clear error message }
   if smprint in curscm then printstop { clear printer pop-up }

end;
{}
{**************************************************************

DEACTIVATE CURRENT ACTIVITIES

Resets all activity buttons, and resets indicators and markers
from the screen.

**************************************************************}

procedure stopact;

var ci: color; { index for trace colors }
    p:  drwptr; { figure pointer }

begin

   butina(bline); { deactivate all these buttons }
   butina(bbox);
   butina(bbline);
   butina(bbbox);
   butina(bcircle);
   butina(barc);
   butina(bwire);
   butina(bbus);
   butina(bjunction);
   butina(bconnect);
   butina(bsaveb);
   butina(bcutb);
   butina(bpasteb);
   butina(bdelete);
   butina(bdeleten);
   butina(btrace);
   butina(btext);
   butina(bplsym);
   butina(bplsch);
   butina(bpan);
   butina(bin);
   butina(bout);
   butina(bruler);
   butina(bname);
   butina(bdown);
   butina(bmet1);
   butina(bmet2);
   butina(bpoly);
   butina(bvia);
   butina(bcont);
   butina(bndiff);
   butina(bpdiff);
   butina(bnwell);
   butina(bpwell);
   butina(bccut);
   butina(bplace);
   butina(bdwave);
   butina(bawave);
   { cancel tracing activity }
   rescur; { lift cursor }
   p := curwin^.cs^.dl[ltfig]; { index top of figure list }
   while p <> nil do begin { traverse }

      if p^.cl <> black then begin { colored figure }

         drwfig(p, black, false, ltfig, curwin^.cs^.vp.v); { restore figure }
         p^.cl := black

      end;
      p := p^.next { next figure }

   end;
   for ci := black to white do trctrk[ci] := false;
   trcclr := lcyan; { reset to starting color }
   setcur; { set cursor }
   canact { cancel activities }

end;
{}
{**************************************************************

DEACTIVATE CURRENT VIEW ACTIVITIES

Resets all view activity buttons, and resets indicators and
markers from the screen.

**************************************************************}

procedure stopview;

begin

   butina(bpan); { deactivate all these buttons }
   butina(bin);
   butina(bout);
   butina(bruler);
   butina(bname);
   butina(bdown);
   rescur; { lift cursor }
   { reset any onscreen cursor }
   reszoom; { reset zoom box }
   resmrk; { reset marker }
   resrlm; { reset ruler mark }
   resline; { reset line cursor }
   resbox; { reset box cursor }
   rescircle; { reset circle cursor }
   resarc; { reset arc cursor }
   restcur; { reset text cursor }
   setcur; { drop cursor }
   { negate in process modes }
   modbut := bnull;
   vimbut := bnull;
   { cancel in-progress edits }
   if cedbut <> bnull then begin

      button[cedbut].s := butsav; { restore from save }
      { update screen }
      updbut(cedbut) { update }

   end

end;
{}
{**************************************************************

PLACE GRID

Fills the indicator grid array with the locations of the dot
grid. This is done prior to drawing the dot grid, usually
anytime a view change is made.

**************************************************************}

{ port: repaired grid step field references (curwin^.cs^.ds) and
  restarted the column scan on each row }

procedure dogrid(x1, y1, x2, y2: integer; { real bounds to draw }
                 c:              color);  { color to draw }

var x, y, xs: integer;

begin

   if (scndist(curwin^.cs^.ds, curwin^.cs^.vp.s.x) >= dotmin) and
      (scndist(curwin^.cs^.ds, curwin^.cs^.vp.s.y) >= dotmin) then begin

      { minimum spacing ok, proceed }
      { find bounding points on grid but within specified square }
      xs := x1 - x1 mod curwin^.cs^.ds; { find starting x }
      if xs < x1 then xs := xs + curwin^.cs^.ds;
      y := y1 - y1 mod curwin^.cs^.ds; { find starting y }
      if y < y1 then y := y + curwin^.cs^.ds;
      { draw dots }
      while y <= y2 do begin { rows }

         x := xs; { restart column scan }
         while x <= x2 do begin { collumns }

            setpix(curwin^.cs^.vp, x, y, c);
            x := x + curwin^.cs^.ds

         end;
         y := y + curwin^.cs^.ds

      end

   end

end;
{}
{**************************************************************

PLACE 10S GRID

Fills the indicator grid array with the locations of the line
grid. This is done prior to drawing the dot grid, usually
anytime a view change is made.

**************************************************************}

{ port: repaired grid step field references (curwin^.cs^.ls) and
  added the missing color parameter to the line calls }

procedure do10sgrid(x1, y1, x2, y2: integer; { real bounds to draw }
                    c:              color);  { color to draw }

var x, y:   integer;

begin

   if (scndist(curwin^.cs^.ls, curwin^.cs^.vp.s.x) >= linemin) and
      (scndist(curwin^.cs^.ls, curwin^.cs^.vp.s.y) >= linemin) then begin

      { minimum spacing ok, proceed }
      x := x1 - x1 mod curwin^.cs^.ls; { find starting x }
      if x < x1 then x := x + curwin^.cs^.ls;
      while x < x2 do begin { collums }

         line(curwin^.cs^.vp, x, y1, x, y2, c);
         x := x + curwin^.cs^.ls

      end;
      y := y1 - y1 mod curwin^.cs^.ls; { find starting y }
      if y < y1 then y := y + curwin^.cs^.ls;
      while y < y2 do begin { rows }

         line(curwin^.cs^.vp, x1, y, x2, y, c);
         y := y + curwin^.cs^.ls

      end

   end

end;
{}
{**************************************************************

CLEAR RULER

Clears the ruler display.

**************************************************************}

procedure cruler;

begin

   button[brulerv].s := '        '; { clear strings }
   button[brulxv].s := '        ';
   button[brulyv].s := '        ';
   updbut(brulerv); { update }
   updbut(brulxv);
   updbut(brulyv)

end;
{}
{**************************************************************

ZERO RULER

Sets the ruler display to all zeros.

**************************************************************}

procedure zruler;

begin

   button[brulerv].s := '      0 '; { set strings }
   button[brulxv].s := '      0 ';
   button[brulyv].s := '      0 ';
   updbut(brulerv); { update }
   updbut(brulxv);
   updbut(brulyv)

end;
{}
{**************************************************************

CHECK TARGET BOUNDS CHANGE

Checks if the bounds set for the current target have changed,
and updates the target display if so. The cursor is not lifted
for this.

**************************************************************}

procedure chktar;

begin

   { port: nil-sheet guard added }
   if curwin^.cs <> nil then
      { check if bounds have changed }
      if (targbnd.s.x <> curwin^.cs^.bbsx) or (targbnd.s.y <> curwin^.cs^.bbsy) or
         (targbnd.e.x <> curwin^.cs^.bbex) or (targbnd.e.y <> curwin^.cs^.bbey) then
         updtar { update target }

end;
{}
{**************************************************************

CHECK BOUNDING BOX SET

Checks if the bounding box has been previously set.

**************************************************************}

function boundset(sp: shtptr): boolean;

begin

   boundset := sp^.bs

end;
{}
{**************************************************************

UPDATE BOUNDING BOX

Given a coordinate set, updates the bounding box. The bounding
box is a box enclosing all drawn points on the screen.

**************************************************************}

procedure setbound(x, y: integer);

begin

   if not curwin^.cs^.bs then begin { never set, set all points }

      curwin^.cs^.bbsx := x;
      curwin^.cs^.bbsy := y;
      curwin^.cs^.bbex := x;
      curwin^.cs^.bbey := y

   end else begin { expand box as required }

      if x < curwin^.cs^.bbsx then curwin^.cs^.bbsx := x; { modify bounding box }
      if y < curwin^.cs^.bbsy then curwin^.cs^.bbsy := y;
      if x > curwin^.cs^.bbex then curwin^.cs^.bbex := x;
      if y > curwin^.cs^.bbey then curwin^.cs^.bbey := y

   end;
   curwin^.cs^.bs := true { set bounds active }

end;
{}
{**************************************************************

CHECK SYMBOL BOUNDING BOX SET

Checks if the symbol bounding box has been previously set.

**************************************************************}

function sboundset: boolean;

begin

   sboundset := curwin^.cs^.sbs

end;
{}
{**************************************************************

UPDATE SYMBOL BOUNDING BOX

Given a coordinate set, updates the symbol bounding box. The
bounding box is a box enclosing all drawn points on the screen.
The symbol bounding box does not include connectors, which do
not appear in symbol placements.

**************************************************************}

procedure setsbound(x, y: integer);

begin

   if not curwin^.cs^.sbs then begin { never set, set all points }

      curwin^.cs^.sbbsx := x;
      curwin^.cs^.sbbsy := y;
      curwin^.cs^.sbbex := x;
      curwin^.cs^.sbbey := y

   end else begin { expand box as required }

      if x < curwin^.cs^.sbbsx then curwin^.cs^.sbbsx := x; { modify bounding box }
      if y < curwin^.cs^.sbbsy then curwin^.cs^.sbbsy := y;
      if x > curwin^.cs^.sbbex then curwin^.cs^.sbbex := x;
      if y > curwin^.cs^.sbbey then curwin^.cs^.sbbey := y

   end;
   curwin^.cs^.sbs := true { set symbol bounds active }

end;
{}
{**************************************************************

REDRAW SCREEN

Clears the active area, and draws all figures onscreen. Also
replaces any in-progress figures. Also updates the target
display.
May be used to refresh "over" an existing screen.

**************************************************************}

procedure redraw;

begin

   rescur; { remove cursor }
   block(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y,
         curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, white); { clear active area }
   { draw active area }
   { port: grid indicator arrays deleted; the grids are drawn directly
     over the real extent of the view }
   if button[blines].act then { line grid active }
      do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                yellow); { place grid lines }
   if button[bdots].act then { dot grid active }
      dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
             curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
             black); { place grid dots }
   drwfigs; { draw figures }
   { replace any cursor figures }
   if zbxdwn then begin zbxdwn := false; setzoom end;
   if mrkdwn then begin mrkdwn := false; setmrk end;
   if rlmdwn then begin rlmdwn := false; setrlm end;
   if lindwn then begin lindwn := false; setline end;
   if boxdwn then begin boxdwn := false; setbox end;
   if cirdwn then begin cirdwn := false; setcircle end;
   if arcdwn then begin arcdwn := false; setarc end;
   if tcrdwn then begin tcrdwn := false; settcur end;
   updtar; { update target display }
   setcur { replace cursor }

end;
{}
{**************************************************************

SET NEW VIEW

Accepts and sets active a new view. The last view is set, and
the grids are calculated. The origin and scale displays are
updated.

**************************************************************}

procedure newview(x, y, s: integer);

var i: btsinx;

begin

   if not ((curwin^.cs^.vp.r.s.x = x) and (curwin^.cs^.vp.r.s.y = y) and
           (curwin^.cs^.vp.s.x = s)) then begin

      { not the same view }
      curwin^.cs^.lvp := curwin^.cs^.vp; { save last view }
      curwin^.cs^.vp.r.s.x := x; { set new view }
      curwin^.cs^.vp.r.s.y := y;
      curwin^.cs^.vp.s.x := s;
      curwin^.cs^.vp.s.y := s;
      curwin^.cs^.vp.r.e.x :=
         curwin^.cs^.vp.r.s.x+realdist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1, s);
      curwin^.cs^.vp.r.e.y :=
         curwin^.cs^.vp.r.s.y+realdist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1, s);
      redraw; { redraw screen }

   end;
   { place origin }
   realstr(curwin^.cs^.vp.r.s.x*pixsiz, button[borgxv].s);
   realstr(curwin^.cs^.vp.r.s.y*pixsiz, button[borgyv].s);
   { place scale }
   intstr(curwin^.cs^.vp.s.x div scalem, button[bsclv].s);
   trmzer(button[bsclv].s); { trim leading zeros }
   { move left }
   for i := 1 to 6 do button[bsclv].s[i] := button[bsclv].s[i+2];
   for i := 7 to butlen do button[bsclv].s[i] := ' ';
   rescur; { remove cursor }
   updbut(borgxv); { update }
   updbut(borgyv);
   updbut(bsclv);
   setcur { restore cursor }

end;
{}
{**************************************************************

DISPLAY SHEET

Updates the display for the current sheet. Also clears
any active modes.

**************************************************************}

procedure dispsht;

var i:  btsinx;

begin

   rescur; { lift cursor }
   rcur := cur; { find real version cursor position }
   realc(rcur, curwin^.cs^.vp); { convert coordinates }
   { place dot grid size }
   realstr(curwin^.cs^.ds*pixsiz, button[bdotsv].s);
   updbut(bdotsv); { update }
   { place line grid size }
   realstr(curwin^.cs^.ls*pixsiz, button[blinev].s);
   updbut(blinev); { update }
   { place origin }
   realstr(curwin^.cs^.vp.r.s.x*pixsiz, button[borgxv].s);
   updbut(borgxv); { update }
   realstr(curwin^.cs^.vp.r.s.y*pixsiz, button[borgyv].s);
   updbut(borgyv); { update }
   { place scale }
   intstr(curwin^.cs^.vp.s.x div scalem, button[bsclv].s);
   trmzer(button[bsclv].s); { trim leading zeros }
   { move left }
   for i := 1 to 6 do button[bsclv].s[i] := button[bsclv].s[i+2];
   for i := 7 to butlen do button[bsclv].s[i] := ' ';
   updbut(bsclv); { update }
   updcps; { place cursor location }
   { place text size }
   realstr(curwin^.cs^.ts*4*pixsiz, button[btsizv].s);
   updbut(btsizv); { update }
   { place junction size }
   realstr(curwin^.cs^.js*2*pixsiz, button[bjuncv].s);
   updbut(bjuncv); { update }
   { place connector size }
   realstr(curwin^.cs^.cs*2*pixsiz, button[bconnv].s);
   updbut(bconnv); { update }
   drmbut := bnull; { set draw mode inactive }
   vimbut := bnull; { set view mode inactive }
   cedbut := bnull; { set no button in edit }
   butina(bout); { clear mode buttons }
   butina(bpan);
   butina(bin);
   butina(bruler);
   redraw; { refresh screen }
   setcur { drop cursor }

end;
{}
{**************************************************************

PLACE CHILD WINDOW

Places, or replaces, a child window in a parent. The screen
viewport of the given child window is set up to occupy the
given retangle in the parent. The rectangle is given in
parent real coordinates.

**************************************************************}

{ port: moved ahead of newsht (forward reference in the original);
  master and child are var parameters, since child receives the
  screen rectangle and viewc requires a var viewport }

procedure plcwin(var master, child: viewport;  { windows }
                 x1, y1, x2, y2: integer); { placement rectangle }

var r: region; { convertion rectangle }

begin

   r.s.x := x1; { load rectangle }
   r.s.y := y1;
   r.e.x := x2;
   r.e.y := y2;
   viewc(r.s, master); { find screen rectangle }
   viewc(r.e, master);
   child.v := r { place screen rectangle }

end;
{}
{**************************************************************

CLEAR NEW SHEET

Clears the entire current sheet, and restores default parameters,
then draws the sheet.

**************************************************************}

procedure newsht;

var n:  nodptr;  { pointer for node list }
    b:  busptr;  { pointer for bus list }
    vi: viewinx;
    si: sizeinx;
    li: laytyp;  { layers index }

{ dispose of drawing list content }

procedure dumpdraw(var p: drwptr);

var p1: drwptr; { pointer for list }

begin

   while p <> nil do begin { remove drawing entries }

      p1 := p^.next; { save next entry }
      dispose(p); { dispose head entry }
      p := p1 { set next entry }

   end

end;

begin

   { dispose of all layers }
   for li := ltcell to ltwell do dumpdraw(curwin^.cs^.dl[li]);
   while curwin^.cs^.nl <> nil do begin { remove node entries }

      n := curwin^.cs^.nl^.next; { save next entry }
      dispose(curwin^.cs^.nl); { dispose head entry }
      curwin^.cs^.nl := n { set next entry }

   end;
   while curwin^.cs^.bl <> nil do begin { remove bus entries }

      b := curwin^.cs^.bl^.next; { save next entry }
      dispose(curwin^.cs^.bl); { dispose head entry }
      curwin^.cs^.bl := b { set next entry }

   end;
   { Set viewport region to all of window active area.
     This can be changed if we allow more than one sheet
     per window. }
   plcwin(curwin^.wv, curwin^.cs^.vp,
          curwin^.ar.s.x, curwin^.ar.s.y,
          curwin^.ar.e.x, curwin^.ar.e.y);
   curwin^.cs^.vp.r.s.x := 0; { set viewport to [0, 0] }
   curwin^.cs^.vp.r.s.y := 0;
   curwin^.cs^.vp.m.x := scalem; { set scaling multiplier }
   curwin^.cs^.vp.m.y := scalem;
   curwin^.cs^.vp.s.x := normscale*scalem; { set normal viewing scale }
   curwin^.cs^.vp.s.y := normscale*scalem;
   curwin^.cs^.vp.r.e.x :=
      curwin^.cs^.vp.r.s.x+realdist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1,
                                curwin^.cs^.vp.s.x);
   curwin^.cs^.vp.r.e.y :=
      curwin^.cs^.vp.r.s.y+realdist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1,
                                curwin^.cs^.vp.s.y);
   curwin^.cs^.lvp := curwin^.cs^.vp; { set last view as same }
   curwin^.cs^.bbsx := 0; { flag bounding box inactive }
   curwin^.cs^.bbex := 0;
   curwin^.cs^.bbsy := 0;
   curwin^.cs^.bbey := 0;
   curwin^.cs^.bs := false;
   curwin^.cs^.sbbsx := 0;
   curwin^.cs^.sbbex := 0;
   curwin^.cs^.sbbsy := 0;
   curwin^.cs^.sbbey := 0;
   curwin^.cs^.sbs := false;
   if smsimulate in curscm then begin

      curwin^.cs^.ds := dftdgsim; { set default dot grid size }
      curwin^.cs^.ls := dftlgsim { set default line grid size }

   end else begin

      curwin^.cs^.ds := dftdg; { set default dot grid size }
      curwin^.cs^.ls := dftlg { set default line grid size }

   end;
   curwin^.cs^.js := dftjun; { set default junction size }
   curwin^.cs^.cs := dftcon; { set default connector size }
   curwin^.cs^.ts := dftchr; { set standard character scale }
   { clear viewer array }
   for vi := 1 to viewmax do curwin^.cs^.sv[vi].a := false;
   { clear text size array }
   for si := 1 to sizemax do curwin^.cs^.sts[si].a := false;
   { clear dot size array }
   for si := 1 to sizemax do curwin^.cs^.sds[si].a := false;
   { clear line size array }
   for si := 1 to sizemax do curwin^.cs^.sls[si].a := false;
   celstk := nil; { clear cell stack }
   dispsht { display sheet }

end;
{}
{**************************************************************

DISPLAY CELL

Activates viewing of the current cell. The existing sheet for the
current mode is either viewed, or created and viewed if it
does not currently exist for that cell.
Also sets the current sheet active (based on mode).

**************************************************************}

procedure dispcell;

var li: laytyp; { layers index }

begin

   if button[bschema].act then begin

      { in schematic mode }
      if curwin^.cc^.schema = nil then begin { create new sheet }

         new(curwin^.cc^.schema); { get a new sheet entry for schematic }
         for li := ltcell to ltwell do
            curwin^.cc^.schema^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.schema^.nl := nil; { clear node list }
         curwin^.cc^.schema^.bl := nil; { clear bus list }
         curwin^.cc^.schema^.nc := 0; { clear node count }
         curwin^.cs := curwin^.cc^.schema; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.schema; { place as current sheet }
         dispsht { display current sheet }

      end

   end else if button[bsymbol].act then begin

      { in symbol mode }
      if curwin^.cc^.symbol = nil then begin { create new sheet }

         new(curwin^.cc^.symbol); { get a new sheet entry for symbol }
         for li := ltcell to ltwell do
            curwin^.cc^.symbol^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.symbol^.nl := nil; { clear node list }
         curwin^.cc^.symbol^.bl := nil; { clear bus list }
         curwin^.cc^.symbol^.nc := 0; { clear node count }
         curwin^.cs := curwin^.cc^.symbol; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.symbol; { place as current sheet }
         dispsht { display current sheet }

      end

   end else if button[blayout].act then begin

      { in layout mode }
      if curwin^.cc^.layout = nil then begin { create new sheet }

         new(curwin^.cc^.layout); { get a new sheet entry for layout }
         for li := ltcell to ltwell do
            curwin^.cc^.layout^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.layout^.nl := nil; { clear node list (unused) }
         curwin^.cc^.layout^.bl := nil; { clear bus list (unused) }
         curwin^.cc^.layout^.nc := 0; { clear node count (unused) }
         curwin^.cs := curwin^.cc^.layout; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.layout; { place as current sheet }
         dispsht { display current sheet }

      end

   end else begin

      { in simulate mode }
      if curwin^.cc^.simulate = nil then begin { create new sheet }

         new(curwin^.cc^.simulate); { get a new sheet entry for layout }
         for li := ltcell to ltwell do
            curwin^.cc^.simulate^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.simulate^.nl := nil; { clear node list (unused) }
         curwin^.cc^.simulate^.bl := nil; { clear bus list (unused) }
         curwin^.cc^.simulate^.nc := 0; { clear node count (unused) }
         curwin^.cs := curwin^.cc^.simulate; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.simulate; { place as current sheet }
         dispsht { display current sheet }

      end

   end

end;
{}
{**************************************************************

DISPLAY WINDOW FRAME

Calculates a window frame based on the given screen viewport,
calculates the client region within that, and displays the
windowframe.

**************************************************************}

procedure dispwframe(wp: winptr;  { window }
                     s:  ttlstr); { window title }

var i:  ttlinx; { string index }
    l:  integer; { length of string in pixels }
    x:  integer;
    sl: ttlinx; { string length }

begin

   wp^.wv.r.s.x := 0; { zero based, but same size }
   wp^.wv.r.s.y := 0;
   { port: repaired wp^.wv.s.x/y to wp^.wv.v.s.x/y (screen extent) }
   wp^.wv.r.e.x := wp^.wv.v.e.x-wp^.wv.v.s.x;
   wp^.wv.r.e.y := wp^.wv.v.e.y-wp^.wv.v.s.y;
   { port: was 1 in the (mid-refactor) originals; see the screen viewport
     note in iniicd — identity window viewports need s = m = scalem }
   wp^.wv.s.x := scalem; { set no scaling }
   wp^.wv.s.y := scalem;
   wp^.wv.m.x := scalem;
   wp^.wv.m.y := scalem;
   wp^.wv.c := wp^.wv.v; { set clipping to window }
   { find client area within frame }
   { port: uiscl - frame border/title bar pixel constants scaled to
     character cell throughout dispwframe }
   wp^.cr.s.x := wp^.wv.r.s.x+uiscl(2+5+2);
   wp^.cr.s.y := wp^.wv.r.s.y+uiscl(2+5+2);
   wp^.cr.e.x := wp^.wv.r.e.x-uiscl(2+5+2);
   wp^.cr.e.y := wp^.wv.r.e.y-uiscl(2+5+2);
   { place move buttons }
   plcmovb;
   rescur; { lift cursor }
   { draw frame backround left }
   block(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y,
         wp^.ar.s.x-1, wp^.wv.r.e.y, wp^.bc);
   { draw frame backround top }
   block(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y,
         wp^.tr.s.x-1, wp^.ar.s.y-1, wp^.bc);
   { draw frame backround right }
   block(wp^.wv, wp^.ar.e.x+1, wp^.tr.e.y+1,
         wp^.wv.r.e.x, wp^.wv.r.e.y, wp^.bc);
   { draw frame backround bottom }
   block(wp^.wv, wp^.wv.r.s.x, wp^.ar.e.y+1,
         wp^.wv.r.e.x, wp^.wv.r.e.y, wp^.bc);
   { draw target margin }
   block(wp^.wv, wp^.tr.s.x, wp^.wv.r.s.y,
         wp^.tr.e.x, wp^.tr.s.y-1, wp^.bc);
   block(wp^.wv, wp^.tr.e.x+1, wp^.wv.r.s.y,
         wp^.wv.r.e.x, wp^.tr.e.y, wp^.bc);
   block(wp^.wv, wp^.ar.e.x+1, wp^.ar.s.y,
         wp^.tr.s.x-1, wp^.tr.e.y, wp^.bc);
   { draw window frame }
   frame(wp^.wv.r.s.x, wp^.wv.r.s.y,
         wp^.wv.r.e.x, wp^.wv.r.e.y,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   frame(wp^.wv.r.s.x+uiscl(2+5), wp^.wv.r.s.y+uiscl(2+5),
         wp^.wv.r.e.x-uiscl(2+5), wp^.wv.r.e.y-uiscl(2+5),
         wp^.sc, wp^.lc, wp^.sc, wp^.lc);
   { draw control, move, min and max button frames }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(2+5+2), wp^.wv.r.s.y+uiscl(28),
        wp^.wv.r.e.x-uiscl(2+5+2), wp^.wv.r.s.y+uiscl(28), wp^.sc);
   { port: repaired wp^.r to wp^.wv.r here and below }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(2+5+2), wp^.wv.r.s.y+uiscl(28)+1,
        wp^.wv.r.e.x-uiscl(2+5+2)+1, wp^.wv.r.s.y+uiscl(28)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y+uiscl(2+5+2+19),
        wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y+uiscl(2+5+2+19)+1,
        wp^.lc);
   frame(wp^.wv.r.s.x+uiscl(2+5+2+2), wp^.wv.r.s.y+uiscl(2+5+2+6),
         wp^.wv.r.s.x+uiscl(2+5+2+19-3), wp^.wv.r.s.y+uiscl(2+5+2+6+7)-1,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y+uiscl(2+5+2+19),
        wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y+uiscl(2+5+2+19)+1,
        wp^.lc);
   if button[bmax].act then { button active }
      frame(wp^.wv.r.e.x-uiscl(29)+uiscl(2+2), wp^.wv.r.s.y+uiscl(2+5+2+2),
            wp^.wv.r.e.x-uiscl(29)+uiscl(2+19-3), wp^.wv.r.s.y+uiscl(2+5+2+2+15)-1,
            wp^.sc, wp^.sc, wp^.lc, wp^.lc)
   else { button inactive }
      frame(wp^.wv.r.e.x-uiscl(29)+uiscl(2+2), wp^.wv.r.s.y+uiscl(2+5+2+2),
            wp^.wv.r.e.x-uiscl(29)+uiscl(2+19-3), wp^.wv.r.s.y+uiscl(2+5+2+2+15)-1,
            wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29+19)-uiscl(2), wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29+19)-uiscl(2), wp^.wv.r.s.y+uiscl(2+5+2+19),
        wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29+19)-uiscl(2)+1, wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29+19)-uiscl(2)+1, wp^.wv.r.s.y+uiscl(2+5+2+19)+1,
        wp^.lc);
   frame(wp^.wv.r.e.x-uiscl(29+19)+uiscl(6), wp^.wv.r.s.y+uiscl(2+5+2+6),
         wp^.wv.r.e.x-uiscl(29+19)+uiscl(19-7), wp^.wv.r.s.y+uiscl(2+5+2+6+7)-1,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   { place move bar breaks }
   { left }
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y+uiscl(28),
        wp^.wv.r.s.x+uiscl(2+5)-1, wp^.wv.r.s.y+uiscl(28), wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y+uiscl(28)+1,
        wp^.wv.r.s.x+uiscl(2+5), wp^.wv.r.s.y+uiscl(28)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.e.y-uiscl(29),
        wp^.wv.r.s.x+uiscl(2+5)-1, wp^.wv.r.e.y-uiscl(29), wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.e.y-uiscl(29)+1,
        wp^.wv.r.s.x+uiscl(2+5), wp^.wv.r.e.y-uiscl(29)+1, wp^.lc);
   { right }
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.s.y+uiscl(28),
        wp^.wv.r.e.x, wp^.wv.r.s.y+uiscl(28), wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.s.y+uiscl(28)+1,
        wp^.wv.r.e.x, wp^.wv.r.s.y+uiscl(28)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.e.y-uiscl(29),
        wp^.wv.r.e.x, wp^.wv.r.e.y-uiscl(29), wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.e.y-uiscl(29)+1,
        wp^.wv.r.e.x, wp^.wv.r.e.y-uiscl(29)+1, wp^.lc);
   { top }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y,
        wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y+uiscl(2+5)-1, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y,
        wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y+uiscl(2+5), wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y,
        wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y+uiscl(2+5)-1, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y,
        wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y+uiscl(2+5), wp^.lc);
   { bottom }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28), wp^.wv.r.e.y,
        wp^.wv.r.s.x+uiscl(28), wp^.wv.r.e.y-uiscl(2+5)+1, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.e.y,
        wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.e.y-uiscl(2+5)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29), wp^.wv.r.e.y,
        wp^.wv.r.e.x-uiscl(29), wp^.wv.r.e.y-uiscl(2+5)+1, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.e.y,
        wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.e.y-uiscl(2+5)+1, wp^.lc);
   { place window title, centered in move bar }
   sl := ttllen; { set maximum }
   while (sl > 1) and (s[sl] = ' ') do sl := sl - 1;
   l := 0; { clear length }
   { find total length }
   { port: alphal width table replaced by chrwidth }
   for i := 1 to sl do l := l+chrwidth(s[i])+uiscl(1);
   { find center of string }
   x := (wp^.wv.r.s.x+uiscl(30)+
         (((wp^.wv.r.e.x-uiscl(30+21))-(wp^.wv.r.s.x+uiscl(30))) div 2))
        -(l div 2);
   for i := 1 to sl do begin

      setchr(wp^.wv, x, wp^.wv.r.s.y+uiscl(2+5+2+4), s[i], black);
      x := x + chrwidth(s[i])+uiscl(1) { next collumn }

   end

end;
{}
{**************************************************************

DISPLAY WINDOW

Activates viewing of the current window. The entire window
format is recalculated and displayed.

**************************************************************}

procedure dispwin;

var b: buttyp; { button index }

begin

   { create window frame }
   dispwframe(curwin, 'Schematic Draft                         ');
   { set initial value of right margin start }
   { port: repaired curwin^.wv.cr to curwin^.cr (client region is a
     window field) here and below }
   curwin^.rm.s.x := curwin^.cr.e.x;
   repeat { menu fits }

      { set target area }
      { port: uiscl - layout margins/title bar/target height scaled }
      curwin^.tr.s.x := curwin^.rm.s.x;
      curwin^.tr.s.y := curwin^.cr.s.y+uiscl(19+2+4);
      curwin^.tr.e.x := curwin^.cr.e.x-uiscl(4);
      curwin^.tr.e.y := curwin^.tr.s.y+uiscl(100);
      { automatically arrange top side buttons }
      arrbutt(curwin^.cr.s.x+uiscl(4),
              curwin^.cr.s.y+uiscl(19+2+4),
              curwin^.rm.s.x-uiscl(5),
              curwin^.cr.e.y-uiscl(4));
      { automatically arrange right side buttons }
      marginr(curwin^.cr.e.x-uiscl(4),
              curwin^.tr.e.y+uiscl(1+4),
              curwin^.cr.e.y-uiscl(4),
              curwin^.cr.s.x+uiscl(4));
      { set active area }
      curwin^.ar.s.x := curwin^.cr.s.x+uiscl(4);
      curwin^.ar.s.y := curwin^.tm.e.y+uiscl(1+4);
      curwin^.ar.e.x := curwin^.rm.s.x-uiscl(1+4);
      curwin^.ar.e.y := curwin^.cr.e.y-uiscl(4)

   until (curwin^.tm.e.x <= curwin^.rm.s.x);
   arrbutr;
   { find aspect angle }
   curwin^.aa := arctan((curwin^.ar.e.x-curwin^.ar.s.x)/
                        (curwin^.ar.e.y-curwin^.ar.s.y));
   { set target viewport }
   plcwin(curwin^.wv, curwin^.tv,
          curwin^.tr.s.x, curwin^.tr.s.y,
          curwin^.tr.e.x, curwin^.tr.e.y);
   { port: the original was mid-migration from the global targvp to
     curwin^.tv (see the "moved to curwin" comments in common.pas); the
     drawing code still reads the global, so keep it in step }
   targvp := curwin^.tv;
   if curwin^.cs <> nil then begin { resize current sheet }

      { set sheet viewport region }
      plcwin(curwin^.wv, curwin^.cs^.vp,
             curwin^.ar.s.x, curwin^.ar.s.y,
             curwin^.ar.e.x, curwin^.ar.e.y)

   end;
   { display buttons }
   for b := succ(bnull) to bdisplay do { place buttons }
      if (curscm - [smprint]) * button[b].sm <> [] then
         { button applicable to screen mode(s) }
         updbut(b); { update }
   dispcell { display cell in edit }

end;
{}
{**************************************************************

ZOOM IN

Handles zoom in functions. If the current button is activated,
it is turned on and the zoom mode entered. If a button is clicked
in the active, the zoom box is placed.
Calculates a zoom based on the zoom box coordinates, then redraws
the screen to that magnification, and viewport centered on that
box.

**************************************************************}

procedure zoomin;

var x, y, s: integer;
    p:       point;

begin

   if (curbut = bin) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bin].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bin); { activate button }
         modbut := bin

      end

   end else if (vimbut = bin) and
               ((inactive(cur) and inactive(mrk)) or
                (intarget(cur) and intarget(mrk))) and
               (puck.b[2].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { if zoom box present, and in active or target windows }
      rescur; { remove cursor }
      reszoom; { remove zoom box }
      setcur; { replace cursor }
      p := zb.s; { find real coordinates of box origin }
      p := zb.s;
      if inactive(cur) then
         realc(p, curwin^.cs^.vp) { convert coordinates }
      else realc(p, targvp);
      x := p.x;
      y := p.y;
      { find new scale }
      if inactive(cur) then
         s := round(curwin^.cs^.vp.s.x/(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/
              abs(zb.e.y-zb.s.y)))
      else
         s := round(targvp.s.x/(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/
              abs(zb.e.y-zb.s.y)));
      newview(x, y, s); { activate new view }
      { clear ruler }
      cruler; { clear ruler display }
      vimbut := bnull; { reset mode }
      modbut := bnull;
      butina(bin); { clear button }
      modbut := dsmbut { restore any draw mode }

   end else if (inactive(cur) or intarget(cur)) and
          (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { in active or target area }
      rescur; { remove cursor }
      if (vimbut = bin) then reszoom; { erase existing zoom box }
      mrk := cur; { set starting marker }
      rmrk := mrk; { create real version }
      if intarget(mrk) then realc(rmrk, targvp) { convert target area }
      else realc(rmrk, curwin^.cs^.vp); { convert coordinates }
      zb.s := mrk; { also set aspect box }
      zb.e := mrk;
      setzoom; { place zoom box }
      zruler; { update ruler }
      setcur; { replace cursor }
      vimbut := bin; { set mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

ZOOM OUT

Handle zoom out mode. Activates the button, starts the zoom out
indicator box.
Calculates a zoom based on the zoom box coordinates, then redraws
the screen to that magnification, and viewport centered on that
box.

**************************************************************}

procedure zoomout;

var x, y, s: integer;

begin

   if (curbut = bout) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bout].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bout); { activate button }
         modbut := bout

      end

   end else if (vimbut = bout) and inactive(cur) and
               (puck.b[2].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { if zoom box present }
      rescur; { reset cursor }
      reszoom; { remove zoom box }
      setcur; { replace cursor }
      { find new scale }
      s := round(curwin^.cs^.vp.s.x*
           (abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/abs(zb.e.y-zb.s.y)));
      { find new origin }
      { is old minus length to place at box }
      x := curwin^.cs^.vp.r.s.x - realdist(zb.s.x-curwin^.cs^.vp.v.s.x, s);
      y := curwin^.cs^.vp.r.s.y - realdist(zb.s.y-curwin^.cs^.vp.v.s.y, s);
      newview(x, y, s); { activate new view }
      vimbut := bnull; { reset mode }
      modbut := bnull;
      butina(bout); { clear button }
      modbut := dsmbut { restore any draw mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      rescur; { remove cursor }
      if (vimbut = bout) then reszoom; { erase existing zoom box }
      mrk := cur; { set starting marker }
      zb.s := mrk; { also set aspect box }
      zb.e := mrk;
      setzoom; { place zoom box }
      setcur; { replace cursor }
      vimbut := bout { set mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

PAN

Handles the pan mode. The pan button is toggled if activated.
The marker is placed onscreen if in the active area.
Pans the marker to the present position by changing the origin,
then refreshing the display.

**************************************************************}

procedure pan;

var x1, y1, x2, y2: integer;

begin

   if (curbut = bpan) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bpan].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bpan); { activate button }
         modbut := bpan

      end

   end else if (vimbut = bpan) and
               ((inactive(cur) and inactive(mrk)) or
                (intarget(cur) and intarget(mrk))) and
               (puck.b[2].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { perform pan }
      rescur; { reset cursor }
      resmrk; { remove marker }
      setcur; { reset cursor }
      x1 := curwin^.cs^.vp.r.s.x+(rmrk.x-rcur.x); { set new origin }
      y1 := curwin^.cs^.vp.r.s.y+(rmrk.y-rcur.y);
      { find end of screen }
      x2 := x1+realdist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1, curwin^.cs^.vp.s.x);
      y2 := y1+realdist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1, curwin^.cs^.vp.s.y);
      if (x1 > rw.s.x) and (x2 < rw.e.x) and
         (y1 > rw.s.y) and (y2 < rw.e.y) then
         newview(x1, y1, curwin^.cs^.vp.s.x); { go new view }
      { clear ruler }
      cruler; { clear ruler display }
      vimbut := bnull; { reset mode }
      modbut := bnull;
      butina(bpan); { clear button }
      modbut := dsmbut { restore any draw mode }

   end else if (inactive(cur) or intarget(cur)) and
               (puck.b[1].a or puck.b[2].a) then begin

      { place pan marker }
      rescur; { remove cursor }
      if vimbut = bpan then resmrk; { remove previous mark }
      mrk := cur; { set marker coordinates }
      rmrk := mrk; { create real version }
      if intarget(mrk) then realc(rmrk, targvp) { convert target area }
      else realc(rmrk, curwin^.cs^.vp); { convert coordinates }
      setmrk; { set marker }
      setcur; { replace cursor }
      zruler; { update ruler }
      vimbut := bpan; { set mark mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

RULER

Handles the ruler mode. If the button is activated, that is
turned on. If a button is clicked in active, the ruler
"target" icon is placed. From then on, the ruler mode is self -
operating.

**************************************************************}

procedure ruler;

begin

   if (curbut = bruler) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bruler].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bruler); { activate button }
         modbut := bruler

      end

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      rescur; { remove cursor }
      if vimbut = bruler then resrlm; { remove previous mark }
      mrk := cur; { set marker coordinates }
      rmrk := mrk; { create real version }
      realc(rmrk, curwin^.cs^.vp); { convert coordinates }
      setrlm; { set marker }
      setcur; { replace cursor }
      zruler; { update ruler }
      vimbut := bruler { set rule mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

GO BOUNDING BOX

Changes the view to the bounding box.

**************************************************************}

procedure bound;

var x, y, s: integer;

begin

   if (curbut = bbound) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      stopview; { stop motion modes }
      butact(bbound); { activate button }
      fndbnd(curwin^.cs, x, y, s); { find the view }
      newview(x, y, s); { activate new view }
      butina(bbound); { deactivate button }
      modbut := dsmbut { restore any draw mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

LAST VIEW

Restores the last origin and scale factor.

**************************************************************}

procedure back;

var x, y, s: integer;

begin

   if (curbut = bback) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      stopview; { stop motion modes }
      butact(bback); { set button active }
      x := curwin^.cs^.lvp.r.s.x; { get the last view }
      y := curwin^.cs^.lvp.r.s.y;
      s := curwin^.cs^.lvp.s.x;
      newview(x, y, s); { activate new (old) view }
      butina(bback); { set button inactive }
      modbut := dsmbut { restore any draw mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE SNAP

Flips the state of the snap to grid mode. Also redraws any
in-progress line.

**************************************************************}

procedure togsnap;

begin

   if (curbut = bsnap) and (puck.b[1].a or
      puck.b[2].a or puck.b[4].a) then begin

      if button[bsnap].act then butina(bsnap) { toggle status }
      else butact(bsnap);
      if drmbut in [bline, bbline, bwire, bbus, bbox,
                    bbbox, bsaveb] then begin

         { line or box }
         str := tstr; { restore true start }
         snapto(str.x, str.y) { snap start point }

      end else if drmbut = bcircle then begin { circle }

         cen := tcen; { restore true center }
         snapto(cen.x, cen.y) { snap center }

      end

   end;
   resptr { reset buttons }

end;
{ UNRESOLVED:
  drwfigs  - draw all figures (icdd.pas), stubbed in redraw; cell drawing
             deferred to a later phase
  drwfig   - draw single figure (icdd/icdh.pas), stubbed in stopact; cell
             drawing deferred to a later phase
  updtar   - update target display (icdf.pas), called by chktar and redraw;
             later phase
  printstop - clear printer pop-up (icde.pas), called by canact; printer
             pass deferred
  fndbnd   - find parameters for bounds view (icda.pas), called by bound;
             expected from the icda fragment or a later phase
  resptr   - reset pointer flags (icda.pas), called by the view mode
             handlers; expected from the icda fragment or the main program
             event loop
  setchr   - viewport character draw, called by dispwframe; expected from
             the icdb fragment (spec rule 3)
  targbnd  - target bounding box global, referenced by chktar; currently
             commented out in icddef.pas ("?? moved to curwin") and must be
             restored or relocated }
{******************************************************************************

LATE COMPATIBILITY DEFINITIONS

Routines forwarded in the base layer whose implementations depend on the
ported layers above.

******************************************************************************}

{ find bounding box view of sheet (from icda.pas) }

procedure fndbnd(sp: shtptr; var x, y, s: integer);

var an: real;

begin

   if not boundset(sp) then begin { bounds not set }

      x := 0; { set default view coordinates for empty sheet }
      y := 0;
      s := normscale*scalem

   end else begin { bounds set }

      { find box diagonal }
      if (sp^.bbsx <> sp^.bbex) and (sp^.bbsy <> sp^.bbey) then
         an := arctan(abs(sp^.bbex-sp^.bbsx)/abs(sp^.bbey-sp^.bbsy));
      if ((an < curwin^.aa) or (sp^.bbsx = sp^.bbex)) and not
         (sp^.bbsy = sp^.bbey) then begin { y dominated }

         s := round((abs(sp^.bbey-sp^.bbsy)/
                     (abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)-
                      (2*bbborder)))*scalem);
         x := round(sp^.bbsx - (((abs(sp^.bbey-sp^.bbsy)/2)/tan((pi/2)-curwin^.aa))-
                    (abs(sp^.bbex-sp^.bbsx)/2)));
         y := sp^.bbsy { set origins }

      end else begin { x dominated }

         s := round((abs(sp^.bbex-sp^.bbsx)/
                     (abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)-
                      (2*bbborder)))*scalem);
         x := sp^.bbsx; { set origins }
         y := round(sp^.bbsy - (((abs(sp^.bbex-sp^.bbsx)/2)/tan(curwin^.aa))-
                   (abs(sp^.bbey-sp^.bbsy)/2)))

      end;
      { offset by margins }
      x := x - realdist(bbborder, s);
      y := y - realdist(bbborder, s)

   end

end;
{***************************************************************

FRAGMENT N: schematic database core ported from icda.pas (1992)

Ported per PORTING-SPEC.md. This fragment contains the puck
communication flag reset (resptr) and the schematic connection
database: node/bus list maintenance, wire/bus/junction deletion,
colinear joins, node and bus creation and merging, wire
attachment, and the junction/wire/bus linkers.

Omitted from the original (see spec):

   fndbnd            - already ported in frag_e.pas.
   readbyt onward    - cell file I/O, deferred to a later phase.

port: the resptr stub in icdui_base.pas is superseded by the
full port below; the integrator removes the stub.

***************************************************************}
{}
{**************************************************************

CLEAR PUCK

Clears all puck action flags.

**************************************************************}

procedure resptr;

begin

   puck.b[1].a := false; { reset buttons }
   puck.b[2].a := false;
   puck.b[3].a := false;
   puck.b[4].a := false;
   puck.b[1].d := false; { reset buttons }
   puck.b[2].d := false;
   puck.b[3].d := false;
   puck.b[4].d := false;
   puck.m := false

end;
{}
{**************************************************************

DELETE NODE

Deletes the given node from the node list, and also from the
smash list if it is there.

**************************************************************}

procedure delnode(n: nodptr);

var p: nodptr;

begin

   { delete from node list }
   p := curwin^.cs^.nl; { index top of node list }
   if p = n then curwin^.cs^.nl := p^.next { gap top of list }
   else begin

      while p^.next <> n do p := p^.next; { find parent node }
      p^.next := n^.next { gap list }

   end;
   { delete from smash list }
   if smslst = n then smslst := smslst^.sl { delete first entry }
   else if smslst <> nil then begin { search }

      p := smslst; { index smash list }
      while (p^.sl <> n) and (p^.sl <> nil) do p := p^.sl;
      if p^.sl <> nil then begin { delete }

         p^.sl := n^.sl; { gap over }
         n^.sl := nil { clear from list }

      end

   end;
   { delete from bus list }
   if n^.bh <> nil then begin { node is part of a bus }

      p := n^.bh^.nl; { index top of node list }
      if p = n then n^.bh^.nl := p^.bl { gap top of list }
      else begin

         while p^.bl <> n do p := p^.bl; { find parent node }
         p^.bl := n^.bl { gap list }

      end

   end

end;
{}
{**************************************************************

DELETE BUS

Deletes the given node from the bus list, and also from the
bus smash list if it is there.

**************************************************************}

procedure delbus(b: busptr);

var p: busptr;

begin

   p := curwin^.cs^.bl; { index top of node list }
   if p = b then curwin^.cs^.bl := p^.next { gap top of list }
   else begin

      while p^.next <> b do p := p^.next; { find parent node }
      p^.next := b^.next { gap list }

   end;
   if bsmlst = b then bsmlst := bsmlst^.sl { delete first entry }
   else if bsmlst <> nil then begin { search }

      p := bsmlst; { index smash list }
      while (p^.sl <> b) and (p^.sl <> nil) do p := p^.sl;
      if p^.sl <> nil then begin { delete }

         p^.sl := b^.sl; { gap over }
         b^.sl := nil { clear from list }

      end

   end

end;
{}
{**************************************************************

DELETE WIRE

Deletes the given wire, bus, connector or junction from
the draw and other lists.

**************************************************************}

procedure delwire(w: drwptr);

var p: drwptr;

begin

   { remove from drawing list }
   p := curwin^.cs^.dl[ltfig]; { index top of list }
   if p = w then curwin^.cs^.dl[ltfig] := w^.next { gap top of list }
   else begin

      while p^.next <> w do p := p^.next; { find parent }
      p^.next := w^.next { gap }

   end;
   if w^.typ <> tbus then begin { wire, junction or connector }

      { remove from node list }
      p := w^.nh^.nl; { index top of node list }
      if p = w then w^.nh^.nl := w^.nl { gap top of list }
      else begin

         while p^.nl <> w do p := p^.nl; { find parent }
         p^.nl := w^.nl

      end;
      { if we have emptied that node list, the node itself is
        removed }
      if w^.nh^.nl = nil then begin

         delnode(w^.nh); { remove }
         { flag to caller that node is no more }
         w^.nh := nil

      end

   end else begin { bus }

      { remove from bus list }
      p := w^.bs.bh^.bl; { index top of node list }
      if p = w then w^.bs.bh^.bl := w^.bs.bl { gap top of list }
      else begin

         while p^.bs.bl <> w do p := p^.bs.bl; { find parent }
         p^.bs.bl := w^.bs.bl

      end;
      { if we have emptied that node list, the bus itself is
        removed }
      if w^.bs.bh^.bl = nil then begin

         delbus(w^.bs.bh); { remove }
         { flag to caller that bus is no more }
         w^.bs.bh := nil

      end

   end

end;
{}
{**************************************************************

JOIN COLINEAR LINE/WIRE/BUS

Joins two lines that have already been found to be colinear,
and overlapping. Line a is extended to be equivalent to both
lines, and line b is extracted from all draw and node lists.
The lines must be of the same type

**************************************************************}

procedure join(a, b: drwptr);

procedure ljoin(var a, b: region); { line join }

var t: integer;

begin

   if a.s.x = a.e.x then begin { vertical line }

      { regularize both lines }
      if a.s.y > a.e.y then { swap ends }
         begin t := a.s.y; a.s.y := a.e.y; a.e.y:= t end;
      if b.s.y > b.e.y then { swap ends }
         begin t := b.s.y; b.s.y := b.e.y; b.e.y:= t end;
      { choose the "widest" ends }
      if b.s.y < a.s.y then a.s.y := b.s.y;
      if b.e.y > a.e.y then a.e.y := b.e.y

   end else begin { horizontal line }

      { regularize both lines }
      if a.s.x > a.e.x then { swap ends }
         begin t := a.s.x; a.s.x := a.e.x; a.e.x:= t end;
      if b.s.x > b.e.x then { swap ends }
         begin t := b.s.x; b.s.x := b.e.x; b.e.x:= t end;
      { choose the "widest" ends }
      if b.s.x < a.s.x then a.s.x := b.s.x;
      if b.e.x > a.e.x then a.e.x := b.e.x

   end

end;

begin

   if a^.typ = twire then ljoin(a^.w, b^.w)  { wire }
   else if a^.typ = tbus then ljoin(a^.bs.l, b^.bs.l) { bus }
   else ljoin(a^.l, b^.l); { line }
   if (a^.typ = twire) or (a^.typ = tbus) then
      delwire(b) { delete b wire }

end;
{}
{**************************************************************

CHECK WIRE/LINE ORTHOGONAL

Checks if the wire/line is orthogonal, that is, either dead vertical
or dead horizontal.

**************************************************************}

function orthogonal(d: drwptr): boolean; { check orthogonality }

var b: boolean;

begin

   if d^.typ = twire then { wire }
      b := (d^.w.s.x = d^.w.e.x) or
           (d^.w.s.y = d^.w.e.y) { set result }
   else if d^.typ = tbus then { bus }
      b := (d^.bs.l.s.x = d^.bs.l.e.x) or
           (d^.bs.l.s.y = d^.bs.l.e.y) { set result }
   else { line }
      b := (d^.l.s.x = d^.l.e.x) or
           (d^.l.s.y = d^.l.e.y); { set result }
   orthogonal := b { return }

end;
{}
{**************************************************************

CHECK POINT CONTAINED IN WIRE/LINE

Checks if the given (x, y) point is contained in the given wire
or line. Contained means that it specifies one of the points
making up the line.
The line must be orthogonal.

**************************************************************}

function contained(tx, ty: integer; w: drwptr): boolean;

var t: integer;
    l: region;

begin

   if w^.typ = twire then l := w^.w { wire }
   else if w^.typ = tbus then l := w^.bs.l { bus }
   else l := w^.l; { line }
   { exchange endpoints for compare }
   if ((l.s.x = l.e.x) and (l.s.y > l.e.y)) or
      ((l.s.y = l.e.y) and (l.s.x > l.e.x)) then begin { exchange }

     t := l.s.x; l.s.x := l.e.x; l.e.x := t;
     t := l.s.y; l.s.y := l.e.y; l.e.y := t

   end;
   contained := ((tx = l.s.x) and (ty >= l.s.y) and (ty <= l.e.y)) or
                ((ty = l.s.y) and (tx >= l.s.x) and (tx <= l.e.x))

end;
{}
{**************************************************************

CHECK COLINEAR

Checks if the line/wires given are colinear. To be so, they
must both be orthogonal, and of the same axis (vertical or
horizonal).
The lines should be of the same type.

**************************************************************}

function colinear(a, b: drwptr): boolean;

var ar, br: region;

begin

   { get the correct line }
   if a^.typ = twire then begin ar := a^.w; br := b^.w end
   else if a^.typ = tbus then begin ar := a^.bs.l; br := b^.bs.l end
   else begin ar := a^.l; br := b^.l end;
   colinear :=
      ((ar.s.x = ar.e.x) and (br.s.x = br.e.x) and
       (ar.s.x = br.s.x)) or
      ((ar.s.y = ar.e.y) and (br.s.y = br.e.y) and
       (ar.s.y = br.s.y))

end;
{}
{**************************************************************

COUNT COORDINATE ENDPOINTS

Given a point (x, y), returns the total number of matching
wire endpoints in the drawbase.
Only counts wires not colinear with the given wire.
Used to determine junction candidates.

**************************************************************}

function cntend(x, y: integer): byte;

var c: byte;
    l: drwptr;

begin

   c := 0; { clear count }
   l := curwin^.cs^.dl[ltfig]; { index list top }
   while l <> nil do begin { traverse list }

      { port: the else below binds to the INNER if, exactly as in
        SVS; the tbus arm is thus only reached when l^.typ = twire
        and the endpoints mismatch, and so never executes. Ported
        verbatim to keep behavior identical. }
      if l^.typ = twire then { is a wire }
         { check coordinance with our point }
         if ((x = l^.w.s.x) and (y = l^.w.s.y)) or
            ((x = l^.w.e.x) and (y = l^.w.e.y)) then
               c := c + 1 { count }
      else if l^.typ = tbus then { is a bus }
         { check coordinance with our point }
         if ((x = l^.bs.l.s.x) and (y = l^.bs.l.s.y)) or
            ((x = l^.bs.l.e.x) and (y = l^.bs.l.e.y)) then
               c := c + 1; { count }
      l := l^.next { link next wire in list }

   end;
   cntend := c { place result }

end;
{}
{**************************************************************

CREATE NEW NODE ENTRY

Allocates and initalizes a node entry. A temp name is assigned
to the node, and the node ordinal defaults to 0.

**************************************************************}

procedure crtnod(var n: nodptr);

begin

   new(n); { get a new node entry }
   n^.next := curwin^.cs^.nl; { link into list }
   curwin^.cs^.nl := n;
   n^.sl := nil; { clear lists }
   n^.bl := nil;
   n^.nl := nil;
   n^.bh := nil;
   curwin^.cs^.nc := curwin^.cs^.nc + 1; { count node }
   intstr(curwin^.cs^.nc, n^.name); { place as node name }
   n^.name[1] := 'N'; { place leading character }
   n^.nord := 0; { set first ordinal }
   n^.tmp := true { set name is a temp }

end;
{}
{**************************************************************

CREATE NEW BUS ENTRY

Allocates and initalizes a bus entry. A temp name is assigned
to the bus.

**************************************************************}

procedure crtbus(var b: busptr);

begin

   new(b); { get new bus entry }
   b^.next := curwin^.cs^.bl; { link into list }
   curwin^.cs^.bl := b;
   b^.bl := nil; { clear lists }
   b^.sl := nil;
   b^.nl := nil;
   curwin^.cs^.nc := curwin^.cs^.nc + 1; { count node }
   intstr(curwin^.cs^.nc, b^.name); { place as node name }
   b^.name[1] := 'N'; { place leading character }
   b^.tmp := true { set name is a temp }

end;
{}
{**************************************************************

MERGE NODE LISTS

Merges node list a into node list b and deletes node list a.

**************************************************************}

procedure nodmrg(a, b: nodptr);

var p: drwptr;

begin

   p := b^.nl; { index top entry of target }
   { find end of target list }
   while p^.nl <> nil do p := p^.nl;
   p^.nl := a^.nl; { link to head of source }
   p := a^.nl; { index top of that list }
   delnode(a); { delete node entry }
   while p <> nil do begin { correct source node heads }

      p^.nh := b; { set node }
      p := p^.nl { link next }

   end

end;
{}
{**************************************************************

ELIMINATE BUS DUPLICATES

The given bus is exastively matched for nodes with the same
ordinal, and those are merged where found.

**************************************************************}

procedure busdup(b: busptr);

var p1, p2, p3: nodptr;

begin

   p1 := b^.nl; { index 1st node in list }
   while p1 <> nil do begin { traverse search entry }

      p2 := p1^.bl; { index next entry }
      while p2 <> nil do begin { traverse match entry }

         p3 := p2^.bl; { save next }
         { merge with search node if same ordinal }
         if p2^.nord = p1^.nord then nodmrg(p2, p1);
         p2 := p3 { next entry }

      end;
      p1 := p1^.bl { next entry }

   end

end;
{}
{**************************************************************

MERGE BUS LISTS

Merges bus list a into bus list b and deletes node bus a.
Duplicate nodes (nodes with the same ordinal) are merged.

**************************************************************}

procedure busmrg(a, b: busptr);

var p: drwptr;
    np: nodptr;

begin

   { merge figure lists }
   p := b^.bl; { index top entry of target }
   { find end of target list }
   while p^.bs.bl <> nil do p := p^.bs.bl;
   p^.bs.bl := a^.bl; { link to head of source }
   p := a^.bl; { index top of that list }
   while p <> nil do begin { correct source bus heads }

      p^.bs.bh := b; { set bus }
      p := p^.bs.bl { link next }

   end;
   { merge node lists }
   if b^.nl = nil then b^.nl := a^.nl
   else begin

      np := b^.nl; { index top entry of target }
      { find end of target list }
      while np^.bl <> nil do np := np^.bl;
      np^.bl := a^.nl { link to head of source }

   end;
   np := a^.nl; { index top of that list }
   while np <> nil do begin { correct source bus nodes }

      np^.name := b^.name; { copy signal name }
      np^.tmp := b^.tmp; { copy temp flag }
      np^.bh := b; { set head entry }
      np := np^.bl { link next }

   end;
   delbus(a); { delete bus entry }
   busdup(b) { eliminate duplicate nodes }

end;
{}
{**************************************************************

ATTACH WIRE OR JUNCTION TO NODE

Attaches the first wire or junction into the node list of the
second wire or bus.
If the first already is part of a node list, and it's not the
same one as the destination, the entire node list for the
first is merged with the second, and the first node deleted.
Note that only entry a is allowed to have a null node list
pointer (in case of wire, junction or connector) or null bus
list (in case of bus).

**************************************************************}

procedure attwire(a, b: drwptr);

var p:  drwptr;
    np: nodptr;
    r:  boolean;

begin

   if (a^.typ <> tbus) and (b^.typ <> tbus) then begin

      { wire, junction or connectors }
      if a^.nh = nil then begin { not in any list }

         a^.nl := b^.nh^.nl; { link wire into list }
         b^.nh^.nl := a;
         a^.nh := b^.nh { link to head }

      end else if a^.nh <> b^.nh then begin { different lists, merge }

         { if one node is a temp, make sure that is overwritten }
         if not a^.nh^.tmp then begin p := a; a := b; b := p end;
         nodmrg(a^.nh, b^.nh) { merge nodes }

      end

   end else if (a^.typ = tbus) and (b^.typ = tbus) then begin

      { bus join }
      if a^.bs.bh = nil then begin { not in any list }

         a^.bs.bl := b^.bs.bh^.bl; { link bus into list }
         b^.bs.bh^.bl := a;
         a^.bs.bh := b^.bs.bh { link to head }

      end else if a^.bs.bh <> b^.bs.bh then begin { different lists, merge }

         { if one bus is a temp, make sure that is overwritten }
         if not a^.bs.bh^.tmp then begin p := a; a := b; b := p end;
         busmrg(a^.bs.bh, b^.bs.bh) { merge busses }

      end

   end else begin { join wire, junction or connector to bus }

      if a^.typ = tbus then begin { source is bus }

         { check in bus list }
         if a^.bs.bh = nil then begin { no, enter new bus }

            crtbus(a^.bs.bh); { get new bus entry }
            a^.bs.bh^.bl := a; { link in bus }
            a^.bs.bl := nil

         end

      end else if a^.nh = nil then begin { not in any list }

         { must give entry a node, so that it can be placed }
         crtnod(a^.nh); { get a new node entry }
         a^.nh^.nl := a; { link in wire }
         a^.nl := nil { clear next }

      end;
      { place operands }
      if a^.typ = tbus then { exchange }
         begin p := a; a := b; b := p; r := true end
      else r := false;
      { place node into bus list }
      if a^.nh^.bh = nil then begin

         { node is not presently in a bus }
         a^.nh^.bl := b^.bs.bh^.nl; { link into list }
         b^.bs.bh^.nl := a^.nh;
         a^.nh^.bh := b^.bs.bh; { place head linkage }
         if a^.nh^.tmp or not b^.bs.bh^.tmp then begin

            { node is temp, or bus is not a temp }
            a^.nh^.name := b^.bs.bh^.name; { adjust name }
            a^.nh^.tmp := b^.bs.bh^.tmp

         end else begin { node annihilates bus }

            b^.bs.bh^.name := a^.nh^.name; { rename bus }
            b^.bs.bh^.tmp := a^.nh^.tmp; { place temp status }
            np := b^.bs.bh^.nl; { index top of node list }
            while np <> nil do begin { rename nodes }

               np^.name := a^.nh^.name; { place name }
               np^.tmp := a^.nh^.tmp;
               np := np^.bl { link next }

            end

         end;
         busdup(b^.bs.bh) { eliminate duplicates }

      end else if a^.nh^.bh <> b^.bs.bh then begin { different busses }

         if r then { operands have been reversed,
                     ensure left side is deleted }
            busmrg(b^.bs.bh, a^.nh^.bh) { merge busses }
         else
            busmrg(a^.nh^.bh, b^.bs.bh) { merge busses }

      end

   end

end;
{}
{**************************************************************

PLACE JUNCTION

Places a junction at the given (x, y) coordinate. This includes
entry into the draw list and display.
Checks if any previous junction exists at that point, and
rejects the request if so.
Returns the node entry.

**************************************************************}

procedure plcjun(x, y: integer; var p: drwptr);

var p1: drwptr;

begin

   { search for previous junction }
   p1 := curwin^.cs^.dl[ltfig]; { index top of list }
   p := nil; { clear result }
   while p1 <> nil do begin { traverse }

      if p1^.typ = tjunction then { is a junction }
         if (p1^.j.x = x) and (p1^.j.y = y) then
            begin p := p1; p1 := nil end { terminate }
         else p1 := p1^.next
      else p1 := p1^.next

   end;
   if p = nil then begin { no previous junction }

      new(p); { get new draw entry }
      p^.typ := tjunction; { set type }
      p^.j.x := x; { place coordinates }
      p^.j.y := y;
      p^.cl := black; { set color }
      p^.nh := nil; { set no node }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      { modify bounding box }
      setbound(x-(curwin^.cs^.js-1), y-(curwin^.cs^.js-1));
      setbound(x+(curwin^.cs^.js-1), y+(curwin^.cs^.js-1));
      setsbound(x-(curwin^.cs^.js-1), y-(curwin^.cs^.js-1));
      setsbound(x+(curwin^.cs^.js-1), y+(curwin^.cs^.js-1));
      chktar; { check target change }

   end

end;
{}
{**************************************************************

LINK JUNCTION

Accepts a (x, y) point for a junction. The junction
is inserted into the node list of any wire that it crosses.
Will also join different nodes that cross under the junction.
If none are found, the junction will get a brand new node.

**************************************************************}

procedure lnkjun(j: drwptr);

var p, l: drwptr;
    n:    nodptr;

begin

   j^.nh := nil; { set in no node list }
   l := nil; { set no last }
   p := curwin^.cs^.dl[ltfig]; { index top of drawing list }
   while p <> nil do begin { traverse }

      if (p^.typ = twire) or (p^.typ = tbus) then
         { is a wire or bus }
         if orthogonal(p) then { is a candidate }
            if contained(j^.j.x, j^.j.y, p) then begin

         attwire(j, p); { attach junction to wire }
         { if there is a last, join with this }
         if l <> nil then attwire(l, p);
         l := p { save this as last }

      end;
      p := p^.next { link next figure }

   end;
   if j^.nh = nil then begin { junction not attached to node }

      { no wires, a lone junction must get a node }
      crtnod(n); { get a new node entry }
      n^.nl := j; { link in junction }
      j^.nl := nil; { clear next }
      j^.nh := n { set head pointer }

   end

end;
{}
{**************************************************************

LINK WIRE OR BUS TO NODE(S)

The given wire is linked into a node. First, the wire is checked
for intersection with existing wires, and if found, that node
is linked. Otherwise, the wire gets its own, new node.
Intersection is determined in two ways. Endpoint intersection
is when the (x,y) start or end points are co-ordinate. This works
on any line.
The second type is when both lines are 90 deg orthogonal, and
one line's endpoint meets another's midsection. This case
automatically generates a junction between the lines.

**************************************************************}

procedure lnkwire(d: drwptr);

var l, l1: drwptr;  { drawing list pointer }
    f:     boolean; { wire found flag }
    n:     nodptr;  { node list pointer }

{ place midline junction }

procedure midatt(x, y: integer);

var p: drwptr;

begin

   if not colinear(d, l) then begin

      plcjun(x, y, p); { place junction }
      { display junction }
      pier(x, y, curwin^.cs^.js, black, curwin^.cs^.vp.v);
      attwire(p, l) { attach to wire }

   end;
   attwire(d, l); { attach to this wire }
   f := true { flag wire found }

end;

begin

   { check for colinear lines }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      l1 := l^.next; { save next }
      if l^.typ = twire then
         { both lines are orthogonal and colinear }
         if colinear(d, l) and
            (contained(d^.w.s.x, d^.w.s.y, l) or
             contained(d^.w.e.x, d^.w.e.y, l)) then
            join(d, l); { joint the two lines together }
      l := l1 { link next }

   end;
   d^.nh := nil; { clear node head }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      if l^.typ = twire then begin

         { figures are wire or bus, check various intersections }
         if (orthogonal(d) or orthogonal(l)) then begin

            { figure is a wire, and one of the wires is orthogonal }
            { check any of the endpoints co-ordinate }
            if ((d^.w.s.x = l^.w.s.x) and (d^.w.s.y = l^.w.s.y)) or
               ((d^.w.s.x = l^.w.e.x) and (d^.w.s.y = l^.w.e.y)) then begin

               attwire(d, l); { attach to this wire }
               { if we reach 3, place a junction }
               if cntend(d^.w.s.x, d^.w.s.y) >= 2 then begin

                  plcjun(d^.w.s.x, d^.w.s.y, l1); { place junction }
                  pier(d^.w.s.x, d^.w.s.y, curwin^.cs^.js, black,
                       curwin^.cs^.vp.v); { display junction }
                  attwire(l1, l) { attach to wire }

               end

            end else if ((d^.w.e.x = l^.w.s.x) and (d^.w.e.y = l^.w.s.y)) or
                        ((d^.w.e.x = l^.w.e.x) and (d^.w.e.y = l^.w.e.y)) then begin

               attwire(d, l); { attach to this wire }
               { if we reach 3, place a junction }
               if cntend(d^.w.e.x, d^.w.e.y) >= 2 then begin

                  plcjun(d^.w.e.x, d^.w.e.y, l1); { place junction }
                  pier(d^.w.e.x, d^.w.e.y, curwin^.cs^.js, black,
                       curwin^.cs^.vp.v); { display junction }
                  attwire(l1, l) { attach to wire }

               end

            end else
            { check both lines orthogonal, and
              an endpoint "contained" within the other }
            if orthogonal(d) and orthogonal(l) then begin

               if contained(d^.w.s.x, d^.w.s.y, l) then
                  midatt(d^.w.s.x, d^.w.s.y)
               else if contained(d^.w.e.x, d^.w.e.y, l) then
                  midatt(d^.w.e.x, d^.w.e.y)
               else if contained(l^.w.s.x, l^.w.s.y, d) then
                  midatt(l^.w.s.x, l^.w.s.y)
               else if contained(l^.w.e.x, l^.w.e.y, d) then
                  midatt(l^.w.e.x, l^.w.e.y)

            end

         end

      end else if ((l^.typ = tjunction) or
                   (l^.typ = tconnect)) and orthogonal(d) then
         { junction, see if crosses line }
         if contained(l^.j.x, l^.j.y, d) then
            attwire(d, l); { attach to junction }
      l := l^.next { index next entry }

   end;
   { check node was found }
   if d^.nh = nil then begin { no match, enter new node }

      crtnod(n); { get new node entry }
      n^.nl := d; { link in wire }
      d^.nl := nil; { clear next }
      d^.nh := n { set head pointer }

   end

end;
{}
{**************************************************************

LINK BUS TO NODE(S)

The given bus is linked into a bus list. First, the bus is checked
for intersection with existing buses, and if found, that bus list
is linked. Otherwise, the bus gets its own, new bus list.
Intersection is determined in two ways. Endpoint intersection
is when the (x,y) start or end points are co-ordinate. This works
on any line.
The second type is when both lines are 90 deg orthogonal, and
one line's endpoint meets another's midsection. This case
automatically generates a junction between the lines.

**************************************************************}

procedure lnkbus(d: drwptr);

var l, l1: drwptr;  { drawing list pointer }
    f:     boolean; { wire found flag }
    b:     busptr;  { bus pointer }

{ place midline junction }

procedure midatt(x, y: integer);

var p: drwptr;

begin

   if not colinear(d, l) then begin

      plcjun(x, y, p); { place junction }
      pier(x, y, curwin^.cs^.js, black, curwin^.cs^.vp.v); { display junction }
      attwire(p, l) { attach to wire }

   end;
   attwire(d, l); { attach to this wire }
   f := true { flag wire found }

end;

begin

   { check for colinear lines }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      l1 := l^.next; { save next }
      if l^.typ = tbus then { bus }
         { both lines are orthogonal and colinear }
         if colinear(d, l) and
            (contained(d^.bs.l.s.x, d^.bs.l.s.y, l) or
             contained(d^.bs.l.e.x, d^.bs.l.e.y, l)) then
            join(d, l); { joint the two lines together }
      l := l1 { link next }

   end;
   d^.bs.bh := nil; { clear bus head }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      if l^.typ = tbus then begin

         { check various intersections }
         { check any of the endpoints co-ordinate }
         if ((d^.bs.l.s.x = l^.bs.l.s.x) and
             (d^.bs.l.s.y = l^.bs.l.s.y)) or
            ((d^.bs.l.s.x = l^.bs.l.e.x) and
             (d^.bs.l.s.y = l^.bs.l.e.y)) then begin

            attwire(d, l); { attach to this bus }
            { if we reach 3, place a junction }
            if cntend(d^.bs.l.s.x, d^.bs.l.s.y) >= 2 then begin

               plcjun(d^.bs.l.s.x, d^.bs.l.s.y, l1); { place junction }
               { display junction }
               pier(d^.bs.l.s.x, d^.bs.l.s.y, curwin^.cs^.js, black,
                    curwin^.cs^.vp.v);
               attwire(l1, l) { attach to wire }

            end

         end else if ((d^.bs.l.e.x = l^.bs.l.s.x) and
                      (d^.bs.l.e.y = l^.bs.l.s.y)) or
                     ((d^.bs.l.e.x = l^.bs.l.e.x) and
                      (d^.bs.l.e.y = l^.bs.l.e.y)) then begin

            attwire(d, l); { attach to this bus }
            { if we reach 3, place a junction }
            if cntend(d^.bs.l.e.x, d^.bs.l.e.y) >= 2 then begin

               plcjun(d^.bs.l.e.x, d^.bs.l.e.y, l1); { place junction }
               { display junction }
               pier(d^.bs.l.e.x, d^.bs.l.e.y, curwin^.cs^.js, black,
                    curwin^.cs^.vp.v);
               attwire(l1, l) { attach to wire }

            end

         end else
         { check both lines orthogonal, and
           an endpoint "contained" within the other }
         if contained(d^.bs.l.s.x, d^.bs.l.s.y, l) then
            midatt(d^.bs.l.s.x, d^.bs.l.s.y)
         else if contained(d^.bs.l.e.x, d^.bs.l.e.y, l) then
            midatt(d^.bs.l.e.x, d^.bs.l.e.y)
         else if contained(l^.bs.l.s.x, l^.bs.l.s.y, d) then
            midatt(l^.bs.l.s.x, l^.bs.l.s.y)
         else if contained(l^.bs.l.e.x, l^.bs.l.e.y, d) then
            midatt(l^.bs.l.e.x, l^.bs.l.e.y)

      end else if (l^.typ = tjunction) or (l^.typ = tconnect)  then
         { junction, see if crosses line }
         if contained(l^.j.x, l^.j.y, d) then
            attwire(d, l); { attach to junction }
      l := l^.next { index next entry }

   end;
   if d^.bs.bh = nil then begin { no match, enter new node }

      crtbus(b); { get new bus entry }
      b^.bl := d; { link in bus }
      d^.bs.bl := nil;
      d^.bs.bh := b { set head pointer }

   end

end;
{}
{ UNRESOLVED: names used here that are defined outside this fragment:
     puck                        - global (icddef)
     curwin, smslst, bsmlst      - globals (icddef)
     intstr                      - frag_c.pas
     pier                        - frag_b.pas
     setbound, setsbound, chktar - frag_d.pas
  drwfig (being ported in parallel as frag_f) is NOT referenced in this
  range. Integrator: replace the resptr stub in icdui_base.pas with
     procedure resptr; forward;
  (frag_d's mode handlers call resptr, and this fragment must follow
  frag_d for setbound/setsbound/chktar) — verified to build with this
  fragment concatenated between frag_e and frag_m. }
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

function blockdist(x1, y1, x2, y2: integer): integer;

var d: integer;

begin

   if (x >= x1) and (x <= x2) and (y >= y1) and (y <= y2) then
      d := 0 { inside square }
   else { outside, calculate as for box }
      d := boxdist(x1, y1, x2, y2, x, y);
   blockdist := d { return result }

end;

{ find distance to predefined cell }

function pdcdist(o: point; rm: rotmod; xl, yl: integer): integer;

var d: integer;

begin

   { cells are treated as if they were filled boxes }
   if rm in [rm0, rm180, rmm0, rmm180] then { normal }
      d := blockdist(o.x, o.y, o.x+xl*1500, o.y+yl*1500)
   else { on side }
      d := blockdist(o.x, o.y, o.x+yl*1500, o.y+xl*1500);
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
         d := blockdist(c.r.s.x, c.r.s.y, c.r.e.x, c.r.e.y);

      tjunction: begin { wire junction }

         { junctions are treated as filled circles }
         d := dist(j.x, j.y, x, y);
         if d <= curwin^.cs^.js then d := 0 { inside the circle }
         else d := d - curwin^.cs^.js { distance to circle }

      end;

      tconnect: { connector }
         { connectors are treated as if they were filled boxes }
         d := blockdist(j.x-curwin^.cs^.cs, j.y-curwin^.cs^.cs,
                        j.x+curwin^.cs^.cs, j.y+curwin^.cs^.cs);

      tcell: with cr do { subcell }
         { cells are treated as if they were filled boxes }
         if rm in [rm0, rm180, rmm0, rmm180] then { normal }
            d := blockdist(o.x, o.y,
                           o.x+abs(cp^.bbex-cp^.bbsx),
                           o.y+abs(cp^.bbey-cp^.bbsy))
         else { on side }
            d := blockdist(o.x, o.y,
                           o.x+abs(cp^.bbey-cp^.bbsy),
                           o.y+abs(cp^.bbex-cp^.bbsx));

      tnmos, tpmos:  { xstrs }
         d := pdcdist(o, rm, 7, 8); { find distance }

      tcap: { capacitor }
         d := pdcdist(o, rm, 4, 5); { find distance }

      tres: { resistor }
         d := pdcdist(o, rm, 4, 20); { find distance }

      tdiode: { diode }
         d := pdcdist(o, rm, 4, 8); { find distance }

      tvdd, tvss: { power connectors }
         d := pdcdist(o, rm, 2, 4); { find distance }

      tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
      tnwell, tpwell, tcont: { filled layer }
         d := blockdist(b.s.x, b.s.y, b.e.x, b.e.y);

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

var x1, y1, x2, y2: integer;

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

var p: drwptr;  { figure pointer }
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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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

var i:  btsinx;

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

var p: drwptr;  { figure pointer }
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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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

var l:       drwptr;
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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

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
   frame(((maxx-minx) div 2)-(max div 2), y,
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
{******************************************************************************

FRAGMENT G: COMMAND LAYER

Ported from icdc.pas (lines ~2056-4992). Contains the mode set
routines, the drawing/entry commands (line/box/circle/arc/text/
junction/connector/cell placement), the in-button sequential
edits, the view/size/block save tableaus, the window resize/move/
maximize handlers, the button command dispatcher and the keyboard
command processor.

Port notes:

1. The grid indicator arrays (dgridsx/dgridsy) and their fill
   routines (plcgrid/plc10sgrid) were deleted in the frag_d port;
   the grids draw directly over the real extent of the view. All
   dogrid/do10sgrid call sites here are converted to the four
   coordinate form, and white-outs that relied on the stale array
   contents are moved ahead of the spacing change so they cover
   the old grid. Each site is marked with a "port:" comment.
2. boxsav/boxrst are the xor rubber-band pair from frag_d; the
   linarr/lininx save index parameters are deleted and boxrst
   takes the draw color (must match the boxsav color, lmagenta).
3. The window screen region field winrec.r was replaced by the
   window viewport (curwin^.wv.v) in the port; resize/move/
   maximize are converted to read wv.v and to reposition through
   plcwin. Each conversion is marked "port:".
4. The nested setbox/resbox in movewin collide with the global
   rubber-band setbox/resbox (frag_b) and are renamed
   setsizbox/ressizbox.
5. command is converted to dispatch (event pump model); dokeyboard
   is converted to a per-character entry. updpuck, gettim/elapsed,
   kbdrdy/kbdinp and the screen blank machinery do not survive.
6. Printer code (doprint, strpedt, dopedt, scnprt, printpop) is
   not ported in this pass; call sites are emptied and marked
   "port: printer pass deferred".

******************************************************************************}

{}
{**************************************************************

SET LINE LIMIT MODE

Sets the line limit to 90, 45 or any. The button activated is
the current one.

**************************************************************}

procedure setllim;

begin

   if (curbut in [b90, b45, bany]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      butina(b90); { set buttons inactive }
      butina(b45);
      butina(bany);
      butact(curbut)

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET TRANSFORMATION MODE

Registers the current transform mode.

**************************************************************}

procedure settrm;

begin

   if not button[birmir].act then begin { unmirrored figures }

      if button[bir0].act then trnfrm := rm0 { 0 deg }
      else if button[bir90].act then trnfrm := rm90 { 90 deg }
      else if button[bir180].act then trnfrm := rm180 { 180 deg }
      else trnfrm := rm270 { 270 deg }

   end else begin { mirrored figures }

      if button[bir0].act then trnfrm := rmm0 { 0 deg }
      else if button[bir90].act then trnfrm := rmm90 { 90 deg }
      else if button[bir180].act then trnfrm := rmm180 { 180 deg }
      else trnfrm := rmm270 { 270 deg }

   end

end;
{}
{**************************************************************

SET PLACEMENT MODE MIRROR

Sets mirrored as the current placement mode.

**************************************************************}

procedure setmirm;

begin

   if (curbut = birmir) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      if button[birmir].act then butina(birmir) { turn mode off }
      else butact(birmir); { turn mode on }
      settrm { set transform mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET ROTATION MODE

Sets the current rotation mode.

**************************************************************}

procedure setrot;

begin

   if (curbut in [bir90, bir180, bir270, bir0]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      butina(bir90); { clear the other rotates }
      butina(bir180);
      butina(bir270);
      butina(bir0);
      butact(curbut); { activate our button }
      settrm { set transform mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

LINE, BOLD LINE, WIRE OR BUS

Handles the mode, setup and entry of these objects.

**************************************************************}

procedure doline;

var l:      drwptr; { line entry }
    i:      btsinx;
    p:      point;
    el:     boolean; { line was entered }

begin

   el := false; { set no line entered }
   if (curbut in [bline, bbline, bwire, bbus]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { mark line mode }
      stopact; { stop all modes }
      butact(curbut); { set line mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bline, bbline, bwire, bbus]) and
               inactive(cur) and
               (puck.b[2].a or puck.b[1].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { enter line }
      setend; { make sure end is established }
      cruler; { clear ruler }
      new(l); { get new draw entry }
      { set type }
      if drmbut = bline then l^.typ := tline
      else if drmbut = bbline then l^.typ := tbline
      else if drmbut = bwire then l^.typ := twire
      else l^.typ := tbus;
      if drmbut = bwire then begin { wire }

         l^.w.s := str; { place coordinates }
         l^.w.e := endp;
         { rationalize line }
         ratlin(l^.w.s.x, l^.w.s.y, l^.w.e.x, l^.w.e.y);

      end else if drmbut = bbus then begin

         l^.bs.l.s := str; { place coordinates }
         l^.bs.l.e := endp;
         { rationalize line }
         ratlin(l^.bs.l.s.x, l^.bs.l.s.y, l^.bs.l.e.x, l^.bs.l.e.y);

      end else begin

         l^.l.s := str; { place coordinates }
         l^.l.e := endp;
         { rationalize line }
         ratlin(l^.l.s.x, l^.l.s.y, l^.l.e.x, l^.l.e.y);

      end;
      l^.cl := black; { set color }
      setbound(str.x, str.y); { modify bounding box }
      setbound(endp.x, endp.y);
      setsbound(str.x, str.y); { modify symbol bounding box }
      setsbound(endp.x, endp.y);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      lindwn := false; { since we have overwritten saved line }
      if drmbut = bwire then begin { link in wire }

         rescur; { lift cursor }
         lnkwire(l);
         setcur { drop cursor }

      end else if drmbut = bbus then begin { link in bus }

         rescur; { lift cursor }
         lnkbus(l);
         setcur { drop cursor }

      end;
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      { display node and ordinal }
      if drmbut = bwire then begin

         { place node name in display }
         button[bnamev].s := l^.nh^.name; { place node name }
         updbut(bnamev); { update }
         { place ordinal in display }
         intstr(l^.nh^.nord, button[bnord].s); { place ordinal }
         trmzer(button[bnord].s); { trim zeros }
         { move back }
         for i := 1 to 4 do
            button[bnord].s[i] := button[bnord].s[i+4];
         updbut(bnord) { update }

      end else if drmbut = bbus then begin

         { place node name in display }
         button[bnamev].s := l^.bs.bh^.name; { place bus name }
         updbut(bnamev); { update }
         { clear ordinal }
         button[bnord].s := '        ';
         updbut(bnord) { update }

      end;
      drmbut := bnull; { reset mode }
      el := true { set line was entered }

   end;
   if inactive(cur) and (puck.b[1].a or (puck.b[2].a and not el)) then begin

      { begin line }
      { find real position }
      p := cur;
      realc(p, curwin^.cs^.vp); { convert coordinates }
      if el then
         { line previously entered, set for continuation }
         str := endp { set start of line to old end }
      else { new line }
         str := p; { set start of line }
      tstr := str; { save as true start }
      snapto(str.x, str.y); { snap that }
      setend; { set up end }
      rescur; { remove cursor }
      setline; { set line to screen }
      setcur; { replace cursor }
      { set draw mode }
      if button[bline].act then drmbut := bline
      else if button[bbline].act then drmbut := bbline
      else if button[bwire].act then drmbut := bwire
      else if button[bbus].act then drmbut := bbus;
      updrul { update ruler }

   end
   { resptr (reset buttons) disabled in original }
   { port: nested-brace comment flattened }

end;
{}
{**************************************************************

BOX, BOLDBOX

Handles the box draw mode. Handles the activation of the button,
the start and cursor draw, and the box entry.

**************************************************************}

procedure dobox;

var l:              drwptr; { line entry }

begin

   if (curbut in [bbox, bbbox]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { mark box mode }
      stopact; { stop all modes }
      butact(curbut); { set line mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bbox, bbbox]) and inactive(cur) and
               (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
                (puck.b[2].d and puck.b[2].dg)) then begin

      { enter box }
      endp := cur; { make sure end is established }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y);
      cruler; { clear ruler }
      new(l); { get new draw entry }
      if drmbut = bbox then l^.typ := tbox { set type }
      else l^.typ := tbbox;
      l^.b.s.x := str.x; { place coordinates }
      l^.b.s.y := str.y;
      l^.b.e.x := endp.x;
      l^.b.e.y := endp.y;
      { rationalize it }
      ratbox(l^.b.s.x, l^.b.s.y, l^.b.e.x, l^.b.e.y);
      l^.cl := black; { set color }
      setbound(l^.b.s.x, l^.b.s.y); { modify bounding box }
      setbound(l^.b.e.x, l^.b.e.y);
      setsbound(l^.b.s.x, l^.b.s.y); { modify symbol bounding box }
      setsbound(l^.b.e.x, l^.b.e.y);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      boxdwn := false; { since we have overwritten box }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      drmbut := bnull { reset line mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { begin box }
      str := cur; { set start of box }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      tstr := str; { save as true start }
      snapto(str.x, str.y); { snap that }
      endp := str; { set end of box }
      rescur; { remove cursor }
      setbox; { set line to screen }
      zruler; { update ruler }
      setcur; { replace cursor }
      if button[bbox].act then drmbut := bbox { set box mode }
      else drmbut := bbbox

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

CIRCLE

Handles the circle draw. The button is turned on, or the circle
is started, or the circle is entered.

**************************************************************}

procedure docircle;

var l: drwptr; { line entry }

begin

   if (curbut = bcircle) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set circle mode }
      stopact; { stop all modes }
      butact(bcircle); { set circle mode active }
      modbut := bcircle;
      dsmbut := bcircle

   end else if (drmbut = bcircle) and inactive(cur) and
      (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
       (puck.b[2].d and puck.b[2].dg)) then begin { circle in progress }

      { enter circle }
      str := cur; { make sure end is established }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      { find radius }
      rad := dist(cen.x, cen.y, str.x, str.y);
      str.x := cen.x; { project to x axis }
      str.y := cen.y + rad;
      snapto(str.x, str.y);
      { recalculate radius }
      rad := abs(str.y-cen.y);
      new(l); { get new draw entry }
      l^.typ := tarc; { set type }
      l^.a.c.x := cen.x; { place parameters }
      l^.a.c.y := cen.y;
      l^.a.s.x := str.x;
      l^.a.s.y := str.y;
      l^.a.e.x := str.x-1;
      l^.a.e.y := str.y;
      l^.a.r := rad;
      l^.cl := black; { set color }
      setbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r); { modify bounding box }
      setbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      { modify symbol bounding box }
      setsbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r);
      setsbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      cirdwn := false; { since we have overwritten circle }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      drmbut := bnull; { reset line mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { start circle }
      cen := cur; { set center of circle }
      realc(cen, curwin^.cs^.vp); { convert coordinates }
      tcen := cen; { save true center }
      snapto(cen.x, cen.y); { snap that }
      str := cen; { set start and end points }
      rad := 1; { set single length radius }
      rescur; { remove cursor }
      setcircle; { set line to screen }
      setcur; { replace cursor }
      drmbut := bcircle { set circle mode }

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

ARC

Handles the arc draw mode. The button is activated, and the
arc started, then the final arc registered.

**************************************************************}

procedure doarc;

var l:                         drwptr; { line entry }

begin

   if (curbut = barc) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set arc mode }
      stopact; { stop all modes }
      butact(barc); { set arc mode active }
      modbut := barc;
      dsmbut := barc

   end else if (drmbut = barc) and inactive(cur) and arcsph and
               (puck.b[1].a or puck.b[2].a) then begin

      { enter arc }
      new(l); { get new draw entry }
      l^.typ := tarc; { set type }
      l^.a.c.x := cen.x; { place parameters }
      l^.a.c.y := cen.y;
      l^.a.s.x := str.x;
      l^.a.s.y := str.y;
      l^.a.e.x := endp.x;
      l^.a.e.y := endp.y;
      l^.a.r := rad;
      l^.cl := black; { set color }
      setbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r); { modify bounding box }
      setbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      { modify symbol bounding box }
      setsbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r);
      setsbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      arcdwn := false; { since we have overwritten arc }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      drmbut := bnull { reset mode }

   end else if (drmbut = barc) and inactive(cur) and
               (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
                (puck.b[2].a and puck.b[2].dg)) then begin

      { begin arc second phase }
      endp := cur; { set end of arc }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y); { snap to location }
      arcflat := true; { set flat arc }
      arcsph := true { set arc 2nd phase }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin { in active area }

      str := cur; { set start of arc }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      tstr := str; { save as true start }
      endp := str; { save as end }
      snapto(str.x, str.y); { snap to location }
      rescur; { remove cursor }
      setline; { set flat arc (line) to screen }
      setcur; { replace cursor }
      arcflat := true; { set flat arc }
      arcsph := false; { set 1st phase }
      drmbut := barc { set arc mode }

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

TEXT

Handles text entry. The button is turned on as activated.
The text entry cursor is placed on an active area click,
and any characters typed on the keyboard are entered at that
point (independent of the cursor).

**************************************************************}

procedure dotext;

begin

   if (curbut = btext) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set text mode }
      stopact; { stop all modes }
      butact(btext); { set text mode active }
      modbut := btext;
      dsmbut := curbut

   end else if inactive(cur) and (modbut = btext) and
               (puck.b[1].a or puck.b[2].a) then begin

      rescur; { remove cursor }
      if drmbut = btext then restcur; { remove present text cursor }
      { set rotation status }
      textrot := trnfrm in [rm90, rm270, rmm90, rmm270];
      tcur := cur; { save as text entry cursor }
      realc(tcur, curwin^.cs^.vp); { convert coordinates }
      snapto(tcur.x, tcur.y); { snap coordinates }
      settcur; { set text cursor }
      drmbut := btext; { set text entry in progress }
      new(texttop); { get new draw entry }
      texttop^.typ := tchar; { set type }
      texttop^.c.r.s.x := tcur.x; { place coordinates }
      if textrot then { rotated }
         texttop^.c.r.s.y := tcur.y
      else { normal }
         texttop^.c.r.s.y := tcur.y-chrhdt*curwin^.cs^.ts;
      texttop^.c.s := curwin^.cs^.ts; { place current scale }
      texttop^.cl := black; { set color }
      { set rotation mode }
      if textrot then texttop^.rm := rm90 else texttop^.rm := rm0;
      texttop^.c.l := nil; { clear character list }
      setcur { replace cursor }

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

ENTER TEXT CHARACTER

Places a single vector character.

**************************************************************}

procedure enttext(c: char);

var cp, cp1: chrptr;

begin

   if ord(c) >= 128 then c := chr(ord(c)-128); { remove parity bit }
   if c >= ' ' then
      begin { valid char }

      rescur; { remove cursor }
      restcur; { remove text cursor }
      { place character }
      if c <> ' ' then begin

         if textrot then { rotated }
            vchar(tcur.x, tcur.y, c, curwin^.cs^.ts,
                  black, textrot, curwin^.cs^.vp.v)
         else { normal }
            vchar(tcur.x, tcur.y-chrhdt*curwin^.cs^.ts, c, curwin^.cs^.ts,
                  black, textrot, curwin^.cs^.vp.v)

      end;
      if texttop^.c.l = nil then begin { first character to place }

         new(texttop^.c.l); { get character entry }
         cp := texttop^.c.l { index }

      end else begin { search for end }

         cp := texttop^.c.l; { index top of character list }
         { search end }
         while cp^.next <> nil do cp := cp^.next;
         new(cp^.next); { allocate entry }
         cp := cp^.next { index }

      end;
      cp^.next := nil; { clear next }
      cp^.c := c; { place character }
      { update bounds for character }
      if textrot then begin { rotated }

         texttop^.c.r.e.x := tcur.x+chrhdt*curwin^.cs^.ts;
         texttop^.c.r.e.y := tcur.y+chrwdt*curwin^.cs^.ts

      end else begin { normal }

         texttop^.c.r.e.x := tcur.x+chrwdt*curwin^.cs^.ts;
         texttop^.c.r.e.y := tcur.y

      end;
      { move cursor to next position (with intercharacter spacing ) }
      if textrot then { rotated text }
         tcur.y := tcur.y+chrwdt*curwin^.cs^.ts+chrspc*curwin^.cs^.ts
      else { normal text }
         tcur.x := tcur.x+chrwdt*curwin^.cs^.ts+chrspc*curwin^.cs^.ts;
      settcur; { reset text cursor }
      setcur { reset cursor }

   end else if c = chr(8) then begin { erase last character }

      if texttop^.c.l <> nil then begin { text string not empty }

         rescur; { remove cursor }
         restcur; { remove text cursor }
         cp := texttop^.c.l; { index top of character list }
         { search end }
         while cp^.next <> nil do cp := cp^.next;
         { move cursor back to last position }
         if textrot then { rotated text }
            tcur.y := tcur.y-chrwdt*curwin^.cs^.ts-chrspc*curwin^.cs^.ts
         else { normal text }
            tcur.x := tcur.x-chrwdt*curwin^.cs^.ts-chrspc*curwin^.cs^.ts;
         if cp^.c <> ' ' then begin

            if textrot then begin { rotated }

               vchar(tcur.x, tcur.y, cp^.c, curwin^.cs^.ts,
                     white, textrot, curwin^.cs^.vp.v);
               rregion(tcur.x, tcur.y,
                       tcur.x+chrhdt*curwin^.cs^.ts,
                       tcur.y+chrwdt*curwin^.cs^.ts)

            end else begin { normal }

               vchar(tcur.x, tcur.y-chrhdt*curwin^.cs^.ts, cp^.c,
                     curwin^.cs^.ts, white, textrot, curwin^.cs^.vp.v);
               rregion(tcur.x, tcur.y-chrhdt*curwin^.cs^.ts,
                       tcur.x+chrwdt*curwin^.cs^.ts,
                       tcur.y)

            end

         end;
         { remove character from list }
         if cp = texttop^.c.l then texttop^.c.l := nil
         else begin

            cp1 := texttop^.c.l; { index top entry }
            { find last entry }
            while cp1^.next <> cp do cp1 := cp1^.next;
            cp1^.next := nil { remove }

         end;
         settcur; { reset text cursor }
         setcur { reset cursor }

      end

   end else if c = chr(13) then begin { terminate mode }

      rescur; { remove cursor }
      restcur; { remove text cursor }
      if texttop^.c.l <> nil then begin { not empty }

         texttop^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
         curwin^.cs^.dl[ltfig] := texttop;
         setbound(texttop^.c.r.s.x, texttop^.c.r.s.y); { set bounds }
         setbound(texttop^.c.r.e.x, texttop^.c.r.e.y);
         setsbound(texttop^.c.r.s.x, texttop^.c.r.s.y); { set symbol bounds }
         setsbound(texttop^.c.r.e.x, texttop^.c.r.e.y);
         chktar; { check target change }

      end;
      setcur; { replace cursor }
      drmbut := bnull { cancel text mode }

   end

end;
{}
{**************************************************************

JUNCTION

Handle junction mode. The button is turned on. The connector is
entered at the current location.

**************************************************************}

procedure junction;

var p:  drwptr;
    i:  btsinx;
    rp: point;

begin

   if (curbut = bjunction) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set junction mode }
      stopact; { stop all modes }
      butact(bjunction); { set junction mode active }
      modbut := bjunction;
      dsmbut := bjunction

   end else if inactive(cur) and (modbut = bjunction) and
               (puck.b[1].a or puck.b[2].a) then begin

      { enter junction }
      rp := cur; { find location }
      realc(rp, curwin^.cs^.vp); { convert coordinates }
      snapto(rp.x, rp.y);
      plcjun(rp.x, rp.y, p); { place new junction }
      rescur; { remove cursor }
      drwfig(p, p^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur; { replace cursor }
      lnkjun(p); { place junction at location }
      { place node name in display }
      button[bnamev].s := p^.nh^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      intstr(p^.nh^.nord, button[bnord].s); { place ordinal }
      trmzer(button[bnord].s); { trim zeros }
      { move back }
      for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
      updbut(bnord) { update }

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

CONNECTOR

Handles the connector mode. If the button is activated, the
connector mode is entered. If but1 or but2 is entered in the
active region during connector mode, a connector is placed at
that position.

**************************************************************}

procedure connect;

var l: drwptr;
    i: btsinx;
    p: point;

begin

   if (curbut = bconnect) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set connector mode }
      stopact; { stop all modes }
      butact(bconnect); { set connector mode active }
      modbut := bconnect;
      dsmbut := bconnect

   end else if inactive(cur) and (modbut = bconnect) and
               (puck.b[1].a or puck.b[2].a) then begin

      p := cur; { find location }
      realc(p, curwin^.cs^.vp); { convert coordinates }
      snapto(p.x, p.y);
      new(l); { get new draw entry }
      l^.typ := tconnect; { set type }
      l^.j.x := p.x; { place coordinates }
      l^.j.y := p.y;
      l^.cl := black; { set color }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      { modify bounding box }
      setbound(l^.j.x-curwin^.cs^.cs, l^.j.y-curwin^.cs^.cs);
      setbound(l^.j.x+curwin^.cs^.cs-1, l^.j.y+curwin^.cs^.cs-1);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur; { replace cursor }
      lnkjun(l); { place junction at location }
      { place node name in display }
      button[bnamev].s := l^.nh^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      intstr(l^.nh^.nord, button[bnord].s); { place ordinal }
      trmzer(button[bnord].s); { trim zeros }
      { move back }
      for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
      updbut(bnord) { update }

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

SUBCELL

Handles the subcell placement mode. Handles the activation of
the button, the sizing of the cursor box, and the entry of the
cell.

**************************************************************}

procedure docell;

var l:  drwptr; { line entry }
    sp: shtptr;
    t:  integer;

begin

   if (curbut = bplsch) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { schematic placement }
      { if there is a cell to place, and placement cell is
        selected, start now }
      if (placel <> nil) and button[bcelv].act then begin

         { cell exists }
         if placel^.schema <> nil then begin

            { sheet exists }
            stopact; { stop all modes }
            butact(bplsch); { activate button }
            plcsiz.x := abs(placel^.schema^.bbex-placel^.schema^.bbsx)+1;
            plcsiz.y := abs(placel^.schema^.bbey-placel^.schema^.bbsy)+1;
            if trnfrm in [rm90, rm270, rmm90, rmm270] then begin

               { swap axies for rotation }
               t := plcsiz.x; plcsiz.x := plcsiz.y; plcsiz.y := t

            end;
            str := rcur; { set start of box }
            snapto(str.x, str.y); { snap }
            { set end of box }
            endp.x := str.x+plcsiz.x;
            endp.y := str.y+plcsiz.y;
            drmbut := bplsch; { set paste mode active }
            modbut := bplsch

         end

      end

   end else if (curbut = bplsym) and
               (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { place symbol }
      { if there is a cell to place, start now }
      if (placel <> nil) or button[bnmos].act or
         button[bpmos].act or button[bcap].act or
         button[bres].act or button[bdiode].act or
         button[bvdd].act or button[bvss].act then begin

         sp := nil; { preset pointer }
         if placel <> nil then sp := placel^.symbol;
         { cell exists }
         if (sp <> nil) or not button[bcelv].act then
            begin

            { sheet exists }
            stopact; { stop all modes }
            butact(bplsym); { activate button }
            { set dementions of box }
            if button[bcelv].act then begin

               plcsiz.x := abs(placel^.symbol^.sbbex-placel^.symbol^.sbbsx)+1;
               plcsiz.y := abs(placel^.symbol^.sbbey-placel^.symbol^.sbbsy)+1

            end else if button[bnmos].act or button[bpmos].act then begin

               plcsiz.x := 7*1500;
               plcsiz.y := 8*1500

            end else if button[bcap].act then begin

               plcsiz.x := 4*1500;
               plcsiz.y := 5*1500

            end else if button[bres].act then begin

               plcsiz.x := 4*750;
               plcsiz.y := 20*750

            end else if button[bdiode].act then begin

               plcsiz.x := 4*1500;
               plcsiz.y := 8*1500

            end else if button[bvdd].act or button[bvss].act then begin

               plcsiz.x := 2*1500;
               plcsiz.y := 4*1500

            end;
            if trnfrm in [rm90, rm270, rmm90, rmm270] then begin

               { swap axies for rotation }
               t := plcsiz.x; plcsiz.x := plcsiz.y; plcsiz.y := t

            end;
            str := rcur; { set start of box }
            snapto(str.x, str.y); { snap }
            { set end of box }
            endp.x := str.x+plcsiz.x;
            endp.y := str.y+plcsiz.y;
            drmbut := bplsym; { set paste mode active }
            modbut := bplsym

         end

      end

   end else if (curbut = bplace) and
               (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { place layout }
      { if there is a cell to place, and placement cell is
        selected, start now }
      if (placel <> nil) and button[bcelv].act then begin

         { cell exists }
         if placel^.layout <> nil then begin

            { sheet exists }
            stopact; { stop all modes }
            butact(bplace); { activate button }
            plcsiz.x := abs(placel^.layout^.bbex-placel^.layout^.bbsx)+1;
            plcsiz.y := abs(placel^.layout^.bbey-placel^.layout^.bbsy)+1;
            if trnfrm in [rm90, rm270, rmm90, rmm270] then begin

               { swap axies for rotation }
               t := plcsiz.x; plcsiz.x := plcsiz.y; plcsiz.y := t

            end;
            str := rcur; { set start of box }
            snapto(str.x, str.y); { snap }
            { set end of box }
            endp.x := str.x+plcsiz.x;
            endp.y := str.y+plcsiz.y;
            drmbut := bplace; { set paste mode active }
            modbut := bplace

         end

      end

   end else if (drmbut in [bplsch, bplsym, bplace]) and inactive(cur) and
               (puck.b[1].a or puck.b[2].a) then begin

      rescur; { remove cursor }
      resbox; { remove box cursor }
      str := rcur; { set start of cell }
      snapto(str.x, str.y); { snap }
      new(l); { get new draw entry }
      { set type }
      if button[bcelv].act then l^.typ := tcell
      else if button[bnmos].act then l^.typ := tnmos
      else if button[bpmos].act then l^.typ := tpmos
      else if button[bcap].act then l^.typ := tcap
      else if button[bres].act then l^.typ := tres
      else if button[bdiode].act then l^.typ := tdiode
      else if button[bvdd].act then l^.typ := tvdd
      else if button[bvss].act then l^.typ := tvss;
      if l^.typ = tcell then begin

         l^.cr.o.x := str.x; { place coordinates }
         l^.cr.o.y := str.y

      end else begin

         l^.o.x := str.x; { place coordinates }
         l^.o.y := str.y

      end;
      if button[bcelv].act then { placement cell }
         if drmbut = bplsch then begin { place schematic }

            l^.cr.cp := placel^.schema;
            l^.cr.ct := ctsch

         end else if drmbut = bplsym then begin { place symbol }

            l^.cr.cp := placel^.symbol;
            l^.cr.ct := ctsym

         end else begin { place layout }

            l^.cr.cp := placel^.layout;
            l^.cr.ct := ctlay

         end;
      l^.rm := trnfrm; { set rotation mode }
      l^.cl := black; { set color }
      dointer(l); { intersect with cell }
      if l^.typ = tcell then begin { enter cell }

         l^.next := curwin^.cs^.dl[ltcell]; { enter to draw list }
         curwin^.cs^.dl[ltcell] := l

      end else begin { enter figure }

         l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
         curwin^.cs^.dl[ltfig] := l

      end;
      setbound(str.x, str.y); { update bounds for cell }
      setsbound(str.x, str.y); { update symbol bounds for cell }
      setbound(str.x+plcsiz.x, str.y+plcsiz.y);
      setsbound(str.x+plcsiz.x, str.y+plcsiz.y);
      chktar; { check target change }
      { redraw cell region }
      frregion(str.x, str.y, str.x+plcsiz.x, str.y+plcsiz.y);
      setbox; { replace box cursor }
      setcur; { replace cursor }

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{**************************************************************

DO NEW SHEET

As newsht, but with button checks.

**************************************************************}

procedure donew;

begin

   if (curbut = bnew) and (puck.b[1].a or puck.b[2].a) then begin

      butact(bnew); { activate button }
      newsht; { clear sheet }
      butina(bnew)

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

START EDIT

Starts off most edits. The contents of the current button is
saved, the button is set in edit mode, and the edit started.

**************************************************************}

procedure stredt;

begin

   if (curbut in [bjuncv, bconnv, bdotsv, blinev, btsizv,
                  bnamev, bnord, bfname, bcname, borgxv, borgyv,
                  bsclv, bmaxx, bmaxy, boffx, boffy]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      canact; { cancel other activity }
      butsav := button[curbut].s; { save button }
      edtbut(button[curbut]); { kick off edit }
      cedbut := curbut { set edit in progress }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

PERFORM EDIT FILENAME

Performs each character placement of this edit. Also handles
termination and activation of this field.

**************************************************************}

procedure dofiln(c, cs: char);

begin

   edit(button[bfname], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin

      { copy to cell name (as the default cell name) }
      button[bcname].s := button[bfname].s;
      cellst^.name := button[bcname].s; { name top cell }
      updbut(bcname); { update }
      cedbut := bnull { end edit }

   end

end;
{}
{**************************************************************

EDIT CELLNAME

Starts off the edit of the cellname field.

**************************************************************}

procedure edtcel;

begin

   if button[bfname].s <> '        ' then
      stredt { start edit }

end;
{}
{**************************************************************

PERFORM EDIT CELLNAME

Performs each character placement of this edit. Also handles
termination and activation of this field.

**************************************************************}

procedure doceln(c, cs: char);

var p: celptr;

begin

   edit(button[bcname], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin

      p := cellst; { index top cell }
      { search for cell match }
      while (p^.next <> nil) and (p^.name <> button[bcname].s) do
         p := p^.next;
      if p^.name <> button[bcname].s then begin

         { create new cell }
         new(p^.next); { create new cell }
         p := p^.next; { index it }
         p^.name := button[bcname].s; { place name }
         p^.symbol := nil; { clear lists }
         p^.schema := nil;
         p^.layout := nil;
         p^.simulate := nil;
         p^.next := nil

      end;
      curwin^.cc := p; { place cell as current }
      celstk := nil; { clear cell stack }
      dispcell; { display current cell }
      cedbut := bnull; { end edit }

   end

end;
{}
{**************************************************************

PERFORM EDIT NODENAME

Performs each character placement of this edit. Also handles
termination and activation of this field.

**************************************************************}

procedure donnam(c, cs: char);

begin

   edit(button[bnamev], edtpos, c, cs); { perform edit }
   if c = chr(13) then cedbut := bnull; { end edit }

end;
{}
{**************************************************************

PERFORM EDIT NODE ORDINAL

Performs each character placement of this edit. Also handles
termination and activation of this field.

**************************************************************}

procedure donord(c, cs: char);

var n: integer;
    i: btsinx;
    e: boolean; { error flag }

begin

   edit(button[bnord], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { end edit }

      getint(button[bnord], n, e); { get ordinal value }
      if not e then begin { value ok }

         { place ordinal in display }
         intstr(n, button[bnord].s); { place ordinal }
         trmzer(button[bnord].s); { trim zeros }
         { move back }
         for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
         { refresh button }
         updbut(bnord); { update }
         { port: was updbut(blinev), copy damage from doling }
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT DOT SPACING

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dodotg(c, cs: char);

var r:  real;
    ds: integer;
    e:  boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(dftdg*pixsiz, button[bdotsv].s);
      updbut(bdotsv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[bdotsv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bdotsv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[bdotsv].s); { place value }
         { refresh button }
         updbut(bdotsv); { update }
         ds := round(r/pixsiz); { find number of vpixels per }
         if ds <> curwin^.cs^.ds then begin { is different }

            rescur; { reset cursor }
            { port: grid indicator arrays (plcgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[bdots].act then { grid active }
               dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                      curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                      white); { white out dots }
            curwin^.cs^.ds := ds; { place size }
            if button[bdots].act then { grid is on, redo }
               drwfigs; { redraw all figures }
            setcur { set cursor }

         end;
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT LINE SPACING

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doling(c, cs: char);

var r:  real;
    ls: integer;
    e:  boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      { set default line grid size }
      realstr(dftlg*pixsiz, button[blinev].s);
      updbut(blinev); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[blinev], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[blinev], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[blinev].s); { place value }
         { refresh button }
         updbut(blinev); { update }
         ls := round(r/pixsiz); { find number of vpixels per }
         if ls <> curwin^.cs^.ls then begin { is different }

            rescur; { remove cursor }
            { port: grid indicator arrays (plc10sgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[blines].act then { grid is on }
               do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                         curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                         white); { white out lines }
            curwin^.cs^.ls := ls; { place size }
            if button[blines].act then { grid is on }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end;
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT ORIGIN X

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doorgx(c, cs: char);

var r: real;
    e: boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(0*pixsiz, button[borgxv].s);
      updbut(borgxv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[borgxv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[borgxv], r, e); { parse number }
      { set new x }
      if not e then begin { value ok }

         newview(round(r/pixsiz), curwin^.cs^.vp.r.s.y, curwin^.cs^.vp.s.x);
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT ORIGIN Y

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doorgy(c, cs: char);

var r: real;
    e: boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(0*pixsiz, button[borgyv].s);
      updbut(borgyv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[borgyv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[borgyv], r, e); { parse number }
      { set new y }
      if not e then begin { value ok }

         newview(curwin^.cs^.vp.r.s.x, round(r/pixsiz), curwin^.cs^.vp.s.x);
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT SCALE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doscl(c, cs: char);

var r: real;
    e: boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(normscale, button[bsclv].s);
      updbut(bsclv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[bsclv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bsclv], r, e); { parse number }
      { set new scale }
      if not e then begin { value ok }

         newview(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y, round(r)*scalem);
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT TEXT SIZE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dotsiz(c, cs: char);

var r: real;
    e: boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(dftchr*4*pixsiz, button[btsizv].s);
      updbut(btsizv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[btsizv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[btsizv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[btsizv].s); { place value }
         curwin^.cs^.ts := round(r/4/pixsiz); { find number of vpixels per }
         { refresh button }
         updbut(btsizv); { update }
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT JUNCTION SIZE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dojsiz(c, cs: char);

var r: real;
    e: boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(dftjun*2*pixsiz, button[bjuncv].s);
      updbut(bjuncv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[bjuncv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bjuncv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[bjuncv].s); { place value }
         curwin^.cs^.js := round(r/2/pixsiz); { find number of vpixels per }
         { refresh button }
         updbut(bjuncv); { update }
         redraw; { refresh screen }
         cedbut := bnull; { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT CONNECTOR SIZE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure docsiz(c, cs: char);

var r: real;
    e: boolean;

begin

   if c = chr(9) then begin { tab, restore default value }

      realstr(dftcon*2*pixsiz, button[bconnv].s);
      updbut(bconnv); { update }
      c := chr(0); { null input character }
      cs := chr(0)

   end;
   edit(button[bconnv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bconnv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[bconnv].s); { place value }
         curwin^.cs^.cs := round(r/2/pixsiz); { find number of vpixels per }
         { refresh button }
         updbut(bconnv); { update }
         redraw; { redraw screen }
         cedbut := bnull; { end edit }

      end

   end

end;
{}
{**************************************************************

EDIT CURRENT PLACEMENT CELL

Starts off the edit of the placement cell field.

**************************************************************}

procedure edtcelv;

var b: buttyp;

begin

   if (curbut = bcelv) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      canact; { cancel other activity }
      butsav := '        '; { set no save }
      placel := nil; { set no placement cell }
      { move down cell stack }
      for b := bceld downto bcela do begin

         button[b].s := button[pred(b)].s;
         updbut(b) { update }

      end;
      edtbut(button[bcelv]); { kick off edit }
      cedbut := bcelv { set edit in progress }

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT PLACEMENT CELL

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure docelv(c, cs: char);

var p: celptr;
    b: buttyp;

begin

   edit(button[bcelv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      cedbut := bnull; { end edit }
      p := cellst; { index top cell }
      { search for cell match }
      while (p^.next <> nil) and (p^.name <> button[bcelv].s) do
         p := p^.next;
      { set cell as current if exists }
      if p^.name = button[bcelv].s then begin

         { good cell }
         placel := p; { place cell pointer }
         { find matching cell }
         b := bcela; { index 1st button }
         while (b < bceld) and
               (button[b].s <> button[bcelv].s) do b := succ(b);
         if button[b].s = button[bcelv].s then begin

            { matching cell, delete from queue }
            for b := b to bceld do { move buttons down }
               button[b].s := button[succ(b)].s;
            button[bceld].s := '        '; { clear last cell }
            for b := bcela to bceld do { refresh buttons }
               updbut(b) { update }

         end;
         butact(bcelv) { set button active }

      end else begin

         button[bcelv].s := '        '; { clear bad cell }
         updbut(bcelv); { update }
         { port: was updbut(b), stale loop index; bcelv intended }
         placel := nil

      end

   end

end;
{}
{**************************************************************

SELECT QUEUE CELL

Selects one the queue list cells, and places that as active.

**************************************************************}

procedure selcel;

var p: celptr;
    b: buttyp;
    s: butstr;

begin

   if (curbut in [bcelv, bcela, bcelb, bcelc, bceld]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      s := button[curbut].s; { save our string }
      { copy up buttons underneath us }
      for b := curbut downto bcela do button[b].s := button[pred(b)].s;
      button[bcelv].s := s; { replace string }
      { refresh buttons }
      for b := bcelv to bceld do
         updbut(b); { update }
      p := cellst; { index top cell }
      { search for cell match }
      while (p^.next <> nil) and (p^.name <> button[bcelv].s) do
         p := p^.next;
      { set cell as current if exists }
      if p^.name = button[bcelv].s then placel := p
      else begin

         button[bcelv].s := '        '; { clear bad cell }
            updbut(bcelv); { update }
            { port: was updbut(b), stale loop index; bcelv intended }
         placel := nil

      end

   end

end;
{}
{**************************************************************

EDIT CURRENT LIBRARY

Starts off the edit of the library field.

**************************************************************}

procedure edtlibv;

var b: buttyp;

begin

   if (curbut = blibv) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      canact; { cancel other activity }
      butsav := '        '; { set no save }
      placel := nil; { set no placement cell }
      { move down cell stack }
      for b := blibd downto bliba do begin

         button[b].s := button[pred(b)].s;
         updbut(b) { update }

      end;
      edtbut(button[blibv]); { kick off edit }
      cedbut := blibv { set edit in progress }

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT LIBRARY

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dolibv(c, cs: char);

var b: buttyp;

begin

   edit(button[blibv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      cedbut := bnull; { end edit }
      { find matching cell }
      b := bliba; { index 1st button }
      while (b < blibd) and
            (button[b].s <> button[blibv].s) do b := succ(b);
      if button[b].s = button[blibv].s then begin

         { matching cell, delete from queue }
         for b := b to blibd do { move buttons down }
            button[b].s := button[succ(b)].s;
         button[blibd].s := '        '; { clear last cell }
         for b := bliba to blibd do { refresh buttons }
            updbut(b) { update }

      end

   end

end;
{}
{**************************************************************

SELECT PLACEMENT CELL

Selects the placement cell as the active cell.

**************************************************************}

procedure selplc;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      butina(bcelv); { set buttons inactive }
      butina(bnmos);
      butina(bpmos);
      butina(bcap);
      butina(bres);
      butina(bdiode);
      butina(bvdd);
      butina(bvss);
      butact(curbut)

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET VIEWS

Handles the viewer buttons. If button 1 is pressed, and a view
has been stored, that view is set current. If button 2 is
pressed, the current view is stored in that button.

**************************************************************}

procedure setview;

var i: viewinx; { index for views }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(bviewa)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sv[i].a and
         not ((curwin^.cs^.sv[i].vp.r.s.x = curwin^.cs^.vp.r.s.x) and
              (curwin^.cs^.sv[i].vp.r.s.y = curwin^.cs^.vp.r.s.y) and
              (curwin^.cs^.sv[i].vp.s.x = curwin^.cs^.vp.s.x)) then begin { go view }

         { button 1 down, view active, not the same old view }
         stopview; { stop motion modes }
         { activate new view }
         newview(curwin^.cs^.sv[i].vp.r.s.x,
                 curwin^.cs^.sv[i].vp.r.s.y,
                 curwin^.cs^.sv[i].vp.s.x);
         setcur; { set cursor }
         modbut := dsmbut { restore any draw mode }

      end else if puck.b[2].a then begin { set view }

         butact(curbut); { activate the button }
         curwin^.cs^.sv[i].vp.r.s.x := curwin^.cs^.vp.r.s.x; { place origin }
         curwin^.cs^.sv[i].vp.r.s.y := curwin^.cs^.vp.r.s.y;
         curwin^.cs^.sv[i].vp.s.x := curwin^.cs^.vp.s.x; { place scale }
         curwin^.cs^.sv[i].vp.s.y := curwin^.cs^.vp.s.y; { place scale }
         curwin^.cs^.sv[i].a := true { set view active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET TEXT SIZES

Handles the text size buttons. If button 1 is pressed, and a size
has been stored, that size is set current. If button 2 is
pressed, the current size is stored in that button.

**************************************************************}

procedure settexts;

var i: sizeinx; { index for sizes }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(btexta)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sts[i].a then begin { activate text size }

         { button 1 down }
         rescur; { remove cursor }
         if drmbut = btext then restcur; { remove text cursor }
         curwin^.cs^.ts := curwin^.cs^.sts[i].s; { place text size }
         realstr(curwin^.cs^.ts*4*pixsiz, button[btsizv].s); { place value }
         updbut(btsizv); { update }
         if drmbut = btext then settcur; { reset text cursor }
         setcur { reset cursor }

      end else if puck.b[2].a then begin { set text size }

         butact(curbut); { activate the button }
         curwin^.cs^.sts[i].s := curwin^.cs^.ts; { save current text size }
         curwin^.cs^.sts[i].a := true { set active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET DOT GRID SIZES

Handles the dot grid size buttons. If button 1 is pressed,
and a size has been stored, that size is set current. If button
2 is pressed, the current size is stored in that button.

**************************************************************}

procedure setdotg;

var i:  sizeinx; { index for sizes }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(bdotsva)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sds[i].a then begin { activate grid size }

         if curwin^.cs^.ds <> curwin^.cs^.sds[i].s then begin { is different }

            { button 1 down }
            rescur; { remove cursor }
            { port: grid indicator arrays (plcgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[bdots].act then { grid active }
               dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                      curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                      white); { white out dots }
            curwin^.cs^.ds := curwin^.cs^.sds[i].s; { place size }
            realstr(curwin^.cs^.ds*pixsiz, button[bdotsv].s); { place value }
            updbut(bdotsv); { update }
            if button[bdots].act then { grid is on, redo }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end

      end else if puck.b[2].a then begin { set dot grid size }

         butact(curbut); { activate the button }
         curwin^.cs^.sds[i].s := curwin^.cs^.ds; { save current dot grid size }
         curwin^.cs^.sds[i].a := true { set active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET LINE GRID SIZES

Handles the line grid size buttons. If button 1 is pressed,
and a size has been stored, that size is set current. If button
2 is pressed, the current size is stored in that button.

**************************************************************}

procedure setlineg;

var i: sizeinx; { index for sizes }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(blineva)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sls[i].a then begin { activate grid size }

         if curwin^.cs^.ls <> curwin^.cs^.sls[i].s then begin { is different }

            { button 1 down }
            rescur; { remove cursor }
            { port: grid indicator arrays (plc10sgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[blines].act then { grid is on }
               do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                         curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                         white); { white out lines }
            curwin^.cs^.ls := curwin^.cs^.sls[i].s; { place size }
            realstr(curwin^.cs^.ls*pixsiz, button[blinev].s); { place value }
            updbut(blinev); { update }
            if button[blines].act then { grid is on }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end

      end else if puck.b[2].a then begin { set line grid size }

         butact(curbut); { activate the button }
         curwin^.cs^.sls[i].s := curwin^.cs^.ls; { save current line grid size }
         curwin^.cs^.sls[i].a := true { set active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET BLOCK SAVE

Stores or recalls a block from the block save tableu.

**************************************************************}

procedure setblk;

var i:  blkinx; { index for block stores }

{ check block list occupied }

function blkact(l: laylst): boolean;

var f:  boolean; { result }
    li: laytyp;  { layer index }

begin

   f := false; { set emtpy }
   { check any content }
   for li := ltcell to ltwell do if l[li] <> nil then f := true;
   blkact := f { return result }

end;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(bblka)+1; { set the index }
      if puck.b[1].a and blkact(blocks[i].l) then begin { activate block save }

         savlst := blocks[i].l; { place figure list }
         namlst := blocks[i].n; { place name list }
         savb.s.x := blocks[i].sx; { place bounding box }
         savb.s.y := blocks[i].sy;
         savb.e.x := blocks[i].ex;
         savb.e.y := blocks[i].ey

      end else if puck.b[2].a then begin { save block }

         butact(curbut); { activate the button }
         blocks[i].l := savlst; { place figure list }
         blocks[i].n := namlst; { place name list }
         blocks[i].sx := savb.s.x; { place bounding box }
         blocks[i].sy := savb.s.y;
         blocks[i].ex := savb.e.x;
         blocks[i].ey := savb.e.y

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE DOT GRID

Turns the dot grid either off or on. Updates the display to
match.
Note that the dot placement array must have been previously
filled.

**************************************************************}

procedure togdot;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { toggle status }
      button[bdots].act := not button[bdots].act;
      updbut(bdots); { update button }
      if button[bdots].act then { activate grid }
         drwfigs { redraw all figures }
      else begin { deactivate grid }

         { port: grid indicator arrays deleted; white out over the
           real extent of the view }
         dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                white); { white out dots }
         drwfigs { replace figures }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE LINE GRID

Turns the line grid either off or on. Updates the display to
match.
Note that the line placement array must have been previously
filled.

**************************************************************}

procedure togline;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { toggle status }
      button[blines].act := not button[blines].act;
      updbut(blines); { update button }
      if button[blines].act then { activate grid }
         drwfigs { redraw all figures }
      else begin { deactivate grid }

         { port: grid indicator arrays deleted; white out over the
           real extent of the view }
         do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                   curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                   white); { white out lines }
         drwfigs { replace figures }

      end;

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET SYMBOL MODE

Sets the symbol edit mode. The symbol sheet in the current cell
is set current.

**************************************************************}

procedure setsymbol;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[bsymbol].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smsymbol]; { set symbol screen mode }
      pixsiz := dftsiz; { set base scale }
      butact(bsymbol); { activate symbol button }
      butina(bschema); { deactivate other buttons }
      butina(blayout);
      butina(bsimulate);
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET SCHEMATIC MODE

Sets the schematic edit mode. The schematic sheet in the current cell
is set current.

**************************************************************}

procedure setschema;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[bschema].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smschema]; { set schematic screen mode }
      pixsiz := dftsiz; { set base scale }
      butact(bschema); { activate schematic button }
      butina(bsymbol); { deactivate other buttons }
      butina(blayout);
      butina(bsimulate);
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

RESIZE WINDOW

Handles the resize control buttons. A cursor box is pinned
between the cursor and the opposite corner or side of the window.
The window then is sized to fit the resulting box.

**************************************************************}

procedure resize;

{ adjust size box according to move mode }

procedure adjsiz(b: buttyp);

begin

   case b of { move button }

      { adjust size box to meet cursor }
      bmbtop:    sizb.s.y := cur.y;
      bmbleft:   sizb.s.x := cur.x;
      bmbright:  sizb.e.x := cur.x;
      bmbbottom: sizb.e.y := cur.y;
      bmbtoplt, bmbtopll:
         begin sizb.s.x := cur.x; sizb.s.y := cur.y end;
      bmbtoprt, bmbtoprr:
         begin sizb.e.x := cur.x; sizb.s.y := cur.y end;
      bmbbotlb, bmbbotll:
         begin sizb.s.x := cur.x; sizb.e.y := cur.y end;
      bmbbotrb, bmbbotrr:
         begin sizb.e.x := cur.x; sizb.e.y := cur.y end;

   end

end;

{ set size box to screen }
{ port: save-under replaced by xor rubber-banding; lininx save index
  deleted }

procedure setsiz;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxsav(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y,
             lmagenta)

   end

end;

{ reset size box from screen }
{ port: boxrst redraws the identical box in xor mode; the color must
  match the setsiz draw color }

procedure ressiz;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxrst(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, lmagenta)

   end

end;

begin

   if modbut in [bmbtop, bmbleft, bmbright, bmbbottom,
                  bmbtoplt, bmbtopll, bmbtoprt, bmbtoprr,
                  bmbbotlb, bmbbotll, bmbbotrb, bmbbotrr] then
      begin { in resize mode }

      if puck.b[1].a or puck.b[2].a or
         (puck.b[1].d and puck.b[1].dg) or
         (puck.b[2].d and puck.b[2].dg) then begin

         { resize complete }
         { resize window to box }
         rescur; { remove cursor }
         ressiz; { remove size cursor }
         { clear overlap space }
         { port: winrec.r (window screen region) was replaced by the
           window viewport; reads convert to curwin^.wv.v }
         case modbut of { move button }

            bmbtop:    if sizb.s.y > curwin^.wv.v.s.y then
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, sizb.s.y, bakclr);
            bmbleft:   if sizb.s.x > curwin^.wv.v.s.x then
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     sizb.s.x, curwin^.wv.v.e.y, bakclr);
            bmbright:  if sizb.e.x < curwin^.wv.v.e.x then
               block(screen, sizb.e.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
            bmbbottom: if sizb.e.y < curwin^.wv.v.e.y then
               block(screen, curwin^.wv.v.s.x, sizb.e.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
            bmbtoplt, bmbtopll: begin

               if sizb.s.y > curwin^.wv.v.s.y then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, sizb.s.y, bakclr);
               if sizb.s.x > curwin^.wv.v.s.x then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        sizb.s.x, curwin^.wv.v.e.y, bakclr)

            end;
            bmbtoprt, bmbtoprr: begin

               if sizb.s.y > curwin^.wv.v.s.y then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, sizb.s.y, bakclr);
               if sizb.e.x < curwin^.wv.v.e.x then
                  block(screen, sizb.e.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr)

            end;
            bmbbotlb, bmbbotll: begin

               if sizb.e.y < curwin^.wv.v.e.y then
                  block(screen, curwin^.wv.v.s.x, sizb.e.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
               if sizb.s.x > curwin^.wv.v.s.x then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        sizb.s.x, curwin^.wv.v.e.y, bakclr)

            end;
            bmbbotrb, bmbbotrr: begin

               if sizb.e.y < curwin^.wv.v.e.y then
                  block(screen, curwin^.wv.v.s.x, sizb.e.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
               if sizb.e.x < curwin^.wv.v.e.x then
                  block(screen, sizb.e.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr)

            end

         end;
         { port: was curwin^.r := sizb; the window repositions through
           its viewport }
         plcwin(screen, curwin^.wv, sizb.s.x, sizb.s.y,
                sizb.e.x, sizb.e.y); { set new window size }
         button[bmax].act := false; { deactivate max button }
         dispwin; { display new window }
         modbut := bnull { reset status }

      end else begin { resize still in progress }

         if puck.m then begin { cursor has moved }

            rescur; { remove cursor }
            ressiz; { reset size cursor }
            adjsiz(modbut); { adjust size cursor }
            setsiz; { set size cursor to screen }
            setcur; { replace cursor }

         end

      end

   end else { must be in select mode }
      if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { mark resize mode }
      sizb := curwin^.wv.v; { set size box to window region }
      { port: was curwin^.r }
      adjsiz(curbut); { adjust size cursor }
      rescur; { remove cursor }
      setsiz; { set size cursor to screen }
      setcur; { replace cursor }
      modbut := curbut

   end
   { resptr (reset buttons) disabled in original }
   { port: nested-brace comment flattened }

end;
{}
{**************************************************************

MOVE WINDOW

Handles the window move button. A cursor box is pinned to the
cursor. The window is then moved to fit the resulting box.

**************************************************************}

procedure movewin;

{ set size box to screen }
{ port: renamed from setbox; collides with the global rubber-band
  setbox (icdb layer). Save-under replaced by xor rubber-banding;
  lininx save index deleted }

procedure setsizbox;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxsav(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y,
             lmagenta)

   end

end;

{ reset size box from screen }
{ port: renamed from resbox; collides with the global rubber-band
  resbox (icdb layer). boxrst redraws the identical box in xor mode;
  the color must match the setsizbox draw color }

procedure ressizbox;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxrst(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, lmagenta)

   end

end;

begin

   if modbut = bmovew then begin { in move mode }

      if puck.b[1].a or puck.b[2].a or
         (puck.b[1].d and puck.b[1].dg) or
         (puck.b[2].d and puck.b[2].dg) then begin

         { move complete }
         { resize window to box }
         rescur; { remove cursor }
         ressizbox; { remove size cursor }
         { clear overlap space }
         { port: winrec.r (window screen region) was replaced by the
           window viewport; reads convert to curwin^.wv.v }
         if (curwin^.wv.v.s.x <= sizb.e.x) and
            (curwin^.wv.v.e.x >= sizb.s.x) and
            (curwin^.wv.v.s.y <= sizb.e.y) and
            (curwin^.wv.v.e.y >= sizb.s.y) then begin

            { rectangles overlap }
            if (curwin^.wv.v.s.y < sizb.s.y) and
               (curwin^.wv.v.e.y > sizb.s.y) then { clear top }
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, sizb.s.y, bakclr);
            if (curwin^.wv.v.s.x < sizb.s.x) and
               (curwin^.wv.v.e.x > sizb.s.x) then { clear left }
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     sizb.s.x, curwin^.wv.v.e.y, bakclr);
            if (curwin^.wv.v.e.x > sizb.e.x) and
               (curwin^.wv.v.s.x < sizb.e.x) then { clear right }
               block(screen, sizb.e.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
            if (curwin^.wv.v.e.y > sizb.e.y) and
               (curwin^.wv.v.s.y < sizb.e.y) then { clear bottom }
               block(screen, curwin^.wv.v.s.x, sizb.e.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr)

         end else { no overlap }
            block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                  curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
         { port: was curwin^.r := sizb; the window repositions through
           its viewport }
         plcwin(screen, curwin^.wv, sizb.s.x, sizb.s.y,
                sizb.e.x, sizb.e.y); { set new window size }
         button[bmax].act := false; { deactivate max button }
         dispwin; { display new window }
         modbut := bnull { reset status }

      end else begin { resize still in progress }

         if puck.m then begin { cursor has moved }

            rescur; { remove cursor }
            ressizbox; { reset size cursor }
            sizb.s.x := sizb.s.x+(cur.x-movoff.x);
            sizb.s.y := sizb.s.y+(cur.y-movoff.y);
            sizb.e.x := sizb.e.x+(cur.x-movoff.x);
            sizb.e.y := sizb.e.y+(cur.y-movoff.y);
            setsizbox; { set size cursor to screen }
            setcur; { replace cursor }
            movoff := cur { save offset cursor }

         end

      end

   end else { must be in select mode }
      if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { mark move mode }
      sizb := curwin^.wv.v; { set size box to window region }
      { port: was curwin^.r }
      movoff := cur; { save offset cursor }
      rescur; { remove cursor }
      setsizbox; { set size cursor to screen }
      setcur; { replace cursor }
      modbut := curbut

   end
   { resptr (reset buttons) disabled in original }
   { port: nested-brace comment flattened }

end;
{}
{**************************************************************

MAXIMIZE WINDOW

Handles the window maximize button. The window is resized to
occupy the full screen.

**************************************************************}

procedure maxwin;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { resize window }
      button[bmax].act := not button[bmax].act; { invert status }
      rescur; { remove cursor }
      if button[bmax].act then begin { maximize window }

         { port: winrec.r (window screen region) was replaced by the
           window viewport; reads convert to curwin^.wv.v, and the
           window repositions through plcwin }
         curwin^.sr := curwin^.wv.v; { save present region }
         { set to occupy entire screen }
         plcwin(screen, curwin^.wv, minx, miny, maxx, maxy)

      end else begin { set back to normal }

         { clear maximized window }
         block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
               curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
         { restore saved region }
         plcwin(screen, curwin^.wv, curwin^.sr.s.x, curwin^.sr.s.y,
                curwin^.sr.e.x, curwin^.sr.e.y)

      end;
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

HANDLE EXIT

Handles the exit button push.

**************************************************************}

procedure doexit;

begin

   if (curbut = bexit) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      butact(bexit); { set exit active }
   resptr { reset buttons }

end;
procedure testbut;

begin

   rescur;
   block(screen, button[curbut].r.s.x, button[curbut].r.s.y,
         button[curbut].r.e.x, button[curbut].r.e.y,
         lred);
   block(screen, button[curbut].r.s.x, button[curbut].r.s.y,
         button[curbut].r.e.x, button[curbut].r.e.y,
         white);
   setcur;

end;
{}
{**************************************************************

EXECUTE BUTTON COMMAND

Executes the handler for each button.

**************************************************************}

procedure dobutton(b: buttyp);

begin

  case(b) of { button active }

      { activated screen button }
      bnull:     ;              { no button }
      bpan:      pan;           { pan }
      bruler:    ruler;         { ruler }
      bin:       zoomin;        { zoom in }
      bout:      zoomout;       { zoom out }
      bbound:    bound;         { go bounding box }
      bback:     back;          { last view }
      bline:     doline;        { line draw mode }
      bbline:    doline;        { bold line draw mode }
      bsnap:     togsnap;       { toggle snap }
      bbox:      dobox;         { box draw mode }
      bbbox:     dobox;         { bold box draw mode }
      bany:      setllim;       { line limit any }
      b45:       setllim;       { line limit 45 deg }
      bcircle:   docircle;      { circle draw mode }
      b90:       setllim;       { line limit 90 deg }
      barc:      doarc;         { arc draw mode }
      bwire:     doline;        { wire place mode }
      bbus:      doline;        { bus place mode }
      bjunction: junction;      { junction place mode }
      bjuncv:    stredt;        { edit junction size variable }
      bconnect:  connect;       { connector place mode }
      bconnv:    stredt;        { edit connector size variable }
      bundo:     ;              { undo }
      bredo:     ;              { redo }
      bcutb:     saveblk;       { cut block }
      bpasteb:   pasteblk;      { set paste block mode }
      bsaveb:    saveblk;       { save block }
      bblka,                    { block save sets }
      bblkb,
      bblkc,
      bblkd,
      bblke,
      bblkf,
      bblkg,
      bblkh:     setblk;
      bdelete:   delete;        { delete }
      bdeleten:  deletenet;     { delete network }
      bdots:     togdot;        { toggle dot grid }
      bdotsv:    stredt;        { edit grid size variable }
      bdotsva,                  { dot grid sets }
      bdotsvb,
      bdotsvc,
      bdotsvd,
      bdotsve,
      bdotsvf,
      bdotsvg,
      bdotsvh:   setdotg;
      blines:    togline;       { toggle line grid }
      blinev:    stredt;        { edit line grid size variable }
      blineva,                  { line grid sets }
      blinevb,
      blinevc,
      blinevd,
      blineve,
      blinevf,
      blinevg,
      blinevh:   setlineg;
      btrace:    tracenet;      { set trace mode }
      btext:     dotext;        { place text }
      btsizv:    stredt;        { set text size variable }
      btexta,                   { text sets }
      btextb,
      btextc,
      btextd,
      btexte,
      btextf,
      btextg,
      btexth:    settexts;
      bname:     doname;        { set node name mode }
      bnamev:    stredt;        { edit node name }
      bnord:     stredt;        { edit node ordinal }
      berc:      ;              { run rules check }
      bup:       upcell;        { up cell level }
      bdown:     downcell;      { down cell level }
      bsymbol:   setsymbol;     { select symbol sheet }
      bschema:   setschema;     { select schema sheet }
      blayout:   setlayout;     { select layout sheet }
      bsimulate: setsimulate;   { select simulate sheet }
      bload:     doloadc;       { load cell }
      bsave:     dosavec;       { save cell }
      bfname:    stredt;        { edit filename }
      bcname:    edtcel;        { edit cellname }
      bexit:     doexit;        { exit program }
      bnew:      donew;         { clear new sheet }
      brulerv:   ;              { ruler variable }
      brulx:     ;              { ruler x }
      brulxv:    ;              { ruler x variable }
      bruly:     ;              { ruler y }
      brulyv:    ;              { ruler y variable }
      bcposx:    ;              { cursor position x }
      bcposxv:   ;              { cursor position x variable }
      bcposy:    ;              { cursor position y }
      bcposyv:   ;              { cursor position y variable }
      borgx:     ;              { origin x }
      borgxv:    stredt;        { origin x variable }
      borgy:     ;              { origin y }
      borgyv:    stredt;        { origin y variable }
      bscl:      ;              { scale }
      bsclv:     stredt;        { scale variable }
      bviewa,                   { view sets }
      bviewb,
      bviewc,
      bviewd,
      bviewe,
      bviewf,
      bviewg,
      bviewh:    setview;
      blibv,                    { current library select }
      bliba,                    { lib queue a }
      blibb,                    { lib queue b }
      blibc,                    { lib queue c }
      blibd:     dolibs;        { lib queue d }
      bcelv:     if puck.b[1].a then selplc { select placement cell }
                 else edtcelv;  { edit placement cell }
      bcela,                    { select placement cell }
      bcelb,
      bcelc,
      bceld:     selcel;
      bplsym:    docell;        { set symbol placement mode }
      bplsch:    docell;        { set schematic placement mode }
      birmir:    setmirm;       { instance mirror }
      bir0:      setrot;        { instance rotate 0 }
      bir90:     setrot;        { instance rotate 90 }
      bir180:    setrot;        { instance rotate 180 }
      bir270:    setrot;        { instance rotate 270 }
      bcells:    docells;       { display avalible cells }
      bnewc:     ;              { clear new cell }
      bprox:     ;              { proximity indicator }
      bnmos:     selplc;        { place nmos }
      bpmos:     selplc;        { place pmos }
      bres:      selplc;        { place resistor }
      bcap:      selplc;        { place capacitor }
      bdiode:    selplc;        { place diode }
      bvdd:      selplc;        { place vdd }
      bvss:      selplc;        { place vss }
      blast:     ;              { last page display }
      bnext:     ;              { next page display }
      bprint:    doprint;       { print current sheet }
      bdisplay:  dofiles;       { display avalible files }
      bmaxx:     strpedt;       { maximum demension printer x }
      bmaxy:     strpedt;       { maximum demension printer y }
      boffx:     strpedt;       { offset demension x }
      boffy:     strpedt;       { offset demension y }
      bseta:     ;              { print setup saves }
      bsetb:     ;
      bsetc:     ;
      bsetd:     ;
      bsete:     ;
      bsetf:     ;
      bsetg:     ;
      bseth:     ;
      bmet1:     dolayer;       { metal one }
      bmet1vis:  togvis;        { metal one visibility }
      bmet2:     dolayer;       { metal two }
      bmet2vis:  togvis;        { metal two visibility }
      bpoly:     dolayer;       { poly }
      bpolyvis:  togvis;        { poly visibility }
      bvia:      dolayer;       { via }
      bviavis:   togvis;        { via visibility }
      bcont:     dolayer;       { contact }
      bcontvis:  togvis;        { contact visibility }
      bndiff:    dolayer;       { N-diff }
      bndiffvis: togvis;        { N-diff visibility }
      bpdiff:    dolayer;       { P-diff }
      bpdiffvis: togvis;        { P-diff visibility }
      bnwell:    dolayer;       { N-well }
      bnwellvis: togvis;        { N-well visibility }
      bpwell:    dolayer;       { P-well }
      bpwellvis: togvis;        { P-well visibility }
      bccut:     dolayer;       { contact cut }
      bccutvis:  togvis;        { contact cut visibility }
      binsides:  togins;        { show insides }
      bplace:    docell;        { place cell }
      bdrc:      ;              { drc }
      bdwave,                   { digital waveform edit }
      bawave:     dowave;       { analog waveform edit }
      bctime:    ;              { cursor time indicator }
      bctimev:   ;              { cursor time value }
      bcvolt:    ;              { cursor voltage indicator }
      bcvoltv:   ;              { cursor voltage value }
      botime:    ;              { origin time indicator }
      botimev:   ;              { origin time value }
      bovolt:    ;              { origin voltage indicator }
      bovoltv:   ;              { origin voltage value }
      brtime:    ;              { ruler time indicator }
      brtimev:   ;              { ruler time value }
      brvolt:    ;              { ruler voltage indicator }
      brvoltv:   ;              { ruler voltage value }
      bmbtop,                   { move bar top }
      bmbleft,                  { move bar left }
      bmbright,                 { move bar right }
      bmbbottom,                { move bar bottom }
      bmbtoplt,                 { move bar top left top }
      bmbtopll,                 { move bar top left left }
      bmbtoprt,                 { move bar top right top }
      bmbtoprr,                 { move bar top right right }
      bmbbotlb,                 { move bar bottom left bottom }
      bmbbotll,                 { move bar bottom left left }
      bmbbotrb,                 { move bar bottom right bottom }
      bmbbotrr:  resize;        { move bar bottom right right }
      bmax:      maxwin;        { maximize }
      bmin:      ;              { minimize }
      bctrl:     ;              { window control }
      bmovew:    movewin;       { move window bar }

   end

end;
{}
{**************************************************************

EXECUTE KEYBOARD

Processes a single keyboard character, and executes the
command.

**************************************************************}

{ port: converted from the kbdrdy/kbdinp poll loop to a per-character
  entry; the event pump calls this once for each keyboard (etchar)
  event. The auxillary (scan code) second character path is gone;
  cs is passed as null to the edit handlers }

procedure dokeyboard(c, cs: char);

{ port: cs (the DOS auxillary scan code) is now supplied by the event
  pump, which translates the Ami keyboard editing events (etenter,
  etdelcb, etleft, ...) to the legacy (c, cs) pairs the edit routines
  expect }

begin

   if c = chr(27) then canact { cancel activity }
   { this next is for debugging only }
   else if (c = chr(ord('Q')-64)) then { ctrl-Q }
      terminate := true { exit program }
   { port: printer pass deferred (scnprt on alt-P print screen) }
   else if drmbut = btext then enttext(c) { enter vector character }
   else if cedbut <> bnull then case cedbut of

      { button in edit }
      bfname: dofiln(c, cs); { filename }
      bcname: doceln(c, cs); { cellname }
      bdotsv: dodotg(c, cs); { dot spacing }
      blinev: doling(c, cs); { line spacing }
      borgxv: doorgx(c, cs); { origin x }
      borgyv: doorgy(c, cs); { origin y }
      bsclv:  doscl(c, cs);  { scale }
      btsizv: dotsiz(c, cs); { text size }
      bjuncv: dojsiz(c, cs); { junction size }
      bconnv: docsiz(c, cs); { connector size }
      bcelv:  docelv(c, cs); { placement cell }
      blibv:  dolibv(c, cs); { library }
      bnamev: donnam(c, cs); { node name }
      bnord:  donord(c, cs); { node ordinal }
      bmaxx:  dopedt(c, cs, bmaxx, ptrmax.x); { edit print parameters }
      bmaxy:  dopedt(c, cs, bmaxy, ptrmax.y);
      boffx:  dopedt(c, cs, boffx, ptroff.x);
      boffy:  dopedt(c, cs, boffy, ptroff.y);

   end

end;
{}
{**************************************************************

EXECUTE COMMANDS

Central command dispatch for the schematic edittor. Executes the
mode and screen button handlers for one event cycle, then resets
the puck communication flags.

**************************************************************}

{ port: converted from command; polling loop replaced by event pump,
  screen blanking dropped. The original repeat loop polled the tablet
  (updpuck), ran the screen blank timer (gettim/elapsed/aniini/
  aniblank/printpop reestablish) and polled the keyboard; the event
  pump now calls dispatch once per event cycle and dokeyboard once
  per character, and the main program tests button[bexit].act or
  terminate for exit }

procedure dispatch;

begin

   if puck.b[3].a then canact; { cancel any activities }
   dobutton(modbut); { execute mode button }
   dobutton(curbut); { execute screen button }
   resptr { reset buttons }

end;
{}
{ UNRESOLVED: the following names are called here but defined in
  fragments being ported in parallel or in later phases:

  frag_n (icda db core):    plcjun, lnkwire, lnkbus, lnkjun
  frag_f (icdd figures):    drwfig, drwfigs, ratlin, rregion, frregion,
                            delete, deletenet, saveblk, pasteblk,
                            doname, upcell, downcell, tracenet
  icda remainder (files):   doloadc, dosavec, docells, dolibs, dofiles
  icdg/icdh (layout/sim):   setlayout, setsimulate, dolayer, togvis,
                            togins, dointer, dowave
  resptr: resolves against the icdui_base stub until the real icda
  version (clear puck flags) lands with frag_n.
  Printer names (doprint, strpedt, dopedt, scnprt, printpop) are NOT
  called: their sites are emptied per spec rule 6 (printer pass
  deferred). }
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
   { port: fndbnd sets only vp.s.x; the ported coordinate transform (viewx
     uses vp.m) and the vp.r.e.y below also need vp.s.y and the multiplier
     vp.m, which newsht sets for fresh sheets but readsht omitted -- a
     loaded sheet drew through a garbage transform and came up blank.
     Match newsht's convention (square scale, multiplier = scalem). }
   sp^.vp.s.y := sp^.vp.s.x;
   sp^.vp.m.x := scalem;
   sp^.vp.m.y := scalem;
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
   si := curwin^.cs^.vp.v.s.y+uiscl(23)-2;
   while si < curwin^.cs^.vp.v.e.y do begin

      line(screen, curwin^.cs^.vp.v.s.x, si,
           curwin^.cs^.vp.v.e.x, si, black);
      line(screen, curwin^.cs^.vp.v.s.x, si+1,
           curwin^.cs^.vp.v.e.x, si+1, black);
      si := si + uiscl(23)

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
   y := 0; { port: start at grid row 0 (client excludes menu) }
   fp := dsplst; { index top of list }
   dn := dspnum; { set number of first entry }
   { find the starting entry }
   while dn <> 1 do begin fp := fp^.next; dn := dn - 1 end;
   while (fp <> nil) and
         (curwin^.cs^.vp.v.s.x+x*chrheight < curwin^.cs^.vp.v.e.x) do
      begin { process entries }

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
      plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, yellow, true);
      { increment to next character }
      { port: wrap by client height; reset to grid row 0 }
      if curwin^.cs^.vp.v.s.y+(y+2)*uiscl(23) < curwin^.cs^.vp.v.e.y then
         y := y + 1
      else begin { end of collumn, next }

         x := x + 8;
         y := 0

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

var x, y, xi, yi: integer; { port: widened from byte for client-relative coords }
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
      plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;
      dspsav := bs

   end

end;

begin

   { port: 16 pixel cell/128 pixel column scaled to chrheight }
   { port: cursor mapped to a grid cell relative to the client origin,
     matching the placement in the display procedure }
   x := ((cur.x-curwin^.cs^.vp.v.s.x)-
         ((cur.x-curwin^.cs^.vp.v.s.x) mod (8*chrheight))) div chrheight;
   y := (cur.y-curwin^.cs^.vp.v.s.y) div uiscl(23);
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      { port: the original passed the cell coordinates unscaled here
        (dspbut.x, dspbut.y are character cells, plcstr takes pixels) }
      plcstr(curwin^.cs^.vp.v.s.x+dspbut.x*chrheight, curwin^.cs^.vp.v.s.y+dspbut.y*uiscl(23), dspsav, 8, black,
             yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 0; { port: start at grid row 0 }
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
               plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, lgreen, true);
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
            { port: wrap by client height; reset to grid row 0 }
            if curwin^.cs^.vp.v.s.y+(yi+2)*uiscl(23) <
               curwin^.cs^.vp.v.e.y then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 0

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
      y := 0; { port: start at grid row 0 }
      p := cellst; { index top of list }
      while p <> nil do begin { process entries }

         { place this string }
         { port: 16 pixel cell scaled to chrheight }
         plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), p^.name, 8, black, yellow, true);
         { increment to next character }
         if curwin^.cs^.vp.v.s.y+(y+2)*uiscl(23) < curwin^.cs^.vp.v.e.y then y := y + 1
         else begin { end of collumn, next }

            x := x + 8;
            y := 0

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

var x, y, xi, yi: integer; { port: widened from byte for client-relative coords }
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    p:            celptr; { cell pointer }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;
      dspsav := bs

   end

end;

begin

   { port: 16 pixel cell/128 pixel column scaled to chrheight }
   { port: cursor mapped to a grid cell relative to the client origin,
     matching the placement in the display procedure }
   x := ((cur.x-curwin^.cs^.vp.v.s.x)-
         ((cur.x-curwin^.cs^.vp.v.s.x) mod (8*chrheight))) div chrheight;
   y := (cur.y-curwin^.cs^.vp.v.s.y) div uiscl(23);
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      { port: the original passed the cell coordinates unscaled here }
      plcstr(curwin^.cs^.vp.v.s.x+dspbut.x*chrheight, curwin^.cs^.vp.v.s.y+dspbut.y*uiscl(23), dspsav, 8, black,
             yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 0; { port: start at grid row 0 }
      p := cellst; { index top of list }
      f := false; { set not found }
      while p <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            bs := p^.name; { save name }
            if puck.b[1].a then begin { activate cell }

               rescur; { remove cursor }
               { place this string }
               plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, lgreen, true);
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
            { port: wrap by client height; reset to grid row 0 }
            if curwin^.cs^.vp.v.s.y+(yi+2)*uiscl(23) <
               curwin^.cs^.vp.v.e.y then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 0

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

procedure skpsht;

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
            skpsht; { skip entire sheet }
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
                  else skpsht { skip sheet }

               end else if b = ord(ccsymbol) then begin

                  { symbol section }
                  if cp^.cross^.symbol = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.symbol); { create symbol sheet }
                     readsht(f, cp^.cross^.symbol) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.symbol) then
                        readsht(f, cp^.cross^.symbol)
                  else skpsht { skip sheet }

               end else if b = ord(cclayout) then begin

                  { layout section }
                  if cp^.cross^.layout = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.layout); { create symbol sheet }
                     readsht(f, cp^.cross^.layout) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.layout) then
                        readsht(f, cp^.cross^.layout)
                  else skpsht { skip sheet }

               end

            end else skpsht { skip entire sheet }

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
      y := 0; { port: start at grid row 0 }
      p := libcel; { index top of list }
      while p <> nil do begin { process entries }

         { place this string }
         { port: 16 pixel cell scaled to chrheight }
         plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), p^.name, 8, black, yellow, true);
         { increment to next character }
         if curwin^.cs^.vp.v.s.y+(y+2)*uiscl(23) < curwin^.cs^.vp.v.e.y then y := y + 1
         else begin { end of collumn, next }

            x := x + 8;
            y := 0

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

var x, y, xi, yi: integer; { port: widened from byte for client-relative coords }
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    p:            celptr; { cell pointer }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;
      dspsav := bs

   end

end;

begin

   { port: 16 pixel cell/128 pixel column scaled to chrheight }
   { port: cursor mapped to a grid cell relative to the client origin,
     matching the placement in the display procedure }
   x := ((cur.x-curwin^.cs^.vp.v.s.x)-
         ((cur.x-curwin^.cs^.vp.v.s.x) mod (8*chrheight))) div chrheight;
   y := (cur.y-curwin^.cs^.vp.v.s.y) div uiscl(23);
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      { port: the original passed the cell coordinates unscaled here }
      plcstr(curwin^.cs^.vp.v.s.x+dspbut.x*chrheight, curwin^.cs^.vp.v.s.y+dspbut.y*uiscl(23), dspsav, 8, black,
             yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 0; { port: start at grid row 0 }
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
               plcstr(curwin^.cs^.vp.v.s.x+x*chrheight, curwin^.cs^.vp.v.s.y+y*uiscl(23), bs, 8, black, lgreen, true);
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
            { port: wrap by client height; reset to grid row 0 }
            if curwin^.cs^.vp.v.s.y+(yi+2)*uiscl(23) <
               curwin^.cs^.vp.v.e.y then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 0

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
{******************************************************************************

FRAGMENT P: LAYOUT COMMAND LAYER

Ported from icdg.pas (all 722 lines). Contains the layout mode
set (setlayout), the layer visibility and cell contents
visibility toggles (togvis/togins), the layer intersection
generator (dointer and its nested traversal), and the layer
rectangle draw command (dolayer).

Port notes:

1. All external declarations deleted (spec rule 2); every name
   icdg imported resolves against earlier fragments (canact/
   stopact/cruler/zruler/chktar/setbound/setsbound/redraw/
   dispcell in frag_d, realc/snapto/inactive/setcur/rescur/
   setbox/resbox/butact/butina in frag_b, rotx/roty/corrot/
   netmir/ratbox/rregion in frag_f, resptr in frag_n). blockr
   was declared external but never called; dropped.
2. intersect was already ported into frag_f.pas (icdd declared
   it external); it is SKIPPED here — dointer calls the frag_f
   copy.
3. dmenu has no surviving definition anywhere in the sources
   (it exists only in the pre-refactor icdc.sav; the menu redraw
   moved into dispwin when the sources were frozen mid-refactor,
   and icdg was never updated). setlayout's "dmenu ... dispcell"
   sequence is converted to the setschema/setsymbol pattern of
   the current icdc.pas: set the mode buttons, then dispwin
   (frame + menu + dispcell). See the "port:" comment in place.
4. No interface pixel constants appear in this file — all
   coordinate math is in real (schematic/layout) coordinates,
   so no uiscl scaling is applied anywhere.
5. tcont entries are rectangles (dolayer stores l^.b, dointer
   reads it) but the original define.pas left tcont out of the
   drwety variant list (SVS free-union punning). icddef.pas is
   amended to place tcont in the rectangle group, and the
   fndbound arm in frag_f that punned b on tinter entries now
   reads ir; both amendments carry "port:" comments.
6. Integrator: remove the setlayout/togvis/togins/dolayer/
   dointer stubs from icdui_base.pas, replacing them with
   forwards (frag_g dispatches to them ahead of this fragment):

      procedure setlayout; forward;
      procedure togvis; forward;
      procedure togins; forward;
      procedure dolayer; forward;
      procedure dointer(ip: drwptr); forward;

******************************************************************************}

{}
{**************************************************************

SET LAYOUT MODE

Sets the layout edit mode. The layout sheet in the current cell
is set current.

**************************************************************}

procedure setlayout;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[blayout].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smlayout]; { set symbol screen mode }
      pixsiz := dftsizl; { set base scale }
      butact(blayout); { activate layout button }
      butina(bschema); { deactivate other buttons }
      butina(bsymbol);
      butina(bsimulate);
      { port: the original called dmenu (no surviving definition; see
        header note 3) before the button set and dispcell after;
        converted to the setschema/setsymbol pattern - dispwin redraws
        the frame and menu for the new mode, then performs dispcell }
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE LAYER VISIBILITY

Toggles the states of the layer visibility.

**************************************************************}

procedure togvis;

begin

   if (curbut in [bmet1vis, bmet2vis, bpolyvis, bviavis,
                  bndiffvis, bpdiffvis, bnwellvis, bpwellvis,
                  bccutvis, bcontvis]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      if button[curbut].act then butina(curbut) { toggle status }
      else butact(curbut);
      redraw { refresh screen }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE CELL CONTENTS VISIBILITY

Toggles the states of the "insides" visibility.

**************************************************************}

procedure togins;

begin

   if (curbut = binsides) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      if button[curbut].act then butina(curbut) { toggle status }
      else butact(curbut);
      redraw { refresh screen }

   end;
   resptr { reset buttons }

end;
{}
{ port: FIND INTERSECTION (procedure intersect) was here in icdg.pas;
  it is ported in frag_f.pas (icdd declared it external) and is
  skipped in this fragment }
{}
{**************************************************************

ENTER INTERSECTION

This routine finds the
"intersection" of the given layer rectangle with any other
rectangle in the poly, metals and diff layers. An intersection
is an overlapping region of two rectangles.
Once found, the intersection is assigned the color of the
highest priority layer's "dark" equivalent, and entered into
the intersection draw list.

**************************************************************}

procedure dointer(ip: drwptr);

var ipx1, ipy1, ipx2, ipy2: integer;

{ check region intersection }

procedure chkintr(pc:                 drwptr; { 1st region cell }
                  p:                  drwptr; { 1st region layer }
                  { 1st region coordinates }
                  x1, y1, x2, y2:     integer;
                  cpc:                drwptr; { 2nd region cell }
                  cp:                 drwptr; { 2nd region layer }
                  { 2nd region coordinates }
                  cx1, cy1, cx2, cy2: integer);

var l: drwptr;  { list pointer }
    irx1, iry1, irx2, iry2: integer; { intersection holder }
    r:     boolean; { intersection flag }

begin

   if (p <> cp) and (p^.typ <> cp^.typ) and
      not ((p^.typ = tpdiff) and (cp^.typ = tndiff)) and
      not ((p^.typ = tndiff) and (cp^.typ = tpdiff)) and
      not ((p^.typ <> tmet2) and (cp^.typ = tcont)) and
      not ((p^.typ = tcont) and (cp^.typ <> tmet2)) then  begin

      { not same entry, type or diffs }
      { find intersection of rectangles }
      intersect(x1, y1, x2, y2, cx1, cy1, cx2, cy2,
                irx1, iry1, irx2, iry2, r);
      if r then begin { intersection found }

         new(l); { get new draw entry }
         l^.typ := tinter; { set intersection type }
         l^.ir.s.x := irx1; { place coordinates }
         l^.ir.s.y := iry1;
         l^.ir.e.x := irx2;
         l^.ir.e.y := iry2;
         { rationalize it }
         ratbox(l^.ir.s.x, l^.ir.s.y, l^.ir.e.x, l^.ir.e.y);
         { find color based on priority }
         if p^.typ = tmet2 then begin

            { metal 2 }
            l^.cl := cyan; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism2]; { enter to met 2 intersection list }
            curwin^.cs^.dl[ltism2] := l

         end else if cp^.typ = tmet2 then begin

            { metal 2 }
            l^.cl := cyan; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism2]; { enter to met 2 intersection list }
            curwin^.cs^.dl[ltism2] := l

         end else if p^.typ = tmet1 then begin

            { metal 1 }
            l^.cl := blue; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism1]; { enter to met 1 intersection list }
            curwin^.cs^.dl[ltism1] := l

         end else if cp^.typ = tmet1 then begin

            { metal 1 }
            l^.cl := blue; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism1]; { enter to met 1 intersection list }
            curwin^.cs^.dl[ltism1] := l

         end else if p^.typ = tpoly then begin

            { poly }
            l^.cl := red; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltisply]; { enter to poly intersection list }
            curwin^.cs^.dl[ltisply] := l

         end else begin

            { poly }
            l^.cl := red; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltisply]; { enter to poly intersection list }
            curwin^.cs^.dl[ltisply] := l

         end

      end

   end

end;

{ declared ahead }

procedure intcell(ipc:    drwptr;  { intersect cell }
                  ip:     drwptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;
                  pc:     drwptr;  { cell pointer }
                  p:      shtptr;  { cell sheet }
                  ct:     celtyp;  { cell type }
                  ox, oy: integer; { cell origin }
                  r:      rotmod); { cell rotation }
                  forward;

{ check cell list intersections }

procedure intfigc(ipc:    drwptr;  { intersect cell }
                  ip:     drwptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;
                  d:      drwptr;  { figure to process }
                  pc:     drwptr;  { cell pointer }
                  p:      shtptr;  { cell sheet }
                  ox, oy: integer; { cell origin }
                  rt:     rotmod); { cell rotation }

var x1, y1, x2, y2: integer; { layer holder }
    co:             point;   { cell origin }

begin

   if d^.typ = tcell then begin { subcell }

      co := d^.cr.o; { find net origin }
      corrot(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, ox, oy, co,
             abs(d^.cr.cp^.bbex-d^.cr.cp^.bbsx)+1,
             abs(d^.cr.cp^.bbey-d^.cr.cp^.bbsy)+1, rt, d^.rm);
      { intersect with net rotation }
      intcell(ipc, ip, ipx1, ipy1, ipx2, ipy2,
              pc, d^.cr.cp, d^.cr.ct, co.x, co.y, netmir(rt, d^.rm));

   end else begin

      { find effective box }
      x1 := rotx(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, ox,
                 d^.b.s.x, d^.b.s.y, rt);
      y1 := roty(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, oy,
                 d^.b.s.x, d^.b.s.y, rt);
      x2 := rotx(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, ox,
                 d^.b.e.x, d^.b.e.y, rt);
      y2 := roty(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, oy,
                 d^.b.e.x, d^.b.e.y, rt);
      ratbox(x1, y1, x2, y2); { rationalize }
      if ip^.typ = tcell then { process subcell }
         intcell(pc, d, x1, y1, x2, y2,
                 ip, ip^.cr.cp, ip^.cr.ct, ip^.cr.o.x,
                 ip^.cr.o.y, ip^.rm)
      else { test/generate intersection }
         chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2,
                 pc, d, x1, y1, x2, y2)

   end

end;

{ cell intersections }

{ port: parameter list repeated per Pascaline forward convention }

procedure intcell(ipc:    drwptr;  { intersect cell }
                  ip:     drwptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;
                  pc:     drwptr;  { cell pointer }
                  p:      shtptr;  { cell sheet }
                  ct:     celtyp;  { cell type }
                  ox, oy: integer; { cell origin }
                  r:      rotmod); { cell rotation }

var d: drwptr;
    cr: region; { cell region }

begin

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
   if (ct = ctlay) and { if layout cell }
      (cr.e.x >= ipx1) and { intersects with target layer }
      (cr.s.x <= ipx2) and
      (cr.e.y >= ipy1) and
      (cr.s.y <= ipy2)  then begin

      { do layers }
      d := p^.dl[ltmet2]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ox, oy, r);
         d := d^.next { next entry }

      end;
      d := p^.dl[ltcont]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ox, oy, r);
         d := d^.next { next entry }

      end;
      d := p^.dl[ltpmd]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ox, oy, r);
         d := d^.next { next entry }

      end;
      { do subcells }
      d := p^.dl[ltcell]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ox, oy, r);
         d := d^.next { next entry }

      end

   end

end;

{ check standard intersections }

procedure intfig(ip: drwptr; { intersect figure }
                 { region }
                 ipx1, ipy1, ipx2, ipy2: integer;
                 p: drwptr); { intersecting figure }

var x1, y1, x2, y2: integer; { figure bounds holder }

begin

   if p^.typ = tcell then { process cell reference }
      intcell(nil, ip, ipx1, ipy1, ipx2, ipy2,
              p, p^.cr.cp, p^.cr.ct, p^.cr.o.x, p^.cr.o.y, p^.rm)
   else begin

      { port: p^.b hoisted to locals; the original passed the members
        directly, but 12-argument calls whose trailing arguments are
        variant-checked member loads exhaust the pgen register
        allocator ("Out of registers") }
      x1 := p^.b.s.x;
      y1 := p^.b.s.y;
      x2 := p^.b.e.x;
      y2 := p^.b.e.y;
      if ip^.typ = tcell then { process cell reference }
         intcell(nil, p, x1, y1, x2, y2,
                 ip, ip^.cr.cp, ip^.cr.ct, ip^.cr.o.x, ip^.cr.o.y, ip^.rm)
      else { test/generate intersection }
         chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2,
                 nil, p, x1, y1, x2, y2)

   end

end;

{ intersect single list }

procedure intlst(ip: drwptr; { intersect figure }
                 { region }
                 ipx1, ipy1, ipx2, ipy2: integer;
                 p: drwptr); { intersecting figure list }

begin

   while p <> nil do begin { traverse list }

      intfig(ip, ipx1, ipy1, ipx2, ipy2, p); { draw }
      p := p^.next { next entry }

   end

end;

begin

   if ip^.typ = tcell then begin { is cell }

      { find bounds of cell }
      ipx1 := ip^.cr.o.x;
      ipy1 := ip^.cr.o.y;
      if ip^.rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

         ipx2 := ip^.cr.o.x + abs(ip^.cr.cp^.bbex - ip^.cr.cp^.bbsx);
         ipy2 := ip^.cr.o.y + abs(ip^.cr.cp^.bbey - ip^.cr.cp^.bbsy)

      end else begin { on side }

         ipx2 := ip^.cr.o.x + abs(ip^.cr.cp^.bbey - ip^.cr.cp^.bbsy);
         ipy2 := ip^.cr.o.y + abs(ip^.cr.cp^.bbex - ip^.cr.cp^.bbsx)

      end

   end else begin { figure }

      ipx1 := ip^.b.s.x; { set bounds }
      ipy1 := ip^.b.s.y;
      ipx2 := ip^.b.e.x;
      ipy2 := ip^.b.e.y

   end;
   { find poly, metals and diff intersects }
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltmet2]);
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltcont]);
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltpmd]);
   { find cell intersects }
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltcell])

end;
{}
{**************************************************************

LAYER DRAW

Handles the layer draw mode. Handles the activation of the button,
the start and cursor draw, and the box entry.

**************************************************************}

procedure dolayer;

var l:              drwptr; { line entry }

begin

   if (curbut in [bmet1, bmet2, bpoly, bvia, bndiff, bpdiff,
                  bnwell, bpwell, bccut, bcont]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { mark box mode }
      stopact; { stop all modes }
      butact(curbut); { set line mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bmet1, bmet2, bpoly, bvia, bndiff,
                           bpdiff, bnwell, bpwell, bccut,
                           bcont]) and
               inactive(cur) and
               (puck.b[1].a or puck.b[2].a or
               (puck.b[1].d and puck.b[1].dg) or
               (puck.b[2].d and puck.b[2].dg)) then begin

      { enter layer }
      endp := cur; { make sure end is established }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y);
      cruler; { clear ruler }
      if (str.x <> endp.x) and (str.y <> endp.y) then begin

         { is a two-dementional object }
         new(l); { get new draw entry }
         case drmbut of { layer type }

            bmet1:  begin l^.typ := tmet1;  l^.cl := lblue end;
            bmet2:  begin l^.typ := tmet2;  l^.cl := lcyan end;
            bpoly:  begin l^.typ := tpoly;  l^.cl := lred end;
            bvia:   begin l^.typ := tvia;   l^.cl := gray end;
            bcont:  begin l^.typ := tcont;  l^.cl := black end;
            bndiff: begin l^.typ := tndiff; l^.cl := green end;
            bpdiff: begin l^.typ := tpdiff; l^.cl := magenta end;
            bnwell: begin l^.typ := tnwell; l^.cl := yellow end;
            bpwell: begin l^.typ := tpwell; l^.cl := brown end;
            bccut:  begin l^.typ := tccut;  l^.cl := dwhite end

         end;
         l^.b.s.x := str.x; { place coordinates }
         l^.b.s.y := str.y;
         l^.b.e.x := endp.x;
         l^.b.e.y := endp.y;
         { rationalize it }
         ratbox(l^.b.s.x, l^.b.s.y, l^.b.e.x, l^.b.e.y);
         setbound(l^.b.s.x, l^.b.s.y); { modify bounding box }
         setbound(l^.b.e.x, l^.b.e.y);
         setsbound(l^.b.s.x, l^.b.s.y); { modify symbol bounding box }
         setsbound(l^.b.e.x, l^.b.e.y);
         chktar; { check target change }
         if drmbut in [bmet1, bmet2, bpoly, bndiff, bpdiff, bcont] then
            { in poly, metals, and diff layer }
            dointer(l); { enter to intersection list }
         case drmbut of { layer type }

            bmet1:  begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bmet2:  begin l^.next := curwin^.cs^.dl[ltmet2];
                          curwin^.cs^.dl[ltmet2] := l end;
            bpoly:  begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bvia:   begin l^.next := curwin^.cs^.dl[ltvia];
                          curwin^.cs^.dl[ltvia] := l end;
            bcont:  begin l^.next := curwin^.cs^.dl[ltcont];
                          curwin^.cs^.dl[ltcont] := l end;
            bndiff: begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bpdiff: begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bnwell: begin l^.next := curwin^.cs^.dl[ltwell];
                          curwin^.cs^.dl[ltwell] := l end;
            bpwell: begin l^.next := curwin^.cs^.dl[ltwell];
                          curwin^.cs^.dl[ltwell] := l end;
            bccut:  begin l^.next := curwin^.cs^.dl[ltovg];
                          curwin^.cs^.dl[ltovg] := l end

         end;
         rescur; { remove cursor }
         { Redraw region. This is the same as a draw of the figure, but
           makes sure that the layers are displayed in the correct
           priority. }
         rregion(l^.b.s.x, l^.b.s.y, l^.b.e.x, l^.b.e.y);
         setcur;  { replace cursor }
         boxdwn := false { since we have overwritten box }

      end else begin { eliminate box }

         rescur; { remove cursor }
         resbox; { remove box }
         setcur  { set cursor }

      end;
      drmbut := bnull { reset line mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      { begin box }
      str := cur; { set start of box }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      tstr := str; { save as true start }
      snapto(str.x, str.y); { snap that }
      endp := str; { set end of box }
      rescur; { remove cursor }
      setbox; { set line to screen }
      zruler; { update ruler }
      setcur; { replace cursor }
      { set mode }
      if button[bmet1].act then drmbut := bmet1
      else if button[bmet2].act then drmbut := bmet2
      else if button[bpoly].act then drmbut := bpoly
      else if button[bvia].act then drmbut := bvia
      else if button[bcont].act then drmbut := bcont
      else if button[bndiff].act then drmbut := bndiff
      else if button[bpdiff].act then drmbut := bpdiff
      else if button[bnwell].act then drmbut := bnwell
      else if button[bpwell].act then drmbut := bpwell
      else if button[bccut].act then drmbut := bccut

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{ UNRESOLVED: none. Every name used here is defined in earlier
  fragments (see header note 1); nothing from icdh (frag_q,
  ported in parallel) is called by this fragment. dmenu, the one
  dangling external in the original, is resolved by the dispwin
  conversion (header note 3). Integration: remove the five
  icdui_base.pas stubs (setlayout/togvis/togins/dolayer/dointer)
  and forward them per header note 6; this fragment concatenates
  after frag_g. }
{******************************************************************************

FRAGMENT Q: SIMULATE MODE LAYER

Ported from icdh.pas (complete file). Contains the simulate mode
set (setsimulate), the digital and analog trace drawers (dtrace,
atrace) called by drwfig for the ttrc/tatrc figure types, the
trace line editors (trclin, atrclin) and the waveform edit
command (dowave).

Port notes:

1. All external declarations deleted per spec rule 2; every name
   resolves in frag_b/c/d/f/n except dmenu (icdg fragment, ported
   in parallel) - see UNRESOLVED at the end.
2. All numeric constants in this file (trace height 4800, the
   state baseline offsets 900/2400/3900, trcsiz/stpsiz multiples,
   timesiz/voltsiz scaling, the 6.5 volt center) are virtual
   (real) trace coordinates, converted to the screen by viewc/
   line/liner - none are interface pixels, so no uiscl scaling
   applies anywhere in this fragment.
3. The variant guards here read the active variant's own fields
   (ttrc guard reads ts, tatrc guard reads as) - no punning
   repairs were needed. The tatrc field name "as" is legal in
   P6/Pascaline and ports unchanged.
4. No timing (wait/gettim) logic existed in icdh.pas.
5. Replaces the icdui_base.pas stubs setsimulate, dowave, dtrace
   and atrace (integrator: remove those stubs when concatenating
   this fragment).

******************************************************************************}

{}
{**************************************************************

SET SIMULATE MODE

Sets the simulate mode. The simulate sheet in the current cell
is set current.

**************************************************************}

procedure setsimulate;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[bsimulate].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smsimulate]; { set symbol screen mode }
      pixsiz := dftsiz; { set base scale }
      butact(bsimulate); { activate layout button }
      butina(blayout); { deactivate other buttons }
      butina(bschema);
      butina(bsymbol);
      { port: the original called dmenu (no surviving definition) and
        dispcell; converted to the setschema/setlayout pattern - dispwin
        redraws frame and menu for the new mode, then performs dispcell }
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

DRAW TRACE

Draws the given trace at the given position.
The trace is drawn from the given point to the left, using
substitute colors.

**************************************************************}

procedure dtrace(ts: point;   { start point of trace }
                 tl: trcptr;  { trace list }
                 r:  region); { clip region }

var tc:   color;   { trace color }
    ltc:  color;   { last trace color }
    off:  integer; { baseline offset }
    loff: integer; { last offset }
    ltp:  trcptr;  { last trace entry }
    ib:   region;  { trace inclusion region }
    cl:   region;  { connection line }
    nl:   region;  { next line }
    t:    integer;

{ set color and offset according to state }

procedure setclr(s: nodest);

begin

   case s of { set trace color }

      nsundef: begin tc := yellow;  off := 2400 end; { soft unknown }
      nsindet: begin tc := yellow;  off := 2400 end; { soft unknown }
      nsindrh: begin tc := brown;   off := 2400 end; { hard unknown }
      nsindrl: begin tc := brown;   off := 2400 end; { hard unknown }
      nswidh:  begin tc := brown;   off := 2400 end; { hard unknown }
      nswidl:  begin tc := brown;   off := 2400 end; { hard unknown }
      nscont:  begin tc := lred;    off := 2400 end; { conflict }
      nswcont: begin tc := lred;    off := 2400 end; { conflict }
      nshigh:  begin tc := green;   off := 900  end; { hard high }
      nslow:   begin tc := blue;    off := 3900 end; { hard low }
      nsstrh:  begin tc := cyan;    off := 900  end; { soft high }
      nsstrl:  begin tc := magenta; off := 3900 end; { soft low }
      nswhigh: begin tc := green;   off := 900  end; { hard high }
      nswlow:  begin tc := blue;    off := 3900 end; { hard low }
      nsvdd:   begin tc := green;   off := 900  end; { hard high }
      nsvss:   begin tc := blue;    off := 3900 end; { hard low }

   end

end;

begin

   ib.s := ts; { set screen y width of trace }
   ib.e := ts;
   ib.e.y := ib.e.y + 4800;
   viewc(ib.s, curwin^.cs^.vp); { convert }
   viewc(ib.e, curwin^.cs^.vp);
   if (ib.s.y <= r.e.y) and (ib.e.y >= r.s.y) and
      (ib.s.x <= r.e.x) then begin

      { trace overlays region at any point }
      ltp := nil; { set no last trace }
      while tl <> nil do begin { traverse list }

         setclr(tl^.state); { set trace color }
         if ltp <> nil then begin { there is a last entry }

            { set next line }
            nl.s.x := ts.x+(ltp^.time*stpsiz);
            nl.s.y := ts.y+loff;
            nl.e.x := ts.x+(tl^.time*stpsiz);
            nl.e.y := ts.y+loff;
            viewc(nl.s, curwin^.cs^.vp); { convert }
            viewc(nl.e, curwin^.cs^.vp);
            { set connecting line }
            cl.s.x := ts.x+(tl^.time*stpsiz);
            cl.s.y := ts.y+loff;
            cl.e.x := cl.s.x;
            cl.e.y := ts.y+off;
            if cl.s.y > cl.e.y then begin { rationalize }

               t := cl.s.y;
               cl.s.y := cl.e.y;
               cl.e.y := t

            end;
            viewc(cl.s, curwin^.cs^.vp); { convert }
            viewc(cl.e, curwin^.cs^.vp);
            if nl.s.x > r.e.x then tl := nil { past view, terninate }
            else if (nl.s.x <= r.e.x) and (nl.e.x >= r.s.x) then begin

               { section in view }
               { draw new trace portion }
               if (nl.s.y >= r.s.y) and (nl.s.y <= r.e.y) then
                  begin

                  if nl.s.x < r.s.x then nl.s.x := r.s.x;
                  if nl.e.x > r.e.x then nl.e.x := r.e.x;
                  line(screen, nl.s.x, nl.s.y, nl.e.x, nl.e.y, ltc)

               end;
               { connect last state to this state }
               if (off <> loff) and (cl.s.x >= r.s.x) and
                  (cl.s.x <= r.e.x) and (cl.s.y <= r.e.y) and
                  (cl.e.y >= r.s.y) then begin

                  if cl.s.y < r.s.y then cl.s.y := r.s.y;
                  if cl.e.y > r.e.y then cl.e.y := r.e.y;
                  line(screen, cl.s.x, cl.s.y, cl.e.x, cl.e.y, black)

               end

            end

         end;
         ltc := tc; { set last trace color }
         loff := off; { set last offset }
         ltp := tl; { set last trace }
         if tl <> nil then tl := tl^.next { index next entry }

      end

   end

end;
{}
{**************************************************************

DRAW ANALOG TRACE

Draws the given trace at the given position.
The trace is drawn from the given point to the left, using
substitute colors.

**************************************************************}

procedure atrace(ts: point;   { start point of trace }
                 tl: atrcptr; { trace list }
                 r:  region); { clip region }

var ltp:  atrcptr; { last trace entry }
    ib:   region;  { trace inclusion region }
    nl:   region;  { next line }
    draw: boolean; { draw flag }

begin

   ib.s := ts; { set screen y width of trace }
   ib.e := ts;
   ib.e.y := ib.e.y + 4800;
   viewc(ib.s, curwin^.cs^.vp); { convert }
   viewc(ib.e, curwin^.cs^.vp);
   if (ib.s.y <= r.e.y) and (ib.e.y >= r.s.y) and
      (ib.s.x <= r.e.x) then begin

      { trace overlays region at any point }
      ltp := nil; { set no last trace }
      while tl <> nil do begin { traverse list }

         if ltp <> nil then begin { there is a last entry }

            { set next line }
            nl.s.x := ts.x+round(ltp^.time/timesiz);
            nl.s.y := ts.y+round((6.5-ltp^.v)/voltsiz);
            nl.e.x := ts.x+round(tl^.time/timesiz);
            nl.e.y := ts.y+round((6.5-tl^.v)/voltsiz);
            viewc(nl.s, curwin^.cs^.vp); { convert }
            viewc(nl.e, curwin^.cs^.vp);
            if nl.s.x > r.e.x then { past view, terminate }
               tl := nil
            else begin { in or in front of view }

               if (nl.s.x = nl.e.x) or (nl.s.y = nl.e.y) then
                  { orthogonal line, clip to critical region }
                  clip(nl.s.x, nl.s.y, nl.e.x, nl.e.y, draw, r)
               else
                  { clip to viewport }
                  clip(nl.s.x, nl.s.y, nl.e.x, nl.e.y, draw,
                       curwin^.cs^.vp.v);
               if draw then
                  line(screen, nl.s.x, nl.s.y, nl.e.x, nl.e.y, black)

            end

         end;
         ltp := tl; { set last trace }
         if tl <> nil then tl := tl^.next { index next entry }

      end

   end

end;
{}
{**************************************************************

ENTER TRACE LINE

A single line of a digital trace is entered. This line must
have nonzero time demension (since voltage connections are done
automatically). This also means that no change in voltage is
allowed.
The line is editted into an existing trace if one exists, or
a new trace is created.

**************************************************************}

procedure trclin(x1, y1, x2, y2: integer);

var tr, tr2: trcptr;  { trace entry pointer }
    d, d1:   drwptr;  { draw entry pointers }
    st, st2: nodest;  { node state }
    off:     integer; { baseline offset }
    loff:    integer; { last offset }
    tb:      region;  { trace box }
    s, e:    integer; { start and end step time }
    ts, te:  integer; { temp start and end }

{ find state offset }

function stoff(st: nodest): integer;

var o: integer;

begin

   case st of { set trace offset }

      nsundef: o := 2400; { soft unknown }
      nsindet: o := 2400; { soft unknown }
      nsindrh: o := 2400; { hard unknown }
      nsindrl: o := 2400; { hard unknown }
      nswidh:  o := 2400; { hard unknown }
      nswidl:  o := 2400; { hard unknown }
      nscont:  o := 2400; { conflict }
      nswcont: o := 2400; { conflict }
      nshigh:  o := 900;  { hard high }
      nslow:   o := 3900; { hard low }
      nsstrh:  o := 900;  { soft high }
      nsstrl:  o := 3900; { soft low }
      nswhigh: o := 900;  { hard high }
      nswlow:  o := 3900; { hard low }
      nsvdd:   o := 900;  { hard high }
      nsvss:   o := 3900  { hard low }

   end;
   stoff := o { return result }

end;

begin

   rescur; { lift cursor }
   ratlin(x1, y1, x2, y2); { ensure rational }
   tb.s.y := (y1 div trcsiz) * trcsiz; { find trace base }
   tb.e.y := tb.s.y + trcsiz; { find trace end }
   tb.s.x := x1;
   tb.e.x := x2;
   d1 := curwin^.cs^.dl[ltfig]; { search for existing trace }
   d := nil;
   while d1 <> nil do begin

      if d1^.typ = ttrc then
         if d1^.ts.y = tb.s.y then d := d1; { found, save }
      d1 := d1^.next { next entry }

   end;
   if d = nil then begin { no trace found, create one }

      new(d); { get new entry }
      d^.typ := ttrc; { set type }
      d^.ts.y := tb.s.y; { set base }
      d^.ts.x := 0;
      d^.tl := nil; { clear trace list }
      d^.next := curwin^.cs^.dl[ltfig]; { insert to list }
      curwin^.cs^.dl[ltfig] := d

   end;
   { find start and end times }
   s := x1 div stpsiz;
   e := x2 div stpsiz;
   { find state }
   if (y1 mod trcsiz) = 900 then st := nshigh { high }
   else if (y1 mod trcsiz) = 2400 then st := nsindet { indeterminate }
   else st := nslow; { low }
   { erase overwritten traces }
   tr := d^.tl; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if tr2 <> nil then begin { there is a last entry }

         loff := stoff(tr2^.state); { find last state }
         off := stoff(tr^.state); { find this state }
         { erase horizontal lines }
         if ((tr^.time >= s) and (tr^.time <= e)) or
            ((tr2^.time >= s) and (tr2^.time <= e)) then begin

            { one end in overwrite region }
            ts := tr2^.time; { set start and end }
            te := tr^.time;
            if ts < s then ts := s; { clip }
            if te > e then te := e;
            { white out line }
            liner(ts*stpsiz, tb.s.y+loff, te*stpsiz,
                  tb.s.y+loff, white, curwin^.cs^.vp.v)

         end;
         { erase vertical lines }
         if (tr^.time >= s) and (tr^.time <= e) then
            if loff <> off then { not same state }
               { white out line }
               liner(tr^.time*stpsiz, tb.s.y+loff,
                     tr^.time*stpsiz,
                     tb.s.y+off, white, curwin^.cs^.vp.v)

      end;
      tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { find 2nd (ending) state }
   tr := d^.tl; { index list top }
   tr2 := nil; { set found entry nil }
   st2 := st; { set as begining }
   while tr <> nil do begin { traverse }

      if tr^.time > e then begin { found }

         tr2 := tr; { place entry }
         tr := nil { flag complete }

      end else begin

         st2 := tr^.state; { set running state }
         tr := tr^.next { next entry }

      end

   end;
   { if no proper ending, set to same as begining }
   if tr2 = nil then st2 := st;
   { delete all entries to overwritten by new section }
   tr := d^.tl; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if (tr^.time >= s) and (tr^.time <= e) then begin

         { delete trace entry }
         if tr2 = nil then d^.tl := tr^.next { gap list }
         else tr2^.next := tr^.next { gap list }

      end else tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { find last entry before insert }
   tr := d^.tl; { index 1st trace entry }
   tr2 := nil; { clear last }
   while tr <> nil do begin { traverse }

      if tr^.time > s then tr := nil { flag found }
      else begin { next entry }

         tr2 := tr; { set last }
         tr := tr^.next { next entry }

      end

   end;
   new(tr); { get new trace entry }
   tr^.time := s; { place time }
   tr^.state := st; { place state }
   if tr2 = nil then begin { insert at top }

      tr^.next := d^.tl; { link in }
      d^.tl := tr

   end else begin { insert middle }

      tr^.next := tr2^.next; { link in }
      tr2^.next := tr

   end;
   tr2 := tr; { save as last }
   new(tr); { get new trace entry }
   tr^.time := e; { place time }
   tr^.state := st2; { place state }
   tr^.next := tr2^.next; { link in }
   tr2^.next := tr;
   { refresh region of trace }
   rregion(tb.s.x, tb.s.y, tb.e.x, tb.e.y);
   setcur { replace cursor }

end;
{}
{**************************************************************

ENTER ANALOG TRACE LINE

A single line of a analog trace is entered.
The line is editted into an existing trace if one exists, or
a new trace is created.

**************************************************************}

procedure atrclin(x1, y1, x2, y2: integer);

var tr, tr2: atrcptr; { trace entry pointer }
    tb:      region;  { trace box }
    s, e:    real;    { start and end time }
    d, d1:   drwptr;  { draw entry pointers }
    ts, te:  integer; { start and end temp }

begin

   rescur; { lift cursor }
   ratlin(x1, y1, x2, y2); { ensure rational }
   tb.s.y := (y1 div trcsiz) * trcsiz; { find trace base }
   tb.e.y := tb.s.y + trcsiz; { find trace end }
   tb.s.x := x1;
   tb.e.x := x2;
   d1 := curwin^.cs^.dl[ltfig]; { search for existing trace }
   d := nil;
   while d1 <> nil do begin

      if d1^.typ = tatrc then
         if d1^.as.y = tb.s.y then d := d1; { found, save }
      d1 := d1^.next { next entry }

   end;
   if d = nil then begin { no trace found, create one }

      new(d); { get new entry }
      d^.typ := tatrc; { set type }
      d^.as.y := tb.s.y; { set base }
      d^.as.x := 0;
      d^.al := nil; { clear trace list }
      d^.next := curwin^.cs^.dl[ltfig]; { insert to list }
      curwin^.cs^.dl[ltfig] := d

   end;
   { find start and end times }
   s := x1 * timesiz;
   e := x2 * timesiz;
   { erase overwritten traces }
   tr := d^.al; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if tr2 <> nil then begin { there is a last entry }

         { erase lines }
         if (tr2^.time <= e) and (tr^.time >= s) then begin

            { crosses our region }
            ts := d^.as.x+round(tr2^.time/timesiz);
            te := d^.as.x+round(tr^.time/timesiz);
            { extend region to cover }
            if ts < tb.s.x then tb.s.x := ts;
            if te > tb.e.x then tb.e.x := te;
            { white out line }
            liner(d^.as.x+round(tr2^.time/timesiz),
                  d^.as.y+round((6.5-tr2^.v)/voltsiz),
                  d^.as.x+round(tr^.time/timesiz),
                  d^.as.y+round((6.5-tr^.v)/voltsiz),
                  white, curwin^.cs^.vp.v)

         end

      end;
      tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { delete all entries to overwritten by new section }
   tr := d^.al; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if (tr^.time >= s) and (tr^.time <= e) then begin

         { delete trace entry }
         if tr2 = nil then d^.al := tr^.next { gap list }
         else tr2^.next := tr^.next { gap list }

      end else tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { find last entry before insert }
   tr := d^.al; { index 1st trace entry }
   tr2 := nil; { clear last }
   while tr <> nil do begin { traverse }

      if tr^.time > s then tr := nil { flag found }
      else begin { next entry }

         tr2 := tr; { set last }
         tr := tr^.next { next entry }

      end

   end;
   new(tr); { get new trace entry }
   tr^.time := s; { place time }
   tr^.v := 6.5-((y1-tb.s.y)*voltsiz); { place value }
   if tr2 = nil then begin { insert at top }

      tr^.next := d^.al; { link in }
      d^.al := tr

   end else begin { insert middle }

      tr^.next := tr2^.next; { link in }
      tr2^.next := tr

   end;
   tr2 := tr; { save as last }
   new(tr); { get new trace entry }
   tr^.time := e; { place time }
   tr^.v := 6.5-((y2-tb.s.y)*voltsiz); { place value }
   tr^.next := tr2^.next; { link in }
   tr2^.next := tr;
   { refresh region of trace }
   rregion(tb.s.x, tb.s.y, tb.e.x, tb.e.y);
   setcur { replace cursor }

end;
{}
{**************************************************************

PERFORM WAVEFORM EDIT

Handles the mode, setup and entry of waveforms.

**************************************************************}

procedure dowave;

var p:      point;
    el:     boolean; { line was entered }

begin

   el := false; { set no line entered }
   if (curbut in [bdwave, bawave]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set wave mode }
      stopact; { stop all modes }
      butact(curbut); { set wave mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bdwave, bawave]) and
               inactive(cur) and
               (puck.b[2].a or puck.b[1].a or
                (puck.b[1].d and puck.b[1].dg) or
                (puck.b[4].s and (drmbut = bawave) and
                 ((str.x <> endp.x) or (str.y <> endp.y)))) then
      begin

      { enter wave }
      setend; { make sure end is established }
      if not cntdrw then cruler; { clear ruler }
      if drmbut = bawave then atrclin(str.x, str.y, endp.x, endp.y)
      { if occupies time, enter to trace }
      else if str.x <> endp.x then trclin(str.x, str.y, endp.x, endp.y)
      else begin

         rescur; { remove cursor }
         resline; { reset line from screen }
         setcur; { replace cursor }

      end;
      lindwn := false; { since we have overwritten saved line }
      drmbut := bnull; { reset mode }
      cntdrw := false;
      el := true { set line was entered }

   end;
   if inactive(cur) and
      (puck.b[1].a or (puck.b[2].a and not el) or
       (puck.b[4].s and button[bawave].act and
        (drmbut <> bawave))) then begin

      { begin wave }
      cntdrw := puck.b[4].s; { set continous draw mode }
      { find real position }
      p := cur;
      realc(p, curwin^.cs^.vp); { convert coordinates }
      if el then
         { line previously entered, set for continuation }
         str := endp { set start of line to old end }
      else { new line }
         str := p; { set start of line }
      tstr := str; { save as true start }
      snapto(str.x, str.y); { snap that }
      setend; { set up end }
      rescur; { remove cursor }
      setline; { set line to screen }
      setcur; { replace cursor }
      { set draw mode }
      if button[bdwave].act then drmbut := bdwave
      else drmbut := bawave;
      updrul { update ruler }

   end;
   if cntdrw and not puck.b[4].s then begin

      { continous draw dropped, exit mode }
      rescur; { remove cursor }
      resline; { reset line from screen }
      setcur; { replace cursor }
      lindwn := false; { since we have overwritten saved line }
      drmbut := bnull; { reset mode }
      cntdrw := false

   end;
   { port: resptr disabled as in doline - a persistent-mode handler must not
     consume the puck flags, or dobutton(curbut) never sees the click and the
     screen buttons cannot switch modes }

end;
{}
{ UNRESOLVED: names called here but defined outside this fragment:

  icdg fragment (parallel): dmenu - draw menu; called by setsimulate.
  Until that fragment lands, a temporary "procedure dmenu; begin end;"
  stub ahead of this fragment satisfies the reference.
  Stub replacement: this fragment supplies the real setsimulate,
  dowave, dtrace and atrace; the matching no-op stubs in
  icdui_base.pas must be removed at integration (dtrace/atrace are
  called earlier by drwfig in frag_f, so if forward references are
  needed, convert those two stubs to forward declarations instead).
  Callers wired elsewhere: frag_g dispatch (bsimulate -> setsimulate,
  bdwave/bawave -> dowave), frag_f drwfig (ttrc -> dtrace,
  tatrc -> atrace). }
{******************************************************************************

PRINTER LAYER (port of icde.pas)

The print pipeline of ICD: the sheet figure walkers rasterize the
drawing, through the p* primitives (pliner, pboxr, parcr, pvchar...),
into the printer strip buffer prtbuf (a [0..pbxmax, 0..pbymax] color
array in icddef), which is walked down the page strip by strip. This
layer draws ONLY into prtbuf and the print output file; it never calls
the graphics layer. The pop-up configuration menu (printpop, update,
strpedt, dopedt, printstop, doprint) is normal UI code and uses the
ported plcstr/updbut/block/box interface with uiscl() scaling.

port: printer back end conversion. The original drove a Fujitsu DL3400
dot matrix printer through the aux port (fjdl3400/printer.pas): strprt
reset the printer, outbuf dithered one completed 24-row swath of prtbuf
into ribbon passes and pumped the bytes out, offy spaced blank rows,
pagprt formed off the page. The port keeps the entire rasterization
pipeline intact but replaces the device with a portable pixmap: strprt
opens a temporary body file (icdprint.tmp), outbuf appends each
completed strip as one "r g b" ASCII triplet per pixel (fixed width
pbxmax+1, columns past the strip width padded white), offy appends
blank rows, and pagprt writes icdprint.ppm with the P3 header (the
height is the accumulated row count, which is why the body is buffered
in a temp file: PPM wants the height up front, but the original streams
strips of unknown total count), copies the body over, and closes both.
The 16 colors map to RGB exactly as the screen palette in setfcolor
(thirds of full scale; maxval 255). printstop abandons any open body
file. The external declarations that headed icde.pas are deleted per
spec; getpix (used only by scnprt) does not exist in the port.

******************************************************************************}

{ port: print output file state (replaces the aux port channel) }

var prttmp:  text;    { pixmap body temp file (raster rows, header deferred) }
    prtppm:  text;    { finished pixmap file }
    prtrows: integer; { raster rows accumulated in the body }
    prtopen: boolean; { print body file is open (set false by iniprt) }

{ find pixmap RGB for ICD color; same ratioed EGA palette as setfcolor,
  at maxval 255 (port: replaces the DL3400 ribbon dither tables) }

procedure ppmclr(c: color; var r, g, b: integer);

begin

   case c of

      black:    begin r := 0;   g := 0;   b := 0   end;
      blue:     begin r := 0;   g := 0;   b := 170 end;
      green:    begin r := 0;   g := 170; b := 0   end;
      cyan:     begin r := 0;   g := 170; b := 170 end;
      red:      begin r := 170; g := 0;   b := 0   end;
      magenta:  begin r := 170; g := 0;   b := 170 end;
      brown:    begin r := 170; g := 85;  b := 0   end;
      dwhite:   begin r := 170; g := 170; b := 170 end;
      gray:     begin r := 85;  g := 85;  b := 85  end;
      lblue:    begin r := 85;  g := 85;  b := 255 end;
      lgreen:   begin r := 85;  g := 255; b := 85  end;
      lcyan:    begin r := 85;  g := 255; b := 255 end;
      lred:     begin r := 255; g := 85;  b := 85  end;
      lmagenta: begin r := 255; g := 85;  b := 255 end;
      yellow:   begin r := 255; g := 255; b := 85  end;
      white:    begin r := 255; g := 255; b := 255 end

   end

end;
{}
{**************************************************************

INITALIZE PRINTER

Sets up the basic printer parameters.

port: from fjdl3400/printer.pas iniprt, minus the ribbon dither
tables and the dither limit; the var parameters became direct
stores to the icddef globals. The page geometry of the DL3400
(13.6in printable width, 11in length, 180 dpi, 24-row swath) is
kept as the default pixmap geometry; the pop-up menu edits it.
MUST be called from iniicd (integration: add to frag_m) so that
pmax/ptrmax/ptrdpm and the file state flag are defined before
any print or pop-up use.

**************************************************************}

procedure iniprt;

begin

   { set dementions of printer buffer (13.6in) }

   ptrmax.x := (13.6*2.54)*0.01; { width of printer path (inches/meters) }
   ptrmax.y := (11.0*2.54)*0.01; { length of printer path (inch/meter) }
   ptrdpm := (180.0/2.54)*100.0; { dots per inch/centimeter }
   { total dots x, actually recalculated at the start of print }
   pmax.x := round(ptrmax.x*ptrdpm)-1;
   pmax.y := 23; { length of 24 wire print swath }
   prtopen := false { port: no print body file open }

end;
{}
{**************************************************************

PREPARE PRINTER FOR OUTPUT

Resets and initalizes the printer for output. This is done
before printout to insure that the printer has not just
been turned on.

port: opens the pixmap body temp file and zeros the row count.
Idempotent so that a print abandoned mid-page does not leave
the next print half stated.

**************************************************************}

procedure strprt;

begin

   if not prtopen then begin

      assign(prttmp, 'icdprint.tmp'); { open raster body file }
      rewrite(prttmp);
      prtrows := 0; { clear accumulated rows }
      prtopen := true { set print in progress }

   end

end;
{}
{**************************************************************

OUTPUT PRINTER BUFFER

Load the printer assembly buffer into the printer output
buffer, then outputs the buffer.

port: was the DL3400 four-ribbon dither pass; now appends the
strip to the pixmap body as one "r g b" line per pixel. Every
row is emitted at the full buffer width pbxmax+1 (a pixmap has
one width); columns past pmaxx pad white. pmaxx is clamped to
the buffer (the original passed the doubled screen width here,
sized to VGA).

**************************************************************}

procedure outbuf(var prtbuf: prtarr; pmaxx: integer);

var x, y:    integer;
    r, g, b: integer; { pixel primaries }

begin

   if prtopen then begin

      if pmaxx > pbxmax then pmaxx := pbxmax; { port: clamp to buffer }
      for y := 0 to pbymax do begin { output swath rows }

         for x := 0 to pbxmax do begin { output row pixels }

            if x <= pmaxx then ppmclr(prtbuf[x, y], r, g, b) { translate }
            else begin r := 255; g := 255; b := 255 end; { pad white }
            writeln(prttmp, r:3, ' ', g:3, ' ', b:3)

         end;
         prtrows := prtrows+1 { count raster row }

      end

   end

end;
{}
{**************************************************************

INCREMENT IN Y DIRECTION

Spaces N*180/in in Y.

port: was single increment commands to the DL3400; now appends
blank white rows to the pixmap body.

**************************************************************}

procedure offy(c: integer);

var i, x: integer;

begin

   if prtopen then
      for i := 1 to c do begin { blank rows }

         for x := 0 to pbxmax do
            writeln(prttmp, 255:3, ' ', 255:3, ' ', 255:3);
         prtrows := prtrows+1 { count raster row }

      end

end;
{}
{**************************************************************

OUTPUT PRINTER PAGE

Brings the printer to the next page position.

port: was a form feed; now finalizes the pixmap. The P3 header
(whose height is only now known) is written to icdprint.ppm,
the buffered body is copied over, and both files are closed;
the body temp file is deleted.

**************************************************************}

procedure pagprt;

var ch: char;

begin

   if prtopen then begin

      assign(prtppm, 'icdprint.ppm'); { open the pixmap file }
      rewrite(prtppm);
      writeln(prtppm, 'P3'); { plain pixmap }
      writeln(prtppm, pbxmax+1:1, ' ', prtrows:1); { width height }
      writeln(prtppm, 255:1); { maxval }
      reset(prttmp); { copy body over }
      while not eof(prttmp) do begin

         while not eoln(prttmp) do begin

            read(prttmp, ch);
            write(prtppm, ch)

         end;
         readln(prttmp);
         writeln(prtppm)

      end;
      close(prtppm);
      close(prttmp);
      { port: the body temp file is left behind: the predefined file
        delete is shadowed module-wide by the ICD delete-figure
        command (frag_f), so it cannot be named here }
      prtopen := false { print complete }

   end

end;
{}
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

            { port: getpix does not exist (spec hardware rule 1: no
              screen readback in the base layer), so print screen
              renders a blank page; kept for structure. The doubled
              store is guarded against the buffer width, since the
              ported screen can be wider than the VGA the original
              sized this to }
            c := white; { was getpix(screen, x, sy+y) }
            if x*2+1 <= pbxmax then begin

               prtbuf[x*2, y*2] := c; { place upper left }
               prtbuf[x*2+1, y*2] := c; { place upper right }
               prtbuf[x*2, y*2+1] := c; { place lower left }
               prtbuf[x*2+1, y*2+1] := c { place lower right }

            end

      end;
      outbuf(prtbuf, 2*(maxx+1)); { output buffer }
      sy := sy + 12 { next screen position }

   end;
   pagprt { next page }

end;
{}
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
{}
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
{}
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
{}
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
{}
{**************************************************************

PRINTER LINE DRAW REAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The line is clipped to the viewport.
Operates on the printer buffer.

***************************************************************}

procedure pliner(x1, y1, x2, y2: integer; c: color);

var x1s, y1s, x2s, y2s: integer;

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
{}
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

var x1s, x2s, y1s, y2s: integer; { coordinate saves }

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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
{**************************************************************

PRINTER PIE DRAW REAL

Draws a filled circle with the given center and radius.
The figure is clipped.
Operates on the printer buffer.

**************************************************************}

procedure ppier(xc, yc, r: integer; c: color);

var di, xi, yi: integer;
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
{}
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
{}
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

      else { port: characters without figures are ignored }

   end

end;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
                 cl)

      else { port: partial case; unmatched types ignored }

   end

end;
{}
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
{}
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
            pblockr(ir.s.x, ir.s.y, ir.e.x, ir.e.y, cl)

      end;

      { contact cut }
      tccut: if button[bccutvis].act then { layer enabled }
                pboxr(b.s.x, b.s.y, b.e.x, b.e.y, cl)

      else { port: partial case; unmatched types ignored }

   end

end;
{}
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
{}
{**************************************************************

PRINT CURRENT SHEET

Prints the currently selected sheet.

**************************************************************}

procedure prtsht;

var x, y:       integer;
    bc:         integer; { buffers printed count }
    bufno:      integer; { total number of buffers in y }
    bufspn:     integer; { buffer y span length in real }
    lenx, leny: integer; { lengths of plot }
    poffx:      integer; { offset x (in printer dots) }
    pwidx:      integer; { net width of x (in printer dots) }

begin

   { bounds have been set, and plot is 2d }
   if (curwin^.cs^.bbsx <> curwin^.cs^.bbex) and
      (curwin^.cs^.bbsy <> curwin^.cs^.bbey) then begin { bounds set }

      stopact; { stop all modes }
      butact(bprint); { set print mode active }
      strprt; { start up printer }
      { find total points x (y does not change) }
      pmax.x := round(ptrmax.x*ptrdpm)-1;
      { port: clamp to the strip buffer; the pop-up accepts arbitrary
        printer widths but prtbuf is fixed at pbxmax+1 dots }
      if pmax.x > pbxmax then pmax.x := pbxmax;
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
{}
{**************************************************************

UPDATE "SYMPATHETIC" BUTTONS IN PRINTER POPUP.

Updates all the buttons that rely on other buttons in the
printer pop-menu. This makes sure that all values are
correct when one is changed (something like a spreadsheet).

port: interface pixel coordinates scaled with uiscl per the
frag_c/frag_d pattern. Note the name shadows the predefined
Pascaline file procedure update from here down; nothing in
icdui uses that.

**************************************************************}

procedure update;

var bs: butstr; { temp string }

begin

   { print x, y }
   realstr(ptrmax.x-ptroff.x, bs); { place value }
   plcstr(uiscl(28*16),   uiscl(32*16), bs, 8, black, yellow, true);
   if abs(curwin^.cs^.bbex-curwin^.cs^.bbsx) <> 0 then begin

      if trnfrm in [rm0, rm180, rmm0, rmm180] then { normal }
         realstr((ptrmax.x-ptroff.x)*abs(curwin^.cs^.bbey-curwin^.cs^.bbsy)/
                 abs(curwin^.cs^.bbex-curwin^.cs^.bbsx), bs)
      else { rotated }
         realstr((ptrmax.x-ptroff.x)*abs(curwin^.cs^.bbex-curwin^.cs^.bbsx)/
                 abs(curwin^.cs^.bbey-curwin^.cs^.bbsy), bs)

   end else realstr(0.0, bs);
   plcstr(uiscl(28*16),   uiscl(33*16), bs, 8, black, yellow, true);
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
{}
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
{}
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
{}
{**************************************************************

PROCESS PRINT CONFIGURATION MENU

Presents the printer configuration menu popup, and handles
all entries thereby.

port: interface pixel coordinates scaled with uiscl per the
frag_c/frag_d pattern; the box calls gained the screen
viewport parameter (the external declaration icde carried
was stale, without the viewport the ported icdb box takes),
and the first box call read 20*16*16 for 20*16 in the
original (source damage, tolerated by the name-only SVS
linkage) - repaired.

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
   plcstr(uiscl(20*16),     uiscl(22*16), '        ', 8, black, yellow, false);
   plcstr(uiscl((20+8)*16), uiscl(22*16), '        ', 8, black, yellow, false);
   plcstr(uiscl(20*16),     uiscl(23*16), '    PRIN', 8, black, yellow, false);
   plcstr(uiscl((20+8)*16), uiscl(23*16), 'TER     ', 8, black, yellow, false);
   plcstr(uiscl(20*16),     uiscl(24*16), '    CONT', 8, black, yellow, false);
   plcstr(uiscl((20+8)*16), uiscl(24*16), 'ROL     ', 8, black, yellow, false);
   plcstr(uiscl(20*16),     uiscl(25*16), '        ', 8, black, yellow, false);
   plcstr(uiscl((20+8)*16), uiscl(25*16), '        ', 8, black, yellow, false);
   box(screen, uiscl(20*16), uiscl(22*16),
       uiscl((20+16)*16)-1, uiscl((22+4)*16)-1, black);
   plcstr(uiscl(20*16),   uiscl(26*16), 'MAX    X', 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(27*16), '       Y', 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(28*16), 'OFFSET X', 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(29*16), '       Y', 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(30*16), 'SHEET  X', 8, black, yellow, true);
   if abs(curwin^.cs^.bbex-curwin^.cs^.bbsx) <> 0 then
      realstr((abs(curwin^.cs^.bbex-curwin^.cs^.bbsx)+1)*pixsiz, bs)
   else realstr(0.0, bs);
   plcstr(uiscl(28*16),   uiscl(30*16), bs, 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(31*16), '       Y', 8, black, yellow, true);
   if abs(curwin^.cs^.bbey-curwin^.cs^.bbsy) <> 0 then
      realstr((abs(curwin^.cs^.bbey-curwin^.cs^.bbsy)+1)*pixsiz, bs)
   else realstr(0.0, bs);
   plcstr(uiscl(28*16),   uiscl(31*16), bs, 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(32*16), 'PRINT  X', 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(33*16), '       Y', 8, black, yellow, true);
   plcstr(uiscl(20*16),   uiscl(34*16), 'SETS    ', 8, black, yellow, true);
   update; { update buttons }
   box(screen, uiscl(20*16)-1, uiscl(22*16)-1,
       uiscl((20+16)*16), uiscl((22+13)*16), black);
   setcur { drop cursor }

end;
{}
{**************************************************************

REMOVE PRINTER POP-UP MENU

Removes the printer pop-menu from the screen.

port: replaces the icdui_base printstop stub (which becomes a
forward declaration; frag_d's canact calls it ahead of this
fragment). Interface pixels scaled with uiscl. Also abandons
any print body file left open by an interrupted print.

**************************************************************}

procedure printstop;

var s, e: point; { menu area bounds }

begin

   rescur; { reset cursor }
   { clear menu off screen }
   block(screen, uiscl(20*16)-1, uiscl(22*16)-1,
         uiscl((20+16)*16), uiscl((22+13)*16), white);
   s.x := uiscl(20*16)-1-1; { set bounds with slop }
   s.y := uiscl(22*16)-1-1;
   e.x := uiscl((20+16)*16)+1;
   e.y := uiscl((22+15)*16)+1;
   realc(s, curwin^.cs^.vp); { convert to real }
   realc(e, curwin^.cs^.vp); { convert coordinates }
   rregion(s.x, s.y, e.x, e.y); { redraw }
   setcur; { drop cursor }
   curscm := curscm - [smprint]; { add overlay screen mode }
   butina(bprint); { deactivate print button }
   { port: abandon print file left open by a stopped print }
   if prtopen then begin

      close(prttmp);
      prtopen := false

   end

end;
{}
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
{}
{ UNRESOLVED:

  - scnprt renders a blank page: getpix (screen readback) does not exist
    in the base layer (spec hardware rule 1) and the graphics library
    offers no pixel read; the strip/page mechanics are kept so a future
    readback (or a redraw-into-buffer scheme) can drop in. Its alt-P
    keyboard binding also needs a decision (the original used the
    chr(0)/chr(25) scan-code pair, which the event pump does not have).
  - iniprt must be called from iniicd (frag_m) - it defines pmax/ptrmax/
    ptrdpm and prtopen, none of which are otherwise initialized (the
    original initialized them in the fjdl3400 module selection that the
    port dropped).
  - icdui_base printstop stub must become a forward declaration (frag_d
    calls it ahead of this fragment); frag_g dobutton/dokeyboard printer
    arms restore to doprint/strpedt/dopedt per the integrator notes.
  - pagprt cannot remove icdprint.tmp: the predefined file delete is
    shadowed by the ICD delete-figure command (frag_f). The temp file is
    abandoned in place.
  - prtsav (printer parameter saves, bseta..bseth) had no handler in the
    original either; the arms stay empty. }
{******************************************************************************

PROGRAM INITIALIZATION AND EVENT ENTRIES

This section owns all writes to the module globals. The program module
must not write them directly: stores to record fields of imported module
globals are miscompiled by the current Pascal-P6 code generator (see
PORTING-SPEC.md, toolchain notes), and in any case the initialization
belongs with the data. The main program calls iniicd once, then feeds
events through the ev* entries below.

The initialization follows the original icd.pas (1992) main body, minus
the hardware device selection (video driver label, tablet, printer).

******************************************************************************}

{ initialize the ICD user interface }

procedure iniicd;

var li:  laytyp;  { layer index }
    tci: color;   { color index }
    bi:  blkinx;  { block index }
    pin: prtinx;  { printer save index }
    bn:  integer; { mouse button number }

begin

   initscreen; { initialize display via graphics library }
   inibut; { initalize button array }
   button[bdots].act := true; { set show grid }
   button[blines].act := true; { set show lines grid }
   button[bschema].act := true; { set schematic mode active }
   curscm := [smschema]; { set screen mode as schematic }
   button[bany].act := true;
   button[bwire].act := true; { set wire mode }
   button[bsnap].act := false;
   button[bir0].act := true; { set placement at 0 deg }
   button[bmet1vis].act := true; { set layers active }
   button[bmet2vis].act := true;
   button[bpolyvis].act := true;
   button[bviavis].act := true;
   button[bcontvis].act := true;
   button[bndiffvis].act := true;
   button[bpdiffvis].act := true;
   button[bnwellvis].act := true;
   button[bpwellvis].act := true;
   button[bccutvis].act := true;
   button[binsides].act := true; { set show insides }
   button[bprox].act := true; { set proximity active }
   modbut := bwire; { set wire mode }
   dsmbut := bwire;
   smslst := nil; { clear node smash list }
   bsmlst := nil; { clear bus smash list }
   for li := ltfig to ltwell do
      savlst[li] := nil; { clear save list }
   namlst := nil; { clear name save list }
   rw.s.x := -(maxint div scalem div 2); { set real borders }
   rw.s.y := -(maxint div scalem div 2);
   rw.e.x := maxint div scalem div 2;
   rw.e.y := maxint div scalem div 2;
   pixsiz := dftsiz; { set default virtual pixel size }
   ptroff.x := 0; { set zero offset }
   ptroff.y := 0;
   curbut := bnull; { set no button active }
   curdwn := false; { set cursor not on screen }
   zbxdwn := false; { set zoom box not on screen }
   mrkdwn := false; { set marker not on screen }
   rlmdwn := false; { set ruler mark not on screen }
   lindwn := false; { set line cursor not on screen }
   boxdwn := false; { set box cursor not on screen }
   cirdwn := false; { set circle cursor not on screen }
   arcdwn := false; { set arc cursor not on screen }
   tcrdwn := false; { set text cursor not on screen }
   cntdrw := false; { reset continous draw mode }
   tcolor := lblue; { set current trace color }
   bakclr := lgreen; { set windows backround color }
   bakshw := green; { set windows backrond shadow }
   baklgt := white; { set windows backround lighted }
   terminate := false; { clear terminate flag }
   blank := false; { set screen not blanked }
   { set permissable tracing colors }
   trcclrs := [lblue, lgreen, lcyan, lred, lmagenta, yellow];
   trcclr := lcyan; { set first trace color to do }
   { clear color tracking }
   for tci := black to white do trctrk[tci] := false;
   { clear block saves }
   for bi := 1 to blkmax do
      for li := ltfig to ltwell do
         blocks[bi].l[li] := nil;
   { clear printer parameter saves }
   for pin := 1 to prtmax do prtsav[pin].a := false;
   placel := nil; { clear placement cell }
   { set up whole screen viewport }
   screen.v.s.x := minx;
   screen.v.s.y := miny;
   screen.v.e.x := maxx;
   screen.v.e.y := maxy;
   screen.r := screen.v;
   { port: was 1 in the (mid-refactor) originals; the real-coordinate
     converter viewc scales by scalem/s and the draw transform viewx by
     m/s, so an identity window viewport needs s = m = scalem for the
     two conventions to agree }
   screen.s.x := scalem; { no scaling }
   screen.s.y := scalem;
   screen.m.x := scalem;
   screen.m.y := scalem;
   screen.c := screen.v; { set clip to whole screen }
   cur.x := ((maxx-minx) div 2)+minx; { reset cursor coordinates }
   cur.y := ((maxy-miny) div 2)+miny; { to middle of screen }
   { clear puck emulation state }
   for bn := 1 to 4 do begin

      puck.b[bn].s := false;
      puck.b[bn].l := false;
      puck.b[bn].a := false;
      puck.b[bn].d := false;
      puck.b[bn].dg := false

   end;
   puck.m := false;
   puck.v := true; { mouse is always valid }
   { establish initial cell }
   new(cellst);
   cellst^.name := '        ';
   cellst^.schema := nil;
   cellst^.symbol := nil;
   cellst^.layout := nil;
   cellst^.simulate := nil;
   cellst^.next := nil;
   { establish initial window }
   new(curwin);
   { set to occupy whole screen }
   plcwin(screen, curwin^.wv,
          screen.v.s.x, screen.v.s.y,
          screen.v.e.x, screen.v.e.y);
   curwin^.cc := cellst; { set current cell }
   curwin^.cs := nil; { set no current sheet }
   curwin^.lc := white; { set lit color }
   curwin^.sc := cyan; { set shadow color }
   curwin^.bc := lcyan; { set backround color }
   iniprt; { port: initialize printer parameters (icde layer) }
   block(screen, minx, miny, maxx, maxy, bakclr); { clear screen }
   dispwin { display window }

end;

{ mouse movement event. Emulates the puck movement state the tablet
  driver produced, then tracks the cursor }

procedure evmove(x, y: integer);

var bn: integer; { button index }

begin

   puck.ol := puck.cl;
   puck.cl.x := x;
   puck.cl.y := y;
   puck.m := true; { set movement flag }
   { port: set the drag flag for any held button that has wandered beyond
     dragmgn from its assertion point. The original updpuck did this via
     the drag() test; the emulation had omitted it, so zoom/pan/box/
     circle/arc completion (which need puck.b[n].d and puck.b[n].dg on
     left-button release) never fired. }
   for bn := 1 to 4 do
      if puck.b[bn].s and
         ((abs(x-puck.b[bn].ap.x) > uiscl(dragmgn)) or
          (abs(y-puck.b[bn].ap.y) > uiscl(dragmgn))) then
         puck.b[bn].dg := true;
   movcur(x, y); { track cursor }
   dispatch { port: run the command dispatch (was the command loop body) }

end;

{ mouse button event. press is true for assert, false for deassert.
  Emulates the puck button communication flags }

procedure evbut(bn: integer; press: boolean);

begin

   if bn in [1..4] then begin

      puck.b[bn].s := press;
      if press then begin

         puck.b[bn].a := true; { set assertion CMF }
         puck.b[bn].ap := cur; { record assertion location }
         puck.b[bn].dg := false { port: clear drag flag on assert }

      end else begin

         puck.b[bn].d := true; { set deassertion CMF }
         puck.b[bn].dp := cur { record deassertion location }

      end;
      chkbut; { check button actions }
      dispatch { port: run the command dispatch (was the command loop body) }

   end

end;

{ keyboard character event }

procedure evkey(c, cs: char);

begin

   dokeyboard(c, cs); { process keyboard command/entry character }
   dispatch { port: run the command dispatch (was the command loop body) }

end;

{ mouse move on the drawing subwindow: coordinates arrive subwindow
  relative; translate to main window coordinates }

procedure evsubmove(x, y: integer);

begin

   evmove(x+subr.s.x-1, y+subr.s.y-1)

end;

{ window redraw request event }

procedure evredraw;

begin

   block(screen, minx, miny, maxx, maxy, bakclr);
   dispwin

end;

{ window resize event }

procedure evresize(nx, ny: integer);

begin

   scnmaxx := nx; { port: use the size carried by the resize event }
   scnmaxy := ny;
   maxx := scnmaxx;
   maxy := scnmaxy;
   screen.v.e.x := maxx;
   screen.v.e.y := maxy;
   screen.r := screen.v;
   screen.c := screen.v;
   plcwin(screen, curwin^.wv,
          screen.v.s.x, screen.v.s.y,
          screen.v.e.x, screen.v.e.y);
   block(screen, minx, miny, maxx, maxy, bakclr);
   dispwin

end;

{ terminate request event (window close) }

procedure evterm;

begin

   terminate := true

end;

{ check terminate requested }

function termreq: boolean;

begin

   { port: the original command loop also exited on the Exit button }
   termreq := terminate or button[bexit].act

end;
{******************************************************************************

MODULE CONSTRUCTOR / DESTRUCTOR

******************************************************************************}

begin { constructor }

   subon := false { drawing subwindow not yet open }

end;

begin { destructor }

end.

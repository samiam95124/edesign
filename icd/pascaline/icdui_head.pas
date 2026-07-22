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

joins graphics;

uses icddef;

var scnmaxx: integer; { physical screen size x (pixels) }
    scnmaxy: integer; { physical screen size y (pixels) }

{******************************************************************************

BASE LAYER

Adapts the ICD drawing vocabulary to the Pascaline graphics library.
The 16 EGA colors of ICD are reproduced exactly via ratioed RGB.

******************************************************************************}

{ set foreground color from ICD color code }

procedure setfcolor(c: color);

var third: integer; { 1/3 of full scale }

begin

   third := maxint div 3;
   case c of

      black:    graphics.fcolorg(0, 0, 0);
      blue:     graphics.fcolorg(0, 0, third*2);
      green:    graphics.fcolorg(0, third*2, 0);
      cyan:     graphics.fcolorg(0, third*2, third*2);
      red:      graphics.fcolorg(third*2, 0, 0);
      magenta:  graphics.fcolorg(third*2, 0, third*2);
      brown:    graphics.fcolorg(third*2, third, 0);
      dwhite:   graphics.fcolorg(third*2, third*2, third*2);
      gray:     graphics.fcolorg(third, third, third);
      lblue:    graphics.fcolorg(third, third, maxint);
      lgreen:   graphics.fcolorg(third, maxint, third);
      lcyan:    graphics.fcolorg(third, maxint, maxint);
      lred:     graphics.fcolorg(maxint, third, third);
      lmagenta: graphics.fcolorg(maxint, third, maxint);
      yellow:   graphics.fcolorg(maxint, maxint, third);
      white:    graphics.fcolorg(maxint, maxint, maxint)

   end

end;

{ set single pixel, screen coordinates }

procedure scrsetpix(x, y: integer; c: color);

begin

   setfcolor(c);
   graphics.setpixel(x, y)

end;

{ draw line, screen coordinates }

procedure scrline(x1, y1, x2, y2: integer; c: color);

begin

   setfcolor(c);
   graphics.line(x1, y1, x2, y2)

end;

{ draw filled rectangle, screen coordinates }

procedure scrblock(x1, y1, x2, y2: integer; c: color);

begin

   setfcolor(c);
   graphics.frect(x1, y1, x2, y2)

end;

{ enter xor drawing mode (rubber band figures) }

procedure xormode;

begin

   graphics.fxor

end;

{ return to overwrite drawing mode }

procedure ovrmode;

begin

   graphics.fover

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

   setfcolor(c);
   graphics.cursorg(x, y);
   write(ch)

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

{ initialize display: graphical mode, font, screen parameters }

procedure initscreen;

begin

   graphics.auto(false);      { free the character grid }
   graphics.curvis(false);    { no text cursor }
   graphics.font(3);          { sign (sans-serif) font, as ICD look }
   graphics.fontsiz(16);      { ICD used a 16 pixel character cell }
   graphics.binvis;           { text draws foreground only }
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

{ rationalize box (from icdd.pas) }

procedure ratbox(var x1, y1, x2, y2: integer);

var t: integer;

begin

   { rationalize box }
   if x1 > x2 then
      begin t := x1; x1 := x2; x2 := t end;
   if y1 > y2 then
      begin t := y1; y1 := y2; y2 := t end

end;

{ reset pointer device. port: stub; the tablet hardware is gone and the
  mouse needs no reset }

procedure resptr;

begin

end;

{ update target area contents. port: stub; target/cell display comes
  with a later phase (icdf.pas) }

procedure updtar;

begin

end;

{ stop print in progress. port: stub; printer pass deferred (icde.pas) }

procedure printstop;

begin

end;

{ find bounding box view of sheet (from icda.pas); defined after the
  viewport and bounds layers it depends on }

procedure fndbnd(sp: shtptr; var x, y, s: integer); forward;

{ find angle of point about center (from icdc.pas); defined in the
  window management layer, forwarded here because the arc code in the
  viewport layer uses it }

function angle(x1, y1, x2, y2: integer): real; forward;

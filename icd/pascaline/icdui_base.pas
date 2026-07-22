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

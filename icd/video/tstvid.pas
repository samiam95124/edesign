{**************************************************************
*                                                             *
* VIDEO ROUTINES PACKAGE TEST PROGRAM                         *
*                                                             *
**************************************************************}

program tstvid;

label 99; { terminate program }

const
      maxint    = 2147483647; { redefine for 32 bits }

      maxlin = 200; { command line maximum length }
      labmax = 20;  { number of character in label }
      linmax = 10000; { maximum length of screen line }
      fillen = 13; { number of characters in filename }

      { reference test times, based on a 16mhz 386sx
        with a Western Digital PVGA at 1024x768x16
        (the minimum hardware requirement to run ICD). 
        Times are in seconds. }

      refpix =  71.57; { time of pixel routines }
      reflft =  31.09; { time of line fill top to bottom }
      reflfl =  26.96; { time of line fill left to right }
      refsun =  14.72; { time of "sunburst" }
      refstr =  34.82; { time of string lines }
      refssr =  31.09; { time of string lines save/restore }
      reffbk =  25.54; { time of full screen blocks }
      refdbk =  24.55; { time of decending blocks }
      refsbk =  25.11; { time of string blocks }
      refchr =  25.70; { time of character placement }
      refall = 320.22; { time for all tests }

type
     integer = longint; { redefine integers for 32 bits }
     real    = double; { redefine reals for 64 bits }

     inxlin = 0..maxlin; { index for line }
     labinx = 1..labmax; { index for label }
     labtyp = packed array [labinx] of char; { label }
     color  = (black, blue, green, cyan, red, magenta, brown,
               dwhite, gray, lblue, lgreen, lcyan, lred, lmagenta,
               yellow, white);
     lininx = 1..linmax; { index for line save }
     linarr = array[lininx] of color; { screen pixel save buffer }
     filinx = 1..fillen; { index for filename }
     point  = record x, y: integer end; { coordinate point }
     region = record s, e: point end; { rectangular region }
     { Viewport specification
       A viewport is a complete specification of the parameters
       that define a window.  }
     viewport = record { viewport parameters, in real }

                   v: region; { viewport rectangle screen }
                   r: region; { viewport rectangle real }
                   s: point;  { scale }
                   m: point;  { multiplier }
                   c: region  { clipping rectangle screen }

                end;     

var
    ds:       labtyp; { driver select label }
    cmdlin:   packed array [inxlin] of char; { command line }
    cmdptr:   inxlin;  { command line index }
    maxx:     integer; { demensions of display screen }
    maxy:     integer;
    minx:     integer;
    miny:     integer;
    x, y:     integer; { temp coordinates }
    c:        color;   { temp color }
    x1, y1, 
    x2, y2:   integer;
    xa1, ya1, 
    xa2, ya2: integer;
    i:        integer;
    li:       lininx;
    lines:    linarr;
    ch, ch1:  char;
    alphal:   array [0..127] of 0..16;
    time:     integer; { time holder }
    timpix:   integer; { time of pixel routines }
    timlft:   integer; { time of line fill top to bottom }
    timlfl:   integer; { time of line fill left to right }
    timsun:   integer; { time of "sunburst" }
    timstr:   integer; { time of string lines }
    timssr:   integer; { time of string lines save/restore }
    timfbk:   integer; { time of full screen blocks }
    timdbk:   integer; { time of decending blocks }
    timsbk:   integer; { time of string blocks }
    timchr:   integer; { time of character placement }
    ai, add:  integer; { addition holder }
    s:        packed array [1..30] of char;
    screen:   viewport; { viewport for whole screen }

procedure inialpha; external; { initalize character matrix }
{ initialize display hardware }
procedure iniscn(var maxx, maxy: integer; var s: labtyp); external; 
procedure resscn; external; { restore display hardware }
function getpix(var vp: viewport; x, y: integer): color; external; { get pixel value }
procedure setpix(var vp: viewport; x, y: integer; c: color); external; { set pixel value }
{ draw block }
procedure block(var vp: viewport; x1, y1, x2, y2: integer; c: color); external;
{ draw line }
procedure line(var vp: viewport; x1, y1, x2, y2: integer; c: color); external; { draw line }
procedure linesav(var vp: viewport; x1, y1, x2, y2: integer; c: color; var lines: linarr; 
                  var i: lininx); external; { draw line w/ save }
procedure linerst(var vp: viewport; x1, y1, x2, y2: integer; var lines: linarr; 
                  var i: lininx); external; { restore buffered line }
{ draw character onscreen }
procedure setchr(var vp: viewport; x, y: integer; ch: char; cl: color); external;
function gettim: integer; cexternal; { get current system time }
procedure clrint; external; { clear interrupt flag }
procedure setint; external; { set interrupt flag }
{}
{**************************************************************

INITALIZE CHARACTER WIDTH ARRAY

Initalizes the character widths, which are the exact number of
pixels in x that the character occupies.

**************************************************************}

procedure iniwidth;

begin

   alphal[$00] := 10; { copyright }
   alphal[$01] :=  9; { micro }
   alphal[$02] :=  0;
   alphal[$03] :=  0;
   alphal[$04] :=  0;
   alphal[$05] :=  0;
   alphal[$06] :=  0;
   alphal[$07] :=  0;
   alphal[$08] :=  0;
   alphal[$09] :=  0;
   alphal[$0a] :=  0;
   alphal[$0b] :=  0;
   alphal[$0c] :=  0;
   alphal[$0d] :=  0;
   alphal[$0e] :=  0;
   alphal[$0f] :=  0;
   alphal[$10] :=  0; 
   alphal[$11] :=  0;
   alphal[$12] :=  0;
   alphal[$13] :=  0;
   alphal[$14] :=  0;
   alphal[$15] :=  0;
   alphal[$16] :=  0;
   alphal[$17] :=  0;
   alphal[$18] :=  0;
   alphal[$19] :=  0;
   alphal[$1a] :=  0;
   alphal[$1b] :=  0;
   alphal[$1c] :=  0;
   alphal[$1d] :=  0;
   alphal[$1e] :=  0;
   alphal[$1f] :=  0;
   alphal[$20] :=  6; { ' ' }
   alphal[$21] :=  2; { '!' }
   alphal[$22] :=  5; { '"' }
   alphal[$23] :=  9; { '#' }
   alphal[$24] :=  6; { '$' }
   alphal[$25] := 11; { '%' }
   alphal[$26] :=  7; { '&' }
   alphal[$27] :=  4; { ''' }
   alphal[$28] :=  3; { '(' }
   alphal[$29] :=  3; { ')' }
   alphal[$2a] :=  6; { '*' }
   alphal[$2b] :=  6; { '+' }
   alphal[$2c] :=  3; { ',' }
   alphal[$2d] :=  4; { '-' }
   alphal[$2e] :=  2; { '.' }
   alphal[$2f] :=  4; { '/' }
   alphal[$30] :=  6; { '0' }
   alphal[$31] :=  4; { '1' }
   alphal[$32] :=  6; { '2' }
   alphal[$33] :=  6; { '3' }
   alphal[$34] :=  6; { '4' }
   alphal[$35] :=  6; { '5' }
   alphal[$36] :=  6; { '6' }
   alphal[$37] :=  6; { '7' }
   alphal[$38] :=  6; { '8' }
   alphal[$39] :=  6; { '9' }
   alphal[$3a] :=  2; { ':' }
   alphal[$3b] :=  3; { ';' }
   alphal[$3c] :=  6; { '<' }
   alphal[$3d] :=  6; { '=' }
   alphal[$3e] :=  6; { '>' }
   alphal[$3f] :=  6; { '?' }
   alphal[$40] := 13; { '@' }
   alphal[$41] :=  8; { 'A' }
   alphal[$42] :=  8; { 'B' }
   alphal[$43] :=  7; { 'C' }
   alphal[$44] :=  8; { 'D' }
   alphal[$45] :=  7; { 'E' }
   alphal[$46] :=  7; { 'F' }
   alphal[$47] :=  8; { 'G' }
   alphal[$48] :=  8; { 'H' }
   alphal[$49] :=  2; { 'I' }
   alphal[$4a] :=  6; { 'J' }
   alphal[$4b] :=  7; { 'K' }
   alphal[$4c] :=  7; { 'L' }
   alphal[$4d] := 10; { 'M' }
   alphal[$4e] :=  8; { 'N' }
   alphal[$4f] :=  8; { 'O' }
   alphal[$50] :=  8; { 'P' }
   alphal[$51] :=  8; { 'Q' }
   alphal[$52] :=  9; { 'R' }
   alphal[$53] :=  7; { 'S' }
   alphal[$54] :=  8; { 'T' }
   alphal[$55] :=  8; { 'U' }
   alphal[$56] :=  8; { 'V' }
   alphal[$57] := 14; { 'W' }
   alphal[$58] :=  9; { 'X' }
   alphal[$59] := 10; { 'Y' }
   alphal[$5a] :=  9; { 'Z' }
   alphal[$5b] :=  3; { '[' }
   alphal[$5c] :=  4; { '\' }
   alphal[$5d] :=  3; { ']' }
   alphal[$5e] :=  5; { '^' }
   alphal[$5f] :=  8; { '_' }
   alphal[$60] :=  3; { '`' }
   alphal[$61] :=  6; { 'a' }
   alphal[$62] :=  6; { 'b' }
   alphal[$63] :=  6; { 'c' }
   alphal[$64] :=  6; { 'd' }
   alphal[$65] :=  6; { 'e' }
   alphal[$66] :=  4; { 'f' }
   alphal[$67] :=  6; { 'g' }
   alphal[$68] :=  6; { 'h' }
   alphal[$69] :=  2; { 'i' }
   alphal[$6a] :=  3; { 'j' }
   alphal[$6b] :=  6; { 'k' }
   alphal[$6c] :=  2; { 'l' }
   alphal[$6d] := 10; { 'm' }
   alphal[$6e] :=  6; { 'n' }
   alphal[$6f] :=  6; { 'o' }
   alphal[$70] :=  6; { 'p' }
   alphal[$71] :=  6; { 'q' }
   alphal[$72] :=  4; { 'r' }
   alphal[$73] :=  6; { 's' }
   alphal[$74] :=  4; { 't' }
   alphal[$75] :=  6; { 'u' }
   alphal[$76] :=  8; { 'v' }
   alphal[$77] := 10; { 'w' }
   alphal[$78] :=  8; { 'x' }
   alphal[$79] :=  8; { 'y' }
   alphal[$7a] :=  6; { 'z' }
   alphal[$7b] :=  4; { left comment }
   alphal[$7c] :=  2; { '|' }
   alphal[$7d] :=  4; { right comment }
   alphal[$7e] :=  5; { '~' }
   alphal[$7f] :=  0  { del }

end;
{}
{**************************************************************

FIND ELAPSED TIME

Given a set point in time, finds the difference between that
time and the present time, or the time elapsed since.
Valid as long as the time elapsed is less than 24 hours.
Exact accuracy depends on the particular computer.
Time is given in hundreths of a second.

**************************************************************}

function elapsed(t: integer): integer;

var ct: integer; { current time }
    d:  boolean; { done flag }

begin

   ct := gettim; { get current time }
   if ct >= t then t := ct-t { find time forward }
   else t := t-ct; { find time backwards }
   elapsed := t { return result }

end;
{}
{**************************************************************

Find upper case

Translates the given character to upper case.

**************************************************************}

function ucase(c: char): char;

begin

   if c in ['a'..'z'] then ucase := chr(ord(c)-ord('a')+ord('A'))
   else ucase := c

end;
{}
{**************************************************************

Get command line

Gets the caller line into the command line buffer.
Dependant on SVS Pascal.

**************************************************************}

procedure getcml;

var i : inxlin; { index for line }
    s: string[128]; { command line holder }
    si: integer; { strings index }
    ci: integer; { character index }

begin

   for i := 1 to maxlin do cmdlin[i] := ' '; { clear command line }
   i := 1; { set 1st position }
   for si := 1 to argc-1 do begin { strings }

      for ci := 1 to length(argv[si+1]^) do begin { characters }   
   
         cmdlin[i] := argv[si+1]^[ci]; { place character }
         i := i + 1 { next position }

      end;
      cmdlin[i] := ' '; { place space to separate }
      i := i + 1

   end;
   cmdptr := 1 { set 1st character position }

end;
{}
{**************************************************************

Check character

Returns the next character in the command line.

**************************************************************}

function chkchr: char;

var c: char;

begin

   if cmdptr <> 0 then c := cmdlin[cmdptr] { return char }
   else c := ' '; { replace with space }
   chkchr := c { return result }

end;

{**************************************************************

Get next character

Skips the command pointer to the next character. Clears the 
command position if the line overflows.

**************************************************************}

procedure getchr;

begin

   if cmdptr <> 0 then begin

      if cmdptr <> maxlin then cmdptr := cmdptr + 1 { next }
      else cmdptr := 0 { clear position }

   end

end;

{**************************************************************

Skip file spaces

Skips the given text file over any spaces, except eoln.

**************************************************************}

procedure skpspc;

begin

   while (chkchr = ' ') and (cmdptr <> 0) do getchr

end;
{}
{**************************************************************

Get word from file

Gets a word from the given file, which is any sequence of
non-blank characters ending by a space or eoln, with any
number of spaces preceeding.

**************************************************************}

procedure getword(var w: labtyp);

var i : filinx; { index for name }

begin

   for i := 1 to labmax do w[i] := ' '; { initalize result }
   skpspc; { skip spaces }
   i := 1; { initalize buffer index }
   while chkchr <> ' ' do begin

      if i > labmax then begin { error }

         writeln('*** Device label too long');
         goto 99

      end;
      { get letters }
      w[i] := ucase(chkchr); { place }
      getchr; { next file position }
      i := i + 1 { next buffer position }

   end

end;
{}
begin

   inialpha; { initalize character matrix }
   iniwidth; { initalize character width table }
   getcml; { get command line }
   getword(ds); { get driver select string }
   iniscn(maxx, maxy, ds); { initalize video device }
   if maxx = 0 then begin { device not found/bad }

      writeln('*** Unable to initalize video device');
      goto 99

   end;
   minx := 0; { clear mins }
   miny := 0;
   { set up whole screen viewport }
   screen.v.s.x := minx;
   screen.v.s.y := miny;
   screen.v.e.x := maxx;
   screen.v.e.y := maxy;
   screen.r := screen.v;
   screen.s.x := 1; { no scaling }
   screen.s.y := 1;
   screen.m.x := 1;
   screen.m.y := 1;
   screen.c := screen.v; { set clip to whole screen }

   timpix := 0; { clear timers }
   timlft := 0;
   timlfl := 0;
   timsun := 0;
   timstr := 0;
   timssr := 0;
   timfbk := 0;
   timdbk := 0;
   timsbk := 0;
   timchr := 0;

   { clear screen to white }
   block(screen, minx, miny, maxx, maxy, white);

   { ********************* Begin tests ********************* }

   { *** Test direct pixel access *** }

   { check can read and write all the same values 
     at single location }

   time := gettim; { start timing }
   for c := black to white do begin

      setpix(screen, minx, miny, c);
      if getpix(screen, minx, miny) <> c then begin { error }

         resscn;
         writeln('*** Error in pixel read or write');
         goto 99

      end

   end;

   { same, but now we will do all of the screen, which could
     double as somewhat of a memory check (a full one
     using bit access would take too long) }

   c := black;
   for y := miny to maxy do
      for x := minx to maxx do begin 

      setpix(screen, x, y, c); { place pixel }
      if getpix(screen, x, y) <> c then begin { error }

         resscn;
         writeln('*** Error in pixel read or write');
         goto 99

      end;
      if c <> white then c := succ(c)
      else c := black

   end;
   timpix := elapsed(time); { set time }

   { *** test lines *** }

   { fill screen top to bottom }

   time := gettim; { start timing }
   c := lblue; { set starting color }
   for i := 1 to 100 do begin

      for y := miny to maxy do
         line(screen, minx, y, maxx, y, c);
      if c <> white then c := succ(c)
      else c := black

   end;
   timlft := elapsed(time); { set time }

   { fill screen left to right }

   time := gettim; { start timing }
   c := lmagenta; { set starting color }
   for i := 1 to 7 do begin

      for x := minx to maxx do
         line(screen, x, miny, x, maxy, c);   
      if c <> white then c := succ(c)
      else c := black

   end;
   timlfl := elapsed(time); { set time }

   { draw "sunburst" }

   time := gettim; { start timing }
   c := black; { set starting color }
   x1 := ((maxx-minx) div 2)+minx; { find screen center }
   y1 := ((maxy-miny) div 2)+miny;
   for x := minx to maxx do begin

      line(screen, x1, y1, x, miny, c);
      if c <> white then c := succ(c)
      else c := black

   end;
   for y := miny to maxy do begin

      line(screen, x1, y1, maxx, y, c);
      if c <> white then c := succ(c)
      else c := black

   end;
   for x := maxx downto minx do begin

      line(screen, x1, y1, x, maxy, c);
      if c <> white then c := succ(c)
      else c := black

   end;
   for y := maxy downto miny do begin

      line(screen, x1, y1, minx, y, c);
      if c <> white then c := succ(c)
      else c := black

   end;
   timsun := elapsed(time); { set time }

   { test "string" lines }
   
   c := black; { set starting color }
   block(screen, minx, miny, maxx, maxy, white);
   time := gettim; { start timing }
   x1 := ((maxx-minx) div 2)+minx;
   y1 := ((maxy-miny) div 2)+miny;
   xa1 := +1;
   ya1 := -1; 
   x2 := ((maxx-minx) div 2)+minx;
   y2 := ((maxy-miny) div 2)+miny;
   x2 := ((x2-minx) div 2)+minx;
   y2 := ((y2-miny) div 2)+miny;
   xa2 := -1;
   ya2 := +1;
   for i := 1 to 7000 do begin { draw }

      line(screen, x1, y1, x2, y2, c);
      { set new directions }
      if (x1 = minx) or (x1 = maxx) then xa1 := -xa1;
      if (y1 = miny) or (y1 = maxy) then ya1 := -ya1;
      if (x2 = minx) or (x2 = maxx) then xa2 := -xa2;
      if (y2 = miny) or (y2 = maxy) then ya2 := -ya2;
      x1 := x1+xa1; { move to next location }
      y1 := y1+ya1;
      x2 := x2+xa2;
      y2 := y2+ya2;
      if i mod 100 = 0 then { change colors }
         if c <> white then c := succ(c)
         else c := black

   end;
   timstr := elapsed(time); { set time }
   
   { test "string" lines, this time with save/
     restore lines }
   
   c := black; { set starting color }
   block(screen, minx, miny, maxx, maxy, white);
   { lay down graph paper }
   x := minx;
   while x <= maxx do begin

      line(screen, x, miny, x, maxy, lcyan);
      x := x+4;

   end;
   y := miny;
   while y <= maxy do begin

      line(screen, minx, y, maxx, y, lcyan);
      y := y+4;

   end;
   time := gettim; { start timing }
   x1 := ((maxx-minx) div 2)+minx;
   y1 := ((maxy-miny) div 2)+miny;
   xa1 := +1;
   ya1 := -1; 
   x2 := ((maxx-minx) div 2)+minx;
   y2 := ((maxy-miny) div 2)+miny;
   x2 := ((x2-minx) div 2)+minx;
   y2 := ((y2-miny) div 2)+miny;
   xa2 := -1;
   ya2 := +1;
   for i := 1 to 1000 do begin { draw }

      li := 1; { reset index }
      { draw }
      linesav(screen, x1, y1, x2, y2, c, lines, li);
      li := 1; { reset index }
      { remove }
      linerst(screen, x1, y1, x2, y2, lines, li);
      { set new directions }
      if (x1 = minx) or (x1 = maxx) then xa1 := -xa1;
      if (y1 = miny) or (y1 = maxy) then ya1 := -ya1;
      if (x2 = minx) or (x2 = maxx) then xa2 := -xa2;
      if (y2 = miny) or (y2 = maxy) then ya2 := -ya2;
      x1 := x1+xa1; { move to next location }
      y1 := y1+ya1;
      x2 := x2+xa2;
      y2 := y2+ya2;
      if i mod 100 = 0 then { change colors }
         if c <> white then c := succ(c)
         else c := black

   end;
   timssr := elapsed(time); { set time }

   { *** Test blocks *** }

   { full screen blocks, also gives a chance to check
     color purity/noise problems }

   time := gettim; { start timing }
   for i := 1 to 6 do
      for c := black to white do
         block(screen, minx, miny, maxx, maxy, c);
   timfbk := elapsed(time); { set time }

   { descending blocks }

   time := gettim; { start timing }
   for i := 1 to 6 do begin

      c := white; { set starting color }
      x1 := minx;
      y1 := miny;
      x2 := maxx;
      y2 := maxy;
      while (x1 < x2) and (y1 < y2) do begin

         block(screen, x1, y1, x2, y2, c); { draw }
         x1 := x1+10; { advance }
         y1 := y1+10;
         x2 := x2-10;
         y2 := y2-10;
         if c <> white then c := succ(c)
         else c := black

      end

   end;
   timdbk := elapsed(time); { set time }

   { test "string" blocks }
   
   c := black; { set starting color }
   block(screen, minx, miny, maxx, maxy, white);
   time := gettim; { start timing }
   x1 := ((maxx-minx) div 2)+minx;
   y1 := ((maxy-miny) div 2)+miny;
   xa1 := +1;
   ya1 := -1; 
   x2 := ((maxx-minx) div 2)+minx;
   y2 := ((maxy-miny) div 2)+miny;
   x2 := ((x2-minx) div 2)+minx;
   y2 := ((y2-miny) div 2)+miny;
   xa2 := -1;
   ya2 := +1;
   for i := 1 to 400 do begin { draw }

      block(screen, x1, y1, x2, y2, c);
      { set new directions }
      if (x1 = minx) or (x1 = maxx) then xa1 := -xa1;
      if (y1 = miny) or (y1 = maxy) then ya1 := -ya1;
      if (x2 = minx) or (x2 = maxx) then xa2 := -xa2;
      if (y2 = miny) or (y2 = maxy) then ya2 := -ya2;
      x1 := x1+xa1; { move to next location }
      y1 := y1+ya1;
      x2 := x2+xa2;
      y2 := y2+ya2;
      { change colors }
      if c <> white then c := succ(c)
      else c := black

   end;
   timsbk := elapsed(time); { set time }

   { *** test characters *** }

   for i := 1 to 10 do begin

      block(screen, minx, miny, maxx, maxy, white);
      { lay down graph paper }
      x := minx;
      while x <= maxx do begin

         line(screen, x, miny, x, maxy, lcyan);
         x := x + 4;

      end;
      y := miny;
      while y <= maxy do begin

         line(screen, minx, y, maxx, y, lcyan);
         y := y + 4;

      end;
      time := gettim; { start timing }
      c := black; { set starting color }
      ch := chr(0); { set 1st character }
      x := minx+5; { establish top left margined }
      y := miny+5;
      while y < maxy-5-23 do begin { rows }
       
         while x < maxx-5-23 do begin { collumns }

            setchr(screen, x, y, ch, c); { draw character }
            ch1 := ch; { find normalized character }
            if ord(ch1) > 127 then ch1 := chr(ord(ch1)-128);
            x := x+alphal[ord(ch1)]+1; { next collumn }
            { next character }
            if ch <> chr(255) then ch := succ(ch)
            else begin { next character sequence }

               ch := chr(0);
               { next color }
               if c <> white then c := succ(c)
               else c := black

            end
      
         end;
         x := minx+5; { reset x }
         y := y+19 { next y }

      end;
      timchr := timchr+elapsed(time); { set time }

   end;

   { restore standard video mode }
   resscn;

   writeln('Graphics test for MOORE/ICD vs. 1.0');
   writeln;
   write('Display adapter type: ');
   for i := 1 to labmax do if ds[i] <> ' 'then write(ds[i]);
   writeln(' demensions: ', minx:1, ',', miny:1, '-', 
           maxx:1, ',', maxy:1);
   writeln;
   writeln('Time of direct pixel access:       ', 
           timpix*0.01:8:2, ' sec. SI: %',
           (refpix*100)/(timpix*0.01):5:1);
   writeln('Time of line fill (top to bottom): ', 
           timlft*0.01:8:2, ' sec. SI: %',
           (reflft*100)/(timlft*0.01):5:1);
   writeln('Time of line fill (left to right): ', 
           timlfl*0.01:8:2, ' sec. SI: %',
           (reflfl*100)/(timlfl*0.01):5:1);
   writeln('Time of sunburst:                  ', 
           timsun*0.01:8:2, ' sec. SI: %',
           (refsun*100)/(timsun*0.01):5:1);
   writeln('Time of string lines:              ', 
           timstr*0.01:8:2, ' sec. SI: %',
           (refstr*100)/(timstr*0.01):5:1);
   writeln('Time of string line save/restores: ', 
           timssr*0.01:8:2, ' sec. SI: %',
           (refssr*100)/(timssr*0.01):5:1);
   writeln('Time of full screen blocks:        ', 
           timfbk*0.01:8:2, ' sec. SI: %',
           (reffbk*100)/(timfbk*0.01):5:1);
   writeln('Time of decending blocks:          ', 
           timdbk*0.01:8:2, ' sec. SI: %',
           (refdbk*100)/(timdbk*0.01):5:1);
   writeln('Time of string blocks:             ', 
           timsbk*0.01:8:2, ' sec. SI: %',
           (refsbk*100)/(timsbk*0.01):5:1);
   writeln('Time of character placement:       ', 
           timchr*0.01:8:2, ' sec. SI: %',
           (refchr*100)/(timchr*0.01):5:1);
   { find total time }
   time := timpix+timlft+timlfl+timsun+timstr+
           timssr+timfbk+timdbk+timsbk+timchr;
   writeln('Time total:                        ', 
           time*0.01:8:2, ' sec. SI: %',
           (refall*100)/(time*0.01):5:1);
   writeln;
   writeln('Speed indexes (SI) percentages are based on the ');
   writeln('time for a 16mhz 386sx with a Western Digital ');
   writeln('PVGA at 1024x768x16 (the minimum hardware ');
   writeln('requirement to run ICD).');

   99: { exit program }

end.

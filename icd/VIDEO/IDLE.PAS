{**************************************************************
*                                                             *
* SCREEN IDLE PROGRAM                                         *
*                                                             *
**************************************************************}

program idle;

label 99; { terminate program }

const
      maxint = 2147483647; { redefine for 32 bits }

      labmax = 20;  { number of character in label }

type
     integer = longint; { redefine integers for 32 bits }
     real    = double; { redefine reals for 64 bits }

     labinx = 1..labmax; { index for label }
     labtyp = packed array [labinx] of char; { label }
     color  = (black, blue, green, cyan, red, magenta, brown,
               dwhite, gray, lblue, lgreen, lcyan, lred, lmagenta,
               yellow, white);

var
    ds:       labtyp; { video device }
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

{ initialize display hardware }
procedure iniscn(var maxx, maxy: integer; var s: labtyp); cexternal; 
procedure resscn; cexternal; { restore display hardware }
function getpix(x, y: integer): color; cexternal; { get pixel value }
procedure setpix(x, y: integer; c: color); cexternal; { set pixel value }
{ draw block }
procedure block(x1, y1, x2, y2: integer; c: color); external;
{ draw line }
procedure line(x1, y1, x2, y2: integer; c: color); external; { draw line }
function kbdrdy: boolean; cexternal; { check keyboard character ready }
function kbdinp: char; cexternal; { get keyboard character }

{ draw box }

procedure box(x1, y1, x2, y2: integer; c: color);

begin

   line(x1, y1, x2, y1, c); { top }
   line(x1, y2, x2, y2, c); { bottom }
   line(x1, y1, x1, y2, c); { left }
   line(x2, y1, x2, y2, c)  { bottom }

end;

procedure strline(m: integer; t: boolean; erase: boolean; qm: integer);

label 1;

var i:  integer;
    sa: array [1..100] of record { coordinate save array }

      sx, sy, ex, ey: integer

    end;
    ep, xp: 1..100; { entry/exit pointers }
    qc: 1..100; { queue counter }
    ch: char;

begin

   c := black; { set starting color }
   block(minx, miny, maxx, maxy, white);
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
   ep := 1; { set 1st entry }
   xp := 1;
   qc := 0; { set number of entries }
   for i := 1 to 20000 do begin { draw }

      if kbdrdy then begin { terminate }

         ch := kbdinp; { get character }
         if ord(ch) = 13 then begin

            resscn;
            goto 99

         end else if ch = ' ' then goto 1

      end;
      if i mod m = 0 then begin

         if t then line(x1, y1, x2, y2, c)
         else box(x1, y1, x2, y2, c);
         sa[ep].sx := x1; { save coordinates }
         sa[ep].sy := y1;
         sa[ep].ex := x2;
         sa[ep].ey := y2;
         if ep = 100 then ep := 1 else ep := ep + 1; { next }
         qc := qc + 1; { count entry }
         if (qc = qm) and erase then begin { at maximum number of entries }

            { erase old line }
            if t then 
               line(sa[xp].sx, sa[xp].sy, sa[xp].ex, sa[xp].ey, white)
            else
               box(sa[xp].sx, sa[xp].sy, sa[xp].ex, sa[xp].ey, white);
            if xp = 100 then xp := 1 else xp := xp + 1; { next }
            qc := qc - 1 { count exit }

         end

      end;
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

   1: { stop pattern }

end;
{}
begin

   ds := 'OTI1280X1024X16     '; { initalize video device }
   iniscn(maxx, maxy, ds);
   if maxx = 0 then begin { device not found/bad }

      writeln('*** Unable to initalize video device');
      goto 99

   end;
   minx := 0; { clear mins }
   miny := 0;
   { clear screen to white }
   block(minx, miny, maxx, maxy, white);

   while true do begin 

      strline(1, true, false, 0);
      strline(1, false, false, 0);
      strline(4, true, false, 0);
      strline(4, false,false, 0);
      strline(1, true, true, 100);
      strline(1, false, true, 100);
      strline(4, true, true, 100);
      strline(4, false,true, 100)

   end;

   resscn; { reset video }
   
   99: { exit program }

end.

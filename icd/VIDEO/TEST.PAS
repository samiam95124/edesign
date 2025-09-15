{**************************************************************
*                                                             *
* VIDEO ROUTINES PACKAGE TEST PROGRAM                         *
*                                                             *
**************************************************************}

program test;

uses {$U ..\common.j} common;

label 99;

var ds:       labtyp;
    vp, vp2:  viewport;
    x1, y1, 
    x2, y2:   integer;
    xa1, ya1, 
    xa2, ya2: integer;
    x, y:     integer;
    c:        color;
    i:        integer;
    li:       lininx;
    ch, ch1:  char;

procedure inialpha; external; { initalize character matrix }
procedure iniwidth; external; { initalize character width table }
{ initialize display hardware }
procedure iniscn(var maxx, maxy: integer; var s: labtyp); cexternal; 
procedure resscn; cexternal; { restore display hardware }
function getpix(vp: viewport; x, y: integer): color; cexternal; { get pixel value }
procedure setpix(vp: viewport; x, y: integer; c: color); cexternal; { set pixel value }
{ draw block }
procedure block(vp: viewport; x1, y1, x2, y2: integer; c: color); external;
{ draw line }
procedure line(vp: viewport; x1, y1, x2, y2: integer; c: color); external; { draw line }
procedure linesav(vp: viewport; x1, y1, x2, y2: integer; c: color; var lines: linarr; 
                  var i: lininx); external; { draw line w/ save }
procedure linerst(vp: viewport; x1, y1, x2, y2: integer; var lines: linarr; 
                  var i: lininx); external; { restore buffered line }
{ draw character onscreen }
procedure setchr(vp: viewport; x, y: integer; ch: char; cl: color); external;

{ move viewport to new location }

procedure moveport(var vp: viewport; x, y: integer);

begin

   vp.v.e.x := vp.v.e.x-vp.v.s.x+x;
   vp.v.s.x := x;
   vp.v.e.y := vp.v.e.y-vp.v.s.y+y;
   vp.v.s.y := y

end;

begin

   inialpha; { initalize character matrix }
   iniwidth; { initalize character width table }
   ds := 'VGA640X480X16       ';
   iniscn(maxx, maxy, ds); { initalize video device }
   minx := 0;
   miny := 0;
   if maxx = 0 then begin { device not found/bad }

      writeln('*** Unable to initalize video device');
      goto 99

   end;
   { set up whole screen viewport }
   vp.v.s.x := minx;
   vp.v.s.y := miny;
   vp.v.e.x := maxx;
   vp.v.e.y := maxy;
   vp.r := vp.v;
   vp.s.x := 1; { no scaling }
   vp.s.y := 1;
   vp.m.x := 1;
   vp.m.y := 1;
   vp.c := vp.v; { set clip to whole screen }

   block(vp, vp.r.s.x, vp.r.s.y, vp.r.e.x, vp.r.e.y, white);

   ch := chr(0); { set 1st character }
   x := vp.r.s.x+5; { establish top left margined }
   y := vp.r.s.y+5;
   while y < vp.r.e.y-5-23 do begin { rows }
    
      while x < vp.r.e.x-5-23 do begin { collumns }

         setchr(vp, x, y, ch, lgreen); { draw character }
         ch1 := ch; { find normalized character }
         if ord(ch1) > 127 then ch1 := chr(ord(ch1)-128);
         x := x+alphal[ord(ch1)]+1; { next collumn }
         { next character }
         if ch <> chr(255) then ch := succ(ch)
         else ch := chr(0)
   
      end;
      x := vp.r.s.x+5; { reset x }
      y := y+19 { next y }

   end;

   vp.c.s.x := vp.c.s.x + 50;
   vp.c.s.y := vp.c.s.y + 50;
   vp.c.e.x := vp.c.e.x - 50;
   vp.c.e.y := vp.c.e.y - 50;

   block(vp, vp.r.s.x, vp.r.s.y, vp.r.e.x, vp.r.e.y, lcyan);
   ch := chr(0); { set 1st character }
   x := vp.r.s.x+5; { establish top left margined }
   y := vp.r.s.y+5;
   while y < vp.r.e.y-5-23 do begin { rows }
    
      while x < vp.r.e.x-5-23 do begin { collumns }

         setchr(vp, x, y, ch, black); { draw character }
         ch1 := ch; { find normalized character }
         if ord(ch1) > 127 then ch1 := chr(ord(ch1)-128);
         x := x+alphal[ord(ch1)]+1; { next collumn }
         { next character }
         if ch <> chr(255) then ch := succ(ch)
         else ch := chr(0)
   
      end;
      x := vp.r.s.x+5; { reset x }
      y := y+19 { next y }

   end;


   99: 

end.

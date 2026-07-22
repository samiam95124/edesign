{**************************************************************

VIDEO MODE TEST

Tests if the pixel read/write routines work in all resolutions
(not all cards implement them for all modes). Must be customized
per the card.

**************************************************************}

program test;

{$i ..\define}

var irs: intregspec; { dos call record }

procedure setpix(x, y: word; c: color);

begin

   irs.ah := 0ch;
   irs.al := ord(c);
   irs.cx := x;
   irs.dx := y;
   syscall(16, irs);

end;

procedure box(xs, ys, xe, ye: word; c: color);

var x, y: word;

begin

   for x := xs to xe do setpix(x,  ys, c);
   for x := xs to xe do setpix(x,  ye, c);
   for y := ys to ye do setpix(xs, y,  c);
   for y := ys to ye do setpix(xe, y,  c)

end;

procedure testmod(m: integer; xm, ym: word);

var i: word;
    c: color;
    xs, ys, xe, ye: word;
    sp: word;
    ch: char;

begin

   irs.ah := 00;
   irs.al := m;
   syscall(16, irs);
   sp := (ym div 2) div 16;
   c := white;
   xs := 0;
   ys := 0;
   xe := xm-1;
   ye := ym-1;
   for i := 1 to 15 do begin

      box(xs, ys, xe, ye, c);
      xs := xs + sp;
      ys := ys + sp;
      xe := xe - sp;
      ye := ye - sp;
      c := pred(c)

   end;
   while not cstat do;
   ch := consilent

end;

begin

{   testmod(0dh, 320, 200); 
   testmod(0eh, 640, 200);
   testmod(10h, 640, 350);}
   testmod(12h, 640, 480); 
{   testmod(25h, 640, 480);}
   testmod(29h, 800, 600);
   irs.ah := 00;
   irs.al := 54h;
   syscall(16, irs);

end.


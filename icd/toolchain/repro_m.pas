module repro_m(output);

type point = record x, y: integer end;
     region = record s, e: point end;
     viewport = record

                   v: region;
                   r: region;
                   s: point;
                   m: point;
                   c: region

                end;

var maxx, maxy, minx, miny: integer;
    screen: viewport;

procedure showscreen;

begin

   writeln('module sees: v.s=', screen.v.s.x:1, ',', screen.v.s.y:1,
           ' v.e=', screen.v.e.x:1, ',', screen.v.e.y:1,
           ' s=', screen.s.x:1, ',', screen.s.y:1)

end;

procedure setscreen;

begin

   screen.v.s.x := 11;
   screen.v.s.y := 12;
   screen.v.e.x := 13;
   screen.v.e.y := 14;
   screen.s.x := 15;
   screen.s.y := 16

end;

procedure setmaxs;

begin

   maxx := 1280;
   maxy := 825;
   minx := 1;
   miny := 1

end;

begin { constructor }

end;

begin { destructor }

end.

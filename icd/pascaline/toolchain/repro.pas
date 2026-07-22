program repro(output);

uses repro_m,
     repro_m2;

begin

   setmaxs;
   writeln('program sees: maxx=', maxx:1, ' maxy=', maxy:1,
           ' minx=', minx:1, ' miny=', miny:1);
   screen.v.s.x := minx;
   screen.v.s.y := miny;
   screen.v.e.x := maxx;
   screen.v.e.y := maxy;
   screen.s.x := 1;
   screen.s.y := 1;
   writeln('program sees: v.s=', screen.v.s.x:1, ',', screen.v.s.y:1,
           ' v.e=', screen.v.e.x:1, ',', screen.v.e.y:1,
           ' s=', screen.s.x:1, ',', screen.s.y:1);
   showscreen;
   setscreen; { now assign module-side }
   showscreen;
   writeln('program sees after module set: v.s=',
           screen.v.s.x:1, ',', screen.v.s.y:1,
           ' v.e=', screen.v.e.x:1, ',', screen.v.e.y:1,
           ' s=', screen.s.x:1, ',', screen.s.y:1);
   setscreen2; { assign from a sibling module }
   showscreen

end.

{**************************************************************

Test for Summagrphics II tablet

**************************************************************}

program test;

{$i c:\propas\doslib}

const maxx    = 1023;  { demensions of standard screen }
      maxy    = 767;
      tabmaxx = 5850; { maximum count in x }
      tabmaxy = 5850; { maximum count in y }

var pr, but1, but2, but3, but4: boolean;
    tpx, tpy: integer;
    i: integer;

procedure iniprt;

var irs: intregspec; { dos call record }

begin

   irs.ah := 00; { initalize communications port }
   irs.dx := 0;
   irs.al := 0ebh; { 9600 baud, 8, n, 1 }
   syscall(20, irs) { execute }

end;

function getaux: byte;

var irs: intregspec; { dos call record }

begin

   irs.ah := 02; 
   irs.dx := 0;
   syscall(20, irs); { execute }
   getaux := irs.al { return result }

end;

procedure putaux(b: byte);

var irs: intregspec; { dos call record }

begin

   irs.ah := 01; 
   irs.dx := 0;
   irs.al := b;
   syscall(20, irs) { execute }

end;

procedure readtab;

var report: array [1..5] of byte;
    i: 1..5;

begin

   putaux(ord('P')); 
   for i := 1 to 5 do report[i] := getaux;
   pr := (report[1] and 040h) <> 0;
   but1 := (report[1] and 007h) = 1;
   but2 := (report[1] and 007h) = 2;
   but3 := (report[1] and 007h) = 3;
   but4 := (report[1] and 007h) = 4;
   tpx := report[2] or (report[3] * 128);
   tpy := report[4] or (report[5] * 128);
   tpy := tabmaxy - tpy; { flip y }
   tpx := tpx*(maxx+1) div tabmaxx; { scale to screen }
   tpy := tpy*(maxx+1) div tabmaxx;
   if tpx > maxx then tpx := maxx; { limit to screen }
   if tpy > maxy then tpy := maxy

end;

begin

   iniprt; { initalize tablet port }
   putaux(0); { send initalize command }
   for i := 1 to 10000 do;
   putaux(0); { repeat for insurance }
   for i := 1 to 10000 do;
   putaux(0);
   for i := 1 to 10000 do;
   putaux(ord('D')); { set report on demand mode }
   for i := 1 to 10000 do;
   putaux(ord('z')); { set binary report mode }
   for i := 1 to 10000 do;
   putaux(ord('b'));
   for i := 1 to 10000 do;

   while true do begin 

      gotoxy(1, 1);
      writeln('Report');
      readtab;
      writeln(pr, but1, but2, but3, but4, tpx, tpy)

   end
      
end.   


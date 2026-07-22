program icd;

uses {$U common.j} common;

label 88, 99; { terminate program }

const maxlin = 200; { command line maximum length }

type inxlin = 0..maxlin; { index for line }

var i:      btsinx;
    x, y:   integer;
    vi:     viewinx;
    si:     sizeinx;
    tci:    color;
    bi:     blkinx;
    pin:    prtinx;
    li:     laytyp;
    tim:    integer;
    ds:     labtyp; { driver select label }
    ms:     labtyp; { positioner select label }
    ps:     labtyp; { printer select label }
    cmdlin: packed array [inxlin] of char; { command line }
    cmdptr: inxlin;  { command line index }

procedure inialpha; external; { initalize character matrix }
procedure iniwidth; external; { initalize character width table }
procedure inibut; external; { initalize button array }
{ initialize display hardware }
procedure iniscn(var maxx, maxy: integer; var s: labtyp); cexternal; 
{ initalize printer hardware }
procedure iniprt(var ptrmax: rpoint; var ptrdpm: real;
                 var pmax: point; var ptrdl: byte); external;
procedure resscn; cexternal; { restore display hardware }
procedure iniptr(var s: labtyp); external; { initialize pointer hardware }
procedure command; external; { execute schematic commands }
procedure dispwin; external; { display current window }
procedure intro; external; { present introduction }
procedure updptr; external; { update pointer device }
function kbdrdy: boolean; cexternal; { check keyboard character ready }
function gettim: integer; cexternal; { get current system time }
{ find elapsed time }
function elapsed(t: integer): integer; external;
procedure wait(t: integer); external; { wait time }
{ draw block }
procedure block(vp: viewport; x1, y1, x2, y2: integer; c: color); external;
{ place child window }
procedure plcwin(master, child: viewport; 
                 x1, y1, x2, y2: integer); external;
{}
{**************************************************************

ABORT PROGRAM

Aborts the entire ICD package. This is used for system errors
only.

**************************************************************}

procedure abort;

begin

   goto 88

end;
{}
{**************************************************************

PROCESS INITALIZATION ERROR

Resets the screen and outputs an initalization error.
This is used where an error in devices or other critical 
configuration errors occurs.

**************************************************************}

procedure deverr(e: devcod);

begin

   if e <> devid then resscn; { reset screen mode }
   write('*** ');
   case e of

      deptr: write('Unable to initalize pointer device');
      devid: write('Unable to initalize display device');
      delab: write('Parameter label too long');

   end;
   writeln(' ***');
   writeln('*** Unable to initalize ICD: procedure aborted ***');
   wait(detime); { hold to allow message read (windows) }
   goto 99

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

      if i > labmax then deverr(delab); { error }
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
   inibut; { initalize button array }
   getcml; { get command line }
   getword(ds); { get driver select string }
   getword(ms); { get positioner select string }
   getword(ps); { get printer select string }
   button[bdots].act := true; { set show grid }
   button[blines].act := true; { set show lines grid }
   button[bschema].act := true; { set schematic mode active }
   curscm := [smschema]; { set screen mode as schematic }
{   button[b90].act := true; { set 90 deg line active }
;button[bany].act := true;
   button[bwire].act := true; { set wire mode }
{   button[bsnap].act := true; { set snap active }
;button[bsnap].act := false;
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
   { set print parameters }
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
   bakclr := {dwhite}lgreen; { set windows backround color }
   bakshw := {gray}green; { set windows backrond shadow }
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
   iniscn(maxx, maxy, ds); { initalize video device }
   if maxx = 0 then deverr(devid); { device not found/bad }
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
   iniptr(ms); { initalize pointer device }
   iniprt(ptrmax, ptrdpm, pmax, ptrdl); { initalize printer }
   cur.x := ((maxx - minx) div 2)+minx; { reset cursor coordinates }
   cur.y := ((maxy - miny) div 2)+miny; { to middle of screen }
   { establish initial cell }
   new(cellst); { establish inital cell }
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
   curwin^.sc := cyan{gray}; { set shadow color }
   curwin^.bc := lcyan{dwhite}; { set backround color }
   block(screen, minx, miny, maxx, maxy, bakclr); { clear screen }
   { show sign-on screen }
   intro;
   tim := gettim; { get current time }
   updptr; { update puck status }
   while not kbdrdy and (elapsed(tim) < introt) and 
         not (puck.b[1].s or puck.b[2].s or
              puck.b[3].s or puck.b[4].s) do
      updptr; { update puck status }
   block(screen, minx, miny, maxx, maxy, bakclr); { clear screen to white }
   dispwin; { display window }
   command; { execute schematic commands }

   88: { exit program }

   { restore standard video mode }
   resscn;

   99: { exit program }

end.

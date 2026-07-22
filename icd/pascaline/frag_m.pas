{******************************************************************************

PROGRAM INITIALIZATION AND EVENT ENTRIES

This section owns all writes to the module globals. The program module
must not write them directly: stores to record fields of imported module
globals are miscompiled by the current Pascal-P6 code generator (see
PORTING-SPEC.md, toolchain notes), and in any case the initialization
belongs with the data. The main program calls iniicd once, then feeds
events through the ev* entries below.

The initialization follows the original icd.pas (1992) main body, minus
the hardware device selection (video driver label, tablet, printer).

******************************************************************************}

{ initialize the ICD user interface }

procedure iniicd;

var li:  laytyp;  { layer index }
    tci: color;   { color index }
    bi:  blkinx;  { block index }
    pin: prtinx;  { printer save index }
    bn:  integer; { mouse button number }

begin

   initscreen; { initialize display via graphics library }
   inibut; { initalize button array }
   button[bdots].act := true; { set show grid }
   button[blines].act := true; { set show lines grid }
   button[bschema].act := true; { set schematic mode active }
   curscm := [smschema]; { set screen mode as schematic }
   button[bany].act := true;
   button[bwire].act := true; { set wire mode }
   button[bsnap].act := false;
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
   bakclr := lgreen; { set windows backround color }
   bakshw := green; { set windows backrond shadow }
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
   { set up whole screen viewport }
   screen.v.s.x := minx;
   screen.v.s.y := miny;
   screen.v.e.x := maxx;
   screen.v.e.y := maxy;
   screen.r := screen.v;
   { port: was 1 in the (mid-refactor) originals; the real-coordinate
     converter viewc scales by scalem/s and the draw transform viewx by
     m/s, so an identity window viewport needs s = m = scalem for the
     two conventions to agree }
   screen.s.x := scalem; { no scaling }
   screen.s.y := scalem;
   screen.m.x := scalem;
   screen.m.y := scalem;
   screen.c := screen.v; { set clip to whole screen }
   cur.x := ((maxx-minx) div 2)+minx; { reset cursor coordinates }
   cur.y := ((maxy-miny) div 2)+miny; { to middle of screen }
   { clear puck emulation state }
   for bn := 1 to 4 do begin

      puck.b[bn].s := false;
      puck.b[bn].l := false;
      puck.b[bn].a := false;
      puck.b[bn].d := false;
      puck.b[bn].dg := false

   end;
   puck.m := false;
   puck.v := true; { mouse is always valid }
   { establish initial cell }
   new(cellst);
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
   curwin^.sc := cyan; { set shadow color }
   curwin^.bc := lcyan; { set backround color }
   iniprt; { port: initialize printer parameters (icde layer) }
   block(screen, minx, miny, maxx, maxy, bakclr); { clear screen }
   dispwin { display window }

end;

{ mouse movement event. Emulates the puck movement state the tablet
  driver produced, then tracks the cursor }

procedure evmove(x, y: integer);

begin

   puck.ol := puck.cl;
   puck.cl.x := x;
   puck.cl.y := y;
   puck.m := true; { set movement flag }
   movcur(x, y); { track cursor }
   dispatch { port: run the command dispatch (was the command loop body) }

end;

{ mouse button event. press is true for assert, false for deassert.
  Emulates the puck button communication flags }

procedure evbut(bn: integer; press: boolean);

begin

   if bn in [1..4] then begin

      puck.b[bn].s := press;
      if press then begin

         puck.b[bn].a := true; { set assertion CMF }
         puck.b[bn].ap := cur { record assertion location }

      end else begin

         puck.b[bn].d := true; { set deassertion CMF }
         puck.b[bn].dp := cur { record deassertion location }

      end;
      chkbut; { check button actions }
      dispatch { port: run the command dispatch (was the command loop body) }

   end

end;

{ keyboard character event }

procedure evkey(c: char);

begin

   dokeyboard(c); { process keyboard command/entry character }
   dispatch { port: run the command dispatch (was the command loop body) }

end;

{ window redraw request event }

procedure evredraw;

begin

   block(screen, minx, miny, maxx, maxy, bakclr);
   dispwin

end;

{ window resize event }

procedure evresize;

begin

   scnmaxx := graphics.maxxg;
   scnmaxy := graphics.maxyg;
   maxx := scnmaxx;
   maxy := scnmaxy;
   screen.v.e.x := maxx;
   screen.v.e.y := maxy;
   screen.r := screen.v;
   screen.c := screen.v;
   plcwin(screen, curwin^.wv,
          screen.v.s.x, screen.v.s.y,
          screen.v.e.x, screen.v.e.y);
   block(screen, minx, miny, maxx, maxy, bakclr);
   dispwin

end;

{ terminate request event (window close) }

procedure evterm;

begin

   terminate := true

end;

{ check terminate requested }

function termreq: boolean;

begin

   { port: the original command loop also exited on the Exit button }
   termreq := terminate or button[bexit].act

end;

{******************************************************************************

FRAGMENT D: WINDOW MANAGEMENT AND VIEW NAVIGATION

Ported from icdc.pas. Contains the window layout engine, view
navigation (zoom/pan/ruler/bounds), grid drawing, sheet and cell
display control, and assorted math helpers.

Port notes:

1. Save-under logic (boxsav/boxrst) is replaced by xor rubber-banding
   per the conversion spec; the linarr/lininx save buffer parameters
   are deleted. boxrst gains the color parameter so it can redraw the
   identical figure in xor mode.
2. Obvious source damage in the original (missing '^.ds'/'^.ls' field
   selections in the grid routines, 'wp^.r' for 'wp^.wv.r', stray
   braces after dispose calls, 'curwin^.wv.cr' for 'curwin^.cr') is
   repaired mechanically; each repair is marked with a "port:" comment.
3. Figure rendering (drwfig/drwfigs) is deferred to a later phase and
   stubbed with "port: cell drawing deferred" comments.

******************************************************************************}

{ port: the var vp frame version that was here was a duplicate of the
  frame in the icdb layer and has been removed at integration }

{ box draw with save }
{ port: save-under replaced by xor rubber-banding; linarr index
  parameter deleted. The box is drawn in xor mode, and boxrst
  removes it by drawing the identical box in xor mode again }

procedure boxsav(x1, y1, x2, y2: integer; c: color);

begin

   xormode; { enter xor mode }
   { draw box outline, screen coordinates }
   scrline(x1, y1, x2, y1, c);
   scrline(x2, y1, x2, y2, c);
   scrline(x2, y2, x1, y2, c);
   scrline(x1, y2, x1, y1, c);
   ovrmode { return to overwrite mode }

end;
{}
{ box restore }
{ port: pixel restore replaced by identical xor redraw; linarr index
  parameter deleted, color parameter added (must match the boxsav
  draw color) }

procedure boxrst(x1, y1, x2, y2: integer; c: color);

begin

   xormode; { enter xor mode }
   { redraw identical box outline, screen coordinates }
   scrline(x1, y1, x2, y1, c);
   scrline(x2, y1, x2, y2, c);
   scrline(x2, y2, x1, y2, c);
   scrline(x1, y2, x1, y1, c);
   ovrmode { return to overwrite mode }

end;
{}
{**************************************************************

FIND TRUE DISTANCE

Finds the direct line distance between two points.

**************************************************************}

function dist(x1, y1, x2, y2: integer): integer;

var xr1, yr1, xr2, yr2: real; { precision holders }

begin

   xr1 := x1; { place parameters in holding }
   yr1 := y1;
   xr2 := x2;
   yr2 := y2;
   dist := round(sqrt(sqr(abs(xr2-xr1))+sqr(abs(yr2-yr1))))

end;
{}
{**************************************************************

FIND ANGLE OF VECTOR

Given a vector, gives the angle of incidence, considering the
first point as the center point.
The angle is clockwise, with 0 as up.

**************************************************************}

function angle(x1, y1, x2, y2: integer): real;

var a: real;

begin

   if y2 = y1 then a := pi/2 { 90 deg }
   else a := arctan(abs(x2-x1)/abs(y2-y1)); { find base angle }
   if x2 > x1 then begin { in right hand half }

      if y2 > y1 then a := pi - a { move to lower right hand quadrant }

   end else begin { in left hand half }

      if y2 > y1 then a := a + pi { move to lower left hand quadrant }
      else a := 2*pi - a { move to upper left hand quadrant }

   end;
   angle := a { return final angle }

end;
{}
{**************************************************************

FIND ANGULAR DIFFERENCE

Finds the shortest angular difference between the given
angles.

**************************************************************}

function angdif(a, b: real): real;

var t: real;
    s: integer;

begin

   s := 1; { set sign }
   { swap to lower }
   if a > b then begin t := a; a := b; b :=  t; s := -s end;
   if b > (a+pi) then b := b - 2*pi; { adjust upper }
   angdif := (b-a)*s { place result }

end;
{}
{**************************************************************

FIND CIRCLE CENTER

Given three points on a circle, will find the center of that
circle.
Note: unfortunately, I thought the answer to this one up
myself.

**************************************************************}

procedure center(x1, y1, x2, y2, x3, y3: integer; { the three points }
                 var xc, yc: integer); { the center }

var an, ana, anb: real;
    lna, lnb:     integer;
    c:            real;
    x, y:         real;

procedure vecend(xs, ys,            { starting point }
                 d:          real;  { distance }
                 an:         real;  { angle }
                 var xe, ye: real); { end point }

begin

   xe := xs + d * sin(an); { find x }
   ye := ys - d * cos(an) { find y }

end;

begin

   { find angles and lengths of vectors }
   ana := angle(x1, y1, x2, y2);
   anb := angle(x1, y1, x3, y3);
   lna := dist(x1, y1, x2, y2);
   lnb := dist(x1, y1, x3, y3);
   { find difference between vectors }
   an := abs(angdif(ana, anb));
   { check dead axial }
   if (an > pi/2-0.005) and (an < pi/2+0.005) then begin

      { determine crossing }
      vecend(x1, y1, lnb/2, anb, x, y);
      vecend(x, y, lna/2, ana, x, y);

   end else begin { do normal }

      c := (lnb/2)/cos(an); { find dist to 2nd intercept }
      vecend(x1, y1, c, ana, x, y); { find that point }
      { find distance from that to center }
      c := (lna/2 - c)/cos(pi/2-an);
      vecend(x, y, c, ana-(pi/2-an), x, y) { find center }

   end;
   xc := round(x); { return }
   yc := round(y)

end;
{}
{**************************************************************

CHECK BUTTON

Checks if the cursor overlays a button, and selects that if
so.

**************************************************************}

procedure chkbut;

var i: buttyp;

begin

   if not inbutton(curbut) or (curbut = bnull) then begin

      { not in the last select }
      curbut := bnull; { clear current button }
      for i := succ(bnull) to bdisplay do
         if inbutton(i) and (curscm * button[i].sm <> []) then
         { inside button and mode matches }
         curbut := i; { set button found }

   end

end;
{}
{**************************************************************

UPDATE CURSOR POSITION DISPLAY

Updates the cursor position display.

**************************************************************}

procedure updcps;

begin

   { update cursor position display }
   if inactive(cur) or intarget(cur) and puck.v and
      not (button[bdisplay].act or
           button[bcells].act or
           button[blibv].act or
           button[bliba].act or
           button[blibb].act or
           button[blibc].act or
           button[blibd].act) then begin

      { in active area, and not in a menu mode }
      realstr(rcur.x*pixsiz, button[bcposxv].s); { place value }
      realstr(rcur.y*pixsiz, button[bcposyv].s); { convert and output }
      if smsimulate in curscm then begin

         { simulate, also do time and voltage }
         realstr(rcur.x*timesiz, button[bctimev].s); { place value }
         realstr((trcsiz*voltsiz)-((rcur.y mod trcsiz)*voltsiz)-1.5,
                 button[bcvoltv].s) { convert and output }

      end

   end else begin { out of active area }

      button[bcposxv].s := '        '; { clear strings }
      button[bcposyv].s := '        ';
      button[bctimev].s := '        ';
      button[bcvoltv].s := '        '

   end;
   updbut(bcposxv); { update }
   updbut(bcposyv);
   updbut(bctimev);
   updbut(bcvoltv)

end;
{}
{**************************************************************

UPDATE RULER DISPLAY

Updates the ruler display. The ruler is active whenever the
ruler mode is active, or some other mode that can be measured
is active. These include line, wire, bus, box, and boldbox
placements, block saves, and zooms and pans.
The relivant x and y are gathered from the coordinates appropriate
to the mode and displayed.

**************************************************************}

procedure updrul;

var xd, yd: real;

begin

   if (drmbut in [bline, bbline, bwire, bbus, bbox, bbbox, bsaveb,
                  bmet1, bmet2, bpoly, bvia, bndiff, bpdiff,
                  bnwell, bpwell, bccut, bcont, bdwave, bawave]) or
      (vimbut in [bin, bpan, bruler]) then begin

      { ruler mode is active }
      if inactive(cur) then begin { in active area }

         if drmbut in [bline, bbline, bwire, bbus, bbox,
                       bbbox, bsaveb, bmet1, bmet2, bpoly,
                       bvia, bndiff, bpdiff, bnwell, bpwell,
                       bccut, bcont, bdwave, bawave] then begin

            { wire or line }
            xd := endp.x-str.x;
            yd := endp.y-str.y

         end else begin { ruler, zoom or pan }

            xd := rcur.x-rmrk.x;
            yd := rcur.y-rmrk.y

         end;
         realstr(sqrt(sqr(xd)+sqr(yd))*pixsiz, button[brulerv].s);
         realstr(abs(xd)*pixsiz, button[brulxv].s);
         realstr(abs(yd)*pixsiz, button[brulyv].s);
         if smsimulate in curscm then begin

            { simulate, also do time and voltage }
            realstr(abs(xd)*timesiz, button[brtimev].s); { place value }
            realstr(abs(yd)*voltsiz, button[brvoltv].s) { convert and output }

         end

      end else begin { out of active area }

         button[brulerv].s := '        '; { clear strings }
         button[brulxv].s := '        ';
         button[brulyv].s := '        ';
         button[brtimev].s := '        ';
         button[brvoltv].s := '        '

      end;
      if not cntdrw then begin

         updbut(brulerv); { update }
         updbut(brulxv);
         updbut(brulyv);
         updbut(brtimev);
         updbut(brvoltv)

      end

   end

end;
{}
{**************************************************************

MOVE CURSOR

Moves the cursor to a new location.
The cursor is removed from the present position, and replaced
at the new position.
Any "in progress" drawn shape is also removed and replaced.

**************************************************************}

procedure movcur(newx, newy: integer); { move cursor }

{ port: line save index variable deleted (save-under removed) }
var t:      integer;
    s:      butstr;
    dx, dy: integer;

begin

   dx := newx-cur.x; { find movement deltas }
   dy := newy-cur.y;
   if inactive(cur) or intarget(cur) then begin { in active area }

      { reset cursor if any "mobile" onscreen }
      if zbxdwn or lindwn or boxdwn or cirdwn or arcdwn then rescur;
      reszoom; { reset all onscreens }
      resline;
      resbox;
      rescircle;
      resarc;

   end;
   cur.x := newx; { place new coordinates }
   cur.y := newy;
   chkbut; { check button select }
   if inactive(cur) or intarget(cur) then begin

      { in active or target area }
      rcur := cur; { find real cursor position }
      if inactive(cur) then
         realc(rcur, curwin^.cs^.vp) { convert coordinates }
      else realc(rcur, targvp);
      if (vimbut in [bin, bout]) and
         ((inactive(cur) and inactive(mrk)) or
          (intarget(cur) and intarget(mrk))) then begin

         rescur; { remove cursor }
         setasp; { set aspect box }
         setzoom { set zoom box }

      end;
      if inactive(cur) then begin { in active }

         if not button[bpan].act and not button[bin].act and
            not button[bout].act and not button[bruler].act then begin

            if drmbut in [bline, bbline, bwire, bbus, bdwave,
                          bawave] then begin

               { place line }
               rescur; { remove cursor }
               setend; { set new end coordinates }
               setline { place line }

            end else if drmbut in [bbox, bbbox, bsaveb, bmet1,
                                   bmet2, bpoly, bvia, bndiff,
                                   bpdiff, bnwell, bpwell,
                                   bccut, bcont] then begin

               { place box }
               rescur; { remove cursor }
               endp := cur; { set new end coordinates }
               realc(endp, curwin^.cs^.vp); { convert coordinates }
               snapto(endp.x, endp.y);
               setbox { place box }

            end else if drmbut = bpasteb then begin { place paste box }

               rescur; { remove cursor }
               str := rcur; { set start of box }
               snapto(str.x, str.y); { snap }
               endp.x := str.x + (savb.e.x - savb.s.x); { set end of box }
               endp.y := str.y + (savb.e.y - savb.s.y);
               setbox { place box }

            end else if drmbut in [bplsch, bplsym, bplace] then begin

               { display placement box }
               rescur; { remove cursor }
               str := rcur; { set start of box }
               snapto(str.x, str.y); { snap }
               { set end of box }
               endp.x := str.x+plcsiz.x;
               endp.y := str.y+plcsiz.y;
               setbox { place box }

            end else if drmbut = bcircle then begin { place circle }

               rescur; { remove cursor }
               str := cur; { make sure end is established }
               realc(str, curwin^.cs^.vp); { convert coordinates }
               { find radius }
               rad := dist(cen.x, cen.y, str.x, str.y);
               str.x := cen.x; { project to x axis }
               str.y := cen.y + rad;
               snapto(str.x, str.y);
               { recalculate radius }
               rad := abs(str.y-cen.y);
               setcircle { place circle }

            end else if (drmbut = barc) and not arcsph then begin

               { place 1st phase arc }
               rescur; { remove cursor }
               endp := cur; { set end }
               realc(endp, curwin^.cs^.vp); { convert coordinates }
               snapto(endp.x, endp.y);
               setline { place flat arc(line) }

            end else if (drmbut = barc) and arcsph then begin

               { place 2nd phase arc }
               rescur; { remove cursor }
               { check which "hand: the cursor is on, and
                 reverse the draw direction as required }
               if angdif(angle(str.x, str.y, endp.x, endp.y),
                  angle(str.x, str.y, rcur.x, rcur.y)) < 0 then begin

                  { swap end and start }
                  t := str.x; str.x := endp.x; endp.x := t;
                  t := str.y; str.y := endp.y; endp.y := t

               end;
               { check points are colinear or nearly so. In this case,
                 the circle calculation climbs to infinity. We substitue
                 a line instead. }
               if (abs(angdif(angle(str.x, str.y, rcur.x, rcur.y),
                   angle(str.x, str.y, endp.x, endp.y))) > pi/50) and
                   (abs(angdif(angle(str.x, str.y, rcur.x, rcur.y),
                   angle(endp.x, endp.y, str.x, str.y))) > pi/10) and
                   (abs(angdif(angle(endp.x, endp.y, rcur.x, rcur.y),
                   angle(str.x, str.y, endp.x, endp.y))) > pi/10) then begin

                  { set the center }
                  center(str.x, str.y, endp.x, endp.y, rcur.x, rcur.y, cen.x, cen.y);
                  rad := dist(cen.x, cen.y, str.x, str.y); { find radius }
                  setarc; { place arc }
                  arcflat := false { set arc not flat }

               end else begin

                  setline; { substitue line }
                  arcflat := true { set arc is flat }

               end

            end

         end

      end

   end;
   updcps; { update cursor position display }
   updrul; { update ruler display }
   rescur; { ensure cursor is up }
   setcur { replace cursor }

end;
{}
{**************************************************************

CANCEL CURRENT ACTIVITIES

Resets indicators and markers from the screen, and cancels
active modes.

**************************************************************}

procedure canact;

begin

   rescur; { lift cursor }
   { reset any onscreen cursor }
   reszoom; { reset zoom box }
   resmrk; { reset marker }
   resrlm; { reset ruler mark }
   resline; { reset line cursor }
   resbox; { reset box cursor }
   rescircle; { reset circle cursor }
   resarc; { reset arc cursor }
   restcur; { reset text cursor }
   setcur; { drop cursor }
   { negate in process modes }
   modbut := bnull;
   drmbut := bnull;
   dsmbut := bnull;
   vimbut := bnull;
   { cancel in-progress edits }
   if cedbut <> bnull then begin

      button[cedbut].s := butsav; { restore from save }
      { update screen }
      updbut(cedbut) { update }

   end;
   if errmsg then plcmsg(mnone, yellow); { clear error message }
   if smprint in curscm then printstop { clear printer pop-up }

end;
{}
{**************************************************************

DEACTIVATE CURRENT ACTIVITIES

Resets all activity buttons, and resets indicators and markers
from the screen.

**************************************************************}

procedure stopact;

var ci: color; { index for trace colors }
    p:  drwptr; { figure pointer }

begin

   butina(bline); { deactivate all these buttons }
   butina(bbox);
   butina(bbline);
   butina(bbbox);
   butina(bcircle);
   butina(barc);
   butina(bwire);
   butina(bbus);
   butina(bjunction);
   butina(bconnect);
   butina(bsaveb);
   butina(bcutb);
   butina(bpasteb);
   butina(bdelete);
   butina(bdeleten);
   butina(btrace);
   butina(btext);
   butina(bplsym);
   butina(bplsch);
   butina(bpan);
   butina(bin);
   butina(bout);
   butina(bruler);
   butina(bname);
   butina(bdown);
   butina(bmet1);
   butina(bmet2);
   butina(bpoly);
   butina(bvia);
   butina(bcont);
   butina(bndiff);
   butina(bpdiff);
   butina(bnwell);
   butina(bpwell);
   butina(bccut);
   butina(bplace);
   butina(bdwave);
   butina(bawave);
   { cancel tracing activity }
   rescur; { lift cursor }
   p := curwin^.cs^.dl[ltfig]; { index top of figure list }
   while p <> nil do begin { traverse }

      if p^.cl <> black then begin { colored figure }

         drwfig(p, black, false, ltfig, curwin^.cs^.vp.v); { restore figure }
         p^.cl := black

      end;
      p := p^.next { next figure }

   end;
   for ci := black to white do trctrk[ci] := false;
   trcclr := lcyan; { reset to starting color }
   setcur; { set cursor }
   canact { cancel activities }

end;
{}
{**************************************************************

DEACTIVATE CURRENT VIEW ACTIVITIES

Resets all view activity buttons, and resets indicators and
markers from the screen.

**************************************************************}

procedure stopview;

begin

   butina(bpan); { deactivate all these buttons }
   butina(bin);
   butina(bout);
   butina(bruler);
   butina(bname);
   butina(bdown);
   rescur; { lift cursor }
   { reset any onscreen cursor }
   reszoom; { reset zoom box }
   resmrk; { reset marker }
   resrlm; { reset ruler mark }
   resline; { reset line cursor }
   resbox; { reset box cursor }
   rescircle; { reset circle cursor }
   resarc; { reset arc cursor }
   restcur; { reset text cursor }
   setcur; { drop cursor }
   { negate in process modes }
   modbut := bnull;
   vimbut := bnull;
   { cancel in-progress edits }
   if cedbut <> bnull then begin

      button[cedbut].s := butsav; { restore from save }
      { update screen }
      updbut(cedbut) { update }

   end

end;
{}
{**************************************************************

PLACE GRID

Fills the indicator grid array with the locations of the dot
grid. This is done prior to drawing the dot grid, usually
anytime a view change is made.

**************************************************************}

{ port: repaired grid step field references (curwin^.cs^.ds) and
  restarted the column scan on each row }

procedure dogrid(x1, y1, x2, y2: integer; { real bounds to draw }
                 c:              color);  { color to draw }

var x, y, xs: integer;

begin

   if (scndist(curwin^.cs^.ds, curwin^.cs^.vp.s.x) >= dotmin) and
      (scndist(curwin^.cs^.ds, curwin^.cs^.vp.s.y) >= dotmin) then begin

      { minimum spacing ok, proceed }
      { find bounding points on grid but within specified square }
      xs := x1 - x1 mod curwin^.cs^.ds; { find starting x }
      if xs < x1 then xs := xs + curwin^.cs^.ds;
      y := y1 - y1 mod curwin^.cs^.ds; { find starting y }
      if y < y1 then y := y + curwin^.cs^.ds;
      { draw dots }
      while y <= y2 do begin { rows }

         x := xs; { restart column scan }
         while x <= x2 do begin { collumns }

            setpix(curwin^.cs^.vp, x, y, c);
            x := x + curwin^.cs^.ds

         end;
         y := y + curwin^.cs^.ds

      end

   end

end;
{}
{**************************************************************

PLACE 10S GRID

Fills the indicator grid array with the locations of the line
grid. This is done prior to drawing the dot grid, usually
anytime a view change is made.

**************************************************************}

{ port: repaired grid step field references (curwin^.cs^.ls) and
  added the missing color parameter to the line calls }

procedure do10sgrid(x1, y1, x2, y2: integer; { real bounds to draw }
                    c:              color);  { color to draw }

var x, y:   integer;

begin

   if (scndist(curwin^.cs^.ls, curwin^.cs^.vp.s.x) >= linemin) and
      (scndist(curwin^.cs^.ls, curwin^.cs^.vp.s.y) >= linemin) then begin

      { minimum spacing ok, proceed }
      x := x1 - x1 mod curwin^.cs^.ls; { find starting x }
      if x < x1 then x := x + curwin^.cs^.ls;
      while x < x2 do begin { collums }

         line(curwin^.cs^.vp, x, y1, x, y2, c);
         x := x + curwin^.cs^.ls

      end;
      y := y1 - y1 mod curwin^.cs^.ls; { find starting y }
      if y < y1 then y := y + curwin^.cs^.ls;
      while y < y2 do begin { rows }

         line(curwin^.cs^.vp, x1, y, x2, y, c);
         y := y + curwin^.cs^.ls

      end

   end

end;
{}
{**************************************************************

CLEAR RULER

Clears the ruler display.

**************************************************************}

procedure cruler;

begin

   button[brulerv].s := '        '; { clear strings }
   button[brulxv].s := '        ';
   button[brulyv].s := '        ';
   updbut(brulerv); { update }
   updbut(brulxv);
   updbut(brulyv)

end;
{}
{**************************************************************

ZERO RULER

Sets the ruler display to all zeros.

**************************************************************}

procedure zruler;

begin

   button[brulerv].s := '      0 '; { set strings }
   button[brulxv].s := '      0 ';
   button[brulyv].s := '      0 ';
   updbut(brulerv); { update }
   updbut(brulxv);
   updbut(brulyv)

end;
{}
{**************************************************************

CHECK TARGET BOUNDS CHANGE

Checks if the bounds set for the current target have changed,
and updates the target display if so. The cursor is not lifted
for this.

**************************************************************}

procedure chktar;

begin

   { port: nil-sheet guard added }
   if curwin^.cs <> nil then
      { check if bounds have changed }
      if (targbnd.s.x <> curwin^.cs^.bbsx) or (targbnd.s.y <> curwin^.cs^.bbsy) or
         (targbnd.e.x <> curwin^.cs^.bbex) or (targbnd.e.y <> curwin^.cs^.bbey) then
         updtar { update target }

end;
{}
{**************************************************************

CHECK BOUNDING BOX SET

Checks if the bounding box has been previously set.

**************************************************************}

function boundset(sp: shtptr): boolean;

begin

   boundset := sp^.bs

end;
{}
{**************************************************************

UPDATE BOUNDING BOX

Given a coordinate set, updates the bounding box. The bounding
box is a box enclosing all drawn points on the screen.

**************************************************************}

procedure setbound(x, y: integer);

var b: region; { save of bounds }

begin

   if not curwin^.cs^.bs then begin { never set, set all points }

      curwin^.cs^.bbsx := x;
      curwin^.cs^.bbsy := y;
      curwin^.cs^.bbex := x;
      curwin^.cs^.bbey := y

   end else begin { expand box as required }

      if x < curwin^.cs^.bbsx then curwin^.cs^.bbsx := x; { modify bounding box }
      if y < curwin^.cs^.bbsy then curwin^.cs^.bbsy := y;
      if x > curwin^.cs^.bbex then curwin^.cs^.bbex := x;
      if y > curwin^.cs^.bbey then curwin^.cs^.bbey := y

   end;
   curwin^.cs^.bs := true { set bounds active }

end;
{}
{**************************************************************

CHECK SYMBOL BOUNDING BOX SET

Checks if the symbol bounding box has been previously set.

**************************************************************}

function sboundset: boolean;

begin

   sboundset := curwin^.cs^.sbs

end;
{}
{**************************************************************

UPDATE SYMBOL BOUNDING BOX

Given a coordinate set, updates the symbol bounding box. The
bounding box is a box enclosing all drawn points on the screen.
The symbol bounding box does not include connectors, which do
not appear in symbol placements.

**************************************************************}

procedure setsbound(x, y: integer);

begin

   if not curwin^.cs^.sbs then begin { never set, set all points }

      curwin^.cs^.sbbsx := x;
      curwin^.cs^.sbbsy := y;
      curwin^.cs^.sbbex := x;
      curwin^.cs^.sbbey := y

   end else begin { expand box as required }

      if x < curwin^.cs^.sbbsx then curwin^.cs^.sbbsx := x; { modify bounding box }
      if y < curwin^.cs^.sbbsy then curwin^.cs^.sbbsy := y;
      if x > curwin^.cs^.sbbex then curwin^.cs^.sbbex := x;
      if y > curwin^.cs^.sbbey then curwin^.cs^.sbbey := y

   end;
   curwin^.cs^.sbs := true { set symbol bounds active }

end;
{}
{**************************************************************

REDRAW SCREEN

Clears the active area, and draws all figures onscreen. Also
replaces any in-progress figures. Also updates the target
display.
May be used to refresh "over" an existing screen.

**************************************************************}

procedure redraw;

begin

   rescur; { remove cursor }
   block(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y,
         curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, white); { clear active area }
   { draw active area }
   { port: grid indicator arrays deleted; the grids are drawn directly
     over the real extent of the view }
   if button[blines].act then { line grid active }
      do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                yellow); { place grid lines }
   if button[bdots].act then { dot grid active }
      dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
             curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
             black); { place grid dots }
   drwfigs; { draw figures }
   { replace any cursor figures }
   if zbxdwn then begin zbxdwn := false; setzoom end;
   if mrkdwn then begin mrkdwn := false; setmrk end;
   if rlmdwn then begin rlmdwn := false; setrlm end;
   if lindwn then begin lindwn := false; setline end;
   if boxdwn then begin boxdwn := false; setbox end;
   if cirdwn then begin cirdwn := false; setcircle end;
   if arcdwn then begin arcdwn := false; setarc end;
   if tcrdwn then begin tcrdwn := false; settcur end;
   updtar; { update target display }
   setcur { replace cursor }

end;
{}
{**************************************************************

SET NEW VIEW

Accepts and sets active a new view. The last view is set, and
the grids are calculated. The origin and scale displays are
updated.

**************************************************************}

procedure newview(x, y, s: integer);

var i: btsinx;

begin

   if not ((curwin^.cs^.vp.r.s.x = x) and (curwin^.cs^.vp.r.s.y = y) and
           (curwin^.cs^.vp.s.x = s)) then begin

      { not the same view }
      curwin^.cs^.lvp := curwin^.cs^.vp; { save last view }
      curwin^.cs^.vp.r.s.x := x; { set new view }
      curwin^.cs^.vp.r.s.y := y;
      curwin^.cs^.vp.s.x := s;
      curwin^.cs^.vp.s.y := s;
      curwin^.cs^.vp.r.e.x :=
         curwin^.cs^.vp.r.s.x+realdist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1, s);
      curwin^.cs^.vp.r.e.y :=
         curwin^.cs^.vp.r.s.y+realdist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1, s);
      redraw; { redraw screen }

   end;
   { place origin }
   realstr(curwin^.cs^.vp.r.s.x*pixsiz, button[borgxv].s);
   realstr(curwin^.cs^.vp.r.s.y*pixsiz, button[borgyv].s);
   { place scale }
   intstr(curwin^.cs^.vp.s.x div scalem, button[bsclv].s);
   trmzer(button[bsclv].s); { trim leading zeros }
   { move left }
   for i := 1 to 6 do button[bsclv].s[i] := button[bsclv].s[i+2];
   for i := 7 to butlen do button[bsclv].s[i] := ' ';
   rescur; { remove cursor }
   updbut(borgxv); { update }
   updbut(borgyv);
   updbut(bsclv);
   setcur { restore cursor }

end;
{}
{**************************************************************

DISPLAY SHEET

Updates the display for the current sheet. Also clears
any active modes.

**************************************************************}

procedure dispsht;

var i:  btsinx;

begin

   rescur; { lift cursor }
   rcur := cur; { find real version cursor position }
   realc(rcur, curwin^.cs^.vp); { convert coordinates }
   { place dot grid size }
   realstr(curwin^.cs^.ds*pixsiz, button[bdotsv].s);
   updbut(bdotsv); { update }
   { place line grid size }
   realstr(curwin^.cs^.ls*pixsiz, button[blinev].s);
   updbut(blinev); { update }
   { place origin }
   realstr(curwin^.cs^.vp.r.s.x*pixsiz, button[borgxv].s);
   updbut(borgxv); { update }
   realstr(curwin^.cs^.vp.r.s.y*pixsiz, button[borgyv].s);
   updbut(borgyv); { update }
   { place scale }
   intstr(curwin^.cs^.vp.s.x div scalem, button[bsclv].s);
   trmzer(button[bsclv].s); { trim leading zeros }
   { move left }
   for i := 1 to 6 do button[bsclv].s[i] := button[bsclv].s[i+2];
   for i := 7 to butlen do button[bsclv].s[i] := ' ';
   updbut(bsclv); { update }
   updcps; { place cursor location }
   { place text size }
   realstr(curwin^.cs^.ts*4*pixsiz, button[btsizv].s);
   updbut(btsizv); { update }
   { place junction size }
   realstr(curwin^.cs^.js*2*pixsiz, button[bjuncv].s);
   updbut(bjuncv); { update }
   { place connector size }
   realstr(curwin^.cs^.cs*2*pixsiz, button[bconnv].s);
   updbut(bconnv); { update }
   drmbut := bnull; { set draw mode inactive }
   vimbut := bnull; { set view mode inactive }
   cedbut := bnull; { set no button in edit }
   butina(bout); { clear mode buttons }
   butina(bpan);
   butina(bin);
   butina(bruler);
   redraw; { refresh screen }
   setcur { drop cursor }

end;
{}
{**************************************************************

PLACE CHILD WINDOW

Places, or replaces, a child window in a parent. The screen
viewport of the given child window is set up to occupy the
given retangle in the parent. The rectangle is given in
parent real coordinates.

**************************************************************}

{ port: moved ahead of newsht (forward reference in the original);
  master and child are var parameters, since child receives the
  screen rectangle and viewc requires a var viewport }

procedure plcwin(var master, child: viewport;  { windows }
                 x1, y1, x2, y2: integer); { placement rectangle }

var r: region; { convertion rectangle }

begin

   r.s.x := x1; { load rectangle }
   r.s.y := y1;
   r.e.x := x2;
   r.e.y := y2;
   viewc(r.s, master); { find screen rectangle }
   viewc(r.e, master);
   child.v := r { place screen rectangle }

end;
{}
{**************************************************************

CLEAR NEW SHEET

Clears the entire current sheet, and restores default parameters,
then draws the sheet.

**************************************************************}

procedure newsht;

var p:  drwptr;  { pointer for display list }
    n:  nodptr;  { pointer for node list }
    b:  busptr;  { pointer for bus list }
    vi: viewinx;
    si: sizeinx;
    li: laytyp;  { layers index }

{ dispose of drawing list content }

procedure dumpdraw(var p: drwptr);

var p1: drwptr; { pointer for list }

begin

   while p <> nil do begin { remove drawing entries }

      p1 := p^.next; { save next entry }
      dispose(p); { dispose head entry }
      p := p1 { set next entry }

   end

end;

begin

   { dispose of all layers }
   for li := ltcell to ltwell do dumpdraw(curwin^.cs^.dl[li]);
   while curwin^.cs^.nl <> nil do begin { remove node entries }

      n := curwin^.cs^.nl^.next; { save next entry }
      dispose(curwin^.cs^.nl); { dispose head entry }
      curwin^.cs^.nl := n { set next entry }

   end;
   while curwin^.cs^.bl <> nil do begin { remove bus entries }

      b := curwin^.cs^.bl^.next; { save next entry }
      dispose(curwin^.cs^.bl); { dispose head entry }
      curwin^.cs^.bl := b { set next entry }

   end;
   { Set viewport region to all of window active area.
     This can be changed if we allow more than one sheet
     per window. }
   plcwin(curwin^.wv, curwin^.cs^.vp,
          curwin^.ar.s.x, curwin^.ar.s.y,
          curwin^.ar.e.x, curwin^.ar.e.y);
   curwin^.cs^.vp.r.s.x := 0; { set viewport to [0, 0] }
   curwin^.cs^.vp.r.s.y := 0;
   curwin^.cs^.vp.m.x := scalem; { set scaling multiplier }
   curwin^.cs^.vp.m.y := scalem;
   curwin^.cs^.vp.s.x := normscale*scalem; { set normal viewing scale }
   curwin^.cs^.vp.s.y := normscale*scalem;
   curwin^.cs^.vp.r.e.x :=
      curwin^.cs^.vp.r.s.x+realdist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1,
                                curwin^.cs^.vp.s.x);
   curwin^.cs^.vp.r.e.y :=
      curwin^.cs^.vp.r.s.y+realdist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1,
                                curwin^.cs^.vp.s.y);
   curwin^.cs^.lvp := curwin^.cs^.vp; { set last view as same }
   curwin^.cs^.bbsx := 0; { flag bounding box inactive }
   curwin^.cs^.bbex := 0;
   curwin^.cs^.bbsy := 0;
   curwin^.cs^.bbey := 0;
   curwin^.cs^.bs := false;
   curwin^.cs^.sbbsx := 0;
   curwin^.cs^.sbbex := 0;
   curwin^.cs^.sbbsy := 0;
   curwin^.cs^.sbbey := 0;
   curwin^.cs^.sbs := false;
   if smsimulate in curscm then begin

      curwin^.cs^.ds := dftdgsim; { set default dot grid size }
      curwin^.cs^.ls := dftlgsim { set default line grid size }

   end else begin

      curwin^.cs^.ds := dftdg; { set default dot grid size }
      curwin^.cs^.ls := dftlg { set default line grid size }

   end;
   curwin^.cs^.js := dftjun; { set default junction size }
   curwin^.cs^.cs := dftcon; { set default connector size }
   curwin^.cs^.ts := dftchr; { set standard character scale }
   { clear viewer array }
   for vi := 1 to viewmax do curwin^.cs^.sv[vi].a := false;
   { clear text size array }
   for si := 1 to sizemax do curwin^.cs^.sts[si].a := false;
   { clear dot size array }
   for si := 1 to sizemax do curwin^.cs^.sds[si].a := false;
   { clear line size array }
   for si := 1 to sizemax do curwin^.cs^.sls[si].a := false;
   celstk := nil; { clear cell stack }
   dispsht { display sheet }

end;
{}
{**************************************************************

DISPLAY CELL

Activates viewing of the current cell. The existing sheet for the
current mode is either viewed, or created and viewed if it
does not currently exist for that cell.
Also sets the current sheet active (based on mode).

**************************************************************}

procedure dispcell;

var li: laytyp; { layers index }

begin

   if button[bschema].act then begin

      { in schematic mode }
      if curwin^.cc^.schema = nil then begin { create new sheet }

         new(curwin^.cc^.schema); { get a new sheet entry for schematic }
         for li := ltcell to ltwell do
            curwin^.cc^.schema^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.schema^.nl := nil; { clear node list }
         curwin^.cc^.schema^.bl := nil; { clear bus list }
         curwin^.cc^.schema^.nc := 0; { clear node count }
         curwin^.cs := curwin^.cc^.schema; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.schema; { place as current sheet }
         dispsht { display current sheet }

      end

   end else if button[bsymbol].act then begin

      { in symbol mode }
      if curwin^.cc^.symbol = nil then begin { create new sheet }

         new(curwin^.cc^.symbol); { get a new sheet entry for symbol }
         for li := ltcell to ltwell do
            curwin^.cc^.symbol^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.symbol^.nl := nil; { clear node list }
         curwin^.cc^.symbol^.bl := nil; { clear bus list }
         curwin^.cc^.symbol^.nc := 0; { clear node count }
         curwin^.cs := curwin^.cc^.symbol; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.symbol; { place as current sheet }
         dispsht { display current sheet }

      end

   end else if button[blayout].act then begin

      { in layout mode }
      if curwin^.cc^.layout = nil then begin { create new sheet }

         new(curwin^.cc^.layout); { get a new sheet entry for layout }
         for li := ltcell to ltwell do
            curwin^.cc^.layout^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.layout^.nl := nil; { clear node list (unused) }
         curwin^.cc^.layout^.bl := nil; { clear bus list (unused) }
         curwin^.cc^.layout^.nc := 0; { clear node count (unused) }
         curwin^.cs := curwin^.cc^.layout; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.layout; { place as current sheet }
         dispsht { display current sheet }

      end

   end else begin

      { in simulate mode }
      if curwin^.cc^.simulate = nil then begin { create new sheet }

         new(curwin^.cc^.simulate); { get a new sheet entry for layout }
         for li := ltcell to ltwell do
            curwin^.cc^.simulate^.dl[li] := nil; { clear draw lists }
         curwin^.cc^.simulate^.nl := nil; { clear node list (unused) }
         curwin^.cc^.simulate^.bl := nil; { clear bus list (unused) }
         curwin^.cc^.simulate^.nc := 0; { clear node count (unused) }
         curwin^.cs := curwin^.cc^.simulate; { place as current sheet }
         newsht { initalize sheet }

      end else begin { view old sheet }

         curwin^.cs := curwin^.cc^.simulate; { place as current sheet }
         dispsht { display current sheet }

      end

   end

end;
{}
{**************************************************************

DISPLAY WINDOW FRAME

Calculates a window frame based on the given screen viewport,
calculates the client region within that, and displays the
windowframe.

**************************************************************}

procedure dispwframe(wp: winptr;  { window }
                     s:  ttlstr); { window title }

var i:  ttlinx; { string index }
    l:  integer; { length of string in pixels }
    x:  integer;
    sl: ttlinx; { string length }

begin

   wp^.wv.r.s.x := 0; { zero based, but same size }
   wp^.wv.r.s.y := 0;
   { port: repaired wp^.wv.s.x/y to wp^.wv.v.s.x/y (screen extent) }
   wp^.wv.r.e.x := wp^.wv.v.e.x-wp^.wv.v.s.x;
   wp^.wv.r.e.y := wp^.wv.v.e.y-wp^.wv.v.s.y;
   { port: was 1 in the (mid-refactor) originals; see the screen viewport
     note in iniicd — identity window viewports need s = m = scalem }
   wp^.wv.s.x := scalem; { set no scaling }
   wp^.wv.s.y := scalem;
   wp^.wv.m.x := scalem;
   wp^.wv.m.y := scalem;
   wp^.wv.c := wp^.wv.v; { set clipping to window }
   { find client area within frame }
   { port: uiscl - frame border/title bar pixel constants scaled to
     character cell throughout dispwframe }
   wp^.cr.s.x := wp^.wv.r.s.x+uiscl(2+5+2);
   wp^.cr.s.y := wp^.wv.r.s.y+uiscl(2+5+2);
   wp^.cr.e.x := wp^.wv.r.e.x-uiscl(2+5+2);
   wp^.cr.e.y := wp^.wv.r.e.y-uiscl(2+5+2);
   { place move buttons }
   plcmovb;
   rescur; { lift cursor }
   { draw frame backround left }
   block(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y,
         wp^.ar.s.x-1, wp^.wv.r.e.y, wp^.bc);
   { draw frame backround top }
   block(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y,
         wp^.tr.s.x-1, wp^.ar.s.y-1, wp^.bc);
   { draw frame backround right }
   block(wp^.wv, wp^.ar.e.x+1, wp^.tr.e.y+1,
         wp^.wv.r.e.x, wp^.wv.r.e.y, wp^.bc);
   { draw frame backround bottom }
   block(wp^.wv, wp^.wv.r.s.x, wp^.ar.e.y+1,
         wp^.wv.r.e.x, wp^.wv.r.e.y, wp^.bc);
   { draw target margin }
   block(wp^.wv, wp^.tr.s.x, wp^.wv.r.s.y,
         wp^.tr.e.x, wp^.tr.s.y-1, wp^.bc);
   block(wp^.wv, wp^.tr.e.x+1, wp^.wv.r.s.y,
         wp^.wv.r.e.x, wp^.tr.e.y, wp^.bc);
   block(wp^.wv, wp^.ar.e.x+1, wp^.ar.s.y,
         wp^.tr.s.x-1, wp^.tr.e.y, wp^.bc);
   { draw window frame }
   frame(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y,
         wp^.wv.r.e.x, wp^.wv.r.e.y,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   frame(wp^.wv, wp^.wv.r.s.x+uiscl(2+5), wp^.wv.r.s.y+uiscl(2+5),
         wp^.wv.r.e.x-uiscl(2+5), wp^.wv.r.e.y-uiscl(2+5),
         wp^.sc, wp^.lc, wp^.sc, wp^.lc);
   { draw control, move, min and max button frames }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(2+5+2), wp^.wv.r.s.y+uiscl(28),
        wp^.wv.r.e.x-uiscl(2+5+2), wp^.wv.r.s.y+uiscl(28), wp^.sc);
   { port: repaired wp^.r to wp^.wv.r here and below }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(2+5+2), wp^.wv.r.s.y+uiscl(28)+1,
        wp^.wv.r.e.x-uiscl(2+5+2)+1, wp^.wv.r.s.y+uiscl(28)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y+uiscl(2+5+2+19),
        wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y+uiscl(2+5+2+19)+1,
        wp^.lc);
   frame(wp^.wv, wp^.wv.r.s.x+uiscl(2+5+2+2), wp^.wv.r.s.y+uiscl(2+5+2+6),
         wp^.wv.r.s.x+uiscl(2+5+2+19-3), wp^.wv.r.s.y+uiscl(2+5+2+6+7)-1,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y+uiscl(2+5+2+19),
        wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y+uiscl(2+5+2+19)+1,
        wp^.lc);
   if button[bmax].act then { button active }
      frame(wp^.wv,
            wp^.wv.r.e.x-uiscl(29)+uiscl(2+2), wp^.wv.r.s.y+uiscl(2+5+2+2),
            wp^.wv.r.e.x-uiscl(29)+uiscl(2+19-3), wp^.wv.r.s.y+uiscl(2+5+2+2+15)-1,
            wp^.sc, wp^.sc, wp^.lc, wp^.lc)
   else { button inactive }
      frame(wp^.wv,
            wp^.wv.r.e.x-uiscl(29)+uiscl(2+2), wp^.wv.r.s.y+uiscl(2+5+2+2),
            wp^.wv.r.e.x-uiscl(29)+uiscl(2+19-3), wp^.wv.r.s.y+uiscl(2+5+2+2+15)-1,
            wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29+19)-uiscl(2), wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29+19)-uiscl(2), wp^.wv.r.s.y+uiscl(2+5+2+19),
        wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29+19)-uiscl(2)+1, wp^.wv.r.s.y+uiscl(2+5+2),
        wp^.wv.r.e.x-uiscl(29+19)-uiscl(2)+1, wp^.wv.r.s.y+uiscl(2+5+2+19)+1,
        wp^.lc);
   frame(wp^.wv,
         wp^.wv.r.e.x-uiscl(29+19)+uiscl(6), wp^.wv.r.s.y+uiscl(2+5+2+6),
         wp^.wv.r.e.x-uiscl(29+19)+uiscl(19-7), wp^.wv.r.s.y+uiscl(2+5+2+6+7)-1,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   { place move bar breaks }
   { left }
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y+uiscl(28),
        wp^.wv.r.s.x+uiscl(2+5)-1, wp^.wv.r.s.y+uiscl(28), wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y+uiscl(28)+1,
        wp^.wv.r.s.x+uiscl(2+5), wp^.wv.r.s.y+uiscl(28)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.e.y-uiscl(29),
        wp^.wv.r.s.x+uiscl(2+5)-1, wp^.wv.r.e.y-uiscl(29), wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.e.y-uiscl(29)+1,
        wp^.wv.r.s.x+uiscl(2+5), wp^.wv.r.e.y-uiscl(29)+1, wp^.lc);
   { right }
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.s.y+uiscl(28),
        wp^.wv.r.e.x, wp^.wv.r.s.y+uiscl(28), wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.s.y+uiscl(28)+1,
        wp^.wv.r.e.x, wp^.wv.r.s.y+uiscl(28)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.e.y-uiscl(29),
        wp^.wv.r.e.x, wp^.wv.r.e.y-uiscl(29), wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(2+5)+1, wp^.wv.r.e.y-uiscl(29)+1,
        wp^.wv.r.e.x, wp^.wv.r.e.y-uiscl(29)+1, wp^.lc);
   { top }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y,
        wp^.wv.r.s.x+uiscl(28), wp^.wv.r.s.y+uiscl(2+5)-1, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y,
        wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.s.y+uiscl(2+5), wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y,
        wp^.wv.r.e.x-uiscl(29), wp^.wv.r.s.y+uiscl(2+5)-1, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y,
        wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.s.y+uiscl(2+5), wp^.lc);
   { bottom }
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28), wp^.wv.r.e.y,
        wp^.wv.r.s.x+uiscl(28), wp^.wv.r.e.y-uiscl(2+5)+1, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.e.y,
        wp^.wv.r.s.x+uiscl(28)+1, wp^.wv.r.e.y-uiscl(2+5)+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29), wp^.wv.r.e.y,
        wp^.wv.r.e.x-uiscl(29), wp^.wv.r.e.y-uiscl(2+5)+1, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.e.y,
        wp^.wv.r.e.x-uiscl(29)+1, wp^.wv.r.e.y-uiscl(2+5)+1, wp^.lc);
   { place window title, centered in move bar }
   sl := ttllen; { set maximum }
   while (sl > 1) and (s[sl] = ' ') do sl := sl - 1;
   l := 0; { clear length }
   { find total length }
   { port: alphal width table replaced by chrwidth }
   for i := 1 to sl do l := l+chrwidth(s[i])+uiscl(1);
   { find center of string }
   x := (wp^.wv.r.s.x+uiscl(30)+
         (((wp^.wv.r.e.x-uiscl(30+21))-(wp^.wv.r.s.x+uiscl(30))) div 2))
        -(l div 2);
   for i := 1 to sl do begin

      setchr(wp^.wv, x, wp^.wv.r.s.y+uiscl(2+5+2+4), s[i], black);
      x := x + chrwidth(s[i])+uiscl(1) { next collumn }

   end

end;
{}
{**************************************************************

DISPLAY WINDOW

Activates viewing of the current window. The entire window
format is recalculated and displayed.

**************************************************************}

procedure dispwin;

var b: buttyp; { button index }

begin

   { create window frame }
   dispwframe(curwin, 'Schematic Draft                         ');
   { set initial value of right margin start }
   { port: repaired curwin^.wv.cr to curwin^.cr (client region is a
     window field) here and below }
   curwin^.rm.s.x := curwin^.cr.e.x;
   repeat { menu fits }

      { set target area }
      { port: uiscl - layout margins/title bar/target height scaled }
      curwin^.tr.s.x := curwin^.rm.s.x;
      curwin^.tr.s.y := curwin^.cr.s.y+uiscl(19+2+4);
      curwin^.tr.e.x := curwin^.cr.e.x-uiscl(4);
      curwin^.tr.e.y := curwin^.tr.s.y+uiscl(100);
      { automatically arrange top side buttons }
      arrbutt(curwin^.cr.s.x+uiscl(4),
              curwin^.cr.s.y+uiscl(19+2+4),
              curwin^.rm.s.x-uiscl(5),
              curwin^.cr.e.y-uiscl(4));
      { automatically arrange right side buttons }
      marginr(curwin^.cr.e.x-uiscl(4),
              curwin^.tr.e.y+uiscl(1+4),
              curwin^.cr.e.y-uiscl(4),
              curwin^.cr.s.x+uiscl(4));
      { set active area }
      curwin^.ar.s.x := curwin^.cr.s.x+uiscl(4);
      curwin^.ar.s.y := curwin^.tm.e.y+uiscl(1+4);
      curwin^.ar.e.x := curwin^.rm.s.x-uiscl(1+4);
      curwin^.ar.e.y := curwin^.cr.e.y-uiscl(4)

   until (curwin^.tm.e.x <= curwin^.rm.s.x);
   arrbutr;
   { find aspect angle }
   curwin^.aa := arctan((curwin^.ar.e.x-curwin^.ar.s.x)/
                        (curwin^.ar.e.y-curwin^.ar.s.y));
   { set target viewport }
   plcwin(curwin^.wv, curwin^.tv,
          curwin^.tr.s.x, curwin^.tr.s.y,
          curwin^.tr.e.x, curwin^.tr.e.y);
   { port: the original was mid-migration from the global targvp to
     curwin^.tv (see the "moved to curwin" comments in common.pas); the
     drawing code still reads the global, so keep it in step }
   targvp := curwin^.tv;
   if curwin^.cs <> nil then begin { resize current sheet }

      { set sheet viewport region }
      plcwin(curwin^.wv, curwin^.cs^.vp,
             curwin^.ar.s.x, curwin^.ar.s.y,
             curwin^.ar.e.x, curwin^.ar.e.y)

   end;
   { display buttons }
   for b := succ(bnull) to bdisplay do { place buttons }
      if (curscm - [smprint]) * button[b].sm <> [] then
         { button applicable to screen mode(s) }
         updbut(b); { update }
   dispcell { display cell in edit }

end;
{}
{**************************************************************

ZOOM IN

Handles zoom in functions. If the current button is activated,
it is turned on and the zoom mode entered. If a button is clicked
in the active, the zoom box is placed.
Calculates a zoom based on the zoom box coordinates, then redraws
the screen to that magnification, and viewport centered on that
box.

**************************************************************}

procedure zoomin;

var x, y, s: integer;
    p:       point;
    b:       boolean;

begin

   if (curbut = bin) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bin].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bin); { activate button }
         modbut := bin

      end

   end else if (vimbut = bin) and
               ((inactive(cur) and inactive(mrk)) or
                (intarget(cur) and intarget(mrk))) and
               (puck.b[2].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { if zoom box present, and in active or target windows }
      rescur; { remove cursor }
      reszoom; { remove zoom box }
      setcur; { replace cursor }
      p := zb.s; { find real coordinates of box origin }
      p := zb.s;
      if inactive(cur) then
         realc(p, curwin^.cs^.vp) { convert coordinates }
      else realc(p, targvp);
      x := p.x;
      y := p.y;
      { find new scale }
      if inactive(cur) then
         s := round(curwin^.cs^.vp.s.x/(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/
              abs(zb.e.y-zb.s.y)))
      else
         s := round(targvp.s.x/(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/
              abs(zb.e.y-zb.s.y)));
      newview(x, y, s); { activate new view }
      { clear ruler }
      cruler; { clear ruler display }
      vimbut := bnull; { reset mode }
      modbut := bnull;
      butina(bin); { clear button }
      modbut := dsmbut { restore any draw mode }

   end else if (inactive(cur) or intarget(cur)) and
          (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { in active or target area }
      rescur; { remove cursor }
      if (vimbut = bin) then reszoom; { erase existing zoom box }
      mrk := cur; { set starting marker }
      rmrk := mrk; { create real version }
      if intarget(mrk) then realc(rmrk, targvp) { convert target area }
      else realc(rmrk, curwin^.cs^.vp); { convert coordinates }
      zb.s := mrk; { also set aspect box }
      zb.e := mrk;
      setzoom; { place zoom box }
      zruler; { update ruler }
      setcur; { replace cursor }
      vimbut := bin; { set mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

ZOOM OUT

Handle zoom out mode. Activates the button, starts the zoom out
indicator box.
Calculates a zoom based on the zoom box coordinates, then redraws
the screen to that magnification, and viewport centered on that
box.

**************************************************************}

procedure zoomout;

var x, y, s: integer;
    b:          boolean;

begin

   if (curbut = bout) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bout].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bout); { activate button }
         modbut := bout

      end

   end else if (vimbut = bout) and inactive(cur) and
               (puck.b[2].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { if zoom box present }
      rescur; { reset cursor }
      reszoom; { remove zoom box }
      setcur; { replace cursor }
      { find new scale }
      s := round(curwin^.cs^.vp.s.x*
           (abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)/abs(zb.e.y-zb.s.y)));
      { find new origin }
      { is old minus length to place at box }
      x := curwin^.cs^.vp.r.s.x - realdist(zb.s.x-curwin^.cs^.vp.v.s.x, s);
      y := curwin^.cs^.vp.r.s.y - realdist(zb.s.y-curwin^.cs^.vp.v.s.y, s);
      newview(x, y, s); { activate new view }
      vimbut := bnull; { reset mode }
      modbut := bnull;
      butina(bout); { clear button }
      modbut := dsmbut { restore any draw mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      rescur; { remove cursor }
      if (vimbut = bout) then reszoom; { erase existing zoom box }
      mrk := cur; { set starting marker }
      zb.s := mrk; { also set aspect box }
      zb.e := mrk;
      setzoom; { place zoom box }
      setcur; { replace cursor }
      vimbut := bout { set mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

PAN

Handles the pan mode. The pan button is toggled if activated.
The marker is placed onscreen if in the active area.
Pans the marker to the present position by changing the origin,
then refreshing the display.

**************************************************************}

procedure pan;

var x1, y1, x2, y2, t: integer;
    b:                 boolean;

begin

   if (curbut = bpan) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bpan].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bpan); { activate button }
         modbut := bpan

      end

   end else if (vimbut = bpan) and
               ((inactive(cur) and inactive(mrk)) or
                (intarget(cur) and intarget(mrk))) and
               (puck.b[2].a or (puck.b[1].d and puck.b[1].dg)) then begin

      { perform pan }
      rescur; { reset cursor }
      resmrk; { remove marker }
      setcur; { reset cursor }
      x1 := curwin^.cs^.vp.r.s.x+(rmrk.x-rcur.x); { set new origin }
      y1 := curwin^.cs^.vp.r.s.y+(rmrk.y-rcur.y);
      { find end of screen }
      x2 := x1+realdist(abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)+1, curwin^.cs^.vp.s.x);
      y2 := y1+realdist(abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)+1, curwin^.cs^.vp.s.y);
      if (x1 > rw.s.x) and (x2 < rw.e.x) and
         (y1 > rw.s.y) and (y2 < rw.e.y) then
         newview(x1, y1, curwin^.cs^.vp.s.x); { go new view }
      { clear ruler }
      cruler; { clear ruler display }
      vimbut := bnull; { reset mode }
      modbut := bnull;
      butina(bpan); { clear button }
      modbut := dsmbut { restore any draw mode }

   end else if (inactive(cur) or intarget(cur)) and
               (puck.b[1].a or puck.b[2].a) then begin

      { place pan marker }
      rescur; { remove cursor }
      if vimbut = bpan then resmrk; { remove previous mark }
      mrk := cur; { set marker coordinates }
      rmrk := mrk; { create real version }
      if intarget(mrk) then realc(rmrk, targvp) { convert target area }
      else realc(rmrk, curwin^.cs^.vp); { convert coordinates }
      setmrk; { set marker }
      setcur; { replace cursor }
      zruler; { update ruler }
      vimbut := bpan; { set mark mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

RULER

Handles the ruler mode. If the button is activated, that is
turned on. If a button is clicked in active, the ruler
"target" icon is placed. From then on, the ruler mode is self -
operating.

**************************************************************}

procedure ruler;

var b: boolean;

begin

   if (curbut = bruler) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { toggle state of button }
      if button[bruler].act then begin { turn it off }

         stopview; { stop current view modes }
         modbut := dsmbut { restore any draw mode }

      end else begin { turn it on }

         stopview; { stop current view modes }
         butact(bruler); { activate button }
         modbut := bruler

      end

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin

      rescur; { remove cursor }
      if vimbut = bruler then resrlm; { remove previous mark }
      mrk := cur; { set marker coordinates }
      rmrk := mrk; { create real version }
      realc(rmrk, curwin^.cs^.vp); { convert coordinates }
      setrlm; { set marker }
      setcur; { replace cursor }
      zruler; { update ruler }
      vimbut := bruler { set rule mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

GO BOUNDING BOX

Changes the view to the bounding box.

**************************************************************}

procedure bound;

var x, y, s: integer;

begin

   if (curbut = bbound) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      stopview; { stop motion modes }
      butact(bbound); { activate button }
      fndbnd(curwin^.cs, x, y, s); { find the view }
      newview(x, y, s); { activate new view }
      butina(bbound); { deactivate button }
      modbut := dsmbut { restore any draw mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

LAST VIEW

Restores the last origin and scale factor.

**************************************************************}

procedure back;

var x, y, s: integer;

begin

   if (curbut = bback) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      stopview; { stop motion modes }
      butact(bback); { set button active }
      x := curwin^.cs^.lvp.r.s.x; { get the last view }
      y := curwin^.cs^.lvp.r.s.y;
      s := curwin^.cs^.lvp.s.x;
      newview(x, y, s); { activate new (old) view }
      butina(bback); { set button inactive }
      modbut := dsmbut { restore any draw mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE SNAP

Flips the state of the snap to grid mode. Also redraws any
in-progress line.

**************************************************************}

procedure togsnap;

begin

   if (curbut = bsnap) and (puck.b[1].a or
      puck.b[2].a or puck.b[4].a) then begin

      if button[bsnap].act then butina(bsnap) { toggle status }
      else butact(bsnap);
      if drmbut in [bline, bbline, bwire, bbus, bbox,
                    bbbox, bsaveb] then begin

         { line or box }
         str := tstr; { restore true start }
         snapto(str.x, str.y) { snap start point }

      end else if drmbut = bcircle then begin { circle }

         cen := tcen; { restore true center }
         snapto(cen.x, cen.y) { snap center }

      end

   end;
   resptr { reset buttons }

end;
{ UNRESOLVED:
  drwfigs  - draw all figures (icdd.pas), stubbed in redraw; cell drawing
             deferred to a later phase
  drwfig   - draw single figure (icdd/icdh.pas), stubbed in stopact; cell
             drawing deferred to a later phase
  updtar   - update target display (icdf.pas), called by chktar and redraw;
             later phase
  printstop - clear printer pop-up (icde.pas), called by canact; printer
             pass deferred
  fndbnd   - find parameters for bounds view (icda.pas), called by bound;
             expected from the icda fragment or a later phase
  resptr   - reset pointer flags (icda.pas), called by the view mode
             handlers; expected from the icda fragment or the main program
             event loop
  setchr   - viewport character draw, called by dispwframe; expected from
             the icdb fragment (spec rule 3)
  targbnd  - target bounding box global, referenced by chktar; currently
             commented out in icddef.pas ("?? moved to curwin") and must be
             restored or relocated }

module icdc;

uses {$U common.j} common;

{ set pixel value }
procedure setpix(var vp: viewport; x, y: integer; c: color); external;
procedure line(var vp: viewport; x1, y1, x2, y2: integer; c: color); external; { draw line }
procedure box(x1, y1, x2, y2: integer; c: color); external; { draw box }
{ draw filled block }
procedure block(var vp: viewport; x1, y1, x2, y2: integer; c: color); external;
procedure butact(b: buttyp); external; { set button active }
procedure butina(b: buttyp); external; { set button inactive }
procedure butuna(b: buttyp); external; { set button disabled }
procedure butalt(b: buttyp); external; { set button alerted }
procedure butdlt(b: buttyp); external; { set button not alerted }
procedure snapto(var x, y: integer); external; { snap coordinates to grid }
procedure setend; external; { set line endpoint }
procedure setasp; external; { set aspect box }
procedure setzoom; external; { set zoom box }
procedure reszoom; external; { reset zoom box }
{ check point in active area }
function inactive(p: point): boolean; external;
{ check point in target area }
function intarget(p: point): boolean; external;
procedure setcur; external; { draw cursor into place }
procedure rescur; external; { remove cursor }
procedure setmrk; external; { set mark }
procedure resmrk; external; { reset mark }
procedure setrlm; external; { set ruler mark }
procedure resrlm; external; { reset ruler mark }
procedure setline; external; { set line }
procedure resline; external; { reset line }
procedure setbox; external; { set box }
procedure resbox; external; { reset box }
procedure setcircle; external; { set circle }
procedure rescircle; external; { reset circle }
procedure setarc; external; { set arc }
procedure resarc; external; { reset arc }
procedure settcur; external; { set text cursor }
procedure restcur; external; { reset text cursor }
{ place vector character }
procedure vchar(x, y: integer; c: char; s: integer; cl: color; 
                r: boolean; cr: region); external;
{ convert integer to string }
procedure intstr(n: integer; var s: butstr); external;
procedure trmzer(var s: butstr); external; { remove leading zeros }
{ convert real to string }
procedure realstr(r: real; var s: butstr); external;
procedure doloadc; external; { load current cell }
procedure dosavec; external; { save current cell }
{ update button }
procedure updbut(b: buttyp); external;
{ edit button string (primitive) }
procedure edit(var b: butrec; var p: btsinx; c: char; cs: char); 
          external;
{ edit button string }
procedure edtbut(var b: butrec); external;
{ get real number from button string }
procedure getrnm(var b: butrec; var n: real; var e: boolean); 
          external;
procedure lnkwire(d: drwptr); external; { link wire to node }
procedure lnkbus(d: drwptr); external; { link bus to bus list }
procedure lnkjun(j: drwptr); external; { link junctions }
procedure dofiles; external; { display availible files }
procedure docells; external; { display availible cells }
procedure dolibs; external; { display library cells }
procedure delete; external; { delete closest figure }
procedure deletenet; external; { delete closest network }
procedure drwfigs; external; { draw all figures }
{ calculate screen distance }
function scndist(d, s: integer): integer; external;
{ calculate real distance }
function realdist(d, s: integer): integer; external;
{ place junction }
procedure plcjun(x, y: integer; var p: drwptr); external; 
procedure tracenet; external; { trace network }
procedure doname; external; { do node name set/show }
procedure saveblk; external; { save block }
procedure pasteblk; external; { paste block }
{ rationalize line }
procedure ratlin(var x1, y1, x2, y2: integer); external;
{ draw figure }
procedure drwfig(p: drwptr; c: color; co: boolean; ln: laytyp; 
                 r: region); external;
{ find parameters for bounds view }
procedure fndbnd(sp: shtptr; var x, y, s: integer); external; 
{ color node }
procedure clrnode(n: nodptr; c: color); external;
{ redraw real region }
procedure rregion(x1, y1, x2, y2: integer); external;
{ redraw real region with fudge }
procedure frregion(x1, y1, x2, y2: integer); external;
procedure downcell; external; { enter subcell }
procedure upcell; external; { exit subcell }
{ get integer from string }
procedure getint(var b: butrec; var n: integer; var err: boolean); 
          external;
procedure scnprt; external; { print screen }
procedure doprint; external; { print sheet }
procedure updtar; external; { update target display }
procedure updptr; external; { update pointer device }
procedure resptr; external; { reset pointer flags }
{ find view coordinates }
procedure viewc(var p: point; var vp: viewport); external;
{ find real coordinates }
procedure realc(var p: point; var vp: viewport); external;
{ place message string }
procedure plcmsg(m: msgtyp; c: color); external;
procedure aniblank; external; { provide blanking animation }
procedure aniini; external; { initalize animator }
{ check in given button }
function inbutton(b: buttyp): boolean; external;
procedure strpedt; external; { start printer pop-up edit }
{ do printer pop-up edit }
procedure dopedt(c, cs: char; b: buttyp; var r: real); external;
procedure printpop; external; { present printer pop-up }
procedure printstop; external; { clear print pop-up }
procedure setlayout; external; { set layout sheet }
procedure setsimulate; external; { set simulate sheet }
procedure togvis; external; { toggle layer visibility }
procedure togins; external; { toggle insides visibility }
procedure dolayer; external; { perform layer draw }
{ rationalize box }
procedure ratbox(var x1, y1, x2, y2: integer); external;
procedure dointer(p: drwptr); external; { create intersections }
procedure dowave; external; { perform waveform edit }
function kbdrdy: boolean; cexternal; { check keyboard ready }
function kbdinp: char; cexternal; { get keyboard character }
function gettim: integer; cexternal; { get current system time }
{ find elapsed time }
function elapsed(t: integer): integer; external;
{ draw character onscreen }
procedure setchr(vp: viewport; x, y: integer; ch: char; cl: color); external;
{ set right margin }
procedure marginr(rm, tm, bm, lm: integer); external;
{ arrange right side buttons }
procedure arrbutr; external;
{ arrange top side buttons }
procedure arrbutt(lm, tm, rm, bm: integer); external;
{ draw button frame }
procedure frame(var vp: viewport; x1, y1, x2, y2: integer; 
                tc1, tc2, bc1, bc2: color); external;
procedure plcmovb; external; { place move buttons }
{ box draw with save }
procedure boxsav(x1, y1, x2, y2: integer; c: color; 
                 var i: lininx);  external;
{ box restore }
procedure boxrst(x1, y1, x2, y2: integer; var i: lininx);
          external;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
{**************************************************************

MOVE CURSOR

Moves the cursor to a new location. 
The cursor is removed from the present position, and replaced
at the new position.
Any "in progress" drawn shape is also removed and replaced.

**************************************************************}

procedure movcur(newx, newy: integer); { move cursor }

var i:      lininx; { index for line save }
    t:      integer;
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
{}
{**************************************************************

UPDATE PUCK STATUS

**************************************************************}

procedure updpuck;

begin

   updptr; { update pointer device }
   { update proximity status }
   if puck.v then butdlt(bprox);
   if not puck.v then butalt(bprox);
   { check puck movement }
   if puck.m then 
      movcur(puck.cl.x, puck.cl.y) { move cursor to new location }
   else if not puck.v then begin { cursor not valid }
    
      updcps; { clear position indicator }
      rescur { lift cursor }

   end

end;
{}
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
{}
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
{}
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
{}
{**************************************************************

PLACE GRID

Fills the indicator grid array with the locations of the dot
grid. This is done prior to drawing the dot grid, usually
anytime a view change is made.

**************************************************************}

procedure dogrid(x1, y1, x2, y2: integer; { real bounds to draw }
                 c:              color);  { color to draw } 

var x, y:     integer;

begin

   if (scndist(curwin^.cs^.ds, curwin^.cs^.vp.s.x) >= dotmin) and 
      (scndist(curwin^.cs^.ds, curwin^.cs^.vp.s.y) >= dotmin) then begin 

      { minimum spacing ok, proceed }
      { find bounding points on grid but within specified square }
      x := x1 - x1 mod curwin^.cs; { find starting x }
      if x < x1 then x := x + curwin^.cs;
      y := y1 - y1 mod curwin^.cs; { find starting y }
      if y < y1 then y := y + curwin^.cs;
      { draw dots }
      while y <= y2 do { rows }
         while x <= x2 do begin { collumns }

            setpix(curwin^.cs.vp, x, y, c);
            x := x + curwin^.cs

         end;
         y := y + curwin^.cs

      end

   end

end;
{}
{**************************************************************

PLACE 10S GRID

Fills the indicator grid array with the locations of the line
grid. This is done prior to drawing the dot grid, usually
anytime a view change is made.

**************************************************************}

procedure do10sgrid(x1, y1, x2, y2: integer; { real bounds to draw }
                    c:              color);  { color to draw } 

var x, y:   integer;

begin

   if (scndist(curwin^.cs^.ls, curwin^.cs^.vp.s.x) >= linemin) and
      (scndist(curwin^.cs^.ls, curwin^.cs^.vp.s.y) >= linemin) then begin 

      { minimum spacing ok, proceed }
      x := x1 - x1 mod curwin^.cs; { find starting x }
      if x < x1 then x := x + curwin^.cs;
      while x < x2 do begin { collums }

         line(curwin^.cs.vp, x, y1, x, y2);
         x := x + curwin^.cs

      end;
      y := y1 - y1 mod curwin^.cs; { find starting y }
      if y < y1 then y := y + curwin^.cs;
      while y < y2 do begin { rows }

         line(curwin^.cs.vp, x1, y, x2, y);
         y := y + curwin^.cs

      end

   end

end;
{}
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
{}
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
{}
{**************************************************************

CHECK TARGET BOUNDS CHANGE

Checks if the bounds set for the current target have changed,
and updates the target display if so. The cursor is not lifted
for this.

**************************************************************}

procedure chktar;

begin

   { check if bounds have changed }
   if (targbnd.s.x <> curwin^.cs^.bbsx) or (targbnd.s.y <> curwin^.cs^.bbsy) or
      (targbnd.e.x <> curwin^.cs^.bbex) or (targbnd.e.y <> curwin^.cs^.bbey) then
      updtar { update target }

end;
{}
{**************************************************************

CHECK BOUNDING BOX SET

Checks if the bounding box has been previously set.

**************************************************************}

function boundset(sp: shtptr): boolean;

begin

   boundset := sp^.bs

end;
{}
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
{}
{**************************************************************

CHECK SYMBOL BOUNDING BOX SET

Checks if the symbol bounding box has been previously set.

**************************************************************}

function sboundset: boolean;

begin

   sboundset := curwin^.cs^.sbs

end;
{}
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
{}
{**************************************************************

REDRAW SCREEN

Clears the active area, and draws all figures onscreen. Also
replaces any in-progress figures. Also updates the target 
display. 
May be used to refresh "over" an existing screen.

**************************************************************}

procedure redraw;

var i: lininx; { index for line save }

begin

   rescur; { remove cursor }
   block(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y, 
         curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, white); { clear active area }
   { draw active area }
   plc10sgrid; { update line grid array }
   plcgrid; { update dot grid array }
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
{}
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
{}
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
{}
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
      dispose(p);} { dispose head entry }
      p := p1 { set next entry }

   end

end;

begin

   { dispose of all layers }
   for li := ltcell to ltwell do dumpdraw(curwin^.cs^.dl[li]);
   while curwin^.cs^.nl <> nil do begin { remove node entries }

      n := curwin^.cs^.nl^.next; { save next entry }
      dispose(curwin^.cs^.nl);} { dispose head entry }
      curwin^.cs^.nl := n { set next entry }

   end;
   while curwin^.cs^.bl <> nil do begin { remove bus entries }

      b := curwin^.cs^.bl^.next; { save next entry }
      dispose(curwin^.cs^.bl);} { dispose head entry }
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
{}
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
{}
{**************************************************************

PLACE CHILD WINDOW

Places, or replaces, a child window in a parent. The screen
viewport of the given child window is set up to occupy the 
given retangle in the parent. The rectangle is given in
parent real coordinates.

**************************************************************}

procedure plcwin(master, child: viewport;  { windows }
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
{}
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
   wp^.wv.r.e.x := wp^.wv.v.e.x-wp^.wv.s.x;
   wp^.wv.r.e.y := wp^.wv.v.e.y-wp^.wv.s.y;
   wp^.wv.s.x := 1; { set no scaling }
   wp^.wv.s.y := 1;
   wp^.wv.m.x := 1;
   wp^.wv.m.y := 1;
   wp^.wv.c := wp^.wv.v; { set clipping to window }
   { find client area within frame }
   wp^.cr.s.x := wp^.wv.r.s.x+2+5+2;
   wp^.cr.s.y := wp^.wv.r.s.y+2+5+2;
   wp^.cr.e.x := wp^.wv.r.e.x-2-5-2;
   wp^.cr.e.y := wp^.wv.r.e.y-2-5-2;
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
   frame(wp^.wv, wp^.wv.r.s.x+2+5, wp^.wv.r.s.y+2+5, 
         wp^.wv.r.e.x-2-5, wp^.wv.r.e.y-2-5,
         wp^.sc, wp^.lc, wp^.sc, wp^.lc);
   { draw control, move, min and max button frames }
   line(wp^.wv, wp^.wv.r.s.x+2+5+2, wp^.wv.r.s.y+28, 
        wp^.wv.r.e.x-2-5-2, wp^.wv.r.s.y+28, wp^.sc);
   line(wp^.wv, wp^.r.s.x+2+5+2, wp^.wv.r.s.y+29, 
        wp^.wv.r.e.x-2-5-2+1, wp^.wv.r.s.y+29, wp^.lc);
   line(wp^.wv, wp^.wv.r.s.x+28, wp^.wv.r.s.y+2+5+2,
        wp^.wv.r.s.x+28, wp^.wv.r.s.y+2+5+2+19, 
        wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+29, wp^.wv.r.s.y+2+5+2,
        wp^.wv.r.s.x+29, wp^.wv.r.s.y+2+5+2+19+1, 
        wp^.lc);
   frame(wp^.wv, wp^.wv.r.s.x+2+5+2+2, wp^.wv.r.s.y+2+5+2+6,
         wp^.wv.r.s.x+2+5+2+19-3, wp^.wv.r.s.y+2+5+2+6+7-1,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-29, wp^.wv.r.s.y+2+5+2,
        wp^.wv.r.e.x-29, wp^.wv.r.s.y+2+5+2+19, 
        wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-28, wp^.wv.r.s.y+2+5+2,
        wp^.wv.r.e.x-28, wp^.wv.r.s.y+2+5+2+19+1, 
        wp^.lc);
   if button[bmax].act then { button active }
      frame(wp^.wv, 
            wp^.wv.r.e.x-29+2+2, wp^.wv.r.s.y+2+5+2+2,
            wp^.wv.r.e.x-29+2+19-3, wp^.wv.r.s.y+2+5+2+2+15-1,
            wp^.sc, wp^.sc, wp^.lc, wp^.lc)
   else { button inactive }
      frame(wp^.wv,
            wp^.wv.r.e.x-29+2+2, wp^.wv.r.s.y+2+5+2+2,
            wp^.wv.r.e.x-29+2+19-3, wp^.wv.r.s.y+2+5+2+2+15-1,
            wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   line(wp^.wv, wp^.r.e.x-29-19-2, wp^.r.s.y+2+5+2,
        wp^.wv.r.e.x-29-19-2, wp^.wv.r.s.y+2+5+2+19, 
        wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-28-19-2, wp^.wv.r.s.y+2+5+2,
        wp^.wv.r.e.x-28-19-2, wp^.wv.r.s.y+2+5+2+19+1, 
        wp^.lc);
   frame(wp^.wv, 
         wp^.wv.r.e.x-29-19+6, wp^.wv.r.s.y+2+5+2+6,
         wp^.wv.r.e.x-29-19+19-7, wp^.wv.r.s.y+2+5+2+6+7-1,
         wp^.lc, wp^.lc, wp^.sc, wp^.sc);
   { place move bar breaks }
   { left }
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y+28,
        wp^.wv.r.s.x+2+5-1, wp^.wv.r.s.y+28, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.s.y+29,
        wp^.wv.r.s.x+2+5, wp^.wv.r.s.y+29, wp^.lc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.e.y-29,
        wp^.wv.r.s.x+2+5-1, wp^.wv.r.e.y-29, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x, wp^.wv.r.e.y-28,
        wp^.wv.r.s.x+2+5, wp^.wv.r.e.y-28, wp^.lc);
   { right }
   line(wp^.wv, wp^.wv.r.e.x-2-5+1, wp^.wv.r.s.y+28,
        wp^.wv.r.e.x, wp^.wv.r.s.y+28, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-2-5+1, wp^.wv.r.s.y+29,
        wp^.wv.r.e.x, wp^.wv.r.s.y+29, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-2-5+1, wp^.wv.r.e.y-29,
        wp^.wv.r.e.x, wp^.wv.r.e.y-29, wp^.sc);
   line(wp^.wv, wp^.r.e.x-2-5+1, wp^.wv.r.e.y-28,
        wp^.wv.r.e.x, wp^.wv.r.e.y-28, wp^.lc);
   { top }
   line(wp^.wv, wp^.wv.r.s.x+28, wp^.wv.r.s.y,
        wp^.wv.r.s.x+28, wp^.wv.r.s.y+2+5-1, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+29, wp^.wv.r.s.y,
        wp^.wv.r.s.x+29, wp^.wv.r.s.y+2+5, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-29, wp^.wv.r.s.y,
        wp^.wv.r.e.x-29, wp^.wv.r.s.y+2+5-1, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-28, wp^.wv.r.s.y,
        wp^.wv.r.e.x-28, wp^.wv.r.s.y+2+5, wp^.lc);
   { bottom }
   line(wp^.wv, wp^.wv.r.s.x+28, wp^.wv.r.e.y,
        wp^.wv.r.s.x+28, wp^.wv.r.e.y-2-5+1, wp^.sc);
   line(wp^.wv, wp^.wv.r.s.x+29, wp^.wv.r.e.y,
        wp^.wv.r.s.x+29, wp^.wv.r.e.y-2-5+1, wp^.lc);
   line(wp^.wv, wp^.wv.r.e.x-29, wp^.wv.r.e.y,
        wp^.wv.r.e.x-29, wp^.wv.r.e.y-2-5+1, wp^.sc);
   line(wp^.wv, wp^.wv.r.e.x-28, wp^.wv.r.e.y,
        wp^.wv.r.e.x-28, wp^.wv.r.e.y-2-5+1, wp^.lc);
   { place window title, centered in move bar }
   sl := ttllen; { set maximum }
   while (sl > 1) and (s[sl] = ' ') do sl := sl - 1;
   l := 0; { clear length }
   { find total length }
   for i := 1 to sl do l := l+alphal[ord(s[i])]+1;
   { find center of string }
   x := (wp^.wv.r.s.x+30+
         (((wp^.wv.r.e.x-30-21)-(wp^.wv.r.s.x+30)) div 2)) 
        -(l div 2);
   for i := 1 to sl do begin

      setchr(wp^.wv, x, wp^.wv.r.s.y+2+5+2+4, s[i], black);
      x := x + alphal[ord(s[i])]+1 { next collumn }

   end
   
end;
{}
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
   curwin^.rm.s.x := curwin^.wv.cr.e.x;
   repeat { menu fits }

      { set target area }
      curwin^.tr.s.x := curwin^.rm.s.x;
      curwin^.tr.s.y := curwin^.wv.cr.s.y+19+2+4;
      curwin^.tr.e.x := curwin^.wv.cr.e.x-4;
      curwin^.tr.e.y := curwin^.tr.s.y+100;
      { automatically arrange top side buttons }
      arrbutt(curwin^.wv.cr.s.x+4, 
              curwin^.wv.cr.s.y+19+2+4,
              curwin^.rm.s.x-5,
              curwin^.wv.cr.e.y-4);
      { automatically arrange right side buttons }
      marginr(curwin^.wv.cr.e.x-4,
              curwin^.tr.e.y+1+4,
              curwin^.wv.cr.e.y-4,
              curwin^.wv.cr.s.x+4);
      { set active area }
      curwin^.ar.s.x := curwin^.wv.cr.s.x+4;
      curwin^.ar.s.y := curwin^.tm.e.y+1+4;
      curwin^.ar.e.x := curwin^.rm.s.x-1-4;
      curwin^.ar.e.y := curwin^.wv.cr.e.y-4

   until (curwin^.tm.e.x <= curwin^.rm.s.x);
   arrbutr;
   { find aspect angle }
   curwin^.aa := arctan((curwin^.ar.e.x-curwin^.ar.s.x)/
                        (curwin^.ar.e.y-curwin^.ar.s.y));
   { set target viewport }
   plcwin(curwin^.wv, curwin^.tv,
          curwin^.tr.s.x, curwin^.tr.s.y,
          curwin^.tr.e.x, curwin^.tr.e.y);
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
         updbut(curwin^.wv, b); { update }
   dispcell { display cell in edit }
   
end;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
{**************************************************************

SET LINE LIMIT MODE

Sets the line limit to 90, 45 or any. The button activated is
the current one.

**************************************************************}

procedure setllim;

begin

   if (curbut in [b90, b45, bany]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      butina(b90); { set buttons inactive }
      butina(b45);
      butina(bany);
      butact(curbut)

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET TRANSFORMATION MODE

Registers the current transform mode.

**************************************************************}

procedure settrm;

begin

   if not button[birmir].act then begin { unmirrored figures }

      if button[bir0].act then trnfrm := rm0 { 0 deg }
      else if button[bir90].act then trnfrm := rm90 { 90 deg }
      else if button[bir180].act then trnfrm := rm180 { 180 deg }
      else trnfrm := rm270 { 270 deg }

   end else begin { mirrored figures }

      if button[bir0].act then trnfrm := rmm0 { 0 deg }
      else if button[bir90].act then trnfrm := rmm90 { 90 deg }
      else if button[bir180].act then trnfrm := rmm180 { 180 deg }
      else trnfrm := rmm270 { 270 deg }

   end

end;
{}
{**************************************************************

SET PLACEMENT MODE MIRROR

Sets mirrored as the current placement mode.

**************************************************************}

procedure setmirm;

begin

   if (curbut = birmir) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      if button[birmir].act then butina(birmir) { turn mode off }
      else butact(birmir); { turn mode on }
      settrm { set transform mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET ROTATION MODE

Sets the current rotation mode.

**************************************************************}

procedure setrot;

begin

   if (curbut in [bir90, bir180, bir270, bir0]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      butina(bir90); { clear the other rotates }
      butina(bir180); 
      butina(bir270);
      butina(bir0);
      butact(curbut); { activate our button }
      settrm { set transform mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

LINE, BOLD LINE, WIRE OR BUS 

Handles the mode, setup and entry of these objects.

**************************************************************}

procedure doline;

var l:      drwptr; { line entry }
    i:      btsinx;
    p:      point;
    xd, yd: integer;  
    el:     boolean; { line was entered }

begin

   el := false; { set no line entered }
   if (curbut in [bline, bbline, bwire, bbus]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { mark line mode }
      stopact; { stop all modes }
      butact(curbut); { set line mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bline, bbline, bwire, bbus]) and 
               inactive(cur) and
               (puck.b[2].a or puck.b[1].a or (puck.b[1].d and puck.b[1].dg)) then begin 

      { enter line }
      setend; { make sure end is established }
      cruler; { clear ruler }
      new(l); { get new draw entry }
      { set type }
      if drmbut = bline then l^.typ := tline
      else if drmbut = bbline then l^.typ := tbline
      else if drmbut = bwire then l^.typ := twire
      else l^.typ := tbus;
      if drmbut = bwire then begin { wire }

         l^.w.s := str; { place coordinates }
         l^.w.e := endp;
         { rationalize line }
         ratlin(l^.w.s.x, l^.w.s.y, l^.w.e.x, l^.w.e.y);

      end else if drmbut = bbus then begin

         l^.bs.l.s := str; { place coordinates }
         l^.bs.l.e := endp;
         { rationalize line }
         ratlin(l^.bs.l.s.x, l^.bs.l.s.y, l^.bs.l.e.x, l^.bs.l.e.y);

      end else begin

         l^.l.s := str; { place coordinates }
         l^.l.e := endp;
         { rationalize line }
         ratlin(l^.l.s.x, l^.l.s.y, l^.l.e.x, l^.l.e.y);

      end;
      l^.cl := black; { set color }
      setbound(str.x, str.y); { modify bounding box }
      setbound(endp.x, endp.y);
      setsbound(str.x, str.y); { modify symbol bounding box }
      setsbound(endp.x, endp.y);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      lindwn := false; { since we have overwritten saved line }
      if drmbut = bwire then begin { link in wire }

         rescur; { lift cursor }
         lnkwire(l); 
         setcur { drop cursor }

      end else if drmbut = bbus then begin { link in bus }

         rescur; { lift cursor }
         lnkbus(l); 
         setcur { drop cursor }

      end;
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      { display node and ordinal }
      if drmbut = bwire then begin

         { place node name in display }
         button[bnamev].s := l^.nh^.name; { place node name }
         updbut(bnamev); { update }
         { place ordinal in display }
         intstr(l^.nh^.nord, button[bnord].s); { place ordinal }
         trmzer(button[bnord].s); { trim zeros }
         { move back }
         for i := 1 to 4 do 
            button[bnord].s[i] := button[bnord].s[i+4];
         updbut(bnord) { update }

      end else if drmbut = bbus then begin

         { place node name in display }
         button[bnamev].s := l^.bs.bh^.name; { place bus name }
         updbut(bnamev); { update }
         { clear ordinal }
         button[bnord].s := '        '; 
         updbut(bnord) { update }

      end;
      drmbut := bnull; { reset mode }
      el := true { set line was entered }

   end; 
   if inactive(cur) and (puck.b[1].a or (puck.b[2].a and not el)) then begin 

      { begin line }
      { find real position }
      p := cur;
      realc(p, curwin^.cs^.vp); { convert coordinates }
      if el then
         { line previously entered, set for continuation }
         str := endp { set start of line to old end }
      else { new line }
         str := p; { set start of line }
      tstr := str; { save as true start }
      snapto(str.x, str.y); { snap that }
      setend; { set up end }
      rescur; { remove cursor }
      setline; { set line to screen }
      setcur; { replace cursor }
      { set draw mode }
      if button[bline].act then drmbut := bline
      else if button[bbline].act then drmbut := bbline
      else if button[bwire].act then drmbut := bwire
      else if button[bbus].act then drmbut := bbus;
      updrul { update ruler }

   end;
{   resptr { reset buttons }

end;
{}
{**************************************************************

BOX, BOLDBOX

Handles the box draw mode. Handles the activation of the button,
the start and cursor draw, and the box entry.

**************************************************************}

procedure dobox;

var l:              drwptr; { line entry }
    x1, y1, x2, y2: integer;

begin

   if (curbut in [bbox, bbbox]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { mark box mode }
      stopact; { stop all modes }
      butact(curbut); { set line mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bbox, bbbox]) and inactive(cur) and
               (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
                (puck.b[2].d and puck.b[2].dg)) then begin 

      { enter box }
      endp := cur; { make sure end is established }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y);
      cruler; { clear ruler }
      new(l); { get new draw entry }
      if drmbut = bbox then l^.typ := tbox { set type }
      else l^.typ := tbbox;
      l^.b.s.x := str.x; { place coordinates }
      l^.b.s.y := str.y;
      l^.b.e.x := endp.x;
      l^.b.e.y := endp.y;
      { rationalize it }
      ratbox(l^.b.s.x, l^.b.s.y, l^.b.e.x, l^.b.e.y);
      l^.cl := black; { set color }
      setbound(l^.b.s.x, l^.b.s.y); { modify bounding box }
      setbound(l^.b.e.x, l^.b.e.y);
      setsbound(l^.b.s.x, l^.b.s.y); { modify symbol bounding box }
      setsbound(l^.b.e.x, l^.b.e.y);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      boxdwn := false; { since we have overwritten box }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      drmbut := bnull { reset line mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin 

      { begin box }
      str := cur; { set start of box }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      tstr := str; { save as true start }
      snapto(str.x, str.y); { snap that }
      endp := str; { set end of box }
      rescur; { remove cursor }
      setbox; { set line to screen }
      zruler; { update ruler }
      setcur; { replace cursor }
      if button[bbox].act then drmbut := bbox { set box mode }
      else drmbut := bbbox

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

CIRCLE

Handles the circle draw. The button is turned on, or the circle
is started, or the circle is entered.

**************************************************************}

procedure docircle;

var l: drwptr; { line entry }

begin

   if (curbut = bcircle) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set circle mode }
      stopact; { stop all modes }
      butact(bcircle); { set circle mode active }
      modbut := bcircle;
      dsmbut := bcircle

   end else if (drmbut = bcircle) and inactive(cur) and
      (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
       (puck.b[2].d and puck.b[2].dg)) then begin { circle in progress }

      { enter circle }
      str := cur; { make sure end is established }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      { find radius }
      rad := dist(cen.x, cen.y, str.x, str.y);
      str.x := cen.x; { project to x axis }
      str.y := cen.y + rad;
      snapto(str.x, str.y);
      { recalculate radius }
      rad := abs(str.y-cen.y);
      new(l); { get new draw entry }
      l^.typ := tarc; { set type }
      l^.a.c.x := cen.x; { place parameters }
      l^.a.c.y := cen.y;
      l^.a.s.x := str.x; 
      l^.a.s.y := str.y;
      l^.a.e.x := str.x-1;
      l^.a.e.y := str.y;
      l^.a.r := rad;
      l^.cl := black; { set color }
      setbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r); { modify bounding box }
      setbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      { modify symbol bounding box }
      setsbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r);
      setsbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      cirdwn := false; { since we have overwritten circle }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      drmbut := bnull; { reset line mode }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin 

      { start circle }
      cen := cur; { set center of circle }
      realc(cen, curwin^.cs^.vp); { convert coordinates }
      tcen := cen; { save true center }
      snapto(cen.x, cen.y); { snap that }
      str := cen; { set start and end points }
      rad := 1; { set single length radius }
      rescur; { remove cursor }
      setcircle; { set line to screen }
      setcur; { replace cursor }
      drmbut := bcircle { set circle mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

ARC

Handles the arc draw mode. The button is activated, and the 
arc started, then the final arc registered.

**************************************************************}

procedure doarc;

var l:                         drwptr; { line entry }
    sx, sy, ex, ey, cx, cy, r: integer;

begin

   if (curbut = barc) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set arc mode }
      stopact; { stop all modes }
      butact(barc); { set arc mode active }
      modbut := barc;
      dsmbut := barc

   end else if (drmbut = barc) and inactive(cur) and arcsph and
               (puck.b[1].a or puck.b[2].a) then begin

      { enter arc }
      new(l); { get new draw entry }
      l^.typ := tarc; { set type }
      l^.a.c.x := cen.x; { place parameters }
      l^.a.c.y := cen.y;
      l^.a.s.x := str.x; 
      l^.a.s.y := str.y;
      l^.a.e.x := endp.x;
      l^.a.e.y := endp.y;
      l^.a.r := rad;
      l^.cl := black; { set color }
      setbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r); { modify bounding box }
      setbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      { modify symbol bounding box }
      setsbound(l^.a.c.x-l^.a.r, l^.a.c.y-l^.a.r);
      setsbound(l^.a.c.x+l^.a.r, l^.a.c.y+l^.a.r);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur;  { replace cursor }
      arcdwn := false; { since we have overwritten arc }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      drmbut := bnull { reset mode }

   end else if (drmbut = barc) and inactive(cur) and
               (puck.b[1].a or puck.b[2].a or (puck.b[1].d and puck.b[1].dg) or
                (puck.b[2].a and puck.b[2].dg)) then begin

      { begin arc second phase }
      endp := cur; { set end of arc }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y); { snap to location }
      arcflat := true; { set flat arc }
      arcsph := true { set arc 2nd phase }

   end else if inactive(cur) and (puck.b[1].a or puck.b[2].a) then begin { in active area }

      str := cur; { set start of arc }
      realc(str, curwin^.cs^.vp); { convert coordinates }
      tstr := str; { save as true start }
      endp := str; { save as end }
      snapto(str.x, str.y); { snap to location }
      rescur; { remove cursor }
      setline; { set flat arc (line) to screen }
      setcur; { replace cursor }
      arcflat := true; { set flat arc }
      arcsph := false; { set 1st phase }
      drmbut := barc { set arc mode }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TEXT

Handles text entry. The button is turned on as activated.
The text entry cursor is placed on an active area click,
and any characters typed on the keyboard are entered at that
point (independent of the cursor).

**************************************************************}

procedure dotext;

begin

   if (curbut = btext) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set text mode }
      stopact; { stop all modes }
      butact(btext); { set text mode active }
      modbut := btext;
      dsmbut := curbut

   end else if inactive(cur) and (modbut = btext) and
               (puck.b[1].a or puck.b[2].a) then begin

      rescur; { remove cursor }
      if drmbut = btext then restcur; { remove present text cursor }
      { set rotation status }
      textrot := trnfrm in [rm90, rm270, rmm90, rmm270];
      tcur := cur; { save as text entry cursor }
      realc(tcur, curwin^.cs^.vp); { convert coordinates }
      snapto(tcur.x, tcur.y); { snap coordinates }
      settcur; { set text cursor }
      drmbut := btext; { set text entry in progress }
      new(texttop); { get new draw entry }
      texttop^.typ := tchar; { set type }
      texttop^.c.r.s.x := tcur.x; { place coordinates }
      if textrot then { rotated }
         texttop^.c.r.s.y := tcur.y
      else { normal }
         texttop^.c.r.s.y := tcur.y-chrhdt*curwin^.cs^.ts;
      texttop^.c.s := curwin^.cs^.ts; { place current scale }
      texttop^.cl := black; { set color }
      { set rotation mode }
      if textrot then texttop^.rm := rm90 else texttop^.rm := rm0;
      texttop^.c.l := nil; { clear character list }
      setcur { replace cursor }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

ENTER TEXT CHARACTER

Places a single vector character.

**************************************************************}

procedure enttext(c: char);

var cp, cp1: chrptr;

begin

   if ord(c) >= 128 then c := chr(ord(c)-128); { remove parity bit }
   if c >= ' ' then 
      begin { valid char }
   
      rescur; { remove cursor }
      restcur; { remove text cursor }
      { place character } 
      if c <> ' ' then begin

         if textrot then { rotated }
            vchar(tcur.x, tcur.y, c, curwin^.cs^.ts, 
                  black, textrot, curwin^.cs^.vp.v)
         else { normal }
            vchar(tcur.x, tcur.y-chrhdt*curwin^.cs^.ts, c, curwin^.cs^.ts, 
                  black, textrot, curwin^.cs^.vp.v)

      end;
      if texttop^.c.l = nil then begin { first character to place }

         new(texttop^.c.l); { get character entry }
         cp := texttop^.c.l { index }

      end else begin { search for end }

         cp := texttop^.c.l; { index top of character list }
         { search end }
         while cp^.next <> nil do cp := cp^.next;
         new(cp^.next); { allocate entry }
         cp := cp^.next { index }

      end;
      cp^.next := nil; { clear next }
      cp^.c := c; { place character }
      { update bounds for character }
      if textrot then begin { rotated }

         texttop^.c.r.e.x := tcur.x+chrhdt*curwin^.cs^.ts;
         texttop^.c.r.e.y := tcur.y+chrwdt*curwin^.cs^.ts

      end else begin { normal }

         texttop^.c.r.e.x := tcur.x+chrwdt*curwin^.cs^.ts;
         texttop^.c.r.e.y := tcur.y

      end;
      { move cursor to next position (with intercharacter spacing ) }
      if textrot then { rotated text }
         tcur.y := tcur.y+chrwdt*curwin^.cs^.ts+chrspc*curwin^.cs^.ts
      else { normal text }
         tcur.x := tcur.x+chrwdt*curwin^.cs^.ts+chrspc*curwin^.cs^.ts;
      settcur; { reset text cursor }
      setcur { reset cursor }

   end else if c = chr(8) then begin { erase last character }

      if texttop^.c.l <> nil then begin { text string not empty }

         rescur; { remove cursor }
         restcur; { remove text cursor }
         cp := texttop^.c.l; { index top of character list }
         { search end }
         while cp^.next <> nil do cp := cp^.next;
         { move cursor back to last position }
         if textrot then { rotated text }
            tcur.y := tcur.y-chrwdt*curwin^.cs^.ts-chrspc*curwin^.cs^.ts
         else { normal text }
            tcur.x := tcur.x-chrwdt*curwin^.cs^.ts-chrspc*curwin^.cs^.ts;
         if cp^.c <> ' ' then begin
    
            if textrot then begin { rotated }

               vchar(tcur.x, tcur.y, cp^.c, curwin^.cs^.ts, 
                     white, textrot, curwin^.cs^.vp.v);
               rregion(tcur.x, tcur.y, 
                       tcur.x+chrhdt*curwin^.cs^.ts, 
                       tcur.y+chrwdt*curwin^.cs^.ts)

            end else begin { normal }

               vchar(tcur.x, tcur.y-chrhdt*curwin^.cs^.ts, cp^.c, 
                     curwin^.cs^.ts, white, textrot, curwin^.cs^.vp.v);
               rregion(tcur.x, tcur.y-chrhdt*curwin^.cs^.ts, 
                       tcur.x+chrwdt*curwin^.cs^.ts, 
                       tcur.y)

            end

         end;
         { remove character from list }
         if cp = texttop^.c.l then texttop^.c.l := nil 
         else begin 

            cp1 := texttop^.c.l; { index top entry }
            { find last entry }
            while cp1^.next <> cp do cp1 := cp1^.next;
            cp1^.next := nil { remove }

         end;
         settcur; { reset text cursor }
         setcur { reset cursor }

      end

   end else if c = chr(13) then begin { terminate mode }

      rescur; { remove cursor }
      restcur; { remove text cursor }
      if texttop^.c.l <> nil then begin { not empty }

         texttop^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
         curwin^.cs^.dl[ltfig] := texttop;
         setbound(texttop^.c.r.s.x, texttop^.c.r.s.y); { set bounds }
         setbound(texttop^.c.r.e.x, texttop^.c.r.e.y); 
         setsbound(texttop^.c.r.s.x, texttop^.c.r.s.y); { set symbol bounds }
         setsbound(texttop^.c.r.e.x, texttop^.c.r.e.y);
         chktar; { check target change }

      end;
      setcur; { replace cursor }
      drmbut := bnull { cancel text mode }

   end

end;
{}
{**************************************************************

JUNCTION

Handle junction mode. The button is turned on. The connector is
entered at the current location.

**************************************************************}

procedure junction;

var p:  drwptr;
    i:  btsinx;
    rp: point;

begin

   if (curbut = bjunction) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set junction mode }
      stopact; { stop all modes }
      butact(bjunction); { set junction mode active }
      modbut := bjunction;
      dsmbut := bjunction

   end else if inactive(cur) and (modbut = bjunction) and
               (puck.b[1].a or puck.b[2].a) then begin

      { enter junction }
      rp := cur; { find location }
      realc(rp, curwin^.cs^.vp); { convert coordinates }
      snapto(rp.x, rp.y);
      plcjun(rp.x, rp.y, p); { place new junction }
      rescur; { remove cursor }
      drwfig(p, p^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur; { replace cursor }
      lnkjun(p); { place junction at location }
      { place node name in display }
      button[bnamev].s := p^.nh^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      intstr(p^.nh^.nord, button[bnord].s); { place ordinal }
      trmzer(button[bnord].s); { trim zeros }
      { move back }
      for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
      updbut(bnord) { update }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

CONNECTOR

Handles the connector mode. If the button is activated, the 
connector mode is entered. If but1 or but2 is entered in the
active region during connector mode, a connector is placed at
that position.

**************************************************************}

procedure connect;

var l: drwptr;
    i: btsinx;
    p: point;

begin

   if (curbut = bconnect) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set connector mode }
      stopact; { stop all modes }
      butact(bconnect); { set connector mode active }
      modbut := bconnect;
      dsmbut := bconnect

   end else if inactive(cur) and (modbut = bconnect) and
               (puck.b[1].a or puck.b[2].a) then begin

      p := cur; { find location }
      realc(p, curwin^.cs^.vp); { convert coordinates }
      snapto(p.x, p.y);
      new(l); { get new draw entry }
      l^.typ := tconnect; { set type }
      l^.j.x := p.x; { place coordinates }
      l^.j.y := p.y;
      l^.cl := black; { set color }
      l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := l;
      { modify bounding box }
      setbound(l^.j.x-curwin^.cs^.cs, l^.j.y-curwin^.cs^.cs);
      setbound(l^.j.x+curwin^.cs^.cs-1, l^.j.y+curwin^.cs^.cs-1);
      chktar; { check target change }
      rescur; { remove cursor }
      drwfig(l, l^.cl, false, ltfig, curwin^.cs^.vp.v); { draw }
      setcur; { replace cursor }
      lnkjun(l); { place junction at location }
      { place node name in display }
      button[bnamev].s := l^.nh^.name; { place node name }
      updbut(bnamev); { update }
      { place ordinal in display }
      intstr(l^.nh^.nord, button[bnord].s); { place ordinal }
      trmzer(button[bnord].s); { trim zeros }
      { move back }
      for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
      updbut(bnord) { update }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SUBCELL

Handles the subcell placement mode. Handles the activation of
the button, the sizing of the cursor box, and the entry of the
cell.

**************************************************************}

procedure docell;

var l:  drwptr; { line entry }
    sp: shtptr;
    t:  integer; 

begin

   if (curbut = bplsch) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { schematic placement }
      { if there is a cell to place, and placement cell is 
        selected, start now }
      if (placel <> nil) and button[bcelv].act then begin

         { cell exists }
         if placel^.schema <> nil then begin 

            { sheet exists }
            stopact; { stop all modes }
            butact(bplsch); { activate button }
            plcsiz.x := abs(placel^.schema^.bbex-placel^.schema^.bbsx)+1; 
            plcsiz.y := abs(placel^.schema^.bbey-placel^.schema^.bbsy)+1;
            if trnfrm in [rm90, rm270, rmm90, rmm270] then begin

               { swap axies for rotation }
               t := plcsiz.x; plcsiz.x := plcsiz.y; plcsiz.y := t

            end;
            str := rcur; { set start of box }
            snapto(str.x, str.y); { snap }
            { set end of box }
            endp.x := str.x+plcsiz.x;
            endp.y := str.y+plcsiz.y;
            drmbut := bplsch; { set paste mode active }
            modbut := bplsch

         end

      end

   end else if (curbut = bplsym) and 
               (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { place symbol }
      { if there is a cell to place, start now }
      if (placel <> nil) or button[bnmos].act or 
         button[bpmos].act or button[bcap].act or 
         button[bres].act or button[bdiode].act or
         button[bvdd].act or button[bvss].act then begin

         sp := nil; { preset pointer }
         if placel <> nil then sp := placel^.symbol;
         { cell exists }
         if (sp <> nil) or not button[bcelv].act then 
            begin 

            { sheet exists }
            stopact; { stop all modes }
            butact(bplsym); { activate button }
            { set dementions of box }
            if button[bcelv].act then begin

               plcsiz.x := abs(placel^.symbol^.sbbex-placel^.symbol^.sbbsx)+1; 
               plcsiz.y := abs(placel^.symbol^.sbbey-placel^.symbol^.sbbsy)+1

            end else if button[bnmos].act or button[bpmos].act then begin

               plcsiz.x := 7*1500;
               plcsiz.y := 8*1500

            end else if button[bcap].act then begin

               plcsiz.x := 4*1500;
               plcsiz.y := 5*1500
  
            end else if button[bres].act then begin

               plcsiz.x := 4*750;
               plcsiz.y := 20*750

            end else if button[bdiode].act then begin

               plcsiz.x := 4*1500;
               plcsiz.y := 8*1500
            
            end else if button[bvdd].act or button[bvss].act then begin

               plcsiz.x := 2*1500;
               plcsiz.y := 4*1500
            
            end;
            if trnfrm in [rm90, rm270, rmm90, rmm270] then begin

               { swap axies for rotation }
               t := plcsiz.x; plcsiz.x := plcsiz.y; plcsiz.y := t

            end;
            str := rcur; { set start of box }
            snapto(str.x, str.y); { snap }
            { set end of box }
            endp.x := str.x+plcsiz.x;
            endp.y := str.y+plcsiz.y;
            drmbut := bplsym; { set paste mode active }
            modbut := bplsym

         end

      end

   end else if (curbut = bplace) and 
               (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { place layout }
      { if there is a cell to place, and placement cell is 
        selected, start now }
      if (placel <> nil) and button[bcelv].act then begin

         { cell exists }
         if placel^.layout <> nil then begin 

            { sheet exists }
            stopact; { stop all modes }
            butact(bplace); { activate button }
            plcsiz.x := abs(placel^.layout^.bbex-placel^.layout^.bbsx)+1; 
            plcsiz.y := abs(placel^.layout^.bbey-placel^.layout^.bbsy)+1;
            if trnfrm in [rm90, rm270, rmm90, rmm270] then begin

               { swap axies for rotation }
               t := plcsiz.x; plcsiz.x := plcsiz.y; plcsiz.y := t

            end;
            str := rcur; { set start of box }
            snapto(str.x, str.y); { snap }
            { set end of box }
            endp.x := str.x+plcsiz.x;
            endp.y := str.y+plcsiz.y;
            drmbut := bplace; { set paste mode active }
            modbut := bplace

         end

      end

   end else if (drmbut in [bplsch, bplsym, bplace]) and inactive(cur) and
               (puck.b[1].a or puck.b[2].a) then begin
   
      rescur; { remove cursor }
      resbox; { remove box cursor }
      str := rcur; { set start of cell }
      snapto(str.x, str.y); { snap }
      new(l); { get new draw entry }
      { set type }
      if button[bcelv].act then l^.typ := tcell
      else if button[bnmos].act then l^.typ := tnmos
      else if button[bpmos].act then l^.typ := tpmos
      else if button[bcap].act then l^.typ := tcap
      else if button[bres].act then l^.typ := tres
      else if button[bdiode].act then l^.typ := tdiode
      else if button[bvdd].act then l^.typ := tvdd
      else if button[bvss].act then l^.typ := tvss;
      if l^.typ = tcell then begin

         l^.cr.o.x := str.x; { place coordinates }
         l^.cr.o.y := str.y

      end else begin

         l^.o.x := str.x; { place coordinates }
         l^.o.y := str.y

      end;   
      if button[bcelv].act then { placement cell }
         if drmbut = bplsch then begin { place schematic }

            l^.cr.cp := placel^.schema;
            l^.cr.ct := ctsch

         end else if drmbut = bplsym then begin { place symbol }

            l^.cr.cp := placel^.symbol;
            l^.cr.ct := ctsym

         end else begin { place layout }

            l^.cr.cp := placel^.layout;
            l^.cr.ct := ctlay

         end;
      l^.rm := trnfrm; { set rotation mode }
      l^.cl := black; { set color }
      dointer(l); { intersect with cell }
      if l^.typ = tcell then begin { enter cell }

         l^.next := curwin^.cs^.dl[ltcell]; { enter to draw list }
         curwin^.cs^.dl[ltcell] := l

      end else begin { enter figure }

         l^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
         curwin^.cs^.dl[ltfig] := l

      end;
      setbound(str.x, str.y); { update bounds for cell }
      setsbound(str.x, str.y); { update symbol bounds for cell }
      setbound(str.x+plcsiz.x, str.y+plcsiz.y);
      setsbound(str.x+plcsiz.x, str.y+plcsiz.y);
      chktar; { check target change }
      { redraw cell region }
      frregion(str.x, str.y, str.x+plcsiz.x, str.y+plcsiz.y);
      setbox; { replace box cursor }
      setcur; { replace cursor }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

DO NEW SHEET

As newsht, but with button checks.

**************************************************************}

procedure donew;

begin

   if (curbut = bnew) and (puck.b[1].a or puck.b[2].a) then begin

      butact(bnew); { activate button }
      newsht; { clear sheet }
      butina(bnew)

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

START EDIT

Starts off most edits. The contents of the current button is
saved, the button is set in edit mode, and the edit started.

**************************************************************}

procedure stredt; 

begin

   if (curbut in [bjuncv, bconnv, bdotsv, blinev, btsizv,
                  bnamev, bnord, bfname, bcname, borgxv, borgyv,
                  bsclv, bmaxx, bmaxy, boffx, boffy]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      canact; { cancel other activity }
      butsav := button[curbut].s; { save button }
      edtbut(button[curbut]); { kick off edit }
      cedbut := curbut { set edit in progress }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

PERFORM EDIT FILENAME

Performs each character placement of this edit. Also handles 
termination and activation of this field.

**************************************************************}

procedure dofiln(c, cs: char);

begin

   edit(button[bfname], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin

      { copy to cell name (as the default cell name) }
      button[bcname].s := button[bfname].s;
      cellst^.name := button[bcname].s; { name top cell }
      updbut(bcname); { update }
      cedbut := bnull { end edit }

   end

end;
{}
{**************************************************************

EDIT CELLNAME

Starts off the edit of the cellname field.

**************************************************************}

procedure edtcel; 

begin

   if button[bfname].s <> '        ' then
      stredt { start edit }

end;
{}
{**************************************************************

PERFORM EDIT CELLNAME

Performs each character placement of this edit. Also handles 
termination and activation of this field.

**************************************************************}

procedure doceln(c, cs: char);

var p: celptr;

begin

   edit(button[bcname], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin

      p := cellst; { index top cell }
      { search for cell match }
      while (p^.next <> nil) and (p^.name <> button[bcname].s) do
         p := p^.next;
      if p^.name <> button[bcname].s then begin 

         { create new cell }
         new(p^.next); { create new cell }
         p := p^.next; { index it }
         p^.name := button[bcname].s; { place name }
         p^.symbol := nil; { clear lists }
         p^.schema := nil; 
         p^.layout := nil;
         p^.simulate := nil;
         p^.next := nil

      end;
      curwin^.cc := p; { place cell as current }
      celstk := nil; { clear cell stack }
      dispcell; { display current cell }
      cedbut := bnull; { end edit }

   end

end;
{}
{**************************************************************

PERFORM EDIT NODENAME

Performs each character placement of this edit. Also handles 
termination and activation of this field.

**************************************************************}

procedure donnam(c, cs: char);

begin

   edit(button[bnamev], edtpos, c, cs); { perform edit }
   if c = chr(13) then cedbut := bnull; { end edit }

end;
{}
{**************************************************************

PERFORM EDIT NODE ORDINAL

Performs each character placement of this edit. Also handles 
termination and activation of this field.

**************************************************************}

procedure donord(c, cs: char);

var n: integer;
    i: btsinx;
    e: boolean; { error flag }

begin

   edit(button[bnord], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { end edit }

      getint(button[bnord], n, e); { get ordinal value }
      if not e then begin { value ok }

         { place ordinal in display }
         intstr(n, button[bnord].s); { place ordinal }
         trmzer(button[bnord].s); { trim zeros }
         { move back }
         for i := 1 to 4 do button[bnord].s[i] := button[bnord].s[i+4];
         { refresh button }
         updbut(blinev); { update }
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT DOT SPACING

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dodotg(c, cs: char);

var r:  real; 
    ds: integer;
    e:  boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(dftdg*pixsiz, button[bdotsv].s);
      updbut(bdotsv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[bdotsv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bdotsv], r, e); { parse number }
      if not e then begin { value ok }
 
         realstr(r, button[bdotsv].s); { place value }
         { refresh button }
         updbut(bdotsv); { update }
         ds := round(r/pixsiz); { find number of vpixels per }
         if ds <> curwin^.cs^.ds then begin { is different }

            curwin^.cs^.ds := ds; { place size }
            rescur; { reset cursor }
            if button[bdots].act then { grid active } 
               dogrid(dgridsx, dgridsy, white); { white out dots }
            plcgrid; { place dot grid }
            if button[bdots].act then { grid is on, redo }
               drwfigs; { redraw all figures }
            setcur { set cursor }

         end;
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT LINE SPACING

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doling(c, cs: char);

var r:  real; 
    ls: integer;
    e:  boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      { set default line grid size }
      realstr(dftlg*pixsiz, button[blinev].s); 
      updbut(blinev); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[blinev], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[blinev], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[blinev].s); { place value }
         { refresh button }
         updbut(blinev); { update }
         ls := round(r/pixsiz); { find number of vpixels per }
         if ls <> curwin^.cs^.ls then begin { is different }

            curwin^.cs^.ls := ls; { place size }
            rescur; { remove cursor }
            if button[blines].act then { grid is on }
               do10sgrid(white); { white out lines }
            plc10sgrid; { place line grid }
            if button[blines].act then { grid is on }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end;
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT ORIGIN X

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doorgx(c, cs: char);

var r: real; 
    e: boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(0*pixsiz, button[borgxv].s);
      updbut(borgxv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[borgxv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[borgxv], r, e); { parse number }
      { set new x }
      if not e then begin { value ok }

         newview(round(r/pixsiz), curwin^.cs^.vp.r.s.y, curwin^.cs^.vp.s.x);
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT ORIGIN Y

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doorgy(c, cs: char);

var r: real; 
    e: boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(0*pixsiz, button[borgyv].s);
      updbut(borgyv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[borgyv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[borgyv], r, e); { parse number }
      { set new y }
      if not e then begin { value ok }

         newview(curwin^.cs^.vp.r.s.x, round(r/pixsiz), curwin^.cs^.vp.s.x);
         cedbut := bnull { end edit }
   
      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT SCALE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure doscl(c, cs: char);

var r: real; 
    i: btsinx;
    e: boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(normscale, button[bsclv].s);
      updbut(bsclv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[bsclv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bsclv], r, e); { parse number }
      { set new scale }
      if not e then begin { value ok }

         newview(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y, round(r)*scalem);
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT TEXT SIZE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dotsiz(c, cs: char);

var r: real; 
    e: boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(dftchr*4*pixsiz, button[btsizv].s);
      updbut(btsizv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[btsizv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[btsizv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[btsizv].s); { place value }
         curwin^.cs^.ts := round(r/4/pixsiz); { find number of vpixels per }
         { refresh button }
         updbut(btsizv); { update }
         cedbut := bnull { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT JUNCTION SIZE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dojsiz(c, cs: char);

var r: real; 
    e: boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(dftjun*2*pixsiz, button[bjuncv].s);
      updbut(bjuncv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[bjuncv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bjuncv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[bjuncv].s); { place value }
         curwin^.cs^.js := round(r/2/pixsiz); { find number of vpixels per }
         { refresh button }
         updbut(bjuncv); { update }
         redraw; { refresh screen }
         cedbut := bnull; { end edit }

      end

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT CONNECTOR SIZE

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure docsiz(c, cs: char);

var r: real; 
    e: boolean;

begin
   
   if c = chr(9) then begin { tab, restore default value }

      realstr(dftcon*2*pixsiz, button[bconnv].s);
      updbut(bconnv); { update }
      c := chr(0); { null input character }
      cs := chr(0)
   
   end;
   edit(button[bconnv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      getrnm(button[bconnv], r, e); { parse number }
      if not e then begin { value ok }

         realstr(r, button[bconnv].s); { place value }
         curwin^.cs^.cs := round(r/2/pixsiz); { find number of vpixels per }
         { refresh button }
         updbut(bconnv); { update }
         redraw; { redraw screen }
         cedbut := bnull; { end edit }

      end

   end

end;
{}
{**************************************************************

EDIT CURRENT PLACEMENT CELL

Starts off the edit of the placement cell field.

**************************************************************}

procedure edtcelv; 

var b: buttyp;

begin

   if (curbut = bcelv) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      canact; { cancel other activity }
      butsav := '        '; { set no save }
      placel := nil; { set no placement cell }
      { move down cell stack }
      for b := bceld downto bcela do begin

         button[b].s := button[pred(b)].s;
         updbut(b) { update }

      end;
      edtbut(button[bcelv]); { kick off edit }
      cedbut := bcelv { set edit in progress }

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT PLACEMENT CELL

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure docelv(c, cs: char);

var p: celptr;
    b: buttyp;

begin
   
   edit(button[bcelv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      cedbut := bnull; { end edit }
      p := cellst; { index top cell }
      { search for cell match }
      while (p^.next <> nil) and (p^.name <> button[bcelv].s) do
         p := p^.next;
      { set cell as current if exists }
      if p^.name = button[bcelv].s then begin

         { good cell }
         placel := p; { place cell pointer }
         { find matching cell }
         b := bcela; { index 1st button }
         while (b < bceld) and 
               (button[b].s <> button[bcelv].s) do b := succ(b);
         if button[b].s = button[bcelv].s then begin

            { matching cell, delete from queue }
            for b := b to bceld do { move buttons down }
               button[b].s := button[succ(b)].s;        
            button[bceld].s := '        '; { clear last cell }     
            for b := bcela to bceld do { refresh buttons }
               updbut(b) { update }

         end;
         butact(bcelv) { set button active }

      end else begin

         button[bcelv].s := '        '; { clear bad cell }
         updbut(b); { update }
         placel := nil

      end

   end

end;
{}
{**************************************************************

SELECT QUEUE CELL

Selects one the queue list cells, and places that as active.

**************************************************************}

procedure selcel;

var p: celptr;
    b: buttyp;
    s: butstr; 

begin
   
   if (curbut in [bcelv, bcela, bcelb, bcelc, bceld]) and 
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      s := button[curbut].s; { save our string }
      { copy up buttons underneath us }
      for b := curbut downto bcela do button[b].s := button[pred(b)].s;
      button[bcelv].s := s; { replace string }
      { refresh buttons }
      for b := bcelv to bceld do
         updbut(b); { update }
      p := cellst; { index top cell }
      { search for cell match }
      while (p^.next <> nil) and (p^.name <> button[bcelv].s) do
         p := p^.next;
      { set cell as current if exists }
      if p^.name = button[bcelv].s then placel := p 
      else begin

         button[bcelv].s := '        '; { clear bad cell }
            updbut(b); { update }
         placel := nil

      end

   end

end;
{}
{**************************************************************

EDIT CURRENT LIBRARY

Starts off the edit of the library field.

**************************************************************}

procedure edtlibv; 

var b: buttyp;

begin

   if (curbut = blibv) and (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      canact; { cancel other activity }
      butsav := '        '; { set no save }
      placel := nil; { set no placement cell }
      { move down cell stack }
      for b := blibd downto bliba do begin

         button[b].s := button[pred(b)].s;
         updbut(b) { update }

      end;
      edtbut(button[blibv]); { kick off edit }
      cedbut := blibv { set edit in progress }

   end

end;
{}
{**************************************************************

PERFORM SEQUENTIAL EDIT LIBRARY

Performs each character placement of this edit, and also handles
termination and activation of the field.

**************************************************************}

procedure dolibv(c, cs: char);

var b: buttyp;

begin
   
   edit(button[blibv], edtpos, c, cs); { perform edit }
   if c = chr(13) then begin { terminating }

      cedbut := bnull; { end edit }
      { find matching cell }
      b := bliba; { index 1st button }
      while (b < blibd) and 
            (button[b].s <> button[blibv].s) do b := succ(b);
      if button[b].s = button[blibv].s then begin

         { matching cell, delete from queue }
         for b := b to blibd do { move buttons down }
            button[b].s := button[succ(b)].s;        
         button[blibd].s := '        '; { clear last cell }     
         for b := bliba to blibd do { refresh buttons }
            updbut(b) { update }

      end

   end

end;
{}
{**************************************************************

SELECT PLACEMENT CELL

Selects the placement cell as the active cell.

**************************************************************}

procedure selplc;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      butina(bcelv); { set buttons inactive }
      butina(bnmos);
      butina(bpmos);
      butina(bcap);
      butina(bres);
      butina(bdiode);
      butina(bvdd);
      butina(bvss);
      butact(curbut)

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET VIEWS

Handles the viewer buttons. If button 1 is pressed, and a view
has been stored, that view is set current. If button 2 is
pressed, the current view is stored in that button.

**************************************************************}

procedure setview;

var i: viewinx; { index for views }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(bviewa)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sv[i].a and 
         not ((curwin^.cs^.sv[i].vp.r.s.x = curwin^.cs^.vp.r.s.x) and 
              (curwin^.cs^.sv[i].vp.r.s.y = curwin^.cs^.vp.r.s.y) and
              (curwin^.cs^.sv[i].vp.s.x = curwin^.cs^.vp.s.x)) then begin { go view }

         { button 1 down, view active, not the same old view }
         stopview; { stop motion modes }
         { activate new view }
         newview(curwin^.cs^.sv[i].vp.r.s.x, 
                 curwin^.cs^.sv[i].vp.r.s.y, 
                 curwin^.cs^.sv[i].vp.s.x); 
         setcur; { set cursor }
         modbut := dsmbut { restore any draw mode }

      end else if puck.b[2].a then begin { set view }

         butact(curbut); { activate the button }
         curwin^.cs^.sv[i].vp.r.s.x := curwin^.cs^.vp.r.s.x; { place origin }
         curwin^.cs^.sv[i].vp.r.s.y := curwin^.cs^.vp.r.s.y;
         curwin^.cs^.sv[i].vp.s.x := curwin^.cs^.vp.s.x; { place scale }
         curwin^.cs^.sv[i].vp.s.y := curwin^.cs^.vp.s.y; { place scale }
         curwin^.cs^.sv[i].a := true { set view active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET TEXT SIZES

Handles the text size buttons. If button 1 is pressed, and a size
has been stored, that size is set current. If button 2 is
pressed, the current size is stored in that button.

**************************************************************}

procedure settexts;

var i: sizeinx; { index for sizes }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(btexta)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sts[i].a then begin { activate text size }

         { button 1 down }
         rescur; { remove cursor }
         if drmbut = btext then restcur; { remove text cursor }
         curwin^.cs^.ts := curwin^.cs^.sts[i].s; { place text size }
         realstr(curwin^.cs^.ts*4*pixsiz, button[btsizv].s); { place value }
         updbut(btsizv); { update }
         if drmbut = btext then settcur; { reset text cursor }
         setcur { reset cursor }

      end else if puck.b[2].a then begin { set text size }

         butact(curbut); { activate the button }
         curwin^.cs^.sts[i].s := curwin^.cs^.ts; { save current text size }
         curwin^.cs^.sts[i].a := true { set active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET DOT GRID SIZES

Handles the dot grid size buttons. If button 1 is pressed, 
and a size has been stored, that size is set current. If button 
2 is pressed, the current size is stored in that button.

**************************************************************}

procedure setdotg;

var i:  sizeinx; { index for sizes }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(bdotsva)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sds[i].a then begin { activate grid size }
       
         if curwin^.cs^.ds <> curwin^.cs^.sds[i].s then begin { is different }

            { button 1 down }
            rescur; { remove cursor }
            curwin^.cs^.ds := curwin^.cs^.sds[i].s; { place size }
            realstr(curwin^.cs^.ds*pixsiz, button[bdotsv].s); { place value }
            updbut(bdotsv); { update }
            if button[bdots].act then { grid active } 
               dogrid(dgridsx, dgridsy, white); { white out dots }
            plcgrid; { place dot grid }
            if button[bdots].act then { grid is on, redo }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end

      end else if puck.b[2].a then begin { set dot grid size }

         butact(curbut); { activate the button }
         curwin^.cs^.sds[i].s := curwin^.cs^.ds; { save current dot grid size }
         curwin^.cs^.sds[i].a := true { set active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET LINE GRID SIZES

Handles the line grid size buttons. If button 1 is pressed, 
and a size has been stored, that size is set current. If button 
2 is pressed, the current size is stored in that button.

**************************************************************}

procedure setlineg;

var i: sizeinx; { index for sizes }

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(blineva)+1; { set the index }
      if puck.b[1].a and curwin^.cs^.sls[i].a then begin { activate grid size }

         if curwin^.cs^.ls <> curwin^.cs^.sls[i].s then begin { is different }

            { button 1 down }
            rescur; { remove cursor }
            curwin^.cs^.ls := curwin^.cs^.sls[i].s; { place size }
            realstr(curwin^.cs^.ls*pixsiz, button[blinev].s); { place value }
            updbut(blinev); { update }
            if button[blines].act then { grid is on }
               do10sgrid(white); { white out lines }
            plc10sgrid; { place line grid }
            if button[blines].act then { grid is on }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end

      end else if puck.b[2].a then begin { set line grid size }

         butact(curbut); { activate the button }
         curwin^.cs^.sls[i].s := curwin^.cs^.ls; { save current line grid size }
         curwin^.cs^.sls[i].a := true { set active }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET BLOCK SAVE

Stores or recalls a block from the block save tableu.

**************************************************************}

procedure setblk;

var i:  blkinx; { index for block stores }

{ check block list occupied }

function blkact(l: laylst): boolean;

var f:  boolean; { result }
    li: laytyp;  { layer index }

begin

   f := false; { set emtpy }
   { check any content }
   for li := ltcell to ltwell do if l[li] <> nil then f := true;
   blkact := f { return result }

end;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      i := ord(curbut)-ord(bblka)+1; { set the index }
      if puck.b[1].a and blkact(blocks[i].l) then begin { activate block save }

         savlst := blocks[i].l; { place figure list }
         namlst := blocks[i].n; { place name list }
         savb.s.x := blocks[i].sx; { place bounding box }
         savb.s.y := blocks[i].sy;
         savb.e.x := blocks[i].ex;
         savb.e.y := blocks[i].ey

      end else if puck.b[2].a then begin { save block }

         butact(curbut); { activate the button }
         blocks[i].l := savlst; { place figure list }
         blocks[i].n := namlst; { place name list }
         blocks[i].sx := savb.s.x; { place bounding box }
         blocks[i].sy := savb.s.y;
         blocks[i].ex := savb.e.x;
         blocks[i].ey := savb.e.y

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE DOT GRID

Turns the dot grid either off or on. Updates the display to
match.
Note that the dot placement array must have been previously
filled.

**************************************************************}

procedure togdot;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { toggle status }
      button[bdots].act := not button[bdots].act;
      updbut(bdots); { update button }
      if button[bdots].act then { activate grid }
         drwfigs { redraw all figures }
      else begin { deactivate grid }

         dogrid(dgridsx, dgridsy, white); { white out dots }
         drwfigs { replace figures }

      end

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE LINE GRID

Turns the line grid either off or on. Updates the display to
match.
Note that the line placement array must have been previously
filled.

**************************************************************}

procedure togline;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { toggle status }
      button[blines].act := not button[blines].act;
      updbut(blines); { update button }
      if button[blines].act then { activate grid }
         drwfigs { redraw all figures }
      else begin { deactivate grid }

         do10sgrid(white); { white out lines }
         drwfigs { replace figures }

      end;

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET SYMBOL MODE

Sets the symbol edit mode. The symbol sheet in the current cell
is set current.

**************************************************************}

procedure setsymbol;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and 
      not button[bsymbol].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smsymbol]; { set symbol screen mode }
      pixsiz := dftsiz; { set base scale }
      butact(bsymbol); { activate symbol button }
      butina(bschema); { deactivate other buttons }
      butina(blayout); 
      butina(bsimulate);
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

SET SCHEMATIC MODE

Sets the schematic edit mode. The schematic sheet in the current cell
is set current.

**************************************************************}

procedure setschema;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[bschema].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smschema]; { set schematic screen mode }
      pixsiz := dftsiz; { set base scale }
      butact(bschema); { activate schematic button }
      butina(bsymbol); { deactivate other buttons }
      butina(blayout);
      butina(bsimulate);
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

RESIZE WINDOW

Handles the resize control buttons. A cursor box is pinned 
between the cursor and the opposite corner or side of the window.
The window then is sized to fit the resulting box.

**************************************************************}

procedure resize;

{ adjust size box according to move mode }

procedure adjsiz(b: buttyp);

begin

   case b of { move button }

      { adjust size box to meet cursor }
      bmbtop:    sizb.s.y := cur.y; 
      bmbleft:   sizb.s.x := cur.x;
      bmbright:  sizb.e.x := cur.x;
      bmbbottom: sizb.e.y := cur.y;
      bmbtoplt, bmbtopll: 
         begin sizb.s.x := cur.x; sizb.s.y := cur.y end; 
      bmbtoprt, bmbtoprr: 
         begin sizb.e.x := cur.x; sizb.s.y := cur.y end;
      bmbbotlb, bmbbotll: 
         begin sizb.s.x := cur.x; sizb.e.y := cur.y end;
      bmbbotrb, bmbbotrr: 
         begin sizb.e.x := cur.x; sizb.e.y := cur.y end;

   end

end;

{ set size box to screen }

procedure setsiz;

var i: lininx;

begin

   if not blank then begin { screen not blank }

      { place box }
      i := 1;
      boxsav(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, 
             lmagenta, i)

   end

end; 

{ reset size box from screen }

procedure ressiz;

var i: lininx;

begin

   if not blank then begin { screen not blank }

      { place box }
      i := 1;
      boxrst(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, i)

   end

end; 

begin

   if modbut in [bmbtop, bmbleft, bmbright, bmbbottom,
                  bmbtoplt, bmbtopll, bmbtoprt, bmbtoprr,
                  bmbbotlb, bmbbotll, bmbbotrb, bmbbotrr] then 
      begin { in resize mode }

      if puck.b[1].a or puck.b[2].a or 
         (puck.b[1].d and puck.b[1].dg) or
         (puck.b[2].d and puck.b[2].dg) then begin 

         { resize complete }
         { resize window to box }
         rescur; { remove cursor }
         ressiz; { remove size cursor }
         { clear overlap space }
         case modbut of { move button }

            bmbtop:    if sizb.s.y > curwin^.r.s.y then
               block(screen, curwin^.r.s.x, curwin^.r.s.y, 
                     curwin^.r.e.x, sizb.s.y, bakclr);
            bmbleft:   if sizb.s.x > curwin^.r.s.x then
               block(screen, curwin^.r.s.x, curwin^.r.s.y,
                     sizb.s.x, curwin^.r.e.y, bakclr);     
            bmbright:  if sizb.e.x < curwin^.r.e.x then
               block(screen, sizb.e.x, curwin^.r.s.y, 
                     curwin^.r.e.x, curwin^.r.e.y, bakclr);
            bmbbottom: if sizb.e.y < curwin^.r.e.y then
               block(screen, curwin^.r.s.x, sizb.e.y,
                     curwin^.r.e.x, curwin^.r.e.y, bakclr);
            bmbtoplt, bmbtopll: begin 

               if sizb.s.y > curwin^.r.s.y then
                  block(screen, curwin^.r.s.x, curwin^.r.s.y, 
                        curwin^.r.e.x, sizb.s.y, bakclr);
               if sizb.s.x > curwin^.r.s.x then
                  block(screen, curwin^.r.s.x, curwin^.r.s.y,
                        sizb.s.x, curwin^.r.e.y, bakclr)

            end;     
            bmbtoprt, bmbtoprr: begin 

               if sizb.s.y > curwin^.r.s.y then
                  block(screen, curwin^.r.s.x, curwin^.r.s.y, 
                        curwin^.r.e.x, sizb.s.y, bakclr);
               if sizb.e.x < curwin^.r.e.x then
                  block(screen, sizb.e.x, curwin^.r.s.y, 
                        curwin^.r.e.x, curwin^.r.e.y, bakclr)

            end;
            bmbbotlb, bmbbotll: begin 

               if sizb.e.y < curwin^.r.e.y then
                  block(screen, curwin^.r.s.x, sizb.e.y,
                        curwin^.r.e.x, curwin^.r.e.y, bakclr);
               if sizb.s.x > curwin^.r.s.x then
                  block(screen, curwin^.r.s.x, curwin^.r.s.y,
                        sizb.s.x, curwin^.r.e.y, bakclr) 

            end;
            bmbbotrb, bmbbotrr: begin 

               if sizb.e.y < curwin^.r.e.y then
                  block(screen, curwin^.r.s.x, sizb.e.y,
                        curwin^.r.e.x, curwin^.r.e.y, bakclr);
               if sizb.e.x < curwin^.r.e.x then
                  block(screen, sizb.e.x, curwin^.r.s.y, 
                        curwin^.r.e.x, curwin^.r.e.y, bakclr)

            end

         end;
         curwin^.r := sizb; { set new window size }
         button[bmax].act := false; { deactivate max button }
         dispwin; { display new window }
         modbut := bnull { reset status }

      end else begin { resize still in progress }

         if puck.m then begin { cursor has moved }

            rescur; { remove cursor }
            ressiz; { reset size cursor }
            adjsiz(modbut); { adjust size cursor }
            setsiz; { set size cursor to screen }
            setcur; { replace cursor }

         end

      end

   end else { must be in select mode }
      if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { mark resize mode }
      sizb := curwin^.r; { set size box to window region }
      adjsiz(curbut); { adjust size cursor }
      rescur; { remove cursor }
      setsiz; { set size cursor to screen }
      setcur; { replace cursor }
      modbut := curbut

   end;
{   resptr { reset buttons }

end;
{}
{**************************************************************

MOVE WINDOW

Handles the window move button. A cursor box is pinned to the
cursor. The window is then moved to fit the resulting box.

**************************************************************}

procedure movewin;

{ set size box to screen }

procedure setbox;

var i: lininx;

begin

   if not blank then begin { screen not blank }

      { place box }
      i := 1;
      boxsav(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, 
             lmagenta, i)

   end

end; 

{ reset size box from screen }

procedure resbox;

var i: lininx;

begin

   if not blank then begin { screen not blank }

      { place box }
      i := 1;
      boxrst(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, i)

   end

end; 

begin

   if modbut = bmovew then begin { in move mode }

      if puck.b[1].a or puck.b[2].a or 
         (puck.b[1].d and puck.b[1].dg) or
         (puck.b[2].d and puck.b[2].dg) then begin 

         { move complete }
         { resize window to box }
         rescur; { remove cursor }
         resbox; { remove size cursor }
         { clear overlap space }
         if (curwin^.r.s.x <= sizb.e.x) and 
            (curwin^.r.e.x >= sizb.s.x) and
            (curwin^.r.s.y <= sizb.e.y) and 
            (curwin^.r.e.y >= sizb.s.y) then begin

            { rectangles overlap }
            if (curwin^.r.s.y < sizb.s.y) and
               (curwin^.r.e.y > sizb.s.y) then { clear top }
               block(screen, curwin^.r.s.x, curwin^.r.s.y,
                     curwin^.r.e.x, sizb.s.y, bakclr);
            if (curwin^.r.s.x < sizb.s.x) and
               (curwin^.r.e.x > sizb.s.x) then { clear left }
               block(screen, curwin^.r.s.x, curwin^.r.s.y,
                     sizb.s.x, curwin^.r.e.y, bakclr);
            if (curwin^.r.e.x > sizb.e.x) and
               (curwin^.r.s.x < sizb.e.x) then { clear right }
               block(screen, sizb.e.x, curwin^.r.s.y,
                     curwin^.r.e.x, curwin^.r.e.y, bakclr);
            if (curwin^.r.e.y > sizb.e.y) and
               (curwin^.r.s.y < sizb.e.y) then { clear bottom }
               block(screen, curwin^.r.s.x, sizb.e.y,
                     curwin^.r.e.x, curwin^.r.e.y, bakclr)

         end else { no overlap }
            block(screen, curwin^.r.s.x, curwin^.r.s.y,
                  curwin^.r.e.x, curwin^.r.e.y, bakclr);
         curwin^.r := sizb; { set new window size }
         button[bmax].act := false; { deactivate max button }
         dispwin; { display new window }
         modbut := bnull { reset status }

      end else begin { resize still in progress }

         if puck.m then begin { cursor has moved }

            rescur; { remove cursor }
            resbox; { reset size cursor }
            sizb.s.x := sizb.s.x+(cur.x-movoff.x);
            sizb.s.y := sizb.s.y+(cur.y-movoff.y);
            sizb.e.x := sizb.e.x+(cur.x-movoff.x);
            sizb.e.y := sizb.e.y+(cur.y-movoff.y);
            setbox; { set size cursor to screen }
            setcur; { replace cursor }
            movoff := cur { save offset cursor } 

         end

      end

   end else { must be in select mode }
      if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { mark move mode }
      sizb := curwin^.r; { set size box to window region }
      movoff := cur; { save offset cursor } 
      rescur; { remove cursor }
      setbox; { set size cursor to screen }
      setcur; { replace cursor }
      modbut := curbut

   end;
{   resptr { reset buttons }

end;
{}
{**************************************************************

MAXIMIZE WINDOW

Handles the window maximize button. The window is resized to 
occupy the full screen.

**************************************************************}

procedure maxwin;

begin

   if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { resize window }
      button[bmax].act := not button[bmax].act; { invert status }
      rescur; { remove cursor }
      if button[bmax].act then begin { maximize window }

         curwin^.sr := curwin^.r; { save present region }
         curwin^.r.s.x := minx; { set to occupy entire screen }
         curwin^.r.s.y := miny;
         curwin^.r.e.x := maxx; 
         curwin^.r.e.y := maxy

      end else begin { set back to normal }

         { clear maximized window }
         block(screen, curwin^.r.s.x, curwin^.r.s.y,
               curwin^.r.e.x, curwin^.r.e.y, bakclr);
         curwin^.r := curwin^.sr { restore saved region }

      end;
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

HANDLE EXIT

Handles the exit button push.

**************************************************************}

procedure doexit;

begin

   if (curbut = bexit) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      butact(bexit); { set exit active }
   resptr { reset buttons }

end;
procedure testbut;

begin

   rescur;
   block(screen, button[curbut].r.s.x, button[curbut].r.s.y,
         button[curbut].r.e.x, button[curbut].r.e.y,
         lred);
   block(screen, button[curbut].r.s.x, button[curbut].r.s.y,
         button[curbut].r.e.x, button[curbut].r.e.y,
         white);
   setcur;

end;
{}
{**************************************************************

EXECUTE BUTTON COMMAND

Executes the handler for each button.

**************************************************************}

procedure dobutton(b: buttyp);

begin

  case(b) of { button active }

      { activated screen button }
      bnull:     ;              { no button }
      bpan:      pan;           { pan }
      bruler:    ruler;         { ruler }
      bin:       zoomin;        { zoom in }
      bout:      zoomout;       { zoom out }
      bbound:    bound;         { go bounding box }
      bback:     back;          { last view }
      bline:     doline;        { line draw mode }
      bbline:    doline;        { bold line draw mode }
      bsnap:     togsnap;       { toggle snap }
      bbox:      dobox;         { box draw mode }
      bbbox:     dobox;         { bold box draw mode }
      bany:      setllim;       { line limit any }
      b45:       setllim;       { line limit 45 deg }
      bcircle:   docircle;      { circle draw mode } 
      b90:       setllim;       { line limit 90 deg }
      barc:      doarc;         { arc draw mode }
      bwire:     doline;        { wire place mode }
      bbus:      doline;        { bus place mode }
      bjunction: junction;      { junction place mode }
      bjuncv:    stredt;        { edit junction size variable }
      bconnect:  connect;       { connector place mode }
      bconnv:    stredt;        { edit connector size variable }
      bundo:     ;              { undo }
      bredo:     ;              { redo }
      bcutb:     saveblk;       { cut block }
      bpasteb:   pasteblk;      { set paste block mode }
      bsaveb:    saveblk;       { save block }
      bblka,                    { block save sets }
      bblkb,
      bblkc,
      bblkd,
      bblke,
      bblkf,
      bblkg,
      bblkh:     setblk;       
      bdelete:   delete;        { delete }
      bdeleten:  deletenet;     { delete network }
      bdots:     togdot;        { toggle dot grid }
      bdotsv:    stredt;        { edit grid size variable }
      bdotsva,                  { dot grid sets }
      bdotsvb,
      bdotsvc,
      bdotsvd,
      bdotsve,
      bdotsvf,
      bdotsvg,
      bdotsvh:   setdotg;       
      blines:    togline;       { toggle line grid }
      blinev:    stredt;        { edit line grid size variable }
      blineva,                  { line grid sets }
      blinevb,
      blinevc,
      blinevd,
      blineve,
      blinevf,
      blinevg,
      blinevh:   setlineg;       
      btrace:    tracenet;      { set trace mode }
      btext:     dotext;        { place text }
      btsizv:    stredt;        { set text size variable }
      btexta,                   { text sets }
      btextb,
      btextc,
      btextd,
      btexte,
      btextf,
      btextg,
      btexth:    settexts;       
      bname:     doname;        { set node name mode }
      bnamev:    stredt;        { edit node name }
      bnord:     stredt;        { edit node ordinal }
      berc:      ;              { run rules check }
      bup:       upcell;        { up cell level }
      bdown:     downcell;      { down cell level }
      bsymbol:   setsymbol;     { select symbol sheet }
      bschema:   setschema;     { select schema sheet }
      blayout:   setlayout;     { select layout sheet }
      bsimulate: setsimulate;   { select simulate sheet }
      bload:     doloadc;       { load cell }
      bsave:     dosavec;       { save cell }
      bfname:    stredt;        { edit filename }
      bcname:    edtcel;        { edit cellname }
      bexit:     doexit;        { exit program }
      bnew:      donew;         { clear new sheet }
      brulerv:   ;              { ruler variable }
      brulx:     ;              { ruler x }
      brulxv:    ;              { ruler x variable }
      bruly:     ;              { ruler y }
      brulyv:    ;              { ruler y variable }
      bcposx:    ;              { cursor position x }
      bcposxv:   ;              { cursor position x variable }
      bcposy:    ;              { cursor position y }
      bcposyv:   ;              { cursor position y variable }
      borgx:     ;              { origin x }
      borgxv:    stredt;        { origin x variable }
      borgy:     ;              { origin y }
      borgyv:    stredt;        { origin y variable }
      bscl:      ;              { scale }
      bsclv:     stredt;        { scale variable }
      bviewa,                   { view sets }
      bviewb,
      bviewc,
      bviewd,
      bviewe,
      bviewf,
      bviewg,
      bviewh:    setview;       
      blibv,                    { current library select }
      bliba,                    { lib queue a }
      blibb,                    { lib queue b }
      blibc,                    { lib queue c }
      blibd:     dolibs;        { lib queue d }
      bcelv:     if puck.b[1].a then selplc { select placement cell }
                 else edtcelv;  { edit placement cell }
      bcela,                    { select placement cell }
      bcelb,  
      bcelc,
      bceld:     selcel;    
      bplsym:    docell;        { set symbol placement mode }
      bplsch:    docell;        { set schematic placement mode }
      birmir:    setmirm;       { instance mirror }
      bir0:      setrot;        { instance rotate 0 }
      bir90:     setrot;        { instance rotate 90 }
      bir180:    setrot;        { instance rotate 180 }
      bir270:    setrot;        { instance rotate 270 }
      bcells:    docells;       { display avalible cells }
      bnewc:     ;              { clear new cell }
      bprox:     ;              { proximity indicator }
      bnmos:     selplc;        { place nmos }
      bpmos:     selplc;        { place pmos }
      bres:      selplc;        { place resistor }
      bcap:      selplc;        { place capacitor }
      bdiode:    selplc;        { place diode }
      bvdd:      selplc;        { place vdd }
      bvss:      selplc;        { place vss }
      blast:     ;              { last page display }
      bnext:     ;              { next page display }
      bprint:    doprint;       { print current sheet }
      bdisplay:  dofiles;       { display avalible files }
      bmaxx:     strpedt;       { maximum demension printer x }
      bmaxy:     strpedt;       { maximum demension printer y }
      boffx:     strpedt;       { offset demension x }
      boffy:     strpedt;       { offset demension y }
      bseta:     ;              { print setup saves }
      bsetb:     ;
      bsetc:     ;
      bsetd:     ;
      bsete:     ;
      bsetf:     ;
      bsetg:     ;
      bseth:     ;
      bmet1:     dolayer;       { metal one }
      bmet1vis:  togvis;        { metal one visibility }
      bmet2:     dolayer;       { metal two }
      bmet2vis:  togvis;        { metal two visibility }
      bpoly:     dolayer;       { poly }
      bpolyvis:  togvis;        { poly visibility }
      bvia:      dolayer;       { via }
      bviavis:   togvis;        { via visibility }
      bcont:     dolayer;       { contact }
      bcontvis:  togvis;        { contact visibility }
      bndiff:    dolayer;       { N-diff }
      bndiffvis: togvis;        { N-diff visibility }
      bpdiff:    dolayer;       { P-diff }
      bpdiffvis: togvis;        { P-diff visibility }
      bnwell:    dolayer;       { N-well }
      bnwellvis: togvis;        { N-well visibility }
      bpwell:    dolayer;       { P-well }
      bpwellvis: togvis;        { P-well visibility }
      bccut:     dolayer;       { contact cut }
      bccutvis:  togvis;        { contact cut visibility }
      binsides:  togins;        { show insides }
      bplace:    docell;        { place cell }
      bdrc:      ;              { drc }
      bdwave,                   { digital waveform edit }
      bawave:     dowave;       { analog waveform edit }
      bctime:    ;              { cursor time indicator }
      bctimev:   ;              { cursor time value }
      bcvolt:    ;              { cursor voltage indicator }
      bcvoltv:   ;              { cursor voltage value }
      botime:    ;              { origin time indicator }
      botimev:   ;              { origin time value }
      bovolt:    ;              { origin voltage indicator }
      bovoltv:   ;              { origin voltage value }
      brtime:    ;              { ruler time indicator }
      brtimev:   ;              { ruler time value }
      brvolt:    ;              { ruler voltage indicator }
      brvoltv:   ;              { ruler voltage value }
      bmbtop,                   { move bar top }
      bmbleft,                  { move bar left }
      bmbright,                 { move bar right }
      bmbbottom,                { move bar bottom }
      bmbtoplt,                 { move bar top left top }
      bmbtopll,                 { move bar top left left }
      bmbtoprt,                 { move bar top right top }
      bmbtoprr,                 { move bar top right right }
      bmbbotlb,                 { move bar bottom left bottom }
      bmbbotll,                 { move bar bottom left left }
      bmbbotrb,                 { move bar bottom right bottom }
      bmbbotrr:  resize;        { move bar bottom right right }
      bmax:      maxwin;        { maximize }
      bmin:      ;              { minimize }
      bctrl:     ;              { window control }
      bmovew:    movewin;       { move window bar }

   end

end;
{}
{**************************************************************

EXECUTE KEYBOARD

Reads any key waiting from the keyboard, and executes the 
command.

**************************************************************}

procedure dokeyboard;

var c, cs: char; { input character }

begin

   { check keyboard activity }
   if kbdrdy then begin { key pressed }

      c := kbdinp; { get character w/o echo }
      if c = chr(0) then cs := kbdinp; { get auxillary key }
      if c = chr(27) then canact { cancel activity }
      { this next is for debugging only }
      else if (c = chr(ord('Q')-64)) then { ctrl-Q }
         terminate := true { exit program }
      { print screen }
      else if (c = chr(0)) and (cs = chr(25)) then scnprt { alt-P }
      else if drmbut = btext then enttext(c) { enter vector character }
      else if cedbut <> bnull then case cedbut of 

         { button in edit }
         bfname: dofiln(c, cs); { filename }
         bcname: doceln(c, cs); { cellname }
         bdotsv: dodotg(c, cs); { dot spacing }
         blinev: doling(c, cs); { line spacing }
         borgxv: doorgx(c, cs); { origin x }
         borgyv: doorgy(c, cs); { origin y }
         bsclv:  doscl(c, cs);  { scale }
         btsizv: dotsiz(c, cs); { text size }
         bjuncv: dojsiz(c, cs); { junction size }
         bconnv: docsiz(c, cs); { connector size }
         bcelv:  docelv(c, cs); { placement cell }
         blibv:  dolibv(c, cs); { library }
         bnamev: donnam(c, cs); { node name }
         bnord:  donord(c, cs); { node ordinal }
         bmaxx:  dopedt(c, cs, bmaxx, ptrmax.x);
         bmaxy:  dopedt(c, cs, bmaxy, ptrmax.y); 
         boffx:  dopedt(c, cs, boffx, ptroff.x); 
         boffy:  dopedt(c, cs, boffy, ptroff.y); 

      end

   end

end;
{}
{**************************************************************

EXECUTE COMMANDS

Central command loop for the schematic edittor. Accepts
pointer motions and buttons, and executes commands.
To simulate a paralell command structure, we perform three
momentary events:

   1. Screen buttons activated, at any time.
 
   2. Keyboard characters, at any time.
 
   3. "mode" routines, executed each any every loop.

Command also operates the button flags. These are set up at the
top of the loop, and reset at the bottom. The flag is a set only
communication with the tablet, and last for one loop only.

**************************************************************}

procedure command;

var timact: boolean;   { timer active flag }
    t:      integer;   { times }
    so, sc: integer;   { seconds count }
    pl:     point;     { puck location }

begin

   blank := false; { clear blank status }
   timact := false; { clear timer active flag }
   repeat { pointer follow loop }

      updpuck; { update puck status }
      if puck.b[1].s or puck.b[2].s or puck.b[3].s or puck.b[4].s or
         (timact and ((abs(pl.x-puck.cl.x) >= figet) or 
                      (abs(pl.y-puck.cl.y) >= figet))) or
         kbdrdy then begin { activity detected } 

         if blank then begin { screen is blanked, reestablish }

            blank := false; { set not black }
            { clear screen to white}
            block(screen, minx, miny, maxx, maxy, white);
            dispwin { display window }
            { check printer pop-up onscreen }
            if smprint in curscm then printpop;
            timact := false { set no time registered }

         end else timact := false { clear time }

      end else if not blank then begin { all quiet, not blanked }

         if not timact then begin { start time }

            t := gettim; { get current time }
            timact := true; { set time active }
            pl := puck.cl { save puck location }

         end else begin { check timeout }

            { find if timeout occurred }
            blank := elapsed(t) > timeout;
            if blank then begin { timed out, blank screen }
         
               block(screen, minx, miny, maxx, maxy, black); { fade to black }
               curdwn := false; { set cursor not on screen }
               aniini { initalize animator }

            end

         end

      end else aniblank; { animate blanking }
      if puck.b[3].a then canact; { cancel any activities }
      dobutton(modbut); { execute mode button }
      dobutton(curbut); { execute screen button }
      dokeyboard; { execute keyboard commands }
      resptr { reset buttons }

   until button[bexit].act or terminate { quit button active }

end;
{}
end. { module }

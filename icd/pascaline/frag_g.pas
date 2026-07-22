{******************************************************************************

FRAGMENT G: COMMAND LAYER

Ported from icdc.pas (lines ~2056-4992). Contains the mode set
routines, the drawing/entry commands (line/box/circle/arc/text/
junction/connector/cell placement), the in-button sequential
edits, the view/size/block save tableaus, the window resize/move/
maximize handlers, the button command dispatcher and the keyboard
command processor.

Port notes:

1. The grid indicator arrays (dgridsx/dgridsy) and their fill
   routines (plcgrid/plc10sgrid) were deleted in the frag_d port;
   the grids draw directly over the real extent of the view. All
   dogrid/do10sgrid call sites here are converted to the four
   coordinate form, and white-outs that relied on the stale array
   contents are moved ahead of the spacing change so they cover
   the old grid. Each site is marked with a "port:" comment.
2. boxsav/boxrst are the xor rubber-band pair from frag_d; the
   linarr/lininx save index parameters are deleted and boxrst
   takes the draw color (must match the boxsav color, lmagenta).
3. The window screen region field winrec.r was replaced by the
   window viewport (curwin^.wv.v) in the port; resize/move/
   maximize are converted to read wv.v and to reposition through
   plcwin. Each conversion is marked "port:".
4. The nested setbox/resbox in movewin collide with the global
   rubber-band setbox/resbox (frag_b) and are renamed
   setsizbox/ressizbox.
5. command is converted to dispatch (event pump model); dokeyboard
   is converted to a per-character entry. updpuck, gettim/elapsed,
   kbdrdy/kbdinp and the screen blank machinery do not survive.
6. Printer code (doprint, strpedt, dopedt, scnprt, printpop) is
   not ported in this pass; call sites are emptied and marked
   "port: printer pass deferred".

******************************************************************************}

{}
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
{}
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
{}
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
{}
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
{}
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

   end
   { resptr (reset buttons) disabled in original }
   { port: nested-brace comment flattened }

end;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
{**************************************************************

EDIT CELLNAME

Starts off the edit of the cellname field.

**************************************************************}

procedure edtcel;

begin

   if button[bfname].s <> '        ' then
      stredt { start edit }

end;
{}
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
{}
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
{}
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
         updbut(bnord); { update }
         { port: was updbut(blinev), copy damage from doling }
         cedbut := bnull { end edit }

      end

   end

end;
{}
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

            rescur; { reset cursor }
            { port: grid indicator arrays (plcgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[bdots].act then { grid active }
               dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                      curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                      white); { white out dots }
            curwin^.cs^.ds := ds; { place size }
            if button[bdots].act then { grid is on, redo }
               drwfigs; { redraw all figures }
            setcur { set cursor }

         end;
         cedbut := bnull { end edit }

      end

   end

end;
{}
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

            rescur; { remove cursor }
            { port: grid indicator arrays (plc10sgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[blines].act then { grid is on }
               do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                         curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                         white); { white out lines }
            curwin^.cs^.ls := ls; { place size }
            if button[blines].act then { grid is on }
               drwfigs; { redraw all figures }
            setcur { reset cursor }

         end;
         cedbut := bnull { end edit }

      end

   end

end;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
         updbut(bcelv); { update }
         { port: was updbut(b), stale loop index; bcelv intended }
         placel := nil

      end

   end

end;
{}
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
            updbut(bcelv); { update }
            { port: was updbut(b), stale loop index; bcelv intended }
         placel := nil

      end

   end

end;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
            { port: grid indicator arrays (plcgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[bdots].act then { grid active }
               dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                      curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                      white); { white out dots }
            curwin^.cs^.ds := curwin^.cs^.sds[i].s; { place size }
            realstr(curwin^.cs^.ds*pixsiz, button[bdotsv].s); { place value }
            updbut(bdotsv); { update }
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
{}
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
            { port: grid indicator arrays (plc10sgrid) deleted; the
              white-out draws over the view extent and must use the
              old spacing, so it moves ahead of the spacing change }
            if button[blines].act then { grid is on }
               do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                         curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                         white); { white out lines }
            curwin^.cs^.ls := curwin^.cs^.sls[i].s; { place size }
            realstr(curwin^.cs^.ls*pixsiz, button[blinev].s); { place value }
            updbut(blinev); { update }
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
{}
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
{}
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

         { port: grid indicator arrays deleted; white out over the
           real extent of the view }
         dogrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                white); { white out dots }
         drwfigs { replace figures }

      end

   end;
   resptr { reset buttons }

end;
{}
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

         { port: grid indicator arrays deleted; white out over the
           real extent of the view }
         do10sgrid(curwin^.cs^.vp.r.s.x, curwin^.cs^.vp.r.s.y,
                   curwin^.cs^.vp.r.e.x, curwin^.cs^.vp.r.e.y,
                   white); { white out lines }
         drwfigs { replace figures }

      end;

   end;
   resptr { reset buttons }

end;
{}
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
{}
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
{}
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
{ port: save-under replaced by xor rubber-banding; lininx save index
  deleted }

procedure setsiz;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxsav(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y,
             lmagenta)

   end

end;

{ reset size box from screen }
{ port: boxrst redraws the identical box in xor mode; the color must
  match the setsiz draw color }

procedure ressiz;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxrst(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, lmagenta)

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
         { port: winrec.r (window screen region) was replaced by the
           window viewport; reads convert to curwin^.wv.v }
         case modbut of { move button }

            bmbtop:    if sizb.s.y > curwin^.wv.v.s.y then
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, sizb.s.y, bakclr);
            bmbleft:   if sizb.s.x > curwin^.wv.v.s.x then
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     sizb.s.x, curwin^.wv.v.e.y, bakclr);
            bmbright:  if sizb.e.x < curwin^.wv.v.e.x then
               block(screen, sizb.e.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
            bmbbottom: if sizb.e.y < curwin^.wv.v.e.y then
               block(screen, curwin^.wv.v.s.x, sizb.e.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
            bmbtoplt, bmbtopll: begin

               if sizb.s.y > curwin^.wv.v.s.y then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, sizb.s.y, bakclr);
               if sizb.s.x > curwin^.wv.v.s.x then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        sizb.s.x, curwin^.wv.v.e.y, bakclr)

            end;
            bmbtoprt, bmbtoprr: begin

               if sizb.s.y > curwin^.wv.v.s.y then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, sizb.s.y, bakclr);
               if sizb.e.x < curwin^.wv.v.e.x then
                  block(screen, sizb.e.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr)

            end;
            bmbbotlb, bmbbotll: begin

               if sizb.e.y < curwin^.wv.v.e.y then
                  block(screen, curwin^.wv.v.s.x, sizb.e.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
               if sizb.s.x > curwin^.wv.v.s.x then
                  block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                        sizb.s.x, curwin^.wv.v.e.y, bakclr)

            end;
            bmbbotrb, bmbbotrr: begin

               if sizb.e.y < curwin^.wv.v.e.y then
                  block(screen, curwin^.wv.v.s.x, sizb.e.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
               if sizb.e.x < curwin^.wv.v.e.x then
                  block(screen, sizb.e.x, curwin^.wv.v.s.y,
                        curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr)

            end

         end;
         { port: was curwin^.r := sizb; the window repositions through
           its viewport }
         plcwin(screen, curwin^.wv, sizb.s.x, sizb.s.y,
                sizb.e.x, sizb.e.y); { set new window size }
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
      sizb := curwin^.wv.v; { set size box to window region }
      { port: was curwin^.r }
      adjsiz(curbut); { adjust size cursor }
      rescur; { remove cursor }
      setsiz; { set size cursor to screen }
      setcur; { replace cursor }
      modbut := curbut

   end
   { resptr (reset buttons) disabled in original }
   { port: nested-brace comment flattened }

end;
{}
{**************************************************************

MOVE WINDOW

Handles the window move button. A cursor box is pinned to the
cursor. The window is then moved to fit the resulting box.

**************************************************************}

procedure movewin;

{ set size box to screen }
{ port: renamed from setbox; collides with the global rubber-band
  setbox (icdb layer). Save-under replaced by xor rubber-banding;
  lininx save index deleted }

procedure setsizbox;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxsav(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y,
             lmagenta)

   end

end;

{ reset size box from screen }
{ port: renamed from resbox; collides with the global rubber-band
  resbox (icdb layer). boxrst redraws the identical box in xor mode;
  the color must match the setsizbox draw color }

procedure ressizbox;

begin

   if not blank then begin { screen not blank }

      { place box }
      boxrst(sizb.s.x, sizb.s.y, sizb.e.x, sizb.e.y, lmagenta)

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
         ressizbox; { remove size cursor }
         { clear overlap space }
         { port: winrec.r (window screen region) was replaced by the
           window viewport; reads convert to curwin^.wv.v }
         if (curwin^.wv.v.s.x <= sizb.e.x) and
            (curwin^.wv.v.e.x >= sizb.s.x) and
            (curwin^.wv.v.s.y <= sizb.e.y) and
            (curwin^.wv.v.e.y >= sizb.s.y) then begin

            { rectangles overlap }
            if (curwin^.wv.v.s.y < sizb.s.y) and
               (curwin^.wv.v.e.y > sizb.s.y) then { clear top }
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, sizb.s.y, bakclr);
            if (curwin^.wv.v.s.x < sizb.s.x) and
               (curwin^.wv.v.e.x > sizb.s.x) then { clear left }
               block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                     sizb.s.x, curwin^.wv.v.e.y, bakclr);
            if (curwin^.wv.v.e.x > sizb.e.x) and
               (curwin^.wv.v.s.x < sizb.e.x) then { clear right }
               block(screen, sizb.e.x, curwin^.wv.v.s.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
            if (curwin^.wv.v.e.y > sizb.e.y) and
               (curwin^.wv.v.s.y < sizb.e.y) then { clear bottom }
               block(screen, curwin^.wv.v.s.x, sizb.e.y,
                     curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr)

         end else { no overlap }
            block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
                  curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
         { port: was curwin^.r := sizb; the window repositions through
           its viewport }
         plcwin(screen, curwin^.wv, sizb.s.x, sizb.s.y,
                sizb.e.x, sizb.e.y); { set new window size }
         button[bmax].act := false; { deactivate max button }
         dispwin; { display new window }
         modbut := bnull { reset status }

      end else begin { resize still in progress }

         if puck.m then begin { cursor has moved }

            rescur; { remove cursor }
            ressizbox; { reset size cursor }
            sizb.s.x := sizb.s.x+(cur.x-movoff.x);
            sizb.s.y := sizb.s.y+(cur.y-movoff.y);
            sizb.e.x := sizb.e.x+(cur.x-movoff.x);
            sizb.e.y := sizb.e.y+(cur.y-movoff.y);
            setsizbox; { set size cursor to screen }
            setcur; { replace cursor }
            movoff := cur { save offset cursor }

         end

      end

   end else { must be in select mode }
      if puck.b[1].a or puck.b[2].a or puck.b[4].a then begin

      { mark move mode }
      sizb := curwin^.wv.v; { set size box to window region }
      { port: was curwin^.r }
      movoff := cur; { save offset cursor }
      rescur; { remove cursor }
      setsizbox; { set size cursor to screen }
      setcur; { replace cursor }
      modbut := curbut

   end
   { resptr (reset buttons) disabled in original }
   { port: nested-brace comment flattened }

end;
{}
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

         { port: winrec.r (window screen region) was replaced by the
           window viewport; reads convert to curwin^.wv.v, and the
           window repositions through plcwin }
         curwin^.sr := curwin^.wv.v; { save present region }
         { set to occupy entire screen }
         plcwin(screen, curwin^.wv, minx, miny, maxx, maxy)

      end else begin { set back to normal }

         { clear maximized window }
         block(screen, curwin^.wv.v.s.x, curwin^.wv.v.s.y,
               curwin^.wv.v.e.x, curwin^.wv.v.e.y, bakclr);
         { restore saved region }
         plcwin(screen, curwin^.wv, curwin^.sr.s.x, curwin^.sr.s.y,
                curwin^.sr.e.x, curwin^.sr.e.y)

      end;
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
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
{}
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
{}
{**************************************************************

EXECUTE KEYBOARD

Processes a single keyboard character, and executes the
command.

**************************************************************}

{ port: converted from the kbdrdy/kbdinp poll loop to a per-character
  entry; the event pump calls this once for each keyboard (etchar)
  event. The auxillary (scan code) second character path is gone;
  cs is passed as null to the edit handlers }

procedure dokeyboard(c: char);

var cs: char; { input character }

begin

   cs := chr(0); { port: no auxillary codes from the event pump }
   if c = chr(27) then canact { cancel activity }
   { this next is for debugging only }
   else if (c = chr(ord('Q')-64)) then { ctrl-Q }
      terminate := true { exit program }
   { port: printer pass deferred (scnprt on alt-P print screen) }
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
      bmaxx:  dopedt(c, cs, bmaxx, ptrmax.x); { edit print parameters }
      bmaxy:  dopedt(c, cs, bmaxy, ptrmax.y);
      boffx:  dopedt(c, cs, boffx, ptroff.x);
      boffy:  dopedt(c, cs, boffy, ptroff.y);

   end

end;
{}
{**************************************************************

EXECUTE COMMANDS

Central command dispatch for the schematic edittor. Executes the
mode and screen button handlers for one event cycle, then resets
the puck communication flags.

**************************************************************}

{ port: converted from command; polling loop replaced by event pump,
  screen blanking dropped. The original repeat loop polled the tablet
  (updpuck), ran the screen blank timer (gettim/elapsed/aniini/
  aniblank/printpop reestablish) and polled the keyboard; the event
  pump now calls dispatch once per event cycle and dokeyboard once
  per character, and the main program tests button[bexit].act or
  terminate for exit }

procedure dispatch;

begin

   if puck.b[3].a then canact; { cancel any activities }
   dobutton(modbut); { execute mode button }
   dobutton(curbut); { execute screen button }
   resptr { reset buttons }

end;
{}
{ UNRESOLVED: the following names are called here but defined in
  fragments being ported in parallel or in later phases:

  frag_n (icda db core):    plcjun, lnkwire, lnkbus, lnkjun
  frag_f (icdd figures):    drwfig, drwfigs, ratlin, rregion, frregion,
                            delete, deletenet, saveblk, pasteblk,
                            doname, upcell, downcell, tracenet
  icda remainder (files):   doloadc, dosavec, docells, dolibs, dofiles
  icdg/icdh (layout/sim):   setlayout, setsimulate, dolayer, togvis,
                            togins, dointer, dowave
  resptr: resolves against the icdui_base stub until the real icda
  version (clear puck flags) lands with frag_n.
  Printer names (doprint, strpedt, dopedt, scnprt, printpop) are NOT
  called: their sites are emptied per spec rule 6 (printer pass
  deferred). }

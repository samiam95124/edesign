{******************************************************************************

FRAGMENT P: LAYOUT COMMAND LAYER

Ported from icdg.pas (all 722 lines). Contains the layout mode
set (setlayout), the layer visibility and cell contents
visibility toggles (togvis/togins), the layer intersection
generator (dointer and its nested traversal), and the layer
rectangle draw command (dolayer).

Port notes:

1. All external declarations deleted (spec rule 2); every name
   icdg imported resolves against earlier fragments (canact/
   stopact/cruler/zruler/chktar/setbound/setsbound/redraw/
   dispcell in frag_d, realc/snapto/inactive/setcur/rescur/
   setbox/resbox/butact/butina in frag_b, rotx/roty/corrot/
   netmir/ratbox/rregion in frag_f, resptr in frag_n). blockr
   was declared external but never called; dropped.
2. intersect was already ported into frag_f.pas (icdd declared
   it external); it is SKIPPED here — dointer calls the frag_f
   copy.
3. dmenu has no surviving definition anywhere in the sources
   (it exists only in the pre-refactor icdc.sav; the menu redraw
   moved into dispwin when the sources were frozen mid-refactor,
   and icdg was never updated). setlayout's "dmenu ... dispcell"
   sequence is converted to the setschema/setsymbol pattern of
   the current icdc.pas: set the mode buttons, then dispwin
   (frame + menu + dispcell). See the "port:" comment in place.
4. No interface pixel constants appear in this file — all
   coordinate math is in real (schematic/layout) coordinates,
   so no uiscl scaling is applied anywhere.
5. tcont entries are rectangles (dolayer stores l^.b, dointer
   reads it) but the original define.pas left tcont out of the
   drwety variant list (SVS free-union punning). icddef.pas is
   amended to place tcont in the rectangle group, and the
   fndbound arm in frag_f that punned b on tinter entries now
   reads ir; both amendments carry "port:" comments.
6. Integrator: remove the setlayout/togvis/togins/dolayer/
   dointer stubs from icdui_base.pas, replacing them with
   forwards (frag_g dispatches to them ahead of this fragment):

      procedure setlayout; forward;
      procedure togvis; forward;
      procedure togins; forward;
      procedure dolayer; forward;
      procedure dointer(ip: drwptr); forward;

******************************************************************************}

{}
{**************************************************************

SET LAYOUT MODE

Sets the layout edit mode. The layout sheet in the current cell
is set current.

**************************************************************}

procedure setlayout;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[blayout].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smlayout]; { set symbol screen mode }
      pixsiz := dftsizl; { set base scale }
      butact(blayout); { activate layout button }
      butina(bschema); { deactivate other buttons }
      butina(bsymbol);
      butina(bsimulate);
      { port: the original called dmenu (no surviving definition; see
        header note 3) before the button set and dispcell after;
        converted to the setschema/setsymbol pattern - dispwin redraws
        the frame and menu for the new mode, then performs dispcell }
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE LAYER VISIBILITY

Toggles the states of the layer visibility.

**************************************************************}

procedure togvis;

begin

   if (curbut in [bmet1vis, bmet2vis, bpolyvis, bviavis,
                  bndiffvis, bpdiffvis, bnwellvis, bpwellvis,
                  bccutvis, bcontvis]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      if button[curbut].act then butina(curbut) { toggle status }
      else butact(curbut);
      redraw { refresh screen }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

TOGGLE CELL CONTENTS VISIBILITY

Toggles the states of the "insides" visibility.

**************************************************************}

procedure togins;

begin

   if (curbut = binsides) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      if button[curbut].act then butina(curbut) { toggle status }
      else butact(curbut);
      redraw { refresh screen }

   end;
   resptr { reset buttons }

end;
{}
{ port: FIND INTERSECTION (procedure intersect) was here in icdg.pas;
  it is ported in frag_f.pas (icdd declared it external) and is
  skipped in this fragment }
{}
{**************************************************************

ENTER INTERSECTION

This routine finds the
"intersection" of the given layer rectangle with any other
rectangle in the poly, metals and diff layers. An intersection
is an overlapping region of two rectangles.
Once found, the intersection is assigned the color of the
highest priority layer's "dark" equivalent, and entered into
the intersection draw list.

**************************************************************}

procedure dointer(ip: drwptr);

var ipx1, ipy1, ipx2, ipy2: integer;

{ check region intersection }

procedure chkintr(pc:                 drwptr; { 1st region cell }
                  p:                  drwptr; { 1st region layer }
                  { 1st region coordinates }
                  x1, y1, x2, y2:     integer;
                  cpc:                drwptr; { 2nd region cell }
                  cp:                 drwptr; { 2nd region layer }
                  { 2nd region coordinates }
                  cx1, cy1, cx2, cy2: integer);

var l: drwptr;  { list pointer }
    irx1, iry1, irx2, iry2: integer; { intersection holder }
    r:     boolean; { intersection flag }

begin

   if (p <> cp) and (p^.typ <> cp^.typ) and
      not ((p^.typ = tpdiff) and (cp^.typ = tndiff)) and
      not ((p^.typ = tndiff) and (cp^.typ = tpdiff)) and
      not ((p^.typ <> tmet2) and (cp^.typ = tcont)) and
      not ((p^.typ = tcont) and (cp^.typ <> tmet2)) then  begin

      { not same entry, type or diffs }
      { find intersection of rectangles }
      intersect(x1, y1, x2, y2, cx1, cy1, cx2, cy2,
                irx1, iry1, irx2, iry2, r);
      if r then begin { intersection found }

         new(l); { get new draw entry }
         l^.typ := tinter; { set intersection type }
         l^.ir.s.x := irx1; { place coordinates }
         l^.ir.s.y := iry1;
         l^.ir.e.x := irx2;
         l^.ir.e.y := iry2;
         { rationalize it }
         ratbox(l^.ir.s.x, l^.ir.s.y, l^.ir.e.x, l^.ir.e.y);
         { find color based on priority }
         if p^.typ = tmet2 then begin

            { metal 2 }
            l^.cl := cyan; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism2]; { enter to met 2 intersection list }
            curwin^.cs^.dl[ltism2] := l

         end else if cp^.typ = tmet2 then begin

            { metal 2 }
            l^.cl := cyan; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism2]; { enter to met 2 intersection list }
            curwin^.cs^.dl[ltism2] := l

         end else if p^.typ = tmet1 then begin

            { metal 1 }
            l^.cl := blue; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism1]; { enter to met 1 intersection list }
            curwin^.cs^.dl[ltism1] := l

         end else if cp^.typ = tmet1 then begin

            { metal 1 }
            l^.cl := blue; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltism1]; { enter to met 1 intersection list }
            curwin^.cs^.dl[ltism1] := l

         end else if p^.typ = tpoly then begin

            { poly }
            l^.cl := red; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltisply]; { enter to poly intersection list }
            curwin^.cs^.dl[ltisply] := l

         end else begin

            { poly }
            l^.cl := red; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := curwin^.cs^.dl[ltisply]; { enter to poly intersection list }
            curwin^.cs^.dl[ltisply] := l

         end

      end

   end

end;

{ declared ahead }

procedure intcell(ipc:    drwptr;  { intersect cell }
                  ip:     drwptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;
                  pc:     drwptr;  { cell pointer }
                  p:      shtptr;  { cell sheet }
                  ct:     celtyp;  { cell type }
                  ox, oy: integer; { cell origin }
                  r:      rotmod); { cell rotation }
                  forward;

{ check cell list intersections }

procedure intfigc(ipc:    drwptr;  { intersect cell }
                  ip:     drwptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;
                  d:      drwptr;  { figure to process }
                  pc:     drwptr;  { cell pointer }
                  p:      shtptr;  { cell sheet }
                  ct:     celtyp;  { cell type }
                  ox, oy: integer; { cell origin }
                  rt:     rotmod); { cell rotation }

var x1, y1, x2, y2: integer; { layer holder }
    co:             point;   { cell origin }

begin

   if d^.typ = tcell then begin { subcell }

      co := d^.cr.o; { find net origin }
      corrot(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, ox, oy, co,
             abs(d^.cr.cp^.bbex-d^.cr.cp^.bbsx)+1,
             abs(d^.cr.cp^.bbey-d^.cr.cp^.bbsy)+1, rt, d^.rm);
      { intersect with net rotation }
      intcell(ipc, ip, ipx1, ipy1, ipx2, ipy2,
              pc, d^.cr.cp, d^.cr.ct, co.x, co.y, netmir(rt, d^.rm));

   end else begin

      { find effective box }
      x1 := rotx(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, ox,
                 d^.b.s.x, d^.b.s.y, rt);
      y1 := roty(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, oy,
                 d^.b.s.x, d^.b.s.y, rt);
      x2 := rotx(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, ox,
                 d^.b.e.x, d^.b.e.y, rt);
      y2 := roty(p^.bbsx, p^.bbsy, p^.bbex, p^.bbey, oy,
                 d^.b.e.x, d^.b.e.y, rt);
      ratbox(x1, y1, x2, y2); { rationalize }
      if ip^.typ = tcell then { process subcell }
         intcell(pc, d, x1, y1, x2, y2,
                 ip, ip^.cr.cp, ip^.cr.ct, ip^.cr.o.x,
                 ip^.cr.o.y, ip^.rm)
      else { test/generate intersection }
         chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2,
                 pc, d, x1, y1, x2, y2)

   end

end;

{ cell intersections }

{ port: parameter list repeated per Pascaline forward convention }

procedure intcell(ipc:    drwptr;  { intersect cell }
                  ip:     drwptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;
                  pc:     drwptr;  { cell pointer }
                  p:      shtptr;  { cell sheet }
                  ct:     celtyp;  { cell type }
                  ox, oy: integer; { cell origin }
                  r:      rotmod); { cell rotation }

var d: drwptr;
    cr: region; { cell region }

begin

   { find bounds of cell }
   cr.s.x := ox;
   cr.s.y := oy;
   if r in [rm0, rm180, rmm0, rmm180] then begin { normal }

      cr.e.x := ox + abs(p^.bbex - p^.bbsx);
      cr.e.y := oy + abs(p^.bbey - p^.bbsy)

   end else begin { on side }

      cr.e.x := ox + abs(p^.bbey - p^.bbsy);
      cr.e.y := oy + abs(p^.bbex - p^.bbsx)

   end;
   if (ct = ctlay) and { if layout cell }
      (cr.e.x >= ipx1) and { intersects with target layer }
      (cr.s.x <= ipx2) and
      (cr.e.y >= ipy1) and
      (cr.s.y <= ipy2)  then begin

      { do layers }
      d := p^.dl[ltmet2]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ct, ox, oy, r);
         d := d^.next { next entry }

      end;
      d := p^.dl[ltcont]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ct, ox, oy, r);
         d := d^.next { next entry }

      end;
      d := p^.dl[ltpmd]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ct, ox, oy, r);
         d := d^.next { next entry }

      end;
      { do subcells }
      d := p^.dl[ltcell]; { index top of list }
      while d <> nil do begin { traverse }

         { intersect figure }
         intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, ct, ox, oy, r);
         d := d^.next { next entry }

      end

   end

end;

{ check standard intersections }

procedure intfig(ip: drwptr; { intersect figure }
                 { region }
                 ipx1, ipy1, ipx2, ipy2: integer;
                 p: drwptr); { intersecting figure }

var x1, y1, x2, y2: integer; { figure bounds holder }

begin

   if p^.typ = tcell then { process cell reference }
      intcell(nil, ip, ipx1, ipy1, ipx2, ipy2,
              p, p^.cr.cp, p^.cr.ct, p^.cr.o.x, p^.cr.o.y, p^.rm)
   else begin

      { port: p^.b hoisted to locals; the original passed the members
        directly, but 12-argument calls whose trailing arguments are
        variant-checked member loads exhaust the pgen register
        allocator ("Out of registers") }
      x1 := p^.b.s.x;
      y1 := p^.b.s.y;
      x2 := p^.b.e.x;
      y2 := p^.b.e.y;
      if ip^.typ = tcell then { process cell reference }
         intcell(nil, p, x1, y1, x2, y2,
                 ip, ip^.cr.cp, ip^.cr.ct, ip^.cr.o.x, ip^.cr.o.y, ip^.rm)
      else { test/generate intersection }
         chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2,
                 nil, p, x1, y1, x2, y2)

   end

end;

{ intersect single list }

procedure intlst(ip: drwptr; { intersect figure }
                 { region }
                 ipx1, ipy1, ipx2, ipy2: integer;
                 p: drwptr); { intersecting figure list }

begin

   while p <> nil do begin { traverse list }

      intfig(ip, ipx1, ipy1, ipx2, ipy2, p); { draw }
      p := p^.next { next entry }

   end

end;

begin

   if ip^.typ = tcell then begin { is cell }

      { find bounds of cell }
      ipx1 := ip^.cr.o.x;
      ipy1 := ip^.cr.o.y;
      if ip^.rm in [rm0, rm180, rmm0, rmm180] then begin { normal }

         ipx2 := ip^.cr.o.x + abs(ip^.cr.cp^.bbex - ip^.cr.cp^.bbsx);
         ipy2 := ip^.cr.o.y + abs(ip^.cr.cp^.bbey - ip^.cr.cp^.bbsy)

      end else begin { on side }

         ipx2 := ip^.cr.o.x + abs(ip^.cr.cp^.bbey - ip^.cr.cp^.bbsy);
         ipy2 := ip^.cr.o.y + abs(ip^.cr.cp^.bbex - ip^.cr.cp^.bbsx)

      end

   end else begin { figure }

      ipx1 := ip^.b.s.x; { set bounds }
      ipy1 := ip^.b.s.y;
      ipx2 := ip^.b.e.x;
      ipy2 := ip^.b.e.y

   end;
   { find poly, metals and diff intersects }
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltmet2]);
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltcont]);
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltpmd]);
   { find cell intersects }
   intlst(ip, ipx1, ipy1, ipx2, ipy2, curwin^.cs^.dl[ltcell])

end;
{}
{**************************************************************

LAYER DRAW

Handles the layer draw mode. Handles the activation of the button,
the start and cursor draw, and the box entry.

**************************************************************}

procedure dolayer;

var l:              drwptr; { line entry }
    x1, y1, x2, y2: integer;

begin

   if (curbut in [bmet1, bmet2, bpoly, bvia, bndiff, bpdiff,
                  bnwell, bpwell, bccut, bcont]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { mark box mode }
      stopact; { stop all modes }
      butact(curbut); { set line mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bmet1, bmet2, bpoly, bvia, bndiff,
                           bpdiff, bnwell, bpwell, bccut,
                           bcont]) and
               inactive(cur) and
               (puck.b[1].a or puck.b[2].a or
               (puck.b[1].d and puck.b[1].dg) or
               (puck.b[2].d and puck.b[2].dg)) then begin

      { enter layer }
      endp := cur; { make sure end is established }
      realc(endp, curwin^.cs^.vp); { convert coordinates }
      snapto(endp.x, endp.y);
      cruler; { clear ruler }
      if (str.x <> endp.x) and (str.y <> endp.y) then begin

         { is a two-dementional object }
         new(l); { get new draw entry }
         case drmbut of { layer type }

            bmet1:  begin l^.typ := tmet1;  l^.cl := lblue end;
            bmet2:  begin l^.typ := tmet2;  l^.cl := lcyan end;
            bpoly:  begin l^.typ := tpoly;  l^.cl := lred end;
            bvia:   begin l^.typ := tvia;   l^.cl := gray end;
            bcont:  begin l^.typ := tcont;  l^.cl := black end;
            bndiff: begin l^.typ := tndiff; l^.cl := green end;
            bpdiff: begin l^.typ := tpdiff; l^.cl := magenta end;
            bnwell: begin l^.typ := tnwell; l^.cl := yellow end;
            bpwell: begin l^.typ := tpwell; l^.cl := brown end;
            bccut:  begin l^.typ := tccut;  l^.cl := dwhite end

         end;
         l^.b.s.x := str.x; { place coordinates }
         l^.b.s.y := str.y;
         l^.b.e.x := endp.x;
         l^.b.e.y := endp.y;
         { rationalize it }
         ratbox(l^.b.s.x, l^.b.s.y, l^.b.e.x, l^.b.e.y);
         setbound(l^.b.s.x, l^.b.s.y); { modify bounding box }
         setbound(l^.b.e.x, l^.b.e.y);
         setsbound(l^.b.s.x, l^.b.s.y); { modify symbol bounding box }
         setsbound(l^.b.e.x, l^.b.e.y);
         chktar; { check target change }
         if drmbut in [bmet1, bmet2, bpoly, bndiff, bpdiff, bcont] then
            { in poly, metals, and diff layer }
            dointer(l); { enter to intersection list }
         case drmbut of { layer type }

            bmet1:  begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bmet2:  begin l^.next := curwin^.cs^.dl[ltmet2];
                          curwin^.cs^.dl[ltmet2] := l end;
            bpoly:  begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bvia:   begin l^.next := curwin^.cs^.dl[ltvia];
                          curwin^.cs^.dl[ltvia] := l end;
            bcont:  begin l^.next := curwin^.cs^.dl[ltcont];
                          curwin^.cs^.dl[ltcont] := l end;
            bndiff: begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bpdiff: begin l^.next := curwin^.cs^.dl[ltpmd];
                          curwin^.cs^.dl[ltpmd] := l end;
            bnwell: begin l^.next := curwin^.cs^.dl[ltwell];
                          curwin^.cs^.dl[ltwell] := l end;
            bpwell: begin l^.next := curwin^.cs^.dl[ltwell];
                          curwin^.cs^.dl[ltwell] := l end;
            bccut:  begin l^.next := curwin^.cs^.dl[ltovg];
                          curwin^.cs^.dl[ltovg] := l end

         end;
         rescur; { remove cursor }
         { Redraw region. This is the same as a draw of the figure, but
           makes sure that the layers are displayed in the correct
           priority. }
         rregion(l^.b.s.x, l^.b.s.y, l^.b.e.x, l^.b.e.y);
         setcur;  { replace cursor }
         boxdwn := false { since we have overwritten box }

      end else begin { eliminate box }

         rescur; { remove cursor }
         resbox; { remove box }
         setcur  { set cursor }

      end;
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
      { set mode }
      if button[bmet1].act then drmbut := bmet1
      else if button[bmet2].act then drmbut := bmet2
      else if button[bpoly].act then drmbut := bpoly
      else if button[bvia].act then drmbut := bvia
      else if button[bcont].act then drmbut := bcont
      else if button[bndiff].act then drmbut := bndiff
      else if button[bpdiff].act then drmbut := bpdiff
      else if button[bnwell].act then drmbut := bnwell
      else if button[bpwell].act then drmbut := bpwell
      else if button[bccut].act then drmbut := bccut

   end;
   resptr { reset buttons }

end;
{}
{ UNRESOLVED: none. Every name used here is defined in earlier
  fragments (see header note 1); nothing from icdh (frag_q,
  ported in parallel) is called by this fragment. dmenu, the one
  dangling external in the original, is resolved by the dispwin
  conversion (header note 3). Integration: remove the five
  icdui_base.pas stubs (setlayout/togvis/togins/dolayer/dointer)
  and forward them per header note 6; this fragment concatenates
  after frag_g. }

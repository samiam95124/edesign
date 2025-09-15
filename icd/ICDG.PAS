module icdg;

uses {$U common.j} common;

procedure canact; external; { cancel current activities }
procedure dmenu; external; { draw menu }
procedure butact(b: buttyp); external; { set button active }
procedure butina(b: buttyp); external; { set button inactive }
procedure resptr; external; { reset pointer flags }
procedure dispcell; external; { display current cell }
procedure stopact; external; { stop current activities }
{ check point in active area }
function inactive(p: point): boolean; external;
{ find real coordinates }
procedure realc(var p: point; var vp: viewport); external;
procedure snapto(var x, y: integer); external; { snap coordinates to grid }
procedure cruler; external; { clear ruler display }
procedure setbound(x, y: integer); external; { set bounding box }
{ set symbol bounding box }
procedure setsbound(x, y: integer); external; { set bounding box }
procedure chktar; external; { check target update }
procedure setcur; external; { draw cursor into place }
procedure rescur; external; { remove cursor }
procedure zruler; external; { zero ruler display }
procedure setbox; external; { set box }
procedure resbox; external; { reset box }
{ redraw real region }
procedure rregion(x1, y1, x2, y2: integer); external;
{ rationalize box }
procedure ratbox(var x1, y1, x2, y2: integer); external;
procedure blockr(x1, y1, x2, y2: integer; c: color); external;
procedure redraw; external; { redraw active region }
{ find rotated point x }
function rotx(sx, sy, ex, ey: integer; ox: integer; x, y: integer; 
              r: rotmod): integer; external;
{ find rotated point y }
function roty(sx, sy, ex, ey: integer; oy: integer; x, y: integer; 
              r: rotmod): integer; external;
{ find cell origin correction for rotation }
procedure corrot(x1, y1, x2, y2: integer; ox, oy: integer;
                 var co: point; lx, ly: integer; rt: rotmod; 
                 cr: rotmod); external;
{ find net mirror product }
function netmir(rt, rm: rotmod): rotmod; external;
{}
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
      dmenu; { display menu }
      butact(blayout); { activate layout button }
      butina(bschema); { deactivate other buttons }
      butina(bsymbol);
      butina(bsimulate);
      dispcell { display current cell }

   end;
   resptr { reset buttons }

end;
{}
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
{}
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
{}
{**************************************************************

FIND INTERSECTION

This routine finds the 
"intersection" of the given layer rectangle with another 
rectangle. An intersection is an overlapping region of two 
rectangles.

**************************************************************}

procedure intersect(    
              ax1, ay1, ax2, ay2,          { 1st rectangle }
              bx1, by1, bx2, by2: integer; { 2nd rectangle }
          var rx1, ry1, rx2, ry2: integer; { result rectangle }
          var rf:                 boolean); { found flag }

var r1, r2: boolean; { point define flags }

{ define an included point }

procedure defpnt(x, y: integer);

begin

   if not r1 then begin { 1st point not defined }

      rx1 := x; { set point }
      ry1 := y;
      r1 := true { set defined }

   end else if (rx1 <> x) and (ry1 <> y) then begin

      { new point is a direct opposite, enter as 2nd }
      rx2 := x; { set point }
      ry2 := y;
      r2 := true { set defined }
     
   end

end;

{ find included orthongonal line }

procedure lincl(x1, y1, x2, y2, { 1st region }
                cx1, cy1, cx2, cy2: integer); { line }

var x, y: integer; { point holders }

begin

   if ((x1 <= cx2) and (x2 >= cx1) and 
       (y1 <= cy1) and (y2 >= cy1)) then begin

      { horizonal included line }
      x := cx1; { set x }
      if x < x1 then x := x1;
      defpnt(x, cy1); { enter points }
      x := cx2; { set x }
      if x > x2 then x := x2;
      defpnt(x, cy1)

   end else if ((y1 <= cy2) and (y2 >= cy1) and 
            (x1 <= cx1) and (x2 >= cx1)) then begin

      { vertical included line }
      y := cy1; { set y }
      if y < y1 then y := y1;
      defpnt(cx1, y); { enter points }
      y := cy2; { set y }
      if y > y2 then y := y2;
      defpnt(cx1, y)

   end

end;

begin

   r1 := false; { clear points }
   r2 := false;
   { test 2nd inclusion in 1st }
   lincl(ax1, ay1, ax2, ay2, bx1, by1, bx1, by2); { left }
   lincl(ax1, ay1, ax2, ay2, bx2, by1, bx2, by2); { right }
   lincl(ax1, ay1, ax2, ay2, bx1, by1, bx2, by1); { top }
   lincl(ax1, ay1, ax2, ay2, bx1, by2, bx2, by2); { bottom }
   { test 1st inclusion in 2nd }
   lincl(bx1, by1, bx2, by2, ax1, ay1, ax1, ay2); { left }
   lincl(bx1, by1, bx2, by2, ax2, ay1, ax2, ay2); { right }
   lincl(bx1, by1, bx2, by2, ax1, ay1, ax2, ay1); { top }
   lincl(bx1, by1, bx2, by2, ax1, ay2, ax2, ay2); { bottom }
   rf := r1 and r2; { set intersection found }
   if rf then ratbox(rx1, ry1, rx2, ry2) { rationalize }

end;
{}
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

procedure intcell; { (ipc:    drwptr; 
                      ip:     drwptr; 
                      ipx1, ipy1, ipx2, ipy2: integer;    
                      pc:     drwptr;
                      p:      shtptr; 
                      ct:     celtyp; 
                      ox, oy: integer; 
                      r:      rotmod); }

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

begin

   if p^.typ = tcell then { process cell reference }
      intcell(nil, ip, ipx1, ipy1, ipx2, ipy2, 
              p, p^.cr.cp, p^.cr.ct, p^.cr.o.x, p^.cr.o.y, p^.rm)
   else if ip^.typ = tcell then { process cell reference }
      intcell(nil, p, p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y, 
              ip, ip^.cr.cp, ip^.cr.ct, ip^.cr.o.x, ip^.cr.o.y, ip^.rm)
   else { test/generate intersection }
      chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2,
              nil, p, p^.b.s.x, p^.b.s.y, p^.b.e.x, p^.b.e.y)

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
{}
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
{}
end. { module }


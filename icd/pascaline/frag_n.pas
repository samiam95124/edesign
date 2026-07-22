{***************************************************************

FRAGMENT N: schematic database core ported from icda.pas (1992)

Ported per PORTING-SPEC.md. This fragment contains the puck
communication flag reset (resptr) and the schematic connection
database: node/bus list maintenance, wire/bus/junction deletion,
colinear joins, node and bus creation and merging, wire
attachment, and the junction/wire/bus linkers.

Omitted from the original (see spec):

   fndbnd            - already ported in frag_e.pas.
   readbyt onward    - cell file I/O, deferred to a later phase.

port: the resptr stub in icdui_base.pas is superseded by the
full port below; the integrator removes the stub.

***************************************************************}
{}
{**************************************************************

CLEAR PUCK

Clears all puck action flags.

**************************************************************}

procedure resptr;

begin

   puck.b[1].a := false; { reset buttons }
   puck.b[2].a := false;
   puck.b[3].a := false;
   puck.b[4].a := false;
   puck.b[1].d := false; { reset buttons }
   puck.b[2].d := false;
   puck.b[3].d := false;
   puck.b[4].d := false;
   puck.m := false

end;
{}
{**************************************************************

DELETE NODE

Deletes the given node from the node list, and also from the
smash list if it is there.

**************************************************************}

procedure delnode(n: nodptr);

var p: nodptr;

begin

   { delete from node list }
   p := curwin^.cs^.nl; { index top of node list }
   if p = n then curwin^.cs^.nl := p^.next { gap top of list }
   else begin

      while p^.next <> n do p := p^.next; { find parent node }
      p^.next := n^.next { gap list }

   end;
   { delete from smash list }
   if smslst = n then smslst := smslst^.sl { delete first entry }
   else if smslst <> nil then begin { search }

      p := smslst; { index smash list }
      while (p^.sl <> n) and (p^.sl <> nil) do p := p^.sl;
      if p^.sl <> nil then begin { delete }

         p^.sl := n^.sl; { gap over }
         n^.sl := nil { clear from list }

      end

   end;
   { delete from bus list }
   if n^.bh <> nil then begin { node is part of a bus }

      p := n^.bh^.nl; { index top of node list }
      if p = n then n^.bh^.nl := p^.bl { gap top of list }
      else begin

         while p^.bl <> n do p := p^.bl; { find parent node }
         p^.bl := n^.bl { gap list }

      end

   end

end;
{}
{**************************************************************

DELETE BUS

Deletes the given node from the bus list, and also from the
bus smash list if it is there.

**************************************************************}

procedure delbus(b: busptr);

var p: busptr;

begin

   p := curwin^.cs^.bl; { index top of node list }
   if p = b then curwin^.cs^.bl := p^.next { gap top of list }
   else begin

      while p^.next <> b do p := p^.next; { find parent node }
      p^.next := b^.next { gap list }

   end;
   if bsmlst = b then bsmlst := bsmlst^.sl { delete first entry }
   else if bsmlst <> nil then begin { search }

      p := bsmlst; { index smash list }
      while (p^.sl <> b) and (p^.sl <> nil) do p := p^.sl;
      if p^.sl <> nil then begin { delete }

         p^.sl := b^.sl; { gap over }
         b^.sl := nil { clear from list }

      end

   end

end;
{}
{**************************************************************

DELETE WIRE

Deletes the given wire, bus, connector or junction from
the draw and other lists.

**************************************************************}

procedure delwire(w: drwptr);

var p: drwptr;
    n: nodptr;

begin

   { remove from drawing list }
   p := curwin^.cs^.dl[ltfig]; { index top of list }
   if p = w then curwin^.cs^.dl[ltfig] := w^.next { gap top of list }
   else begin

      while p^.next <> w do p := p^.next; { find parent }
      p^.next := w^.next { gap }

   end;
   if w^.typ <> tbus then begin { wire, junction or connector }

      { remove from node list }
      p := w^.nh^.nl; { index top of node list }
      if p = w then w^.nh^.nl := w^.nl { gap top of list }
      else begin

         while p^.nl <> w do p := p^.nl; { find parent }
         p^.nl := w^.nl

      end;
      { if we have emptied that node list, the node itself is
        removed }
      if w^.nh^.nl = nil then begin

         delnode(w^.nh); { remove }
         { flag to caller that node is no more }
         w^.nh := nil

      end

   end else begin { bus }

      { remove from bus list }
      p := w^.bs.bh^.bl; { index top of node list }
      if p = w then w^.bs.bh^.bl := w^.bs.bl { gap top of list }
      else begin

         while p^.bs.bl <> w do p := p^.bs.bl; { find parent }
         p^.bs.bl := w^.bs.bl

      end;
      { if we have emptied that node list, the bus itself is
        removed }
      if w^.bs.bh^.bl = nil then begin

         delbus(w^.bs.bh); { remove }
         { flag to caller that bus is no more }
         w^.bs.bh := nil

      end

   end

end;
{}
{**************************************************************

JOIN COLINEAR LINE/WIRE/BUS

Joins two lines that have already been found to be colinear,
and overlapping. Line a is extended to be equivalent to both
lines, and line b is extracted from all draw and node lists.
The lines must be of the same type

**************************************************************}

procedure join(a, b: drwptr);

procedure ljoin(var a, b: region); { line join }

var t: integer;

begin

   if a.s.x = a.e.x then begin { vertical line }

      { regularize both lines }
      if a.s.y > a.e.y then { swap ends }
         begin t := a.s.y; a.s.y := a.e.y; a.e.y:= t end;
      if b.s.y > b.e.y then { swap ends }
         begin t := b.s.y; b.s.y := b.e.y; b.e.y:= t end;
      { choose the "widest" ends }
      if b.s.y < a.s.y then a.s.y := b.s.y;
      if b.e.y > a.e.y then a.e.y := b.e.y

   end else begin { horizontal line }

      { regularize both lines }
      if a.s.x > a.e.x then { swap ends }
         begin t := a.s.x; a.s.x := a.e.x; a.e.x:= t end;
      if b.s.x > b.e.x then { swap ends }
         begin t := b.s.x; b.s.x := b.e.x; b.e.x:= t end;
      { choose the "widest" ends }
      if b.s.x < a.s.x then a.s.x := b.s.x;
      if b.e.x > a.e.x then a.e.x := b.e.x

   end

end;

begin

   if a^.typ = twire then ljoin(a^.w, b^.w)  { wire }
   else if a^.typ = tbus then ljoin(a^.bs.l, b^.bs.l) { bus }
   else ljoin(a^.l, b^.l); { line }
   if (a^.typ = twire) or (a^.typ = tbus) then
      delwire(b) { delete b wire }

end;
{}
{**************************************************************

CHECK WIRE/LINE ORTHOGONAL

Checks if the wire/line is orthogonal, that is, either dead vertical
or dead horizontal.

**************************************************************}

function orthogonal(d: drwptr): boolean; { check orthogonality }

var b: boolean;

begin

   if d^.typ = twire then { wire }
      b := (d^.w.s.x = d^.w.e.x) or
           (d^.w.s.y = d^.w.e.y) { set result }
   else if d^.typ = tbus then { bus }
      b := (d^.bs.l.s.x = d^.bs.l.e.x) or
           (d^.bs.l.s.y = d^.bs.l.e.y) { set result }
   else { line }
      b := (d^.l.s.x = d^.l.e.x) or
           (d^.l.s.y = d^.l.e.y); { set result }
   orthogonal := b { return }

end;
{}
{**************************************************************

CHECK POINT CONTAINED IN WIRE/LINE

Checks if the given (x, y) point is contained in the given wire
or line. Contained means that it specifies one of the points
making up the line.
The line must be orthogonal.

**************************************************************}

function contained(tx, ty: integer; w: drwptr): boolean;

var t: integer;
    l: region;
    sx, sy, ex, ey: integer; { line coordinates }

begin

   if w^.typ = twire then l := w^.w { wire }
   else if w^.typ = tbus then l := w^.bs.l { bus }
   else l := w^.l; { line }
   { exchange endpoints for compare }
   if ((l.s.x = l.e.x) and (l.s.y > l.e.y)) or
      ((l.s.y = l.e.y) and (l.s.x > l.e.x)) then begin { exchange }

     t := l.s.x; l.s.x := l.e.x; l.e.x := t;
     t := l.s.y; l.s.y := l.e.y; l.e.y := t

   end;
   contained := ((tx = l.s.x) and (ty >= l.s.y) and (ty <= l.e.y)) or
                ((ty = l.s.y) and (tx >= l.s.x) and (tx <= l.e.x))

end;
{}
{**************************************************************

CHECK COLINEAR

Checks if the line/wires given are colinear. To be so, they
must both be orthogonal, and of the same axis (vertical or
horizonal).
The lines should be of the same type.

**************************************************************}

function colinear(a, b: drwptr): boolean;

var ar, br: region;

begin

   { get the correct line }
   if a^.typ = twire then begin ar := a^.w; br := b^.w end
   else if a^.typ = tbus then begin ar := a^.bs.l; br := b^.bs.l end
   else begin ar := a^.l; br := b^.l end;
   colinear :=
      ((ar.s.x = ar.e.x) and (br.s.x = br.e.x) and
       (ar.s.x = br.s.x)) or
      ((ar.s.y = ar.e.y) and (br.s.y = br.e.y) and
       (ar.s.y = br.s.y))

end;
{}
{**************************************************************

COUNT COORDINATE ENDPOINTS

Given a point (x, y), returns the total number of matching
wire endpoints in the drawbase.
Only counts wires not colinear with the given wire.
Used to determine junction candidates.

**************************************************************}

function cntend(x, y: integer): byte;

var c: byte;
    l: drwptr;

begin

   c := 0; { clear count }
   l := curwin^.cs^.dl[ltfig]; { index list top }
   while l <> nil do begin { traverse list }

      { port: the else below binds to the INNER if, exactly as in
        SVS; the tbus arm is thus only reached when l^.typ = twire
        and the endpoints mismatch, and so never executes. Ported
        verbatim to keep behavior identical. }
      if l^.typ = twire then { is a wire }
         { check coordinance with our point }
         if ((x = l^.w.s.x) and (y = l^.w.s.y)) or
            ((x = l^.w.e.x) and (y = l^.w.e.y)) then
               c := c + 1 { count }
      else if l^.typ = tbus then { is a bus }
         { check coordinance with our point }
         if ((x = l^.bs.l.s.x) and (y = l^.bs.l.s.y)) or
            ((x = l^.bs.l.e.x) and (y = l^.bs.l.e.y)) then
               c := c + 1; { count }
      l := l^.next { link next wire in list }

   end;
   cntend := c { place result }

end;
{}
{**************************************************************

CREATE NEW NODE ENTRY

Allocates and initalizes a node entry. A temp name is assigned
to the node, and the node ordinal defaults to 0.

**************************************************************}

procedure crtnod(var n: nodptr);

begin

   new(n); { get a new node entry }
   n^.next := curwin^.cs^.nl; { link into list }
   curwin^.cs^.nl := n;
   n^.sl := nil; { clear lists }
   n^.bl := nil;
   n^.nl := nil;
   n^.bh := nil;
   curwin^.cs^.nc := curwin^.cs^.nc + 1; { count node }
   intstr(curwin^.cs^.nc, n^.name); { place as node name }
   n^.name[1] := 'N'; { place leading character }
   n^.nord := 0; { set first ordinal }
   n^.tmp := true { set name is a temp }

end;
{}
{**************************************************************

CREATE NEW BUS ENTRY

Allocates and initalizes a bus entry. A temp name is assigned
to the bus.

**************************************************************}

procedure crtbus(var b: busptr);

begin

   new(b); { get new bus entry }
   b^.next := curwin^.cs^.bl; { link into list }
   curwin^.cs^.bl := b;
   b^.bl := nil; { clear lists }
   b^.sl := nil;
   b^.nl := nil;
   curwin^.cs^.nc := curwin^.cs^.nc + 1; { count node }
   intstr(curwin^.cs^.nc, b^.name); { place as node name }
   b^.name[1] := 'N'; { place leading character }
   b^.tmp := true { set name is a temp }

end;
{}
{**************************************************************

MERGE NODE LISTS

Merges node list a into node list b and deletes node list a.

**************************************************************}

procedure nodmrg(a, b: nodptr);

var p: drwptr;

begin

   p := b^.nl; { index top entry of target }
   { find end of target list }
   while p^.nl <> nil do p := p^.nl;
   p^.nl := a^.nl; { link to head of source }
   p := a^.nl; { index top of that list }
   delnode(a); { delete node entry }
   while p <> nil do begin { correct source node heads }

      p^.nh := b; { set node }
      p := p^.nl { link next }

   end

end;
{}
{**************************************************************

ELIMINATE BUS DUPLICATES

The given bus is exastively matched for nodes with the same
ordinal, and those are merged where found.

**************************************************************}

procedure busdup(b: busptr);

var p1, p2, p3: nodptr;

begin

   p1 := b^.nl; { index 1st node in list }
   while p1 <> nil do begin { traverse search entry }

      p2 := p1^.bl; { index next entry }
      while p2 <> nil do begin { traverse match entry }

         p3 := p2^.bl; { save next }
         { merge with search node if same ordinal }
         if p2^.nord = p1^.nord then nodmrg(p2, p1);
         p2 := p3 { next entry }

      end;
      p1 := p1^.bl { next entry }

   end

end;
{}
{**************************************************************

MERGE BUS LISTS

Merges bus list a into bus list b and deletes node bus a.
Duplicate nodes (nodes with the same ordinal) are merged.

**************************************************************}

procedure busmrg(a, b: busptr);

var p: drwptr;
    np: nodptr;

begin

   { merge figure lists }
   p := b^.bl; { index top entry of target }
   { find end of target list }
   while p^.bs.bl <> nil do p := p^.bs.bl;
   p^.bs.bl := a^.bl; { link to head of source }
   p := a^.bl; { index top of that list }
   while p <> nil do begin { correct source bus heads }

      p^.bs.bh := b; { set bus }
      p := p^.bs.bl { link next }

   end;
   { merge node lists }
   if b^.nl = nil then b^.nl := a^.nl
   else begin

      np := b^.nl; { index top entry of target }
      { find end of target list }
      while np^.bl <> nil do np := np^.bl;
      np^.bl := a^.nl { link to head of source }

   end;
   np := a^.nl; { index top of that list }
   while np <> nil do begin { correct source bus nodes }

      np^.name := b^.name; { copy signal name }
      np^.tmp := b^.tmp; { copy temp flag }
      np^.bh := b; { set head entry }
      np := np^.bl { link next }

   end;
   delbus(a); { delete bus entry }
   busdup(b) { eliminate duplicate nodes }

end;
{}
{**************************************************************

ATTACH WIRE OR JUNCTION TO NODE

Attaches the first wire or junction into the node list of the
second wire or bus.
If the first already is part of a node list, and it's not the
same one as the destination, the entire node list for the
first is merged with the second, and the first node deleted.
Note that only entry a is allowed to have a null node list
pointer (in case of wire, junction or connector) or null bus
list (in case of bus).

**************************************************************}

procedure attwire(a, b: drwptr);

var p:  drwptr;
    np: nodptr;
    r:  boolean;

begin

   if (a^.typ <> tbus) and (b^.typ <> tbus) then begin

      { wire, junction or connectors }
      if a^.nh = nil then begin { not in any list }

         a^.nl := b^.nh^.nl; { link wire into list }
         b^.nh^.nl := a;
         a^.nh := b^.nh { link to head }

      end else if a^.nh <> b^.nh then begin { different lists, merge }

         { if one node is a temp, make sure that is overwritten }
         if not a^.nh^.tmp then begin p := a; a := b; b := p end;
         nodmrg(a^.nh, b^.nh) { merge nodes }

      end

   end else if (a^.typ = tbus) and (b^.typ = tbus) then begin

      { bus join }
      if a^.bs.bh = nil then begin { not in any list }

         a^.bs.bl := b^.bs.bh^.bl; { link bus into list }
         b^.bs.bh^.bl := a;
         a^.bs.bh := b^.bs.bh { link to head }

      end else if a^.bs.bh <> b^.bs.bh then begin { different lists, merge }

         { if one bus is a temp, make sure that is overwritten }
         if not a^.bs.bh^.tmp then begin p := a; a := b; b := p end;
         busmrg(a^.bs.bh, b^.bs.bh) { merge busses }

      end

   end else begin { join wire, junction or connector to bus }

      if a^.typ = tbus then begin { source is bus }

         { check in bus list }
         if a^.bs.bh = nil then begin { no, enter new bus }

            crtbus(a^.bs.bh); { get new bus entry }
            a^.bs.bh^.bl := a; { link in bus }
            a^.bs.bl := nil

         end

      end else if a^.nh = nil then begin { not in any list }

         { must give entry a node, so that it can be placed }
         crtnod(a^.nh); { get a new node entry }
         a^.nh^.nl := a; { link in wire }
         a^.nl := nil { clear next }

      end;
      { place operands }
      if a^.typ = tbus then { exchange }
         begin p := a; a := b; b := p; r := true end
      else r := false;
      { place node into bus list }
      if a^.nh^.bh = nil then begin

         { node is not presently in a bus }
         a^.nh^.bl := b^.bs.bh^.nl; { link into list }
         b^.bs.bh^.nl := a^.nh;
         a^.nh^.bh := b^.bs.bh; { place head linkage }
         if a^.nh^.tmp or not b^.bs.bh^.tmp then begin

            { node is temp, or bus is not a temp }
            a^.nh^.name := b^.bs.bh^.name; { adjust name }
            a^.nh^.tmp := b^.bs.bh^.tmp

         end else begin { node annihilates bus }

            b^.bs.bh^.name := a^.nh^.name; { rename bus }
            b^.bs.bh^.tmp := a^.nh^.tmp; { place temp status }
            np := b^.bs.bh^.nl; { index top of node list }
            while np <> nil do begin { rename nodes }

               np^.name := a^.nh^.name; { place name }
               np^.tmp := a^.nh^.tmp;
               np := np^.bl { link next }

            end

         end;
         busdup(b^.bs.bh) { eliminate duplicates }

      end else if a^.nh^.bh <> b^.bs.bh then begin { different busses }

         if r then { operands have been reversed,
                     ensure left side is deleted }
            busmrg(b^.bs.bh, a^.nh^.bh) { merge busses }
         else
            busmrg(a^.nh^.bh, b^.bs.bh) { merge busses }

      end

   end

end;
{}
{**************************************************************

PLACE JUNCTION

Places a junction at the given (x, y) coordinate. This includes
entry into the draw list and display.
Checks if any previous junction exists at that point, and
rejects the request if so.
Returns the node entry.

**************************************************************}

procedure plcjun(x, y: integer; var p: drwptr);

var p1: drwptr;

begin

   { search for previous junction }
   p1 := curwin^.cs^.dl[ltfig]; { index top of list }
   p := nil; { clear result }
   while p1 <> nil do begin { traverse }

      if p1^.typ = tjunction then { is a junction }
         if (p1^.j.x = x) and (p1^.j.y = y) then
            begin p := p1; p1 := nil end { terminate }
         else p1 := p1^.next
      else p1 := p1^.next

   end;
   if p = nil then begin { no previous junction }

      new(p); { get new draw entry }
      p^.typ := tjunction; { set type }
      p^.j.x := x; { place coordinates }
      p^.j.y := y;
      p^.cl := black; { set color }
      p^.nh := nil; { set no node }
      p^.next := curwin^.cs^.dl[ltfig]; { enter to draw list }
      curwin^.cs^.dl[ltfig] := p;
      { modify bounding box }
      setbound(x-(curwin^.cs^.js-1), y-(curwin^.cs^.js-1));
      setbound(x+(curwin^.cs^.js-1), y+(curwin^.cs^.js-1));
      setsbound(x-(curwin^.cs^.js-1), y-(curwin^.cs^.js-1));
      setsbound(x+(curwin^.cs^.js-1), y+(curwin^.cs^.js-1));
      chktar; { check target change }

   end

end;
{}
{**************************************************************

LINK JUNCTION

Accepts a (x, y) point for a junction. The junction
is inserted into the node list of any wire that it crosses.
Will also join different nodes that cross under the junction.
If none are found, the junction will get a brand new node.

**************************************************************}

procedure lnkjun(j: drwptr);

var p, l: drwptr;
    n:    nodptr;

begin

   j^.nh := nil; { set in no node list }
   l := nil; { set no last }
   p := curwin^.cs^.dl[ltfig]; { index top of drawing list }
   while p <> nil do begin { traverse }

      if (p^.typ = twire) or (p^.typ = tbus) then
         { is a wire or bus }
         if orthogonal(p) then { is a candidate }
            if contained(j^.j.x, j^.j.y, p) then begin

         attwire(j, p); { attach junction to wire }
         { if there is a last, join with this }
         if l <> nil then attwire(l, p);
         l := p { save this as last }

      end;
      p := p^.next { link next figure }

   end;
   if j^.nh = nil then begin { junction not attached to node }

      { no wires, a lone junction must get a node }
      crtnod(n); { get a new node entry }
      n^.nl := j; { link in junction }
      j^.nl := nil; { clear next }
      j^.nh := n { set head pointer }

   end

end;
{}
{**************************************************************

LINK WIRE OR BUS TO NODE(S)

The given wire is linked into a node. First, the wire is checked
for intersection with existing wires, and if found, that node
is linked. Otherwise, the wire gets its own, new node.
Intersection is determined in two ways. Endpoint intersection
is when the (x,y) start or end points are co-ordinate. This works
on any line.
The second type is when both lines are 90 deg orthogonal, and
one line's endpoint meets another's midsection. This case
automatically generates a junction between the lines.

**************************************************************}

procedure lnkwire(d: drwptr);

var l, l1: drwptr;  { drawing list pointer }
    f:     boolean; { wire found flag }
    n:     nodptr;  { node list pointer }
    b:     busptr;  { bus pointer }

{ place midline junction }

procedure midatt(x, y: integer);

var p: drwptr;

begin

   if not colinear(d, l) then begin

      plcjun(x, y, p); { place junction }
      { display junction }
      pier(x, y, curwin^.cs^.js, black, curwin^.cs^.vp.v);
      attwire(p, l) { attach to wire }

   end;
   attwire(d, l); { attach to this wire }
   f := true { flag wire found }

end;

begin

   { check for colinear lines }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      l1 := l^.next; { save next }
      if l^.typ = twire then
         { both lines are orthogonal and colinear }
         if colinear(d, l) and
            (contained(d^.w.s.x, d^.w.s.y, l) or
             contained(d^.w.e.x, d^.w.e.y, l)) then
            join(d, l); { joint the two lines together }
      l := l1 { link next }

   end;
   d^.nh := nil; { clear node head }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      if l^.typ = twire then begin

         { figures are wire or bus, check various intersections }
         if (orthogonal(d) or orthogonal(l)) then begin

            { figure is a wire, and one of the wires is orthogonal }
            { check any of the endpoints co-ordinate }
            if ((d^.w.s.x = l^.w.s.x) and (d^.w.s.y = l^.w.s.y)) or
               ((d^.w.s.x = l^.w.e.x) and (d^.w.s.y = l^.w.e.y)) then begin

               attwire(d, l); { attach to this wire }
               { if we reach 3, place a junction }
               if cntend(d^.w.s.x, d^.w.s.y) >= 2 then begin

                  plcjun(d^.w.s.x, d^.w.s.y, l1); { place junction }
                  pier(d^.w.s.x, d^.w.s.y, curwin^.cs^.js, black,
                       curwin^.cs^.vp.v); { display junction }
                  attwire(l1, l) { attach to wire }

               end

            end else if ((d^.w.e.x = l^.w.s.x) and (d^.w.e.y = l^.w.s.y)) or
                        ((d^.w.e.x = l^.w.e.x) and (d^.w.e.y = l^.w.e.y)) then begin

               attwire(d, l); { attach to this wire }
               { if we reach 3, place a junction }
               if cntend(d^.w.e.x, d^.w.e.y) >= 2 then begin

                  plcjun(d^.w.e.x, d^.w.e.y, l1); { place junction }
                  pier(d^.w.e.x, d^.w.e.y, curwin^.cs^.js, black,
                       curwin^.cs^.vp.v); { display junction }
                  attwire(l1, l) { attach to wire }

               end

            end else
            { check both lines orthogonal, and
              an endpoint "contained" within the other }
            if orthogonal(d) and orthogonal(l) then begin

               if contained(d^.w.s.x, d^.w.s.y, l) then
                  midatt(d^.w.s.x, d^.w.s.y)
               else if contained(d^.w.e.x, d^.w.e.y, l) then
                  midatt(d^.w.e.x, d^.w.e.y)
               else if contained(l^.w.s.x, l^.w.s.y, d) then
                  midatt(l^.w.s.x, l^.w.s.y)
               else if contained(l^.w.e.x, l^.w.e.y, d) then
                  midatt(l^.w.e.x, l^.w.e.y)

            end

         end

      end else if ((l^.typ = tjunction) or
                   (l^.typ = tconnect)) and orthogonal(d) then
         { junction, see if crosses line }
         if contained(l^.j.x, l^.j.y, d) then
            attwire(d, l); { attach to junction }
      l := l^.next { index next entry }

   end;
   { check node was found }
   if d^.nh = nil then begin { no match, enter new node }

      crtnod(n); { get new node entry }
      n^.nl := d; { link in wire }
      d^.nl := nil; { clear next }
      d^.nh := n { set head pointer }

   end

end;
{}
{**************************************************************

LINK BUS TO NODE(S)

The given bus is linked into a bus list. First, the bus is checked
for intersection with existing buses, and if found, that bus list
is linked. Otherwise, the bus gets its own, new bus list.
Intersection is determined in two ways. Endpoint intersection
is when the (x,y) start or end points are co-ordinate. This works
on any line.
The second type is when both lines are 90 deg orthogonal, and
one line's endpoint meets another's midsection. This case
automatically generates a junction between the lines.

**************************************************************}

procedure lnkbus(d: drwptr);

var l, l1: drwptr;  { drawing list pointer }
    f:     boolean; { wire found flag }
    n:     nodptr;  { node list pointer }
    b:     busptr;  { bus pointer }

{ place midline junction }

procedure midatt(x, y: integer);

var p: drwptr;

begin

   if not colinear(d, l) then begin

      plcjun(x, y, p); { place junction }
      pier(x, y, curwin^.cs^.js, black, curwin^.cs^.vp.v); { display junction }
      attwire(p, l) { attach to wire }

   end;
   attwire(d, l); { attach to this wire }
   f := true { flag wire found }

end;

begin

   { check for colinear lines }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      l1 := l^.next; { save next }
      if l^.typ = tbus then { bus }
         { both lines are orthogonal and colinear }
         if colinear(d, l) and
            (contained(d^.bs.l.s.x, d^.bs.l.s.y, l) or
             contained(d^.bs.l.e.x, d^.bs.l.e.y, l)) then
            join(d, l); { joint the two lines together }
      l := l1 { link next }

   end;
   d^.bs.bh := nil; { clear bus head }
   l := curwin^.cs^.dl[ltfig]; { index top of list }
   while l <> nil do begin { traverse list }

      if l^.typ = tbus then begin

         { check various intersections }
         { check any of the endpoints co-ordinate }
         if ((d^.bs.l.s.x = l^.bs.l.s.x) and
             (d^.bs.l.s.y = l^.bs.l.s.y)) or
            ((d^.bs.l.s.x = l^.bs.l.e.x) and
             (d^.bs.l.s.y = l^.bs.l.e.y)) then begin

            attwire(d, l); { attach to this bus }
            { if we reach 3, place a junction }
            if cntend(d^.bs.l.s.x, d^.bs.l.s.y) >= 2 then begin

               plcjun(d^.bs.l.s.x, d^.bs.l.s.y, l1); { place junction }
               { display junction }
               pier(d^.bs.l.s.x, d^.bs.l.s.y, curwin^.cs^.js, black,
                    curwin^.cs^.vp.v);
               attwire(l1, l) { attach to wire }

            end

         end else if ((d^.bs.l.e.x = l^.bs.l.s.x) and
                      (d^.bs.l.e.y = l^.bs.l.s.y)) or
                     ((d^.bs.l.e.x = l^.bs.l.e.x) and
                      (d^.bs.l.e.y = l^.bs.l.e.y)) then begin

            attwire(d, l); { attach to this bus }
            { if we reach 3, place a junction }
            if cntend(d^.bs.l.e.x, d^.bs.l.e.y) >= 2 then begin

               plcjun(d^.bs.l.e.x, d^.bs.l.e.y, l1); { place junction }
               { display junction }
               pier(d^.bs.l.e.x, d^.bs.l.e.y, curwin^.cs^.js, black,
                    curwin^.cs^.vp.v);
               attwire(l1, l) { attach to wire }

            end

         end else
         { check both lines orthogonal, and
           an endpoint "contained" within the other }
         if contained(d^.bs.l.s.x, d^.bs.l.s.y, l) then
            midatt(d^.bs.l.s.x, d^.bs.l.s.y)
         else if contained(d^.bs.l.e.x, d^.bs.l.e.y, l) then
            midatt(d^.bs.l.e.x, d^.bs.l.e.y)
         else if contained(l^.bs.l.s.x, l^.bs.l.s.y, d) then
            midatt(l^.bs.l.s.x, l^.bs.l.s.y)
         else if contained(l^.bs.l.e.x, l^.bs.l.e.y, d) then
            midatt(l^.bs.l.e.x, l^.bs.l.e.y)

      end else if (l^.typ = tjunction) or (l^.typ = tconnect)  then
         { junction, see if crosses line }
         if contained(l^.j.x, l^.j.y, d) then
            attwire(d, l); { attach to junction }
      l := l^.next { index next entry }

   end;
   if d^.bs.bh = nil then begin { no match, enter new node }

      crtbus(b); { get new bus entry }
      b^.bl := d; { link in bus }
      d^.bs.bl := nil;
      d^.bs.bh := b { set head pointer }

   end

end;
{}
{ UNRESOLVED: names used here that are defined outside this fragment:
     puck                        - global (icddef)
     curwin, smslst, bsmlst      - globals (icddef)
     intstr                      - frag_c.pas
     pier                        - frag_b.pas
     setbound, setsbound, chktar - frag_d.pas
  drwfig (being ported in parallel as frag_f) is NOT referenced in this
  range. Integrator: replace the resptr stub in icdui_base.pas with
     procedure resptr; forward;
  (frag_d's mode handlers call resptr, and this fragment must follow
  frag_d for setbound/setsbound/chktar) — verified to build with this
  fragment concatenated between frag_e and frag_m. }

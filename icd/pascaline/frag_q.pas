{******************************************************************************

FRAGMENT Q: SIMULATE MODE LAYER

Ported from icdh.pas (complete file). Contains the simulate mode
set (setsimulate), the digital and analog trace drawers (dtrace,
atrace) called by drwfig for the ttrc/tatrc figure types, the
trace line editors (trclin, atrclin) and the waveform edit
command (dowave).

Port notes:

1. All external declarations deleted per spec rule 2; every name
   resolves in frag_b/c/d/f/n except dmenu (icdg fragment, ported
   in parallel) - see UNRESOLVED at the end.
2. All numeric constants in this file (trace height 4800, the
   state baseline offsets 900/2400/3900, trcsiz/stpsiz multiples,
   timesiz/voltsiz scaling, the 6.5 volt center) are virtual
   (real) trace coordinates, converted to the screen by viewc/
   line/liner - none are interface pixels, so no uiscl scaling
   applies anywhere in this fragment.
3. The variant guards here read the active variant's own fields
   (ttrc guard reads ts, tatrc guard reads as) - no punning
   repairs were needed. The tatrc field name "as" is legal in
   P6/Pascaline and ports unchanged.
4. No timing (wait/gettim) logic existed in icdh.pas.
5. Replaces the icdui_base.pas stubs setsimulate, dowave, dtrace
   and atrace (integrator: remove those stubs when concatenating
   this fragment).

******************************************************************************}

{}
{**************************************************************

SET SIMULATE MODE

Sets the simulate mode. The simulate sheet in the current cell
is set current.

**************************************************************}

procedure setsimulate;

begin

   if (puck.b[1].a or puck.b[2].a or puck.b[4].a) and
      not button[bsimulate].act then begin { not already active }

      canact; { cancel activities }
      curscm := [smsimulate]; { set symbol screen mode }
      pixsiz := dftsiz; { set base scale }
      butact(bsimulate); { activate layout button }
      butina(blayout); { deactivate other buttons }
      butina(bschema);
      butina(bsymbol);
      { port: the original called dmenu (no surviving definition) and
        dispcell; converted to the setschema/setlayout pattern - dispwin
        redraws frame and menu for the new mode, then performs dispcell }
      dispwin { display new window }

   end;
   resptr { reset buttons }

end;
{}
{**************************************************************

DRAW TRACE

Draws the given trace at the given position.
The trace is drawn from the given point to the left, using
substitute colors.

**************************************************************}

procedure dtrace(ts: point;   { start point of trace }
                 tl: trcptr;  { trace list }
                 r:  region); { clip region }

var tc:   color;   { trace color }
    ltc:  color;   { last trace color }
    off:  integer; { baseline offset }
    loff: integer; { last offset }
    ltp:  trcptr;  { last trace entry }
    ib:   region;  { trace inclusion region }
    cl:   region;  { connection line }
    nl:   region;  { next line }
    t:    integer;

{ set color and offset according to state }

procedure setclr(s: nodest);

begin

   case s of { set trace color }

      nsundef: begin tc := yellow;  off := 2400 end; { soft unknown }
      nsindet: begin tc := yellow;  off := 2400 end; { soft unknown }
      nsindrh: begin tc := brown;   off := 2400 end; { hard unknown }
      nsindrl: begin tc := brown;   off := 2400 end; { hard unknown }
      nswidh:  begin tc := brown;   off := 2400 end; { hard unknown }
      nswidl:  begin tc := brown;   off := 2400 end; { hard unknown }
      nscont:  begin tc := lred;    off := 2400 end; { conflict }
      nswcont: begin tc := lred;    off := 2400 end; { conflict }
      nshigh:  begin tc := green;   off := 900  end; { hard high }
      nslow:   begin tc := blue;    off := 3900 end; { hard low }
      nsstrh:  begin tc := cyan;    off := 900  end; { soft high }
      nsstrl:  begin tc := magenta; off := 3900 end; { soft low }
      nswhigh: begin tc := green;   off := 900  end; { hard high }
      nswlow:  begin tc := blue;    off := 3900 end; { hard low }
      nsvdd:   begin tc := green;   off := 900  end; { hard high }
      nsvss:   begin tc := blue;    off := 3900 end; { hard low }

   end

end;

begin

   ib.s := ts; { set screen y width of trace }
   ib.e := ts;
   ib.e.y := ib.e.y + 4800;
   viewc(ib.s, curwin^.cs^.vp); { convert }
   viewc(ib.e, curwin^.cs^.vp);
   if (ib.s.y <= r.e.y) and (ib.e.y >= r.s.y) and
      (ib.s.x <= r.e.x) then begin

      { trace overlays region at any point }
      ltp := nil; { set no last trace }
      while tl <> nil do begin { traverse list }

         setclr(tl^.state); { set trace color }
         if ltp <> nil then begin { there is a last entry }

            { set next line }
            nl.s.x := ts.x+(ltp^.time*stpsiz);
            nl.s.y := ts.y+loff;
            nl.e.x := ts.x+(tl^.time*stpsiz);
            nl.e.y := ts.y+loff;
            viewc(nl.s, curwin^.cs^.vp); { convert }
            viewc(nl.e, curwin^.cs^.vp);
            { set connecting line }
            cl.s.x := ts.x+(tl^.time*stpsiz);
            cl.s.y := ts.y+loff;
            cl.e.x := cl.s.x;
            cl.e.y := ts.y+off;
            if cl.s.y > cl.e.y then begin { rationalize }

               t := cl.s.y;
               cl.s.y := cl.e.y;
               cl.e.y := t

            end;
            viewc(cl.s, curwin^.cs^.vp); { convert }
            viewc(cl.e, curwin^.cs^.vp);
            if nl.s.x > r.e.x then tl := nil { past view, terninate }
            else if (nl.s.x <= r.e.x) and (nl.e.x >= r.s.x) then begin

               { section in view }
               { draw new trace portion }
               if (nl.s.y >= r.s.y) and (nl.s.y <= r.e.y) then
                  begin

                  if nl.s.x < r.s.x then nl.s.x := r.s.x;
                  if nl.e.x > r.e.x then nl.e.x := r.e.x;
                  line(screen, nl.s.x, nl.s.y, nl.e.x, nl.e.y, ltc)

               end;
               { connect last state to this state }
               if (off <> loff) and (cl.s.x >= r.s.x) and
                  (cl.s.x <= r.e.x) and (cl.s.y <= r.e.y) and
                  (cl.e.y >= r.s.y) then begin

                  if cl.s.y < r.s.y then cl.s.y := r.s.y;
                  if cl.e.y > r.e.y then cl.e.y := r.e.y;
                  line(screen, cl.s.x, cl.s.y, cl.e.x, cl.e.y, black)

               end

            end

         end;
         ltc := tc; { set last trace color }
         loff := off; { set last offset }
         ltp := tl; { set last trace }
         if tl <> nil then tl := tl^.next { index next entry }

      end

   end

end;
{}
{**************************************************************

DRAW ANALOG TRACE

Draws the given trace at the given position.
The trace is drawn from the given point to the left, using
substitute colors.

**************************************************************}

procedure atrace(ts: point;   { start point of trace }
                 tl: atrcptr; { trace list }
                 r:  region); { clip region }

var ltp:  atrcptr; { last trace entry }
    ib:   region;  { trace inclusion region }
    nl:   region;  { next line }
    draw: boolean; { draw flag }

begin

   ib.s := ts; { set screen y width of trace }
   ib.e := ts;
   ib.e.y := ib.e.y + 4800;
   viewc(ib.s, curwin^.cs^.vp); { convert }
   viewc(ib.e, curwin^.cs^.vp);
   if (ib.s.y <= r.e.y) and (ib.e.y >= r.s.y) and
      (ib.s.x <= r.e.x) then begin

      { trace overlays region at any point }
      ltp := nil; { set no last trace }
      while tl <> nil do begin { traverse list }

         if ltp <> nil then begin { there is a last entry }

            { set next line }
            nl.s.x := ts.x+round(ltp^.time/timesiz);
            nl.s.y := ts.y+round((6.5-ltp^.v)/voltsiz);
            nl.e.x := ts.x+round(tl^.time/timesiz);
            nl.e.y := ts.y+round((6.5-tl^.v)/voltsiz);
            viewc(nl.s, curwin^.cs^.vp); { convert }
            viewc(nl.e, curwin^.cs^.vp);
            if nl.s.x > r.e.x then { past view, terminate }
               tl := nil
            else begin { in or in front of view }

               if (nl.s.x = nl.e.x) or (nl.s.y = nl.e.y) then
                  { orthogonal line, clip to critical region }
                  clip(nl.s.x, nl.s.y, nl.e.x, nl.e.y, draw, r)
               else
                  { clip to viewport }
                  clip(nl.s.x, nl.s.y, nl.e.x, nl.e.y, draw,
                       curwin^.cs^.vp.v);
               if draw then
                  line(screen, nl.s.x, nl.s.y, nl.e.x, nl.e.y, black)

            end

         end;
         ltp := tl; { set last trace }
         if tl <> nil then tl := tl^.next { index next entry }

      end

   end

end;
{}
{**************************************************************

ENTER TRACE LINE

A single line of a digital trace is entered. This line must
have nonzero time demension (since voltage connections are done
automatically). This also means that no change in voltage is
allowed.
The line is editted into an existing trace if one exists, or
a new trace is created.

**************************************************************}

procedure trclin(x1, y1, x2, y2: integer);

var tr, tr2: trcptr;  { trace entry pointer }
    d, d1:   drwptr;  { draw entry pointers }
    st, st2: nodest;  { node state }
    off:     integer; { baseline offset }
    loff:    integer; { last offset }
    tc:      color;   { trace color }
    tb:      region;  { trace box }
    s, e:    integer; { start and end step time }
    ts, te:  integer; { temp start and end }

{ find state offset }

function stoff(st: nodest): integer;

var o: integer;

begin

   case st of { set trace offset }

      nsundef: o := 2400; { soft unknown }
      nsindet: o := 2400; { soft unknown }
      nsindrh: o := 2400; { hard unknown }
      nsindrl: o := 2400; { hard unknown }
      nswidh:  o := 2400; { hard unknown }
      nswidl:  o := 2400; { hard unknown }
      nscont:  o := 2400; { conflict }
      nswcont: o := 2400; { conflict }
      nshigh:  o := 900;  { hard high }
      nslow:   o := 3900; { hard low }
      nsstrh:  o := 900;  { soft high }
      nsstrl:  o := 3900; { soft low }
      nswhigh: o := 900;  { hard high }
      nswlow:  o := 3900; { hard low }
      nsvdd:   o := 900;  { hard high }
      nsvss:   o := 3900  { hard low }

   end;
   stoff := o { return result }

end;

begin

   rescur; { lift cursor }
   ratlin(x1, y1, x2, y2); { ensure rational }
   tb.s.y := (y1 div trcsiz) * trcsiz; { find trace base }
   tb.e.y := tb.s.y + trcsiz; { find trace end }
   tb.s.x := x1;
   tb.e.x := x2;
   d1 := curwin^.cs^.dl[ltfig]; { search for existing trace }
   d := nil;
   while d1 <> nil do begin

      if d1^.typ = ttrc then
         if d1^.ts.y = tb.s.y then d := d1; { found, save }
      d1 := d1^.next { next entry }

   end;
   if d = nil then begin { no trace found, create one }

      new(d); { get new entry }
      d^.typ := ttrc; { set type }
      d^.ts.y := tb.s.y; { set base }
      d^.ts.x := 0;
      d^.tl := nil; { clear trace list }
      d^.next := curwin^.cs^.dl[ltfig]; { insert to list }
      curwin^.cs^.dl[ltfig] := d

   end;
   { find start and end times }
   s := x1 div stpsiz;
   e := x2 div stpsiz;
   { find state }
   if (y1 mod trcsiz) = 900 then st := nshigh { high }
   else if (y1 mod trcsiz) = 2400 then st := nsindet { indeterminate }
   else st := nslow; { low }
   { erase overwritten traces }
   tr := d^.tl; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if tr2 <> nil then begin { there is a last entry }

         loff := stoff(tr2^.state); { find last state }
         off := stoff(tr^.state); { find this state }
         { erase horizontal lines }
         if ((tr^.time >= s) and (tr^.time <= e)) or
            ((tr2^.time >= s) and (tr2^.time <= e)) then begin

            { one end in overwrite region }
            ts := tr2^.time; { set start and end }
            te := tr^.time;
            if ts < s then ts := s; { clip }
            if te > e then te := e;
            { white out line }
            liner(ts*stpsiz, tb.s.y+loff, te*stpsiz,
                  tb.s.y+loff, white, curwin^.cs^.vp.v)

         end;
         { erase vertical lines }
         if (tr^.time >= s) and (tr^.time <= e) then
            if loff <> off then { not same state }
               { white out line }
               liner(tr^.time*stpsiz, tb.s.y+loff,
                     tr^.time*stpsiz,
                     tb.s.y+off, white, curwin^.cs^.vp.v)

      end;
      tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { find 2nd (ending) state }
   tr := d^.tl; { index list top }
   tr2 := nil; { set found entry nil }
   st2 := st; { set as begining }
   while tr <> nil do begin { traverse }

      if tr^.time > e then begin { found }

         tr2 := tr; { place entry }
         tr := nil { flag complete }

      end else begin

         st2 := tr^.state; { set running state }
         tr := tr^.next { next entry }

      end

   end;
   { if no proper ending, set to same as begining }
   if tr2 = nil then st2 := st;
   { delete all entries to overwritten by new section }
   tr := d^.tl; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if (tr^.time >= s) and (tr^.time <= e) then begin

         { delete trace entry }
         if tr2 = nil then d^.tl := tr^.next { gap list }
         else tr2^.next := tr^.next { gap list }

      end else tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { find last entry before insert }
   tr := d^.tl; { index 1st trace entry }
   tr2 := nil; { clear last }
   while tr <> nil do begin { traverse }

      if tr^.time > s then tr := nil { flag found }
      else begin { next entry }

         tr2 := tr; { set last }
         tr := tr^.next { next entry }

      end

   end;
   new(tr); { get new trace entry }
   tr^.time := s; { place time }
   tr^.state := st; { place state }
   if tr2 = nil then begin { insert at top }

      tr^.next := d^.tl; { link in }
      d^.tl := tr

   end else begin { insert middle }

      tr^.next := tr2^.next; { link in }
      tr2^.next := tr

   end;
   tr2 := tr; { save as last }
   new(tr); { get new trace entry }
   tr^.time := e; { place time }
   tr^.state := st2; { place state }
   tr^.next := tr2^.next; { link in }
   tr2^.next := tr;
   { refresh region of trace }
   rregion(tb.s.x, tb.s.y, tb.e.x, tb.e.y);
   setcur { replace cursor }

end;
{}
{**************************************************************

ENTER ANALOG TRACE LINE

A single line of a analog trace is entered.
The line is editted into an existing trace if one exists, or
a new trace is created.

**************************************************************}

procedure atrclin(x1, y1, x2, y2: integer);

var tr, tr2: atrcptr; { trace entry pointer }
    tb:      region;  { trace box }
    s, e:    real;    { start and end time }
    d, d1:   drwptr;  { draw entry pointers }
    ts, te:  integer; { start and end temp }

begin

   rescur; { lift cursor }
   ratlin(x1, y1, x2, y2); { ensure rational }
   tb.s.y := (y1 div trcsiz) * trcsiz; { find trace base }
   tb.e.y := tb.s.y + trcsiz; { find trace end }
   tb.s.x := x1;
   tb.e.x := x2;
   d1 := curwin^.cs^.dl[ltfig]; { search for existing trace }
   d := nil;
   while d1 <> nil do begin

      if d1^.typ = tatrc then
         if d1^.as.y = tb.s.y then d := d1; { found, save }
      d1 := d1^.next { next entry }

   end;
   if d = nil then begin { no trace found, create one }

      new(d); { get new entry }
      d^.typ := tatrc; { set type }
      d^.as.y := tb.s.y; { set base }
      d^.as.x := 0;
      d^.al := nil; { clear trace list }
      d^.next := curwin^.cs^.dl[ltfig]; { insert to list }
      curwin^.cs^.dl[ltfig] := d

   end;
   { find start and end times }
   s := x1 * timesiz;
   e := x2 * timesiz;
   { erase overwritten traces }
   tr := d^.al; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if tr2 <> nil then begin { there is a last entry }

         { erase lines }
         if (tr2^.time <= e) and (tr^.time >= s) then begin

            { crosses our region }
            ts := d^.as.x+round(tr2^.time/timesiz);
            te := d^.as.x+round(tr^.time/timesiz);
            { extend region to cover }
            if ts < tb.s.x then tb.s.x := ts;
            if te > tb.e.x then tb.e.x := te;
            { white out line }
            liner(d^.as.x+round(tr2^.time/timesiz),
                  d^.as.y+round((6.5-tr2^.v)/voltsiz),
                  d^.as.x+round(tr^.time/timesiz),
                  d^.as.y+round((6.5-tr^.v)/voltsiz),
                  white, curwin^.cs^.vp.v)

         end

      end;
      tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { delete all entries to overwritten by new section }
   tr := d^.al; { index 1st trace entry }
   tr2 := nil; { clear last entry }
   while tr <> nil do begin { traverse }

      if (tr^.time >= s) and (tr^.time <= e) then begin

         { delete trace entry }
         if tr2 = nil then d^.al := tr^.next { gap list }
         else tr2^.next := tr^.next { gap list }

      end else tr2 := tr; { set last }
      tr := tr^.next { next entry }

   end;
   { find last entry before insert }
   tr := d^.al; { index 1st trace entry }
   tr2 := nil; { clear last }
   while tr <> nil do begin { traverse }

      if tr^.time > s then tr := nil { flag found }
      else begin { next entry }

         tr2 := tr; { set last }
         tr := tr^.next { next entry }

      end

   end;
   new(tr); { get new trace entry }
   tr^.time := s; { place time }
   tr^.v := 6.5-((y1-tb.s.y)*voltsiz); { place value }
   if tr2 = nil then begin { insert at top }

      tr^.next := d^.al; { link in }
      d^.al := tr

   end else begin { insert middle }

      tr^.next := tr2^.next; { link in }
      tr2^.next := tr

   end;
   tr2 := tr; { save as last }
   new(tr); { get new trace entry }
   tr^.time := e; { place time }
   tr^.v := 6.5-((y2-tb.s.y)*voltsiz); { place value }
   tr^.next := tr2^.next; { link in }
   tr2^.next := tr;
   { refresh region of trace }
   rregion(tb.s.x, tb.s.y, tb.e.x, tb.e.y);
   setcur { replace cursor }

end;
{}
{**************************************************************

PERFORM WAVEFORM EDIT

Handles the mode, setup and entry of waveforms.

**************************************************************}

procedure dowave;

var l:      drwptr; { line entry }
    i:      btsinx;
    p:      point;
    xd, yd: integer;
    el:     boolean; { line was entered }

begin

   el := false; { set no line entered }
   if (curbut in [bdwave, bawave]) and
      (puck.b[1].a or puck.b[2].a or puck.b[4].a) then begin

      { set wave mode }
      stopact; { stop all modes }
      butact(curbut); { set wave mode active }
      modbut := curbut;
      dsmbut := curbut

   end else if (drmbut in [bdwave, bawave]) and
               inactive(cur) and
               (puck.b[2].a or puck.b[1].a or
                (puck.b[1].d and puck.b[1].dg) or
                (puck.b[4].s and (drmbut = bawave) and
                 ((str.x <> endp.x) or (str.y <> endp.y)))) then
      begin

      { enter wave }
      setend; { make sure end is established }
      if not cntdrw then cruler; { clear ruler }
      if drmbut = bawave then atrclin(str.x, str.y, endp.x, endp.y)
      { if occupies time, enter to trace }
      else if str.x <> endp.x then trclin(str.x, str.y, endp.x, endp.y)
      else begin

         rescur; { remove cursor }
         resline; { reset line from screen }
         setcur; { replace cursor }

      end;
      lindwn := false; { since we have overwritten saved line }
      drmbut := bnull; { reset mode }
      cntdrw := false;
      el := true { set line was entered }

   end;
   if inactive(cur) and
      (puck.b[1].a or (puck.b[2].a and not el) or
       (puck.b[4].s and button[bawave].act and
        (drmbut <> bawave))) then begin

      { begin wave }
      cntdrw := puck.b[4].s; { set continous draw mode }
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
      if button[bdwave].act then drmbut := bdwave
      else drmbut := bawave;
      updrul { update ruler }

   end;
   if cntdrw and not puck.b[4].s then begin

      { continous draw dropped, exit mode }
      rescur; { remove cursor }
      resline; { reset line from screen }
      setcur; { replace cursor }
      lindwn := false; { since we have overwritten saved line }
      drmbut := bnull; { reset mode }
      cntdrw := false

   end;
   resptr { reset buttons }

end;
{}
{ UNRESOLVED: names called here but defined outside this fragment:

  icdg fragment (parallel): dmenu - draw menu; called by setsimulate.
  Until that fragment lands, a temporary "procedure dmenu; begin end;"
  stub ahead of this fragment satisfies the reference.
  Stub replacement: this fragment supplies the real setsimulate,
  dowave, dtrace and atrace; the matching no-op stubs in
  icdui_base.pas must be removed at integration (dtrace/atrace are
  called earlier by drwfig in frag_f, so if forward references are
  needed, convert those two stubs to forward declarations instead).
  Callers wired elsewhere: frag_g dispatch (bsimulate -> setsimulate,
  bdwave/bawave -> dowave), frag_f drwfig (ttrc -> dtrace,
  tatrc -> atrace). }

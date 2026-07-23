{**************************************************************
*                                                             *
*               CMOS ANALOG CIRCUIT SIMULATOR                 *
*                                                             *
*                    9/89 S. A. Moore                         *
*                                                             *
* An analog version of the digital circuit simulator,         *
* simlates mosfets, capacitors and resistors, essentailly     *
* all the elements avalible in a CMOS IC. Simulates with      *
* voltage plots. The algorithim used is based on simplified   *
* formulas, and therefore lies between the accuracy of a      *
* state simulator and "spice".                                *
*                                                             *
**************************************************************}

program sim(command, output);

uses strings;

label 99; { abort program }

const linmax = 80; { maximum command line }
      labmax = 20; { maximum characters per label }

type bytfil  = file of byte; { byte file }
     labinx  = 1..labmax; { index for label }
     nodlab  = packed array [labinx] of char; { label for node }
     nodptr  = ^node;   { node pointer }
     node    = record   { node }

                  voll:   real;    { last node voltage }
                  voln:   real;    { next node voltage }
                  trc:    boolean; { node is traced }
                  isum:   real;    { sum of currents }
                  cap:    real;    { total capacitience }
                  setv:   boolean; { set mode }
                  inc:    real;    { voltage increment }
                  ltrc:   real;    { last traced voltage }
                  num:    integer; { node number }
                  next:   nodptr   { next list node }

               end;
     { device file codes }
     devtyp  = (dpmos,   { p-channel }
                dnmos,   { n-channel }
                dres);   { resistor }
     devptr  = ^dev;     { pointer to device }
     dev     = record

                  dtype:  devtyp;    { device type }
                  source: nodptr;    { source node connect (or a) }
                  gate:   nodptr;    { gate node connect }
                  drain:  nodptr;    { drain node connect (or b) }
                  width:  real;      { width (or resistance) }
                  length: real;      { length }
                  gain:   real;      { gain factor, or K(W/L) }
                  next:   devptr;    { next in list }

               end;
    lininx   = 1..linmax; { command line index }
    errcod   = (eilovf,   { input line too long }
                ecfns,    { circuit file not specified }
                eivopt,   { invalid option }
                ecfnf,    { net file not found }
                estfnf,   { set file not found }
                einvnff,  { invalid input file format }
                elabtl,   { label too long }
                eivlor,   { input value out of range }
                einvctk,  { input command inappropriate for simulator }
                efnft,    { file not flat }
                esys);    { system error }
    line     = array [lininx] of char;   { input line buffer }
    setptr   = ^nodset; { node set entry pointer }
    nodset   = record   { node set entry }

                  clk:   integer; { clock to trigger on }
                  nod:   nodptr;  { node to set }
                  vol:   real;    { state to set to }
                  drv:   boolean; { state of drive }
                  next:  setptr   { next entry }

               end;

var devtbl: devptr;  { device list }
    nodtbl: nodptr;  { node list }
    settbl: setptr;  { node set list }
    curset: setptr;  { current set }
    clkcnt: integer; { current clock }
    cmdlin: line;    { input command buffer }
    cmdptr: lininx;  { current command line position }
    simnam: nodlab;  { sim file name }
    simfil: bytfil;  { sim file }
    simopn: boolean; { sim file open }
    setnam: nodlab;  { set file name }
    setfil: bytfil;  { set file }
    setopn: boolean; { set file open }
    trcnam: nodlab;  { trace file name }
    trcfil: bytfil;  { trace file }
    trcopn: boolean; { trace file open }
    stpcnt: integer; { step count }
    span:   real;    { time span for cycle }
    limit:  real;    { minimum change to output trace }
    pthresh, nthresh: real; { threshold voltages }
    pconst, nconst:  real; { process constants }
    fverb:  boolean; { verbose flag }

{**************************************************************

Process error

Prints an error message by the given error code and aborts.
The procedure does not return.

**************************************************************}

procedure error(e: errcod);

begin

   write('*** '); { output header }
   case e of { error }

      eilovf:  writeln('Input line overflow');
      ecfns:   writeln('Circuit file not specified');
      eivopt:  writeln('Invalid option');
      ecfnf:   writeln('Net file not found');
      estfnf:  writeln('Set file not found');
      einvnff: writeln('Invalid input file format');
      elabtl:  writeln('Filename too long');
      eivlor:  writeln('Input value out of range');
      einvctk: writeln('Input command inappropriate for simulator');
      efnft:   writeln('Input file is not flat');
      esys:    writeln('System error: contact Moore/CAD');

   end;
   goto 99

end;

{**************************************************************

Add extention

Adds the extention to the filename. If an extention is already
present, this is left alone.

**************************************************************}

procedure addext(var w: nodlab;  { filename }
                     e: nodlab); { extention }

var i1, i2: labinx; { indexes for labels }

begin

   i1 := 1; { index start of filename }
   { skip to first '.' or space }
   while (i1 < labmax) and (w[i1] <> '.') and
         (w[i1] <> ' ') do i1 := i1 + 1;
   if w[i1] <> '.' then begin { no extention present }

      if w[i1] = ' ' then begin { plant extention }

         i2 := 1; { set 1st extention }
         while i1 <= labmax do begin

            w[i1] := e[i2]; { place character }
            i1 := i1 + 1; { next characters }
            i2 := i2 + 1

         end;
         if i2 < labmax then
            if e[i2] <> ' ' then error(elabtl) { error }

      end

   end

end;

{**************************************************************

Read input line

Reads a line of text from the given text file into the
command buffer. No interactive processing is implemented.

**************************************************************}

procedure readline(var f: text); { input file }

var i : lininx; { index for line }

begin

   for i := 1 to linmax do cmdlin[i] := ' '; { clear command line }
   i := 1; { set 1st character position }
   while not eoln(f) do begin { read characters }

      if i > linmax then error(eilovf); { process error }
      read(f, cmdlin[i]); { get a character }
      i := i + 1 { next character position }

   end;
   readln(f); { skip line end }
   cmdptr := 1 { set 1st character position }

end;

{**************************************************************

Check character

Returns the character at the current command line position.
If the position is off the end of the line, a blank is returned
instead.

**************************************************************}

function chkchr: char;

var c : char;

begin

   { return contents of at line }
   if cmdptr <= linmax then c := cmdlin[cmdptr]
   else c := ' '; { off end, return zip }
   chkchr := c { return result }

end;

{**************************************************************

Get character

Skips to the next command line character. This will only
occur if we are not at the end of the line.

**************************************************************}

procedure getchr;

begin

   if cmdptr <= linmax then cmdptr := cmdptr + 1 { advance }

end;

{**************************************************************

Skip spaces

Skips spaces in the command line. If at line end, we stop.

***************************************************************}

procedure skpspc;

begin

   while (chkchr = ' ') and (cmdptr <= linmax) do
      getchr

end;

{**************************************************************

Get word

Gets a word from the command line. This will be any sequence
of non-space characters after any leading spaces, and
terminated by a space.
Generates an error on label overflow or no word found.

***************************************************************}

procedure getword(var n: nodlab);

var i : labinx; { index for label }

begin

   n := '                    ';
   skpspc; { skip spaces }
   i := 1; { initalize label pointer }
   while (chkchr <> ' ') and (chkchr <> '!') do begin

      if i > labmax then error(elabtl); { process error }
      n[i] := chkchr; { place character }
      i := i + 1; { next character }
      getchr { next character }

   end;
   { convert to lower case }
   for i := 1 to labmax do n[i] := lcase(n[i]);
   if n = '                    ' then error(ecfns) { no word found }

end;

{**************************************************************

Process caller line

Read a line from the given file, and processes the circuit
file there and any command line options.

**************************************************************}

procedure prcopt(var f: text);

begin

   readline(f); { load command line }
   skpspc; { skip spaces }
   if cmdptr > linmax then error(ecfns); { error }
   getword(simnam); { get the circuit file name }
   skpspc; { skip spaces }
   while cmdptr <= linmax do begin { process options }

      if chkchr <> '#' then error(eivopt); { error }
      getchr;
      if not (lcase(chkchr) in ['v']) then
         error(eivopt); { error }
      case lcase(chkchr) of { option }

         'v': begin { set verbose mode }

                 fverb := true; { set }
                 getchr { skip }

              end;

      end;
      skpspc { skip spaces }

   end

end;

{**************************************************************

Create new node entry

Creates a new node entry by the given number, and returns
a pointer to it.
If the number matches an entry already present, that is returned,
else a new entry is created.
If the new entry is not contingious with the entries
present, the table is filled until it is. Herein lies
the importance of a continigous node numbering system.
The node is placed into the list in alphabetical order.

**************************************************************}

procedure newnode(    n: integer; { label for node }
                  var p: nodptr); { create new node }

var l: nodptr;  { node index }
    c: integer; { node counter }
    f: boolean; { found flag }

begin

   p := nodtbl; { index node root }
   l := nil; { clear last }
   c := 0; { set node number count }
   f := false; { set not found }
   while (p <> nil) and not f do begin { search }

      if c = n then f := true { found }
      else begin

         c := c + 1; { count }
         l := p; { set last }
         p := p^.next { next }

      end

   end;
   if not f then repeat { insert }

         new(p); { get new node entry }
         p^.voll := 0.0;   { set 0 }
         p^.voln := 0.0;
         p^.trc    := false;   { set not traced }
         p^.isum := 0.0;
         p^.cap  := 0.0;
         p^.setv := false; { not in set }
         p^.inc  := 0.0;
         p^.ltrc := 0.0;
         p^.num    := c;       { place node number }
         p^.next   := nil;     { link to next }
         if l <> nil then l^.next := p { link last to us }
         else nodtbl := p; { link root to us }
         l := p; { set that as last }
         c := c + 1 { count that entry }

   until c > n

end;

{**************************************************************

Create new transistor

Creates a new transistor of the given type.
Accepts node labels for source, gate and drain, and connects
the transistor to these.

**************************************************************}

procedure newtrans(t:       devtyp;   { type of transistor }
                   s, g, d: integer;  { nodes }
                   wd, ln:  real);    { width and length  }

var f: devptr; { pointer to fet }
    n: nodptr; { pointer to node }

begin

   new(f); { get a new transistor entry }
   f^.dtype  := t;      { set type }
   newnode(s, n);       { get a source node }
   f^.source := n;      { place }
   newnode(g, n);       { get a gate node }
   f^.gate   := n;      { place }
   newnode(d, n);       { get a drain node }
   f^.drain  := n;      { place }
   f^.width := wd;      { place width }
   f^.length := ln;     { place length }
   f^.next := devtbl;   { place in list }
   devtbl := f

end;

{**************************************************************

Create new resistor

Creates a new resistor.
Accepts node labels for A and B, and connects
the resistor to these.

**************************************************************}

procedure newres(a, b: integer; { nodes }
                   var r: real);   { ohms }

var d: devptr; { pointer to device }
    n: nodptr; { pointer to node }

begin

   new(d); { get a new device entry }
   d^.dtype  := dres;   { set type }
   newnode(a, n);       { get A node }
   d^.source := n;      { place }
   newnode(b, n);       { get B node }
   d^.drain := n;       { place }
   d^.width := r;       { place resistance }
   d^.next := devtbl;   { place in list }
   devtbl := d

end;

{**************************************************************

Create set entry

Creates a set entry, with the given clock trigger, node to
set, and the state to set the node to.
The clock given is converted by the clock scaling to the tick
clock. This means that clocks triggered WITHIN a scaled clock
time happen at the start of that clock time.

**************************************************************}

procedure newset(n:  integer; { node to set to }
                 c:  integer; { clock to set on }
                 x:  boolean; { drive flag }
                 sv: real);   { set value }

var p: nodptr;   { node pointer }
    st: setptr; { set pointer }

begin

   new(st);       { create a set entry }
   newnode(n, p); { create a node }
   st^.clk   := c;      { place clock }
   st^.nod   := p;      { place node pointer }
   st^.vol   := sv;     { place set voltage }
   st^.drv   := x;      { place drive }
   if curset = nil then begin { first in list }

      settbl := st; { place as top entry }
      curset := st

   end else begin

      curset^.next := st; { attach to last }
      curset := st { index next }

   end;
   st^.next  := nil { terminate }

end;
{}
{**************************************************************

READ 32 BIT NUMBER FROM FILE

Reads a number in 32 bit signed magnitude format. The highest
order byte appears first, and the least order last. The high
byte 7th bit contains the sign.

**************************************************************}

procedure read32(var f: bytfil; var i: integer); 

var b: byte;    { read byte holder }
    s: integer; { sign of result }
    t: integer; { temp }

begin

   s := 1; { set no sign }
   read(f, b);
   if b >= 128 then begin { signed }

      s := -1; { set sign }
      b := b - 128 { remove sign }

   end;
   t := b; { place in large buffer }
   i := t*16777216;
   read(f, b);
   t := b; { place in large buffer }
   i := i + t*65536;
   read(f, b);
   t := b; { place in large buffer }
   i := i + t*256;
   read(f, b);
   i := i + b;
   i := i*s { set sign of result }

end;

{**************************************************************

WRITE 32 BIT NUMBER TO FILE

Writes a number in 32 bit signed mangnitude format to the
given file. The highest order byte appears first, and the least
order last. The high byte 7th bit contains the sign.

**************************************************************}

procedure write32(var f: bytfil; i: integer); 

var t, s: integer;

begin

   { set sign }
   if i < 0 then s := 128 else s := 0;
   i := abs(i); { remove sign }
   t := i div 16777216; { high byte }
   write(f, t+s); { with sign }
   i := i - (t * 16777216); { high middle }
   t := i div 65536;
   write(f, t);
   i := i - (t * 65536); { low middle }
   t := i div 256;
   write(f, t);
   i := i - (t * 256); { low }
   write(f, i)

end;

{**************************************************************

Read single real

Reads the single precision IEEE format real from the given
file, and converts that to our real.

**************************************************************}

procedure readsreal(var f: bytfil; var r: real);

var fc:  record case boolean of { float convertion }

            false: (r: sreal);
            true:  (b: packed array [1..4] of byte)

         end; 

begin

   read(f, fc.b[1]); { read bytes of single real }
   read(f, fc.b[2]);
   read(f, fc.b[3]);
   read(f, fc.b[4]);
   r := fc.r { place result }

end;

{**************************************************************

Write single real

Writes the single precision IEEE format real to the given
file, and converts that from our real.

**************************************************************}

procedure writesreal(var f: bytfil; { file to write }
                     var r: real);  { real to be written }
                    
var fc:  record case boolean of { float convertion }

            false: (r: sreal);
            true:  (b: packed array [1..4] of byte)

         end; 

begin

   fc.r := r; { place real in convertion area }
   write(f, fc.b[4]); { output }
   write(f, fc.b[3]);
   write(f, fc.b[2]);
   write(f, fc.b[1])

end;

{**************************************************************

Load circuit file

***************************************************************}

procedure loadckt(var f: bytfil);

var t:                        devtyp; { device type }
    clk:                      integer; { clock holder }
    s, g, d, n:               integer; { node numbers }
    a, b:                     integer;
    np:                       nodptr;
    c:                        byte; { tolken code holder }
    ohms, farads, sv, wd, ln: real; { various }

begin

   repeat { parse tolkens }

      read(f, c); { get next tolken code }
      case c div 16 of { operation code }

         0:; { eof, do nothing }

         1: begin { transistor }

               if ((c mod 4) div 2) <> 0 then
                  t := dnmos  { set N channel }
               else
                  t := dpmos; { set P channel }
               read32(f, s); { get source }
               read32(f, g); { get drain }
               read32(f, d); { get drain }
               readsreal(f, wd); { get width }
               readsreal(f, ln); { get length }
               newtrans(t, s, g, d, wd, ln) { create transistor }

            end;

         2: begin { resistor }

               read32(f, a); { get A terminal }
               read32(f, b); { get B terminal }
               readsreal(f, ohms); { get resistance }
               newres(a, b, ohms) { enter resistor }

            end;

         3: begin { set trace on node }

               read32(f, n); { get node number }
               newnode(n, np); { index that node }
               np^.trc := true { set node is traced }

            end;

         4: if (c mod 16) <> 0 then error(efnft)
            else read32(f, stpcnt); { enter step count }

         5: error(einvctk); { bad command for us }

         6: ; { run simulation (we ignore) }

         7: ; { read trace memory (we ignore) }

         8: begin { set node capacitience }

               read32(f, n); { get node number }
               readsreal(f, farads); { get node capacitience }
               newnode(n, np); { index that node }
               np^.cap := np^.cap + farads { set node capacitience }

            end;

         9: begin { set node voltage }

               read32(f, clk); { get the time }
               read32(f, n); { get the node }
               readsreal(f, sv); { get the voltage to set }
               { enter set }
               newset(n , clk, ((c mod 4) div 2) <> 0, sv)

            end;

         10: readsreal(f, span); { set span }

         11: readsreal(f, limit); { set trace limit }

         12: begin { read process parameters }

                readsreal(f, pthresh); { P threshold }
                readsreal(f, nthresh); { N threshold }
                readsreal(f, pconst);  { P process constant }
                readsreal(f, nconst)   { N process constant }

             end;

         13, 14, 15: error(einvnff) { invalid tolken }

      end

   until c = 0 { end of file }

end;
{**************************************************************

Calculate gain factors

The gain factor for mosfets can be calculated in advance, from
K(W/L), where K is the process constant, W is the width, and
L is the length.

**************************************************************}

procedure findgain;

var dp: devptr; { pointer for devices }

begin

   dp := devtbl; { index device table }
   while dp <> nil do begin { traverse devices }

      case dp^.dtype of { device }

         { P channel }
         dpmos: dp^.gain := pconst * (dp^.width/dp^.length);
         { N channel }
         dnmos: dp^.gain := nconst * (dp^.width/dp^.length);
         { Resistor, has no gain ! }
         dres:

      end;
      dp := dp^.next { link next entry }

   end

end;

{**************************************************************

Save node values

Copies all current node values to the last node value.
Also performs set voltage increments, and resets the current
sums for each node.

**************************************************************}

procedure save;

var p: nodptr; { pointer for nodes }

begin

   p := nodtbl; { index table }
   while p <> nil do begin { copy }

      p^.voll := p^.voln; { copy next to last }
      { process voltage increment as applicable }
      if p^.setv then p^.voln := p^.voln + p^.inc;
      p^.isum := 0.0; { clear current sum }
      p := p^.next { link next entry }

   end

end;

{**************************************************************

Process sets

Finds all sets that apply to the current clock, then processes
those sets. If the set is to turn drive off, the drive flag on
the node is removed. This allows the node to follow values
calculated for it from the net. If the set is for driven, the
node drive flag is turned on, and the indicated voltage replaces
(distructively) the current node voltage. The next set for the
same node is then searched for. If there is none, or if the next
set is to remove drive, the increment is set to 0 (meaning that
the node will never change voltage or will not change until
drive is removed). Otherwise, the increment is set to an
approximation of a voltage that, if added to the node voltage
on each cycle, will cause the node voltage to match that next
set voltage when it becomes current.
Note that the next set replaces this approximation with an
exact voltage when it becomes active, so the system is self-
correcting. The only problem will become with VERY long times
between such sets.

**************************************************************}

procedure setnodes;

var sp1, sp2: setptr;
    np: nodptr; { pointer for nodes }

begin

   sp1 := curset; { index current set }
   while sp1 <> nil do begin { more sets to come }

      if sp1^.clk = clkcnt then begin { active entries }

         if curset^.drv then begin

            np := curset^.nod; { index the set node }
            np^.setv := true; { set drive active }
            np^.voln := curset^.vol; { set voltage }
            np^.inc := 0.0; { clear increment }
            sp2 := curset^.next; { index next entry }
            while sp2 <> nil do begin

               { search for next set on this node }
               if sp2^.nod = np then begin { found }

                  if sp2^.drv then { is driven }
                     { find increment required to step to next }
                     np^.inc := (sp2^.vol - np^.voln) /
                                (sp2^.clk - clkcnt);
                  sp2 := nil { flag end }

               end;
               if sp2 <> nil then sp2 := sp2^.next { next entry }

            end

         end else sp1^.nod^.setv := false; { remove drive }
         sp1 := sp1^.next; { next entry }
         curset := curset^.next

      end else sp1 := nil { flag end }

   end

end;

{**************************************************************

Run current cycle

Runs the current summing cycle, or device evaluation cycle.
For each of P or N channel devices and resistors, the current
flow and direction is found. That is then subtracted from the source
node and added to the destination node.

**************************************************************}

procedure findcur;

var dp: devptr; { pointer for devices }
    vds, vgs, vgsmvt: real; { equation terms }
    i: real;

begin

   dp := devtbl; { index device table }
   while dp <> nil do begin { traverse devices }

      case dp^.dtype of { device }

         dpmos: begin { P channel }

                   { find drain to source voltage }
                   vds := dp^.drain^.voll - dp^.source^.voll;
                   { find gate to source voltage }
                   vgs := dp^.gate^.voll - dp^.source^.voll;
                   vgsmvt := vgs - pthresh;
                   if (0.0 > vds) and (vds > vgsmvt) then begin

                      { linear }
                      i := dp^.gain*((vgsmvt*vds)-((vds*vds)/2))

                   end else if (0.0 > vgsmvt) and (vgsmvt > vds) then
                      begin

                      { saturation }
                      i := (dp^.gain/2)*(vgsmvt*vgsmvt)

                   end else
                      { cutoff }
                      i := 0;
                   { subtract from "source" }
                   dp^.source^.isum := dp^.source^.isum - i;
                   { add to "destination" }
                   dp^.drain^.isum := dp^.drain^.isum + i

                end;

         dnmos: begin { N channel }

                   { find drain to source voltage }
                   vds := dp^.drain^.voll - dp^.source^.voll;
                   { find gate to source voltage }
                   vgs := dp^.gate^.voll - dp^.source^.voll;
                   vgsmvt := vgs - nthresh;
                   if (0.0 < vds) and (vds < vgsmvt) then begin

                      { linear }
                      i := dp^.gain*((vgsmvt*vds)-((vds*vds)/2))

                   end else if (0.0 < vgsmvt) and (vgsmvt < vds) then
                      begin

                      { saturation }
                      i := (dp^.gain/2)*(vgsmvt*vgsmvt)

                   end else
                      { cutoff }
                      i := 0;
                   { subtract from "destination" }
                   dp^.drain^.isum := dp^.drain^.isum - i;
                   { add to "source" }
                   dp^.source^.isum := dp^.source^.isum + i

                end;

         dres:  begin

                   i := (dp^.source^.voll - dp^.drain^.voll)/
                        dp^.width; { i = e/r }
                   { subtract from "source" }
                   dp^.source^.isum := dp^.source^.isum - i;
                   { add to "destination" }
                   dp^.drain^.isum := dp^.drain^.isum + i

                end;

      end;
      dp := dp^.next { next entry }

   end

end;

{**************************************************************

Find voltages

Calculate the next node voltages, and output traces.
The next node voltage is calculated from the current on each node,
using the current sum from the previous step, and the span
and capacitience parameters. The result is then checked against
the last output trace voltage, and if that has changed by the
amount specified in the trace limit, a trace is output.

***************************************************************}

procedure findvol;

var np: nodptr; { pointer for nodes }
    time: real;

begin

   np := nodtbl; { index table }
   while np <> nil do begin { traverse }

      if not np^.setv then { is not driven }
         np^.voln := np^.voll + ((span*np^.isum)/np^.cap);
      if abs(np^.voln - np^.ltrc) >= limit then begin

         { output trace }
         write(trcfil, $20); { output indicator }
         write32(trcfil, np^.num); { output node number }
         time := clkcnt * span; { find actual time }
         writesreal(trcfil, time); { output }
         writesreal(trcfil, np^.voln); { output voltage }
         np^.ltrc := np^.voln { set new last trace }

      end;
      np := np^.next { next entry }

   end

end;

{**************************************************************

Main program

Initalizes global variables, processes the options, loads
the circuit file and runs the simulation.

**************************************************************}

begin

   writeln('CMOS analog circuit simulator 0.1 Copyright (C) 1989 S. A. Moore');

   { initalize tables }

   nodtbl := nil;
   devtbl := nil;
   settbl := nil;
   curset := nil;
   clkcnt := 0; { set clock time 0 }
   stpcnt := 0; { set no step }
   span := 0.0; { clear parameters }
   limit := 0.0;
   pthresh := 0.0;
   nthresh := 0.0;
   pconst := 0.0;
   nconst := 0.0;
   fverb := false; { set no verbose }
   simopn := false; { set files closed }
   setopn := false;
   trcopn := false;

   { process options and open output file }

   prcopt(command); { process options }
   setnam := simnam; { copy names }
   trcnam := simnam;
   addext(simnam, '.sim                '); { place extentions }
   addext(setnam, '.set                ');
   addext(trcnam, '.trc                ');
   { check circuit files exist }
   if not exists(simnam) then error(ecfnf);
   if not exists(setnam) then error(estfnf);
   assign(simfil, simnam); { open net file }
   reset(simfil);
   simopn := true; { set sim file open }
   assign(setfil, setnam); { open set file }
   reset(setfil);
   setopn := true; { set set file open }
   assign(trcfil, trcnam); { open trace file }
   rewrite(trcfil);
   trcopn := true; { set trace file open }

   { load files }

   loadckt(simfil);
   loadckt(setfil);
   curset := settbl; { index top set }
   findgain; { calculate gain for devices }

   { run simulation }

   if fverb then writeln('Executing simulation');
   while clkcnt < stpcnt do begin { run sim }

      save;     { run save cycle }
      setnodes; { run set cycle }
      findcur;  { run current cycle }
      findvol;  { run voltage cycle }
      clkcnt := clkcnt + 1 { advance clock }

   end;
   write(trcfil, $00); { terminate trace file }

   99: { abort program }

   if fverb then writeln('Function complete');
   if simopn then close(simfil); { close files }
   if setopn then close(setfil);
   if trcopn then close(trcfil)

end.

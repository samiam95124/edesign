{**************************************************************
*                                                             *
*             SIMULATOR PATTERN GENERATOR                     *
*                                                             *
*                 8/88 S. A. Moore                            *
*                                                             *
* Generates a pattern set file. This file controls most of    *
* general activity of the simulator. Relivant files:          *
*                                                             *
*     file.dic - The dictionary for the circuit to set.       *
*     file.set - The output set generator file.               *
*                                                             *
* The allowed statements are:                                 *
*                                                             *
*     set <node> [<time>[:<period>]]...                       *
*     output <node> [<node>]...                               *
*     trace <start time>[:<period>] [<end time>               *
*           [<start time>[:<period>] [<end time>]]...         *
*                                                             *
* The set statement generates a node set at the given time,   *
* or 0 if not specified. The optional period specifies the    *
* reset time of the set.                                      *
* The output statement sets a node or nodes to be output      *
* into the trace file. Note that normally ALL nodes are       *
* traced. The appearance of a single output statement         *
* immediately turns all traces off, so that only the          *
* specified node(s) are output. Note also that this really    *
* isn't designed to select an output format, but simply to    *
* limit the amount of expensive trace I/O during simulation.  *
* The trace statement specifies when trace lines are to be    *
* output. This allows the tracing to be started, stopped,     *
* and the period to be specified. Again, this is used to      *
* limit trace I/O.                                            *
*                                                             *
**************************************************************}

program cktpat(command, output);

uses stddef,
     strlib;

label 99; { abort program }

const linmax = 80; { maximum command line }
      labmax = 40; { maximum characters per label }

type
     nodadr  = 0..maxint; { node address. Maximum unsigned
                            value in 32 bit signed word }
     bytfil  = file of byte; { file of byte }
     labinx  = 1..labmax; { index for label }
     { note that there are 16 states of a node, the
       perfect number for table lookups. They are
       also broken evenly into indeterminate and
       determinate states. }
     nodest  = (         { node states }
     { indeterminate }
                undef,   { unspecified }
                indet,   { stored indeterminate }
                indrh,   { indeterminate driven by high }
                indrl,   { indeterminate driven by low }
                widh,    { weak indeterminate driven by high }
                widl,    { weak indeterminate driven by low }
                cont,    { conflicting drives }
                wcont,   { conflicting weak drives }
     { determinate }
                high,    { driven high }
                low,     { driven low }
                strh,    { stored high }
                strl,    { stored low }
                whigh,   { weak driven high }
                wlow,    { weak driven low }
                vcc,     { high supply rail }
                vss      { low supply rail }
                );
     nodlab  = packed array [labinx] of char; { label for node }
     nodptr  = ^node;   { node pointer }
     node    = record   { node }

                  lab:    nodlab; { name of the node }
                  next:   nodptr  { next list node }

               end;
     cixptr  = ^celinx;   { cell index pointer }
     celptr  = ^cell;     { cell pointer }
     cell    = record     { cell }

                  lab:    nodlab;  { name of cell }
                  nod:    nodptr;  { node list }
                  cell:   cixptr;  { cell reference list }
                  cnt:    integer; { number of nodes contained }
                  next:   celptr   { next cell }

               end;
     celinx  = record     { cell index }

                  cell:   celptr; { index to cell }
                  next:   cixptr  { next }

               end;
     lininx  = 1..linmax; { command line index }
     errcod  = (ecpar,    { command/parameter not found }
                ecnf,     { command not found }
                eilovf,   { input line overflow }
                elabtl,   { label too long }
                ecfns,    { circuit file not specified }
                eivopt,   { invalid option }
                ecfnf,    { circuit file not found }
                enumovf,  { integer overflow }
                enumnf,   { number not found }
                einvcmd,  { invalid command }
                enodnf,   { node not found }
                einvnod,  { invalid node specification }
                einvdff,  { invalid dictionary file format }
                etmon,    { too many output nodes }
                einvstp,  { invalid step count }
                estpns,   { step count not set }
                einvnf,   { invalid numeric format }
                esys);    { system error }
     equsta   = packed array [nodest] of char; { state equate table }
     line     = packed array [lininx] of char; { input line buffer }
     setype   = (stat, ana); { type of set entry }
     setptr   = ^nodset; { node set entry pointer }
     nodset   = record   { node set entry }

                   typ:   setype;  { type of set }
                   clk:   integer; { clock to trigger on }
                   nod:   integer; { node to set }
                   state: nodest;  { state to set to (state) }
                   vol:   real;    { voltage to set to (analog) }
                   drv:   boolean; { drive status }
                   next:  setptr   { next entry }

                end;
     linptr   = ^linbuf; { pointer to line buffer }
     linbuf   = record

                   lin: line; { line buffer }
                   next: linptr { next entry }

                end;

var srclin:   boolean; { reading source lines }
    celtbl:   celptr;  { cell list }
    settbl:   setptr;  { node set list }
    equtbl:   equsta;  { node state memnonics }
    cmdlin:   line;    { input command buffer }
    cmdptr:   lininx;  { current command line position }
    setnam:   nodlab;  { output file name }
    setfil:   bytfil;  { output file }
    setopn:   boolean; { set file open }
    dicnam:   nodlab;  { dictionary file name }
    dicfil:   bytfil;  { dictionary file }
    dicopn:   boolean; { dictionary file open }
    cktnam:   nodlab;  { circuit file name }
    cktfil:   text;    { circuit file }
    cktopn:   boolean; { circuit file open }
    fverb:    boolean; { verbose flag }
    lincnt:   integer; { source line count }
    stpcnt:   nodadr;  { step count }
    realconv: ^real;   { real to bytes convertion buffer }
    nodeconv: ^nodadr; { node to bytes convertion buffer }

{**************************************************************

Process error

Prints an error message by the given error code and aborts.
The procedure does not return.

**************************************************************}

procedure error(e: errcod);

var i, y: lininx; { index for line }
    x: labinx;

begin

   if srclin then begin

      y := linmax; { find last non-space }
      while (y > 1) and (cmdlin[y] = ' ') do y := y - 1;
      for i := 1 to y do write(cmdlin[i]); { output line }
      if cmdptr > (y + 1) then cmdptr := y + 1; { back up to last }
      writeln;
      if cmdptr <= y then writeln('^':cmdptr) { output index }
      else writeln('^':y);
      write('*** '); { output header }
      for x := 1 to labmax do if cktnam[x] <> ' ' then
         write(cktnam[x]); { output filename }
      write(':', lincnt:1, ' ') { output line count }

   end else write('*** '); { output header }
   case e of { error }

      ecpar:   writeln('Command/parameter expected');
      ecnf:    writeln('Command not found');
      eilovf:  writeln('Input line overflow');
      elabtl:  writeln('Label too long');
      ecfns:   writeln('Circuit file not specified');
      eivopt:  writeln('Invalid option');
      ecfnf:   writeln('Circuit file not found');
      enumovf: writeln('Input numeric overflow');
      enumnf:  writeln('Numeric not found');
      einvcmd: writeln('Invalid command');
      enodnf:  writeln('Node not found');
      einvnod: writeln('Invalid node specification');
      einvdff: writeln('Invalid dictionary file format');
      etmon:   writeln('Too many output nodes');
      einvstp: writeln('Invalid step count');
      estpns:  writeln('Step count not set');
      einvnf:  writeln('Invalid numeric format');
      esys:    writeln('System error: contact Moore/CAD');

   end;
   goto 99

end;

{**************************************************************

Read word

Reads a word from a byte file, in high-low order.

**************************************************************}

procedure readword(var f: bytfil; var w: nodadr);

var h, l: byte;

begin

   read(f, h); { get high }
   read(f, l); { get low }
   w := h*256+l { convert }

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

Determine label length

Determines the number of non-space characters in the label.

**************************************************************}

function len(var n: nodlab): labinx;

var i: labinx; { index for label }
    l: 0..labmax; { count }

begin

   l := 0; { initalize count }
   for i := 1 to labmax do if n[i] <> ' ' then
      l := l + 1; { count non-space character }
   len := l { return result }

end;

{**************************************************************

Check label equality

Checks if the labels are equal, without case.

**************************************************************}

function equ(var a, b: nodlab): boolean;

var i : labinx; { index for labels }
    m : boolean; { match flag }

begin

   m := true; { set match }
   for i := 1 to labmax do { check matches }
      if lcase(a[i]) <> lcase(b[i]) then m := false;
   equ := m { return result }

end;

{**************************************************************

Add index specification to label

Adds an index specification of the form:

     [num]

to the end of the given label.

***************************************************************}

procedure addinx(var n: nodlab; i: byte);

var x: labinx;
    f: boolean;

begin

   x := 1; { find end of label }
   while (x < labmax) and (n[x] in ['A'..'Z', 'a'..'z', '_', '0'..'9']) do
      x := x + 1; { skip forward }
   if n[x] in ['A'..'Z', 'a'..'z', '_', '0'..'9'] then error(elabtl);
   n[x] := '['; { place left }
   x := x + 1; { next }
   f := false; { set no leading digit }
   if (i div 100) <> 0 then begin { place hundreds digit }

      if x > labmax then error(elabtl); { overflow }
      n[x] := chr((i div 100) + ord('0')); { place digit }
      i := i - ((i div 100) * 100); { subtract that }
      x := x + 1; { next }
      f := true { set leading placed }

   end;
   if ((i div 10) <> 0) or f then begin { place tens digit }

      if x > labmax then error(elabtl); { overflow }
      n[x] := chr((i div 10) + ord('0')); { place digit }
      i := i - ((i div 10) * 10); { subtract that }
      x := x + 1 { next }

   end;
   { place ones digit }
   if x > labmax then error(elabtl); { overflow }
   n[x] := chr(i + ord('0')); { place digit }
   x := x + 1; { next }
   if x > labmax then error(elabtl); { overflow }
   n[x] := ']'; { place right }
   x := x + 1; { next }
   { blank out the rest }
   while x <= labmax do begin n[x] := ' '; x := x + 1 end;

end;

{**************************************************************

Strip primary

Strips the first primary name off. This may be of the form:

   name

or

   name[n]

**************************************************************}

procedure strip(var n, w: nodlab; var c: nodadr);

var i : labinx; { index for label }

procedure getchr; { dispose of first character }

var i: labinx;

begin

   for i := 1 to labmax - 1 do { move characters left }
      n[i] := n[i + 1]

end;

begin

   c := maxint; { flag no index parsed }
   i := 1; { set first }
   w := '                                        '; { clear result }
   { get primary }
   { validate first character }
   if not(n[1] in ['A'..'Z', 'a'..'z', '_']) then error(einvnod);
   while n[1] in ['A'..'Z', 'a'..'z', '_', '0'..'9'] do begin

      w[i] := n[1]; { place character }
      i := i + 1; { next }
      getchr { skip }

   end;
   if n[1] = '[' then begin { index number }

      getchr; { skip '[' }
      c := 0; { clear count }
      { check valid digit }
      if not (n[1] in ['0'..'9']) then error(einvnod);
      while n[1] in ['0'..'9'] do begin { read number }

         c := c*10 + (ord(n[1])-ord('0')); { convert }
         getchr { skip }

      end;
      if not (n[1] = ']') then error(einvnod); { error }
      getchr; { skip ']' }
      if c = 0 then error(einvnod) { invalid cell number }

   end;
   if n[1] = '.' then begin

      getchr; { skip '.' }
      if len(n) = 0 then error(einvnod) { error }

   end

end;

{*******************************************************************************

Find node entry

Returns the node number for a given node name. Nodes have the following format:

spec     ::= <name> | <path> '.' <name>
name     ::= <label> | <label> '[' <number> [':' <number> ']'
path     ::= <instance> ['.' <instance>]...
instance ::= <label> | <label> '#' <number>
digit    ::= '0'..'9'
number   ::= <digit> [<digit>]...
letter   ::= 'a'..'z', 'A'..'Z', '_'
label    ::= <letter> | [<letter>]...

A typical node specification is:

mycell.this#1.that2.sig[5]

The search for a node starts with the top cell, which was the last cell in the
dictionary. This cell logically contains all other cells. We match the path to
the node by matching cell names:

cell.cell.cell ...

The top cell name may or not be present. If not present, we simply start the
search at the top cell. Note that even though other cells are "visible" at this
point, we cannot reach them, because their nodes have no meaning without
nesting information.
Searching each name on the path either gives a subcell or a node (a terminal).
If a subcell is involved, it may be an instance:

name#n

Instance numbers cause the subcell to be rejected unless it matches the
instance number. Cell names can have no instance number, but in this case,
there must be only one instance of the cell or it is an error.
The search ends when we find a node (a terminal). Then, no further path 
information can be present. Cell names and node names are unique.
A node name can have a index specification:

name[n]

That is cleaned up, but otherwise searched for as a string, since '[' and ']'
are allowed as characters in a node label. The range specification is taken
care of by the caller of this routine, who must expand these ranges out.


*******************************************************************************}

procedure fndnode(view n: string;  { label for node }
                  var c: nodadr); { returns number of node }

var m:  boolean; { match flag }
    cp: celptr; { cell index }
    li: integer; { label index }
    cn, cc: nodadr;
    np: nodptr;
    ip: cixptr;
    w: nodlab;
    b: byte;
    i: labinx;

{ get next character from node specification }

function nxtchr: char;

begin

   if li > max(nodlab) then c := ' ' { off end }
   else c := nodlab[li]

end;

{ get label from node specification }

procedure getlab(var n: string);

var i: integer; { output index }

begin

   clears(n); { clear result }
   i := 1; { set 1st character }
   while nxtchr in ['a'..'z', 'A'..'Z', '_'] do begin

      n[i] := nxtchr; { get character }
      i := i+1; { next character }
      li := li+1

   end

end;

{ get index specification, add to label end }

procedure prcinx(var n: string; var inx: boolean);

var id: integer; { index number }
    w:  nodlab;  { temp label }

begin

   inx := false; { set no index }
   if nxtchr = '[' then begin { there is an index }

      li := li+1;
      if not (nxtchr in ['0'..'9']) then error(einvnod); { missing number }
      id := 0; { clear index }
      while nxtchr in ['0'..'9'] do begin { convert number }

         id := id*10+ord(nxtchr)-ord('0'); { convert }
         li := li+1 { next }

      end;
      if nxtchr <> ']' then error(einvnod); { missing ']' }
      { reconstruct index }
      catp(n, '[');
      intsp(w, id);
      catp(n, w);
      catp(n, ']');
      inx := true { set index found }

   end

end;

{ find cell or node in current level }

procedure schlvl(cp: cellptr);

var np, fnp: nodptr; { pointers to nodes }
    n:       nodlab; { labels for node }
    inx:     boolean; { index exists }

begin

   getlab(n); { strip label }
   if n[1] = ' ' then error(einvnod); { label is missing }
   prcinx(n, inx); { get any index }
   { search nodes }
   np := cp^.nod; { index top of node list }
   fnp := nil; { set no node found }
   while np <> nil do begin

      if compp(n, np^.lab) then begin { found }

         fnp := np; { set found node }
         np := nil { stop search }

      end else np := np^.next

   end;
   { if an index was specified, it must be a node, and so that must be found }
   if (fnp = nil) and inx then error(enodnf);
   if fnp = nil then begin { node not found, search subcells

end;

procedure search;

begin

   strip(n, w, cn); { strip primary name }
   b := cn;
   { if there is an index, add that }
   if cn <> maxint then addinx(w, b);
   m := false; { clear match flag }
   np := cp^.nod; { index node list start }
   while (np <> nil) and not m do begin

      if equ(np^.lab, w) then m := true { found }
      else begin np := np^.next; c := c + 1 end

   end;
   i := 1; { clear out any index }
   while (i < labmax) and (w[i] <> '[') do i := i + 1; { skip to '[' }
   if w[i] = '[' then { clear it out }
      while i <= labmax do begin w[i] := ' '; i := i + 1 end;
   if cn = maxint then cn := 1; { default to cell instance one }
   if not m then begin { search cell list }

      ip := cp^.cell; { index index list start }
      cc := 1; { clear cell count }
      while (ip <> nil) and not m do begin

         if equ(ip^.cell^.lab, w) then begin

            if cc = cn then m := true { found }
            else cc := cc + 1 { next cell }

         end;
         if not m then { skip to next }
            begin ip := ip^.next; c := c + ip^.cell^.cnt end

      end;
      if not m then error(enodnf); { error }
      cp := ip^.cell; { break open that cell }
      search { and search that }

   end

end;

begin

   { find top cell for implied first level }
   cp := celtbl; { index cell table root }
   if cp = nil then error(enodnf); { no list }
   li := 1; { set 1st label character }
   { find last (top) entry) }
   while cp^.next <> nil do cp := cp^.next;
   c := 0; { clear node count }
   search; { search list }
   if len(n) <> 0 then error(einvnod) { error }

end;

{**************************************************************

Create set entry

Creates a set entry, with the given clock trigger, node to
set, and the state to set the node to.

**************************************************************}

procedure newset(var n: nodlab; { node to set to }
                 c:     nodadr; { clock to set on }
                 s:     nodest; { state to set }
                 pr:    nodadr; { trigger period }
                 styp:  setype; 
                 svol:  real;
                 sdrv:  boolean);

var w: nodadr;   { node pointer }
    st, sp, ls: setptr; { set pointers }
    d: boolean; { done flag }

begin

   if (pr <> 0) and (stpcnt = 0) then error(estpns); { error }
   repeat { generate sets }

      new(st); { create a set entry }
      fndnode(n, w); { create a node }
      st^.typ   := styp; { place type }
      st^.clk   := c;    { place clock }
      st^.nod   := w;    { place node pointer }
      st^.state := s;    { place state }
      st^.vol   := svol; { place voltage }
      st^.drv   := sdrv; { place drive state }
      sp := settbl; { index top of set list }
      ls := nil; { set no last }
      d := false; { set not done }
      repeat { search list }

         if sp = nil then begin { insert end }

            if ls = nil then settbl := st { link to root }
            else ls^.next := st; { link to last }
            st^.next := sp; { link to next }
            d := true { flag done }

         end else if sp^.clk > c then begin { insert }

            if ls = nil then settbl := st { link to root }
            else ls^.next := st; { link to last }
            st^.next := sp; { link to next }
            d := true { flag done }

         end else begin ls := sp; sp := sp^.next end { next entry }

      until d; { end }
      c := c + pr; { find next clock time }
      if c > stpcnt then pr := 0 { flag end }

   until pr = 0 { end }

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
   cmdptr := 1; { set 1st character position }
   lincnt := lincnt + 1 { count lines }

end;

{**************************************************************

Read input line

Reads the caller command line.

**************************************************************}

procedure readcomm; { input file }

var ovf: boolean; { overflow flag }

begin

   readsp(command, cmdlin, ovf); { read command line }
   if ovf then error(eilovf); { process error }
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

   n := '                                        ';
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
   if n = '                                        ' then
      error(ecpar) { no word found }

end;

{**************************************************************

Get number

Reads and converts the decimal numeric at the command line
position. Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getnum(var n: nodadr);

begin

   n := 0; { initalize number }
   skpspc; { skip spaces }
   { check any digits }
   if not (chkchr in ['0'..'9']) then error(enumnf);
   while chkchr in ['0'..'9'] do begin

      if n > 65535/10 then error(enumovf); { overflow }
      n := n * 10; { scale }
      n := n + ord(chkchr) - ord('0'); { add new digit }
      getchr { next }

   end

end;

{**************************************************************

Get real

Reads and converts the decimal numeric at the command line
position. Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getrnm(var n: real);

var dp: boolean; { decimal point flag }
    p: real; { scaling factor }
    s: real; { sign }

begin

   n := 0.0; { initalize number }
   p := 1.0;   { set scaling factor }
   s := 1.0; { set sign }
   dp := false; { set decimal point not scanned }
   skpspc; { skip spaces }
   if chkchr = '-' then begin s := -s; getchr end
   else if chkchr = '+' then begin getchr end;
   skpspc; { skip spaces }
   { check any digits }
   if not (chkchr in ['0'..'9', '.']) then error(enumnf);
   while chkchr in ['0'..'9', '.'] do begin

      if chkchr = '.' then begin { decimal point }

         if dp then error(einvnf); { error }
         getchr; { skip '.' }
         dp := true { set decimal passed }

      end else begin { parse digit }

         if dp then begin { after decimal point }

            p := p / 10.0; { find next scale }
            n := n + (p * (ord(chkchr) - ord('0'))) { add new digit }

         end else begin { before decimal point }

            n := n * 10.0; { scale }
            n := n + ord(chkchr) - ord('0') { add new digit }

         end;
         getchr { next }

      end

   end;
   if lcase(chkchr) in ['f', 'p', 'n', 'u', 'm', 'k', 'g', 't'] then
   case lcase(chkchr) of

      'f': begin n := n * 10e-15; getchr end; { femto }
      'p': begin n := n * 10e-12; getchr end; { pico }
      'n': begin n := n * 10e-9; getchr end;  { nano }
      'u': begin n := n * 10e-6; getchr end;  { micro }
      'm': begin

              getchr; { skip 'm' }
              if not (lcase(chkchr) in ['a'..'z']) then
                 n := n * 10e-3               { mili }
              else if lcase(chkchr) = 'e' then begin

                 getchr; { skip }
                 if lcase(chkchr) <> 'g' then error(einvnf); { error }
                 getchr; { skip }
                 n := n * 1e6                { mega }

              end else if lcase(chkchr) = 'i' then begin

                 getchr; { skip }
                 if lcase(chkchr) <> 'l' then error(einvnf); { error }
                 getchr; { skip }
                 n := n * 25.4e-6              { mil }

              end else error(einvnf) { error }

           end;

      'k': begin n := n * 1e3; getchr end;   { kilo }
      'g': begin n := n * 1e9; getchr end;   { giga }
      't': begin n := n * 1e12; getchr end   { tera }

   end;
   n := n*s { set sign of result }

end;

{**************************************************************

Get node state

Gets a single character state code from the command line.
This is converted to an encoded state.

**************************************************************}

procedure getst(var s: nodest); { state }

begin

   skpspc; { skip spaces }
   if not (lcase(chkchr) in ['u', 'i', 'a', 'b', 'd', 'e',
                             'c', 'f', '1', '0', 'h', 'l',
                             'j', 'k', 'p', 'g']) then
      error(ecpar); { error }
   case lcase(chkchr) of { state }

      'u': s := undef;
      'i': s := indet;
      'a': s := indrh;
      'b': s := indrl;
      'd': s := widh;
      'e': s := widl;
      'c': s := cont;
      'f': s := wcont;
      '1': s := high;
      '0': s := low;
      'h': s := strh;
      'l': s := strl;
      'j': s := whigh;
      'k': s := wlow;
      'p': s := vcc;
      'g': s := vss

   end;
   getchr { skip character }

end;

{**************************************************************

Write real

Writes the given real out to a byte file, high order to low
order.

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

Write 32 bit word

Outputs a word to the file, expanding that with 8 zero high
bits.
This should be replaced by signed magnitude.

**************************************************************}

procedure writenadr(var f: bytfil; n: nodadr);

var ic:  record case boolean of { integer convertion }

            false: (i: integer);
            true:  (b: packed array [1..4] of byte)

         end; 

begin

   ic.i := n; { place real in convertion area }
   write(f, ic.b[4]); { output }
   write(f, ic.b[3]);
   write(f, ic.b[2]);
   write(f, ic.b[1])

end;

{**************************************************************

Process single line

Executes the command in the command line buffer. Anyplace
'!' appears is a comment, as is a blank line.

***************************************************************}

procedure prclin;

var w, n: nodlab; { label holders }
    clk: nodadr; { clock holder }
    per: nodadr; { clock period }
    st: nodest; { state holder }
    nn: nodadr; { node number }
    pr: real; { parameter holder }
    styp: setype;
    svol: real;
    sdrv: boolean;

begin

   skpspc; { skip spaces }
   if (chkchr <> '!') and (cmdptr <= linmax) then
      begin { not comment }

      getword(w); { get command word }
      if (w = 'set                                     ') or
         (w = 'aset                                    ') then begin

         if w = 'aset                                    ' then
         styp := ana else styp := stat; { set mode }
         { node set command }
         getword(n); { get the node to set }
         repeat { get sets }

            clk := 0; { set default time }
            per := 0; { set default period }
            if styp = ana then begin { get analog state }

               skpspc; { skip spaces }
               if lcase(chkchr) = 'x' then
                  begin sdrv := false; getchr end
               else
                  begin getrnm(svol); sdrv := true end

            end else getst(st); { get state to set }
            skpspc; { skip spaces }
            if chkchr in ['0'..'9'] then begin

               getnum(clk); { get clock }
               if chkchr = ':' then begin { period spec }

                  getchr; { skip that }
                  getnum(per) { get the period }

               end;
               skpspc { skip spaces }

            end;
            { create a clock entry }
            newset(n, clk, st, per, styp, svol, sdrv)

         until (chkchr = ' ') or (chkchr = '!')

      end else if w = 'step                                    ' then begin

         getnum(stpcnt); { get the clock count }
         if stpcnt = 0 then error(einvstp); { error }
         write(setfil, $40); { output step code }
         writenadr(setfil, stpcnt) { output step count }

      end else if w = 'trace                                   ' then begin

         repeat

            getword(n); { get node to output }
            fndnode(n, nn); { find that }
            write(setfil, $30); { output trace command }
            writenadr(setfil, nn); { output node }
            skpspc { skip spaces }

         until (chkchr = ' ') or (chkchr = '!'); { end of line }

      end else if w = 'ascale                                  ' then begin

         getrnm(pr); { get analog step scale }
         write(setfil, $a0); { output span command }
         writesreal(setfil, pr) { output scale }

      end else if w = 'tracelimit                              ' then begin

         getrnm(pr); { get analog trace limit }
         write(setfil, $b0); { output trace limit command }
         writesreal(setfil, pr) { output trace limit }

      end else if w = 'setparams                               ' then begin

         write(setfil, $c0); { output parameter set command }
         getrnm(pr); { get P channel threshold }
         writesreal(setfil, pr); { output }
         getrnm(pr); { get N channel threshold }
         writesreal(setfil, pr); { output }
         getrnm(pr); { get P channel process constant }
         writesreal(setfil, pr); { output }
         getrnm(pr); { get N channel process constant }
         writesreal(setfil, pr) { output }

      end else error(einvcmd) { no command }

   end

end;

{**************************************************************

Process set file

Loads each line of the given file in turn, and executes
the commands contained there.

***************************************************************}

procedure prcset(var f: text);

begin

   while not eof(f) do begin { read lines }

      readline(f); { read next line }
      prclin { execute line }

   end

end;

{**************************************************************

Process caller line

Read a line from the given file, and processes the circuit
file there and any command line options.

**************************************************************}

procedure prcopt;

begin

   readcomm; { load command line }
   skpspc; { skip spaces }
   if cmdptr > linmax then error(ecfns); { error }
   getword(cktnam); { get the circuit file name }
   skpspc; { skip spaces }
   while cmdptr <= linmax do begin { process options }

      if chkchr <> '#' then error(eivopt); { error }
      getchr;
      if not (lcase(chkchr) in ['v']) then
         error(eivopt); { error }
      case lcase(chkchr) of { option }

         'v': begin { set verbose mode }

                 getchr; { skip option }
                 fverb := true { set }

              end;

      end;
      skpspc { skip spaces }

   end

end;

{**************************************************************

Load node dictionary

Loads the node name dictionary.

***************************************************************}

procedure loaddic;

var cp, lc, cp2: celptr; { pointer for cell list }
    np, ln: nodptr; { pointer for node list }
    ci, li: cixptr; { pointers for indexes }
    cc, cn, nc: nodadr;
    pc: byte;
    b: byte;

procedure readlab(var n: nodlab);

var i, l: labinx;
    b: byte;

begin

   read(dicfil, b); { get string length }
   l := b;
   if l > labmax then error(elabtl); { overflow }
   n := '                                        '; { clear }
   i := 1; { set 1st character }
   while l <> 0 do begin { read characters }

      read(dicfil, b); { get character }
      n[i] := chr(b); { place }
      l := l - 1; { count }
      i := i + 1

   end

end;

begin

   lc := nil; { set no last cell }
   cp := nil; { clear cell pointer }
   repeat { cells }

      read(dicfil, b); { get the code }
      if b <> 0 then begin { not end }

         if b <> 1 then error(einvdff); { flag error }
         if cp <> nil then begin { dispose of cell last parameters }

            while pc <> 0 do begin

               if cp^.nod = nil then error(esys); { error }
               cp^.nod := cp^.nod^.next; { gap list }
               pc := pc - 1 { count }

            end

         end;
         new(cp); { get new cell entry }
         cp^.next := nil; { clear next }
         if lc <> nil then lc^.next := cp { add top end }
         else celtbl := cp; { insert as first }
         lc := cp; { set last }
         readlab(cp^.lab);  { read cell label }
         read(dicfil, pc); { read parameter count }
         ln := nil; { clear last node }
         li := nil; { clear last index }
         nc := 0; { clear node count }
         repeat { nodes }

            read(dicfil, b); { get the next code }
            if b = 3 then begin { node }

               new(np); { get a new node entry }
               np^.next := nil; { clear next }
               if ln <> nil then ln^.next := np { add top end }
               else cp^.nod := np; { insert as first }
               ln := np; { set last }
               nc := nc + 1; { count node }
               readlab(np^.lab) { get label }

            end else if b = 4 then begin { subcell reference }

               readword(dicfil, cn); { get the cell number }
               cp2 := celtbl; { index cell table start }
               cc := 1; { clear cell count }
               while (cp2 <> nil) and (cc <> cn) do begin

                  cp2 := cp2^.next; { link next }
                  cc := cc + 1 { count }

               end;
               if cp2 = nil then error(einvdff); { error }
               new(ci); { get a new index }
               ci^.next := nil; { clear next }
               if li <> nil then li^.next := ci { add top end }
               else cp^.cell := ci; { insert as first }
               li := ci; { set last }
               ci^.cell := cp2; { index that cell }
               nc := nc + cp2^.cnt { find number of nodes }

            end else if b <> 2 then error(einvdff) { invalid code }

         until b = 2; { end of cell }
         { find number of nodes, which is nodes minus parameters }
         cp^.cnt := nc - pc

      end

   until b = 0 { end of file }

end;

{**************************************************************

Output set list

Outputs the set list to the file.

***************************************************************}

procedure outset;

var p: setptr; { pointer for set }

begin

   p := settbl; { index set list root }
   while p <> nil do begin { output entries }

      if p^.typ = stat then begin { output state format }

         write(setfil, $50+ord(p^.state)); { output set entry code }
         writenadr(setfil, p^.clk); { output clock time }
         writenadr(setfil, p^.nod)  { output node number }

      end else begin { output analog format }

         write(setfil, $90+(ord(p^.drv)*2)); { output set entry code }
         writenadr(setfil, p^.clk); { output clock time }
         writenadr(setfil, p^.nod); { output node number }
         if p^.drv then writesreal(setfil, p^.vol) { output voltage }

      end;
      p := p^.next { next entry }

   end

end;

{**************************************************************

Main program

Initalizes global variables, processes the options, loads
the circuit file and runs the simulation.

**************************************************************}

begin

   writeln('Circuit pattern generator 0.1 Copyright (C) 1988 S. A. Moore');

   { set up type convertion buffers }
 
   new(realconv);
   new(nodeconv);

   { initalize node memnonic table }

   equtbl[undef] := 'U'; { undefined }
   equtbl[indet] := 'I'; { indeterminate }
   equtbl[indrh] := 'A'; { indeterminate driven high }
   equtbl[indrl] := 'B'; { indeterminate driven low }
   equtbl[widh]  := 'D'; { indeterminate driven weakly high }
   equtbl[widl]  := 'E'; { indeterminate driven weakly low }
   equtbl[cont]  := 'C'; { contention }
   equtbl[wcont] := 'F'; { weak contention }
   equtbl[high]  := '1'; { high driven }
   equtbl[low]   := '0'; { low driven }
   equtbl[strh]  := 'H'; { stored high }
   equtbl[strl]  := 'L'; { stored low }
   equtbl[whigh] := 'J'; { high driven weakly }
   equtbl[wlow]  := 'K'; { low driven weakly }
   equtbl[vcc]   := 'P'; { power }
   equtbl[vss]   := 'G'; { ground }

   { initalize tables }

   celtbl := nil;
   settbl := nil;
   fverb := false; { set verbose off }
   lincnt := 0; { clear line counter }
   stpcnt := 0; { clear step count }
   cktopn := false; { set files not open }
   setopn := false;
   dicopn := false;

   { process options and open output file }

   srclin := false; { set not reading source }
   prcopt; { process options }
   setnam := cktnam; { copy circuit name to output }
   dicnam := cktnam; { and to dictionary }
   { place extentions }
   addext(cktnam, '.ctl                                    ');
   addext(setnam, '.set                                    ');
   addext(dicnam, '.dic                                    ');
   { check circuit file exists }
   if not exists(cktnam) then error(ecfnf);
   assign(cktfil, cktnam); { open circuit file }
   reset(cktfil);
   cktopn := true;
   assign(setfil, setnam); { open set file }
   rewrite(setfil);
   setopn := true;
   assign(dicfil, dicnam); { open dictionary file }
   reset(dicfil);
   dicopn := true;

   { process set file }

   srclin := true; { set reading source }
   lincnt := 0; { clear line counter }
   loaddic; { load the dictionary file }
   prcset(cktfil); { process set file }
   outset; { output the set file }
   write(setfil, 0); { terminate file }
   if stpcnt = 0 then error(estpns); { error }

   99: { abort program }

   if cktopn then close(cktfil); { close all files }
   if setopn then close(setfil);
   if dicopn then close(dicfil)

end.

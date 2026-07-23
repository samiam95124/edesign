{**************************************************************
*                                                             *
*                 CMOS CIRCUIT ASSEMBLER                      *
*                                                             *
*                 5/89 S. A. Moore                            *
*                                                             *
* Assembles a circuit net file based on an ascii format net   *
* specification. Relivant files:                              *
*                                                             *
*      file.ckt - The input net ascii source file.            *
*      file.net - The net specification file.                 *
*      file.dic - The ascii node equivalence file.            *
*                                                             *
* Using a one pass algorithim, the input file is converted to *
* the equivalent net. The input format basically consists of  *
* a sequence of entries:                                      *
*                                                             *
*      <device> <param 1> [<param n>] ! <comment>             *
*                                                             *
* The following devices are currently implemented:            *
*                                                             *
* n <source> <gate> <drain> - Creates an N channel            *
*                             transistor, with the indicated  *
*                             node labels.                    *
* p <source> <gate> <drain> - Creates a P channel             *
*                             transistor, with the indicated  *
*                             node labels.                    *
* wn <source> <gate> <drain> - Creates a weak N channel       *
*                             transistor, with the indicated  *
*                             node labels.                    *
* wp <source> <gate> <drain> - Creates a weak P channel       *
*                             transistor, with the indicated  *
*                             node labels.                    *
*                                                             *
**************************************************************}

program cktass(command, output);

uses strings;

label 99; { abort program }

const linmax = 80; { maximum command line }
      labmax = 20; { maximum characters per label }

type bytfil  = file of byte; { byte file }
     nodadr  = 0..maxint; { node address }
     labinx  = 1..labmax; { index for label }
     nodlab  = packed array [labinx] of char; { label for node }
     nodptr  = ^node;   { node pointer }
     node    = record   { node }

                  lab:    nodlab;  { name of the node }
                  ref:    boolean; { has been referenced }
                  drv:    boolean; { is driven }
                  next:   nodptr   { next list node }

               end;
     { device file codes }
     devtyp  = (dpmos,   { p-channel }
                dnmos,   { n-channel }
                dwpmos,  { weak p-channel }
                dwnmos,  { weak n-channel }
                dres,    { resistor }
                dcap);   { capacitor }
    lininx   = 1..linmax; { command line index }
    errcod   = (ecpar,    { command/parameter not found }
                ecnf,     { command not found }
                eilovf,   { input line overflow }
                elabtl,   { label too long }
                ecfns,    { circuit file not specified }
                eivopt,   { invalid option }
                ecfnf,    { circuit file not found }
                einvcmd,  { invalid command }
                eduppar,  { duplicate cell parameter }
                ecelexp,  { 'cell' expected }
                edupcel,  { duplicate cell name }
                escnexp,  { ';' expected }
                eclnexp,  { ':' expected }
                ecmaexp,  { ',' expected }
                eedcexp,  { 'endcell' expected }
                enumnf,   { number expected }
                ebgcexp,  { 'begincell' expected }
                enumovf,  { input numeric overflow }
                einvrpp,  { invalid vector specification }
                erbexp,   { ']' expected }
                evectl,   { vector too long }
                einvnf,   { invalid numeric format }
                esys);    { system error }
    line     = packed array [lininx] of char;   { input line buffer }
    celptr   = ^cell; { cell pointer }
    cell     = record { macro definition }

                  lab:  nodlab; { name of cell }
                  num:  nodadr; { number of cell }
                  par:  nodptr; { parameter table }
                  nodc: nodadr; { number of nodes in cell }
                  next: celptr  { next entry }

               end;
    cktptr   = ^cktent; { pointer for circuit file entry }
    cktent   = record { circuit file entry }

                  nam: nodlab; { name of file }
                  next: cktptr { next entry }

               end;

var nodtbl:   nodptr;  { node list }
    frenod:   nodptr;  { free node list }
    celtbl:   celptr;  { cell table }
    cmdlin:   line;    { input command buffer }
    cmdptr:   lininx;  { current command line position }
    cktnam:   cktptr;  { circuit file name stack }
    cktfil:   text;    { circuit file }
    netnam:   nodlab;  { net file name }
    netfil:   bytfil;  { net file }
    dicnam:   nodlab;  { dictionary file name }
    dicfil:   bytfil;  { dictionary file }
    nodnum:   nodadr;    { number of current node }
    devnum:   nodadr;    { number of devices }
    celnum:   nodadr;    { number of cells }
    fout:     boolean; { output file present }
    fverb:    boolean; { verbose flag }
    endf:     boolean; { end of source file flag }
    srclin:   boolean; { source line in buffer }
    lincnt:   integer;    { source line counter }
    listf:     text;    { output file }
    i:        labinx;
    l:        nodlab;
    fp:       cktptr; { pointer for circuit file entries }

{**************************************************************

Write file conditional

Performs a conditional write to a byte file. If an output
file is active, the write takes place.

**************************************************************}

procedure writec(var f: bytfil; b: byte);

begin

   if fout then write(f, b) { write if outputs open }

end;

{**************************************************************

Output label

Writes only non-space characters in a label.

**************************************************************}

procedure writelab(var f: text; var l: nodlab);

var i: labinx; { index for label }

begin

   for i := 1 to labmax do { output }
      if l[i] <> ' ' then write(f, l[i])

end;

{**************************************************************

Process error

Prints an error message by the given error code and aborts.
The procedure does not return.

**************************************************************}

procedure error(e: errcod);

var i, y: lininx; { index for line }

begin

   if srclin then begin

      y := linmax; { find last non-space }
      while (y > 1) and (cmdlin[y] = ' ') do y := y - 1;
      for i := 1 to y do write(listf, cmdlin[i]); { output line }
      writeln(listf);
      if cmdptr <= y then writeln(listf, '^':cmdptr) { output index }
      else writeln(listf, '^':y);
      write(listf, '*** '); { output header }
      writelab(listf, cktnam^.nam); { output filename }
      write(listf, ':', lincnt:1, ' ') { output line count }

   end else write(listf, '*** '); { output header }
   case e of { error }

      ecpar:   writeln(listf, 'Command/parameter expected');
      ecnf:    writeln(listf, 'Command not found');
      eilovf:  writeln(listf, 'Input line overflow');
      elabtl:  writeln(listf, 'Label too long');
      ecfns:   writeln(listf, 'Circuit file not specified');
      eivopt:  writeln(listf, 'Invalid option');
      ecfnf:   writeln(listf, 'Circuit file not found');
      einvcmd: writeln(listf, 'Invalid command');
      eduppar: writeln(listf, 'Duplicate cell parameter');
      ecelexp: writeln(listf, '''cell'' expected');
      edupcel: writeln(listf, 'Duplicate cell name');
      escnexp: writeln(listf, ''';'' expected');
      eclnexp: writeln(listf, ''':'' expected');
      ecmaexp: writeln(listf, ''','' expected');
      eedcexp: writeln(listf, '''end'' expected');
      enumnf:  writeln(listf, 'Number expected');
      ebgcexp: writeln(listf, '''begin'' expected');
      enumovf: writeln(listf, 'Input numeric overflow');
      einvrpp: writeln(listf, 'Invalid vector specification');
      erbexp:  writeln(listf, ''']'' expected');
      evectl:  writeln(listf, 'Vector too long for parameter list');
      einvnf:  writeln(listf, 'Invalid numeric format');
      esys:    writeln(listf, 'System error: notify Moore/CAD');

   end;
   goto 99

end;

{**************************************************************

Get node entry

Returns either a new node entry, or a recycled one.

**************************************************************}

procedure getnod(var n: nodptr);

begin

   if frenod = nil then new(n) { get a new entry }
   else begin { get old one }

      n := frenod; { unlink }
      frenod := n^.next

   end

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

function lenl(var n: nodlab): labinx;

var i: labinx;    { index for label }
    l: 0..labmax; { count }

begin

   l := 0; { initalize count }
   for i := 1 to labmax do if n[i] <> ' ' then
      l := l + 1; { count non-space character }
   lenl := l { return result }

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

Create new node entry

Creates a new node entry by the given name, and returns
a pointer to it.
If the name matches an entry already present, that is returned,
else a new entry is created.

**************************************************************}

procedure newnode(var n: nodlab;   { label for node }
                  var c: nodadr;     { number of node }
                  var np: nodptr); { entry }

var m: boolean; { match flag }
    l: nodptr; { node index }

begin

   { search for previously defined node }
   np := nodtbl; { index node table root }
   m := false; { clear match flag }
   c := 0; { clear node count }
   l := nil; { clear last }
   while (np <> nil) and not m do begin { search }

      if equ(np^.lab, n) then begin

         m := true; { set match status }
         np^.ref := true { set referenced }

      end else begin

         l := np; { set last }
         np := np^.next; { link next }
         c := c + 1 { count nodes }

      end

   end;
   if not m then begin { insert }

      nodnum := nodnum + 1; { count total nodes }
      getnod(np); { get new node entry }
      np^.lab := n; { place label }
      np^.ref := true; { set referenced }
      np^.drv := false; { set undriven }
      np^.next := nil; { clear next }
      if l <> nil then l^.next := np { link last to us }
      else nodtbl := np; { link root to us }

   end

end;

{**************************************************************

Create original node

Creates a new node. Indicates an error if the node has
already been declared.

**************************************************************}

procedure orgnode(var n: nodlab;   { label for node }
                  var c: nodadr;     { number of node }
                  var np: nodptr); { entry }
                 
var m: boolean; { match flag }
    l: nodptr; { node index }

begin

   { search for previously defined node }
   np := nodtbl; { index node table root }
   m := false; { clear match flag }
   c := 0; { clear node count }
   l := nil; { clear last }
   while (np <> nil) and not m do begin { search }

      c := c + 1; { count nodes }
      if equ(np^.lab, n) then error(eduppar) { error }
      else begin l := np; np := np^.next end { link next }

   end;
   if not m then begin { insert }

      nodnum := nodnum + 1; { set next node number }
      c := nodnum; { return that }
      getnod(np); { get new node entry }
      np^.lab := n; { place label }
      np^.ref := true; { set referenced }
      np^.drv := false; { set undriven }
      np^.next := nil; { clear next }
      if l <> nil then l^.next := np { link last to us }
      else nodtbl := np; { link root to us }

   end

end;

{**************************************************************

Output node dictionary

Outputs all the node names to the dictionary file.

**************************************************************}

procedure outdic;

var np: nodptr; { node index }
    i: labinx; { index for label }

begin

   if fout then begin

      np := nodtbl; { index node table root }
      while np <> nil do begin { output node names }

         write(dicfil, 3); { output node code }
         write(dicfil, lenl(np^.lab)); { output length }
         for i := 1 to lenl(np^.lab) do { output name }
            write(dicfil, ord(np^.lab[i]));
         np := np^.next { next entry }

      end

   end

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
   writec(f, fc.b[4]); { output }
   writec(f, fc.b[3]);
   writec(f, fc.b[2]);
   writec(f, fc.b[1])

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
   writec(f, ic.b[4]); { output }
   writec(f, ic.b[3]);
   writec(f, ic.b[2]);
   writec(f, ic.b[1])

end;

{**************************************************************

Output transistor

Outputs a transistor of the given type.
Accepts node labels for source, gate, drain, and substrate,
and connects the transistor to these.
Also accepts the width and length parameters.

**************************************************************}

procedure outtrans(dv: devtyp;           { type of device }
                   var s, g, d: nodlab;  { node labels }
                   ln, wd: real);        { length and width }
                  
var n: nodadr; { node number }
    p: nodptr;

begin

   devnum := devnum + 1; { count devices }
   case dv of { device }

      dpmos:  writec(netfil, $10);
      dwpmos: writec(netfil, $11);
      dnmos:  writec(netfil, $12);
      dwnmos: writec(netfil, $13)

   end;
   newnode(s, n, p);       { get a source node }
   writenadr(netfil, n); { output }
   p^.drv := true; { set is driven }
   newnode(g, n, p);       { get a gate node }
   writenadr(netfil, n); { output }
   newnode(d, n, p);       { get a drain node }
   writenadr(netfil, n); { output }
   p^.drv := true; { set is driven }
   writesreal(netfil, wd); { output width }
   writesreal(netfil, ln) { output length }

end;

{**************************************************************

Output capacitor

Outputs a capacitor, by the two terminals and the capacitience
in farads.

**************************************************************}

procedure outcap(var a: nodlab; { terminal }
                 var f: real); { farads }
                
var n: nodadr; { node number }
    p: nodptr;

begin

   devnum := devnum + 1; { count devices }
   writec(netfil, $80); { output command }
   newnode(a, n, p);   { get a terminal node }
   writenadr(netfil, n); { output }
   writesreal(netfil, f) { output farads }

end;

{**************************************************************

Output resistor

Outputs a resistor, by the two terminals and the resistance
in ohms.

**************************************************************}

procedure outres(var a, b: nodlab; { terminals }
                 var r: real); { ohms }

var n: nodadr; { node number }
    p: nodptr;

begin

   devnum := devnum + 1; { count devices }
   writec(netfil, $20); { output command }
   newnode(a, n, p);       { get a terminal node }
   writenadr(netfil, n); { output }
   newnode(b, n, p);       { get b terminal node }
   writenadr(netfil, n); { output }
   writesreal(netfil, r) { output ohms }

end;

{**************************************************************

Read input line

Reads a line of text from the given text file into the
command buffer.

**************************************************************}

procedure readline; { input file }

var ovf: boolean; { overflow flag }

begin

   if not endf then begin

      clears(cmdlin); { clear command line }
      i := 1; { set 1st character position }
      if srclin then { reading source }
         begin if eof(cktfil) then begin

            close(cktfil); { close input file }
            cktnam := cktnam^.next; { pop top file }
            { open new file }
            if cktnam <> nil then begin

               assign(cktfil, cktnam^.nam);
               reset(cktfil);
               lincnt := 0; { clear line count }
               if fverb then begin { output process message }

                  write(listf, 'Processing: ');
                  writelab(listf, cktnam^.nam);
                  writeln(listf)

               end

            end else endf := true end { no more files }

         end;
      if not endf then begin

         if srclin then begin

            reads(cktfil, cmdlin, ovf); { get line }
            if ovf then error(eilovf); { process error }
            readln(cktfil) { skip line end }

         end else begin

            reads(command, cmdlin, ovf); { get the command line }
            if ovf then error(eilovf) { process error }

         end;
         cmdptr := 1; { set 1st character position }
         if srclin then lincnt := lincnt + 1 { count lines }

      end

   end

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
   else if srclin then readline { load new line }
   else endf := true { set end }

end;

{**************************************************************

Skip spaces

Skips spaces in the command line. If at line end, we stop.
Will also skip comments, tabs and form feeds.

***************************************************************}

procedure skpspc;

begin

   while ((chkchr = ' ') or (chkchr = chr(8) { \ht }) or
          (chkchr = chr(12) { \ff }) or (chkchr = '{')) and not endf do begin

      if chkchr = '{' then { comment }
         repeat getchr until (chkchr = '}') or endf;
      getchr { skip }

   end

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
   while chkchr in ['A'..'Z', 'a'..'z', '0'..'9', '_', '[', ']'] do
      begin

      if i > labmax then error(elabtl); { process error }
      n[i] := chkchr; { place character }
      i := i + 1; { next character }
      getchr { next character }

   end;
   { convert to lower case }
   for i := 1 to labmax do n[i] := lcase(n[i]);
   if n = '                    ' then error(ecpar) { no word found }

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

begin

   n := 0.0; { initalize number }
   p := 1.0; { set scaling factor }
   dp := false; { set decimal point not scanned }
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

   end

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

Get node label

Gets a valid node label from the command line. This will also
strip off a trailing repetition marker, and return the start,
end and increment parameters.
A repetition marker is of the following form:

     name[start]

or

     name[start:end]

or

     name[start:end:step]

Note that the first form is a nop (the name is passed as is).
Generates an error on label overflow or no word found.

***************************************************************}

procedure GetNodeLabel(var n: nodlab; var s, e, ic: byte);

var i : labinx; { index for label }
    w: nodadr;

begin

   ic := 255; { flag no rep (impossible value, since 255 - 1 = 254) }
   n := '                    ';
   skpspc; { skip spaces }
   i := 1; { initalize label pointer }
   while chkchr in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do begin

      if i > labmax then error(elabtl); { process error }
      n[i] := chkchr; { place character }
      i := i + 1; { next character }
      getchr { next character }

   end;
   { convert to lower case }
   for i := 1 to labmax do n[i] := lcase(n[i]);
   if n = '                    ' then error(ecpar); { no word found }
   if chkchr = '[' then begin { repetition specification }

      getchr; { skip '[' }
      getnum(w); { get the start address }
      if w > 255 then error(einvrpp); { error }
      s := w; { place }
      skpspc; { skip spaces }
      if chkchr = ':' then begin { end is present }

         i := 1; { set default specification }
         getchr; { skip ':' }
         getnum(w); { get the end address }
         if w > 255 then error(einvrpp); { error }
         e := w; { place }
         ic := 1; { set default increment }
         skpspc; { skip spaces }
         if chkchr = ':' then begin { increment is present }

            getchr; { skip ':' }
            getnum(w); { get the increment }
            if w > 254 then error(einvrpp); { error }
            ic := w { place }

         end

      end else addinx(n, w); { start only, add index }
      skpspc; { skip spaces }
      if chkchr <> ']' then error(erbexp); { error }
      getchr { skip ']' }

   end

end;

{**************************************************************

Process caller line

Read a line from the given file, and processes the circuit
file there and any command line options.

**************************************************************}

procedure prcopt;

var last: cktptr; { pointer for last entry }

begin

   fout := false; { set no output }
   new(cktnam); { allocate a new file entry }
   cktnam^.next := nil; { clear next }
   last := cktnam; { save that }
   readline; { load command line }
   skpspc; { skip spaces }
   if cmdptr > linmax then error(ecfns); { error }
   getword(cktnam^.nam); { get the circuit file name }
   skpspc; { skip spaces }
   if chkchr = '=' then begin { output file present }

      getchr; { skip '=' }
      fout := true; { set flag }
      new(last^.next); { allocate next entry }
      last := last^.next; { index that }
      last^.next := nil; { clear next }
      getword(last^.nam) { get the circuit file name }

   end;
   skpspc; { skip spaces }
   while (cmdptr <= linmax) and not (chkchr = '#') do begin

      { parse files }
      new(last^.next); { allocate next entry }
      last := last^.next; { index that }
      last^.next := nil; { clear next }
      getword(last^.nam); { get the circuit file name }
      skpspc { skip spaces }

   end;
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

              end

      end;
      skpspc { skip spaces }

   end
end;

{**************************************************************

Process cell call

Parses the parameters for a given cell and generates the
cell call.

***************************************************************}

procedure exccel(c: celptr);

var np, p: nodptr; { pointer for nodes }
    pc: byte; { parameter count }
    n: nodadr;
    w: nodlab;
    s, e, ic: byte;
    y: integer;

begin

   writec(dicfil, 4); { mark cell beginning in dictionary }
   writec(dicfil, c^.num div 256); { output number high }
   writec(dicfil, c^.num mod 256); { output number low }
   pc := 0; { count parameters }
   writec(netfil, $43); { output cell call code }
   writec(netfil, c^.num div 256); { output number high }
   writec(netfil, c^.num mod 256); { output number low }
   pc := 0; { count parameters }
   np := c^.par;
   while np <> nil do begin pc := pc + 1; np := np^.next end;
   writec(netfil, pc); { output parameters count }
   np := c^.par; { index parameters }
   if c^.par <> nil then begin { skip ':' }

      skpspc; { skip spaces }
      if chkchr <> ':' then error(eclnexp); { error }
      getchr { skip }

   end;
   while np <> nil do begin { parse parameters }

      GetNodeLabel(w, s, e, ic); { get a node }
      if ic <> 255 then begin

         if s <= e then begin { increment to end }

            y := s; { copy start }
            while y <= e do begin

               if np = nil then error(evectl); { error }
               s := y; { copy start }
               addinx(w, s); { place index }
               y := y + ic; { set next index }
               newnode(w, n, p); { find corresponding node }
               if np^.drv then p^.drv := true; { copy driven status }
               writenadr(netfil, n); { output }
               np := np^.next { link next parameter }

            end

         end else begin { decrement to end }

            y := s; { copy start }
            while y >= e do begin

               if np = nil then error(evectl); { error }
               s := y; { copy start }
               addinx(w, s); { place index }
               y := y - ic; { set next index }
               newnode(w, n, p); { find corresponding node }
               if np^.drv then p^.drv := true; { copy driven status }
               writenadr(netfil, n); { output }
               np := np^.next { link next parameter }

            end

         end

      end else begin { standard node label }

         newnode(w, n, p); { find corresponding node }
         if np^.drv then p^.drv := true; { copy driven status }
         writenadr(netfil, n); { output }
         np := np^.next { link next parameter }

      end;
      if np <> nil then begin { skip ',' }

         skpspc; { skip spaces }
         if chkchr <> ',' then error(ecmaexp); { error }
         getchr { skip }

      end

   end;
   nodnum := nodnum + c^.nodc { add include node count to cell }

end;

{**************************************************************

Assemble statement

Assembles one or more statements.

***************************************************************}

procedure statement(var c: nodlab);

var s, g, d, a, b: nodlab; { label holders }
    f, r: real; { farads and ohms }
    dv : devtyp; { device type }
    cp: celptr; { pointer for cell entries }
    ln, wd: real; { length and width }

begin

   if (c = 'neif                ') or
      (c = 'peif                ') or
      (c = 'wneif               ') or
      (c = 'wpeif               ') then begin

      skpspc; { check ':' }
      if chkchr <> ':' then error(eclnexp); { error }
      getchr; { skip ':' }
      { enter transistor }
      { set transistor type }
      if c = 'neif                ' then dv := dnmos
      else if c = 'peif                ' then dv := dpmos
      else if c = 'wneif               ' then dv := dwnmos
      else dv := dwpmos;
      getword(s); { get source }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { error }
      getchr; { skip ',' }
      getword(g); { get gate }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { error }
      getchr; { skip ',' }
      getword(d); { get drain }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { error }
      getchr; { skip ',' }
      getrnm(wd); { get width }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { must both be present }
      getchr; { skip ',' }
      getrnm(ln); { get length }
      outtrans(dv, s, g, d, ln, wd) { create transistor }

   end else if c = 'cap                 ' then begin

      skpspc; { check ':' }
      if chkchr <> ':' then error(eclnexp); { error }
      getchr; { skip ':' }
      getword(a); { get a terminal }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { error }
      getchr; { skip ',' }
      getrnm(f); { get farads }
      outcap(a, f) { create capacitor }

   end else if c = 'res                 ' then begin

      skpspc; { check ':' }
      if chkchr <> ':' then error(eclnexp); { error }
      getchr; { skip ':' }
      getword(a); { get a terminal }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { error }
      getchr; { skip ',' }
      getword(b); { get b terminal }
      skpspc; { check ',' }
      if chkchr <> ',' then error(ecmaexp); { error }
      getchr; { skip ',' }
      getrnm(r); { get ohms }
      outres(a, b, r) { create resistor }

   end else begin { try to find cell definition }

      cp := celtbl; { index macro table root }
      if cp = nil then error(ecnf); { process error }
      while cp <> nil do begin { fit cell }

         if c = cp^.lab then begin

            exccel(cp); { found, execute }
            cp := nil { flag done }

         end else begin { next }

            cp := cp^.next; { link next }
            if cp = nil then error(ecnf) { process error }

         end

      end

   end

end;

{**************************************************************

Assemble net

Assembles one or more cells.  Note that cells do not enter
the definition table until they are completely defined. This
makes it immpossible to recursively reference a cell.

***************************************************************}

procedure cassm(var f: text);

var cp: celptr; { cell list pointer }
    np, lp, p: nodptr;
    w: nodlab;
    i: labinx;
    x: nodadr;
    c: char;
    pc: byte;
    s, e, ic: byte;
    y: integer;

begin

   skpspc; { skip spaces }
   while not endf do begin

      getword(w); { check 'cell' }
      if w <> 'cell                ' then error(ecelexp); { error }
      getword(w); { get the cell name }
      { check attempt to redefine cell }
      cp := celtbl; { index cell table start }
      while cp <> nil do begin

         if equ(cp^.lab, w) then error(edupcel); { error }
         cp := cp^.next { next entry }

      end;
      writec(netfil, $41); { mark cell start for net }
      writec(dicfil, 1); { and for dictionary }
      celnum := celnum + 1; { count cells }
      new(cp); { get a cell entry }
      cp^.lab := w; { place cell name }
      cp^.num := celnum; { place cell number }
      cp^.par := nil; { clear parameter list }
      lp := nil; { clear last }
      writec(dicfil, lenl(cp^.lab)); { output length }
      { output cell name }
      for i := 1 to lenl(cp^.lab) do writec(dicfil, ord(cp^.lab[i]));
      pc := 0; { set parameter count }
      skpspc; { skip spaces }
      if chkchr = ':' then begin { parameters present }

         getchr; { skip ':' }
         repeat { parse parameters }

            GetNodeLabel(w, s, e, ic); { get a node }
            if ic <> 255 then begin

               if s <= e then begin { increment to end }

                  y := s; { copy start }
                  while y <= e do begin

                     s := y; { copy start }
                     addinx(w, s); { place index }
                     y := y + ic; { set next index }
                     orgnode(w, x, p); { create a node for that }
                     p^.ref := false; { set not referenced }
                     getnod(np); { get a parameter entry }
                     np^.next := nil; { clear next }
                     np^.ref := false; { clear reference }
                     np^.lab := w; { place label }
                     if lp = nil then cp^.par := np { place link }
                     else lp^.next := np;
                     lp := np; { set last }
                     pc := pc + 1 { count parameter }

                  end

               end else begin { decrement to end }

                  y := s; { copy start }
                  while y >= e do begin

                     s := y; { copy start }
                     addinx(w, s); { place index }
                     y := y - ic; { set next index }
                     orgnode(w, x, p); { create a node for that }
                     p^.ref := false; { set not referenced }
                     getnod(np); { get a parameter entry }
                     np^.next := nil; { clear next }
                     np^.ref := false; { clear reference }
                     np^.lab := w; { place label }
                     if lp = nil then cp^.par := np { place link }
                     else lp^.next := np;
                     lp := np; { set last }
                     pc := pc + 1 { count parameter }

                  end

               end

            end else begin { standard node label }

               orgnode(w, x, p); { create a node for that }
               p^.ref := false; { set not referenced }
               getnod(np); { get a parameter entry }
               np^.next := nil; { clear next }
               np^.ref := false; { clear reference }
               np^.lab := w; { place label }
               if lp = nil then cp^.par := np { place link }
               else lp^.next := np;
               lp := np; { set last }
               pc := pc + 1 { count parameter }

            end;
            skpspc; { skip spaces }
            c := chkchr; { check ',' }
            if c = ',' then getchr { skip if so }

         until c <> ',' { no more parameters }

      end;
      if chkchr <> ';' then error(escnexp); { error }
      getchr; { skip ';' }
      writec(dicfil, pc); { output parameter count }
      nodnum := 0; { clear node count }
      getword(w); { get next }
      if w <> 'begin               ' then error(ebgcexp); { error }
      getword(w); { get next }
      if not (w = 'end                 ') then statement(w); { execute }
      skpspc; { skip spaces }
      while (chkchr = ';') and
            not (w = 'end                 ') and
            not endf do begin { parse statements }

         getchr; { skip ';' }
         skpspc; { check end }
         if not endf then begin

            getword(w); { get command }
            if not (w = 'end                 ') then statement(w); { execute }
            skpspc { skip spaces }

         end

      end;
      if (w <> 'end                 ') and not endf then begin

         getword(w); { parse next }
         if w <> 'end                 ' then error(eedcexp); { error }
         skpspc { skip spaces }

      end;
      if (chkchr <> ';') and not endf then error(escnexp); { error }
      getchr; { skip ';' }
      skpspc; { skip spaces }
      outdic; { output the directory }
      writec(dicfil, 2); { output cell end marker }
      writec(netfil, $42); { mark cell end }
      cp^.next := celtbl; { link cell into table }
      celtbl := cp;
      cp^.nodc := nodnum; { set total nodes in cell }
      np := cp^.par; { index parameter node lists }
      p := nodtbl;
      while np <> nil do begin { traverse }

         if p = nil then error(esys); { error }
         np^.drv := p^.drv; { copy driven status }
         if not p^.ref then begin { unreferenced parameter }

            write(f, '*** Warning: Unreferenced parameter node ''');
            writelab(f, p^.lab); { output label }
            write(f, ''' in cell ''');
            writelab(f, cp^.lab); { output cell }
            writeln(f, '''')

         end;
         np := np^.next; { next }
         p := p^.next

      end;
      while p <> nil do begin { validate drive status }

         if not p^.drv then begin { undriven node }

            write(f, '*** Warning: Infinite impedence node ''');
            writelab(f, p^.lab); { output label }
            write(f, ''' in cell ''');
            writelab(f, cp^.lab); { output cell }
            writeln(f, '''')

         end;
         p := p^.next { next }

      end;
      frenod := nodtbl; { free node list }
      nodtbl := nil

   end

end;

{**************************************************************

Main program

Initalizes global variables, processes the options, loads
the circuit file and runs the simulation.

**************************************************************}

begin

   l := '_output             '; { open default output file }
   assign(listf, l);
   rewrite(listf);

   writeln('Circuit assembler 0.1 Copyright (C) 1989 S. A. Moore');

   { initalize tables }

   nodtbl := nil;
   frenod := nil;
   celtbl := nil;
   nodnum := 0; { clear node counts }
   devnum := 0; { clear device count }
   celnum := 0; { clear cell count }
   fverb := false; { set verbose off }
   srclin := false; { set source reading false }
   endf := false; { set not end }
   lincnt := 0; { clear line count }

   { process options and open output file }

   prcopt; { process options }
   netnam := cktnam^.nam; { copy file names }
   dicnam := cktnam^.nam;
   addext(netnam, '.net                '); { place extentions }
   addext(dicnam, '.dic                ');
   if fout then cktnam := cktnam^.next; { remove output filename }
   fp := cktnam; { index top of list }
   while fp <> nil do begin { process and check all input files }

      addext(fp^.nam, '.ckt                '); { place extention }
      { check circuit file exists }
      if not exists(fp^.nam) then error(ecfnf);
      fp := fp^.next { index next entry }

   end;
   assign(cktfil, cktnam^.nam); { open first circuit file }
   reset(cktfil);
   endf := false; { set not end }
   if fout then begin

      assign(netfil, netnam); { open net file }
      rewrite(netfil); 
      assign(dicfil, dicnam); { open dictionary file }
      rewrite(dicfil)

   end;

   { process circuit file }

   if fverb then begin { output process message }

      write(listf, 'Processing: ');
      writelab(listf, cktnam^.nam);
      writeln(listf)

   end;
   srclin := true; { set source reading }
   cassm(listf); { run assembly }
   writec(netfil, 0); { terminate net }
   writec(dicfil, 0); { terminate dictionary }
   if fverb then begin { output process message }

      if celtbl <> nil then begin

         write(listf, 'Cell name: '); { write top cell name }
         writelab(listf, celtbl^.lab);
         writeln(listf)

      end;
      writeln(listf, 'Total devices: ', devnum:1); { write devices }
      writeln(listf, 'Total nodes:   ', nodnum:1); { write nodes }
      writeln(listf, 'Total cells:   ', celnum:1)  { write cells }

   end;

   99: { abort program }

   if fverb then writeln(listf, 'Function complete');
   close(listf); { close the files }
   if fout then begin

      close(netfil);
      close(dicfil)

   end

end.

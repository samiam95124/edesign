segment utla;

{$i fltdef}
{$i common}

procedure error(e: errcod); external; { process error }
{}
{**************************************************************

Get parameter entry

Returns either a new or old parameter entry

**************************************************************}

procedure getpar(var p: parptr);

begin

   if frepar <> nil then begin { recycle old }

      p := frepar; { index top entry }
      frepar := frepar^.next { gap list }

   end else new(p) { get a new entry }

end;
{}
{**************************************************************

Put parameter entry

Returns a used parameter entry to free

**************************************************************}

procedure putpar(p: parptr);

begin

   p^.next := frepar; { place next }
   frepar := p { place top }

end;
{}
{**************************************************************

Convert to lower case

Converts the given character to lower case and returns.
Only characters 'A'..'Z' are converted.

**************************************************************}

function lcase(c: char):char;

begin
   if c in ['A'..'Z'] then { convert }
      c := chr(ord(c) - ord('A') + ord('a'));
   lcase := c
end;
{}
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
{}
{**************************************************************

Read input line

Reads a line of text from the given text file into the
command buffer. No interactive processing is implemented.

**************************************************************}

procedure readline(f: text); { input file }

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
{}
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
{}
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
{}
{**************************************************************

Process caller line

Read a line from the given file, and processes the circuit
file there and any command line options.

**************************************************************}

procedure prcopt;

begin
   readline(f); { load command line }
   skpspc; { skip spaces }
   if cmdptr > linmax then error(ecfns); { error }
   getword(netnam) { get the circuit file name }
end;
{}
{**************************************************************

Read 16 bit word

Reads a 16 bit high/low number from the given file.

**************************************************************}

procedure readword(f: bytfil; var w: nodadr);

var h, l: byte;

begin

   read(f, h); { get middle byte }
   read(f, l); { get low byte }
   w := (256*h)+l { convert and place }

end;
{}
{**************************************************************

Read 32 bit node address from the given file

**************************************************************}

procedure readnadr(f: bytfil; var n: nodadr);

type na = array [1..4] of byte; { a bin for 32 bit integer }
     np = ^na;

var nd: np;
    t: ptr; { used to pass type }

begin

   t := nodeconv; { pass type }
   nd := t;
   read(f, nd^.[4]); { read address }
   read(f, nd^.[3]);
   read(f, nd^.[2]);
   read(f, nd^.[3]);
   n := nodconv^ { place }

end;
{}
{**************************************************************

Read single real

Reads the single precision IEEE format real from the given
file, and simply stores that.

**************************************************************}

procedure readsreal(f: bytfil; var r: single);

type single = array [1..4] of byte; { a bin for single precision }
     sp = ^single;

var sr: sp;
    t: ptr; { used to pass type }

begin

   t := realconv; { pass type }
   sr := t;
   read(f, sr^.[4]); { read real }
   read(f, sr^.[3]);
   read(f, sr^.[2]);
   read(f, sr^.[1]);
   r := realconv^ { get result }

end;
{}
{**************************************************************

Write real

Writes the given real out to a byte file, high order to low
order.

**************************************************************}

procedure writesreal(var f: bytfil; { file to write }
                     var r: real);  { real to be written }
                    

type single = array [1..4] of byte; { a bin for single precision }
     sp = ^single;

var sr: sp;
    t: ptr; { used to pass type }

begin

   realconv^ := r; { place real in convertion area }
   t := realconv; { pass type }
   sr := t;
   writec(f, sr^[4]); { output }
   writec(f, sr^[3]);
   writec(f, sr^[2]);
   writec(f, sr^[1])

end;
{}
{**************************************************************

Write 32 bit word

Outputs a word to the file, expanding that with 8 zero high
bits.

**************************************************************}

procedure writenadr(var f: bytfil; n: nodadr);

type na = array [1..4] of byte; { a bin for 32 bit integer }
     np = ^na;

var nd: np;
    t: ptr; { used to pass type }

begin

   nodeconv^ := n; { place real in convertion area }
   t := nodeconv; { pass type }
   nd := t;
   writec(f, nd^[4]); { output }
   writec(f, nd^[3]);
   writec(f, nd^[2]);
   writec(f, nd^[1])

end;
{}
{**************************************************************

Load circuit file

**************************************************************}

procedure loadckt;

var cp: celptr; { pointer for cells }
    dp, ld: fetptr; { pointer for devices }
    pp, lp: parptr; { pointer for parameters }
    pc: byte; { parameter count }
    b: byte;

begin

   new(dp); { get a new entry }
   dp^.next := nil; { clear }
   dp^.source := 0;
   dp^.gate := 0;
   dp^.drain := 0;
   dp^.par := nil;
   if ld = nil then cp^.dev := dp { link to root }
   else ld^.next := dp; { link to last }
   ld := dp { set last }

end;

begin

   repeat { cells }

      read(netfil, b); { get cell code }
      if b <> $00 then begin { not end }

         if b <> $41 then error(einvnff); { error }
         new(cp); { get a new cell }
         cp^.next := celtbl; { link in }
         celtbl := cp;
         celnum := celnum + 1; { count cells }
         cp^.dev := nil; { clear device list }
         ld := nil; { clear last device }
         repeat { devices }

            read(netfil, b); { get device code }
            if b in [$10, $11, $12, $13] then begin { fet }

               getdev(dp); { get a new device entry }
               case b of { fet }

                  $10: dp^.typet := pmos; { set type }
                  $11: dp^.typet := wpmos;
                  $12: dp^.typet := nmos;
                  $13: dp^.typet := wnmos

               end;
               read24(netfil, dp^.source);    { get source }
               read24(netfil, dp^.gate);      { get gate }
               read24(netfil, dp^.drain);     { get drain }
               readsreal(netfil, dp^.width);  { get width }
               readsreal(netfil, dp^.length)  { get length }

            end else if b = $20 then begin { resistor }

               getdev(dp); { get a new device entry }
               dp^.typet := res;
               read24(netfil, dp^.source);   { get a terminal }
               read24(netfil, dp^.drain);    { get b terminal }
               readsreal(netfil, dp^.width)  { get resistance }

            end else if b = $80 then begin { capacitor }

               getdev(dp); { get a new device entry }
               dp^.typet := cap;
               read24(netfil, dp^.source);   { get a terminal }
               readsreal(netfil, dp^.width)  { get resistance }

            end else if b = $43 then begin { cell }

               getdev(dp); { get a new device entry }
               dp^.typet := cellr; { set type }
               readword(netfil, dp^.num); { get cell number }
               read(netfil, pc); { get the parameter count }
               lp := nil; { clear last }
               while pc <> 0 do begin { read parameters }

                  getpar(pp); { get a parameter entry }
                  pp^.next := nil; { clear next }
                  if lp = nil then dp^.par := pp { link to root }
                  else lp^.next := pp; { link in line }
                  lp := pp; { copy last }
                  readword(netfil, pp^.num); { get node number }
                  pc := pc - 1 { count }

               end

            end else if b <> $42 then error(einvnff) { error }

         until b = $42 { end of cell }

      end

   until b = $00 { end of file }

end;
{}
{**************************************************************

Output simulator file

**************************************************************}

procedure outsim;

var nodnum: nodadr; { node output address }

procedure max(dp: fetptr); { find maximum node number }

var t: nodadr; { top }
    pp: parptr;

procedure top(w: nodadr);

begin

   if (w + 1) > t then t := w + 1

end;

begin

   t := 0; { clear top }
   while dp <> nil do begin { traverse }

      if dp^.typet in [nmos, pmos, wnmos, wpmos] then begin { xstr }

         top(dp^.source); { do all terminals }
         top(dp^.gate);
         top(dp^.drain)

      end else if dp^.typet = res then begin { resistor }

         top(dp^.source); { do all terminals }
         top(dp^.gate);
         top(dp^.drain)

      end else if dp^.typet = res then { capacitor }

         top(dp^.source) { do all terminals }

      else if dp^.typet = cellr then begin

         pp := dp^.par; { index parameter list }
         while pp <> nil do begin { traverse }

            top(pp^.num);
            pp := pp^.next

         end

      end;
      dp := dp^.next { next }

   end;
   nodnum := nodnum + t { find new top }

end;

procedure outcell(cp: celptr; { cell that is to be output }
                  pp: parptr; { list of parameter nodes }
                  pb: nodadr);  { base address of parameter nodes }

var base: nodadr; { base of current cell node addresses }
    dp: fetptr; { device pointer }
    pc: byte; { parameter count }
    pi, pi2, lp: parptr; { parameter list index }
    tp: parptr; { parameter list start }
    cc: nodadr;
    nc: celptr;

function xlate(n: nodadr): nodadr; { find proper node address }

var pi: parptr; { parameter list pointer }

begin

   if n < pc then begin { is a parameter node, remap }

      pi := pp; { index top }
      while (pi <> nil) and (n <> 0) do
         begin n := n - 1; pi := pi^.next end;
      if pi = nil then error(esys);
      xlate := pi^.num { place }

   end else xlate := n+base-pc { place offset address }

end;

procedure outnode(n: nodadr); { output node address }

begin

   write24(simfil, xlate(n)) { output translated node }

end;

begin

   pc := 0; { clear parameter count }
   pi := pp; { count parameters }
   while pi <> nil do begin pc := pc + 1; pi := pi^.next end;
   base := nodnum; { set base of addresses }
   max(cp^.dev); { find next top }
   nodnum := nodnum - pc; { eliminate parameters }
   dp := cp^.dev; { index device list }
   while dp <> nil do begin { traverse }

      case dp^.typet of

         pmos:  begin { p chan }

                   write(simfil, $10);     { output device code }
                   outnode(dp^.source);    { source }
                   outnode(dp^.gate);      { gate }
                   outnode(dp^.drain);     { drain }
                   writesreal(simfil, dp^.width);  { width }
                   writesreal(simfil, dp^.length)  { length }

                end;

         wpmos: begin { weak p chan }

                   write(simfil, $11); { output device code }
                   outnode(dp^.source); { source }
                   outnode(dp^.gate);   { gate }
                   outnode(dp^.drain);   { drain }
                   writesreal(simfil, dp^.width);  { width }
                   writesreal(simfil, dp^.length)  { length }

                end;

         nmos:  begin { n chan }

                   write(simfil, $12); { output device code }
                   outnode(dp^.source); { source }
                   outnode(dp^.gate);   { gate }
                   outnode(dp^.drain);   { drain }
                   writesreal(simfil, dp^.width);  { width }
                   writesreal(simfil, dp^.length)  { length }

                end;

         wnmos: begin { weak n chan }

                   write(simfil, $13); { output device code }
                   outnode(dp^.source); { source }
                   outnode(dp^.gate);   { gate }
                   outnode(dp^.drain);   { drain }
                   writesreal(simfil, dp^.width);  { width }
                   writesreal(simfil, dp^.length)  { length }

                end;

         res:   begin { resistor }

                   write(simfil, $20);    { output device code }
                   outnode(dp^.source);   { a terminal }
                   outnode(dp^.drain);    { b terminal }
                   writesreal(simfil, dp^.width)  { resistance }

                end;

        cap:   begin { capacitor }

                   write(simfil, $80);    { output device code }
                   outnode(dp^.source);   { a terminal }
                   writesreal(simfil, dp^.width)  { capacitience }

                end;

         cellr:  begin { cell }

                   { find corresponding cell }
                   cc := celnum; { get max cell }
                   nc := celtbl; { index top cell }
                   while (cc <> dp^.num) and (nc <> nil) do
                      begin cc := cc - 1; nc := nc^.next end; { search }
                   if nc = nil then error(esys);
                   { form translated parameter list to pass on }
                   tp := nil; { clear list }
                   lp := nil; { clear last }
                   pi := dp^.par; { index top of source list }
                   while pi <> nil do begin { traverse }

                      getpar(pi2); { get a new parameter entry }
                      pi2^.next := nil; { clear next }
                      if lp = nil then tp := pi2 { link to root }
                      else lp^.next := pi2; { link in line }
                      lp := pi2; { copy last }
                      pi2^.num := xlate(pi^.num); { place translated node }
                      pi := pi^.next { link next }

                   end;
                   outcell(nc, tp, base); { output that cell }
                   while tp <> nil do begin { dispose of list }

                      pi := tp^.next; { save next }
                      putpar(tp); { dispose of top entry }
                      tp := pi { set next }

                   end

                end

      end;
      dp := dp^.next { next device }

   end

end;

begin

   nodnum := 0; { initalize node address count }
   outcell(celtbl, nil, 0); { output top cell }
   write(simfil, 0) { output file end }

end;

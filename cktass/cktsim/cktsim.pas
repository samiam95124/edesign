{**************************************************************
*                                                             *
*                 CMOS CIRCUIT SIMULATOR                      *
*                                                             *
*                 8/88 S. A. Moore                            *
*                                                             *
* A transistor level simulator intendended primarily for CMOS *
* circuits. Simulates a network of N and P channel            *
* transistors with connecting nodes. The transistors appear   *
* with no source to drain delay, no resistance, and a "unit"  *
* delay from gate to switch that forms the quanta of this     *
* simulator. Many classes of high, low and indeterminate      *
* states are supported.                                       *
* The network and other paramters are input via a single      *
* file format. This is "unversal" in that a single file can   *
* contain all parameters, but these are more typically        *
* broken down into different files. For example:              *
*                                                             *
*     file.ckt - Contains the netlist.                        *
*     file.clk - Contains clocking sets.                      *
*     file.fmt - Contains the output format.                  *
*     file.cmd - Contains the command file.                   *
*                                                             *
* The file consists of a set of command lines of the format:  *
*                                                             *
*     <comm> <par>                                            *
*                                                             *
* The following commands are implemented:                     *
*                                                             *
* n <source> <gate> <drain> - Creates an N channel            *
*                             transistor, with the indicated  *
*                             node labels.                    *
* p <source> <gate> <drain> - Creates a P channel             *
*                             transistor, with the indicated  *
*                             node labels.                    *
* set <node> <value>        - Sets the node to the given      *
*                             value before the simulation     *
*                             starts.                         *
* clock <node> <time> <value> [<time> <value>] - Sets the     *
*                             node to a sequence of values    *
*                             based on the time of            *
*                             appearance.                     *
*                                                             *
* Future commands/functions:                                  *
*                                                             *
* Stored value decay.                                         *
* Commands that can execute on demand, as step, etc.          *
* Automatic fallthrough to interactive mode, along with       *
* debug commands like display current node state, parameters, *
* etc.                                                        *
* Circuit reports by node and circuit.                        *
* Ability to specify multiple .ckt files to be concatenated.  *
* Ability to save and restore current state (usefull with     *
* very large nets).                                           *
* Ability to turn display off and on, to specify the quanta   *
* of display, etc.                                            *
* Ability to save history points and to adjust quanta of      *
* these, then the ability to run them back.                   *
* Ability to trigger commands on node conditions.             *
* VERY interactive mode with on-screen update, sliding traces.*
* Ability to integrate HLL module simulators.                 *
* Alternative eval function in assembly for speed.            *
*                                                             *
**************************************************************}

program cktsim(command, output);

uses stddef,
     strlib;

label 99; { abort program }

const linmax = 80; { maximum command line }
      labmax = 20; { maximum characters per label }
      trcmax = 80; { maximum number of trace steps saved }

type labinx  = 1..labmax; { index for label }
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
     nodptr = ^node;   { node pointer }
     fetptr  = ^fet;     { pointer to fet }
     node    = record   { node }
                  lab:    nodlab; { name of the node }
                  statel: nodest; { last node state }
                  staten: nodest; { next node state }
                  next:   nodptr  { next list node }
               end;
     { transistor type }
     trntyp  = (nmos,   { n-channel }
                pmos,   { p-channel }
                wnmos,  { weak n-channel }
                wpmos); { weak p-channel }
     fet     = record
                  typet:  trntyp;  { transistor type }
                  source: nodptr; { source node connect }
                  gate:   nodptr; { gate node connect }
                  drain:  nodptr; { drain node connect }
                  next:   fetptr; { next in list }
               end;
    statbl   = array [nodest, nodest] of
                  record
                     source: nodest; { new source state }
                     drain:  nodest  { new drain state }
                  end;
    lininx   = 1..linmax; { command line index }
    errcod   = (ecpar,    { command/parameter not found }
                ecnf,     { command not found }
                eilovf,   { input line overflow }
                elabtl,   { label too long }
                ecfns,    { circuit file not specified }
                eivopt,   { invalid option }
                ecfnf,    { circuit file not found }
                enumovf,  { integer overflow }
                enumnf,   { number not found }
                einvcmd,  { invalid command }
                eutmac,   { unterminated macro }
                emetl,    { macro expansion too long }
                eparc);   { parameter correspondence }
    stattr   = array [nodest] of nodest; { state translate table }
    equsta   = packed array [nodest] of char;   { state equate table }
    line     = packed array [lininx] of char;   { input line buffer }
    setptr   = ^nodset; { node set entry pointer }
    nodset   = record   { node set entry }
                  clk: integer;     { clock to trigger on }
                  per: integer;     { period of clock }
                  nod: nodptr;   { node to set }
                  state: nodest; { state to set to }
                  next: setptr   { next entry }
               end;
    trcinx   = 1..trcmax; { index for trace buffer }
    trclin   = array [trcinx] of nodest; { single trace line }
    trcptr   = ^trcbuf; { trace buffer pointer }
    trcbuf   = record { trace buffer }
                  nod: nodptr; { pointer to traced node }
                  buf: trclin; { line of trace }
                  next: trcptr { next entry }
               end;
    fmtptr   = ^fmtspc; { pointer to format specification }
    fmtspc   = record { format specification }
                  nod: nodptr; { pointer to formatted node }
                  next: fmtptr { next entry }
               end;
    parptr   = ^parlab; { parameter label pointer }
    parlab   = record
                  lab: nodlab; { label for parameter }
                  next: parptr { next entry }
               end;
    linptr   = ^linbuf; { pointer to line buffer }
    linbuf   = record
                  lin: line; { line buffer }
                  next: linptr { next entry }
               end;
    macptr   = ^macro; { macro entry pointer }
    macro    = record { macro definition }
                  nam: nodlab; { name of macro }
                  num: integer;   { execution count }
                  par: parptr; { parameter table }
                  lin: linptr; { line table }
                  next: macptr { next entry }
               end;

var ontbl: statbl;     { "on strong" table }
    indtbl: statbl;    { "indeterminate" strong table }
    wontbl: statbl;    { "on weak" table }
    windtbl: statbl;   { "indeterminate weak" table }
    fettbl: fetptr;    { transistor list }
    nodtbl: nodptr;    { node list }
    settbl: setptr;    { node set list }
    strtbl: stattr;    { clock start states }
    clkcnt: integer;   { current clock }
    clkscale: integer; { clock scaling factor }
    equtbl: equsta;    { node state memnonics }
    cmdlin: line;      { input command buffer }
    cmdptr: lininx;    { current command line position }
    outnam: nodlab;    { output file name }
    outfil: text;      { output file }
    outopn: boolean;   { output file open }
    cktnam: nodlab;    { circuit file name }
    cktfil: text;      { circuit file }
    cktopn: boolean;   { circuit file open }
    trace:  boolean;   { trace mode flag }
    trctbl: trcptr;    { trace table root }
    stpcnt: integer;   { step count }
    labtop: 0..labmax; { top label character count }
    trccnt: trcinx;    { current tracing count }
    i: integer;        { step counter }
    lswidth: integer;  { width of output listing }
    lslen: integer;    { length of page }
    lincnt: integer;   { current line on page count }
    pagcnt: integer;   { current page count }
    trcnum: integer;   { number of traces in a chart }
    first: boolean;    { first trace on page }
    margin: integer;   { left margin }
    fmttbl: fmtptr;    { format table }
    mactbl: macptr;    { macro definition table }
    i1: integer;

procedure exclin(var f: text); forward;

{**************************************************************

Process error

Prints an error message by the given error code and aborts.
The procedure does not return.

**************************************************************}

procedure error(e: errcod);

begin

   write('*** '); { output header }
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
      eutmac:  writeln('Unterminated macro');
      emetl:   writeln('Macro expansion too long');
      eparc:   writeln('Macro parameters do not correspond')

   end;
   goto 99

end;

{**************************************************************

Initalize "on" strong table

This table contains the evaluation rules for "on" strong
transistors.

**************************************************************}

procedure initon;

begin

   ontbl[undef, undef ].source := undef;
   ontbl[undef, undef ].drain  := undef;
   ontbl[undef, indet ].source := indet;
   ontbl[undef, indet ].drain  := indet;
   ontbl[undef, indrh ].source := indrh;
   ontbl[undef, indrh ].drain  := indrh;
   ontbl[undef, indrl ].source := indrl;
   ontbl[undef, indrl ].drain  := indrl;
   ontbl[undef, widh  ].source := widh;
   ontbl[undef, widh  ].drain  := widh;
   ontbl[undef, widl  ].source := widl;
   ontbl[undef, widl  ].drain  := widl;
   ontbl[undef, cont  ].source := cont;
   ontbl[undef, cont  ].drain  := cont;
   ontbl[undef, wcont ].source := wcont;
   ontbl[undef, wcont ].drain  := wcont;
   ontbl[undef, high  ].source := high;
   ontbl[undef, high  ].drain  := high;
   ontbl[undef, low   ].source := low;
   ontbl[undef, low   ].drain  := low;
   ontbl[undef, strh  ].source := indet;
   ontbl[undef, strh  ].drain  := indet;
   ontbl[undef, strl  ].source := indet;
   ontbl[undef, strl  ].drain  := indet;
   ontbl[undef, whigh ].source := whigh;
   ontbl[undef, whigh ].drain  := whigh;
   ontbl[undef, wlow  ].source := wlow;
   ontbl[undef, wlow  ].drain  := wlow;
   ontbl[undef, vcc   ].source := high;
   ontbl[undef, vcc   ].drain  := vcc;
   ontbl[undef, vss   ].source := low;
   ontbl[undef, vss   ].drain  := vss;

   ontbl[indet, undef ].source := indet;
   ontbl[indet, undef ].drain  := indet;
   ontbl[indet, indet ].source := indet;
   ontbl[indet, indet ].drain  := indet;
   ontbl[indet, indrh ].source := indrh;
   ontbl[indet, indrh ].drain  := indrh;
   ontbl[indet, indrl ].source := indrl;
   ontbl[indet, indrl ].drain  := indrl;
   ontbl[indet, widh  ].source := widh;
   ontbl[indet, widh  ].drain  := widh;
   ontbl[indet, widl  ].source := widl;
   ontbl[indet, widl  ].drain  := widl;
   ontbl[indet, cont  ].source := cont;
   ontbl[indet, cont  ].drain  := cont;
   ontbl[indet, wcont ].source := wcont;
   ontbl[indet, wcont ].drain  := wcont;
   ontbl[indet, high  ].source := high;
   ontbl[indet, high  ].drain  := high;
   ontbl[indet, low   ].source := low;
   ontbl[indet, low   ].drain  := low;
   ontbl[indet, strh  ].source := indet;
   ontbl[indet, strh  ].drain  := indet;
   ontbl[indet, strl  ].source := indet;
   ontbl[indet, strl  ].drain  := indet;
   ontbl[indet, whigh ].source := whigh;
   ontbl[indet, whigh ].drain  := whigh;
   ontbl[indet, wlow  ].source := wlow;
   ontbl[indet, wlow  ].drain  := wlow;
   ontbl[indet, vcc   ].source := high;
   ontbl[indet, vcc   ].drain  := vcc;
   ontbl[indet, vss   ].source := low;
   ontbl[indet, vss   ].drain  := vss;

   ontbl[indrh, undef ].source := indrh;
   ontbl[indrh, undef ].drain  := indrh;
   ontbl[indrh, indet ].source := indrh;
   ontbl[indrh, indet ].drain  := indrh;
   ontbl[indrh, indrh ].source := indrh;
   ontbl[indrh, indrh ].drain  := indrh;
   ontbl[indrh, indrl ].source := cont;
   ontbl[indrh, indrl ].drain  := cont;
   ontbl[indrh, widh  ].source := indrh;
   ontbl[indrh, widh  ].drain  := indrh;
   ontbl[indrh, widl  ].source := indrh;
   ontbl[indrh, widl  ].drain  := indrh;
   ontbl[indrh, cont  ].source := cont;
   ontbl[indrh, cont  ].drain  := cont;
   ontbl[indrh, wcont ].source := indrh;
   ontbl[indrh, wcont ].drain  := indrh;
   ontbl[indrh, high  ].source := high;
   ontbl[indrh, high  ].drain  := high;
   ontbl[indrh, low   ].source := cont;
   ontbl[indrh, low   ].drain  := cont;
   ontbl[indrh, strh  ].source := indrh;
   ontbl[indrh, strh  ].drain  := indrh;
   ontbl[indrh, strl  ].source := indrh;
   ontbl[indrh, strl  ].drain  := indrh;
   ontbl[indrh, whigh ].source := indrh;
   ontbl[indrh, whigh ].drain  := indrh;
   ontbl[indrh, wlow  ].source := indrh;
   ontbl[indrh, wlow  ].drain  := indrh;
   ontbl[indrh, vcc   ].source := high;
   ontbl[indrh, vcc   ].drain  := vcc;
   ontbl[indrh, vss   ].source := cont;
   ontbl[indrh, vss   ].drain  := vss;

   ontbl[indrl, undef ].source := indrl;
   ontbl[indrl, undef ].drain  := indrl;
   ontbl[indrl, indet ].source := indrl;
   ontbl[indrl, indet ].drain  := indrl;
   ontbl[indrl, indrh ].source := cont;
   ontbl[indrl, indrh ].drain  := cont;
   ontbl[indrl, indrl ].source := indrl;
   ontbl[indrl, indrl ].drain  := indrl;
   ontbl[indrl, widh  ].source := indrl;
   ontbl[indrl, widh  ].drain  := indrl;
   ontbl[indrl, widl  ].source := indrl;
   ontbl[indrl, widl  ].drain  := indrl;
   ontbl[indrl, cont  ].source := cont;
   ontbl[indrl, cont  ].drain  := cont;
   ontbl[indrl, wcont ].source := indrl;
   ontbl[indrl, wcont ].drain  := indrl;
   ontbl[indrl, high  ].source := cont;
   ontbl[indrl, high  ].drain  := cont;
   ontbl[indrl, low   ].source := low;
   ontbl[indrl, low   ].drain  := low;
   ontbl[indrl, strh  ].source := indrl;
   ontbl[indrl, strh  ].drain  := indrl;
   ontbl[indrl, strl  ].source := indrl;
   ontbl[indrl, strl  ].drain  := indrl;
   ontbl[indrl, whigh ].source := indrl;
   ontbl[indrl, whigh ].drain  := indrl;
   ontbl[indrl, wlow  ].source := indrl;
   ontbl[indrl, wlow  ].drain  := indrl;
   ontbl[indrl, vcc   ].source := cont;
   ontbl[indrl, vcc   ].drain  := vcc;
   ontbl[indrl, vss   ].source := low;
   ontbl[indrl, vss   ].drain  := vss;

   ontbl[widh,  undef ].source := widh;
   ontbl[widh,  undef ].drain  := widh;
   ontbl[widh,  indet ].source := widh;
   ontbl[widh,  indet ].drain  := widh;
   ontbl[widh,  indrh ].source := indrh;
   ontbl[widh,  indrh ].drain  := indrh;
   ontbl[widh,  indrl ].source := indrl;
   ontbl[widh,  indrl ].drain  := indrl;
   ontbl[widh,  widh  ].source := widh;
   ontbl[widh,  widh  ].drain  := widh;
   ontbl[widh,  widl  ].source := wcont;
   ontbl[widh,  widl  ].drain  := wcont;
   ontbl[widh,  cont  ].source := cont;
   ontbl[widh,  cont  ].drain  := cont;
   ontbl[widh,  wcont ].source := wcont;
   ontbl[widh,  wcont ].drain  := wcont;
   ontbl[widh,  high  ].source := high;
   ontbl[widh,  high  ].drain  := high;
   ontbl[widh,  low   ].source := low;
   ontbl[widh,  low   ].drain  := low;
   ontbl[widh,  strh  ].source := widh;
   ontbl[widh,  strh  ].drain  := widh;
   ontbl[widh,  strl  ].source := widh;
   ontbl[widh,  strl  ].drain  := widh;
   ontbl[widh,  whigh ].source := whigh;
   ontbl[widh,  whigh ].drain  := whigh;
   ontbl[widh,  wlow  ].source := wcont;
   ontbl[widh,  wlow  ].drain  := wcont;
   ontbl[widh,  vcc   ].source := high;
   ontbl[widh,  vcc   ].drain  := vcc;
   ontbl[widh,  vss   ].source := low;
   ontbl[widh,  vss   ].drain  := vss;

   ontbl[widl,  undef ].source := widl;
   ontbl[widl,  undef ].drain  := widl;
   ontbl[widl,  indet ].source := widl;
   ontbl[widl,  indet ].drain  := widl;
   ontbl[widl,  indrh ].source := indrh;
   ontbl[widl,  indrh ].drain  := indrh;
   ontbl[widl,  indrl ].source := indrl;
   ontbl[widl,  indrl ].drain  := indrl;
   ontbl[widl,  widh  ].source := wcont;
   ontbl[widl,  widh  ].drain  := wcont;
   ontbl[widl,  widl  ].source := widl;
   ontbl[widl,  widl  ].drain  := widl;
   ontbl[widl,  cont  ].source := cont;
   ontbl[widl,  cont  ].drain  := cont;
   ontbl[widl,  wcont ].source := wcont;
   ontbl[widl,  wcont ].drain  := wcont;
   ontbl[widl,  high  ].source := high;
   ontbl[widl,  high  ].drain  := high;
   ontbl[widl,  low   ].source := low;
   ontbl[widl,  low   ].drain  := low;
   ontbl[widl,  strh  ].source := widl;
   ontbl[widl,  strh  ].drain  := widl;
   ontbl[widl,  strl  ].source := widl;
   ontbl[widl,  strl  ].drain  := widl;
   ontbl[widl,  whigh ].source := wcont;
   ontbl[widl,  whigh ].drain  := wcont;
   ontbl[widl,  wlow  ].source := wlow;
   ontbl[widl,  wlow  ].drain  := wlow;
   ontbl[widl,  vcc   ].source := high;
   ontbl[widl,  vcc   ].drain  := vcc;
   ontbl[widl,  vss   ].source := low;
   ontbl[widl,  vss   ].drain  := vss;

   ontbl[cont,  undef ].source := cont;
   ontbl[cont,  undef ].drain  := cont;
   ontbl[cont,  indet ].source := cont;
   ontbl[cont,  indet ].drain  := cont;
   ontbl[cont,  indrh ].source := cont;
   ontbl[cont,  indrh ].drain  := cont;
   ontbl[cont,  indrl ].source := cont;
   ontbl[cont,  indrl ].drain  := cont;
   ontbl[cont,  widh  ].source := cont;
   ontbl[cont,  widh  ].drain  := cont;
   ontbl[cont,  widl  ].source := cont;
   ontbl[cont,  widl  ].drain  := cont;
   ontbl[cont,  cont  ].source := cont;
   ontbl[cont,  cont  ].drain  := cont;
   ontbl[cont,  wcont ].source := cont;
   ontbl[cont,  wcont ].drain  := cont;
   ontbl[cont,  high  ].source := cont;
   ontbl[cont,  high  ].drain  := cont;
   ontbl[cont,  low   ].source := cont;
   ontbl[cont,  low   ].drain  := cont;
   ontbl[cont,  strh  ].source := cont;
   ontbl[cont,  strh  ].drain  := cont;
   ontbl[cont,  strl  ].source := cont;
   ontbl[cont,  strl  ].drain  := cont;
   ontbl[cont,  whigh ].source := cont;
   ontbl[cont,  whigh ].drain  := cont;
   ontbl[cont,  wlow  ].source := cont;
   ontbl[cont,  wlow  ].drain  := cont;
   ontbl[cont,  vcc   ].source := cont;
   ontbl[cont,  vcc   ].drain  := vcc;
   ontbl[cont,  vss   ].source := cont;
   ontbl[cont,  vss   ].drain  := vss;

   ontbl[wcont, undef ].source := wcont;
   ontbl[wcont, undef ].drain  := wcont;
   ontbl[wcont, indet ].source := wcont;
   ontbl[wcont, indet ].drain  := wcont;
   ontbl[wcont, indrh ].source := indrh;
   ontbl[wcont, indrh ].drain  := indrh;
   ontbl[wcont, indrl ].source := indrl;
   ontbl[wcont, indrl ].drain  := indrl;
   ontbl[wcont, widh  ].source := wcont;
   ontbl[wcont, widh  ].drain  := wcont;
   ontbl[wcont, widl  ].source := wcont;
   ontbl[wcont, widl  ].drain  := wcont;
   ontbl[wcont, cont  ].source := cont;
   ontbl[wcont, cont  ].drain  := cont;
   ontbl[wcont, wcont ].source := wcont;
   ontbl[wcont, wcont ].drain  := wcont;
   ontbl[wcont, high  ].source := high;
   ontbl[wcont, high  ].drain  := high;
   ontbl[wcont, low   ].source := low;
   ontbl[wcont, low   ].drain  := low;
   ontbl[wcont, strh  ].source := wcont;
   ontbl[wcont, strh  ].drain  := wcont;
   ontbl[wcont, strl  ].source := wcont;
   ontbl[wcont, strl  ].drain  := wcont;
   ontbl[wcont, whigh ].source := wcont;
   ontbl[wcont, whigh ].drain  := wcont;
   ontbl[wcont, wlow  ].source := wcont;
   ontbl[wcont, wlow  ].drain  := wcont;
   ontbl[wcont, vcc   ].source := high;
   ontbl[wcont, vcc   ].drain  := vcc;
   ontbl[wcont, vss   ].source := low;
   ontbl[wcont, vss   ].drain  := vss;

   ontbl[high,  undef ].source := high;
   ontbl[high,  undef ].drain  := high;
   ontbl[high,  indet ].source := high;
   ontbl[high,  indet ].drain  := high;
   ontbl[high,  indrh ].source := high;
   ontbl[high,  indrh ].drain  := high;
   ontbl[high,  indrl ].source := cont;
   ontbl[high,  indrl ].drain  := cont;
   ontbl[high,  widh  ].source := high;
   ontbl[high,  widh  ].drain  := high;
   ontbl[high,  widl  ].source := high;
   ontbl[high,  widl  ].drain  := high;
   ontbl[high,  cont  ].source := cont;
   ontbl[high,  cont  ].drain  := cont;
   ontbl[high,  wcont ].source := high;
   ontbl[high,  wcont ].drain  := high;
   ontbl[high,  high  ].source := high;
   ontbl[high,  high  ].drain  := high;
   ontbl[high,  low   ].source := cont;
   ontbl[high,  low   ].drain  := cont;
   ontbl[high,  strh  ].source := high;
   ontbl[high,  strh  ].drain  := high;
   ontbl[high,  strl  ].source := high;
   ontbl[high,  strl  ].drain  := high;
   ontbl[high,  whigh ].source := high;
   ontbl[high,  whigh ].drain  := high;
   ontbl[high,  wlow  ].source := high;
   ontbl[high,  wlow  ].drain  := high;
   ontbl[high,  vcc   ].source := high;
   ontbl[high,  vcc   ].drain  := vcc;
   ontbl[high,  vss   ].source := cont;
   ontbl[high,  vss   ].drain  := vss;

   ontbl[low,   undef ].source := low;
   ontbl[low,   undef ].drain  := low;
   ontbl[low,   indet ].source := low;
   ontbl[low,   indet ].drain  := low;
   ontbl[low,   indrh ].source := cont;
   ontbl[low,   indrh ].drain  := cont;
   ontbl[low,   indrl ].source := low;
   ontbl[low,   indrl ].drain  := low;
   ontbl[low,   widh  ].source := low;
   ontbl[low,   widh  ].drain  := low;
   ontbl[low,   widl  ].source := low;
   ontbl[low,   widl  ].drain  := low;
   ontbl[low,   cont  ].source := cont;
   ontbl[low,   cont  ].drain  := cont;
   ontbl[low,   wcont ].source := low;
   ontbl[low,   wcont ].drain  := low;
   ontbl[low,   high  ].source := cont;
   ontbl[low,   high  ].drain  := cont;
   ontbl[low,   low   ].source := low;
   ontbl[low,   low   ].drain  := low;
   ontbl[low,   strh  ].source := low;
   ontbl[low,   strh  ].drain  := low;
   ontbl[low,   strl  ].source := low;
   ontbl[low,   strl  ].drain  := low;
   ontbl[low,   whigh ].source := low;
   ontbl[low,   whigh ].drain  := low;
   ontbl[low,   wlow  ].source := low;
   ontbl[low,   wlow  ].drain  := low;
   ontbl[low,   vcc   ].source := cont;
   ontbl[low,   vcc   ].drain  := vcc;
   ontbl[low,   vss   ].source := low;
   ontbl[low,   vss   ].drain  := vss;

   ontbl[strh,  undef ].source := indet;
   ontbl[strh,  undef ].drain  := indet;
   ontbl[strh,  indet ].source := indet;
   ontbl[strh,  indet ].drain  := indet;
   ontbl[strh,  indrh ].source := indrh;
   ontbl[strh,  indrh ].drain  := indrh;
   ontbl[strh,  indrl ].source := indrl;
   ontbl[strh,  indrl ].drain  := indrl;
   ontbl[strh,  widh  ].source := widh;
   ontbl[strh,  widh  ].drain  := widh;
   ontbl[strh,  widl  ].source := widl;
   ontbl[strh,  widl  ].drain  := widl;
   ontbl[strh,  cont  ].source := cont;
   ontbl[strh,  cont  ].drain  := cont;
   ontbl[strh,  wcont ].source := wcont;
   ontbl[strh,  wcont ].drain  := wcont;
   ontbl[strh,  high  ].source := high;
   ontbl[strh,  high  ].drain  := high;
   ontbl[strh,  low   ].source := low;
   ontbl[strh,  low   ].drain  := low;
   ontbl[strh,  strh  ].source := strh;
   ontbl[strh,  strh  ].drain  := strh;
   ontbl[strh,  strl  ].source := indet;
   ontbl[strh,  strl  ].drain  := indet;
   ontbl[strh,  whigh ].source := whigh;
   ontbl[strh,  whigh ].drain  := whigh;
   ontbl[strh,  wlow  ].source := wlow;
   ontbl[strh,  wlow  ].drain  := wlow;
   ontbl[strh,  vcc   ].source := high;
   ontbl[strh,  vcc   ].drain  := vcc;
   ontbl[strh,  vss   ].source := low;
   ontbl[strh,  vss   ].drain  := vss;

   ontbl[strl,  undef ].source := indet;
   ontbl[strl,  undef ].drain  := indet;
   ontbl[strl,  indet ].source := indet;
   ontbl[strl,  indet ].drain  := indet;
   ontbl[strl,  indrh ].source := indrh;
   ontbl[strl,  indrh ].drain  := indrh;
   ontbl[strl,  indrl ].source := indrl;
   ontbl[strl,  indrl ].drain  := indrl;
   ontbl[strl,  widh  ].source := widh;
   ontbl[strl,  widh  ].drain  := widh;
   ontbl[strl,  widl  ].source := widl;
   ontbl[strl,  widl  ].drain  := widl;
   ontbl[strl,  cont  ].source := cont;
   ontbl[strl,  cont  ].drain  := cont;
   ontbl[strl,  wcont ].source := wcont;
   ontbl[strl,  wcont ].drain  := wcont;
   ontbl[strl,  high  ].source := high;
   ontbl[strl,  high  ].drain  := high;
   ontbl[strl,  low   ].source := low;
   ontbl[strl,  low   ].drain  := low;
   ontbl[strl,  strh  ].source := indet;
   ontbl[strl,  strh  ].drain  := indet;
   ontbl[strl,  strl  ].source := strl;
   ontbl[strl,  strl  ].drain  := strl;
   ontbl[strl,  whigh ].source := whigh;
   ontbl[strl,  whigh ].drain  := whigh;
   ontbl[strl,  wlow  ].source := wlow;
   ontbl[strl,  wlow  ].drain  := wlow;
   ontbl[strl,  vcc   ].source := high;
   ontbl[strl,  vcc   ].drain  := vcc;
   ontbl[strl,  vss   ].source := low;
   ontbl[strl,  vss   ].drain  := vss;

   ontbl[whigh, undef ].source := whigh;
   ontbl[whigh, undef ].drain  := whigh;
   ontbl[whigh, indet ].source := whigh;
   ontbl[whigh, indet ].drain  := whigh;
   ontbl[whigh, indrh ].source := indrh;
   ontbl[whigh, indrh ].drain  := indrh;
   ontbl[whigh, indrl ].source := indrl;
   ontbl[whigh, indrl ].drain  := indrl;
   ontbl[whigh, widh  ].source := whigh;
   ontbl[whigh, widh  ].drain  := whigh;
   ontbl[whigh, widl  ].source := wcont;
   ontbl[whigh, widl  ].drain  := wcont;
   ontbl[whigh, cont  ].source := cont;
   ontbl[whigh, cont  ].drain  := cont;
   ontbl[whigh, wcont ].source := wcont;
   ontbl[whigh, wcont ].drain  := wcont;
   ontbl[whigh, high  ].source := high;
   ontbl[whigh, high  ].drain  := high;
   ontbl[whigh, low   ].source := low;
   ontbl[whigh, low   ].drain  := low;
   ontbl[whigh, strh  ].source := whigh;
   ontbl[whigh, strh  ].drain  := whigh;
   ontbl[whigh, strl  ].source := whigh;
   ontbl[whigh, strl  ].drain  := whigh;
   ontbl[whigh, whigh ].source := whigh;
   ontbl[whigh, whigh ].drain  := whigh;
   ontbl[whigh, wlow  ].source := wcont;
   ontbl[whigh, wlow  ].drain  := wcont;
   ontbl[whigh, vcc   ].source := high;
   ontbl[whigh, vcc   ].drain  := vcc;
   ontbl[whigh, vss   ].source := low;
   ontbl[whigh, vss   ].drain  := vss;

   ontbl[wlow,  undef ].source := wlow;
   ontbl[wlow,  undef ].drain  := wlow;
   ontbl[wlow,  indet ].source := wlow;
   ontbl[wlow,  indet ].drain  := wlow;
   ontbl[wlow,  indrh ].source := indrh;
   ontbl[wlow,  indrh ].drain  := indrh;
   ontbl[wlow,  indrl ].source := indrl;
   ontbl[wlow,  indrl ].drain  := indrl;
   ontbl[wlow,  widh  ].source := wcont;
   ontbl[wlow,  widh  ].drain  := wcont;
   ontbl[wlow,  widl  ].source := wlow;
   ontbl[wlow,  widl  ].drain  := wlow;
   ontbl[wlow,  cont  ].source := cont;
   ontbl[wlow,  cont  ].drain  := cont;
   ontbl[wlow,  wcont ].source := wcont;
   ontbl[wlow,  wcont ].drain  := wcont;
   ontbl[wlow,  high  ].source := high;
   ontbl[wlow,  high  ].drain  := high;
   ontbl[wlow,  low   ].source := low;
   ontbl[wlow,  low   ].drain  := low;
   ontbl[wlow,  strh  ].source := wlow;
   ontbl[wlow,  strh  ].drain  := wlow;
   ontbl[wlow,  strl  ].source := wlow;
   ontbl[wlow,  strl  ].drain  := wlow;
   ontbl[wlow,  whigh ].source := wcont;
   ontbl[wlow,  whigh ].drain  := wcont;
   ontbl[wlow,  wlow  ].source := wlow;
   ontbl[wlow,  wlow  ].drain  := wlow;
   ontbl[wlow,  vcc   ].source := high;
   ontbl[wlow,  vcc   ].drain  := vcc;
   ontbl[wlow,  vss   ].source := low;
   ontbl[wlow,  vss   ].drain  := vss;

   ontbl[vcc,   undef ].source := vcc;
   ontbl[vcc,   undef ].drain  := high;
   ontbl[vcc,   indet ].source := vcc;
   ontbl[vcc,   indet ].drain  := high;
   ontbl[vcc,   indrh ].source := vcc;
   ontbl[vcc,   indrh ].drain  := high;
   ontbl[vcc,   indrl ].source := vcc;
   ontbl[vcc,   indrl ].drain  := cont;
   ontbl[vcc,   widh  ].source := vcc;
   ontbl[vcc,   widh  ].drain  := high;
   ontbl[vcc,   widl  ].source := vcc;
   ontbl[vcc,   widl  ].drain  := high;
   ontbl[vcc,   cont  ].source := vcc;
   ontbl[vcc,   cont  ].drain  := cont;
   ontbl[vcc,   wcont ].source := vcc;
   ontbl[vcc,   wcont ].drain  := high;
   ontbl[vcc,   high  ].source := vcc;
   ontbl[vcc,   high  ].drain  := high;
   ontbl[vcc,   low   ].source := vcc;
   ontbl[vcc,   low   ].drain  := cont;
   ontbl[vcc,   strh  ].source := vcc;
   ontbl[vcc,   strh  ].drain  := high;
   ontbl[vcc,   strl  ].source := vcc;
   ontbl[vcc,   strl  ].drain  := high;
   ontbl[vcc,   whigh ].source := vcc;
   ontbl[vcc,   whigh ].drain  := high;
   ontbl[vcc,   wlow  ].source := vcc;
   ontbl[vcc,   wlow  ].drain  := high;
   ontbl[vcc,   vcc   ].source := vcc;
   ontbl[vcc,   vcc   ].drain  := vcc;
   ontbl[vcc,   vss   ].source := vcc;
   ontbl[vcc,   vss   ].drain  := vss;

   ontbl[vss,   undef ].source := vss;
   ontbl[vss,   undef ].drain  := low;
   ontbl[vss,   indet ].source := vss;
   ontbl[vss,   indet ].drain  := low;
   ontbl[vss,   indrh ].source := vss;
   ontbl[vss,   indrh ].drain  := cont;
   ontbl[vss,   indrl ].source := vss;
   ontbl[vss,   indrl ].drain  := low;
   ontbl[vss,   widh  ].source := vss;
   ontbl[vss,   widh  ].drain  := low;
   ontbl[vss,   widl  ].source := vss;
   ontbl[vss,   widl  ].drain  := low;
   ontbl[vss,   cont  ].source := vss;
   ontbl[vss,   cont  ].drain  := cont;
   ontbl[vss,   wcont ].source := vss;
   ontbl[vss,   wcont ].drain  := low;
   ontbl[vss,   high  ].source := vss;
   ontbl[vss,   high  ].drain  := cont;
   ontbl[vss,   low   ].source := vss;
   ontbl[vss,   low   ].drain  := low;
   ontbl[vss,   strh  ].source := vss;
   ontbl[vss,   strh  ].drain  := low;
   ontbl[vss,   strl  ].source := vss;
   ontbl[vss,   strl  ].drain  := low;
   ontbl[vss,   whigh ].source := vss;
   ontbl[vss,   whigh ].drain  := low;
   ontbl[vss,   wlow  ].source := vss;
   ontbl[vss,   wlow  ].drain  := low;
   ontbl[vss,   vcc   ].source := vss;
   ontbl[vss,   vcc   ].drain  := vcc;
   ontbl[vss,   vss   ].source := vss;
   ontbl[vss,   vss   ].drain  := vss

end;

{**************************************************************

Initalize "indeterminate" strong table

This table contains the evaluation rules for "indeterminate"
strong transistors. This is a table of possibilities:
the rule is to assume the worst case.

**************************************************************}

procedure initind;

begin

   indtbl[undef, undef ].source := undef;
   indtbl[undef, undef ].drain  := undef;
   indtbl[undef, indet ].source := indet;
   indtbl[undef, indet ].drain  := indet;
   indtbl[undef, indrh ].source := indrh;
   indtbl[undef, indrh ].drain  := indrh;
   indtbl[undef, indrl ].source := indrl;
   indtbl[undef, indrl ].drain  := indrl;
   indtbl[undef, widh  ].source := widh;
   indtbl[undef, widh  ].drain  := widh;
   indtbl[undef, widl  ].source := widl;
   indtbl[undef, widl  ].drain  := widl;
   indtbl[undef, cont  ].source := cont;
   indtbl[undef, cont  ].drain  := cont;
   indtbl[undef, wcont ].source := wcont;
   indtbl[undef, wcont ].drain  := wcont;
   indtbl[undef, high  ].source := indrh;
   indtbl[undef, high  ].drain  := high;
   indtbl[undef, low   ].source := indrl;
   indtbl[undef, low   ].drain  := low;
   indtbl[undef, strh  ].source := indet;
   indtbl[undef, strh  ].drain  := indet;
   indtbl[undef, strl  ].source := indet;
   indtbl[undef, strl  ].drain  := indet;
   indtbl[undef, whigh ].source := widh;
   indtbl[undef, whigh ].drain  := whigh;
   indtbl[undef, wlow  ].source := widl;
   indtbl[undef, wlow  ].drain  := wlow;
   indtbl[undef, vcc   ].source := indrh;
   indtbl[undef, vcc   ].drain  := vcc;
   indtbl[undef, vss   ].source := indrl;
   indtbl[undef, vss   ].drain  := vss;

   indtbl[indet, undef ].source := indet;
   indtbl[indet, undef ].drain  := indet;
   indtbl[indet, indet ].source := indet;
   indtbl[indet, indet ].drain  := indet;
   indtbl[indet, indrh ].source := indrh;
   indtbl[indet, indrh ].drain  := indrh;
   indtbl[indet, indrl ].source := indrl;
   indtbl[indet, indrl ].drain  := indrl;
   indtbl[indet, widh  ].source := widh;
   indtbl[indet, widh  ].drain  := widh;
   indtbl[indet, widl  ].source := widl;
   indtbl[indet, widl  ].drain  := widl;
   indtbl[indet, cont  ].source := cont;
   indtbl[indet, cont  ].drain  := cont;
   indtbl[indet, wcont ].source := wcont;
   indtbl[indet, wcont ].drain  := wcont;
   indtbl[indet, high  ].source := indrh;
   indtbl[indet, high  ].drain  := high;
   indtbl[indet, low   ].source := indrl;
   indtbl[indet, low   ].drain  := low;
   indtbl[indet, strh  ].source := indet;
   indtbl[indet, strh  ].drain  := indet;
   indtbl[indet, strl  ].source := indet;
   indtbl[indet, strl  ].drain  := indet;
   indtbl[indet, whigh ].source := widh;
   indtbl[indet, whigh ].drain  := whigh;
   indtbl[indet, wlow  ].source := widl;
   indtbl[indet, wlow  ].drain  := wlow;
   indtbl[indet, vcc   ].source := indrh;
   indtbl[indet, vcc   ].drain  := vcc;
   indtbl[indet, vss   ].source := indrl;
   indtbl[indet, vss   ].drain  := vss;

   indtbl[indrh, undef ].source := indrh;
   indtbl[indrh, undef ].drain  := indrh;
   indtbl[indrh, indet ].source := indrh;
   indtbl[indrh, indet ].drain  := indrh;
   indtbl[indrh, indrh ].source := indrh;
   indtbl[indrh, indrh ].drain  := indrh;
   indtbl[indrh, indrl ].source := cont;
   indtbl[indrh, indrl ].drain  := cont;
   indtbl[indrh, widh  ].source := indrh;
   indtbl[indrh, widh  ].drain  := indrh;
   indtbl[indrh, widl  ].source := indrh;
   indtbl[indrh, widl  ].drain  := indrh;
   indtbl[indrh, cont  ].source := cont;
   indtbl[indrh, cont  ].drain  := cont;
   indtbl[indrh, wcont ].source := indrh;
   indtbl[indrh, wcont ].drain  := indrh;
   indtbl[indrh, high  ].source := indrh;
   indtbl[indrh, high  ].drain  := high;
   indtbl[indrh, low   ].source := cont;
   indtbl[indrh, low   ].drain  := cont;
   indtbl[indrh, strh  ].source := indrh;
   indtbl[indrh, strh  ].drain  := indrh;
   indtbl[indrh, strl  ].source := indrh;
   indtbl[indrh, strl  ].drain  := indrh;
   indtbl[indrh, whigh ].source := indrh;
   indtbl[indrh, whigh ].drain  := indrh;
   indtbl[indrh, wlow  ].source := indrh;
   indtbl[indrh, wlow  ].drain  := indrh;
   indtbl[indrh, vcc   ].source := indrh;
   indtbl[indrh, vcc   ].drain  := vcc;
   indtbl[indrh, vss   ].source := cont;
   indtbl[indrh, vss   ].drain  := vss;

   indtbl[indrl, undef ].source := indrl;
   indtbl[indrl, undef ].drain  := indrl;
   indtbl[indrl, indet ].source := indrl;
   indtbl[indrl, indet ].drain  := indrl;
   indtbl[indrl, indrh ].source := cont;
   indtbl[indrl, indrh ].drain  := cont;
   indtbl[indrl, indrl ].source := indrl;
   indtbl[indrl, indrl ].drain  := indrl;
   indtbl[indrl, widh  ].source := indrl;
   indtbl[indrl, widh  ].drain  := indrl;
   indtbl[indrl, widl  ].source := indrl;
   indtbl[indrl, widl  ].drain  := indrl;
   indtbl[indrl, cont  ].source := cont;
   indtbl[indrl, cont  ].drain  := cont;
   indtbl[indrl, wcont ].source := indrl;
   indtbl[indrl, wcont ].drain  := indrl;
   indtbl[indrl, high  ].source := cont;
   indtbl[indrl, high  ].drain  := cont;
   indtbl[indrl, low   ].source := indrl;
   indtbl[indrl, low   ].drain  := low;
   indtbl[indrl, strh  ].source := indrl;
   indtbl[indrl, strh  ].drain  := indrl;
   indtbl[indrl, strl  ].source := indrl;
   indtbl[indrl, strl  ].drain  := indrl;
   indtbl[indrl, whigh ].source := indrl;
   indtbl[indrl, whigh ].drain  := indrl;
   indtbl[indrl, wlow  ].source := indrl;
   indtbl[indrl, wlow  ].drain  := indrl;
   indtbl[indrl, vcc   ].source := cont;
   indtbl[indrl, vcc   ].drain  := vcc;
   indtbl[indrl, vss   ].source := indrl;
   indtbl[indrl, vss   ].drain  := vss;

   indtbl[widh,  undef ].source := widh;
   indtbl[widh,  undef ].drain  := widh;
   indtbl[widh,  indet ].source := widh;
   indtbl[widh,  indet ].drain  := widh;
   indtbl[widh,  indrh ].source := indrh;
   indtbl[widh,  indrh ].drain  := indrh;
   indtbl[widh,  indrl ].source := indrl;
   indtbl[widh,  indrl ].drain  := indrl;
   indtbl[widh,  widh  ].source := widh;
   indtbl[widh,  widh  ].drain  := widh;
   indtbl[widh,  widl  ].source := wcont;
   indtbl[widh,  widl  ].drain  := wcont;
   indtbl[widh,  cont  ].source := cont;
   indtbl[widh,  cont  ].drain  := cont;
   indtbl[widh,  wcont ].source := wcont;
   indtbl[widh,  wcont ].drain  := wcont;
   indtbl[widh,  high  ].source := indrh;
   indtbl[widh,  high  ].drain  := high;
   indtbl[widh,  low   ].source := indrl;
   indtbl[widh,  low   ].drain  := low;
   indtbl[widh,  strh  ].source := widh;
   indtbl[widh,  strh  ].drain  := widh;
   indtbl[widh,  strl  ].source := widh;
   indtbl[widh,  strl  ].drain  := widh;
   indtbl[widh,  whigh ].source := whigh;
   indtbl[widh,  whigh ].drain  := whigh;
   indtbl[widh,  wlow  ].source := wcont;
   indtbl[widh,  wlow  ].drain  := wcont;
   indtbl[widh,  vcc   ].source := indrh;
   indtbl[widh,  vcc   ].drain  := vcc;
   indtbl[widh,  vss   ].source := indrl;
   indtbl[widh,  vss   ].drain  := vss;

   indtbl[widl,  undef ].source := widl;
   indtbl[widl,  undef ].drain  := widl;
   indtbl[widl,  indet ].source := widl;
   indtbl[widl,  indet ].drain  := widl;
   indtbl[widl,  indrh ].source := indrh;
   indtbl[widl,  indrh ].drain  := indrh;
   indtbl[widl,  indrl ].source := indrl;
   indtbl[widl,  indrl ].drain  := indrl;
   indtbl[widl,  widh  ].source := wcont;
   indtbl[widl,  widh  ].drain  := wcont;
   indtbl[widl,  widl  ].source := widl;
   indtbl[widl,  widl  ].drain  := widl;
   indtbl[widl,  cont  ].source := cont;
   indtbl[widl,  cont  ].drain  := cont;
   indtbl[widl,  wcont ].source := wcont;
   indtbl[widl,  wcont ].drain  := wcont;
   indtbl[widl,  high  ].source := indrh;
   indtbl[widl,  high  ].drain  := high;
   indtbl[widl,  low   ].source := indrl;
   indtbl[widl,  low   ].drain  := low;
   indtbl[widl,  strh  ].source := widl;
   indtbl[widl,  strh  ].drain  := widl;
   indtbl[widl,  strl  ].source := widl;
   indtbl[widl,  strl  ].drain  := widl;
   indtbl[widl,  whigh ].source := wcont;
   indtbl[widl,  whigh ].drain  := wcont;
   indtbl[widl,  wlow  ].source := wlow;
   indtbl[widl,  wlow  ].drain  := wlow;
   indtbl[widl,  vcc   ].source := indrh;
   indtbl[widl,  vcc   ].drain  := vcc;
   indtbl[widl,  vss   ].source := indrl;
   indtbl[widl,  vss   ].drain  := vss;

   indtbl[cont,  undef ].source := cont;
   indtbl[cont,  undef ].drain  := cont;
   indtbl[cont,  indet ].source := cont;
   indtbl[cont,  indet ].drain  := cont;
   indtbl[cont,  indrh ].source := cont;
   indtbl[cont,  indrh ].drain  := cont;
   indtbl[cont,  indrl ].source := cont;
   indtbl[cont,  indrl ].drain  := cont;
   indtbl[cont,  widh  ].source := cont;
   indtbl[cont,  widh  ].drain  := cont;
   indtbl[cont,  widl  ].source := cont;
   indtbl[cont,  widl  ].drain  := cont;
   indtbl[cont,  cont  ].source := cont;
   indtbl[cont,  cont  ].drain  := cont;
   indtbl[cont,  wcont ].source := cont;
   indtbl[cont,  wcont ].drain  := cont;
   indtbl[cont,  high  ].source := cont;
   indtbl[cont,  high  ].drain  := cont;
   indtbl[cont,  low   ].source := cont;
   indtbl[cont,  low   ].drain  := cont;
   indtbl[cont,  strh  ].source := cont;
   indtbl[cont,  strh  ].drain  := cont;
   indtbl[cont,  strl  ].source := cont;
   indtbl[cont,  strl  ].drain  := cont;
   indtbl[cont,  whigh ].source := cont;
   indtbl[cont,  whigh ].drain  := cont;
   indtbl[cont,  wlow  ].source := cont;
   indtbl[cont,  wlow  ].drain  := cont;
   indtbl[cont,  vcc   ].source := cont;
   indtbl[cont,  vcc   ].drain  := vcc;
   indtbl[cont,  vss   ].source := cont;
   indtbl[cont,  vss   ].drain  := vss;

   indtbl[wcont, undef ].source := wcont;
   indtbl[wcont, undef ].drain  := wcont;
   indtbl[wcont, indet ].source := wcont;
   indtbl[wcont, indet ].drain  := wcont;
   indtbl[wcont, indrh ].source := indrh;
   indtbl[wcont, indrh ].drain  := indrh;
   indtbl[wcont, indrl ].source := indrl;
   indtbl[wcont, indrl ].drain  := indrl;
   indtbl[wcont, widh  ].source := wcont;
   indtbl[wcont, widh  ].drain  := wcont;
   indtbl[wcont, widl  ].source := wcont;
   indtbl[wcont, widl  ].drain  := wcont;
   indtbl[wcont, cont  ].source := cont;
   indtbl[wcont, cont  ].drain  := cont;
   indtbl[wcont, wcont ].source := wcont;
   indtbl[wcont, wcont ].drain  := wcont;
   indtbl[wcont, high  ].source := indrh;
   indtbl[wcont, high  ].drain  := high;
   indtbl[wcont, low   ].source := indrl;
   indtbl[wcont, low   ].drain  := low;
   indtbl[wcont, strh  ].source := wcont;
   indtbl[wcont, strh  ].drain  := wcont;
   indtbl[wcont, strl  ].source := wcont;
   indtbl[wcont, strl  ].drain  := wcont;
   indtbl[wcont, whigh ].source := wcont;
   indtbl[wcont, whigh ].drain  := wcont;
   indtbl[wcont, wlow  ].source := wcont;
   indtbl[wcont, wlow  ].drain  := wcont;
   indtbl[wcont, vcc   ].source := indrh;
   indtbl[wcont, vcc   ].drain  := vcc;
   indtbl[wcont, vss   ].source := indrl;
   indtbl[wcont, vss   ].drain  := vss;

   indtbl[high,  undef ].source := high;
   indtbl[high,  undef ].drain  := indrh;
   indtbl[high,  indet ].source := high;
   indtbl[high,  indet ].drain  := indrh;
   indtbl[high,  indrh ].source := high;
   indtbl[high,  indrh ].drain  := indrh;
   indtbl[high,  indrl ].source := cont;
   indtbl[high,  indrl ].drain  := cont;
   indtbl[high,  widh  ].source := high;
   indtbl[high,  widh  ].drain  := indrh;
   indtbl[high,  widl  ].source := high;
   indtbl[high,  widl  ].drain  := indrh;
   indtbl[high,  cont  ].source := cont;
   indtbl[high,  cont  ].drain  := cont;
   indtbl[high,  wcont ].source := high;
   indtbl[high,  wcont ].drain  := indrh;
   indtbl[high,  high  ].source := high;
   indtbl[high,  high  ].drain  := high;
   indtbl[high,  low   ].source := cont;
   indtbl[high,  low   ].drain  := cont;
   indtbl[high,  strh  ].source := high;
   indtbl[high,  strh  ].drain  := indrh;
   indtbl[high,  strl  ].source := high;
   indtbl[high,  strl  ].drain  := indrh;
   indtbl[high,  whigh ].source := high;
   indtbl[high,  whigh ].drain  := indrh;
   indtbl[high,  wlow  ].source := high;
   indtbl[high,  wlow  ].drain  := indrh;
   indtbl[high,  vcc   ].source := high;
   indtbl[high,  vcc   ].drain  := vcc;
   indtbl[high,  vss   ].source := cont;
   indtbl[high,  vss   ].drain  := vss;

   indtbl[low,   undef ].source := low;
   indtbl[low,   undef ].drain  := indrl;
   indtbl[low,   indet ].source := low;
   indtbl[low,   indet ].drain  := indrl;
   indtbl[low,   indrh ].source := cont;
   indtbl[low,   indrh ].drain  := cont;
   indtbl[low,   indrl ].source := low;
   indtbl[low,   indrl ].drain  := indrl;
   indtbl[low,   widh  ].source := low;
   indtbl[low,   widh  ].drain  := indrl;
   indtbl[low,   widl  ].source := low;
   indtbl[low,   widl  ].drain  := indrl;
   indtbl[low,   cont  ].source := cont;
   indtbl[low,   cont  ].drain  := cont;
   indtbl[low,   wcont ].source := low;
   indtbl[low,   wcont ].drain  := indrl;
   indtbl[low,   high  ].source := cont;
   indtbl[low,   high  ].drain  := cont;
   indtbl[low,   low   ].source := low;
   indtbl[low,   low   ].drain  := low;
   indtbl[low,   strh  ].source := low;
   indtbl[low,   strh  ].drain  := indrl;
   indtbl[low,   strl  ].source := low;
   indtbl[low,   strl  ].drain  := indrl;
   indtbl[low,   whigh ].source := low;
   indtbl[low,   whigh ].drain  := indrl;
   indtbl[low,   wlow  ].source := low;
   indtbl[low,   wlow  ].drain  := indrl;
   indtbl[low,   vcc   ].source := cont;
   indtbl[low,   vcc   ].drain  := vcc;
   indtbl[low,   vss   ].source := low;
   indtbl[low,   vss   ].drain  := vss;

   indtbl[strh,  undef ].source := indet;
   indtbl[strh,  undef ].drain  := indet;
   indtbl[strh,  indet ].source := indet;
   indtbl[strh,  indet ].drain  := indet;
   indtbl[strh,  indrh ].source := indrh;
   indtbl[strh,  indrh ].drain  := indrh;
   indtbl[strh,  indrl ].source := indrl;
   indtbl[strh,  indrl ].drain  := indrl;
   indtbl[strh,  widh  ].source := widh;
   indtbl[strh,  widh  ].drain  := widh;
   indtbl[strh,  widl  ].source := widl;
   indtbl[strh,  widl  ].drain  := widl;
   indtbl[strh,  cont  ].source := cont;
   indtbl[strh,  cont  ].drain  := cont;
   indtbl[strh,  wcont ].source := wcont;
   indtbl[strh,  wcont ].drain  := wcont;
   indtbl[strh,  high  ].source := indrh;
   indtbl[strh,  high  ].drain  := high;
   indtbl[strh,  low   ].source := indrl;
   indtbl[strh,  low   ].drain  := low;
   indtbl[strh,  strh  ].source := strh;
   indtbl[strh,  strh  ].drain  := strh;
   indtbl[strh,  strl  ].source := indet;
   indtbl[strh,  strl  ].drain  := indet;
   indtbl[strh,  whigh ].source := widh;
   indtbl[strh,  whigh ].drain  := whigh;
   indtbl[strh,  wlow  ].source := widl;
   indtbl[strh,  wlow  ].drain  := wlow;
   indtbl[strh,  vcc   ].source := indrh;
   indtbl[strh,  vcc   ].drain  := vcc;
   indtbl[strh,  vss   ].source := indrl;
   indtbl[strh,  vss   ].drain  := vss;

   indtbl[strl,  undef ].source := indet;
   indtbl[strl,  undef ].drain  := indet;
   indtbl[strl,  indet ].source := indet;
   indtbl[strl,  indet ].drain  := indet;
   indtbl[strl,  indrh ].source := indrh;
   indtbl[strl,  indrh ].drain  := indrh;
   indtbl[strl,  indrl ].source := indrl;
   indtbl[strl,  indrl ].drain  := indrl;
   indtbl[strl,  widh  ].source := widh;
   indtbl[strl,  widh  ].drain  := widh;
   indtbl[strl,  widl  ].source := widl;
   indtbl[strl,  widl  ].drain  := widl;
   indtbl[strl,  cont  ].source := cont;
   indtbl[strl,  cont  ].drain  := cont;
   indtbl[strl,  wcont ].source := wcont;
   indtbl[strl,  wcont ].drain  := wcont;
   indtbl[strl,  high  ].source := indrh;
   indtbl[strl,  high  ].drain  := high;
   indtbl[strl,  low   ].source := indrl;
   indtbl[strl,  low   ].drain  := low;
   indtbl[strl,  strh  ].source := indet;
   indtbl[strl,  strh  ].drain  := indet;
   indtbl[strl,  strl  ].source := strl;
   indtbl[strl,  strl  ].drain  := strl;
   indtbl[strl,  whigh ].source := widh;
   indtbl[strl,  whigh ].drain  := whigh;
   indtbl[strl,  wlow  ].source := widl;
   indtbl[strl,  wlow  ].drain  := wlow;
   indtbl[strl,  vcc   ].source := indrh;
   indtbl[strl,  vcc   ].drain  := vcc;
   indtbl[strl,  vss   ].source := indrl;
   indtbl[strl,  vss   ].drain  := vss;

   indtbl[whigh, undef ].source := whigh;
   indtbl[whigh, undef ].drain  := widh;
   indtbl[whigh, indet ].source := whigh;
   indtbl[whigh, indet ].drain  := widh;
   indtbl[whigh, indrh ].source := indrh;
   indtbl[whigh, indrh ].drain  := indrh;
   indtbl[whigh, indrl ].source := indrl;
   indtbl[whigh, indrl ].drain  := indrl;
   indtbl[whigh, widh  ].source := whigh;
   indtbl[whigh, widh  ].drain  := widh;
   indtbl[whigh, widl  ].source := wcont;
   indtbl[whigh, widl  ].drain  := wcont;
   indtbl[whigh, cont  ].source := cont;
   indtbl[whigh, cont  ].drain  := cont;
   indtbl[whigh, wcont ].source := wcont;
   indtbl[whigh, wcont ].drain  := wcont;
   indtbl[whigh, high  ].source := indrh;
   indtbl[whigh, high  ].drain  := high;
   indtbl[whigh, low   ].source := indrl;
   indtbl[whigh, low   ].drain  := low;
   indtbl[whigh, strh  ].source := whigh;
   indtbl[whigh, strh  ].drain  := widh;
   indtbl[whigh, strl  ].source := whigh;
   indtbl[whigh, strl  ].drain  := widh;
   indtbl[whigh, whigh ].source := whigh;
   indtbl[whigh, whigh ].drain  := whigh;
   indtbl[whigh, wlow  ].source := wcont;
   indtbl[whigh, wlow  ].drain  := wcont;
   indtbl[whigh, vcc   ].source := indrh;
   indtbl[whigh, vcc   ].drain  := vcc;
   indtbl[whigh, vss   ].source := indrl;
   indtbl[whigh, vss   ].drain  := vss;

   indtbl[wlow,  undef ].source := wlow;
   indtbl[wlow,  undef ].drain  := widl;
   indtbl[wlow,  indet ].source := wlow;
   indtbl[wlow,  indet ].drain  := widl;
   indtbl[wlow,  indrh ].source := indrh;
   indtbl[wlow,  indrh ].drain  := indrh;
   indtbl[wlow,  indrl ].source := indrl;
   indtbl[wlow,  indrl ].drain  := indrl;
   indtbl[wlow,  widh  ].source := wcont;
   indtbl[wlow,  widh  ].drain  := wcont;
   indtbl[wlow,  widl  ].source := wlow;
   indtbl[wlow,  widl  ].drain  := widl;
   indtbl[wlow,  cont  ].source := cont;
   indtbl[wlow,  cont  ].drain  := cont;
   indtbl[wlow,  wcont ].source := wcont;
   indtbl[wlow,  wcont ].drain  := wcont;
   indtbl[wlow,  high  ].source := indrh;
   indtbl[wlow,  high  ].drain  := high;
   indtbl[wlow,  low   ].source := indrl;
   indtbl[wlow,  low   ].drain  := low;
   indtbl[wlow,  strh  ].source := wlow;
   indtbl[wlow,  strh  ].drain  := widl;
   indtbl[wlow,  strl  ].source := wlow;
   indtbl[wlow,  strl  ].drain  := widl;
   indtbl[wlow,  whigh ].source := wcont;
   indtbl[wlow,  whigh ].drain  := wcont;
   indtbl[wlow,  wlow  ].source := wlow;
   indtbl[wlow,  wlow  ].drain  := wlow;
   indtbl[wlow,  vcc   ].source := indrh;
   indtbl[wlow,  vcc   ].drain  := vcc;
   indtbl[wlow,  vss   ].source := indrl;
   indtbl[wlow,  vss   ].drain  := vss;

   indtbl[vcc,   undef ].source := vcc;
   indtbl[vcc,   undef ].drain  := indrh;
   indtbl[vcc,   indet ].source := vcc;
   indtbl[vcc,   indet ].drain  := indrh;
   indtbl[vcc,   indrh ].source := vcc;
   indtbl[vcc,   indrh ].drain  := indrh;
   indtbl[vcc,   indrl ].source := vcc;
   indtbl[vcc,   indrl ].drain  := cont;
   indtbl[vcc,   widh  ].source := vcc;
   indtbl[vcc,   widh  ].drain  := indrh;
   indtbl[vcc,   widl  ].source := vcc;
   indtbl[vcc,   widl  ].drain  := indrh;
   indtbl[vcc,   cont  ].source := vcc;
   indtbl[vcc,   cont  ].drain  := cont;
   indtbl[vcc,   wcont ].source := vcc;
   indtbl[vcc,   wcont ].drain  := indrh;
   indtbl[vcc,   high  ].source := vcc;
   indtbl[vcc,   high  ].drain  := high;
   indtbl[vcc,   low   ].source := vcc;
   indtbl[vcc,   low   ].drain  := cont;
   indtbl[vcc,   strh  ].source := vcc;
   indtbl[vcc,   strh  ].drain  := indrh;
   indtbl[vcc,   strl  ].source := vcc;
   indtbl[vcc,   strl  ].drain  := indrh;
   indtbl[vcc,   whigh ].source := vcc;
   indtbl[vcc,   whigh ].drain  := indrh;
   indtbl[vcc,   wlow  ].source := vcc;
   indtbl[vcc,   wlow  ].drain  := indrh;
   indtbl[vcc,   vcc   ].source := vcc;
   indtbl[vcc,   vcc   ].drain  := vcc;
   indtbl[vcc,   vss   ].source := vcc;
   indtbl[vcc,   vss   ].drain  := vss;

   indtbl[vss,   undef ].source := vss;
   indtbl[vss,   undef ].drain  := indrl;
   indtbl[vss,   indet ].source := vss;
   indtbl[vss,   indet ].drain  := indrl;
   indtbl[vss,   indrh ].source := vss;
   indtbl[vss,   indrh ].drain  := cont;
   indtbl[vss,   indrl ].source := vss;
   indtbl[vss,   indrl ].drain  := indrl;
   indtbl[vss,   widh  ].source := vss;
   indtbl[vss,   widh  ].drain  := indrl;
   indtbl[vss,   widl  ].source := vss;
   indtbl[vss,   widl  ].drain  := indrl;
   indtbl[vss,   cont  ].source := vss;
   indtbl[vss,   cont  ].drain  := cont;
   indtbl[vss,   wcont ].source := vss;
   indtbl[vss,   wcont ].drain  := indrl;
   indtbl[vss,   high  ].source := vss;
   indtbl[vss,   high  ].drain  := cont;
   indtbl[vss,   low   ].source := vss;
   indtbl[vss,   low   ].drain  := low;
   indtbl[vss,   strh  ].source := vss;
   indtbl[vss,   strh  ].drain  := indrl;
   indtbl[vss,   strl  ].source := vss;
   indtbl[vss,   strl  ].drain  := indrl;
   indtbl[vss,   whigh ].source := vss;
   indtbl[vss,   whigh ].drain  := indrl;
   indtbl[vss,   wlow  ].source := vss;
   indtbl[vss,   wlow  ].drain  := indrl;
   indtbl[vss,   vcc   ].source := vss;
   indtbl[vss,   vcc   ].drain  := vcc;
   indtbl[vss,   vss   ].source := vss;
   indtbl[vss,   vss   ].drain  := vss

end;

{**************************************************************

Initalize "on" weak table

This table contains the evaluation rules for "on" weak
transistors.

**************************************************************}

procedure initwon;

begin

   wontbl[undef, undef ].source := undef;
   wontbl[undef, undef ].drain  := undef;
   wontbl[undef, indet ].source := indet;
   wontbl[undef, indet ].drain  := indet;
   wontbl[undef, indrh ].source := widh;
   wontbl[undef, indrh ].drain  := indrh;
   wontbl[undef, indrl ].source := widl;
   wontbl[undef, indrl ].drain  := indrl;
   wontbl[undef, widh  ].source := widh;
   wontbl[undef, widh  ].drain  := widh;
   wontbl[undef, widl  ].source := widl;
   wontbl[undef, widl  ].drain  := widl;
   wontbl[undef, cont  ].source := wcont;
   wontbl[undef, cont  ].drain  := cont;
   wontbl[undef, wcont ].source := wcont;
   wontbl[undef, wcont ].drain  := wcont;
   wontbl[undef, high  ].source := whigh;
   wontbl[undef, high  ].drain  := high;
   wontbl[undef, low   ].source := wlow;
   wontbl[undef, low   ].drain  := low;
   wontbl[undef, strh  ].source := indet;
   wontbl[undef, strh  ].drain  := indet;
   wontbl[undef, strl  ].source := indet;
   wontbl[undef, strl  ].drain  := indet;
   wontbl[undef, whigh ].source := whigh;
   wontbl[undef, whigh ].drain  := whigh;
   wontbl[undef, wlow  ].source := wlow;
   wontbl[undef, wlow  ].drain  := wlow;
   wontbl[undef, vcc   ].source := whigh;
   wontbl[undef, vcc   ].drain  := vcc;
   wontbl[undef, vss   ].source := wlow;
   wontbl[undef, vss   ].drain  := vss;

   wontbl[indet, undef ].source := indet;
   wontbl[indet, undef ].drain  := indet;
   wontbl[indet, indet ].source := indet;
   wontbl[indet, indet ].drain  := indet;
   wontbl[indet, indrh ].source := widh;
   wontbl[indet, indrh ].drain  := indrh;
   wontbl[indet, indrl ].source := widl;
   wontbl[indet, indrl ].drain  := indrl;
   wontbl[indet, widh  ].source := widh;
   wontbl[indet, widh  ].drain  := widh;
   wontbl[indet, widl  ].source := widl;
   wontbl[indet, widl  ].drain  := widl;
   wontbl[indet, cont  ].source := wcont;
   wontbl[indet, cont  ].drain  := cont;
   wontbl[indet, wcont ].source := wcont;
   wontbl[indet, wcont ].drain  := wcont;
   wontbl[indet, high  ].source := whigh;
   wontbl[indet, high  ].drain  := high;
   wontbl[indet, low   ].source := wlow;
   wontbl[indet, low   ].drain  := low;
   wontbl[indet, strh  ].source := indet;
   wontbl[indet, strh  ].drain  := indet;
   wontbl[indet, strl  ].source := indet;
   wontbl[indet, strl  ].drain  := indet;
   wontbl[indet, whigh ].source := whigh;
   wontbl[indet, whigh ].drain  := whigh;
   wontbl[indet, wlow  ].source := wlow;
   wontbl[indet, wlow  ].drain  := wlow;
   wontbl[indet, vcc   ].source := whigh;
   wontbl[indet, vcc   ].drain  := vcc;
   wontbl[indet, vss   ].source := wlow;
   wontbl[indet, vss   ].drain  := vss;

   wontbl[indrh, undef ].source := indrh;
   wontbl[indrh, undef ].drain  := widh;
   wontbl[indrh, indet ].source := indrh;
   wontbl[indrh, indet ].drain  := widh;
   wontbl[indrh, indrh ].source := indrh;
   wontbl[indrh, indrh ].drain  := indrh;
   wontbl[indrh, indrl ].source := indrh;
   wontbl[indrh, indrl ].drain  := indrl;
   wontbl[indrh, widh  ].source := indrh;
   wontbl[indrh, widh  ].drain  := widh;
   wontbl[indrh, widl  ].source := indrh;
   wontbl[indrh, widl  ].drain  := wcont;
   wontbl[indrh, cont  ].source := indrh;
   wontbl[indrh, cont  ].drain  := cont;
   wontbl[indrh, wcont ].source := indrh;
   wontbl[indrh, wcont ].drain  := wcont;
   wontbl[indrh, high  ].source := indrh;
   wontbl[indrh, high  ].drain  := high;
   wontbl[indrh, low   ].source := indrh;
   wontbl[indrh, low   ].drain  := low;
   wontbl[indrh, strh  ].source := indrh;
   wontbl[indrh, strh  ].drain  := indrh;
   wontbl[indrh, strl  ].source := indrh;
   wontbl[indrh, strl  ].drain  := indrh;
   wontbl[indrh, whigh ].source := indrh;
   wontbl[indrh, whigh ].drain  := whigh;
   wontbl[indrh, wlow  ].source := indrh;
   wontbl[indrh, wlow  ].drain  := wcont;
   wontbl[indrh, vcc   ].source := indrh;
   wontbl[indrh, vcc   ].drain  := vcc;
   wontbl[indrh, vss   ].source := indrh;
   wontbl[indrh, vss   ].drain  := vss;

   wontbl[indrl, undef ].source := indrl;
   wontbl[indrl, undef ].drain  := widl;
   wontbl[indrl, indet ].source := indrl;
   wontbl[indrl, indet ].drain  := widl;
   wontbl[indrl, indrh ].source := indrl;
   wontbl[indrl, indrh ].drain  := indrh;
   wontbl[indrl, indrl ].source := indrl;
   wontbl[indrl, indrl ].drain  := indrl;
   wontbl[indrl, widh  ].source := indrl;
   wontbl[indrl, widh  ].drain  := wcont;
   wontbl[indrl, widl  ].source := indrl;
   wontbl[indrl, widl  ].drain  := widl;
   wontbl[indrl, cont  ].source := indrl;
   wontbl[indrl, cont  ].drain  := cont;
   wontbl[indrl, wcont ].source := indrl;
   wontbl[indrl, wcont ].drain  := wcont;
   wontbl[indrl, high  ].source := indrl;
   wontbl[indrl, high  ].drain  := high;
   wontbl[indrl, low   ].source := indrl;
   wontbl[indrl, low   ].drain  := low;
   wontbl[indrl, strh  ].source := indrl;
   wontbl[indrl, strh  ].drain  := indrl;
   wontbl[indrl, strl  ].source := indrl;
   wontbl[indrl, strl  ].drain  := indrl;
   wontbl[indrl, whigh ].source := indrl;
   wontbl[indrl, whigh ].drain  := wcont;
   wontbl[indrl, wlow  ].source := indrl;
   wontbl[indrl, wlow  ].drain  := wlow;
   wontbl[indrl, vcc   ].source := indrl;
   wontbl[indrl, vcc   ].drain  := vcc;
   wontbl[indrl, vss   ].source := indrl;
   wontbl[indrl, vss   ].drain  := vss;

   wontbl[widh,  undef ].source := widh;
   wontbl[widh,  undef ].drain  := widh;
   wontbl[widh,  indet ].source := widh;
   wontbl[widh,  indet ].drain  := widh;
   wontbl[widh,  indrh ].source := widh;
   wontbl[widh,  indrh ].drain  := indrh;
   wontbl[widh,  indrl ].source := wcont;
   wontbl[widh,  indrl ].drain  := indrl;
   wontbl[widh,  widh  ].source := widh;
   wontbl[widh,  widh  ].drain  := widh;
   wontbl[widh,  widl  ].source := wcont;
   wontbl[widh,  widl  ].drain  := wcont;
   wontbl[widh,  cont  ].source := wcont;
   wontbl[widh,  cont  ].drain  := cont;
   wontbl[widh,  wcont ].source := wcont;
   wontbl[widh,  wcont ].drain  := wcont;
   wontbl[widh,  high  ].source := whigh;
   wontbl[widh,  high  ].drain  := high;
   wontbl[widh,  low   ].source := wcont;
   wontbl[widh,  low   ].drain  := low;
   wontbl[widh,  strh  ].source := widh;
   wontbl[widh,  strh  ].drain  := widh;
   wontbl[widh,  strl  ].source := widh;
   wontbl[widh,  strl  ].drain  := widh;
   wontbl[widh,  whigh ].source := whigh;
   wontbl[widh,  whigh ].drain  := whigh;
   wontbl[widh,  wlow  ].source := wcont;
   wontbl[widh,  wlow  ].drain  := wcont;
   wontbl[widh,  vcc   ].source := whigh;
   wontbl[widh,  vcc   ].drain  := vcc;
   wontbl[widh,  vss   ].source := wcont;
   wontbl[widh,  vss   ].drain  := vss;

   wontbl[widl,  undef ].source := widl;
   wontbl[widl,  undef ].drain  := widl;
   wontbl[widl,  indet ].source := widl;
   wontbl[widl,  indet ].drain  := widl;
   wontbl[widl,  indrh ].source := wcont;
   wontbl[widl,  indrh ].drain  := indrh;
   wontbl[widl,  indrl ].source := widl;
   wontbl[widl,  indrl ].drain  := indrl;
   wontbl[widl,  widh  ].source := wcont;
   wontbl[widl,  widh  ].drain  := wcont;
   wontbl[widl,  widl  ].source := widl;
   wontbl[widl,  widl  ].drain  := widl;
   wontbl[widl,  cont  ].source := wcont;
   wontbl[widl,  cont  ].drain  := cont;
   wontbl[widl,  wcont ].source := wcont;
   wontbl[widl,  wcont ].drain  := wcont;
   wontbl[widl,  high  ].source := wcont;
   wontbl[widl,  high  ].drain  := high;
   wontbl[widl,  low   ].source := wlow;
   wontbl[widl,  low   ].drain  := low;
   wontbl[widl,  strh  ].source := widl;
   wontbl[widl,  strh  ].drain  := widl;
   wontbl[widl,  strl  ].source := widl;
   wontbl[widl,  strl  ].drain  := widl;
   wontbl[widl,  whigh ].source := wcont;
   wontbl[widl,  whigh ].drain  := wcont;
   wontbl[widl,  wlow  ].source := wlow;
   wontbl[widl,  wlow  ].drain  := wlow;
   wontbl[widl,  vcc   ].source := wcont;
   wontbl[widl,  vcc   ].drain  := vcc;
   wontbl[widl,  vss   ].source := wlow;
   wontbl[widl,  vss   ].drain  := vss;

   wontbl[cont,  undef ].source := cont;
   wontbl[cont,  undef ].drain  := wcont;
   wontbl[cont,  indet ].source := cont;
   wontbl[cont,  indet ].drain  := wcont;
   wontbl[cont,  indrh ].source := cont;
   wontbl[cont,  indrh ].drain  := indrh;
   wontbl[cont,  indrl ].source := cont;
   wontbl[cont,  indrl ].drain  := indrl;
   wontbl[cont,  widh  ].source := cont;
   wontbl[cont,  widh  ].drain  := wcont;
   wontbl[cont,  widl  ].source := cont;
   wontbl[cont,  widl  ].drain  := wcont;
   wontbl[cont,  cont  ].source := cont;
   wontbl[cont,  cont  ].drain  := cont;
   wontbl[cont,  wcont ].source := cont;
   wontbl[cont,  wcont ].drain  := wcont;
   wontbl[cont,  high  ].source := cont;
   wontbl[cont,  high  ].drain  := high;
   wontbl[cont,  low   ].source := cont;
   wontbl[cont,  low   ].drain  := low;
   wontbl[cont,  strh  ].source := cont;
   wontbl[cont,  strh  ].drain  := wcont;
   wontbl[cont,  strl  ].source := cont;
   wontbl[cont,  strl  ].drain  := wcont;
   wontbl[cont,  whigh ].source := cont;
   wontbl[cont,  whigh ].drain  := wcont;
   wontbl[cont,  wlow  ].source := cont;
   wontbl[cont,  wlow  ].drain  := wcont;
   wontbl[cont,  vcc   ].source := cont;
   wontbl[cont,  vcc   ].drain  := vcc;
   wontbl[cont,  vss   ].source := cont;
   wontbl[cont,  vss   ].drain  := vss;

   wontbl[wcont, undef ].source := wcont;
   wontbl[wcont, undef ].drain  := wcont;
   wontbl[wcont, indet ].source := wcont;
   wontbl[wcont, indet ].drain  := wcont;
   wontbl[wcont, indrh ].source := wcont;
   wontbl[wcont, indrh ].drain  := indrh;
   wontbl[wcont, indrl ].source := wcont;
   wontbl[wcont, indrl ].drain  := indrl;
   wontbl[wcont, widh  ].source := wcont;
   wontbl[wcont, widh  ].drain  := wcont;
   wontbl[wcont, widl  ].source := wcont;
   wontbl[wcont, widl  ].drain  := wcont;
   wontbl[wcont, cont  ].source := wcont;
   wontbl[wcont, cont  ].drain  := cont;
   wontbl[wcont, wcont ].source := wcont;
   wontbl[wcont, wcont ].drain  := wcont;
   wontbl[wcont, high  ].source := wcont;
   wontbl[wcont, high  ].drain  := high;
   wontbl[wcont, low   ].source := wcont;
   wontbl[wcont, low   ].drain  := low;
   wontbl[wcont, strh  ].source := wcont;
   wontbl[wcont, strh  ].drain  := wcont;
   wontbl[wcont, strl  ].source := wcont;
   wontbl[wcont, strl  ].drain  := wcont;
   wontbl[wcont, whigh ].source := wcont;
   wontbl[wcont, whigh ].drain  := wcont;
   wontbl[wcont, wlow  ].source := wcont;
   wontbl[wcont, wlow  ].drain  := wcont;
   wontbl[wcont, vcc   ].source := wcont;
   wontbl[wcont, vcc   ].drain  := vcc;
   wontbl[wcont, vss   ].source := wcont;
   wontbl[wcont, vss   ].drain  := vss;

   wontbl[high,  undef ].source := high;
   wontbl[high,  undef ].drain  := whigh;
   wontbl[high,  indet ].source := high;
   wontbl[high,  indet ].drain  := whigh;
   wontbl[high,  indrh ].source := high;
   wontbl[high,  indrh ].drain  := indrh;
   wontbl[high,  indrl ].source := high;
   wontbl[high,  indrl ].drain  := indrl;
   wontbl[high,  widh  ].source := high;
   wontbl[high,  widh  ].drain  := whigh;
   wontbl[high,  widl  ].source := high;
   wontbl[high,  widl  ].drain  := wcont;
   wontbl[high,  cont  ].source := high;
   wontbl[high,  cont  ].drain  := cont;
   wontbl[high,  wcont ].source := high;
   wontbl[high,  wcont ].drain  := wcont;
   wontbl[high,  high  ].source := high;
   wontbl[high,  high  ].drain  := high;
   wontbl[high,  low   ].source := high;
   wontbl[high,  low   ].drain  := low;
   wontbl[high,  strh  ].source := high;
   wontbl[high,  strh  ].drain  := whigh;
   wontbl[high,  strl  ].source := high;
   wontbl[high,  strl  ].drain  := whigh;
   wontbl[high,  whigh ].source := high;
   wontbl[high,  whigh ].drain  := whigh;
   wontbl[high,  wlow  ].source := high;
   wontbl[high,  wlow  ].drain  := wcont;
   wontbl[high,  vcc   ].source := high;
   wontbl[high,  vcc   ].drain  := vcc;
   wontbl[high,  vss   ].source := high;
   wontbl[high,  vss   ].drain  := vss;

   wontbl[low,   undef ].source := low;
   wontbl[low,   undef ].drain  := wlow;
   wontbl[low,   indet ].source := low;
   wontbl[low,   indet ].drain  := wlow;
   wontbl[low,   indrh ].source := low;
   wontbl[low,   indrh ].drain  := indrh;
   wontbl[low,   indrl ].source := low;
   wontbl[low,   indrl ].drain  := indrl;
   wontbl[low,   widh  ].source := low;
   wontbl[low,   widh  ].drain  := wcont;
   wontbl[low,   widl  ].source := low;
   wontbl[low,   widl  ].drain  := wlow;
   wontbl[low,   cont  ].source := low;
   wontbl[low,   cont  ].drain  := cont;
   wontbl[low,   wcont ].source := low;
   wontbl[low,   wcont ].drain  := wcont;
   wontbl[low,   high  ].source := low;
   wontbl[low,   high  ].drain  := high;
   wontbl[low,   low   ].source := low;
   wontbl[low,   low   ].drain  := low;
   wontbl[low,   strh  ].source := low;
   wontbl[low,   strh  ].drain  := wlow;
   wontbl[low,   strl  ].source := low;
   wontbl[low,   strl  ].drain  := wlow;
   wontbl[low,   whigh ].source := low;
   wontbl[low,   whigh ].drain  := wcont;
   wontbl[low,   wlow  ].source := low;
   wontbl[low,   wlow  ].drain  := wlow;
   wontbl[low,   vcc   ].source := low;
   wontbl[low,   vcc   ].drain  := vcc;
   wontbl[low,   vss   ].source := low;
   wontbl[low,   vss   ].drain  := vss;

   wontbl[strh,  undef ].source := indet;
   wontbl[strh,  undef ].drain  := indet;
   wontbl[strh,  indet ].source := indet;
   wontbl[strh,  indet ].drain  := indet;
   wontbl[strh,  indrh ].source := widh;
   wontbl[strh,  indrh ].drain  := indrh;
   wontbl[strh,  indrl ].source := widl;
   wontbl[strh,  indrl ].drain  := indrl;
   wontbl[strh,  widh  ].source := widh;
   wontbl[strh,  widh  ].drain  := widh;
   wontbl[strh,  widl  ].source := widl;
   wontbl[strh,  widl  ].drain  := widl;
   wontbl[strh,  cont  ].source := wcont;
   wontbl[strh,  cont  ].drain  := cont;
   wontbl[strh,  wcont ].source := wcont;
   wontbl[strh,  wcont ].drain  := wcont;
   wontbl[strh,  high  ].source := whigh;
   wontbl[strh,  high  ].drain  := high;
   wontbl[strh,  low   ].source := wlow;
   wontbl[strh,  low   ].drain  := low;
   wontbl[strh,  strh  ].source := strh;
   wontbl[strh,  strh  ].drain  := strh;
   wontbl[strh,  strl  ].source := indet;
   wontbl[strh,  strl  ].drain  := indet;
   wontbl[strh,  whigh ].source := whigh;
   wontbl[strh,  whigh ].drain  := whigh;
   wontbl[strh,  wlow  ].source := wlow;
   wontbl[strh,  wlow  ].drain  := wlow;
   wontbl[strh,  vcc   ].source := whigh;
   wontbl[strh,  vcc   ].drain  := vcc;
   wontbl[strh,  vss   ].source := wlow;
   wontbl[strh,  vss   ].drain  := vss;

   wontbl[strl,  undef ].source := indet;
   wontbl[strl,  undef ].drain  := indet;
   wontbl[strl,  indet ].source := indet;
   wontbl[strl,  indet ].drain  := indet;
   wontbl[strl,  indrh ].source := widh;
   wontbl[strl,  indrh ].drain  := indrh;
   wontbl[strl,  indrl ].source := widl;
   wontbl[strl,  indrl ].drain  := indrl;
   wontbl[strl,  widh  ].source := widh;
   wontbl[strl,  widh  ].drain  := widh;
   wontbl[strl,  widl  ].source := widl;
   wontbl[strl,  widl  ].drain  := widl;
   wontbl[strl,  cont  ].source := wcont;
   wontbl[strl,  cont  ].drain  := cont;
   wontbl[strl,  wcont ].source := wcont;
   wontbl[strl,  wcont ].drain  := wcont;
   wontbl[strl,  high  ].source := whigh;
   wontbl[strl,  high  ].drain  := high;
   wontbl[strl,  low   ].source := wlow;
   wontbl[strl,  low   ].drain  := low;
   wontbl[strl,  strh  ].source := indet;
   wontbl[strl,  strh  ].drain  := indet;
   wontbl[strl,  strl  ].source := strl;
   wontbl[strl,  strl  ].drain  := strl;
   wontbl[strl,  whigh ].source := whigh;
   wontbl[strl,  whigh ].drain  := whigh;
   wontbl[strl,  wlow  ].source := wlow;
   wontbl[strl,  wlow  ].drain  := wlow;
   wontbl[strl,  vcc   ].source := whigh;
   wontbl[strl,  vcc   ].drain  := vcc;
   wontbl[strl,  vss   ].source := wlow;
   wontbl[strl,  vss   ].drain  := vss;

   wontbl[whigh, undef ].source := whigh;
   wontbl[whigh, undef ].drain  := whigh;
   wontbl[whigh, indet ].source := whigh;
   wontbl[whigh, indet ].drain  := whigh;
   wontbl[whigh, indrh ].source := whigh;
   wontbl[whigh, indrh ].drain  := indrh;
   wontbl[whigh, indrl ].source := wcont;
   wontbl[whigh, indrl ].drain  := indrl;
   wontbl[whigh, widh  ].source := whigh;
   wontbl[whigh, widh  ].drain  := whigh;
   wontbl[whigh, widl  ].source := wcont;
   wontbl[whigh, widl  ].drain  := wcont;
   wontbl[whigh, cont  ].source := wcont;
   wontbl[whigh, cont  ].drain  := cont;
   wontbl[whigh, wcont ].source := wcont;
   wontbl[whigh, wcont ].drain  := wcont;
   wontbl[whigh, high  ].source := whigh;
   wontbl[whigh, high  ].drain  := high;
   wontbl[whigh, low   ].source := wcont;
   wontbl[whigh, low   ].drain  := low;
   wontbl[whigh, strh  ].source := whigh;
   wontbl[whigh, strh  ].drain  := whigh;
   wontbl[whigh, strl  ].source := whigh;
   wontbl[whigh, strl  ].drain  := whigh;
   wontbl[whigh, whigh ].source := whigh;
   wontbl[whigh, whigh ].drain  := whigh;
   wontbl[whigh, wlow  ].source := wcont;
   wontbl[whigh, wlow  ].drain  := wcont;
   wontbl[whigh, vcc   ].source := whigh;
   wontbl[whigh, vcc   ].drain  := vcc;
   wontbl[whigh, vss   ].source := wcont;
   wontbl[whigh, vss   ].drain  := vss;

   wontbl[wlow,  undef ].source := wlow;
   wontbl[wlow,  undef ].drain  := wlow;
   wontbl[wlow,  indet ].source := wlow;
   wontbl[wlow,  indet ].drain  := wlow;
   wontbl[wlow,  indrh ].source := wcont;
   wontbl[wlow,  indrh ].drain  := indrh;
   wontbl[wlow,  indrl ].source := wlow;
   wontbl[wlow,  indrl ].drain  := indrl;
   wontbl[wlow,  widh  ].source := wcont;
   wontbl[wlow,  widh  ].drain  := wcont;
   wontbl[wlow,  widl  ].source := wlow;
   wontbl[wlow,  widl  ].drain  := wlow;
   wontbl[wlow,  cont  ].source := wcont;
   wontbl[wlow,  cont  ].drain  := cont;
   wontbl[wlow,  wcont ].source := wcont;
   wontbl[wlow,  wcont ].drain  := wcont;
   wontbl[wlow,  high  ].source := wcont;
   wontbl[wlow,  high  ].drain  := high;
   wontbl[wlow,  low   ].source := wlow;
   wontbl[wlow,  low   ].drain  := low;
   wontbl[wlow,  strh  ].source := wlow;
   wontbl[wlow,  strh  ].drain  := wlow;
   wontbl[wlow,  strl  ].source := wlow;
   wontbl[wlow,  strl  ].drain  := wlow;
   wontbl[wlow,  whigh ].source := wcont;
   wontbl[wlow,  whigh ].drain  := wcont;
   wontbl[wlow,  wlow  ].source := wlow;
   wontbl[wlow,  wlow  ].drain  := wlow;
   wontbl[wlow,  vcc   ].source := wcont;
   wontbl[wlow,  vcc   ].drain  := vcc;
   wontbl[wlow,  vss   ].source := wlow;
   wontbl[wlow,  vss   ].drain  := vss;

   wontbl[vcc,   undef ].source := vcc;
   wontbl[vcc,   undef ].drain  := whigh;
   wontbl[vcc,   indet ].source := vcc;
   wontbl[vcc,   indet ].drain  := whigh;
   wontbl[vcc,   indrh ].source := vcc;
   wontbl[vcc,   indrh ].drain  := indrh;
   wontbl[vcc,   indrl ].source := vcc;
   wontbl[vcc,   indrl ].drain  := indrl;
   wontbl[vcc,   widh  ].source := vcc;
   wontbl[vcc,   widh  ].drain  := whigh;
   wontbl[vcc,   widl  ].source := vcc;
   wontbl[vcc,   widl  ].drain  := wcont;
   wontbl[vcc,   cont  ].source := vcc;
   wontbl[vcc,   cont  ].drain  := cont;
   wontbl[vcc,   wcont ].source := vcc;
   wontbl[vcc,   wcont ].drain  := wcont;
   wontbl[vcc,   high  ].source := vcc;
   wontbl[vcc,   high  ].drain  := high;
   wontbl[vcc,   low   ].source := vcc;
   wontbl[vcc,   low   ].drain  := low;
   wontbl[vcc,   strh  ].source := vcc;
   wontbl[vcc,   strh  ].drain  := whigh;
   wontbl[vcc,   strl  ].source := vcc;
   wontbl[vcc,   strl  ].drain  := whigh;
   wontbl[vcc,   whigh ].source := vcc;
   wontbl[vcc,   whigh ].drain  := whigh;
   wontbl[vcc,   wlow  ].source := vcc;
   wontbl[vcc,   wlow  ].drain  := wcont;
   wontbl[vcc,   vcc   ].source := vcc;
   wontbl[vcc,   vcc   ].drain  := vcc;
   wontbl[vcc,   vss   ].source := vcc;
   wontbl[vcc,   vss   ].drain  := vss;

   wontbl[vss,   undef ].source := vss;
   wontbl[vss,   undef ].drain  := wlow;
   wontbl[vss,   indet ].source := vss;
   wontbl[vss,   indet ].drain  := wlow;
   wontbl[vss,   indrh ].source := vss;
   wontbl[vss,   indrh ].drain  := indrh;
   wontbl[vss,   indrl ].source := vss;
   wontbl[vss,   indrl ].drain  := indrl;
   wontbl[vss,   widh  ].source := vss;
   wontbl[vss,   widh  ].drain  := wcont;
   wontbl[vss,   widl  ].source := vss;
   wontbl[vss,   widl  ].drain  := wlow;
   wontbl[vss,   cont  ].source := vss;
   wontbl[vss,   cont  ].drain  := cont;
   wontbl[vss,   wcont ].source := vss;
   wontbl[vss,   wcont ].drain  := wcont;
   wontbl[vss,   high  ].source := vss;
   wontbl[vss,   high  ].drain  := high;
   wontbl[vss,   low   ].source := vss;
   wontbl[vss,   low   ].drain  := low;
   wontbl[vss,   strh  ].source := vss;
   wontbl[vss,   strh  ].drain  := wlow;
   wontbl[vss,   strl  ].source := vss;
   wontbl[vss,   strl  ].drain  := wlow;
   wontbl[vss,   whigh ].source := vss;
   wontbl[vss,   whigh ].drain  := wcont;
   wontbl[vss,   wlow  ].source := vss;
   wontbl[vss,   wlow  ].drain  := wlow;
   wontbl[vss,   vcc   ].source := vss;
   wontbl[vss,   vcc   ].drain  := vcc;
   wontbl[vss,   vss   ].source := vss;
   wontbl[vss,   vss   ].drain  := vss

end;

{**************************************************************

Initalize "indeterminate" weak table

This table contains the evaluation rules for "indeterminate" weak
transistors.

**************************************************************}


procedure initwind;

begin

   windtbl[undef, undef ].source := undef;
   windtbl[undef, undef ].drain  := undef;
   windtbl[undef, indet ].source := indet;
   windtbl[undef, indet ].drain  := indet;
   windtbl[undef, indrh ].source := widh;
   windtbl[undef, indrh ].drain  := indrh;
   windtbl[undef, indrl ].source := widl;
   windtbl[undef, indrl ].drain  := indrl;
   windtbl[undef, widh  ].source := widh;
   windtbl[undef, widh  ].drain  := widh;
   windtbl[undef, widl  ].source := widl;
   windtbl[undef, widl  ].drain  := widl;
   windtbl[undef, cont  ].source := wcont;
   windtbl[undef, cont  ].drain  := cont;
   windtbl[undef, wcont ].source := wcont;
   windtbl[undef, wcont ].drain  := wcont;
   windtbl[undef, high  ].source := widh;
   windtbl[undef, high  ].drain  := high;
   windtbl[undef, low   ].source := widl;
   windtbl[undef, low   ].drain  := low;
   windtbl[undef, strh  ].source := indet;
   windtbl[undef, strh  ].drain  := indet;
   windtbl[undef, strl  ].source := indet;
   windtbl[undef, strl  ].drain  := indet;
   windtbl[undef, whigh ].source := widh;
   windtbl[undef, whigh ].drain  := whigh;
   windtbl[undef, wlow  ].source := widl;
   windtbl[undef, wlow  ].drain  := wlow;
   windtbl[undef, vcc   ].source := widh;
   windtbl[undef, vcc   ].drain  := vcc;
   windtbl[undef, vss   ].source := widl;
   windtbl[undef, vss   ].drain  := vss;

   windtbl[indet, undef ].source := indet;
   windtbl[indet, undef ].drain  := indet;
   windtbl[indet, indet ].source := indet;
   windtbl[indet, indet ].drain  := indet;
   windtbl[indet, indrh ].source := widh;
   windtbl[indet, indrh ].drain  := indrh;
   windtbl[indet, indrl ].source := widl;
   windtbl[indet, indrl ].drain  := indrl;
   windtbl[indet, widh  ].source := widh;
   windtbl[indet, widh  ].drain  := widh;
   windtbl[indet, widl  ].source := widl;
   windtbl[indet, widl  ].drain  := widl;
   windtbl[indet, cont  ].source := wcont;
   windtbl[indet, cont  ].drain  := cont;
   windtbl[indet, wcont ].source := wcont;
   windtbl[indet, wcont ].drain  := wcont;
   windtbl[indet, high  ].source := widh;
   windtbl[indet, high  ].drain  := high;
   windtbl[indet, low   ].source := widl;
   windtbl[indet, low   ].drain  := low;
   windtbl[indet, strh  ].source := indet;
   windtbl[indet, strh  ].drain  := indet;
   windtbl[indet, strl  ].source := indet;
   windtbl[indet, strl  ].drain  := indet;
   windtbl[indet, whigh ].source := widh;
   windtbl[indet, whigh ].drain  := whigh;
   windtbl[indet, wlow  ].source := widl;
   windtbl[indet, wlow  ].drain  := wlow;
   windtbl[indet, vcc   ].source := widh;
   windtbl[indet, vcc   ].drain  := vcc;
   windtbl[indet, vss   ].source := widl;
   windtbl[indet, vss   ].drain  := vss;

   windtbl[indrh, undef ].source := indrh;
   windtbl[indrh, undef ].drain  := widh;
   windtbl[indrh, indet ].source := indrh;
   windtbl[indrh, indet ].drain  := widh;
   windtbl[indrh, indrh ].source := indrh;
   windtbl[indrh, indrh ].drain  := indrh;
   windtbl[indrh, indrl ].source := indrh;
   windtbl[indrh, indrl ].drain  := indrl;
   windtbl[indrh, widh  ].source := indrh;
   windtbl[indrh, widh  ].drain  := widh;
   windtbl[indrh, widl  ].source := indrh;
   windtbl[indrh, widl  ].drain  := wcont;
   windtbl[indrh, cont  ].source := indrh;
   windtbl[indrh, cont  ].drain  := cont;
   windtbl[indrh, wcont ].source := indrh;
   windtbl[indrh, wcont ].drain  := wcont;
   windtbl[indrh, high  ].source := indrh;
   windtbl[indrh, high  ].drain  := high;
   windtbl[indrh, low   ].source := indrh;
   windtbl[indrh, low   ].drain  := low;
   windtbl[indrh, strh  ].source := indrh;
   windtbl[indrh, strh  ].drain  := widh;
   windtbl[indrh, strl  ].source := indrh;
   windtbl[indrh, strl  ].drain  := widh;
   windtbl[indrh, whigh ].source := indrh;
   windtbl[indrh, whigh ].drain  := whigh;
   windtbl[indrh, wlow  ].source := indrh;
   windtbl[indrh, wlow  ].drain  := wcont;
   windtbl[indrh, vcc   ].source := indrh;
   windtbl[indrh, vcc   ].drain  := vcc;
   windtbl[indrh, vss   ].source := indrh;
   windtbl[indrh, vss   ].drain  := vss;

   windtbl[indrl, undef ].source := indrl;
   windtbl[indrl, undef ].drain  := widl;
   windtbl[indrl, indet ].source := indrl;
   windtbl[indrl, indet ].drain  := widl;
   windtbl[indrl, indrh ].source := indrl;
   windtbl[indrl, indrh ].drain  := indrh;
   windtbl[indrl, indrl ].source := indrl;
   windtbl[indrl, indrl ].drain  := indrl;
   windtbl[indrl, widh  ].source := indrl;
   windtbl[indrl, widh  ].drain  := wcont;
   windtbl[indrl, widl  ].source := indrl;
   windtbl[indrl, widl  ].drain  := widl;
   windtbl[indrl, cont  ].source := indrl;
   windtbl[indrl, cont  ].drain  := cont;
   windtbl[indrl, wcont ].source := indrl;
   windtbl[indrl, wcont ].drain  := wcont;
   windtbl[indrl, high  ].source := indrl;
   windtbl[indrl, high  ].drain  := high;
   windtbl[indrl, low   ].source := indrl;
   windtbl[indrl, low   ].drain  := low;
   windtbl[indrl, strh  ].source := indrl;
   windtbl[indrl, strh  ].drain  := widl;
   windtbl[indrl, strl  ].source := indrl;
   windtbl[indrl, strl  ].drain  := widl;
   windtbl[indrl, whigh ].source := indrl;
   windtbl[indrl, whigh ].drain  := wcont;
   windtbl[indrl, wlow  ].source := indrl;
   windtbl[indrl, wlow  ].drain  := wlow;
   windtbl[indrl, vcc   ].source := indrl;
   windtbl[indrl, vcc   ].drain  := vcc;
   windtbl[indrl, vss   ].source := indrl;
   windtbl[indrl, vss   ].drain  := vss;

   windtbl[widh,  undef ].source := widh;
   windtbl[widh,  undef ].drain  := widh;
   windtbl[widh,  indet ].source := widh;
   windtbl[widh,  indet ].drain  := widh;
   windtbl[widh,  indrh ].source := widh;
   windtbl[widh,  indrh ].drain  := indrh;
   windtbl[widh,  indrl ].source := wcont;
   windtbl[widh,  indrl ].drain  := indrl;
   windtbl[widh,  widh  ].source := widh;
   windtbl[widh,  widh  ].drain  := widh;
   windtbl[widh,  widl  ].source := wcont;
   windtbl[widh,  widl  ].drain  := wcont;
   windtbl[widh,  cont  ].source := wcont;
   windtbl[widh,  cont  ].drain  := cont;
   windtbl[widh,  wcont ].source := wcont;
   windtbl[widh,  wcont ].drain  := wcont;
   windtbl[widh,  high  ].source := widh;
   windtbl[widh,  high  ].drain  := high;
   windtbl[widh,  low   ].source := wcont;
   windtbl[widh,  low   ].drain  := low;
   windtbl[widh,  strh  ].source := widh;
   windtbl[widh,  strh  ].drain  := widh;
   windtbl[widh,  strl  ].source := widh;
   windtbl[widh,  strl  ].drain  := widh;
   windtbl[widh,  whigh ].source := widh;
   windtbl[widh,  whigh ].drain  := whigh;
   windtbl[widh,  wlow  ].source := wcont;
   windtbl[widh,  wlow  ].drain  := wcont;
   windtbl[widh,  vcc   ].source := widh;
   windtbl[widh,  vcc   ].drain  := vcc;
   windtbl[widh,  vss   ].source := wcont;
   windtbl[widh,  vss   ].drain  := vss;

   windtbl[widl,  undef ].source := widl;
   windtbl[widl,  undef ].drain  := widl;
   windtbl[widl,  indet ].source := widl;
   windtbl[widl,  indet ].drain  := widl;
   windtbl[widl,  indrh ].source := wcont;
   windtbl[widl,  indrh ].drain  := indrh;
   windtbl[widl,  indrl ].source := widl;
   windtbl[widl,  indrl ].drain  := indrl;
   windtbl[widl,  widh  ].source := wcont;
   windtbl[widl,  widh  ].drain  := wcont;
   windtbl[widl,  widl  ].source := widl;
   windtbl[widl,  widl  ].drain  := widl;
   windtbl[widl,  cont  ].source := wcont;
   windtbl[widl,  cont  ].drain  := cont;
   windtbl[widl,  wcont ].source := wcont;
   windtbl[widl,  wcont ].drain  := wcont;
   windtbl[widl,  high  ].source := wcont;
   windtbl[widl,  high  ].drain  := high;
   windtbl[widl,  low   ].source := widl;
   windtbl[widl,  low   ].drain  := low;
   windtbl[widl,  strh  ].source := widl;
   windtbl[widl,  strh  ].drain  := widl;
   windtbl[widl,  strl  ].source := widl;
   windtbl[widl,  strl  ].drain  := widl;
   windtbl[widl,  whigh ].source := wcont;
   windtbl[widl,  whigh ].drain  := wcont;
   windtbl[widl,  wlow  ].source := widl;
   windtbl[widl,  wlow  ].drain  := wlow;
   windtbl[widl,  vcc   ].source := wcont;
   windtbl[widl,  vcc   ].drain  := vcc;
   windtbl[widl,  vss   ].source := widl;
   windtbl[widl,  vss   ].drain  := vss;

   windtbl[cont,  undef ].source := cont;
   windtbl[cont,  undef ].drain  := wcont;
   windtbl[cont,  indet ].source := cont;
   windtbl[cont,  indet ].drain  := wcont;
   windtbl[cont,  indrh ].source := cont;
   windtbl[cont,  indrh ].drain  := indrh;
   windtbl[cont,  indrl ].source := cont;
   windtbl[cont,  indrl ].drain  := indrl;
   windtbl[cont,  widh  ].source := cont;
   windtbl[cont,  widh  ].drain  := wcont;
   windtbl[cont,  widl  ].source := cont;
   windtbl[cont,  widl  ].drain  := wcont;
   windtbl[cont,  cont  ].source := cont;
   windtbl[cont,  cont  ].drain  := cont;
   windtbl[cont,  wcont ].source := cont;
   windtbl[cont,  wcont ].drain  := wcont;
   windtbl[cont,  high  ].source := cont;
   windtbl[cont,  high  ].drain  := high;
   windtbl[cont,  low   ].source := cont;
   windtbl[cont,  low   ].drain  := low;
   windtbl[cont,  strh  ].source := cont;
   windtbl[cont,  strh  ].drain  := wcont;
   windtbl[cont,  strl  ].source := cont;
   windtbl[cont,  strl  ].drain  := wcont;
   windtbl[cont,  whigh ].source := cont;
   windtbl[cont,  whigh ].drain  := wcont;
   windtbl[cont,  wlow  ].source := cont;
   windtbl[cont,  wlow  ].drain  := wcont;
   windtbl[cont,  vcc   ].source := cont;
   windtbl[cont,  vcc   ].drain  := vcc;
   windtbl[cont,  vss   ].source := cont;
   windtbl[cont,  vss   ].drain  := vss;

   windtbl[wcont, undef ].source := wcont;
   windtbl[wcont, undef ].drain  := wcont;
   windtbl[wcont, indet ].source := wcont;
   windtbl[wcont, indet ].drain  := wcont;
   windtbl[wcont, indrh ].source := wcont;
   windtbl[wcont, indrh ].drain  := indrh;
   windtbl[wcont, indrl ].source := wcont;
   windtbl[wcont, indrl ].drain  := indrl;
   windtbl[wcont, widh  ].source := wcont;
   windtbl[wcont, widh  ].drain  := wcont;
   windtbl[wcont, widl  ].source := wcont;
   windtbl[wcont, widl  ].drain  := wcont;
   windtbl[wcont, cont  ].source := wcont;
   windtbl[wcont, cont  ].drain  := cont;
   windtbl[wcont, wcont ].source := wcont;
   windtbl[wcont, wcont ].drain  := wcont;
   windtbl[wcont, high  ].source := wcont;
   windtbl[wcont, high  ].drain  := high;
   windtbl[wcont, low   ].source := wcont;
   windtbl[wcont, low   ].drain  := low;
   windtbl[wcont, strh  ].source := wcont;
   windtbl[wcont, strh  ].drain  := wcont;
   windtbl[wcont, strl  ].source := wcont;
   windtbl[wcont, strl  ].drain  := wcont;
   windtbl[wcont, whigh ].source := wcont;
   windtbl[wcont, whigh ].drain  := wcont;
   windtbl[wcont, wlow  ].source := wcont;
   windtbl[wcont, wlow  ].drain  := wcont;
   windtbl[wcont, vcc   ].source := wcont;
   windtbl[wcont, vcc   ].drain  := vcc;
   windtbl[wcont, vss   ].source := wcont;
   windtbl[wcont, vss   ].drain  := vss;

   windtbl[high,  undef ].source := high;
   windtbl[high,  undef ].drain  := widh;
   windtbl[high,  indet ].source := high;
   windtbl[high,  indet ].drain  := widh;
   windtbl[high,  indrh ].source := high;
   windtbl[high,  indrh ].drain  := indrh;
   windtbl[high,  indrl ].source := high;
   windtbl[high,  indrl ].drain  := indrl;
   windtbl[high,  widh  ].source := high;
   windtbl[high,  widh  ].drain  := widh;
   windtbl[high,  widl  ].source := high;
   windtbl[high,  widl  ].drain  := wcont;
   windtbl[high,  cont  ].source := high;
   windtbl[high,  cont  ].drain  := cont;
   windtbl[high,  wcont ].source := high;
   windtbl[high,  wcont ].drain  := wcont;
   windtbl[high,  high  ].source := high;
   windtbl[high,  high  ].drain  := high;
   windtbl[high,  low   ].source := high;
   windtbl[high,  low   ].drain  := low;
   windtbl[high,  strh  ].source := high;
   windtbl[high,  strh  ].drain  := widh;
   windtbl[high,  strl  ].source := high;
   windtbl[high,  strl  ].drain  := widh;
   windtbl[high,  whigh ].source := high;
   windtbl[high,  whigh ].drain  := whigh;
   windtbl[high,  wlow  ].source := high;
   windtbl[high,  wlow  ].drain  := wcont;
   windtbl[high,  vcc   ].source := high;
   windtbl[high,  vcc   ].drain  := vcc;
   windtbl[high,  vss   ].source := high;
   windtbl[high,  vss   ].drain  := vss;

   windtbl[low,   undef ].source := low;
   windtbl[low,   undef ].drain  := widl;
   windtbl[low,   indet ].source := low;
   windtbl[low,   indet ].drain  := widl;
   windtbl[low,   indrh ].source := low;
   windtbl[low,   indrh ].drain  := indrh;
   windtbl[low,   indrl ].source := low;
   windtbl[low,   indrl ].drain  := indrl;
   windtbl[low,   widh  ].source := low;
   windtbl[low,   widh  ].drain  := wcont;
   windtbl[low,   widl  ].source := low;
   windtbl[low,   widl  ].drain  := widl;
   windtbl[low,   cont  ].source := low;
   windtbl[low,   cont  ].drain  := cont;
   windtbl[low,   wcont ].source := low;
   windtbl[low,   wcont ].drain  := wcont;
   windtbl[low,   high  ].source := low;
   windtbl[low,   high  ].drain  := high;
   windtbl[low,   low   ].source := low;
   windtbl[low,   low   ].drain  := low;
   windtbl[low,   strh  ].source := low;
   windtbl[low,   strh  ].drain  := widl;
   windtbl[low,   strl  ].source := low;
   windtbl[low,   strl  ].drain  := widl;
   windtbl[low,   whigh ].source := low;
   windtbl[low,   whigh ].drain  := wcont;
   windtbl[low,   wlow  ].source := low;
   windtbl[low,   wlow  ].drain  := wlow;
   windtbl[low,   vcc   ].source := low;
   windtbl[low,   vcc   ].drain  := vcc;
   windtbl[low,   vss   ].source := low;
   windtbl[low,   vss   ].drain  := vss;

   windtbl[strh,  undef ].source := indet;
   windtbl[strh,  undef ].drain  := indet;
   windtbl[strh,  indet ].source := indet;
   windtbl[strh,  indet ].drain  := indet;
   windtbl[strh,  indrh ].source := widh;
   windtbl[strh,  indrh ].drain  := indrh;
   windtbl[strh,  indrl ].source := widl;
   windtbl[strh,  indrl ].drain  := indrl;
   windtbl[strh,  widh  ].source := widh;
   windtbl[strh,  widh  ].drain  := widh;
   windtbl[strh,  widl  ].source := widl;
   windtbl[strh,  widl  ].drain  := widl;
   windtbl[strh,  cont  ].source := wcont;
   windtbl[strh,  cont  ].drain  := cont;
   windtbl[strh,  wcont ].source := wcont;
   windtbl[strh,  wcont ].drain  := wcont;
   windtbl[strh,  high  ].source := widh;
   windtbl[strh,  high  ].drain  := high;
   windtbl[strh,  low   ].source := widl;
   windtbl[strh,  low   ].drain  := low;
   windtbl[strh,  strh  ].source := strh;
   windtbl[strh,  strh  ].drain  := strh;
   windtbl[strh,  strl  ].source := indet;
   windtbl[strh,  strl  ].drain  := indet;
   windtbl[strh,  whigh ].source := widh;
   windtbl[strh,  whigh ].drain  := whigh;
   windtbl[strh,  wlow  ].source := widl;
   windtbl[strh,  wlow  ].drain  := wlow;
   windtbl[strh,  vcc   ].source := widh;
   windtbl[strh,  vcc   ].drain  := vcc;
   windtbl[strh,  vss   ].source := widl;
   windtbl[strh,  vss   ].drain  := vss;

   windtbl[strl,  undef ].source := indet;
   windtbl[strl,  undef ].drain  := indet;
   windtbl[strl,  indet ].source := indet;
   windtbl[strl,  indet ].drain  := indet;
   windtbl[strl,  indrh ].source := widh;
   windtbl[strl,  indrh ].drain  := indrh;
   windtbl[strl,  indrl ].source := widl;
   windtbl[strl,  indrl ].drain  := indrl;
   windtbl[strl,  widh  ].source := widh;
   windtbl[strl,  widh  ].drain  := widh;
   windtbl[strl,  widl  ].source := widl;
   windtbl[strl,  widl  ].drain  := widl;
   windtbl[strl,  cont  ].source := wcont;
   windtbl[strl,  cont  ].drain  := cont;
   windtbl[strl,  wcont ].source := wcont;
   windtbl[strl,  wcont ].drain  := wcont;
   windtbl[strl,  high  ].source := widh;
   windtbl[strl,  high  ].drain  := high;
   windtbl[strl,  low   ].source := widl;
   windtbl[strl,  low   ].drain  := low;
   windtbl[strl,  strh  ].source := indet;
   windtbl[strl,  strh  ].drain  := indet;
   windtbl[strl,  strl  ].source := strl;
   windtbl[strl,  strl  ].drain  := strl;
   windtbl[strl,  whigh ].source := widh;
   windtbl[strl,  whigh ].drain  := whigh;
   windtbl[strl,  wlow  ].source := widl;
   windtbl[strl,  wlow  ].drain  := wlow;
   windtbl[strl,  vcc   ].source := widh;
   windtbl[strl,  vcc   ].drain  := vcc;
   windtbl[strl,  vss   ].source := widl;
   windtbl[strl,  vss   ].drain  := vss;

   windtbl[whigh, undef ].source := whigh;
   windtbl[whigh, undef ].drain  := widh;
   windtbl[whigh, indet ].source := whigh;
   windtbl[whigh, indet ].drain  := widh;
   windtbl[whigh, indrh ].source := whigh;
   windtbl[whigh, indrh ].drain  := indrh;
   windtbl[whigh, indrl ].source := wcont;
   windtbl[whigh, indrl ].drain  := indrl;
   windtbl[whigh, widh  ].source := whigh;
   windtbl[whigh, widh  ].drain  := widh;
   windtbl[whigh, widl  ].source := wcont;
   windtbl[whigh, widl  ].drain  := wcont;
   windtbl[whigh, cont  ].source := wcont;
   windtbl[whigh, cont  ].drain  := cont;
   windtbl[whigh, wcont ].source := wcont;
   windtbl[whigh, wcont ].drain  := wcont;
   windtbl[whigh, high  ].source := whigh;
   windtbl[whigh, high  ].drain  := high;
   windtbl[whigh, low   ].source := wcont;
   windtbl[whigh, low   ].drain  := low;
   windtbl[whigh, strh  ].source := whigh;
   windtbl[whigh, strh  ].drain  := widh;
   windtbl[whigh, strl  ].source := whigh;
   windtbl[whigh, strl  ].drain  := widh;
   windtbl[whigh, whigh ].source := whigh;
   windtbl[whigh, whigh ].drain  := whigh;
   windtbl[whigh, wlow  ].source := wcont;
   windtbl[whigh, wlow  ].drain  := wcont;
   windtbl[whigh, vcc   ].source := whigh;
   windtbl[whigh, vcc   ].drain  := vcc;
   windtbl[whigh, vss   ].source := wcont;
   windtbl[whigh, vss   ].drain  := vss;

   windtbl[wlow,  undef ].source := wlow;
   windtbl[wlow,  undef ].drain  := widl;
   windtbl[wlow,  indet ].source := wlow;
   windtbl[wlow,  indet ].drain  := widl;
   windtbl[wlow,  indrh ].source := wcont;
   windtbl[wlow,  indrh ].drain  := indrh;
   windtbl[wlow,  indrl ].source := wlow;
   windtbl[wlow,  indrl ].drain  := indrl;
   windtbl[wlow,  widh  ].source := wcont;
   windtbl[wlow,  widh  ].drain  := wcont;
   windtbl[wlow,  widl  ].source := wlow;
   windtbl[wlow,  widl  ].drain  := widl;
   windtbl[wlow,  cont  ].source := wcont;
   windtbl[wlow,  cont  ].drain  := cont;
   windtbl[wlow,  wcont ].source := wcont;
   windtbl[wlow,  wcont ].drain  := wcont;
   windtbl[wlow,  high  ].source := wcont;
   windtbl[wlow,  high  ].drain  := high;
   windtbl[wlow,  low   ].source := wlow;
   windtbl[wlow,  low   ].drain  := low;
   windtbl[wlow,  strh  ].source := wlow;
   windtbl[wlow,  strh  ].drain  := widl;
   windtbl[wlow,  strl  ].source := wlow;
   windtbl[wlow,  strl  ].drain  := widl;
   windtbl[wlow,  whigh ].source := wcont;
   windtbl[wlow,  whigh ].drain  := wcont;
   windtbl[wlow,  wlow  ].source := wlow;
   windtbl[wlow,  wlow  ].drain  := wlow;
   windtbl[wlow,  vcc   ].source := wcont;
   windtbl[wlow,  vcc   ].drain  := vcc;
   windtbl[wlow,  vss   ].source := wlow;
   windtbl[wlow,  vss   ].drain  := vss;

   windtbl[vcc,   undef ].source := vcc;
   windtbl[vcc,   undef ].drain  := widh;
   windtbl[vcc,   indet ].source := vcc;
   windtbl[vcc,   indet ].drain  := widh;
   windtbl[vcc,   indrh ].source := vcc;
   windtbl[vcc,   indrh ].drain  := indrh;
   windtbl[vcc,   indrl ].source := vcc;
   windtbl[vcc,   indrl ].drain  := indrl;
   windtbl[vcc,   widh  ].source := vcc;
   windtbl[vcc,   widh  ].drain  := widh;
   windtbl[vcc,   widl  ].source := vcc;
   windtbl[vcc,   widl  ].drain  := wcont;
   windtbl[vcc,   cont  ].source := vcc;
   windtbl[vcc,   cont  ].drain  := cont;
   windtbl[vcc,   wcont ].source := vcc;
   windtbl[vcc,   wcont ].drain  := wcont;
   windtbl[vcc,   high  ].source := vcc;
   windtbl[vcc,   high  ].drain  := high;
   windtbl[vcc,   low   ].source := vcc;
   windtbl[vcc,   low   ].drain  := low;
   windtbl[vcc,   strh  ].source := vcc;
   windtbl[vcc,   strh  ].drain  := widh;
   windtbl[vcc,   strl  ].source := vcc;
   windtbl[vcc,   strl  ].drain  := widh;
   windtbl[vcc,   whigh ].source := vcc;
   windtbl[vcc,   whigh ].drain  := whigh;
   windtbl[vcc,   wlow  ].source := vcc;
   windtbl[vcc,   wlow  ].drain  := wcont;
   windtbl[vcc,   vcc   ].source := vcc;
   windtbl[vcc,   vcc   ].drain  := vcc;
   windtbl[vcc,   vss   ].source := vcc;
   windtbl[vcc,   vss   ].drain  := vss;

   windtbl[vss,   undef ].source := vss;
   windtbl[vss,   undef ].drain  := widl;
   windtbl[vss,   indet ].source := vss;
   windtbl[vss,   indet ].drain  := widl;
   windtbl[vss,   indrh ].source := vss;
   windtbl[vss,   indrh ].drain  := indrh;
   windtbl[vss,   indrl ].source := vss;
   windtbl[vss,   indrl ].drain  := indrl;
   windtbl[vss,   widh  ].source := vss;
   windtbl[vss,   widh  ].drain  := wcont;
   windtbl[vss,   widl  ].source := vss;
   windtbl[vss,   widl  ].drain  := widl;
   windtbl[vss,   cont  ].source := vss;
   windtbl[vss,   cont  ].drain  := cont;
   windtbl[vss,   wcont ].source := vss;
   windtbl[vss,   wcont ].drain  := wcont;
   windtbl[vss,   high  ].source := vss;
   windtbl[vss,   high  ].drain  := high;
   windtbl[vss,   low   ].source := vss;
   windtbl[vss,   low   ].drain  := low;
   windtbl[vss,   strh  ].source := vss;
   windtbl[vss,   strh  ].drain  := widl;
   windtbl[vss,   strl  ].source := vss;
   windtbl[vss,   strl  ].drain  := widl;
   windtbl[vss,   whigh ].source := vss;
   windtbl[vss,   whigh ].drain  := wcont;
   windtbl[vss,   wlow  ].source := vss;
   windtbl[vss,   wlow  ].drain  := wlow;
   windtbl[vss,   vcc   ].source := vss;
   windtbl[vss,   vcc   ].drain  := vcc;
   windtbl[vss,   vss   ].source := vss;
   windtbl[vss,   vss   ].drain  := vss

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

Check label greater than

Checks if label a is less than (in alphanumeric order) label b.
Accounts for spaces.

**************************************************************}

function lgtn(var a, b: nodlab):boolean;

var l1, l2: labinx; { indexes for labels }
    f: boolean;

begin

   l1 := len(a); { find label characters a }
   l2 := len(b); { find label characters b }
   { determine greater }
   if l1 < l2 then f := true
   else if l1 > l2 then f := false
   else f := a < b;
   lgtn := f { return result }

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
   if n = '                    ' then error(ecpar) { no word found }

end;

{**************************************************************

Get number

Reads and converts the decimal numeric at the command line
position. Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getnum(var n: integer);

begin

   n := 0; { initalize number }
   skpspc; { skip spaces }
   { check any digits }
   if not (chkchr in ['0'..'9']) then error(enumnf);
   while chkchr in ['0'..'9'] do begin

      if n > maxint/10 then error(enumovf); { overflow }
      n := n * 10; { scale }
      n := n + ord(chkchr) - ord('0'); { add new digit }
      getchr { next }

   end

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
   getword(cktnam); { get the circuit file name }
   skpspc; { skip spaces }
   while cmdptr <= linmax do begin { process options }

      if chkchr <> '#' then error(eivopt); { error }
      getchr;
      if not (lcase(chkchr) in ['l', 'c']) then
         error(eivopt); { error }
      case lcase(chkchr) of { option }

         'l': begin { specify output file }

                 getchr; { skip option }
                 { check for '=' }
                 if chkchr <> '=' then error(eivopt);
                 getchr; { skip }
                 getword(outnam) { get output file name }

              end;

         'c': begin { specify trace mode }

                 getchr; { skip option }
                 trace := true { set trace mode true }

              end

      end;
      skpspc { skip spaces }

   end

end;

{**************************************************************

Create new node entry

Creates a new node entry by the given name, and returns
a pointer to it.
If the name matches an entry already present, that is returned,
else a new entry is created.
Both the next and last states are set to undefined.
The node is placed into the list in alphabetical order.

**************************************************************}

procedure newnode(var n: nodlab;  { label for node }
                  var p: nodptr); { create new node }

var m: boolean; { match flag }
    l: nodptr; { last node seen }
    np: nodptr; { node index }

begin

   { search for previously defined node }
   np := nodtbl; { index node table root }
   m := false; { clear match flag }
   l := nil; { set no last node }
   while (np <> nil) and not m do begin { search }

      if not lgtn(np^.lab, n) then m := true { found }
      else begin

         l := np; { set last }
         np := np^.next { link next }

      end

   end;
   { check true match was found }
   if np <> nil then if np^.lab <> n then m := false;
   if not m then begin { insert }

      new(p); { get new node entry }
      p^.lab    := n;      { place name }
      p^.statel := undef;  { set undefined }
      p^.staten := undef;
      p^.next   := np;     { link to next }
      if l <> nil then l^.next := p { link last to us }
      else nodtbl    := p { link root to us }

   end else p := np; { return existing entry }
   { determine number of node label characters }
   if len(n) > labtop then labtop := len(n) { set new maximum }

end;

{**************************************************************

Create new transistor

Creates a new transistor of the given type.
Accepts node labels for source, gate and drain, and connects
the transistor to these.

**************************************************************}

procedure newtrans(t: trntyp;            { type of transistor }
                   var s, g, d: nodlab); { node labels }

var f: fetptr; { pointer to fet }
    n: nodptr; { pointer to node }

begin

   new(f); { get a new transistor entry }
   f^.typet  := t;      { set type }
   newnode(s, n);       { get a source node }
   f^.source := n;      { place }
   newnode(g, n);       { get a gate node }
   f^.gate   := n;      { place }
   newnode(d, n);       { get a drain node }
   f^.drain  := n;      { place }
   f^.next   := fettbl; { link into table }
   fettbl    := f

end;

{**************************************************************

Create set entry

Creates a set entry, with the given clock trigger, node to
set, and the state to set the node to.
The clock given is converted by the clock scaling to the tick
clock. This means that clocks triggered WITHIN a scaled clock
time happen at the start of that clock time.

**************************************************************}

procedure newset(var n: nodlab; { node to set to }
                 c : integer;      { clock to set on }
                 s : nodest;    { state to set }
                 pr : integer);    { trigger period }

var p: nodptr;   { node pointer }
    st: setptr; { set pointer }

begin

   new(st); { create a set entry }
   newnode(n, p); { create a node }
   st^.clk   := c div clkscale; { place descaled clock }
   st^.nod   := p; { place node pointer }
   st^.state := s; { place state }
   st^.per   := pr div clkscale; { place descaled period }
   st^.next  := settbl; { link into list }
   settbl := st

end;

{**************************************************************

Process set node list

Runs through the set list, checking for sets that have clock
values matching the current clock. If one is found, then
the pointed node is given the value.
Note that this is a single shot event, and there is no
garantee that the node will stay set afterwards.

**************************************************************}

procedure setnodes;

var p: setptr; { pointer for set list }

begin

   p := settbl; { index set table root }
   while p <> nil do begin { process sets }

      if p^.clk = clkcnt then begin { at the proper clock }

         p^.nod^.staten := p^.state; { set the node }
         p^.clk := p^.clk + p^.per { reset by period }

      end;
      p := p^.next { link next set entry }

   end

end;

{**************************************************************

Process single clock

This is the "buisness" end of the simulator. Each transistor
is "evaluated" in turn using on, indeterminate and off rules.
Whether any change occured during the pass is flagged, and
if a change happened, further passes are run until the
circuit is "relaxed". Since the gate state is stored,
inability to relax the circuit in a single clock (and
therefore cause this routine to "hang") is impossible
(theoretically !).
The "rules" for on and indeterminate are processed via a
state lookup table to determine the next source and drain
from the last one. The rules for "off" are simple: the transistor
behaves as if it was not there, and is therefore skipped.
The rule a transistor uses are determined by the state on the
gate, which is stored from the last run.
The run starts by coping the next state to last, and converting
each next state to it's stored equivalent. This places the
requirement that drivers must assert on each and every cycle.
This procedure is the most time consuming in the simulator, and
in fact determines the basic simulation speed. It will therefore
have assembly equivalents for each machine run where high speed
is desired.

***************************************************************}

procedure sclock;

var p : fetptr;  { fet index }
    n : nodptr;  { node index }
    f : boolean; { state change flag }

procedure eval(var t: statbl); { evaluate xstr }

var ss, sd: nodest; { state variables }

begin

   ss := p^.source^.staten;
   sd := p^.drain^.staten; { save previous states }
   { find the next source and drain states }
   p^.source^.staten := t[ss, sd].source;
   p^.drain^.staten  := t[ss, sd].drain;
   { check any state change, flag if so }
   if (ss <> p^.source^.staten) or
      (sd <> p^.drain^.staten) then f := true
{;writeln(diag, 'eval: source ', p^.source^.lab, ' drain ', p^.drain^.lab,
               ' ss = ', ord(ss):1, ' nss ', ord(p^.source^.staten):1,
               ' sd = ', ord(sd):1, ' nsd ', ord(p^.drain^.staten):1);}

end;

begin

   { copy next state to last state, and translate next state
     to stored }
   n := nodtbl; { index root }
   while n <> nil do begin { translate }

      n^.statel := n^.staten; { copy to last state }
      n^.staten := strtbl[n^.staten]; { set new state }
      n := n^.next { link next }

   end;
   repeat { relax circuit }

      f := false; { set no node change }
      p := fettbl; { index root }
      while p <> nil do begin { process transistors }

         case p^.typet of

            nmos:  begin { n-channel xstr }

                      if p^.gate^.statel in [high, whigh, strh, vcc] then
                         { xstr on }
                         eval(ontbl) { evaluate by "on" rules }
                      else if p^.gate^.statel in
                         [undef, indet, indrh, indrl,
                          widh, widl, cont, wcont] then
                         { xstr indeterminate }
                         eval(indtbl) { evaluate by "indeterminate" rules }

                   end;

            pmos:  begin { p-channel xstr }

                      if p^.gate^.statel in [low, wlow, strl, vss] then
                         { xstr on }
                         eval(ontbl) { evaluate by "on" rules }
                      else if p^.gate^.statel in
                         [undef, indet, indrh, indrl,
                          widh, widl, cont, wcont] then
                         { xstr indeterminate }
                         eval(indtbl) { evaluate by "indeterminate" rules }

                   end;

            wnmos: begin { weak n-channel xstr }

                      if p^.gate^.statel in [high, whigh, strh, vcc] then
                         { xstr on }
                         eval(wontbl) { evaluate by "on" rules }
                      else if p^.gate^.statel in
                         [undef, indet, indrh, indrl,
                          widh, widl, cont, wcont] then
                         { xstr indeterminate }
                         eval(windtbl) { evaluate by "indeterminate" rules }

                   end;

            wpmos: begin { weak p-channel xstr }

                      if p^.gate^.statel in [low, wlow, strl, vss] then
                         { xstr on }
                         eval(wontbl) { evaluate by "on" rules }
                      else if p^.gate^.statel in
                         [undef, indet, indrh, indrl,
                          widh, widl, cont, wcont] then
                         { xstr indeterminate }
                         eval(windtbl) { evaluate by "indeterminate" rules }

                   end

         end;
         p := p^.next { link next transistor }

      end

   until not f;
   clkcnt := clkcnt + 1 { advance clock }

end;

{**************************************************************

Output list header

Prints the header for the list output mode.
This consists of a vertical list of all the labels, each
label over the collumn of data comprising the trace.
Note that only as many lines as the longest label to be
printed are used.

**************************************************************}

procedure header(var f: text); { file to output to }

var np : nodptr; { pointer for node list }
    c : labinx; { index for node names }
    i : byte; { index for line }
    fp: fmtptr; { pointer for format list }

begin

   for c := 1 to labtop do begin { output names }

      for i := 1 to margin do write(f, ' '); { print margin }
      if c = labtop then write(f, 'Time        ')
      else write(f, '            ');
      if fmttbl = nil then begin { use all nodes }

         np := nodtbl; { index node root }
         i := 8 + margin; { set line position }
         while (np <> nil) and (i <= lswidth) do begin

            { traverse node list }
            if np^.lab[c] <> ' ' then
               write(f, np^.lab[c]) { output node label character }
            else write(f, '.'); { mark }
            np := np^.next;      { index next node }
            i := i + 1 { count collumns }

         end

      end else begin { use format list }

         fp := fmttbl; { format table root }
         i := 8 + margin; { set line position }
         while (fp <> nil) and (i <= lswidth) do begin

            np := fp^.nod; { index node }
            if np^.lab[c] <> ' ' then
               write(f, np^.lab[c]) { output node label character }
            else write(f, '.'); { mark }
            fp := fp^.next; { index next format }
            i := i + 1 { count collumns }

         end

      end;
      writeln(f); { terminate line }
      lincnt := lincnt + 1 { count lines }

   end;
   for i := 1 to margin do write(f, ' '); { output margin }
   for i := 1 to lswidth - margin do
      write(f, '-'); { output divider }
   writeln(f); { terminate line }
   lincnt := lincnt + 1 { count line }

end;

{**************************************************************

List current node states

Outputs each node state in it's own vertical collumn, preceeded
by the scaled clock time.

**************************************************************}

procedure listnodes(var f: text); { file to output to }

var np : nodptr; { pointer for node list }
    i : byte; { index for line }
    fp: fmtptr; { pointer for format list }

begin

   for i := 1 to margin do write(f, ' '); { output margin }
   write(f, clkcnt * clkscale, ' '); { output current clock }
   i := 8 + margin; { set position }
   if fmttbl = nil then begin { use all nodes }

      np := nodtbl; { index root }
      while (np <> nil) and (i <= lswidth) do begin

         { output node states }
         write(f, equtbl[np^.staten]); { output state }
         np := np^.next; { link next }
         i := i + 1 { next position }

      end

   end else begin { use format nodes }

      fp := fmttbl; { index format root }
      while (fp <> nil) and (i <= lswidth) do begin

         np := fp^.nod; { index format node }
         { output node states }
         write(f, equtbl[np^.staten]); { output state }
         fp := fp^.next; { link next }
         i := i + 1 { next position }

      end

   end;
   writeln(f); { terminate }
   lincnt := lincnt + 1 { count line }

end;

{**************************************************************

Find label maximum for print

If a format list is present, then that is used to find the
maximum label length that will be printed.
If no format list is present, we will leave the top alone,
as it was already calculated from the node entries.

**************************************************************}

procedure fndtop;

var fp : fmtptr; { pointer for format entries }

begin

   if fmttbl <> nil then begin { table exists }

      labtop := 0; { initalize top }
      fp := fmttbl; { index table root }
      while fp <> nil do begin { find top }

         { check this entry greater than maximum,
           and update max if so }
         if len(fp^.nod^.lab) > labtop then
            labtop := len(fp^.nod^.lab);
         fp := fp^.next { link next }

      end

   end

end;

{**************************************************************

Enter new format entry

Places a new format entry at the tail end of the format
table. This will point at the given node.

**************************************************************}

procedure newfmt(var n: nodlab);

var fp1, fp2: fmtptr; { format entry pointers }
    np: nodptr; { node pointer }

begin

   new(fp1); { create format entry }
   newnode(n, np); { create new node entry }
   fp1^.nod := np; { place node pointer }
   fp1^.next := nil; { clear next }
   if fmttbl = nil then fmttbl := fp1 { 1st entry }
   else begin { find end }

      fp2 := fmttbl; { index table root }
      { search end of list }
      while fp2^.next <> nil do fp2 := fp2^.next;
      fp2^.next := fp1 { place in list }

   end

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

Load circuit file

Loads each line of the given file in turn, and executes
the commands contained there.

***************************************************************}

procedure loadckt(var f: text);

begin

   while not eof(f) do begin { read lines }

      readline(f); { read next line }
      exclin(f) { execute line }

   end

end;

{**************************************************************

Create trace buffers

Creates a table of trace buffers, one for each node present.
Each trace buffer is set to point to it's recording node.

**************************************************************}

procedure maktrc;

var np: nodptr; { pointer for nodes }
    t, t1: trcptr; { pointers for traces }
    fp: fmtptr; { format entry pointer }

begin

   trcnum := 0; { initalize trace count }
   if fmttbl = nil then begin { use all nodes }

      np := nodtbl; { index node table root }
      while np <> nil do begin { create traces }

         new(t); { create a new trace }
         t^.nod  := np; { point to the node }
         t^.next := trctbl; { link into table }
         trctbl := t;
         np := np^.next; { link next node }
         trcnum := trcnum + 1 { count traces }

      end

   end else begin { use format table }

      fp := fmttbl; { index format table root }
      while fp <> nil do begin { create traces }

         new(t); { create a new trace }
         t^.nod  := fp^.nod; { point to the node }
         t^.next := trctbl; { link into table }
         trctbl := t;
         fp := fp^.next; { link next format }
         trcnum := trcnum + 1 { count traces }

      end

   end;
   { trace table created, but backwards so reverse }
   t := trctbl; { index trace table root }
   trctbl := nil; { clear trace table }
   while t <> nil do begin { insert traces }

      t1 := t^.next; { index next trace }
      t^.next := trctbl; { link into table }
      trctbl := t;
      t := t1 { link over }

   end

end;

{**************************************************************

Store traces

The state of all nodes are saved in there trace buffers at the
proper trace data position.

**************************************************************}

procedure strtrc(tc: trcinx); { current trace count }

var t: trcptr; { pointer for traces }

begin

   t := trctbl; { index trace table root }
   while t <> nil do begin { store trace info }

      t^.buf[tc] := t^.nod^.staten; { place step }
      t := t^.next { link next trace }

   end

end;

{**************************************************************

Output trace header

Prints the trace header. This is a list of numbers representing
scaled clock values for the coming trace, listed in collumar
form. Only as many lines as needed are used.

**************************************************************}

procedure trchead(var f: text; tc: trcinx);

var s: array [1..5] of char; { integer convert save }
    i, x: 1..5;
    c: integer;
    l: trcinx;
    ni: labinx; { label index }
    si: byte; { screen index }

procedure cvtnum(n: integer); { convert integer to ascii }

begin

   s[1] := chr(n div 10000 + ord('0')); { find digits }
   s[2] := chr((n mod 10000) div 1000 + ord('0'));
   s[3] := chr((n mod 1000) div 100 + ord('0'));
   s[4] := chr((n mod 100) div 10 + ord('0'));
   s[5] := chr(n mod 10 + ord('0'))

end;

begin

   c := (clkcnt + 1) - tc * clkscale; { find starting clock }
   cvtnum((c + tc)*clkscale); { find top number }
   i := 1; { find number of digits }
   while (i < 5) and (s[i] = '0') do i := i + 1;
   for i := i to 5 do begin { line }

      { output margin }
      for si := 1 to margin do write(f, ' ');
      { space over label }
      for ni := 1 to labtop + 1 do write(f, ' ');
      for l := 0 to tc - 1 do begin { digits }

         cvtnum((c+l)*clkscale); { find clock }
         { eliminate leading zeros }
         x := 1;
         while (x < 5) and (s[x] = '0') do begin

            s[x] := ' '; { blank out }
            x := x + 1

         end;
         write(f, s[i]) { output digit }

      end;
      writeln(f); { terminate line }
      lincnt := lincnt + 1 { count lines }

   end;
   { output margin }
   for si := 1 to margin do write(f, ' ');
   { print dividing line }
   for si := 1 to tc + labtop + 1 do write(f, '=');
   writeln(f); { terminate line }
   lincnt := lincnt + 1 { count line }

end;

{**************************************************************

Output centering margin

Outputs the number of left side spaces required to center
the string whose length is given. If the string is >= the line
length, nothing happens.

**************************************************************}

procedure center(var f: text; n: byte);

var i: byte;

begin

   if n < lswidth then { fits in line }
      { space off }
      for i := 1 to (lswidth div 2) - (n div 2) do write(f, ' ')

end;

{**************************************************************

Print page header

Prints the header for a pagenated list. Includes our logo,
the circuit title, and the page number.

**************************************************************}

procedure prtpgh(var f: text);

var s: packed array [1..60] of char; { holder for strings }
    t: byte; { print width holder }
    i: byte; { string index }

begin

   page(f); { output new page }
   lincnt := 0; { reset line count }
   { print out logo }
   t := 60; { set print width }
   s := 'Cktsim logic simulator vs 1.0 copyright (C) 1988 S. A. Moore';
   center(f, t); { center that }
   if t <= lswidth then
      for i := 1 to t do write(f, s[i]); { print logo }
   writeln(f); { terminate line }
   lincnt := lincnt + 1; { count }
   writeln(f); { space off }
   lincnt := lincnt + 1; { count }
   writeln(f);
   lincnt := lincnt + 1; { count }
   { output indicator line }
   if trace then begin

   t := 24;
   s := 'Circuit state trace for                                     '

   end else begin

   t := 23;
   s := 'Circuit state list for                                      '

   end;
   center(f, t + len(cktnam) + 4); { center that line }
   if (t + len(cktnam) + 4) <= lswidth then begin

      for i := 1 to t do write(f, s[i]); { print line }
      write(f, '- '); { bracket name }
      i := 1; { set 1st label character }
      { print label }
      while (i <= labmax) and (cktnam[i] <> '.') and
            (cktnam[i] <> ' ') do begin

         write(f, cktnam[i]); { print character }
         i := i + 1 { next character }

      end;
      write(f, ' -') { bracket name }

   end;
   writeln(f); { terminate line }
   lincnt := lincnt + 1; { count }
   writeln(f); { space off }
   lincnt := lincnt + 1; { count }
   writeln(f);
   lincnt := lincnt + 1 { count }

end;

{**************************************************************

Print page number

Prints two blank lines, then the page number centered on the
line.

**************************************************************}

procedure pagnum(var f: text);

begin

   writeln(f); { space off }
   lincnt := lincnt + 1; { count }
   writeln(f);
   lincnt := lincnt + 1; { count }
   if pagcnt < 10 then center(f, 1+4) { center 1 digit }
   else if pagcnt < 100 then center(f, 2+4) { center 2 digits }
   else if pagcnt < 1000 then center(f, 3+4) { etc. }
   else if pagcnt < 10000 then center(f, 4+4)
   else center(f, 5+4);
   writeln(f, '- ', pagcnt:1, ' -'); { output page count }
   lincnt := lincnt + 1; { count }
   pagcnt := pagcnt + 1 { next page }

end;

{**************************************************************

List traces

A trace line for each node is output, preceeded by the node name.

**************************************************************}

procedure listtrc(var f: text; tc: trcinx);

var t: trcptr; { pointer for traces }
    i: labinx; { index for labels }
    ti: trcinx; { index for traces }
    si: byte; { screen index }

begin

   t := trctbl; { index trace table root }
   while t <> nil do begin { output traces }

      if (lincnt = 0) and (lslen <> 0) then begin

         prtpgh(f); { output page header }
         trchead(f, trccnt) { output trace header }

      end;
      { output margin }
      for si := 1 to margin do write(f, ' ');
      for i := 1 to labtop do { output node label }
         if t^.nod^.lab[i] <> ' ' then
            write(f, t^.nod^.lab[i])
         else write(f, '.'); { format }
      write(f, '.'); { space off }
      for ti := 1 to tc do { output trace states }
         if t^.buf[ti] in [undef, indet, indrh, indrl, widh,
                           widl, cont, wcont] then
            write(f, 'x') { output indeterminate }
         else if t^.buf[ti] in [high, strh, whigh, vcc] then
            write(f, '-') { output high }
         else write(f, '_'); { output low }
      writeln(f); { terminate line }
      lincnt := lincnt + 1; { count lines }
      t := t^.next; { link next entry }
      if lslen <> 0 then
         if lincnt = lslen -3 then begin

         { end of page }
         pagnum(f); { print the page number }
         lincnt := 0 { set page start }

      end

   end

end;

{**************************************************************

Enter macro definition

Entered after the "macro" command has been parsed, parses
the rest of the parameters on the command line as the
macro name and parameters, then gathers all the command
lines following as the macro body until a endmac statement
appears.

**************************************************************}

procedure macdef(var f: text);

var n: nodlab; { label holder }
    mp: macptr; { pointer for macro entry }
    pp1, pp2: parptr; { pointer for parameters }
    lp1, lp2: linptr; { pointer for lines }
    done: boolean; { done flag }

begin

   new(mp); { get a new macro entry }
   mp^.next := mactbl; { link into macro table }
   mactbl := mp;
   mp^.par := nil; { initalize links }
   mp^.lin := nil;
   mp^.num := 0; { set number of executions }
   getword(mp^.nam); { get the macro name }
   skpspc; { skip spaces }
   while (cmdptr <= linmax) and (chkchr <> '!') do begin

      { load parameters }
      new(pp1); { get a new parameter entry }
      pp1^.next := nil; { initalize link }
      { insert at parameter list end }
      if mp^.par = nil then mp^.par := pp1 { insert at start }
      else begin { insert at end }

         pp2 := mp^.par; { index root }
         { find end of list }
         while pp2^.next <> nil do pp2 := pp2^.next;
         pp2^.next := pp1 { insert }

      end;
      getword(pp1^.lab); { get the parameter name }
      skpspc { skip spaces }

   end;
   done := false; { set not at macro end }
   while not eof(f) and not done do begin { read lines }

      readline(f); { read next line }
      skpspc; { skip spaces }
      if (cmdptr <= linmax) and (chkchr <> '!') then begin

         { check for "endmac" command }
         getword(n); { get command }
         if n = 'endmac              ' then begin { at end }

            done := true; { set done with this def }
            skpspc; { skip spaces }
            if (cmdptr <= linmax) and (chkchr <> '!') then
               error(einvcmd) { error }

         end

      end;
      if not done then begin { enter line }

         new(lp1); { get a new line entry }
         lp1^.next := nil; { initalize link }
         { insert at line list end }
         if mp^.lin = nil then mp^.lin := lp1 { insert at start }
         else begin { insert at end }

            lp2 := mp^.lin; { index root }
            { find end of list }
            while lp2^.next <> nil do lp2 := lp2^.next;
            lp2^.next := lp1 { insert }

         end;
         lp1^.lin := cmdlin { place macro line }

      end

   end;
   if not done then error(eutmac) { error }

end;

{*************************************************************

Subsitute parameters

Expects a formal and actual parameter list, and the
macro execution number. Walks through the line character
by character, searching for a match with any of the formal
parameters. This is done without regard to the context.
The actual parameter is then inserted.
Also subsitutes the '@' character with the ascii macro
execution number.

**************************************************************}

procedure subsitute(fp, ap: parptr; en: integer);

var li1, li2, li3: lininx; { indexs for line }
    ni: labinx; { index for label }
    pp1, pp2: parptr; { pointers for parameters }
    m: boolean; { match flag }
    ens: array [1..5] of char; { ascii execution number }
    ei: 1..5; { index for that }

begin

   li1 := 1; { set 1st character }
   while li1 <= linmax do begin { successive fit }

      if cmdlin[li1] = '@' then begin

         { perform subsitution of macro execution number }
         ens[1] := chr(en div 10000 + ord('0')); { find digits }
         ens[2] := chr((en mod 10000) div 1000 + ord('0'));
         ens[3] := chr((en mod 1000) div 100 + ord('0'));
         ens[4] := chr((en mod 100) div 10 + ord('0'));
         ens[5] := chr(en mod 10 + ord('0'));
         { skip leading zeros }
         ei := 1;
         while (ei < 5) and (ens[ei] = '0') do ei := ei + 1;
         for li2 := li1 to linmax - 1 do
            cmdlin[li2] := cmdlin[li2 + 1]; { gap out '@' }
         cmdlin[linmax] := ' '; { space out end }
         while ei <= 5 do begin

            { copy into place }
            { check for line overflow }
            if cmdlin[linmax] <> ' ' then error(emetl);
            { move line characters up }
            for li2 := linmax downto li1 + 1 do
               cmdlin[li2] := cmdlin[li2 - 1];
            cmdlin[li1] := ens[ei]; { place character }
            li1 := li1 + 1; { next position }
            ei :=ei + 1

         end

      end else begin { check parameter subsitution }

         pp1 := fp; { index parameter list roots }
         pp2 := ap;
         m := false; { set no match }
         while (pp1 <> nil) and (pp2 <> nil) and not m do begin

            { try each parameter in turn }
            if len(pp1^.lab) <= (linmax - li1 + 1) then begin

               { match parameter }
               ni := 1; { set 1st label character }
               while (ni <= labmax) and
                  (pp1^.lab[ni] = cmdlin[li1 + ni - 1]) and
                  (pp1^.lab[ni] <> ' ') do
                     ni := ni + 1; { keep going }
               { set match status }
               m := true; { set matched }
               if ni <= labmax then { check match }
                  m := pp1^.lab[ni] = ' '

            end;
            if not m then begin { next }

               pp1 := pp1^.next; { next formal }
               pp2 := pp2^.next  { next actual }

            end

         end;
         if m then begin { found a parameter, perform subsitution }

            li2 := li1; { index present position }
            li3 := li1 + ni - 1; { index end of parameter }
            while li3 <= linmax do begin { gap the line }

               cmdlin[li2] := cmdlin[li3];
               li2 := li2 + 1; { next positions }
               li3 := li3 + 1

            end;
            while li2 <= linmax do begin { fill end with spaces }

               cmdlin[li2] := ' '; { place space }
               li2 := li2 + 1 { next }

            end;
            ni := 1; { set start of actual parameter }
            while (ni <= labmax) and (pp2^.lab[ni] <> ' ') do begin

               { copy actual into place }
               { check for line overflow }
               if cmdlin[linmax] <> ' ' then error(emetl);
               { move line characters up }
               for li3 := linmax downto li1 + 1 do
                  cmdlin[li3] := cmdlin[li3 - 1];
               cmdlin[li1] := pp2^.lab[ni]; { place character }
               li1 := li1 + 1; { next position }
               ni := ni + 1

            end

         end else li1 := li1 + 1 { next line character }

      end { parameter subsititute }

   end { while loop }

end;

{**************************************************************

Execute macro

Called after the macro name has been found. A list of actual
parameters is parsed and checked against the original list.
Then each line of the macro is processed for subsitution,
and then executed.
The special symbol '@' stands for the macro execution number,
and will be expanded to the number of times the macro has been
executed. This is used to create unique labels.

**************************************************************}

procedure excmac(var f: text; mp: macptr); { execute macro }

var en: integer; { execution number save }
    lp: linptr; { pointer for lines }
    pp1, pp2: parptr; { pointer for parameters }
    actlst: parptr; { actual parameter list }

begin

   mp^.num := mp^.num + 1; { count executions }
   en := mp^.num; { save macro execution number }
   actlst := nil; { initalize actual parameter list }
   skpspc; { skip spaces }
   while (cmdptr <= linmax) and (chkchr <> '!') do begin

      { read actual parameters }
      new(pp1); { get a new parameter entry }
      pp1^.next := nil; { initalize link }
      { insert at parameter list end }
      if actlst = nil then actlst := pp1 { insert at start }
      else begin { insert at end }

         pp2 := actlst; { index root }
         { find end of list }
         while pp2^.next <> nil do pp2 := pp2^.next;
         pp2^.next := pp1 { insert }

      end;
      getword(pp1^.lab); { get the parameter name }
      skpspc { skip spaces }

   end;
   { check actual to formal parameter correspondence }
   pp1 := actlst; { index actual root }
   pp2 := mp^.par; { index formal root }
   while (pp1 <> nil) and (pp2 <> nil) do begin

      pp1 := pp1^.next; { skip actuals }
      pp2 := pp2^.next  { skip formals }

   end;
   if pp1 <> pp2 then error(eparc); { error }
   lp := mp^.lin; { index line root }
   while lp <> nil do begin { execute lines }

      cmdlin := lp^.lin; { place command line }
      cmdptr := 1; { reset line pointer }
      subsitute(mp^.par, actlst, en); { process subsitution }
      exclin(f); { execute line }
      lp := lp^.next { link next line }

   end

end;

{**************************************************************

Execute single line

Executes the command in the command line buffer. Anyplace
'!' appears is a comment, as is a blank line.

***************************************************************}

procedure exclin(var f: text);

var w, s, g, d, n: nodlab; { label holders }
    t : trntyp; { transistor type }
    clk: integer; { clock holder }
    per: integer; { clock period }
    st: nodest; { state holder }
    mp: macptr; { pointer for macro entries }

begin

   skpspc; { skip spaces }
   if (chkchr <> '!') and (cmdptr <= linmax) then
      begin { not comment }

      getword(w); { get command word }
      if (w = 'n                   ') or
         (w = 'p                   ') or
         (w = 'wn                  ') or
         (w = 'wp                  ') then begin

         { enter transistor }
         { set transistor type }
         if w = 'n                   ' then t := nmos
         else if w = 'p                   ' then t := pmos
         else if w = 'wn                  ' then t := wnmos
         else t := wpmos;
         getword(s); { get source }
         getword(g); { get gate }
         getword(d); { get drain }
         newtrans(t, s, g, d) { create transistor }

      end else if w = 'set                 ' then begin

         { node set command }
         getword(n); { get the node to set }
         repeat { get sets }

            clk := clkcnt; { set default to now }
            per := 0; { set default period }
            getst(st); { get state to set }
            skpspc; { skip spaces }
            if chkchr in ['0'..'9', '+'] then begin

               if chkchr = '+' then begin { offset clock }

                  getchr; { skip '+' }
                  getnum(clk); { get clock }
                  clk := clk + clkcnt { offset by current }

               end else getnum(clk); { get clock }
               if chkchr = ':' then begin { period spec }

                  getchr; { skip that }
                  getnum(per) { get the period }

               end;
               skpspc { skip spaces }

            end;
            newset(n, clk, st, per) { create a clock entry }


         until (cmdptr > linmax) or (chkchr = '!')

      end else if w = 'clockscale          ' then
         { set clock scaling command }
         getnum(clkscale) { get the clock scaling }
      else if w = 'chart               ' then
         trace := true { set to trace mode }
      else if w = 'list                ' then
         trace := false { set to list mode }
      else if (w = 'step                ') or
              (w = 's                   ') then begin

              getnum(stpcnt); { get the step count }
              stpcnt := stpcnt div clkscale { scale }

      end else if w = 'line                ' then
         getnum(lswidth) { get the list width }
      else if w = 'page                ' then begin

         { set pagenation mode }
         skpspc; { check parameter present }
         if chkchr in ['0'..'9'] then
            getnum(lslen) { get the list length }
         else lslen := 60 { set default }

      end else if w = 'margin              ' then begin

         { set left margin for list }
         skpspc; { check parameter present }
         if chkchr in ['0'..'9'] then
            getnum(margin) { get the margin count }
         else margin := 10 { set default }

      end else if w = 'format              ' then
         { create new format entries }
         repeat

            getword(n); { get node }
            newfmt(n); { create new format entry }
            skpspc { skip spaces }

         until (cmdptr > linmax) or (chkchr = '!')
      else if w = 'macro               ' then
         macdef(f) { process macro define }
      else begin { try to find macro definition }

         mp := mactbl; { index macro table root }
         if mp = nil then error(ecnf); { process error }
         while mp <> nil do begin { fit macro }

            if w = mp^.nam then begin

               excmac(f, mp); { found, execute }
               mp := nil { flag done }

            end else begin { next }

               mp := mp^.next; { link next }
               if mp = nil then error(ecnf) { process error }

            end

         end

      end

   end

end;

{**************************************************************

Main program

Initalizes global variables, processes the options, loads
the circuit file and runs the simulation.

**************************************************************}

begin

   writeln('CMOS circuit simulator 0.2 Copyright (C) 2001 S. A. Moore');

   { initalize "on" state tables }

   initon;
   initwon;

   { initalize "indeterminate" state table }

   initind;
   initwind;

   { set start of clock translation table }

   strtbl[undef] := undef; { stays }
   strtbl[indet] := indet; { stays }
   strtbl[indrh] := indet; { goes to general stored }
   strtbl[indrl] := indet; { "   " }
   strtbl[widh]  := indet; { "   " }
   strtbl[widl]  := indet; { "   " }
   strtbl[cont]  := indet; { "   " }
   strtbl[wcont] := indet; { "   " }
   strtbl[high]  := strh;  { goes to stored }
   strtbl[low]   := strl;  { goes to stored }
   strtbl[strh]  := strh;  { stays }
   strtbl[strl]  := strl;  { stays }
   strtbl[whigh] := strh;  { goes to stored }
   strtbl[wlow]  := strl;  { "   " }
   strtbl[vcc]   := vcc;   { stays }
   strtbl[vss]   := vss;   { stays }

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

   { initalize node and fet tables }

   nodtbl := nil;
   fettbl := nil;
   settbl := nil;
   trctbl := nil;
   fmttbl := nil;
   mactbl := nil;
   clkcnt := 0; { set clock time 0 }
   clkscale := 1; { set clock scaling to 1 }
   stpcnt := 50; { set default step count }
   labtop := 1; { set default label top }
   trccnt := 1; { initalize tracing count }
   lswidth := 79; { set default listing width }
   lslen := 0; { set no pagination }
   lincnt := 0; { set line count }
   pagcnt := 1; { set 1st page }
   trcnum := 0; { set no traces }
   first := true; { set 1st on page }
   margin := 0; { no left margin }

   { process options and open output file }

   trace := false; { set trace mode off }
   outopn := false; { set files not open }
   cktopn := false;
   outnam := '_output             '; { assign default output }
   prcopt(command); { process options }
   addext(cktnam, '.ckt                '); { place extention }
   { check circuit file exists }
   if not exists(cktnam) then error(ecfnf);
   assign(cktfil, cktnam); { open circuit file }
   reset(cktfil);
   assign(outfil, outnam); { open output file }
   rewrite(outfil);

   { load simulator file }

   write('Loading circuit file: '); { announce }
   for i := 1 to labmax do if cktnam[i] <> ' ' then
      write(cktnam[i]);
   writeln;
   loadckt(cktfil);
   fndtop; { find new label top }

   { run simulation }

   writeln('Performing simulation');
   if trace then maktrc; { make trace table }
   for i := 1 to stpcnt do begin { run sim }

      setnodes; { process node sets }
      if trace then begin { process trace step }

         strtrc(trccnt); { store traces }
         { check if we have enough traces to fill a screen }
         if trccnt = (lswidth - labtop - 1 - margin) then begin

            { determine size of trace }
            i1 := clkcnt * clkscale; { find scaled top }
            if i1 < 10 then i1 := 1 { one digit }
            else if i1 < 100 then i1 := 2 { two digits }
            else if i1 < 1000 then i1 := 3 { etc }
            else if i1 < 10000 then i1 := 4
            else i1 := 5;
            i1 := i1 + 1; { add divider line }
            if ((lincnt + trcnum + i1) > lslen) and
               (lslen <> 0) and (lincnt <> 0) then begin

               { chart to big for page, skip to next page }
               { space down to page end }
               for i1 := lincnt to lslen - 3 - 1 do writeln(outfil);
               pagnum(outfil); { print the page number }
               lincnt := 0; { reset to page start }
               first := true { restore virginity (quite a trick !) }

            end;
            if (lincnt = 0) and (lslen <> 0) then
               prtpgh(outfil); { output page header }
            if not first then begin

               writeln(outfil); { provide spacing }
               lincnt := lincnt + 1 { count that }

            end;
            trchead(outfil, trccnt); { output trace header }
            listtrc(outfil, trccnt); { output full trace }
            trccnt := 1; { reset trace count }
            first := false { remove virginity }

         end else trccnt := trccnt + 1 { count traces }

      end else begin { process list format }

         if lincnt = 0 then begin { output header }

            { if pagenation on, output page header }
            if lslen <> 0 then prtpgh(outfil);
            header(outfil); { output our header }

         end;
         listnodes(outfil); { list node states }
         { if we overflow a page, reset to next page }
         if lslen <> 0 then
            if lincnt = lslen - 3 then begin

           { end of page }
            pagnum(outfil); { print the page number }
            lincnt := 0

         end

      end;
      sclock { step clock }

   end;
   if trace and (trccnt <> 0) then begin

      trccnt := trccnt - 1; { back out last count }
      clkcnt := clkcnt - 1; { this really could be done better }
      { determine size of trace }
      i1 := clkcnt * clkscale; { find scaled top }
      if i1 < 10 then i1 := 1 { one digit }
      else if i1 < 100 then i1 := 2 { two digits }
      else if i1 < 1000 then i1 := 3 { etc }
      else if i1 < 10000 then i1 := 4
      else i1 := 5;
      i1 := i1 + 1; { add divider line }
      if ((lincnt + trcnum + i1) > lslen) and
         (lslen <> 0) and (lincnt <> 0) then begin

         { chart to big for page, skip to next page }
         { space down to page end }
         for i := lincnt to lslen - 3 - 1 do writeln(outfil);
         pagnum(outfil); { print the page number }
         lincnt := 0 { reset to page start }

      end;
      if (lincnt = 0) and (lslen <> 0) then
         prtpgh(outfil); { output page header }
      if not first then begin

         writeln(outfil); { provide spacing }
         lincnt := lincnt + 1

      end;
      trchead(outfil, trccnt); { output trace header }
      listtrc(outfil, trccnt) { output full trace }

   end;
   if (lincnt <> 0) and (lslen <> 0) then begin { finish page }

      { space down to page end }
      for i := lincnt to lslen - 3 - 1 do writeln(outfil);
      pagnum(outfil) { print the page number }

   end;
   writeln('Simulation complete');

   99: { abort program }

   if cktopn then close(cktfil); { close the input file }
   if outopn then close(outfil) { close the output file }

end.

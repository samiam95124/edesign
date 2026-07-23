{**************************************************************
*                                                             *
* MOSIS .CIF TO .CEL CONVERTER PROGRAM                        *
*                                                             *
* Format:                                                     *
*                                                             *
*   cif2cel filename [/ps] [/ns] [/b]                         *
*                                                             *
* Converts the file.cif to a file.cel. Any extention in the   *
* filename is unused. Only MOSIS .cifs are presently          *
* converted.                                                  *
*                                                             *
* Options:                                                    *
*                                                             *
*   /ps - Causes the p-select mask to be output as comment    *
*         boxes.                                              *
*                                                             *
*   /ns - Causes the n-select mask to be output as comment    *
*         boxes.                                              *
*                                                             *
*   /b  - Causes the bonding mask to be output as comment     *
*         boxes.                                              *
*                                                             *
**************************************************************}

program cif2cel(output, command);

uses strings;

label 99; { terminate program }

const 

      linmax = 200; { command line maximum length }
      filmax = 76;  { number of characters in a filename }
      extmax = 5;   { number of characters in extention }
      labmax = 20;  { number of character in label }

type

     bytfil = file of byte; { byte file }
     point  = record x, y: integer end; { coordinate point }
     region = record s, e: point end; { rectangular region }
     labinx = 1..labmax; { index for label }
     labtyp = packed array [labinx] of char; { label }
     { Mosis CIF layers }
     mlaytyp = (mltnone,    { no layer }
                mltcell,    { cells (our own addition) }
                mltwell,    { generic well }
                mltpwell,   { p well }
                mltnwell,   { n well }
                mltactive,  { active }
                mltselect,  { generic select }
                mltpselect, { p select }
                mltnselect, { n select }
                mltpoly,    { poly }
                mltpcont,   { poly contact }
                mltacont,   { active contact }
                mltmet1,    { metal 1 }
                mltvia,     { via }
                mltmet2,    { metal 2 }
                mltecont,   { electrode contract }
                mltelect,   { electrode }
                mltovg,     { overglass }
                mltbnd);    { bonding }
     { ICD layers }
     ilaytyp  = (iltcell,  { cells layer }
                 iltfig,   { figures layer }
                 iltovg,   { overglass layer }
                 iltvia,   { via layer }
                 iltism2,  { met 2 intersections layer }
                 iltism1,  { met 1 intersections layer }
                 iltisply, { poly intersections layer }
                 iltmet2,  { metal 2 layer }
                 iltcont,  { contact layer }
                 iltpmd,   { poly, metals and diff layer }
                 iltwell); { wells layer }
     { ICD figure codes }
     figtyp = (tend, tline, tbox, tarc, tchar, twire, tbus, 
               tjunction, tbline, tbbox, tcell, tconnect,
               tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss,
               tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
               tnwell, tpwell, tccut, tinter, tcont, ttrc, tatrc);
     color  = (black, blue, green, cyan, red, magenta, brown,
               dwhite, gray, lblue, lgreen, lcyan, lred, lmagenta,
               yellow, white);
     rotmod = (rm0, rm90, rm180, rm270, rmm0, rmm90, rmm180, 
               rmm270);
     celptr = ^cell; { cell pointer }
     recptr = ^rectangle; { pointer to rectangle record }
     rectangle = record { rectangle record }

        typ:    figtyp;  { figure type (unused on CIF) }
        sx, sy: integer; { starting point, or cell offset }
        ex, ey: integer; { ending point, or cell multipliers }
        c:      color;   { color }
        itt:    figtyp;  { type of top layer }
        ipt:    recptr;  { intersection top }
        itb:    figtyp;  { type of bottom layer }
        ipb:    recptr;  { intersection bottom }
        fn:     integer; { number of entry (1-N) }
        ln:     ilaytyp; { layer type of entry (ICD only) }
        celn:   integer; { cell reference number. If non-zero,
                           is a cell call, with origin at
                           starting point. }
        celp:   celptr;  { pointer to cell after definition }
        r:      rotmod;  { cell rotation }
        next:   recptr   { next entry }

     end;
     cell = record { cell entry }

        name:   labtyp; { name of cell }
        num:    integer; { number of cell }
        { Mosis layer database }
        mclay:  array [mlaytyp] of recptr;
        { ICD layer database }
        icdlay: array [ilaytyp] of recptr;
        bndset:  boolean; { bounds set flag }
        bndsx, bndsy, bndex, bndey: integer; { bounds of sheet }
        a, b:   integer; { CIF a/b parameters }
        next:   celptr { next entry }

     end;
     { cell file partition marker codes }
     celseg = (ccfterm, ccterm, cceldir, ccell, ccschema, cclayout, 
               ccwave, ccsymbol);
     celtyp = (ctsch, ctsym, ctlay); { placement cell type }
     lininx = 0..linmax; { index for line }
     filinx = 1..filmax; { index for filename }
     filnam = packed array [filinx] of char; { a filename }
     extinx = 1..extmax; { index for extention }
     extnam = packed array [extinx] of char; { an extention }
     { error codes }
     errcod = (einvfn,   { invalid filename }
               ecifne,   { .CIF file does not exist }
               einvopt,  { invalid option }
               efilntl,  { filename to large }
               eeof,     { Unexpected end of file }
               enume,    { number expected }
               elabtl,   { label too long }
               eclm,     { checksum line missing }
               euicmd,   { unimplemented command }
               enalfe,   { no active layer for entry }
               eorna,    { orientations not allowed }
               einvt,    { invalid transformation }
               erot,     { 90 degree rotations only allowed }
               einvcmd,  { invalid command }
               enestc,   { nested cell definition }
               einvcn,   { invalid cell number }
               eunkly,   { unknown layer }
               elyns,    { layer not supported }
               escne,    { ";" expected }
               echksm,   { checksum mismatch }
               ecelnd,   { cell number not defined }
               ecmdltl); { command line too long }

var cmdlin:   packed array [1..linmax] of char; { command line }
    cmdptr:   lininx;  { command line index }
    name:     filnam; { filename holder }  
    celstk:   celptr; { cell list }
    lincnt:   integer; { source lines counter }
    celnum:   integer; { error cell number holder }
    { options }
    opselect: boolean; { output p-select }
    onselect: boolean; { output n-select }
    obond:    boolean; { output bonding layer }
    onchk:    boolean; { do not do checksum }

{**************************************************************

PROCESS ERROR

Prints the error and exits.

**************************************************************}

procedure error(e: errcod);

begin

   write('*** Error: ');
   if lincnt <> 0 then write('line ', lincnt:1, ': ');
   case e of { error }

      einvfn:  writeln('invalid filename');
      ecifne:  writeln('.CIF file does not exist');
      einvopt: writeln('invalid option');
      efilntl: writeln('filename to large');
      eeof:    writeln('Unexpected end of file');
      enume:   writeln('number expected');
      elabtl:  writeln('label too long');
      eclm:    writeln('checksum line missing');
      euicmd:  writeln('unimplemented command');
      enalfe:  writeln('no active layer for entry');
      eorna:   writeln('orientations not allowed');
      einvt:   writeln('invalid transformation');
      erot:    writeln('90 degree rotations only allowed');
      einvcmd: writeln('invalid command');
      enestc:  writeln('nested cell definition');
      einvcn:  writeln('invalid cell number');
      eunkly:  writeln('unknown layer');
      elyns:   writeln('layer not supported');
      escne:   writeln('";" expected');
      echksm:  writeln('checksum mismatch');
      ecelnd:  writeln('cell number ', celnum:1, 
                       ' not defined');
      ecmdltl: writeln('command line too long');

   end;
   goto 99 { exit }

end;

{**************************************************************

Get command line

Gets the caller line into the command line buffer.
Dependant on SVS Pascal.

**************************************************************}

procedure getcml;

var ovf: boolean;

begin

   reads(command, cmdlin, ovf); { get command line }
   if ovf then error(ecmdltl); { command line to long }
   cmdptr := 1 { set 1st character position }

end;

{**************************************************************

Check character

Returns the next character in the command line.

**************************************************************}

function chkchr: char;

var c: char;

begin

   if cmdptr <> 0 then c := cmdlin[cmdptr] { return char }
   else c := ' '; { replace with space }
   chkchr := c { return result }

end;

{**************************************************************

Get next character

Skips the command pointer to the next character. Clears the 
command position if the line overflows.

**************************************************************}

procedure getchr;

begin

   if cmdptr <> 0 then begin

      if cmdptr <> linmax then cmdptr := cmdptr + 1 { next }
      else cmdptr := 0 { clear position }

   end

end;

{**************************************************************

Skip file spaces

Skips the given text file over any spaces, except eoln.

**************************************************************}

procedure skpspc;

begin

   while (chkchr = ' ') and (cmdptr <> 0) do getchr

end;

{**************************************************************

Get filename

Parses a filename (a whitespace-delimited token) from the command line.

**************************************************************}

procedure getfnm(var n: filnam); 

var fi, i: lininx; { index for filename }

procedure plcchr(c: char);

begin

   if fi = filmax then error(efilntl); { overflow }
   n[fi] := c; { place character }
   fi := fi + 1

end;

begin

   for i := 1 to filmax do n[i] := ' '; { clear result }
   fi := 1; { index 1st file character }
   skpspc; { skip leading spaces }
   { Copy the filename as a whitespace-delimited token. Unlike the
     original, no MSDOS 8.3/drive/section structure is imposed: every
     character up to the next space or end of line is taken verbatim,
     so long names, an extension, and path separators all pass through. }
   while (chkchr <> ' ') and (cmdptr <> 0) do begin

      plcchr(chkchr); { place character }
      getchr { next character }

   end;
   if fi = 1 then error(einvfn) { no characters processed }

end;

{**************************************************************

Get word from file

Gets a word from the given file, which is any sequence of
non-blank characters ending by a space or eoln, with any
number of spaces preceeding.

**************************************************************}

procedure getword(var w: labtyp);

var i : filinx; { index for name }

begin

   for i := 1 to labmax do w[i] := ' '; { initalize result }
   skpspc; { skip spaces }
   i := 1; { initalize buffer index }
   while chkchr in
      ['_', 'a'..'z', 'A'..'Z', '0'..'9', '.', ':', '*',
       '?'] do begin

      if i > labmax then error(elabtl); { error }
      { get letters }
      w[i] := chkchr; { place }
      getchr; { next file position }
      i := i + 1 { next buffer position }

   end

end;

{**************************************************************

Process caller line

Read a line from the given file, and processes the circuit
file there and any command line options.

**************************************************************}

procedure paropt;

var w: labtyp;

begin

   skpspc; { skip spaces }
   while chkchr = '/' do begin { process options }

      getchr; { skip '/' }
      getword(w);	{ get option name }
		if (w = 'ps                  ') or 
         (w = 'pselect             ') then
         opselect := true { set output p-select }
		else if (w = 'nps                 ') or 
              (w = 'nopselect           ') then
         opselect := false { reset output p-select }
		else if (w = 'ns                  ') or 
              (w = 'nselect             ') then
         onselect := true { set output n-select }
		else if (w = 'nns                 ') or 
              (w = 'nonselect           ') then
         opselect := false { reset output n-select }
		else if (w = 'b                   ') or 
              (w = 'bond                ') then
         obond := true { set output bonding layer }
		else if (w = 'nb                  ') or 
              (w = 'nobond              ') then
         obond := false { reset output bonding layer }
		else if (w = 'nc                  ') or 
              (w = 'nocheck             ') then
         onchk := true { set no checksum }
      else error(einvopt); 
      skpspc { skip spaces }

   end

end;

{**************************************************************

Append file extention

Appends a given extension to the file name. Places the extension
at the first period or space position.

**************************************************************}

procedure addext(var f: filnam; e: extnam);

var i1: filinx; { filename index }
    i2: extinx; { extention index }

begin

   i1 := 1; { initalize file index }
   { skip to first blank or period }
   while (f[i1] <> ' ') and (f[i1] <> '.') do begin

      if i1 = filmax then error(efilntl);
      i1 := i1 + 1

   end;
   i2 := 1; { initalize extension index }
   while (e[i2] <> ' ') do begin { copy extension into place }

      if i1 = filmax then error(efilntl); { overflow, error }
      f[i1] := e[i2]; { copy character }
      i1 := i1 + 1; { next position }
      i2 := i2 + 1

   end

end;

{**************************************************************

CONVERT NUMBER TO STRING

Converts the given number to the label.

**************************************************************}

procedure strnum(n: integer; var l: labtyp);

var p:     integer; { current power }
    i, i1: labinx;  { index for label }

begin

   for i := 1 to 8 do begin { extract powers }   

      case i of { power }

         1: p :=   10000000;
         2: p :=    1000000;
         3: p :=     100000;
         4: p :=      10000;
         5: p :=       1000;
         6: p :=        100;
         7: p :=         10;
         8: p :=          1

      end;
      { convert and place digit }
      l[i] := chr(n div p + ord('0'));
      n := n mod p { remove that power }

   end;
   i := 1; { find 1st non-zero digit }
   while (i < 8) and (l[i] = '0') do i := i + 1;
   i1 := 1; { move back }
   while i <= 8 do begin { move }

      l[i1] := l[i]; { move character }
      i := i + 1; { next }
      i1 := i1 + 1

   end;
   { blank the rest }
   for i := i1 to labmax do l[i] := ' '

end;

{**************************************************************

FIND NET MIRROR ON CELL

Finds the net product of two transforms.
This is for when a cell with any given transform
is placed into another cell with it's own transform.
I suspect that the product is associative, but have not
tried the experiment.

**************************************************************}

function netmir(rt,         { containing cell }
                rm: rotmod) { cell contained }
                : rotmod;   { net rotation }

var rc:     rotmod;
    ra, rb: 0..7;

begin

   ra := ord(rm); { find unmirrored equivalents }
   if rm > rm270 then ra := ra - ord(rmm0);
   rb := ord(rt);
   if rt > rm270 then rb := rb - ord(rmm0);
   rb := ra+rb; { find net rotation }
   { adjust for wraparound }
   if rb > ord(rm270) then rb := rb - ord(rmm0);
   { check net mirroring effect }
   if (rm in [rm0, rm90, rm180, rm270]) =
      (rt in [rm0, rm90, rm180, rm270]) then
         case rb of { normal rotation }

      0: rc := rm0;
      1: rc := rm90;
      2: rc := rm180;
      3: rc := rm270

   end else case rb of { mirrored rotation }

      0: rc := rmm0;
      1: rc := rmm90;
      2: rc := rmm180;
      3: rc := rmm270

   end;
   netmir := rc { return result }

end;

{**************************************************************

LOAD MOSIS CIF FILE

Loads a Mosis CIF file to internal database.

**************************************************************}

procedure loadcif;

var fcif:    text;    { cif input file }
    n:       integer; { number holder }
    ef:      boolean; { end of file flag }
    labbuf:  labtyp;  { label buffer }
    layer:   mlaytyp; { current entry layer }
    li:      mlaytyp; { layers index }
    l:       integer; { length }
    w:       integer; { width }
    cx:      integer; { center x }
    cy:      integer; { center y }
    r:       recptr;  { rectangle }
	 chksum:	 integer; { CIF checksum }
	 sepflg:	 boolean; { Boolean for prevdataus separator.}
    chksumc: integer; { comparision checksum }
    curcel:  celptr;  { current entry cell }
    i:       labinx;  { index for label }
    cp:      celptr;  { pointer for cell }
    lc:      celptr;  { last cell in list }
    dx, dy:  integer; { direction vectors }


{ convert to lower case }

function lcase(c: char): char;

begin

   if c in ['A'..'Z'] then { upper case }
      c := chr(ord(c)-ord('A')+ord('a')); { convert }
   lcase := c { return result }

end;

{ convert to upper case }

function ucase(c: char): char;

begin

   if c in ['a'..'z'] then { lower case }
      c := chr(ord(c)-ord('a')+ord('A')); { convert }
   ucase := c { return result }

end;

{ Compute checksum 1 char at a time.}

procedure sum(ch:char);

begin

   { Get rid of unwanted bits.}
   if (ch >= chr(128)) then ch := chr(ord(ch) - 128);
   if (ch > ' ') then begin { Is this a printing character? }

      chksum := chksum + ord(ch);
      sepflg := false

   end else if ((ch <> chr(0)) and (sepflg = false)) then begin

      chksum := chksum + 32; { Process the first }
      sepflg := true

   end

end;

{ check next character in file. Converts EOF to space }

function chknxt: char;

var c: char;

begin

   if eof(fcif) then c := ' '
   else c := fcif^;
   chknxt :=  c { return next character }

end;

{ get next character in file, with checksum }

procedure getnxt;

begin

   sum(chknxt); { add to checksum }
   if eoln(fcif) then lincnt := lincnt + 1;
   get(fcif)

end;

{ check end of file }

function chkeof: boolean;

begin

   chkeof := eof(fcif)

end;

{ skip spaces }

procedure skpspc;

begin

   repeat { skip spaces }

      if chkeof then error(eeof); { end of file }
      if chknxt = ' ' then getnxt { skip space }

   until not chkeof and (chknxt <> ' ') { no more spaces }

end;

{ skip comment }

procedure skpcmt;

begin

   getnxt; { skip character }
   while not chkeof and not (chknxt = ')') do
      { skip comment text }
      if chknxt = '(' then skpcmt { skip nested comment }
      else getnxt; { skip till ')' }
   if not chkeof and (chknxt = ')') then 
      getnxt { skip ')' }

end;

{ read number }

procedure readnum(var n: integer);

var s: integer;

begin

   s := 1; { set positive default }
   skpspc; { skip spaces }
   if not (chknxt in ['-', '+', '0'..'9']) then
      error(enume);
   if chknxt = '+' then getnxt { plus sign }
   else if chknxt = '-' then begin { minus sign }

      s := -1; { set negative }
      getnxt { skip '-' }

   end;
   n := 0; { clear result }
   if not (chknxt in ['-', '+', '0'..'9']) then
      error(enume);
   while chknxt in ['0'..'9'] do begin { read digits }

      n := n*10+ord(chknxt)-ord('0'); { scale and add digit }
      getnxt { get next character }

   end;
   n := n*s { set sign }   

end;

{ get label }

procedure getlab(var l: labtyp);

var i: labinx; { label index }

begin

   for i := 1 to labmax do l[i] := ' '; { clear result string }
   i := 1; { set 1st character }
   skpspc; { skip spaces }
   while (chknxt <> ' ') and (chknxt <> ';') do begin

      { gather label characters }
      if i = labmax then error(elabtl); { overflow }
      l[i] := lcase(chknxt); { place character }
      getnxt; { next character }
      i := i + 1 

   end
      
end;

{ print label (diagnostic) }

{procedure prtlab(var l: labtyp);

var i: labinx;

begin

   for i := 1 to labmax do if l[i] <> ' ' then
      write(l[i])

end;}

begin

   ef := false; { set end of file false }
   layer := mltnone; { set no layer defined }
   curcel := nil; { clear current cell }
   new(cp); { create top cell }
   celstk := cp; { set as first in list }
   cp^.next := nil; { clear next }
   { set top cell name to filename without extention }
   for i := 1 to labmax do cp^.name[i] := ' ';
   addext(name, '     '); { clear any extention }
   for i := 1 to labmax do cp^.name[i] := name[i];
   cp^.num := 0; { top is the "zero" cell }
   { clear Mosis layers }
   for li := mltcell to mltbnd do cp^.mclay[li] := nil; 
   cp^.a := 1; { set default a/b parameters,
                     to leave demensions as is }
   cp^.b := 1;
   cp^.bndset := false; { set bounds never set }
   lc := cp; { set as last cell }
   addext(name, '.cif '); { add .cif extention }
   if not exists(name) then error(ecifne); { not found }
   assign(fcif, name); { open file }
   reset(fcif);
   lincnt := 1; { clear line counter }
   getlab(labbuf); { peek for the MOSIS checksum intro }
   if labbuf = 'cif-checksum:       ' then begin

      readnum(chksumc); { get comparision checksum }
      readnum(n); { dispose of byte count }
      readln(fcif) { skip checksum line }

   end else begin

      { No checksum header: a non-MOSIS .cif that opens with a
        description comment rather than a cif-checksum: line. Rewind to
        the start and disable checksum verification, since there is no
        reference checksum to match against. }
      reset(fcif);
      lincnt := 1;
      onchk := true

   end;
   sepflg := true; { Set the separator flag.}
   chksum := 32; { Initial checksum value.}
   repeat { get commands }

      skpspc; { skip spaces }
      if not(lcase(chknxt) in ['p', 'b', 'r', 'w', 'l',
                          'd', 'c', '(', 'e', '0'..'9']) then
         error(einvcmd); { command not found }
      case lcase(chknxt) of { command start }

         'p', 'r', 'w': begin { unimplemented command }

            getnxt; { skip character }
            error(euicmd)

         end;

         '(': skpcmt; { comment }

         '0', '1', '2', '3', '4', '5',
         '6', '7', '8', '9': begin { extention command }

            readnum(n); { get number of command }
            if n = 9 then begin{ cell label command }

               getlab(cp^.name);
               { translate to upper case. This probabally will
                 not be nessary when ICD gets a decent lower
                 case font. }
               for i := 1 to labmax do 
                  cp^.name[i] := ucase(cp^.name[i])

            end else { skip command }
               while not chkeof and not (chknxt = ';') do
                  getnxt { skip till ';' }

         end;

         'b': begin { box }

            if layer = mltnone then { no layer to enter to }
               error(enalfe);
            getnxt; { skip character }
            readnum(l); { get length }
            readnum(w); { get width }
            readnum(cx); { get center x }
            readnum(cy); { get center y }
            cy := -cy; { correct y axis }
            skpspc; { skip  }
            if chknxt <> ';' then error(eorna);
            l := round((cp^.a*l)/cp^.b); { find scaled length }
            w := round((cp^.a*w)/cp^.b); { find scaled width }
            cx := round((cp^.a*cx)/cp^.b); { find scaled x }
            cy := round((cp^.a*cy)/cp^.b); { find scaled y }
            new(r); { get a new rectangle entry }
            r^.next := cp^.mclay[layer]; { link into database }
            cp^.mclay[layer] := r;
            r^.sx := round(cx - l/2); { set starting x } 
            r^.sy := round(cy - w/2); { set starting y }
            r^.ex := round(cx + l/2); { set ending x }
            r^.ey := round(cy + w/2); { set ending y }
            r^.celn := 0; { set isn't a cell }
            r^.celp := nil;
            r^.r := rm0 { no rotation }

         end; 

         'c': begin { cell instantiation }

            getnxt; { skip character }
            new(r); { get cell call entry }
            r^.next := cp^.mclay[mltcell]; { link into cells }
            cp^.mclay[mltcell] := r;
            r^.sx := 0; { clear offset }
            r^.sy := 0;
            r^.ex := 1; { clear multiplier }
            r^.ey := 1;
            readnum(r^.celn); { get cell number }
            r^.celp := nil; { clear cell pointer }
            r^.r := rm0; { set no rotation }
            skpspc; { skip spaces }
            while chknxt <> ';' do begin

               { perform transformations }
               if lcase(chknxt) = 'm' then begin { mirror }

                  getnxt; { skip character }
                  skpspc;
                  if not (lcase(chknxt) in ['x', 'y']) then
                     error(einvt);
                  if lcase(chknxt) = 'x' then begin 

                     { mirror x }
                     getnxt; { skip character }
                     { find resultant mirror for x }
                     r^.r := netmir(r^.r, rmm0);
                     r^.ex := -1 * r^.ex

                  end else begin 
            
                     { mirror y }
                     getnxt; { skip character }
                     { find resultant mirror for y }
                     r^.r := netmir(r^.r, rmm180);
                     r^.ex := -1 * r^.ex
   
                  end

               end else if lcase(chknxt) = 't' then begin

                  getnxt; { skip character }
                  readnum(n); { get x offset }
                  r^.sx := r^.sx + round((n*cp^.a)/cp^.b);
                  readnum(n); { get y offset }
                  n := -n; { correct y axis }
                  r^.sy := r^.sy + round((n*cp^.a)/cp^.b)

               end else if lcase(chknxt) = 'r' then begin

                  getnxt; { skip character }
                  readnum(dx); { get direction x }
                  readnum(dy); { get direction y }
                  if (dx <> 0) and (dy <> 0) then
                     error(erot);
                  { find requested rotation }
                  if dy < 0 then r^.r := netmir(r^.r, rm90)
                  else if dx < 0 then r^.r := netmir(r^.r, rm180)
                  else if dy > 0 then r^.r := netmir(r^.r, rm270)

               end else error(einvt);
               skpspc { skip spaces }

            end

         end;

         'd': begin { 'd' commands }

            getnxt; { skip character }
            skpspc; { skip spaces }
            if not (lcase(chknxt) in ['s', 'f', 'd']) then
               error(einvcmd);
            case lcase(chknxt) of { subcommand }

               's': begin { define cell start }

                  getnxt; { skip character }
                  if (cp <> celstk) then error(enestc);
                  new(cp); { create new cell }
                  lc^.next := cp; { link to end of list }
                  lc := cp; { set new end }
                  cp^.next := nil;
                  { clear Mosis layers }
                  for li := mltcell to mltbnd do cp^.mclay[li] := nil; 
                  cp^.a := 1; { set default a/b parameters,
                                    to leave demensions as is }
                  cp^.b := 1;
                  readnum(cp^.num); { get cell number }
                  if cp^.num <= 0 then error(einvcn); 
                  strnum(n, cp^.name); { convert cell number to name }
                  skpspc; { skip spaces }
                  if chknxt <> ';' then begin

                     { scale parameters exist }
                     readnum(cp^.a); { read scaling parameters } 
                     readnum(cp^.b)

                  end;
                  cp^.bndset := false { set bounds never set }

               end;

               'f': begin { define cell end }

                  getnxt; { skip character }
                  cp := celstk { return to top cell }

               end;

               'd': begin

                  getnxt; { skip character }
                  error(euicmd) { unimplemented command }

               end

            end

         end;
 
         'l': begin { layer }

            getnxt; { skip character }
            getlab(labbuf); { get layer name }
            if labbuf = 'cwg                 ' then 
               layer := mltwell
            else if labbuf = 'cwp                 ' then 
               layer := mltpwell
            else if labbuf = 'cwn                 ' then 
               layer := mltnwell
            else if labbuf = 'caa                 ' then 
               layer := mltactive
            else if labbuf = 'csg                 ' then 
               layer := mltselect
            else if labbuf = 'csp                 ' then 
               layer := mltpselect
            else if labbuf = 'csn                 ' then 
               layer := mltnselect
            else if labbuf = 'cpg                 ' then 
               layer := mltpoly
            else if labbuf = 'ccp                 ' then 
               layer := mltpcont
            else if labbuf = 'cca                 ' then 
               layer := mltacont
            else if labbuf = 'cmf                 ' then 
               layer := mltmet1
            else if labbuf = 'cva                 ' then 
               layer := mltvia
            else if labbuf = 'cms                 ' then 
               layer := mltmet2
            else if labbuf = 'cce                 ' then 
               layer := mltecont
            else if labbuf = 'cel                 ' then 
               layer := mltelect
            else if labbuf = 'cog                 ' then 
               layer := mltovg
            else if labbuf = 'xp                  ' then 
               layer := mltbnd
            else error(eunkly); { no layer match }
            if layer in [mltwell, mltselect, mltecont, 
                         mltelect] then error(elyns)
      
         end;

         'e': ef := true; { end of file }

      end;
      if not ef then begin { not end of file }

         skpspc; { skip spaces }
         if not (chknxt = ';') then error(escne);
         getnxt { skip ';' }

      end

   until ef; { until proper end of file }
   while not chkeof do getnxt; { skip rest of file }
   close(fcif); { close file }

   { Process the implied trailing separator.}

   if sepflg = false then chksum := chksum + 32;
   { check checksum matches calculated }
   if (chksum <> chksumc) and not onchk then 
      error(echksm) { mismatch }

end;

{**************************************************************

RATIONALIZE BOX

"rationalizes" a box. This means to eliminate duplicate 
versions of the same box.
The resulting box will have x1 <= x2, y1 <= y2.

**************************************************************}

procedure ratbox(var x1, y1, x2, y2: integer);

var t: integer;

begin

   { rationalize box }
   if x1 > x2 then 
      begin t := x1; x1 := x2; x2 := t end; 
   if y1 > y2 then 
      begin t := y1; y1 := y2; y2 := t end

end; 

{**************************************************************

ROTATE SINGLE POINT X

Rotate a single point for predefined figures.

**************************************************************}

function rotx(sx, sy, ex, ey: integer; { figure region }
              ox:             integer; { destination origin x }
              x, y:           integer; { point to rotate }
              r:              rotmod)  { rotation mode }
              : integer;               { rotated x }

begin

   case r of { rotate }

      rm0:    rotx := x-sx+ox; 
      rm90:   rotx := abs(ey-sy)-(y-sy)+ox; 
      rm180:  rotx := abs(ex-sx)-(x-sx)+ox; 
      rm270:  rotx := y-sy+ox;
      rmm0:   rotx := abs(ex-sx)-(x-sx)+ox; 
      rmm90:  rotx := abs(ey-sy)-(y-sy)+ox; 
      rmm180: rotx := x-sx+ox; 
      rmm270: rotx := y-sy+ox

   end

end;

{**************************************************************

ROTATE SINGLE POINT Y

Rotate a single point for predefined figures.

**************************************************************}

function roty(sx, sy, ex, ey: integer; { figure region }
              oy:             integer; { destination origin y }
              x, y:           integer; { point to rotate }
              r:              rotmod)  { rotation mode }
              : integer;               { rotated y }

begin

   case r of { rotate }

      rm0:    roty := y-sy+oy;
      rm90:   roty := x-sx+oy; 
      rm180:  roty := abs(ey-sy)-(y-sy)+oy; 
      rm270:  roty := abs(ex-sx)-(x-sx)+oy; 
      rmm0:   roty := y-sy+oy; 
      rmm90:  roty := abs(ex-sx)-(x-sx)+oy; 
      rmm180: roty := abs(ey-sy)-(y-sy)+oy; 
      rmm270: roty := x-sx+oy

   end

end;

{**************************************************************

FIND CELL ORIGIN CORRECTION FOR ROTATION

Finds the origin of a cell to be included in another cell, 
considering the rotations of both.

**************************************************************}

procedure corrot(    
                 { region of container cell }
                     x1, y1, x2, y2: integer;
                 { origin of container cell }
                     ox, oy:        integer;
                 { included cell origin }
                 var co:             point; 
                 { lengths of cell sides }
                     lx, ly:         integer;
                 { rotation of container cell }
                     rt:             rotmod; 
                 { rotation of included cell }
                     cr:             rotmod);

var sx, sy: integer;

begin

   sx := co.x; { save coordinates }
   sy := co.y;
   co.x := rotx(x1, y1, x2, y2, ox, sx, sy, rt); { find rotated coordinates }
   co.y := roty(x1, y1, x2, y2, oy, sx, sy, rt);
   { add corrections }
   if cr in [rm0, rm180, rmm0, rmm180] then
      case rt of { rotation }

      rm0:    ;
      rm90:   co.x := co.x-ly;
      rm180:  begin co.x := co.x-lx; co.y := co.y-ly end;
      rm270:  co.y := co.y-lx;
      rmm0:   co.x := co.x-lx; 
      rmm90:  begin co.x := co.x-ly; co.y := co.y-lx end;
      rmm180: co.y := co.y-ly;
      rmm270:
                                                        
   end else case rt of { rotation }

      rm0:    ;
      rm90:   co.x := co.x-lx;
      rm180:  begin co.x := co.x-ly; co.y := co.y-lx end;
      rm270:  co.y := co.y-ly;
      rmm0:   co.x := co.x-ly; 
      rmm90:  begin co.x := co.x-lx; co.y := co.y-ly end;
      rmm180: co.y := co.y-lx;
      rmm270:

   end

end;

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

procedure dointer(celp: celptr; ip: recptr);

var ipx1, ipy1, ipx2, ipy2: integer;    

{ check region intersection }

procedure chkintr(pc:                 recptr; { 1st region cell }
                  p:                  recptr; { 1st region layer }
                  { 1st region coordinates }
                  x1, y1, x2, y2:     integer;
                  cpc:                recptr; { 2nd region cell }
                  cp:                 recptr; { 2nd region layer }
                  { 2nd region coordinates }
                  cx1, cy1, cx2, cy2: integer); 

var l: recptr;  { list pointer }
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
         l^.sx := irx1; { place coordinates }
         l^.sy := iry1;
         l^.ex := irx2;
         l^.ey := iry2;
         { rationalize it }
         ratbox(l^.sx, l^.sy, l^.ex, l^.ey);
         { find color based on priority }
         if p^.typ = tmet2 then begin

            { metal 2 }
            l^.c := cyan; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := celp^.icdlay[iltism2]; { enter to met 2 intersection list }
            celp^.icdlay[iltism2] := l 
   
         end else if cp^.typ = tmet2 then begin
    
            { metal 2 }
            l^.c := cyan; { set color } 
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := celp^.icdlay[iltism2]; { enter to met 2 intersection list }
            celp^.icdlay[iltism2] := l 
   
         end else if p^.typ = tmet1 then begin
   
            { metal 1 }
            l^.c := blue; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := celp^.icdlay[iltism1]; { enter to met 1 intersection list }
            celp^.icdlay[iltism1] := l 

         end else if cp^.typ = tmet1 then begin
    
            { metal 1 }
            l^.c := blue; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := celp^.icdlay[iltism1]; { enter to met 1 intersection list }
            celp^.icdlay[iltism1] := l 
   
         end else if p^.typ = tpoly then begin
   
            { poly }
            l^.c := red; { set color }
            l^.itt := p^.typ; { set top layer type }
            if pc = nil then l^.ipt := p { set top layer }
            else l^.ipt := pc; { set top layer cell }
            l^.itb := cp^.typ; { set bottom layer type }
            if cpc = nil then l^.ipb := cp { set bottom layer }
            else l^.ipb := cpc; { set bottom layer cell }
            l^.next := celp^.icdlay[iltisply]; { enter to poly intersection list }
            celp^.icdlay[iltisply] := l 
   
         end else begin
    
            { poly }
            l^.c := red; { set color }
            l^.itt := cp^.typ; { set top layer type }
            if cpc = nil then l^.ipt := cp { set top layer }
            else l^.ipt := cpc; { set top layer cell }
            l^.itb := p^.typ; { set bottom layer type }
            if pc = nil then l^.ipb := p { set bottom layer }
            else l^.ipb := pc; { set bottom layer cell }
            l^.next := celp^.icdlay[iltisply]; { enter to poly intersection list }
            celp^.icdlay[iltisply] := l 
   
         end
   
      end

   end

end;

{ declared ahead }

procedure intcell(ipc:    recptr;  { intersect cell }
                  ip:     recptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;   
                  pc:     recptr;  { cell pointer } 
                  p:      celptr;  { cell sheet }
                  ox, oy: integer; { cell origin }
                  r:      rotmod); { cell rotation }
                  forward;

{ check cell list intersections }

procedure intfigc(ipc:    recptr;  { intersect cell }
                  ip:     recptr;  { intersect figure }
                  { region }
                  ipx1, ipy1, ipx2, ipy2: integer;    
                  d:      recptr;  { figure to process }
                  pc:     recptr;  { cell pointer }
                  p:      celptr;  { cell sheet }
                  ox, oy: integer; { cell origin }
                  rt:     rotmod); { cell rotation }

var x1, y1, x2, y2: integer; { layer holder }
    co:             point;   { cell origin }

begin

   if d^.typ = tcell then begin { subcell }

      co.x := d^.sx; { find net origin }
      co.y := d^.sy;
      corrot(p^.bndsx, p^.bndsy, p^.bndex, p^.bndey, ox, oy, co, 
             abs(d^.celp^.bndex-d^.celp^.bndsx)+1, 
             abs(d^.celp^.bndey-d^.celp^.bndsy)+1, rt, d^.r);
      { intersect with net rotation }
      intcell(ipc, ip, ipx1, ipy1, ipx2, ipy2, 
              pc, d^.celp, co.x, co.y, netmir(rt, d^.r));

   end else begin

      { find effective box }
      x1 := rotx(p^.bndsx, p^.bndsy, p^.bndex, p^.bndey, ox, 
                 d^.sx, d^.sy, rt); 
      y1 := roty(p^.bndsx, p^.bndsy, p^.bndex, p^.bndey, oy, 
                 d^.sx, d^.sy, rt);
      x2 := rotx(p^.bndsx, p^.bndsy, p^.bndex, p^.bndey, ox, 
                 d^.ex, d^.ey, rt); 
      y2 := roty(p^.bndsx, p^.bndsy, p^.bndex, p^.bndey, oy, 
                 d^.ex, d^.ey, rt); 
      ratbox(x1, y1, x2, y2); { rationalize }
      if ip^.typ = tcell then { process subcell }
         intcell(pc, d, x1, y1, x2, y2, 
                 ip, ip^.celp, ip^.sx, 
                 ip^.sy, ip^.r)
      else { test/generate intersection }
         chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2, 
                 pc, d, x1, y1, x2, y2)

   end

end;

{ cell intersections }

procedure intcell; { (ipc:    recptr; 
                      ip:     recptr; 
                      ipx1, ipy1, ipx2, ipy2: integer;    
                      pc:     recptr;
                      p:      celptr; 
                      ox, oy: integer; 
                      r:      rotmod); }

var d: recptr; 
    cr: region; { cell region }

begin

   if ip <> pc then begin { not intersecting a cell with itself }

      { find bounds of cell }
      cr.s.x := ox;
      cr.s.y := oy;
      if r in [rm0, rm180, rmm0, rmm180] then begin { normal }
      
         cr.e.x := ox + abs(p^.bndex - p^.bndsx);
         cr.e.y := oy + abs(p^.bndey - p^.bndsy)
      
      end else begin { on side }
      
         cr.e.x := ox + abs(p^.bndey - p^.bndsy);
         cr.e.y := oy + abs(p^.bndex - p^.bndsx)
      
      end;
      if (cr.e.x >= ipx1) and { intersects with target layer }
         (cr.s.x <= ipx2) and
         (cr.e.y >= ipy1) and 
         (cr.s.y <= ipy2)  then begin
   
         { do layers }
         d := p^.icdlay[iltmet2]; { index top of list }
         while d <> nil do begin { traverse }
   
            { intersect figure }
            intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, 
                    ox, oy, r); 
            d := d^.next { next entry }
   
         end;
         d := p^.icdlay[iltcont]; { index top of list }
         while d <> nil do begin { traverse }
   
            { intersect figure }
            intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, 
                    ox, oy, r); 
            d := d^.next { next entry }
   
         end;
         d := p^.icdlay[iltpmd]; { index top of list }
         while d <> nil do begin { traverse }
   
            { intersect figure }
            intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, 
                    ox, oy, r); 
            d := d^.next { next entry }
   
         end;
         { do subcells }
         d := p^.icdlay[iltcell]; { index top of list }
         while d <> nil do begin { traverse }
   
            { intersect figure }
            intfigc(ipc, ip, ipx1, ipy1, ipx2, ipy2, d, pc, p, 
                    ox, oy, r); 
            d := d^.next { next entry }
   
         end
   
      end

   end
   
end;

{ check standard intersections }

procedure intfig(ip: recptr; { intersect figure }
                 { region }
                 ipx1, ipy1, ipx2, ipy2: integer;
                 p: recptr); { intersecting figure }

begin

   if p^.typ = tcell then { process cell reference }
      intcell(nil, ip, ipx1, ipy1, ipx2, ipy2, 
              p, p^.celp, p^.sx, p^.sy, p^.r)
   else if ip^.typ = tcell then { process cell reference }
      intcell(nil, p, p^.sx, p^.sy, p^.ex, p^.ey, 
              ip, ip^.celp, ip^.sx, ip^.sy, ip^.r)
   else { test/generate intersection }
      chkintr(nil, ip, ipx1, ipy1, ipx2, ipy2,
              nil, p, p^.sx, p^.sy, p^.ex, p^.ey)

end;

{ intersect single list }

procedure intlst(ip: recptr; { intersect figure }
                 { region }
                 ipx1, ipy1, ipx2, ipy2: integer; 
                 p: recptr); { intersecting figure list }

begin

   while p <> nil do begin { traverse list }

      intfig(ip, ipx1, ipy1, ipx2, ipy2, p); { draw }
      p := p^.next { next entry }

   end

end;

begin

   if ip^.typ = tcell then begin { is cell }

      { find bounds of cell }
      ipx1 := ip^.sx;
      ipy1 := ip^.sy;
      if ip^.r in [rm0, rm180, rmm0, rmm180] then begin { normal }
   
         ipx2 := ip^.sx + abs(ip^.celp^.bndex - ip^.celp^.bndsx);
         ipy2 := ip^.sy + abs(ip^.celp^.bndey - ip^.celp^.bndsy)
   
      end else begin { on side }
       
         ipx2 := ip^.sx + abs(ip^.celp^.bndey - ip^.celp^.bndsy);
         ipy2 := ip^.sy + abs(ip^.celp^.bndex - ip^.celp^.bndsx)
   
      end

   end else begin { figure }

      ipx1 := ip^.sx; { set bounds }
      ipy1 := ip^.sy;
      ipx2 := ip^.ex;
      ipy2 := ip^.ey

   end;
   { find poly, metals and diff intersects }
   intlst(ip, ipx1, ipy1, ipx2, ipy2, celp^.icdlay[iltmet2]);
   intlst(ip, ipx1, ipy1, ipx2, ipy2, celp^.icdlay[iltcont]);
   intlst(ip, ipx1, ipy1, ipx2, ipy2, celp^.icdlay[iltpmd]);
   { find cell intersects }
   intlst(ip, ipx1, ipy1, ipx2, ipy2, celp^.icdlay[iltcell])

end;

{**************************************************************

CONVERT LAYERS

Converts the Mosis CIF layers to ICD format.

**************************************************************}

procedure lconvert;

var cp: celptr; { pointer for cells }

{ add layers together }

procedure addlay(    s:  recptr;  { source list }
                 var d:  recptr;  { destination list }
                     f:  figtyp); { type of figures in list }

var r: recptr; { rectangle pointers }

begin

   while s <> nil do begin { copy contents of list }

      new(r); { get a rectangle entry }
      r^ := s^; { copy contents }
      r^.typ := f; { set type }
      r^.next := d; { link into list }
      d := r;
      s := s^.next; { index next source entry }

   end

end;

{ "and" layers to destination }

procedure andlay(    a, b: recptr;  { source lists }
                 var d:    recptr;  { destination list }
                     f:    figtyp); { type of figures in list }

var p, r:                   recptr; { rectangle pointer }
    irx1, iry1, irx2, iry2: integer; { intersection holder }
    ff:                      boolean; { intersection flag }

begin

   while b <> nil do begin { traverse b }

      p := a; { index top of a }
      while p <> nil do begin { traverse a }

         { find intersection of rectangles }
         intersect(p^.sx, p^.sy, p^.ex, p^.ey, 
                   b^.sx, b^.sy, b^.ex, b^.ey,
                   irx1, iry1, irx2, iry2, ff);
         if ff then begin { "and" found, register }
  
            new(r); { get a rectangle entry }
            r^.typ := f; { set type }
            r^.sx := irx1; { set anded rectangle }
            r^.sy := iry1;
            r^.ex := irx2;
            r^.ey := iry2;
            r^.next := d; { link into list }
            d := r

         end;
         p := p^.next { index next entry a }

      end;
      b := b^.next { next entry b }

   end

end;

{ convert cell to ICD format and link all cell calls to cells }

procedure concel(cp: celptr);

var li:       ilaytyp; { index for layers }
    p:        recptr;  { rectangles pointer }
    cp1, cp2: celptr; { cell list pointer }

begin

   { clear destination layers }
   for li := iltcell to iltwell do cp^.icdlay[li] := nil;  
   { merge contact layers to single layer }   
   addlay(cp^.mclay[mltpcont], cp^.icdlay[iltcont], tcont);
   addlay(cp^.mclay[mltacont], cp^.icdlay[iltcont], tcont);
   { copy over wells, poly, metals, ccut, via, 
     which are equivalent }
   addlay(cp^.mclay[mltvia],   cp^.icdlay[iltvia],  tvia);
   addlay(cp^.mclay[mltpwell], cp^.icdlay[iltwell], tpwell);
   addlay(cp^.mclay[mltnwell], cp^.icdlay[iltwell], tnwell);
   addlay(cp^.mclay[mltpoly],  cp^.icdlay[iltpmd],  tpoly);
   addlay(cp^.mclay[mltmet1],  cp^.icdlay[iltpmd],  tmet1);
   addlay(cp^.mclay[mltmet2],  cp^.icdlay[iltmet2], tmet2);
   addlay(cp^.mclay[mltovg],   cp^.icdlay[iltovg],  tccut);
   { diffs are "and" of select p or n and the active mask }
   andlay(cp^.mclay[mltpselect], cp^.mclay[mltactive], 
          cp^.icdlay[iltpmd], tpdiff);
   andlay(cp^.mclay[mltnselect], cp^.mclay[mltactive], 
          cp^.icdlay[iltpmd], tndiff);
   { transfer cell calls }
   addlay(cp^.mclay[mltcell],  cp^.icdlay[iltcell], tcell);

   { the select and bonding layers are not required, but
     can be brought forward as comment boxes to make them
     visible. }

   if opselect then { output p-select }
      addlay(cp^.mclay[mltpselect], cp^.icdlay[iltfig], tbox);
   if onselect then { output n-select }
      addlay(cp^.mclay[mltnselect], cp^.icdlay[iltfig], tbox); 
   if obond then { output bonding layer }
      addlay(cp^.mclay[mltbnd], cp^.icdlay[iltfig], tbox);

   { link cell calls to cells }

   p := cp^.icdlay[iltcell]; { index top of list }
   while p <> nil do begin { traverse }

      { search match in cell list }
      cp1 := celstk; { index top of cell stack }
      cp2 := nil; { clear result }
      while cp1 <> nil do begin { traverse }
   
         if cp1^.num = p^.celn then cp2 := cp1; { found }
         cp1 := cp1^.next { next cell entry }

      end;
      if cp2 = nil then begin { not found }

         celnum := p^.celn; { place cell number }
         error(ecelnd)

      end;
      p^.celp := cp2; { place cell pointer }
      p := p^.next { next entry }

   end

end;

{ set cell bounds }

procedure bndcel(cp: celptr);

var li:                 ilaytyp; { index for layers }
    p:                  recptr;  { rectangles pointer }
    x1, y1, x2, y2:     integer; { bounds of cell holders }
    nx1, ny1, nx2, ny2: integer; { temps }

begin

   if not cp^.bndset then begin { bounds never set }

      p := cp^.icdlay[iltcell]; { index cell list top }
      while p <> nil do begin { traverse }
   
         { if cell has not been bounded, perform that }
         if not p^.celp^.bndset then bndcel(p^.celp);
         { load bounding box with transformations }
         { perform mirrors and offsets }
         x1 := p^.celp^.bndsx*p^.ex;
         y1 := p^.celp^.bndsy*p^.ey;
         x2 := p^.celp^.bndex*p^.ex;
         y2 := p^.celp^.bndey*p^.ey;
         { perform rotation }
         case p^.r of { rotation }
   
            rm0, rmm0: begin { rotate 0 }
   
               nx1 := x1;
               ny1 := y1;
               nx2 := x2;
               ny2 := y2
   
            end;
            rm90, rmm90: begin { rotate 90 }
   
               nx1 := -y1;
               ny1 := x1;
               nx2 := -y2;
               ny2 := x2
   
            end;
            rm180, rmm180: begin { rotate 180 }
   
               nx1 := -x1;
               ny1 := -y1;
               nx2 := -x2;
               ny2 := -y2
   
            end;
            rm270, rmm270: begin { rotate 270 }
   
               nx1 := y1;
               ny1 := -x1;
               nx2 := y2;
               ny2 := -x2
   
            end
   
         end;
         x1 := nx1; { copy back result }
         y1 := ny1;
         x2 := nx2;
         y2 := ny2;
         { perform offsets }
         x1 := x1+p^.sx;
         y1 := y1+p^.sy;
         x2 := x2+p^.sx;
         y2 := y2+p^.sy;
         ratbox(x1, y1, x2, y2); { rationalize }
         p^.sx := x1; { place origin }
         p^.sy := y1;
         p^.ex := x2;
         p^.ey := y2;
         p := p^.next { index next cell }
   
      end;
      { calculate sheet bounds }
      cp^.bndsx := 0; { set up bounds }
      cp^.bndsy := 0;
      cp^.bndex := 0;
      cp^.bndey := 0;
      for li := iltcell to iltwell do begin { do list }
   
         p := cp^.icdlay[li]; { index top of list }
         while p <> nil do begin { traverse list }

            if not cp^.bndset then begin 
   
               { bounds not set, set all }
               cp^.bndsx := p^.sx; { set all }
               cp^.bndsy := p^.sy;
               cp^.bndex := p^.ex;
               cp^.bndey := p^.ey;
               cp^.bndset := true { set bounds valid }
   
            end else begin { check individual bounds }
   
               if p^.sx < cp^.bndsx then cp^.bndsx := p^.sx;
               if p^.sy < cp^.bndsy then cp^.bndsy := p^.sy;
               if p^.ex > cp^.bndex then cp^.bndex := p^.ex;
               if p^.ey > cp^.bndey then cp^.bndey := p^.ey
   
            end;
            p := p^.next { next rectangle }
   
         end       
   
      end

   end
   
end;

{ scale to ICD }

procedure scale(cp: celptr);               

var li: ilaytyp; { index for layers }
    p:  recptr;  { rectangles pointer }

begin

   for li := iltcell to iltwell do begin { do list }

      p := cp^.icdlay[li]; { index top of list }
      while p <> nil do begin { traverse list }

         { scale }
         p^.sx := p^.sx*10;
         p^.sy := p^.sy*10;
         p^.ex := p^.ex*10;
         p^.ey := p^.ey*10;
         { rationalize result }
         ratbox(p^.sx, p^.sy, p^.ex, p^.ey);
         p := p^.next { next rectangle }

      end       

   end;
   cp^.bndsx := cp^.bndsx*10; { scale bounds }
   cp^.bndsy := cp^.bndsy*10;
   cp^.bndex := cp^.bndex*10;
   cp^.bndey := cp^.bndey*10;
   ratbox(cp^.bndsx, cp^.bndsy, cp^.bndex, cp^.bndey)

end;

{ "normalize" cell bounds }

procedure normal(cp: celptr);               

var li:       ilaytyp; { index for layers }
    p:        recptr;  { rectangles pointer }

begin

   { adjust sheet bounds to 0 } 
   for li := iltcell to iltwell do begin { do list }

      p := cp^.icdlay[li]; { index top of list }
      while p <> nil do begin { traverse list }

         { adjust to 0 and rotate y }
         p^.sx := p^.sx-cp^.bndsx;
         p^.sy := p^.sy-cp^.bndsy;
         p^.ex := p^.ex-cp^.bndsx;
         p^.ey := p^.ey-cp^.bndsy;
         { rationalize result }
         ratbox(p^.sx, p^.sy, p^.ex, p^.ey);
         p := p^.next { next rectangle }

      end       

   end;
   { adjust the bounds themselves }
   cp^.bndex := cp^.bndex-cp^.bndsx;
   cp^.bndey := cp^.bndey-cp^.bndsy;
   cp^.bndsx := 0; { and clear the starting bounds }
   cp^.bndsy := 0

end;

{ intersect cell }

procedure intercell(cp: celptr);               

procedure interlist(p: recptr);

begin

   while p <> nil do begin { traverse }

      dointer(cp, p); { intersect }
      p := p^.next { next figure }

   end

end;

begin

   { intersect all required lists }
   interlist(cp^.icdlay[iltmet2]);
   interlist(cp^.icdlay[iltcont]);
   interlist(cp^.icdlay[iltpmd]);
   interlist(cp^.icdlay[iltcell])

end;

begin

   { perform cell convertion to ICD format }
   cp := celstk; { index cell list }
   while cp <> nil do begin { traverse }

      concel(cp); { convert cell }
      cp := cp^.next { next entry }

   end;
   { bound cells }
   cp := celstk; { index cell list }
   while cp <> nil do begin { traverse }

      bndcel(cp); { bound }
      cp := cp^.next { next entry }

   end;
   { scale to ICD }
   cp := celstk; { index cell list }
   while cp <> nil do begin { traverse }

      scale(cp); { scale }
      cp := cp^.next { next entry }

   end;
   { normalize cells to 0 origin }
   cp := celstk; { index cell list }
   while cp <> nil do begin { traverse }

      normal(cp); { normalize cell }
      cp := cp^.next { next entry }

   end;
   { intersect cells }
   cp := celstk; { index cell list }
   while cp <> nil do begin { traverse }

      intercell(cp); { intersect cell }
      cp := cp^.next { next entry }

   end

end;

{**************************************************************

SAVE CELL

Saves the cell data in ICD format.

**************************************************************}

procedure savecel;

var i:    labinx;  { index for label }
    fcel: bytfil;  { file }
    li:   ilaytyp; { layer index }
    p:    recptr;  { rectangle pointer }
    c:    integer; { figures counter }
    cp:   celptr;  { cell list pointer }

procedure write32(i: integer); { write 32 bit number as bytes }

var t, s: integer;

begin

   { set sign }
   if i < 0 then s := 128 else s := 0;
   i := abs(i); { remove sign }
   t := i div 16777216; { high byte }
   write(fcel, t+s); { with sign }
   i := i - (t * 16777216); { high middle }
   t := i div 65536;
   write(fcel, t);
   i := i - (t * 65536); { low middle }
   t := i div 256;
   write(fcel, t);
   i := i - (t * 256); { low }
   write(fcel, i)

end;

{ find number of referenced cell }

function celnum(sp: celptr): integer;

var cp: celptr;  { cell pointer }
    c:  integer; { count }

begin

   c := 1; { clear count }
   cp := celstk; { index top of cell list }
   while sp <> cp do 
      begin c := c + 1; cp := cp^.next end;
   celnum := c { return result }

end;

{ output figures }

procedure wrtfigs(sl: recptr);

begin

   while sl <> nil do begin { write schematic figures }
   
      write(fcel, ord(sl^.typ)); { output figure type }
      if sl^.typ = tinter then begin { intersection }

         { intersection layer }
         write32(sl^.sx); { starting }
         write32(sl^.sy); 
         write32(sl^.ex); { ending }
         write32(sl^.ey);
         write(fcel, ord(sl^.c)); { color }
         write(fcel, ord(sl^.itt)); { output figure type top }
         write(fcel, ord(sl^.ln)); { output layer number }
         write32(sl^.fn); { output figure number }
         write(fcel, ord(sl^.itb)); { output figure type bottom }
         write(fcel, ord(sl^.ln)); { output layer number }
         write32(sl^.fn) { output figure number }

      end else if sl^.typ = tcell then begin { cell call }

         write32(sl^.sx); { output origin }
         write32(sl^.sy);
         write32(celnum(sl^.celp)); { output cell number }
         write(fcel, ord(ctlay)); { output cell type }
         write(fcel, ord(sl^.r)) { output rotation }

      end else begin { other layer }

         { output box or layer }
         write32(sl^.sx); { starting }
         write32(sl^.sy); 
         write32(sl^.ex); { ending }
         write32(sl^.ey)

      end;
      sl := sl^.next { link next entry }

   end;
   write(fcel, 0) { terminate figure list }

end;

{ output sheet }

procedure wrtsht(cp: celptr);

begin

   { output bounding box }
   write(fcel, ord(cp^.bndset)); { output set/unset status }
   write32(cp^.bndsx); { output bounding box }
   write32(cp^.bndex);
   write32(cp^.bndsy);
   write32(cp^.bndey);
   write(fcel, ord(cp^.bndset)); { output set/unset status }
   write32(cp^.bndsx); { output symbol bounding box }
   write32(cp^.bndex);
   write32(cp^.bndsy);
   write32(cp^.bndey);
   write(fcel, 0); { output null node list }
   write(fcel, 0); { output null bus list }
   wrtfigs(cp^.icdlay[iltcell]); { write cell layer }
   wrtfigs(cp^.icdlay[iltfig]);  { write comment/schema layer }
   wrtfigs(cp^.icdlay[iltovg]);  { write overglass cuts layer }
   wrtfigs(cp^.icdlay[iltvia]);  { write via layer }
   wrtfigs(cp^.icdlay[iltmet2]); { write met2 layer }
   wrtfigs(cp^.icdlay[iltcont]); { write contact layer }
   wrtfigs(cp^.icdlay[iltpmd]);  { write poly/metals, diff layer }
   wrtfigs(cp^.icdlay[iltwell]); { write wells layer }
   wrtfigs(cp^.icdlay[iltism2]); { write met 2 intersections layer }
   wrtfigs(cp^.icdlay[iltism1]); { write met 1 intersections layer }
   wrtfigs(cp^.icdlay[iltisply]) { write poly intersections layer }

end;

begin

   { cross reference database }
   cp := celstk; { index cell list }
   while cp <> nil do begin { traverse }

      for li := iltcell to iltwell do begin

         p := cp^.icdlay[li]; { index list top }
         c := 1;
         while p <> nil do begin { traverse }

            p^.ln := li; { place layer }
            p^.fn := c; { place ordinal number }
            p := p^.next { next entry }

         end

      end;
      cp := cp^.next { next cell }

   end;
   addext(name, '.cel '); { add .cel extention }
   assign(fcel, name); { open output file }
   rewrite(fcel);
   write(fcel, ord('M')); { write signature }
   write(fcel, ord('C'));
   write(fcel, ord('F'));
   write(fcel, ord(cceldir)); { mark cell directory }
   cp := celstk; { index top of cell list }
   while cp <> nil do begin { output cell names }
         
      c := 0; { count cellname characters }
      for i := 1 to 8 do { only 8 characters output }
         if cp^.name[i] <> ' ' then c := c + 1; 
      write(fcel, c); { output }
      { output cellname }
      for i := 1 to 8 do 
         if cp^.name[i] <> ' ' then write(fcel, ord(cp^.name[i]));
      cp := cp^.next { next cell }
   
   end;
   write(fcel, 0); { mark end of section } 
   cp := celstk; { index top of cell list }
   while cp <> nil do begin { output cells }

      write(fcel, ord(ccell)); { output cell marker }
      write(fcel, ord(cclayout)); { mark layout section }
      wrtsht(cp); { output sheet contents }
      write(fcel, ord(ccterm)); { terminate cell }
      cp := cp^.next { next cell }

   end;
   write(fcel, ord(ccfterm)); { terminate file }
   close(fcel) { close file }

end;

begin

   opselect := false; { set no output p-select }
   onselect := false; { set no output n-select }
   obond := false; { set no output bonding layer }
   onchk := false; { set verify checksum }
   lincnt := 0; { set line counter invalid }
   writeln('MOSIS specific .CIF to .CEL converter vs. 1.0 ', 
           'Copyright (C) S. A. Moore');
   writeln;
   getcml; { get command line }
   paropt; { parse options }
   getfnm(name); { get filename of .CIF }
   paropt; { parse options }
   writeln('Loading .CIF file');
   loadcif; { load .CIF file to database }
   lincnt := 0; { set line counter invalid }
   writeln('Performing layer conversion');
   lconvert; { convert layers to ICD form }
   writeln('Outputting .CEL file');
   savecel; { save .cel file }
  
   writeln('Function complete');

   99: { exit program }

end.

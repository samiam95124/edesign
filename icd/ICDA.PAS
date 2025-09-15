module icda;

uses {$U common.j} common;

{$I \svs\include\psyscall.inc } { for intdos function }

{ draw line real }
procedure liner(x1, y1, x2, y2: integer; c: color; 
                r: region); external; 
procedure redraw; external; { redraw screen }
procedure butina(b: buttyp); external; { set button inactive }
{ place string }
procedure plcstr(x, y: integer; s: butstr; l: btsinx; f: color;
                 b: color; p: boolean); external;
{ draw line }
procedure line(vp: viewport; x1, y1, x2, y2: integer; c: color); external;
{ update button }
procedure updbut(b: buttyp); external;
procedure setcur; external; { draw cursor into place }
procedure rescur; external; { remove cursor }
{ draw pie real }
procedure pier(xc, yc, r: integer; c: color; cr: region); external;
{ set bounding box limits }
procedure setbound(x, y: integer); external;
{ set symbol bounding box limits }
procedure setsbound(x, y: integer); external;
procedure bound; external; { go to the bounding box }
{ draw filled block }
procedure block(vp: viewport; x1, y1, x2, y2: integer; c: color); external;
procedure butact(b: buttyp); external; { set button active }
procedure dispsht; external; { display current sheet }
{ calculate real distance }
function realdist(d, s: integer): integer; external;
procedure dispcell; external; { display current cell }
{ check bounds set }
function boundset(sp: shtptr): boolean; external;
procedure edtlibv; external; { edit library button } 
{ check point in active area }
function inactive(p: point): boolean; external;
procedure chktar; external; { check target update }
{ place message string }
procedure plcmsg(m: msgtyp; c: color); external;
procedure plcchr(x, y: integer; c: char; f, b, p: color; l, r: boolean);
          external; { place character }
procedure iniptr; external; { initalize pointer device }
procedure updptr; external; { update pointer device }
function gettim: integer; cexternal; { get current system time }
function tan(r: real): real; external; { find tangent of angle }
{}
{**************************************************************

FIND ELAPSED TIME

Given a set point in time, finds the difference between that
time and the present time, or the time elapsed since.
Valid as long as the time elapsed is less than 24 hours.
Exact accuracy depends on the particular computer.
Time is given in hundreths of a second.

**************************************************************}

function elapsed(t: integer): integer;

var ct: integer; { current time }
    d:  boolean; { done flag }

begin

   ct := gettim; { get current time }
   if ct >= t then t := ct-t { find time forward }
   else t := t-ct; { find time backwards }
   elapsed := t { return result }

end;
{}
{**************************************************************

WAIT TIME PERIOD

Waits the given time period, with the time given in hundreths
of seconds. Valid as long as the time period is not longer
than one day.
Exact accuracy may vary depending on computer, but you will
get AT LEAST the time you ask for.

**************************************************************}

procedure wait(t: integer);

var rt: integer; { reference time }

begin

   rt := gettim; { get time now for reference }
   while elapsed(rt) < t do { nothing }

end;
{}
{**************************************************************

GET FILES LIST

Gets a list of files matching the given specification.
This routine is very dependant on both DOS and SVS Pascal.
Presently, no error checking is done.

**************************************************************}

procedure getlst(    fn: filnam;  { search file specification }
                 var fp: filptr); { result list }

label 99;

type byte   = -128..127;
     word   = -32768..32767;
     dtaptr = ^dtarec;
     dtarec = record { returned data }
    
                 _0, _1, _2, _3, _4, _5, _6, _7, _8, _9,
                 _10, _11, _12, _13, _14, _15, _16, _17,
                 _18, _19, _20: byte;
                 fa: byte;    { attribute of matched file }
                 ft: word;    { file time }
                 fd: word;    { file date }
                 fs: integer; { file size }
                 fn: filnam   { file name }

              end;

var inregs, outregs: syscallregs;
    i: longint;
    s:   filnam; { file string holder }
    cv:  record { general pointer to integer converter }

            case integer of

               0: (p: ^integer); { pointer }
               1: (i: integer)   { integer }

         end;
    ba:  record { return buffer address }

            case integer of 

               0: (p: dtaptr); { buffer address pointer }
               1: (i: integer) { buffer address holder }

         end;
    dta: dtarec; { returned data }
   
function intdos(var inregs,outregs: syscallregs): longint; cexternal;

procedure entnam;

var i: filinx; { index for filename }
    p: filptr; { pointer for filename entries }

begin

   new(p); { get a new entry }
   p^.next := fp; { link into list }
   fp := p;
   p^.name := '             '; { clear filename }
   { copy filename from buffer }
   i := 1;
   while ba.p^.fn[i] <> chr(0) do begin

      p^.name[i] := ba.p^.fn[i];
      i := i + 1

   end

end;

begin

   fn[13] := chr(0); { terminate filename }
   fp := nil; { clear result list }
   inregs.ah := $2f;
   i := intdos(inregs, outregs);
   ba.i := outregs.ebx; { place buffer address }
   inregs.ah := $4e;
   inregs.cx := 0;
   cv.p := @fn; { convert string }
   inregs.edx := cv.i; { place address }
   i := intdos(inregs, outregs); { search first match }
   if outregs.eax <> 0 then goto 99; { terminate on error }
   entnam; { create list entry for this name }
   repeat { subsequent files }

      inregs.ah := $4f;
      inregs.edx := cv.i; { place address }
      i := intdos(inregs, outregs); { search next match }
      if outregs.eax <> 0 then goto 99; { terminate on error }
      entnam { create list entry for this name }

   until outregs.eax <> 0; { error occurs }

   99:

end;
{}
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
{}
{**************************************************************

INITALIZE BUTTON ARRAY

Loads all the button descriptors into the button array.

**************************************************************}

procedure inibut;

var i: buttyp; { index for buttons }

{ set up single botton entry }

procedure plcbut(ox, oy: integer;  { screen location }
                 st:     butstr;   { string }
                 ln:     btsinx;   { length of button }
                 b:      buttyp;   { button code }
                 ms:     modset;   { applicable screen set }
                 caf:    color;    { "active" color foreground }
                 cab:    color;    { "active" color backround }
                 cif:    color;    { "inactive" color foreground }
                 cib:    color;    { "inactive" color backround }
                 lc:     loctyp;   { location }
                 t:      distyp;   { appearance }
                 fm:     formset); { placement format }

var w: integer;
    i: btsinx;

begin

   { find total pixel width of string }
   w := 11; { set margin width }
   for i := 1 to ln do w := w+alphal[ord(st[i])]+1; 
   with button[b] do begin

      r.s.x   := ox; { place origin }
      r.s.y   := oy;
      r.e.x   := ox+w-1; { place end }
      r.e.y   := oy+23-1;
      s   := st; { place button string }
      l   := ln; { place button length }
      m   := w;     { place minimum width }
      act := false; { set button inactive }
      dis := false; { set button not disabled }
      alt := false; { set not on alert }
      sm  := ms;    { set screen modes }
      acf := caf;   { set "active" color foreground }
      acb := cab;   { set "active" color backround }
      icf := cif;   { set "inactive" color foreground }
      icb := cib;   { set "inactive" color backround }
      loc := lc;    { set location }
      typ := t;     { appearance mode }
      fmt := fm     { placement mode }

   end

end;
   
begin   

   { clear unused buttons }
   for i := bnull to bdisplay do 
      begin button[i].r.s.x := 0; button[i].r.s.y := 0 end;
   { define right side buttons }
   plcbut(909,  156, 'In      ', 2, bin,
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);       
   plcbut(936,  156, 'Out     ', 3, bout,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);      
   plcbut(916,  131, 'Pan     ', 3, bpan,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(982,  131, 'Full    ', 4, bbound, 
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);    
   plcbut(976,  156, 'Back    ', 4, bback,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(915,  181, 'A       ', 1, bviewa, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(940,  181, 'B       ', 1, bviewb, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(964,  181, 'C       ', 1, bviewc, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(988,  181, 'D       ', 1, bviewd, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(960,  160, 'E       ', 1, bviewe, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(976,  160, 'F       ', 1, bviewf, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(992,  160, 'G       ', 1, bviewg, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(1008, 160, 'H       ', 1, bviewh, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(905,  206, 'Dots    ', 4, bdots,  
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []); 
   plcbut(951,  206, '+000.00M', 8, bdotsv, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);    
   plcbut(915,  232, 'A       ', 1, bdotsva, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(940,  232, 'B       ', 1, bdotsvb,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(965,  232, 'C       ', 1, bdotsvc,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(988,  232, 'D       ', 1, bdotsvd,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(960,  208, 'E       ', 1, bdotsve,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(976,  208, 'F       ', 1, bdotsvf,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(992,  208, 'G       ', 1, bdotsvg,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(1008, 208, 'H       ', 1, bdotsvh,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(904,  257, 'Lines   ', 5, blines,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []); 
   plcbut(951,  257, '+000.00M', 8, blinev,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);   
   plcbut(915,  282, 'A       ', 1, blineva,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(940,  282, 'B       ', 1, blinevb,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(965,  282, 'C       ', 1, blinevc,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(988,  282, 'D       ', 1, blinevd,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(960,  256, 'E       ', 1, blineve,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(976,  256, 'F       ', 1, blinevf,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(992,  256, 'G       ', 1, blinevg,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(1008, 256, 'H       ', 1, blinevh,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(904,  307, 'Undo    ', 4, bundo,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);     
   plcbut(904,  332, 'Redo    ', 4, bredo,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(899,  357, 'Save    ', 4, bsaveb,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);    
   plcbut(943,  357, 'Cut     ', 3, bcutb,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(976,  357, 'Paste   ', 5, bpasteb,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);   
   plcbut(915,  382, 'A       ', 1, bblka,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(940,  382, 'B       ', 1, bblkb,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(964,  382, 'C       ', 1, bblkc,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(989,  382, 'D       ', 1, bblkd,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(960,  352, 'E       ', 1, bblke,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(976,  352, 'F       ', 1, bblkf,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(992,  352, 'G       ', 1, bblkg,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(1008, 352, 'H       ', 1, bblkh,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(900,  532, 'Del     ', 3, bdelete,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);   
   plcbut(952,  532, 'Rip     ', 3, bdeleten,   
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, []);   
   plcbut(900,  582, 'Up      ', 2, bup,        
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, [ftlnxt]);
   plcbut(932,  582, 'Dwn     ', 3, bdown,      
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(908,  557, 'Mir     ', 3, birmir,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(986,  532, '0       ', 1, bir0,       
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(997,  557, '90      ', 2, bir90,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(982,  582, '180     ', 3, bir180,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(962,  557, '270     ', 3, bir270,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(967,  657, 'Name    ', 4, bname,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]);     
   plcbut(912,  657, 'Trc     ', 3, btrace,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);    
   plcbut(910,  682, '        ', 8, bnamev,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, fld, [ftlnxt]);
   plcbut(981,  682, '000     ', 3, bnord,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(907,  707, 'Cel     ', 3, bplsym,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(907,  732, 'Psch    ', 4, bplsch,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(981,  708, 'Erc     ', 3, berc,       
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);      
   plcbut(949,  307, 'Snap    ', 4, bsnap,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(949,  332, 'Any     ', 3, bany,       
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(992,  307, '45      ', 2, b45,        
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);       
   plcbut(992,  332, '90      ', 2, b90,        
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);       
   plcbut(902,  457, 'Line    ', 4, bline,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);     
   plcbut(900,  507, 'Bline   ', 5, bbline,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(941,  457, 'Box     ', 3, bbox,       
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);      
   plcbut(961,  507, 'Bbox    ', 4, bbbox,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(903,  482, 'Cir     ', 3, bcircle,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);   
   plcbut(946,  482, 'Arc     ', 3, barc,       
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(979,  457, 'Wire    ', 4, bwire,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]);     
   plcbut(984,  482, 'Bus     ', 3, bbus,       
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);      
   plcbut(908,  607, 'Junc    ', 4, bjunction,  
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]); 
   plcbut(950,  607, '+000.00M', 8, bjuncv,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(908,  632, 'Conn    ', 4, bconnect,   
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(950,  632, '+000.00M', 8, bconnv,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(905,  407, 'Text    ', 4, btext,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(951,  407, '+000.00M', 8, btsizv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);     
   plcbut(916,  432, 'A       ', 1, btexta,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(940,  432, 'B       ', 1, btextb,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(965,  432, 'C       ', 1, btextc,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(989,  432, 'D       ', 1, btextd,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(960,  400, 'E       ', 1, btexte,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(976,  400, 'F       ', 1, btextf,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(992,  400, 'G       ', 1, btextg,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(1008, 400, 'H       ', 1, btexth,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   { layout specific buttons }
   plcbut(896,  560, 'Met 1   ', 5, bmet1,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  560, 'Vis     ', 3, bmet1vis,   
          [smlayout], black, lblue,  black, white, right, but, []);
   plcbut(896,  576, 'Met 2   ', 5, bmet2,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  576, 'Vis     ', 3, bmet2vis,   
          [smlayout], black, lcyan,  black, white, right, but, []);
   plcbut(896,  592, 'Poly    ', 4, bpoly,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  592, 'Vis     ', 3, bpolyvis,   
          [smlayout], black, lred,   black, white, right, but, []);
   plcbut(896,  608, 'Via     ', 3, bvia,       
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  608, 'Vis     ', 3, bviavis,    
          [smlayout], black, gray,   black, white, right, but, []);
   plcbut(896,  624, 'Cont    ', 4, bcont,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  624, 'Vis     ', 3, bcontvis,   
          [smlayout], white, black,  black, white, right, but, []);
   plcbut(896,  640, 'Ndiff   ', 5, bndiff,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  640, 'Vis     ', 3, bndiffvis,  
          [smlayout], black, green,  black, white, right, but, []);
   plcbut(896,  656, 'Pdiff   ', 5, bpdiff,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  656, 'Vis     ', 3, bpdiffvis,  
          [smlayout], black, magenta, black, white, right, but, []);
   plcbut(896,  672, 'Nwell   ', 5, bnwell,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  672, 'Vis     ', 3, bnwellvis,  
          [smlayout], black, yellow, black, white, right, but, []);
   plcbut(896,  688, 'Pwell   ', 5, bpwell,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  688, 'Vis     ', 3, bpwellvis,  
          [smlayout], black, brown,  black, white, right, but, []);
   plcbut(896,  704, 'Ccut    ', 4, bccut,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(976,  704, 'Vis     ', 3, bccutvis,   
          [smlayout], black, dwhite, black, white, right, but, []);
   plcbut(896,  720, 'Insides ', 7, binsides,   
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(896,  736, 'Place   ', 5, bplace,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(896,  752, 'Drc     ', 3, bdrc,       
          [smlayout], black, lgreen, black, yellow, right, but, []);
   { simulator specific buttons }
   plcbut(896,  496, 'Dwave   ', 5, bdwave,     
          [smsimulate], black, lgreen, black, yellow, right, but, []);
   plcbut(896,  512, 'Awave   ', 5, bawave,     
          [smsimulate], black, lgreen, black, yellow, right, but, []);
   { define top side buttons }
   plcbut(256,  0,   'Symbol  ', 6, bsymbol,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(352,  0,   'Schemat ', 7, bschema,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);   
   plcbut(464,  0, 'Layout  ', 6, blayout,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);   
   plcbut(560,  0, 'Simulate', 8, bsimulate,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []); 
   plcbut(0,    32, 'Load    ', 4, bload,  
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(64,   32, 'Save    ', 4, bsave,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(128,  32, '        ', 8, bfname,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(0,    48, 'Newfile ', 7, bnew,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);      
   plcbut(128,  48, '        ', 8, bcname, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(0,    64, 'Files   ', 5, bdisplay,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);  
   plcbut(128,  64, 'Newcell ', 7, bnewc,   
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(128,  80, 'Print   ', 5, bprint,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(0,    80, 'Cells   ', 5, bcells,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(0,    96, 'Exit    ', 4, bexit,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(0,    112, 'LAST    ', 4, blast,   
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(64,   112, 'NEXT    ', 4, bnext,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(256,  32, '        ', 8, blibv,    
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(256,  48, '        ', 8, bliba, 
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(256,  64, '        ', 8, blibb,  
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(256,  80, '        ', 8, blibc,  
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(256,  96, '        ', 8, blibd,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(384,  32, '        ', 8, bcelv,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(384,  48, '        ', 8, bcela,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(384,  64, '        ', 8, bcelb,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(384,  80, '        ', 8, bcelc,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(384,  96, '        ', 8, bceld,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(256,  16, 'Proximty', 8, bprox,      
          [{smschema, smsymbol, smlayout, smsimulate}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(512,  32, 'Nmos    ', 4, bnmos,      
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(592,  32, 'Pmos    ', 4, bpmos,      
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(512,  48, 'Res     ', 3, bres,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(560,  48, 'Cap     ', 3, bcap,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(608,  48, 'Diode   ', 5, bdiode,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(512,  64, 'Vdd     ', 3, bvdd,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(592,  64, 'Vss     ', 3, bvss,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(651,  52, 'Ruler   ', 5, bruler,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);    
   plcbut(703,  52, '+000.00M', 8, brulerv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(651,  77, '    X   ', 5, brulx,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(703,  77, '+000.00M', 8, brulxv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(651,  102, '    Y   ', 5, bruly,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(703,  102, '+000.00M', 8, brulyv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(771,  10, 'Pos X   ', 5, bcposx,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(825,  10, '+000.00M', 8, bcposxv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(772,  31, '    Y   ', 5, bcposy,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(825,  31, '+000.00M', 8, bcposyv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(772,  52, 'Org X   ', 5, borgx,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(825,  52, '+000.00M', 8, borgxv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(772,  77, '    Y   ', 5, borgy,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(825,  77, '+000.00M', 8, borgyv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(772,  102, 'Scale   ', 5, bscl,       
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(825,  102, '00000   ', 8, bsclv,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(432,  16, 'Rul time', 8, brtime,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(560,  16, '+000.00M', 8, brtimev,   
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(432,  32, 'Rul volt', 8, brvolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(560,  32, '+000.00M', 8, brvoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(432,  48, 'Pos time', 8, bctime,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(560,  48, '+000.00M', 8, bctimev,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(432,  64, 'Pos volt', 8, bcvolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(560,  64, '+000.00M', 8, bcvoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(432,  80, 'Org time', 8, botime,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(560,  80, '+000.00M', 8, botimev,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(432,  96, 'Org volt', 8, bovolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(560,  96, '+000.00M', 8, bovoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   { buttons for printer control pop-up }
   plcbut(448,  416, '+000.00M', 8, bmaxx,      
          [smprint], black, lgreen, black, yellow, none, fld, []);      
   plcbut(448,  432, '+000.00M', 8, bmaxy,  
          [smprint], black, lgreen, black, yellow, none, fld, []); 
   plcbut(448,  448, '+000.00M', 8, boffx,   
          [smprint], black, lgreen, black, yellow, none, fld, []);
   plcbut(448,  464, '+000.00M', 8, boffy,   
          [smprint], black, lgreen, black, yellow, none, fld, []); 
   plcbut(448,  544, 'A       ', 1, bseta, 
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(464,  544, 'B       ', 1, bsetb,   
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(480,  544, 'C       ', 1, bsetc,  
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(496,  544, 'D       ', 1, bsetd,     
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(512,  544, 'E       ', 1, bsete,    
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(528,  544, 'F       ', 1, bsetf,    
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(544,  544, 'G       ', 1, bsetg,   
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(560,  544, 'H       ', 1, bseth,  
          [smprint], black, lgreen, black, yellow, none, but, []); 
   plcbut(0,    0,   '        ', 0, bmbtop,    
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbleft,   
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbright,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbottom, 
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtoplt,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtopll,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtoprt,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbtoprr,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotlb,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotll,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotrb,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmbbotrr,  
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bctrl,     
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmovew,    
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmin,      
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 
   plcbut(0,    0,   '        ', 0, bmax,      
          [smsymbol, smschema, smlayout, smsimulate, smprint], 
          white, white, white, white, none, cust, []); 

end;
{}
{**************************************************************

PLACE MOVE BUTTONS

Places the location of the move buttons for the present
window, and initalizes these buttons.

**************************************************************}

procedure plcmovb;

{ set up single botton entry }

procedure plcbut(b:              buttyp;   { button to place }
                 x1, y1, x2, y2: integer); { button rectangle }

begin

   with button[b] do begin

      r.s.x   := x1; { place origin }
      r.s.y   := y1;
      r.e.x   := x2; { place end }
      r.e.y   := y2

   end

end;

begin

   plcbut(bmbtop,    curwin^.r.s.x+25,    curwin^.r.s.y, 
                     curwin^.r.e.x-25,    curwin^.r.s.y+2+5-1);
   plcbut(bmbleft,   curwin^.r.s.x,       curwin^.r.s.y+25, 
                     curwin^.r.s.x+2+5-1, curwin^.r.e.y-25);
   plcbut(bmbright,  curwin^.r.e.x-2-5+1, curwin^.r.s.y+25,
                     curwin^.r.e.x,       curwin^.r.e.y-25);
   plcbut(bmbbottom, curwin^.r.s.x+25,    curwin^.r.e.y-2-5+1,
                     curwin^.r.e.x-25,    curwin^.r.e.y);
   plcbut(bmbtoplt,  curwin^.r.s.x,       curwin^.r.s.y,
                     curwin^.r.s.x+25,    curwin^.r.s.y+2+5-1);
   plcbut(bmbtopll,  curwin^.r.s.x,       curwin^.r.s.y,
                     curwin^.r.s.x+2+5-1, curwin^.r.s.y+25);
   plcbut(bmbtoprt,  curwin^.r.e.x-25,    curwin^.r.s.y,
                     curwin^.r.e.x,       curwin^.r.s.y+2+5-1);
   plcbut(bmbtoprr,  curwin^.r.e.x-2-5+1, curwin^.r.s.y,
                     curwin^.r.e.x,       curwin^.r.s.y+25);
   plcbut(bmbbotlb,  curwin^.r.s.x,       curwin^.r.e.y-2-5+1,
                     curwin^.r.s.x+25,    curwin^.r.e.y);
   plcbut(bmbbotll,  curwin^.r.s.x,       curwin^.r.e.y-25,
                     curwin^.r.s.x+2+5-1, curwin^.r.e.y);
   plcbut(bmbbotrb,  curwin^.r.e.x-25,    curwin^.r.e.y-2-5+1,
                     curwin^.r.e.x,       curwin^.r.e.y);
   plcbut(bmbbotrr,  curwin^.r.e.x-2-5+1, curwin^.r.e.y-25,
                     curwin^.r.e.x,       curwin^.r.e.y);
   plcbut(bctrl,     curwin^.r.s.x+2+5+2, 
                     curwin^.r.s.y+2+5+2,
                     curwin^.r.s.x+2+5+2+19-1, 
                     curwin^.r.s.y+2+5+2+19-1);
   plcbut(bmovew,    curwin^.r.s.x+2+5+2+19+2, 
                     curwin^.r.s.y+2+5+2,
                     curwin^.r.e.x-29-19-2-1, 
                     curwin^.r.s.y+2+5+2+19-1);
   plcbut(bmin,      curwin^.r.e.x-29-19, 
                     curwin^.r.s.y+2+5+2,
                     curwin^.r.e.x-29-1, 
                     curwin^.r.s.y+2+5+2+19-1);
   plcbut(bmax,      curwin^.r.e.x-29+2, 
                     curwin^.r.s.y+2+5+2,
                     curwin^.r.e.x-2-5-2, 
                     curwin^.r.s.y+2+5+2+19-1);

end;
{}
{**************************************************************

ARRANGE BUTTONS TOP

Arranges the buttons for the current window. Called after
a window size change.

**************************************************************}

procedure arrbutt(lm, tm, rm, bm: integer); { margins }

var b:    buttyp;  { button index }
    x, y: integer; { screen indexes }
    t:    integer;

begin

   x := lm; { find position of 1st button }
   y := tm;
   b := succ(bnull); { index 1st button }
   while b <> bnull do begin { while valid buttons to place }

      if ((curscm - [smprint]) * button[b].sm <> []) and
         (button[b].loc = top) then begin

         if x+button[b].m > rm then begin

            { overflow, next line }
            x := lm; { reset collumn to start }
            y := y+23+1+2; { next row }       
            if y > bm then begin { error, overflow }

               writeln('Error: window overflow');
               while true do

            end

         end;
         button[b].r.s.x := x; { set button position }
         button[b].r.s.y := y;
         button[b].r.e.x := x+button[b].m;
         button[b].r.e.y := y+23;
         x := x+button[b].m+1+2 { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end;
   y := y+23; { next row }
   { find proper margin }
   curwin^.tm.s.x := lm;   
   curwin^.tm.s.y := tm;
   curwin^.tm.e.x := rm;
   curwin^.tm.e.y := y
   
end;
{}
{**************************************************************

SET MARGIN RIGHT

Sets the minimum margin for the right menu.

**************************************************************}

procedure marginr(rm, tm, bm, lm: integer); { margins }

var mm:   integer; { minimum margin }
    b:    buttyp;  { button index }
    fg:   boolean; { fit good flag }
    nm:   integer; { minimum move distance }
    l:    integer; { button length }
    b1:   buttyp;  { button index }

{ perform trial fit }

procedure tfit;

var b:    buttyp;  { button index }
    x, y: integer; { screen indexes }
    t:    integer;
    o:    boolean; { overflow flag }
    b1:   buttyp;  { button index }
    x1:   integer; { index }
    l:    integer; { button length }

begin

   fg := true; { set fit ok }
   nm := maxint; { set no minimum move }
   x := rm-mm; { find position of 1st button }
   y := tm;
   b := succ(bnull); { index 1st button }
   while b <> bnull do begin { while valid buttons to place }

      if ((curscm - [smprint]) * button[b].sm <> []) and
         (button[b].loc = right) then begin

         l := button[b].m; { set length of button }
         o := x+button[b].m > rm;
         if (ftlnxt in button[b].fmt) and not o then begin 

            { check next linkage }
            x1 := x; { get copy x }
            b1 := b; { get copy button }
            repeat

               x1 := x1+button[b1].m+1+2; { find next button position }
               b1 := succ(b1);
               l := l+button[b1].m+1+2; { find virtual button length }
               if x1+button[b1].m > rm then o := true { test overflow }

            until not (ftlnxt in button[b1].fmt) { no more linkage }
            
         end;
         if o then begin

            { overflow, next line }
            { find minimum n }
            t := l-(rm-x);
            if t < nm then 
               nm := t; { set minimum }
            x := rm-mm; { reset collumn to start }
            y := y+23+1+2; { next row }       
            if y+23+1+2 > bm then begin 

               { overlow, end }
               fg := false; { set bad fit }
               b := bnull

            end

         end;
         x := x+button[b].m+1+2 { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end
   
end;

begin

   { search for initial minimum margin }
   mm := 0; { clear minimum }
   { find maximum button applicable button width }
   for b := succ(bnull) to bdisplay do
      if ((curscm - [smprint]) * button[b].sm <> []) and 
         (button[b].loc = right) then begin

      l := button[b].m; { set length of button }
      if ftlnxt in button[b].fmt then begin 

         { check next linkage }
         b1 := b; { get copy button }
         repeat

            b1 := succ(b1);
            l := l+button[b1].m+1+2 { find virtual button length }

         until not (ftlnxt in button[b1].fmt) { no more linkage }
            
      end;
      if l > mm then mm := l

   end;
   repeat

      tfit; { try trail fit at this size }
      if not fg then mm := mm+nm; { find new margin }
      if rm-mm < lm then begin { error, overflow }

         writeln('Error: window overflow');
         while true do

      end

   until fg; { fit is good }
   { find proper margin }
   curwin^.rm.s.x := rm-mm;   
   curwin^.rm.s.y := tm;
   curwin^.rm.e.x := rm;
   curwin^.rm.e.y := bm
   
end;
{}
{**************************************************************

ARRANGE BUTTONS RIGHT

Arranges the buttons for the current window. Called after
a window size change.

**************************************************************}

procedure arrbutr; { margins }

var b:    buttyp;  { button index }
    fb:   buttyp;  { first button on line }
    bc:   integer; { buttons on line count }
    x, y: integer; { screen indexes }
    t:    integer;
    xl:   integer; { screen index for line }
    o:    boolean; { overflow flag }
    b1:   buttyp;  { button index }
    x1:   integer; { index }

{ adjust line }

procedure adjlin;

var i:   integer;
    al:  integer; { adjustment length }
    rmd: integer; { adjustment remainder }
    add: integer; { addition holder }

begin

   al := (curwin^.rm.e.x-(x-1-2)) div bc; { find adjustment length }
   rmd := (curwin^.rm.e.x-(x-1-2)) mod bc; { find adjustment remainder }
   for i := 1 to bc do begin { proportion button spacing }

      { distribute remainder among buttons, starting left }
      if rmd <> 0 then begin add := 1; rmd := rmd-1 end
      else add := 0;
      button[fb].r.s.x := xl; { set button position }
      button[fb].r.s.y := y;
      button[fb].r.e.x := xl+button[fb].m+al+add;
      button[fb].r.e.y := y+23;
      { find next button position }
      xl := xl+button[fb].m+al+add+1+2;
      repeat if fb <> bdisplay then fb := succ(fb) { next button }
      until (((curscm - [smprint]) * button[fb].sm <> []) and
            (button[fb].loc = right)) or
            (fb = bdisplay)

   end

end;

begin

   x := curwin^.rm.s.x; { find position of 1st button }
   y := curwin^.rm.s.y;
   b := succ(bnull); { index 1st button }
   fb := b; { set first button on line }
   bc := 1; { count }
   xl := x; { set first on line index }
   while b <> bnull do begin { while valid buttons to place }

      if ((curscm - [smprint]) * button[b].sm <> []) and
         (button[b].loc = right) then begin

         o := x+button[b].m > curwin^.rm.e.x;
         if (ftlnxt in button[b].fmt) and not o then begin 

            { check next linkage }
            x1 := x; { get copy x }
            b1 := b; { get copy button }
            repeat

               x1 := x1+button[b1].m+1+2; { find next button position }
               b1 := succ(b1);
               if x1+button[b1].m > curwin^.rm.e.x then o := true { test overflow }

            until not (ftlnxt in button[b1].fmt) { no more linkage }
            
         end;
         if o then begin

            { overflow, next line }
            { justify buttons on last line }
            bc := bc - 1; { remove last button from line }
            adjlin; { adjust line }
            fb := b; { set first button on line }
            x := curwin^.rm.s.x; { reset collumn to start }
            y := y+23+1+2; { next row }       
            xl := x; { set first on line index }
            bc := 1 { set first count }

         end;
         bc := bc + 1; { count buttons on line }
         x := x+button[b].m+1+2 { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end;
   bc := bc - 1; { back out last count }
   if bc <> 0 then adjlin { adjust last line }
   
end;
{}
{**************************************************************

PLACE VECTOR CHARACTER 

Draws a single character in vector form. The characters were
planned on a 4x8 grid, with upper left as 0,0. They may be
scaled to any given size. 
Obviously, there is a minimum size possible to give reasonable
representation.

**************************************************************}

procedure vchar(x, y: integer; { location }
                c:    char;    { character to place }
                s:    integer; { scale factor }
                cl:   color;   { color }
                r:    boolean; { rotate 90 deg }
                cr:   region); { clip region }

{ rotate single point x }

function rotx(px, py: integer): integer;

begin

   if r then rotx := chrhdt*s-py*s+x
   else rotx := px*s+x

end;

{ rotate single point y }

function roty(px, py: integer): integer;

begin

   if r then roty := px*s+y 
   else roty := py*s+y

end;

{ draw rotated real line }

procedure linerr(x1, y1, x2, y2: integer);

begin

   if (x1 = x2) or (y1 = y2) then
      { orthogonal line, use critical region }
      liner(rotx(x1, y1), roty(x1, y1), 
            rotx(x2, y2), roty(x2, y2), cl, cr)
   else 
      { else use viewport }
      liner(rotx(x1, y1), roty(x1, y1), 
            rotx(x2, y2), roty(x2, y2), cl, curwin^.cs^.vp.v)
                
end;

begin

   { check in active area }
   if (x+chrwdt*s >= curwin^.cs^.vp.r.s.x) and 
      (x <= curwin^.cs^.vp.r.s.x+(abs(cr.e.x-cr.s.x)*
                              curwin^.cs^.vp.s.x div scalem)) and
      (y+chrhdt*s >= curwin^.cs^.vp.r.s.y) and 
      (y <= curwin^.cs^.vp.r.s.y+(abs(cr.e.y-cr.s.y)*
                              curwin^.cs^.vp.s.y div scalem)) then
      case c of { character }
            
      '0': begin

              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 7);
              linerr(0, 8, 4, 0)

           end;

      '1': begin

              linerr(2, 0, 2, 8);
              linerr(0, 2, 2, 0);
              linerr(0, 8, 4, 8)

           end;

      '2': begin

              linerr(0, 1, 1, 0);
              linerr(0, 5, 1, 4);
              linerr(0, 5, 0, 8);
              linerr(0, 8, 4, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 4, 3, 4);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(4, 1, 4, 3)

           end;

      '3': begin

              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(2, 4, 3, 4);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 3);
              linerr(4, 5, 4, 7)

           end;

      '4': begin

              linerr(3, 0, 3, 8);
              linerr(0, 4, 3, 0);
              linerr(0, 4, 4, 4);
              linerr(2, 8, 4, 8)

           end;

      '5': begin

              linerr(0, 0, 0, 4);
              linerr(0, 0, 4, 0);
              linerr(0, 4, 3, 4);
              linerr(3, 4, 4, 5);
              linerr(0, 8, 3, 8);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 7)

           end;

      '6': begin

              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 7)

           end;

      '7': begin

              linerr(0, 0, 4, 0);
              linerr(0, 8, 4, 0)

           end;

      '8': begin

              linerr(0, 1, 0, 3);
              linerr(0, 5, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 3, 1, 4);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 3);
              linerr(4, 5, 4, 7)

           end;

      '9': begin

              linerr(0, 1, 0, 3);
              linerr(0, 1, 1, 0);
              linerr(0, 3, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 7)

           end;

      'A': begin

              linerr(0, 1, 0, 8);
              linerr(4, 1, 4, 8);
              linerr(1, 0, 3, 0);
              linerr(0, 4, 4, 4);
              linerr(0, 1, 1, 0);
              linerr(3, 0, 4, 1)

           end;

      'B': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 3, 0);
              linerr(0, 4, 3, 4);
              linerr(0, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 3);
              linerr(4, 5, 4, 7)

           end;

      'C': begin

              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 8, 4, 7)

           end;

      'D': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 3, 0);
              linerr(0, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 7)

           end;

      'E': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 4, 0);
              linerr(0, 4, 2, 4);
              linerr(0, 8, 4, 8)

           end;

      'F': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 4, 0);
              linerr(0, 4, 2, 4)

           end;

      'G': begin
   
              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 8, 4, 7);
              linerr(2, 4, 4, 4);
              linerr(4, 4, 4, 7)

           end;

      'H': begin

              linerr(0, 0, 0, 8);
              linerr(4, 0, 4, 8);
              linerr(0, 4, 4, 4)

           end;

      'I': begin

              linerr(0, 0, 4, 0);
              linerr(0, 8, 4, 8);
              linerr(2, 0, 2, 8)

           end;

      'J': begin

              linerr(0, 6, 0, 7);
              linerr(0, 7, 1, 8);
              linerr(1, 8, 3, 8);
              linerr(3, 8, 4, 7);
              linerr(4, 0, 4, 7)

           end;

      'K': begin

              linerr(0, 0, 0, 8);
              linerr(0, 4, 1, 4);
              linerr(1, 4, 4, 0);
              linerr(1, 4, 4, 8)

           end;

      'L': begin

              linerr(0, 0, 0, 8);
              linerr(0, 8, 4, 8)

           end;

      'M': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 2, 4);
              linerr(2, 4, 4, 0);
              linerr(4, 0, 4, 8)

           end;

      'N': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 4, 8);
              linerr(4, 8, 4, 0)

           end;
           
      'O': begin

              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 7)

           end;

      'P': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 3, 0);
              linerr(0, 4, 3, 4);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(4, 1, 4, 3)

           end;

      'Q': begin

              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 8, 4, 7);
              linerr(4, 1, 4, 7);
              linerr(2, 6, 4, 8)

           end;

      'R': begin

              linerr(0, 0, 0, 8);
              linerr(0, 0, 3, 0);
              linerr(0, 4, 3, 4);
              linerr(2, 4, 4, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 3);
              linerr(4, 1, 4, 3)

           end;

      'S': begin

              linerr(0, 1, 0, 3);
              linerr(0, 1, 1, 0);
              linerr(0, 3, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 3, 0);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 4, 1);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 7)

           end;

      'T': begin

              linerr(0, 0, 4, 0);
              linerr(2, 0, 2, 8)

           end;

      'U': begin

              linerr(0, 0, 0, 7);
              linerr(0, 7, 1, 8);
              linerr(1, 8, 3, 8);
              linerr(3, 8, 4, 7);
              linerr(4, 0, 4, 7)

           end;

      'V': begin

              linerr(0, 0, 2, 8);
              linerr(2, 8, 4, 0)

           end;

      'W': begin

              linerr(0, 0, 0, 8);
              linerr(0, 8, 2, 4);
              linerr(2, 4, 4, 8);
              linerr(4, 0, 4, 8)

           end;

      'X': begin

              linerr(0, 0, 4, 8);
              linerr(0, 8, 4, 0)

           end;

      'Y': begin

              linerr(0, 0, 2, 4);
              linerr(2, 4, 4, 0);
              linerr(2, 4, 2, 8)

           end;

      'Z': begin

              linerr(0, 0, 4, 0);
              linerr(4, 0, 0, 8);
              linerr(0, 8, 4, 8)

           end;

      'a': begin

              linerr(0, 5, 0, 7);
              linerr(1, 4, 0, 5);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 8)

           end;

      'b': begin

              linerr(0, 0, 0, 8);
              linerr(0, 4, 3, 4);
              linerr(0, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 7)

           end;

      'c': begin

              linerr(0, 5, 0, 7);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7)

           end;

      'd': begin

              linerr(0, 5, 0, 7);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 0, 4, 8)

           end;

      'e': begin

              linerr(0, 5, 0, 7);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(0, 6, 4, 6);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 6);
              linerr(1, 8, 3, 8)

           end;

      'f': begin

              linerr(0, 4, 2, 4);
              linerr(1, 1, 1, 8);
              linerr(1, 1, 2, 0);
              linerr(2, 0, 3, 0);
              linerr(3, 0, 4, 1)

           end;

      'g': begin

              linerr(0, 5, 0, 7);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(0, 10, 1, 11);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(1, 11, 3, 11);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(3, 11, 4, 10);
              linerr(4, 5, 4, 10)

           end;

      'h': begin

              linerr(0, 0, 0, 8);
              linerr(0, 5, 1, 4);
              linerr(1, 4, 3, 4);
              linerr(3, 4, 4, 5);
              linerr(4, 5, 4, 8)

           end;

      'i': begin

              linerr(1, 4, 2, 4);
              linerr(1, 8, 3, 8);
              linerr(2, 2, 2, 3);
              linerr(2, 4, 2, 8)

           end;

      'j': begin

              linerr(0, 10, 1, 11);
              linerr(1, 11, 3, 11);
              linerr(3, 4, 4, 4);
              linerr(3, 11, 4, 10);
              linerr(4, 2, 4, 3);
              linerr(4, 4, 4, 10)

           end;

      'k': begin

              linerr(1, 0, 1, 8);
              linerr(1, 6, 4, 4);
              linerr(1, 6, 4, 8)

           end;

      'l': begin

              linerr(1, 0, 2, 0);
              linerr(1, 8, 3, 8);
              linerr(2, 0, 2, 8)

           end;

      'm': begin

              linerr(0, 4, 0, 8);
              linerr(0, 4, 2, 6);
              linerr(2, 6, 4, 4);
              linerr(4, 4, 4, 8)

           end;

      'n': begin

              linerr(0, 4, 0, 8);
              linerr(0, 5, 1, 4);
              linerr(1, 4, 3, 4);
              linerr(3, 4, 4, 5);
              linerr(4, 5, 4, 8)

           end;

      'o': begin

              linerr(0, 5, 0, 7);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 7)

           end;

      'p': begin

              linerr(0, 4, 0, 11);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 7)

           end;

      'q': begin

              linerr(0, 5, 0, 7);
              linerr(0, 5, 1, 4);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 8, 4, 7);
              linerr(4, 5, 4, 11)

           end;

      'r': begin

              linerr(0, 4, 0, 8);
              linerr(0, 5, 1, 4);
              linerr(1, 4, 3, 4);
              linerr(3, 4, 4, 5)

           end;

      's': begin

              linerr(0, 5, 1, 4);
              linerr(0, 5, 1, 6);
              linerr(0, 7, 1, 8);
              linerr(1, 4, 3, 4);
              linerr(1, 6, 3, 6);
              linerr(1, 8, 3, 8);
              linerr(3, 4, 4, 5);
              linerr(3, 6, 4, 7);
              linerr(3, 8, 4, 7)

           end;

      't': begin

              linerr(0, 2, 4, 2);
              linerr(2, 0, 2, 8);
              linerr(2, 8, 3, 8)

           end;

      'u': begin

              linerr(0, 4, 0, 7);
              linerr(0, 7, 1, 8);
              linerr(1, 8, 3, 8);
              linerr(3, 8, 4, 7);
              linerr(4, 4, 4, 8)

           end;

      'v': begin

              linerr(0, 4, 2, 8);
              linerr(2, 8, 4, 4)

           end;

      'w': begin

              linerr(0, 4, 0, 8);
              linerr(0, 8, 2, 6);
              linerr(2, 6, 4, 8);
              linerr(4, 4, 4, 8)

           end;

      'x': begin

              linerr(0, 4, 4, 8);
              linerr(0, 8, 4, 4)

           end;

      'y': begin

              linerr(0, 4, 0, 7);
              linerr(0, 7, 1, 8);
              linerr(1, 8, 3, 8);
              linerr(3, 8, 4, 7);
              linerr(0, 10, 1, 11);
              linerr(1, 11, 3, 11);
              linerr(3, 11, 4, 10);
              linerr(4, 4, 4, 10)

           end;

      'z': begin

              linerr(0, 4, 4, 4);
              linerr(0, 8, 4, 4);
              linerr(0, 8, 4, 8)

           end;

      '!': begin

              linerr(2, 0, 2, 5);
              linerr(2, 7, 2, 8)

           end;

      '@': begin

              linerr(0, 1, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 7, 1, 8);
              linerr(1, 2, 1, 6);
              linerr(1, 0, 3, 0);
              linerr(1, 2, 3, 2);
              linerr(1, 6, 4, 6);
              linerr(1, 8, 4, 8);
              linerr(3, 2, 3, 6);
              linerr(3, 0, 4, 1);
              linerr(4, 1, 4, 6)

           end;

      '#': begin

              linerr(1, 0, 1, 8);
              linerr(3, 0, 3, 8);
              linerr(0, 3, 4, 3);
              linerr(0, 5, 4, 5)

           end;

      '$': begin

              linerr(0, 2, 0, 3);
              linerr(0, 2, 1, 1);
              linerr(0, 3, 1, 4);
              linerr(0, 6, 1, 7);
              linerr(1, 1, 3, 1);
              linerr(1, 4, 3, 4);
              linerr(1, 7, 3, 7);
              linerr(2, 0, 2, 8);
              linerr(3, 1, 4, 2);
              linerr(3, 4, 4, 5);
              linerr(3, 7, 4, 6);
              linerr(4, 5, 4, 6)

           end;

      '%': begin

              linerr(0, 1, 0, 2);
              linerr(0, 1, 1, 1);
              linerr(0, 2, 1, 2);
              linerr(1, 1, 1, 2);
              linerr(0, 8, 4, 0);
              linerr(3, 6, 3, 7);
              linerr(3, 6, 4, 6);
              linerr(3, 7, 4, 7);
              linerr(4, 6, 4, 7)

           end;

      '^': begin

              linerr(0, 2, 2, 0);
              linerr(2, 0, 4, 2)

           end;

      '&': begin

              linerr(0, 1, 0, 3);
              linerr(0, 5, 0, 7);
              linerr(0, 1, 1, 0);
              linerr(0, 3, 4, 8);
              linerr(0, 5, 3, 3);
              linerr(0, 7, 1, 8);
              linerr(1, 0, 2, 0);
              linerr(1, 8, 3, 8);
              linerr(2, 0, 3, 1);
              linerr(3, 1, 3, 3);
              linerr(3, 8, 4, 7);
              linerr(4, 6, 4, 7)

           end;

      '*': begin

              linerr(2, 0, 2, 8);
              linerr(0, 4, 4, 4);
              linerr(0, 1, 4, 7);
              linerr(0, 7, 4, 1)

           end;

      '(': begin

              linerr(3, 0, 2, 1);
              linerr(2, 1, 1, 3);
              linerr(1, 3, 1, 5);
              linerr(1, 5, 2, 7);
              linerr(2, 7, 3, 8)

           end;

      ')': begin

              linerr(1, 0, 2, 1);
              linerr(2, 1, 3, 3);
              linerr(3, 3, 3, 5);
              linerr(3, 5, 2, 7);
              linerr(2, 7, 1, 8)

           end;

      '-': begin

              linerr(0, 4, 4, 4)

           end;

      '_': begin

              linerr(0, 8, 4, 8)

           end;

      '+': begin

              linerr(0, 4, 4, 4);
              linerr(2, 2, 2, 6)

           end;

      '=': begin

              linerr(0, 3, 4, 3);
              linerr(0, 5, 4, 5)

           end;

      '\\': begin

              linerr(0, 0, 4, 8)

           end;

      '/': begin

              linerr(0, 8, 4, 0)

           end;

      '|': begin

              linerr(2, 0, 2, 3);
              linerr(2, 5, 2, 8)

           end;

      '[': begin

              linerr(1, 0, 1, 8);
              linerr(1, 0, 2, 0);
              linerr(1, 8, 2, 8)

           end;

      ']': begin

              linerr(1, 0, 3, 0);
              linerr(1, 8, 3, 8);
              linerr(3, 0, 3, 8)

           end;

      '{': begin

              linerr(0, 4, 1, 4);
              linerr(1, 4, 2, 3);
              linerr(1, 4, 2, 5);
              linerr(2, 1, 2, 3);
              linerr(2, 5, 2, 7);
              linerr(2, 1, 3, 0);
              linerr(2, 7, 3, 8);
              linerr(3, 0, 4, 0);
              linerr(3, 8, 4, 8)

           end;

      '}': begin

              linerr(0, 0, 1, 0);
              linerr(0, 8, 1, 8);
              linerr(1, 0, 2, 1);
              linerr(1, 8, 2, 7);
              linerr(2, 1, 2, 3);
              linerr(2, 5, 2, 7);
              linerr(2, 3, 3, 4);
              linerr(2, 5, 3, 4);
              linerr(3, 4, 4, 4)

           end;

      ':': begin

              linerr(2, 4, 2, 5);
              linerr(2, 7, 2, 8)

           end;

      ';': begin

              linerr(2, 4, 2, 5);
              linerr(2, 7, 2, 8);
              linerr(1, 9, 2, 8)

           end;

      '"': begin

              linerr(1, 0, 1, 1);
              linerr(3, 0, 3, 1)

           end;

      '''': begin

              linerr(1, 1, 2, 0)

           end;

      ',': begin

              linerr(2, 7, 2, 8);
              linerr(1, 9, 2, 8)

           end;

      '.': begin

              linerr(2, 7, 2, 8)

           end;

      '<': begin

              linerr(1, 4, 3, 0);
              linerr(1, 4, 3, 8)

           end;

      '>': begin

              linerr(1, 0, 3, 4);
              linerr(1, 8, 3, 4)

           end;

      '?': begin

              linerr(0, 1, 0, 2);
              linerr(0, 1, 1, 0);
              linerr(1, 0, 3, 0);
              linerr(3, 0, 4, 1);
              linerr(4, 1, 4, 3);
              linerr(4, 3, 3, 4);
              linerr(3, 4, 2, 4);
              linerr(2, 4, 2, 5);
              linerr(2, 7, 2, 8)

           end;

      '`': begin

              linerr(2, 0, 3, 1)

           end;

      '~': begin

              linerr(0, 2, 1, 0);
              linerr(1, 0, 3, 2);
              linerr(3, 2, 4, 0)

           end

   end

end;
{}
{**************************************************************

CONVERT INTEGER

Convert unsigned integer to string.
Note: only converts an 8 digit number.

**************************************************************}

procedure intstr(n: integer; var s: butstr);

var i: btsinx; { index for string }
    p: integer;

begin

   s := '        '; { clear target string }
   for i := 1 to 8 do begin { extract digits }

      case i of { power }
    
         1: p := 10000000;
         2: p := 1000000;
         3: p := 100000;
         4: p := 10000;
         5: p := 1000;
         6: p := 100;
         7: p := 10;
         8: p := 1

      end;
      s[i] := chr(n div p + ord('0')); { extract that digit }
      n := n mod p { remove digit }

   end
   
end;
{}
{**************************************************************

ELIMINATE LEADING SPACES

Erases leading spaces in a number string.

**************************************************************}

procedure trmzer(var s: butstr);

var i: btsinx; { index for string }

begin

   i := 1; { set 1st character }
   repeat

      if s[i] = '0' then begin 

         s[i] := ' '; { clear digit }
         i := i + 1 { next digit }

      end else i := butlen

   until i = butlen { end of string }
   
end;
{}
{**************************************************************

CONVERT REAL

Convert real to string. The resulting format is:

   999.000xx to 1.000xx where "xx" is um, cm, dm etc.

Note that we should never really have to represent 1 meter and
above (but 1-999m was included anyways).

**************************************************************}

procedure realstr(r: real; var s: butstr);

var ec:  packed array [1..13] of char;
    e:   1..13;
    n:   integer;
    i:   btsinx;
    sgn: char; { sign character }

begin

   sgn := ' '; { set not signed }
   if r < 0.0 then begin { signed }

      sgn := '-'; { set signed }
      r := -r { convert to positive }

   end;
   ec := 'EPTGMk munpfa'; { set exponent characters }
   ec[9] := chr(microchr); { set special for micro }
   e := 7; { intialize exponent }
   r := r * 1000; { scale to our decimal point }
   { scale downwards (done in two parts to avoid integer
     accuracy limits) }
   while r >= 1000000000 do begin r := r / 1000; e := e-1 end;
   while round(r) >= 1000000 do begin r := r / 1000; e := e-1 end;
   { scale upwards }
   if r <> 0 then
      while round(r) < 1000 do begin r := r * 1000; e := e+1 end;
   n := round(r); { scale for decimal placement }
   intstr(n, s); { convert }
   trmzer(s); { eliminate zeros }
   for i := 2 to 4 do s[i] := s[i+1]; { move 1st part of number }
   if s[7] <> ' ' then s[5] := '.'; { place decimal }
   { preserve 0 case }
   if (s[7] = ' ') and (s[8] = '0') then s[7] := '0';
   s[8] := ec[e]; { place exponent }
   s[1] := sgn { place sign }

end; 
{}
{**************************************************************

PERFORM EDIT FUNCTION

Performs the given edit character on a screen displayed screen.
The routine is pretty much self contained. To activate the edit,
(and lay down the inital cursor), call with a null character.
To terminate the edit, call with return.
The following controls are implemented:

   <left arrow>  - move cursor left
   <right arrow> - move cursor right
   home          - move cursor to line start 
   end           - move cursor to line end
   <backspace>   - delete last character
   del           - delete next character
   ins           - clear string and home cursor
   enter         - terminate edit

**************************************************************}

procedure edit(var b:  butrec; { button to edit }
               var p:  btsinx; { current cursor position }
                   c:  char;   { primary input character }
                   cs: char);  { secondary input character }  

var i: btsinx;

begin

   if errmsg then plcmsg(mnone, yellow); { clear error message }
   if c in ['A'..'Z', 'a'..'z', '0'..'9', '.', ' '] then begin

      { insert normal character }
      if (p <> b.l) and (b.s[b.l] = ' ') then 
         begin { line not full }

         { move characters right to make space }
         for i := b.l downto p+2 do
            b.s[i] := b.s[i-1];
         p := p + 1; { move cursor right }
         b.s[p] := c { place character }

      end
      
   end else if c = chr(8) then begin

      { backspace (erase last) }
      if p <> 0 then begin { not already at left }
  
         { move characters left to gap }
         for i := p to b.l-1 do b.s[i] := b.s[i+1]; 
         b.s[b.l] := ' '; { clear last character }
         p := p - 1 { move cursor left }

      end         

   end else if (c = chr(0)) and (cs = chr(83)) then begin

      if p <> b.l then begin { not at extreme right }

         { delete (erase next) }
         { move characters left to gap }
         for i := p+1 to b.l-1 do b.s[i] := b.s[i+1]; 
         b.s[b.l] := ' ' { clear last character }

      end

   end else if (c = chr(0)) and (cs = chr(75)) then begin

      { left arrow }
       if p > 0 then p := p - 1 { move cursor left }

   end else if (c = chr(0)) and (cs = chr(77)) then begin

      { right arrow }
      if p < b.l then p := p + 1 { move cursor right }

   end else if (c = chr(0)) and (cs = chr(71)) then begin

      { home }
      p := 0 { set cursor to left side }
      
   end else if (c = chr(0)) and (cs = chr(79)) then begin

      { end }
      p := b.l { set cursor to right side }

   end else if (c = chr(0)) and (cs = chr(82)) then begin

      { insert (clear) }
      b.s := '        '; { clear string }
      p := 0 { set cursor to left side }

   end;
   rescur; { reset cursor }
   if true{b.sel} and (c = chr(13)) then { update button }
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, yellow, true)
   else 
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, b.icb, true);
   if c <> chr(13) then begin { not end, replace cursor }

      if p = 0 then begin { draw left side cursor }

         line(screen, b.r.s.x*16+1, b.r.s.y*16+1,
              b.r.s.x*16+1, (b.r.s.y+1)*16-1-1, lmagenta);
         line(screen, b.r.s.x*16+1+1, b.r.s.y*16+1, 
              b.r.s.x*16+1+1, (b.r.s.y+1)*16-1-1, lmagenta)

      end else if p = b.l then begin { draw right side cursor }

         line(screen, (b.r.s.x+b.l)*16-1-1-1, b.r.s.y*16+1, 
              (b.r.s.x+b.l)*16-1-1-1, 
              (b.r.s.y+1)*16-1-1, lmagenta);
         line(screen, (b.r.s.x+b.l)*16-1-1, b.r.s.y*16+1, 
              (b.r.s.x+b.l)*16-1-1, 
              (b.r.s.y+1)*16-1-1, lmagenta)

      end else begin { draw between characters cursor }

         line(screen, (b.r.s.x+p)*16-1, b.r.s.y*16+1, 
              (b.r.s.x+p)*16-1, (b.r.s.y+1)*16-1-1, lmagenta);
         line(screen, (b.r.s.x+p)*16, b.r.s.y*16+1, 
              (b.r.s.x+p)*16, (b.r.s.y+1)*16-1-1, lmagenta)

      end

   end;
   setcur { replace cursor }

end;
{}
{**************************************************************

BEGIN BUTTON EDIT

Begins an edit on the given button.

**************************************************************}

procedure edtbut(var b: butrec);

var i: integer;

begin

   { set cursor position based on where cross cursor landed }
   i := cur.x - b.r.s.x; { find dot offset of cursor }
   edtpos := i div 16; { find character offset }
   if (i mod 16) > 8 then edtpos := edtpos + 1; { round up }
   edit(b, edtpos, chr(0), chr(0))

end;
{}
{**************************************************************

GET INTEGER

Reads and converts the decimal numeric in the given string.
Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getint(var b:   butrec;   { button to parse }
                 var n:   integer;  { returned value }
                 var err: boolean); { error status }

var i:   btsinx;  { current position in string }
    e:   boolean; { end of string flag }
    c:   char; 

function chkchr: char; { check next character }

begin

   if e then chkchr := ' ' { at end }
   else chkchr := b.s[i]

end;

procedure getchr; { get next character }

begin

   if i <> b.l then i := i + 1 { advance } 
   else e := true { set end }

end;

procedure skpspc; { skip spaces }

begin

   while not e and (chkchr = ' ') do getchr { skip spaces }

end;

begin

   i := 1; { set 1st character }
   e := false; { set not end }
   err := false; { set no error }
   n := 0; { initalize number }
   skpspc; { skip leading spaces }
   { check any digits }
   while chkchr in ['0'..'9'] do begin

      { check overflow }
      if n > maxint div 10 - 10 then begin err := true; n := 0 end;
      n := n * 10; { scale }
      n := n + ord(chkchr) - ord('0'); { add new digit }
      getchr { next }

   end;
   if err then plcmsg(movfn, lred) { overflow occurred }
   else begin

      skpspc; { skip trailing spaces }
      if chkchr <> ' ' then begin 

         plcmsg(minvn, lred); { invalid integer }
         err := true { flag error }

      end

   end;
   if err then begin { highlight position of error }

      rescur; { reset cursor }
      { set button back to normal }
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, b.icb, true);
      plcchr((b.r.s.x+(i*16)-16), b.r.s.y, b.s[i], black, lred, black, 
             i = 1, i = b.l);
      setcur { replace cursor }

   end

end;
{}
{**************************************************************

GET REAL

Reads and converts the decimal numeric at the command line
position. Indicates an error on numeric overflow, or number
not found.

**************************************************************}

procedure getrnm(var b:   butrec;   { button to parse from }
                 var n:   real;     { returned value }
                 var err: boolean); { error flag }

label 99; { terminate on error }

var dp:  boolean; { decimal point flag }
    p:   real;    { scaling factor }
    i:   btsinx;  { current position in string }
    e:   boolean; { end of string flag }
    c:   char; 
    sgn: real;    { sign }

function chkchr: char; { check next character }

begin

   if e then chkchr := ' ' { at end }
   else chkchr := b.s[i]

end;

procedure getchr; { get next character }

begin

   if i <> b.l then i := i + 1 { advance } 
   else e := true { set end }

end;

procedure skpspc; { skip spaces }

begin

   while not e and (chkchr = ' ') do getchr { skip spaces }

end;

begin

   i := 1; { set 1st character }
   e := false; { set not end }
   n := 0.0; { initalize number }
   p := 1.0; { set scaling factor }
   dp := false; { set decimal point not scanned }
   sgn := 1.0; { set positive sign }
   err := false; { set no error }
   skpspc; { skip spaces }
   { check any signs }
   if chkchr = '+' then getchr { skip }
   else if chkchr = '-' then begin { negative }

      sgn := -1.0;
      getchr { skip }

   end;
   { check any digits }
   if not (chkchr in ['0'..'9', '.']) then 
      begin plcmsg(minvn, lred); err := true; goto 99 end;
   while chkchr in ['0'..'9', '.'] do begin

      if chkchr = '.' then begin { decimal point }

         if dp then { decimal point already passed }
            begin plcmsg(minvn, lred); err := true; goto 99 end;
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
   c := chkchr; { get next }
   { convert micro character }
   if c = chr(microchr) then c := 'u';
   if c in ['a', 'f', 'p', 'n', 'u', 'm', 'k', 'M', 'G', 'T',
            'P', 'E'] then
      case c of

      'a': begin n := n * 1e-18; getchr end; { atto }
      'f': begin n := n * 1e-15; getchr end; { femto }
      'p': begin n := n * 1e-12; getchr end; { pico }
      'n': begin n := n * 1e-9;  getchr end; { nano }
      'u': begin n := n * 1e-6;  getchr end; { micro }
      'm': begin n := n * 1e-3;  getchr end; { mili }
      'k': begin n := n * 1e+3;  getchr end; { kilo }
      'M': begin n := n * 1e+6;  getchr end; { mega }
      'G': begin n := n * 1e+9;  getchr end; { giga }
      'T': begin n := n * 1e+12; getchr end; { tera }
      'P': begin n := n * 1e+15; getchr end; { peta }
      'E': begin n := n * 1e+18; getchr end  { exa }

   end;
   n := n * sgn; { establish sign }
   skpspc; { skip spaces }
   if chkchr <> ' ' then { invalid format } 
      begin plcmsg(minvn, lred); err := true; goto 99 end;

   99: { error }

   if err then begin { highlight position of error }

      rescur; { reset cursor }
      { set button back to normal }
      plcstr(b.r.s.x, b.r.s.y, b.s, b.l, black, b.icb, true);
      plcchr((b.r.s.x+(i*16)-16), b.r.s.y, b.s[i], black, lred, black, 
             i = 1, i = b.l);
      setcur { replace cursor }

   end

end;
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
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
{}
{**************************************************************

FIND BOUNDING BOX PARAMETERS

Given a sheet, will find the origin and scale of the proper
view for a bounding box.
 
**************************************************************}

procedure fndbnd(sp: shtptr; var x, y, s: integer); 

var an: real;

begin

   if not boundset(sp) then begin { bounds not set }

      x := 0; { set default view coordinates for empty sheet }
      y := 0;
      s := normscale*scalem

   end else begin { bounds set }

      { find box diagonal }
      if (sp^.bbsx <> sp^.bbex) and (sp^.bbsy <> sp^.bbey) then
         an := arctan(abs(sp^.bbex-sp^.bbsx)/abs(sp^.bbey-sp^.bbsy));
      if ((an < curwin^.aa) or (sp^.bbsx = sp^.bbex)) and not
         (sp^.bbsy = sp^.bbey) then begin { y dominated }

         s := round((abs(sp^.bbey-sp^.bbsy)/
                     (abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)-
                      (2*bbborder)))*scalem);
         x := round(sp^.bbsx - (((abs(sp^.bbey-sp^.bbsy)/2)/tan((pi/2)-curwin^.aa))-
                    (abs(sp^.bbex-sp^.bbsx)/2))); 
         y := sp^.bbsy { set origins }

      end else begin { x dominated }

         s := round((abs(sp^.bbex-sp^.bbsx)/
                     (abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)-
                      (2*bbborder)))*scalem); 
         x := sp^.bbsx; { set origins }
         y := round(sp^.bbsy - (((abs(sp^.bbex-sp^.bbsx)/2)/tan(curwin^.aa))-
                   (abs(sp^.bbey-sp^.bbsy)/2))) 

      end;
      { offset by margins }
      x := x - realdist(bbborder, s);
      y := y - realdist(bbborder, s)

   end

end;
{}
{**************************************************************

READ BYTE FROM A FILE

Reads a byte with values 0..255 from the given file.
This procedure required because SVS does not accept
that definition as occupying a byte, as allowed by the
ISO rules. 

**************************************************************}

procedure readbyt(var f: bytfil; var b: byte);

var rb: boolean; { read buffer }

begin

   read(f, rb); { get byte }
   b := ord(rb) and $ff { convert }

end;
{}
{**************************************************************

WRITE BYTE TO A FILE

Writes a byte with values 0..255 to the given file.
This procedure required because SVS does not accept
that definition as occupying a byte, as allowed by the
ISO rules. 

**************************************************************}

procedure writebyt(var f: bytfil; b: byte);

function convert(b: byte): boolean; cexternal;

begin

   write(f, convert(b)) { output }

end;
{}
{**************************************************************

READ 32 BIT NUMBER FROM FILE

Reads a 32 bit number from the given file. The highest order
byte appears first, and the least order last.
The high byte 7th bit contains the sign.
NOTE: on SVS pascal, subrange types are not expanded to 
integer on read (a violation of the standard). The fix for this
is still compatible with ISO.

**************************************************************}

procedure read32(var f: bytfil; var i: integer); 

var b: byte;    { read byte holder }
    s: integer; { sign of result }
    t: integer; { temp }
vp: region;

begin

   s := 1; { set no sign }
   readbyt(f, b);
   if b >= 128 then begin { signed }

      s := -1; { set sign }
      b := b - 128 { remove sign }

   end;
   t := b; { place in large buffer }
   i := t*16777216;
   readbyt(f, b);
   t := b; { place in large buffer }
   i := i + t*65536;
   readbyt(f, b);
   t := b; { place in large buffer }
   i := i + t*256;
   readbyt(f, b);
   i := i + b;
   i := i*s { set sign of result }

end;
{}
{**************************************************************

WRITE 32 BIT NUMBER TO FILE

Writes a 32 bit number to the given file. The highest order
byte appears first, and the least order last.
The high byte 7th bit contains the sign.

**************************************************************}

procedure write32(var f: bytfil; i: integer); 

var t, s: integer;

begin

   { set sign }
   if i < 0 then s := 128 else s := 0;
   i := abs(i); { remove sign }
   t := i div 16777216; { high byte }
   writebyt(f, t+s); { with sign }
   i := i - (t * 16777216); { high middle }
   t := i div 65536;
   writebyt(f, t);
   i := i - (t * 65536); { low middle }
   t := i div 256;
   writebyt(f, t);
   i := i - (t * 256); { low }
   writebyt(f, i)

end;
{}
{**************************************************************

READ FIGURES FROM FILE

Reads a list of draw figures from the given file.

**************************************************************}

procedure readfigs(var f: bytfil; var p: drwptr; sp: shtptr);

var sl:    drwptr; { figure holder }
    b:     byte;   { byte holder }
    c, c1: byte;   { character count }
    ch:    chrptr; { character pointer }
    n:     integer;
    t:     figtyp; { type holder }

{ read rotation mode }

procedure readrot(var rm: rotmod);

var b: byte;

begin

   readbyt(f, b); { get rotation mode }
   case b of { rotation }

      0: rm := rm0;    { 0 deg }
      1: rm := rm90;   { 90 deg }
      2: rm := rm180;  { 180 deg }
      3: rm := rm270;  { 270 deg }
      4: rm := rmm0;   { 0 deg mirrored }
      5: rm := rmm90;  { 90 deg mirrored }
      6: rm := rmm180; { 180 deg mirrored }
      7: rm := rmm270  { 270 deg mirrored }

   end

end;

{ read color }

procedure readclr(var c: color);

var b: byte;

begin

   readbyt(f, b); { get color }
   case b of { color }

      0:  c := black;
      1:  c := blue;
      2:  c := green;
      3:  c := cyan;
      4:  c := red;
      5:  c := magenta;
      6:  c := brown;
      7:  c := dwhite;
      8:  c := gray;
      9:  c := lblue;
      10: c := lgreen;
      11: c := lcyan; 
      12: c := lred;
      13: c := lmagenta;
      14: c := yellow;
      15: c := white

   end

end;

{ read type }

procedure readtyp(var t: figtyp);

var b: byte;

begin

   readbyt(f, b); { get type }
   case b of { type }

      0:  t := tend; 
      1:  t := tline; 
      2:  t := tbox; 
      3:  t := tarc; 
      4:  t := tchar; 
      5:  t := twire; 
      6:  t := tbus; 
      7:  t := tjunction; 
      8:  t := tbline; 
      9:  t := tbbox; 
      10: t := tcell; 
      11: t := tconnect;
      12: t := tnmos; 
      13: t := tpmos; 
      14: t := tcap; 
      15: t := tres; 
      16: t := tdiode; 
      17: t := tvdd; 
      18: t := tvss;
      19: t := tmet1; 
      20: t := tmet2; 
      21: t := tpoly; 
      22: t := tvia; 
      23: t := tndiff; 
      24: t := tpdiff;
      25: t := tnwell; 
      26: t := tpwell; 
      27: t := tccut; 
      28: t := tinter;
      29: t := tcont

   end

end;

{ attach figure to node }

procedure fignode(p: drwptr; n: integer; sp: shtptr);

var np, nl: nodptr;

begin

   np := sp^.nl; { index node list }
   while n <> 1 do begin { traverse }

      n := n - 1; { count }
      np := np^.next { next entry }

   end;
   p^.nh := np; { set node head }
   p^.nl := np^.nl; { place in node list }
   np^.nl := p

end;

{ attach figure to bus }

procedure figbus(p: drwptr; n: integer; sp: shtptr);

var bp, bl: busptr;

begin

   bp := sp^.bl; { index bus list }
   while n <> 1 do begin { traverse }

      n := n - 1; { count }
      bp := bp^.next { next entry }

   end;
   p^.bs.bh := bp; { set bus head }
   p^.bs.bl := bp^.bl; { place in bus list }
   bp^.bl := p

end;

{ link cell from cell number }

procedure lnkcel(n: integer; var sp: shtptr; ct: celtyp);

var cp:      celptr;       { cell pointer }

begin

   cp := cellst; { index 1st cell }
   { find that cell }
   while n <> 1 do begin cp := cp^.next; n := n - 1 end;
   if ct = ctsch then begin { schematic cell }

      { make sure that schematic sheet exists }
      if cp^.schema = nil then new(cp^.schema);
      sp := cp^.schema { place that link }

   end else if ct = ctsym then begin { symbol cell }

      { make sure that symbol sheet exists }
      if cp^.symbol = nil then new(cp^.symbol);
      sp := cp^.symbol { place that link }

   end else if ct = ctlay then begin { layout cell }

      { make sure that layout sheet exists }
      if cp^.layout = nil then new(cp^.layout);
      sp := cp^.layout { place that link }

   end

end;

{  link figure from layer, figure number }

procedure lnkfig(ln, fn: integer; sp: shtptr; var p: drwptr);

begin

   { index top of list }
   case ln of { layer }

      0:  p := sp^.dl[ltcell];  { layer 0 }
      1:  p := sp^.dl[ltfig];   { layer 1 }
      2:  p := sp^.dl[ltovg];   { layer 2 }
      3:  p := sp^.dl[ltvia];   { layer 3 }
      4:  p := sp^.dl[ltism2];  { layer 4 }
      5:  p := sp^.dl[ltism1];  { layer 5 }
      6:  p := sp^.dl[ltisply]; { layer 6 }
      7:  p := sp^.dl[ltmet2];  { layer 7 }
      8:  p := sp^.dl[ltcont];  { layer 8 }
      9:  p := sp^.dl[ltpmd];   { layer 9 }
      10: p := sp^.dl[ltwell]   { layer 10 }

   end;
   while fn <> 1 do begin { traverse }

      fn := fn - 1; { count }
      p := p^.next { next entry }

   end

end;

begin

   sl := nil; { clear last entry }
   readtyp(t); { get figure type }
   while t <> tend do begin { read figures }

      { create new entry at end }
      if sl = nil then begin new(p); sl := p end
      else begin new(sl^.next); sl := sl^.next end;
      sl^.next := nil; { clear next }
      sl^.typ := t; { set type }
      case sl^.typ of { figure }

         tline: begin { line }

            sl^.typ := tline; { set type }
            read32(f, sl^.l.s.x); { starting }
            read32(f, sl^.l.s.y); 
            read32(f, sl^.l.e.x); { ending }
            read32(f, sl^.l.e.y);
            sl^.cl := black { set color }

         end;

         tbox: begin { box }

            sl^.typ := tbox; { set type }
            read32(f, sl^.b.s.x); { starting }
            read32(f, sl^.b.s.y); 
            read32(f, sl^.b.e.x); { ending }
            read32(f, sl^.b.e.y);
            sl^.cl := black { set color }

         end;

         tarc: begin { arc or circle }

            sl^.typ := tarc; { set type }
            read32(f, sl^.a.s.x); { starting }
            read32(f, sl^.a.s.y); 
            read32(f, sl^.a.e.x); { ending }
            read32(f, sl^.a.e.y);
            read32(f, sl^.a.c.x); { center }
            read32(f, sl^.a.c.y);
            read32(f, sl^.a.r);  { radius }
            sl^.cl := black { set color }

         end;

         tchar: begin { char }

            sl^.typ := tchar; { set type }
            read32(f, sl^.c.r.s.x);   { origin }
            read32(f, sl^.c.r.s.y); 
            read32(f, sl^.c.r.e.x); 
            read32(f, sl^.c.r.e.y); 
            sl^.c.l := nil; { clear character string }
            readbyt(f, c); { get character count }
            for c1 := 1 to c do begin { read string }
         
               readbyt(f, b); { get a character }
               if sl^.c.l = nil then begin { first character }
         
                  new(sl^.c.l); { get an entry }
                  ch := sl^.c.l { index }

               end else begin { mid character }

                  new(ch^.next); { get an entry }
                  ch := ch^.next { index }

               end;
               ch^.next := nil; { terminate string }
               ch^.c := chr(b); { place character }

            end; 
            read32(f, sl^.c.s); { scale }
            readrot(sl^.rm); { get rotation }
            sl^.cl := black { set color }

         end;
     
         twire: begin { wire }

            sl^.typ := twire; { set type }
            read32(f, sl^.w.s.x); { starting }
            read32(f, sl^.w.s.y); 
            read32(f, sl^.w.e.x); { ending }
            read32(f, sl^.w.e.y);
            read32(f, n); { node number }
            fignode(sl, n, sp); { link to node }
            sl^.cl := black { set color }

         end;

         tbus: begin { bus }

            sl^.typ := tbus; { set type }
            read32(f, sl^.bs.l.s.x); { starting }
            read32(f, sl^.bs.l.s.y); 
            read32(f, sl^.bs.l.e.x); { ending }
            read32(f, sl^.bs.l.e.y);
            read32(f, n); { bus number }
            figbus(sl, n, sp); { link to bus }
            sl^.cl := black { set color }

         end;

         tjunction: begin { junction }

            sl^.typ := tjunction; { set type }
            read32(f, sl^.j.x); { center }
            read32(f, sl^.j.y);
            read32(f, n); { node number }
            fignode(sl, n, sp); { link to node }
            sl^.cl := black { set color }

         end;

         tconnect: begin { connector }

            sl^.typ := tconnect; { set type }
            read32(f, sl^.j.x); { center }
            read32(f, sl^.j.y);
            read32(f, n); { node number }
            fignode(sl, n, sp); { link to node }
            sl^.cl := black { set color }

         end;

         tbline: begin { bold line }

            sl^.typ := tbline; { set type }
            read32(f, sl^.l.s.x); { starting }
            read32(f, sl^.l.s.y); 
            read32(f, sl^.l.e.x); { ending }
            read32(f, sl^.l.e.y);
            sl^.cl := black { set color }

         end;

         tbbox: begin { bold box }

            sl^.typ := tbbox; { set type }
            read32(f, sl^.b.s.x); { starting }
            read32(f, sl^.b.s.y); 
            read32(f, sl^.b.e.x); { ending }
            read32(f, sl^.b.e.y);
            sl^.cl := black { set color }

         end;

         tcell: begin { subcell }

            sl^.typ := tcell; { set type }
            read32(f, sl^.cr.o.x); { read origin }
            read32(f, sl^.cr.o.y);
            read32(f, n); { read cell number }
            readbyt(f, b); { get cell type }
            case b of { cell type }

               0: sl^.cr.ct := ctsch; { schematic }
               1: sl^.cr.ct := ctsym; { symbol }
               2: sl^.cr.ct := ctlay  { layout }

            end;
            { find the corresponding cell }
            lnkcel(n, sl^.cr.cp, sl^.cr.ct); 
            readrot(sl^.rm); { get rotation mode }
            sl^.cl := black { set color }

         end;

         tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss: begin

            { predefined cell }
            case b of { type }

               12: sl^.typ := tnmos;
               13: sl^.typ := tpmos;
               14: sl^.typ := tcap;
               15: sl^.typ := tres;
               16: sl^.typ := tdiode;
               17: sl^.typ := tvdd;
               18: sl^.typ := tvss

            end;
            read32(f, sl^.o.x); { read origin }
            read32(f, sl^.o.y);
            readrot(sl^.rm); { get rotation mode }
            sl^.cl := black { set color }

         end;

         tmet1, tmet2, tpoly, tvia, tndiff, tpdiff, tnwell, 
         tpwell, tccut, tcont: begin

            case sl^.typ of { type }

               tmet1:  sl^.cl := lblue;
               tmet2:  sl^.cl := lcyan;
               tpoly:  sl^.cl := lred;
               tvia:   sl^.cl := gray;
               tndiff: sl^.cl := green;
               tpdiff: sl^.cl := magenta;
               tnwell: sl^.cl := yellow;
               tpwell: sl^.cl := brown;
               tccut:  sl^.cl := dwhite;
               tcont:  sl^.cl := black

            end;
            read32(f, sl^.b.s.x); { starting }
            read32(f, sl^.b.s.y); 
            read32(f, sl^.b.e.x); { ending }
            read32(f, sl^.b.e.y)

         end;

         tinter: begin

            sl^.typ := tinter;
            read32(f, sl^.ir.s.x); { starting }
            read32(f, sl^.ir.s.y); 
            read32(f, sl^.ir.e.x); { ending }
            read32(f, sl^.ir.e.y);
            readclr(sl^.cl); { color }
            readtyp(sl^.itt); { get top layer type }
            readbyt(f, b); { get layer number of top }
            read32(f, n); { get figure number }
            lnkfig(b, n, sp, sl^.ipt); { link to figure }
            readtyp(sl^.itb); { get bottom layer type }
            readbyt(f, b); { get layer number of bottom }
            read32(f, n); { get figure number }
            lnkfig(b, n, sp, sl^.ipb) { link to figure }

         end

      end;
      readtyp(t) { get next figure type }

   end

end;
{}
{**************************************************************

READ SHEET

Reads a single sheet structure, and sets up all parameters
for the sheet, including centering the view of the sheet.

**************************************************************}

procedure readsht(var f: bytfil; sp: shtptr);

var b:  byte;
    n:  integer;
    vi: viewinx;
    si: sizeinx;
    c:  byte;    { character count }
    i:  btsinx;  { index for filename }
    np: nodptr;  { node pointer }
    bp: busptr;  { bus pointer }
    li: laytyp;  { layer index }

{ attach node to bus }

procedure busnode(p: busptr; n: integer; sp: shtptr);

var np, nl: nodptr;

begin

   np := sp^.nl; { index node list }
   while n <> 1 do begin { traverse }

      n := n - 1; { count }
      np := np^.next { next entry }

   end;
   np^.bl := p^.nl; { insert to node list }
   p^.nl := np;
   np^.bh := p { place bus head }

end;

begin

   { clear draw lists }
   for li := ltcell to ltwell do sp^.dl[li] := nil; 
   sp^.nl := nil; { clear node list }
   sp^.bl := nil; { clear bus list }
   sp^.nc := 0; { clear node count }
   { input bounding box }
   readbyt(f, b); { get set/noset flag }
   sp^.bs := b <> 0; { set status }
   read32(f, sp^.bbsx);
   read32(f, sp^.bbex);
   read32(f, sp^.bbsy);
   read32(f, sp^.bbey);
   readbyt(f, b); { get set/noset flag }
   sp^.sbs := b <> 0; { set status }
   read32(f, sp^.sbbsx); 
   read32(f, sp^.sbbex);
   read32(f, sp^.sbbsy);
   read32(f, sp^.sbbey);
   { read node list }
   readbyt(f, c); { read node name count }
   np := nil; { clear last node }
   while c <> 0 do begin { read nodes }

      { get a new node pointer }
      if np = nil then begin new(sp^.nl); np := sp^.nl end
      else begin new(np^.next); np := np^.next end;
      np^.next := nil; { clear next }
      np^.nl := nil; { clear node list }
      np^.sl := nil; { clear smash list }
      np ^.name := '        '; { clear node name }
      i := 1; { index 1st cell character }
      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         np^.name[i] := chr(b); { place character }
         c := c - 1; { count characters }
         i := i + 1

      end;
      readbyt(f, np^.nord); { input ordinal }
      readbyt(f, b); { input temp indicator }
      np^.tmp := b <> 0; { set }
      readbyt(f, c) { read next cell name count }

   end;
   { read bus list }
   readbyt(f, c); { read bus name count }
   bp := nil; { clear last bus }
   while c <> 0 do begin { read busses }

      { get a new bus pointer }
      if bp = nil then begin new(sp^.bl); bp := sp^.bl end
      else begin new(bp^.next); bp := bp^.next end;
      bp^.next := nil; { clear next }
      bp^.nl := nil; { clear node list }
      bp^.sl := nil; { clear smash list }
      bp^.bl := nil; { clear bus list }
      bp ^.name := '        '; { clear bus name }
      i := 1; { index 1st cell character }
      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         bp^.name[i] := chr(b); { place character }
         c := c - 1; { count characters }
         i := i + 1

      end;
      readbyt(f, b); { input temp indicator }
      bp^.tmp := b <> 0; { set }
      { read node list }
      readbyt(f, c); { get node count }
      while c <> 0 do begin { read bus nodes }

         read32(f, n); { get node number }
         busnode(bp, n, sp); { attach node to bus }
         c := c - 1 { count }

      end;
      readbyt(f, c) { read next cell name count }

   end;
   readfigs(f, sp^.dl[ltcell],  sp); { read cells layer }
   readfigs(f, sp^.dl[ltfig],   sp); { read comment/schema layer }
   readfigs(f, sp^.dl[ltovg],   sp); { read overglass cuts layer }
   readfigs(f, sp^.dl[ltvia],   sp); { read via layer }
   readfigs(f, sp^.dl[ltmet2],  sp); { read met2 layer }
   readfigs(f, sp^.dl[ltcont],  sp); { read contact layer }
   readfigs(f, sp^.dl[ltpmd],   sp); { read poly/metals, diff layer }
   readfigs(f, sp^.dl[ltwell],  sp); { read wells layer }
   readfigs(f, sp^.dl[ltism2],  sp); { read met 2 intersections layer }
   readfigs(f, sp^.dl[ltism1],  sp); { read met 1 intersections layer }
   readfigs(f, sp^.dl[ltisply], sp); { read poly intersections layer }
   { set up sheet parameters }
   sp^.ds := dftdg; { set default dot grid size }
   sp^.ls := dftlg; { set default line grid size }
   sp^.js := dftjun; { set default junction size }
   sp^.cs := dftcon; { set default connector size }
   sp^.ts := dftchr; { set standard character scale }
   { clear viewer array }
   for vi := 1 to viewmax do sp^.sv[vi].a := false;
   { clear text size array }
   for si := 1 to sizemax do sp^.sts[si].a := false;
   { clear dot size array }
   for si := 1 to sizemax do sp^.sds[si].a := false;
   { clear line size array }
   for si := 1 to sizemax do sp^.sls[si].a := false;
   { set view to bounding box }
   sp^.vp.v.s.x := curwin^.ar.s.x; { set viewport region }
   sp^.vp.v.s.y := curwin^.ar.s.y;
   sp^.vp.v.e.x := curwin^.ar.e.x;
   sp^.vp.v.e.y := curwin^.ar.e.y;
   fndbnd(sp, sp^.vp.r.s.x, sp^.vp.r.s.y, sp^.vp.s.x); { find bounds view }
   sp^.vp.r.e.x := 
      sp^.vp.r.s.x+realdist(abs(sp^.vp.v.e.x-sp^.vp.v.s.x)+1, sp^.vp.s.x);
   sp^.vp.r.e.y := 
      sp^.vp.r.s.y+realdist(abs(sp^.vp.v.e.y-sp^.vp.v.s.y)+1, sp^.vp.s.y);
   sp^.lvp := sp^.vp { set last view as same }

end;
{}
{**************************************************************

LOAD CELL

Loads the current cell data.

**************************************************************}

procedure loadcell;

var fn: string[12];   { dos interface name }
    i:  btsinx;       { index for filename }
    f:  bytfil;       { file }
    sl: drwptr;       { schematic drawing pointer }
    b:  byte;         { read holder }
    p:  drwptr;
    nl: nodptr;       { node pointer }
    n:  integer;      { node number }
    cp: celptr;       { cell pointer }
    c:  btsinx;       { file name count }
    sp: shtptr;       { sheet pointer }
    vi: viewinx;
    si: sizeinx;

begin

   if button[bfname].s <> '        ' then begin 

      { filename is defined }
      cellst := nil; { clear cell list }
      fn := ''; { clear destination }
      { create filename string }
      for i := 1 to butlen do if button[bfname].s[i] <> ' ' then 
         begin

         fn[0] := succ(fn[0]);
         fn[i] := button[bfname].s[i]

      end;
      fn := concat(fn, '.cel'); { place extention }
      reset(f, fn); { activate file }
      readbyt(f, b); { read signature }
      readbyt(f, b);
      readbyt(f, b);
      readbyt(f, b); { read cell directory mark }
      readbyt(f, b); { read cell name count }
      c := b;
      cp := nil; { clear last cell }
      while c <> 0 do begin { read cell names }

         { get a new cell pointer }
         if cp = nil then begin new(cellst); cp := cellst end
         else begin new(cp^.next); cp := cp^.next end;
         cp^.next := nil; { clear next }
         cp^.schema := nil; { clear out }
         cp^.symbol := nil; 
         cp^.layout := nil;
         cp^.simulate := nil;
         cp^.name := '        '; { clear cell name }
         i := 1; { index 1st cell character }
         while c <> 0 do begin { read cell characters }

            readbyt(f, b); { get a cell character }
            cp^.name[i] := chr(b); { place character }
            c := c - 1; { count characters }
            i := i + 1

         end;
         readbyt(f, b); { read next cell name count }
         c := b

      end;
      cp := cellst; { index first cell }
      readbyt(f, b); { read section mark }
      while b = ord(ccell) do begin { read cells }

         readbyt(f, b); { read cell section mark }
         while b <> ord(ccterm) do begin { read sections }

            if b = ord(ccschema) then begin 

               { schematic section }
               if cp^.schema = nil then { no previous sheet }
                  new(cp^.schema); { create schematic sheet }
               readsht(f, cp^.schema) { read that sheet }

            end else if b = ord(ccsymbol) then begin 

               { symbol section }
               if cp^.symbol = nil then { no previous sheet }
                  new(cp^.symbol); { create symbol sheet }
               readsht(f, cp^.symbol) { read that sheet }

            end else if b = ord(cclayout) then begin 

               { layout section }
               if cp^.layout = nil then { no previous sheet }
                  new(cp^.layout); { create layout sheet }
               readsht(f, cp^.layout) { read that sheet }

            end;
            readbyt(f, b) { get next section mark }

         end;
         cp := cp^.next; { index next cell }
         readbyt(f, b) { get next cell mark }

      end;
      close(f, lock); { close file }
      curwin^.cc := cellst; { set current cell }
      button[bcname].s := cellst^.name; { set current cell name }
      updbut(bcname); { update button }
      dispcell { display cell }

   end

end;
{}
{**************************************************************

PERFORM LOAD CELL

Handles a load cell button push.

**************************************************************}

procedure doloadc;

begin

   if (curbut = bload) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      loadcell; { load current cell }
   resptr { reset pointer device }

end;
{}
{**************************************************************

SAVE CELL

Saves the current cell data.

**************************************************************}

procedure savecell;

var fn: string[12]; { dos interface name }
    i:  btsinx;     { index for filename }
    f:  bytfil;     { file }
    sl: drwptr;     { schematic drawing pointer }
    cp: celptr;     { cell pointer }
    c:  btsinx;     { file name count }
    sp: shtptr;     { sheet pointer }

{ find number of node }

function nodenum(p: nodptr; sp: shtptr): integer;

var n: nodptr;
    c: integer;

begin

   c := 1; { clear count }
   n := sp^.nl; { index node list }
   { count nodes }
   while p <> n do begin c := c + 1; n := n^.next end;
   nodenum := c { return result }

end;

{ find number of bus }

function busnum(p: busptr; sp: shtptr): integer;

var b: busptr;
    c: integer;

begin

   c := 1; { clear count }
   b := sp^.bl; { index bus list }
   { count busses }
   while p <> b do begin c := c + 1; b := b^.next end;
   busnum := c { return result }

end;

{ find number of referenced cell }

function celnum(sp: shtptr): integer;

var cp: celptr;  { cell pointer }
    c:  integer; { count }

begin

   c := 1; { clear count }
   cp := cellst; { index top of cell list }
   while (sp <> cp^.schema) and 
         (sp <> cp^.symbol) and
         (sp <> cp^.layout) do 
      begin c := c + 1; cp := cp^.next end;
   celnum := c { return result }

end;

{ find numbers of referenced figure }

procedure fignum(sp: shtptr;       { base sheet }
                 fp: drwptr;       { figure to find }
                 var ln: laytyp;   { layer number index }
                 var fn: integer); { figure number }

function fndfig(p: drwptr): integer;

var c: integer; { count }

begin

   c := 1; { clear count }
   while (fp <> p) and (p <> nil) do { traverse }
      begin c := c + 1; p := p^.next end;
   if p = nil then c := 0; { set not found }
   fndfig := c { return result }

end;

begin

   ln := ltcell; { set first layer }
   repeat { search layers }

      fn := fndfig(sp^.dl[ln]); { search }
      if fn = 0 then ln := succ(ln) { next layer }

   until fn <> 0 { figure found }

end;

{ output figures }

procedure wrtfigs(sp: shtptr; sl: drwptr);

var ch: chrptr; { character pointer }
    ln: laytyp; { layer index }
    fn: integer; { layer and figure numbers }

begin

   while sl <> nil do begin { write schematic figures }
   
      writebyt(f, ord(sl^.typ)); { output figure type }
      case sl^.typ of { figure }
   
         tline, tbline: begin { line }

            write32(f, sl^.l.s.x); { starting }
            write32(f, sl^.l.s.y); 
            write32(f, sl^.l.e.x); { ending }
            write32(f, sl^.l.e.y)

         end;

         twire: begin { wire }

            write32(f, sl^.w.s.x); { starting }
            write32(f, sl^.w.s.y); 
            write32(f, sl^.w.e.x); { ending }
            write32(f, sl^.w.e.y);
            write32(f, nodenum(sl^.nh, sp)) { node number }

         end;

         tbus: begin { bus }

            write32(f, sl^.bs.l.s.x); { starting }
            write32(f, sl^.bs.l.s.y); 
            write32(f, sl^.bs.l.e.x); { ending }
            write32(f, sl^.bs.l.e.y);
            write32(f, busnum(sl^.bs.bh, sp)) { bus number }

         end;

         tbox, tbbox, tmet1, tmet2, tpoly, tvia, tndiff, 
         tpdiff, tnwell, tpwell, tccut, tcont: begin 

            { box or layer }
            write32(f, sl^.b.s.x); { starting }
            write32(f, sl^.b.s.y); 
            write32(f, sl^.b.e.x); { ending }
            write32(f, sl^.b.e.y)

         end;

         tinter: begin 

            { intersection layer }
            write32(f, sl^.ir.s.x); { starting }
            write32(f, sl^.ir.s.y); 
            write32(f, sl^.ir.e.x); { ending }
            write32(f, sl^.ir.e.y);
            writebyt(f, ord(sl^.cl)); { color }
            writebyt(f, ord(sl^.itt)); { output figure type top }
            fignum(sp, sl^.ipt, ln, fn); { find reference }
            writebyt(f, ord(ln)); { output layer number }
            write32(f, fn); { output figure number }
            writebyt(f, ord(sl^.itb)); { output figure type bottom }
            fignum(sp, sl^.ipb, ln, fn); { find reference }
            writebyt(f, ord(ln)); { output layer number }
            write32(f, fn) { output figure number }

         end;
 
         tarc: begin { arc or circle }

            write32(f, sl^.a.s.x); { starting }
            write32(f, sl^.a.s.y); 
            write32(f, sl^.a.e.x); { ending }
            write32(f, sl^.a.e.y);
            write32(f, sl^.a.c.x); { center }
            write32(f, sl^.a.c.y);
            write32(f, sl^.a.r)   { radius }

         end;

         tchar: begin { char }

            write32(f, sl^.c.r.s.x);   { origin }
            write32(f, sl^.c.r.s.y); 
            write32(f, sl^.c.r.e.x);
            write32(f, sl^.c.r.e.y);
            c := 0; { count characters }
            ch := sl^.c.l; { index top of string }
            { count }
            while ch <> nil do begin c := c + 1; ch := ch^.next end;
            writebyt(f, c); { output count }
            { output string }
            ch := sl^.c.l; { index top of string }
            while ch <> nil do begin 

               writebyt(f, ord(ch^.c)); { output }
               ch := ch^.next { next }

            end;
            write32(f, sl^.c.s);    { scale }
            writebyt(f, ord(sl^.rm)) { output rotation }

         end;

         tjunction, tconnect: begin { junction }

            write32(f, sl^.j.x); { center }
            write32(f, sl^.j.y);
            write32(f, nodenum(sl^.nh, sp)) { node number }

         end;

         tcell: begin { subcell }

            write32(f, sl^.cr.o.x); { output origin }
            write32(f, sl^.cr.o.y);
            write32(f, celnum(sl^.cr.cp)); { output cell number }
            writebyt(f, ord(sl^.cr.ct)); { output cell type }
            writebyt(f, ord(sl^.rm)) { output rotation }

         end;

         tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss: begin 

            { predefined cell }
            write32(f, sl^.o.x); { output origin }
            write32(f, sl^.o.y);
            writebyt(f, ord(sl^.rm)) { output rotation }

         end

      end;
      sl := sl^.next { link next entry }

   end;
   writebyt(f, 0) { terminate figure list }

end;

{ output sheet }

procedure wrtsht(sp: shtptr);

var np: nodptr; { node pointer }
    bp: busptr; { bus pointer }
    c:  byte;   { character count }
    i:  btsinx; { index for filename }

begin

   { output bounding box }
   writebyt(f, ord(sp^.bs)); { output set/unset status }
   write32(f, sp^.bbsx);
   write32(f, sp^.bbex);
   write32(f, sp^.bbsy);
   write32(f, sp^.bbey);
   writebyt(f, ord(sp^.sbs)); { output set/unset status }
   write32(f, sp^.sbbsx);
   write32(f, sp^.sbbex);
   write32(f, sp^.sbbsy);
   write32(f, sp^.sbbey);
   { output node list }
   np := sp^.nl; { index top node }
   while np <> nil do begin { output nodes }

      c := 0; { count node characters }
      for i := 1 to butlen do 
         if np^.name[i] <> ' ' then c := c + 1; 
      writebyt(f, c); { output }
      { output name }
      for i := 1 to butlen do 
         if np^.name[i] <> ' ' then writebyt(f, ord(np^.name[i]));
      writebyt(f, np^.nord); { output ordinal }
      writebyt(f, ord(np^.tmp)); { output temp indicator }
      np := np^.next { next entry }

   end;
   writebyt(f, 0); { terminate node list }
   { output bus list }
   bp := sp^.bl; { index top bus }
   while bp <> nil do begin { output busses }

      c := 0; { count bus characters }
      for i := 1 to butlen do 
         if bp^.name[i] <> ' ' then c := c + 1; 
      writebyt(f, c); { output }
      { output name }
      for i := 1 to butlen do 
         if bp^.name[i] <> ' ' then writebyt(f, ord(bp^.name[i]));
      writebyt(f, ord(bp^.tmp)); { output temp indicator }
      c := 0; { initalize node count }
      np := bp^.nl; { index 1st node in list }
      while np <> nil do begin { traverse }

         c := c + 1; { count nodes }
         np := np^.bl { next entry }

      end;
      writebyt(f, c); { output count }
      np := bp^.nl; { index 1st node in list }
      while np <> nil do begin { traverse }

         write32(f, nodenum(np, sp)); { node number }
         np := np^.bl { next entry }

      end;
      bp := bp^.next { next entry }

   end;
   writebyt(f, 0); { terminate bus list }
   wrtfigs(sp, sp^.dl[ltcell]); { write cell layer }
   wrtfigs(sp, sp^.dl[ltfig]);  { write comment/schema layer }
   wrtfigs(sp, sp^.dl[ltovg]);  { write overglass cuts layer }
   wrtfigs(sp, sp^.dl[ltvia]);  { write via layer }
   wrtfigs(sp, sp^.dl[ltmet2]); { write met2 layer }
   wrtfigs(sp, sp^.dl[ltcont]); { write contact layer }
   wrtfigs(sp, sp^.dl[ltpmd]);  { write poly/metals, diff layer }
   wrtfigs(sp, sp^.dl[ltwell]); { write wells layer }
   wrtfigs(sp, sp^.dl[ltism2]); { write met 2 intersections layer }
   wrtfigs(sp, sp^.dl[ltism1]); { write met 1 intersections layer }
   wrtfigs(sp, sp^.dl[ltisply]) { write poly intersections layer }

end;

begin

   if button[bfname].s <> '        ' then begin 

      { filename is defined }
      fn := ''; { clear destination }
      { create filename string }
      for i := 1 to butlen do if button[bfname].s[i] <> ' ' then begin

         fn[0] := succ(fn[0]);
         fn[i] := button[bfname].s[i]

      end;
      fn := concat(fn, '.cel'); { place extention }
      rewrite(f, fn); { activate file }
      writebyt(f, ord('M')); { write signature }
      writebyt(f, ord('C'));
      writebyt(f, ord('F'));
      writebyt(f, ord(cceldir)); { mark cell directory }
      cp := cellst; { index top of cell list }
      while cp <> nil do begin { output cell names }
         
         c := 0; { count cellname characters }
         for i := 1 to butlen do 
            if cp^.name[i] <> ' ' then c := c + 1; 
         writebyt(f, c); { output }
         { output cellname }
         for i := 1 to butlen do 
            if cp^.name[i] <> ' ' then writebyt(f, ord(cp^.name[i]));
         cp := cp^.next { next cell }
   
      end;
      writebyt(f, 0); { mark end of section } 
      cp := cellst; { index top of cell list }
      while cp <> nil do begin { output cells }
   
         writebyt(f, ord(ccell)); { output cell marker }
         sp := cp^.schema; { index schematic cell }
         if sp <> nil then begin { output schematic section }

            writebyt(f, ord(ccschema)); { mark schematic section }
            wrtsht(sp) { output sheet contents }

         end;
         sp := cp^.symbol; { index symbol cell }
         if sp <> nil then begin { output symbol section }

            writebyt(f, ord(ccsymbol)); { mark symbol section }
            wrtsht(sp) { output sheet contents }

         end;
         sp := cp^.layout; { index layout cell }
         if sp <> nil then begin { output layout section }

            writebyt(f, ord(cclayout)); { mark layout section }
            wrtsht(sp) { output sheet contents }

         end;
         writebyt(f, ord(ccterm)); { terminate cell }
         cp := cp^.next { link next cell }
   
      end;
      writebyt(f, ord(ccfterm)); { terminate file }
      close(f, lock) { close file }

   end

end;
{}
{**************************************************************

PERFORM SAVE CELL

Handles a save cell button push.

**************************************************************}

procedure dosavec;

begin

   if (curbut = bsave) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      savecell; { save current cell }
   resptr { reset pointer device }

end;
{$p}
{**************************************************************

CREATE FILES LIST

Creates a list of the files in the current directory.
The files are sorted for alphabetical order.

**************************************************************}

procedure fillst(var p: filptr);

var fp, fps, fp1, fp2, fp3, fp4: filptr;

begin

   getlst('????????.cel ', fp); { make files list }
   { sort list for alphabetical order }
   fps := nil; { clear target list }
   while fp <> nil do begin { process entries }

      fp1 := fp; { index entry }
      fp := fp^.next; { gap source list }
      fp2 := fps; { index target top }
      fp3 := fp2; { echo }
      fp4 := nil; { clear last }
      while fp3 <> nil do begin { traverse target }
  
         if fp1^.name < fp2^.name then 
            fp3 := nil { flag found }
         else begin { next entry }

            fp4 := fp2; { save last }
            fp2 := fp2^.next; { go next }
            fp3 := fp2 { echo }

         end

      end;
      if fp4 = nil then begin { insert at top }

         fp1^.next := fps;
         fps := fp1

      end else begin { insert in middle }

         fp4^.next := fp1;
         fp1^.next := fp2

      end

   end;
   p := fps { place sorted list }

end;
{}
{**************************************************************

LAY DOWN LIST FORMAT GRID

Places the list grid format in the active area, as used for
cell and file name displays.

**************************************************************}

procedure lstfmt;

var si: integer;   { screen index }

begin

   { clear active area }
   block(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y, 
         curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, yellow);
   { lay down grid }
   line(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.s.y, 
        curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.e.y, black);
   si := curwin^.cs^.vp.v.s.x+127; 
   while si < curwin^.cs^.vp.v.e.x do begin

      line(screen, si, curwin^.cs^.vp.v.s.y, si, 
           curwin^.cs^.vp.v.e.y, blue);
      line(screen, si+1, curwin^.cs^.vp.v.s.y, si+1, 
           curwin^.cs^.vp.v.e.y, black);
      si := si+128

   end;
   si := curwin^.cs^.vp.v.s.y+16-2;
   while si < curwin^.cs^.vp.v.e.y do begin

      line(screen, curwin^.cs^.vp.v.s.x, si, 
           curwin^.cs^.vp.v.e.x, si, black);
      line(screen, curwin^.cs^.vp.v.s.x, si+1, 
           curwin^.cs^.vp.v.e.x, si+1, black);
      si := si + 16

   end;
   line(screen, curwin^.cs^.vp.v.s.x, curwin^.cs^.vp.v.e.y, 
        curwin^.cs^.vp.v.e.x, curwin^.cs^.vp.v.e.y, black)

end;
{}
{**************************************************************

DISPLAY FILES LIST

Fills the active area with the files in the files list, at the
current offset.

**************************************************************}

procedure dspfils;

var fp:   filptr;  { files list }
    bs:   butstr;  { string entry }
    i:    btsinx;  { index for same }
    x, y: byte;    { character position }
    dn:   integer; { display number holder }

begin

   lstfmt; { place onscreen formatting }
   x := 0; { index 1st character of active area }
   y := 8;
   fp := dsplst; { index top of list }
   dn := dspnum; { set number of first entry }
   { find the starting entry }
   while dn <> 1 do begin fp := fp^.next; dn := dn - 1 end;
   while (fp <> nil) and (x < 56) do begin { process entries }

      { transfer filename to compatible store }
      bs := '        '; { clear }
      i := 1; { initalize index }
      while (fp^.name[i] <> '.') and (fp^.name[i] <> ' ') do 
         begin 

         bs[i] := fp^.name[i];
         i := i + 1

      end;
      { place this string }
      plcstr(x*16, y*16, bs, 8, black, yellow, true);   
      { increment to next character }
      if y < 47 then y := y + 1
      else begin { end of collumn, next }

         x := x + 8;
         y := 8

      end;
      fp := fp^.next { index next entry }

   end;
   { if there is more, say so }
   if fp <> nil then butact(bnext) else butina(bnext); 
   if dspnum <> 1 then butact(blast) else butina(blast)

end;
{}
{**************************************************************

DISPLAY AVALIBLE FILES

Fills the active area with all the files that can be found in
the current directory. Handles both the start and end of the
mode.

**************************************************************}

procedure files;

var fp:   filptr;  { files list }
    bs:   butstr;  { string entry }
    i:    btsinx;  { index for same }
    x, y: byte;    { character position }
    si:   integer; { screen index }

begin

   if not button[bdisplay].act then begin { button not active }

      butact(bdisplay); { activate button }
      modbut := bdisplay; { activate mode }
      fillst(dsplst);
      dspnum := 1; { set current display entry }
      rescur; { remove cursor }
      dspfils; { display file names }
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end else begin { restore regular display }

      butina(bdisplay); { deactivate button }
      butina(blast); 
      butina(bnext);
      modbut := dsmbut; { restore old mode }
      redraw { refresh the display }

   end
      
end;
{}
{**************************************************************

CHECK FILE SELECT

Called when the file display is active, handles both lighting
up files and detecting a selected file to be loaded.
Cusor must be in active area.

**************************************************************}

procedure chkfile;

var x, y, xi, yi: byte;
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    fp:           filptr; { files list }
    i:            btsinx; { index for same }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(x*16, y*16, bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;   
      dspsav := bs 

   end

end;

begin

   x := (cur.x - (cur.x mod 128)) div 16; { find character cell }
   y := cur.y div 16;
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      plcstr(dspbut.x, dspbut.y, dspsav, 8, black, yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 8;
      fp := dsplst; { index top of list }
      f := false; { set not found }
      while fp <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            { transfer filename to compatible store }
            bs := '        '; { clear }
            i := 1; { initalize index }
            while (fp^.name[i] <> '.') and (fp^.name[i] <> ' ') do 
               begin 

               bs[i] := fp^.name[i];
               i := i + 1

            end;
            if puck.b[1].a then begin { activate cell }
   
               { place this string }
               plcstr(x*16, y*16, bs, 8, black, lgreen, true);  
               button[bfname].s := bs; { place cell name to filename }
               { update that button }
               updbut(bfname); { update button }
               loadcell; { load up the cell }             
               butina(bdisplay); { deactivate button }
               butina(blast); 
               butina(bnext);
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s); 
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv)

            end else if puck.b[2].a then begin { set placement cell }

               { find matching cell }
               b := blibv; { index 1st button }
               while (b < blibd) and 
                     (button[b].s <> bs) do b := succ(b);
               if button[b].s = bs then begin

                  { matching cell, delete from queue }
                  for b := b to blibd do { move buttons down }
                     button[b].s := button[succ(b)].s;        
                  button[blibd].s := '        ' { clear last cell }     

               end;
               { move down cell stack }
               for b := blibd downto bliba do 
                  button[b].s := button[pred(b)].s;
               button[blibv].s := bs; { place file name to cell }
               { refresh buttons }
               for b := blibv to blibd do
                  updbut(b); { update button }
               butina(bdisplay); { deactivate button }
               butina(blast); 
               butina(bnext);
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s); 
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv); 
               redraw; { refresh the display }

            end else selbut; { select button }
            f := true; { flag found }
            fp := nil { flag done }

         end else begin

            { increment to next character }
            if yi < 47 then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 8

            end;
            fp := fp^.next { index next entry }

         end

      end;
      if not f then begin { select empty space }

         bs := '        '; { clear }
         selbut { select the button }

      end

   end;
   resptr { reset pointer device }
   
end;   
{}
{**************************************************************

PERFORM FILES LIST MODE

**************************************************************}

procedure dofiles;

var dn, dn1: integer; { display number }
    fp:      filptr; { files list }

begin

   if (curbut = bdisplay) and (puck.b[1].a or puck.b[2].a or 
                               puck.b[3].a) then
      files { activate/deactivate display }
   else if (curbut in [bnext, blast]) and 
           (puck.b[1].a or puck.b[2].a or puck.b[3].a) then begin

      { display next section }
      fp := dsplst; { index top of list }
      { set display number }
      if curbut = bnext then dn := dspnum+7*40
      else dn := dspnum-7*40;
      dn1 := dn; { copy }
      if dn > 0 then begin { didn't back to far }

         while dn1 <> 1 do begin { index that entry }
     
            if fp <> nil then fp := fp^.next; { next entry }
            dn1 := dn1 - 1 { count }

         end;
         if fp <> nil then begin { there is a next page }

            dspnum := dn; { set new offset }
            dspfils { display new list }

         end

      end
      
   end else if modbut = bdisplay then chkfile; { check each file button }
   resptr { reset pointer device }

end;
{}
{**************************************************************

DISPLAY AVALIBLE CELLS

Fills the active area with all the cells in the current file.
Handles both the start and end of the mode.

**************************************************************}

procedure displayc;

var p:    celptr; { pointer for cells }
    x, y: byte;   { character position }

begin

   if not button[bcells].act then begin { button not active }

      butact(bcells); { activate button }
      modbut := bcells;
      rescur; { remove cursor }
      lstfmt; { set up screen }
      x := 0; { index 1st character of active area }
      y := 8;
      p := cellst; { index top of list }
      while p <> nil do begin { process entries }

         { place this string }
         plcstr(x*16, y*16, p^.name, 8, black, yellow, true);   
         { increment to next character }
         if y < 47 then y := y + 1
         else begin { end of collumn, next }

            x := x + 8;
            y := 8

         end;
         p := p^.next { index next entry }

      end;
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end else begin { restore regular display }

      butina(bcells); { deactivate button }
      modbut := dsmbut; { restore old mode }
      redraw { refresh the display }

   end
      
end;
{}
{**************************************************************

CHECK CELL SELECT

Called when the cell display is active, handles both lighting
up cells and detecting a selected cell to be loaded.
Cusor must be in active area.

**************************************************************}

procedure chkcell;

var x, y, xi, yi: byte;
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    p:            celptr; { cell pointer }
    i:            btsinx; { index for same }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(x*16, y*16, bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;   
      dspsav := bs 

   end

end;

begin

   x := (cur.x - (cur.x mod 128)) div 16; { find character cell }
   y := cur.y div 16;
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      plcstr(dspbut.x, dspbut.y, dspsav, 8, black, yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 8;
      p := cellst; { index top of list }
      f := false; { set not found }
      while p <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            bs := p^.name; { save name }
            if puck.b[1].a then begin { activate cell }
   
               rescur; { remove cursor }
               { place this string }
               plcstr(x*16, y*16, bs, 8, black, lgreen, true);  
               setcur; { replace cursor }
               button[bcname].s := bs; { place cell name to cellname }
               { update that button }
               updbut(bcname); { update button }
               curwin^.cc := p; { set current cell }
               celstk := nil; { clear cell stack }
               dispcell; { display current cell }
               butina(bcells); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s); 
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv)

            end else if puck.b[2].a then begin { set placement cell }

               { not already selected for placement }
               placel := p; { place cell pointer }
               { find matching cell }
               b := bcelv; { index 1st button }
               while (b < bceld) and 
                     (button[b].s <> bs) do b := succ(b);
               if button[b].s = bs then begin

                  { matching cell, delete from queue }
                  for b := b to bceld do { move buttons down }
                     button[b].s := button[succ(b)].s;        
                  button[bceld].s := '        ' { clear last cell }     

               end;
               { move down cell stack }
               for b := bceld downto bcela do 
                  button[b].s := button[pred(b)].s;
               button[bcelv].s := bs; { place cell name to cellname }
               { refresh buttons }
               for b := bcelv to bceld do
                  updbut(b); { update button }
               butina(bcells); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s); 
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv);
               butact(bcelv); { set button active }
               redraw { refresh the display }

            end else selbut; { select button }
            f := true; { flag found }
            p := nil { flag done }

         end else begin

            { increment to next character }
            if yi < 47 then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 8

            end;
            p := p^.next { index next entry }

         end

      end;
      if not f then begin { select empty space }

         bs := '        '; { clear }
         selbut { select the button }

      end

   end;
   resptr { reset pointer device }
   
end;   
{}
{**************************************************************

PERFORM CELLS LIST MODE

**************************************************************}

procedure docells;

begin

   if (curbut = bcells) and (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      displayc { activate/deactivate display }
   else if modbut = bcells then chkcell; { check each file button }
   resptr { reset pointer device }

end;
{}
{**************************************************************

LOAD LIBRARY CELL

Loads the library cell data.
Presently just skips to the required cell and loads that. To
be complete, we must account for a cell that has subcells. This
means that other cells may also need to be copied, and it is not
possible to predict the exact tree before we have read the entire
deck.
One solution: we perform a pass that extracts the tree for the
entire file, then a second pass to load the needed cells. This
first pass can be merged with the primary cell pickup.
What to do about duplications ? if an incoming cell matches 
the name of an existing cell, it may replace it, be replaced by
it, or generate an error. Discarding the incoming cell seems like
the most "library like" solution.

**************************************************************}

procedure loadlib(lcp: celptr);

var fn:           string[12];   { dos interface name }
    i:            btsinx;       { index for filename }
    f:            bytfil;       { file }
    sl:           drwptr;       { schematic drawing pointer }
    b:            byte;         { read holder }
    p:            drwptr;
    nl:           nodptr;       { node pointer }
    n:            integer;      { node number }
    cp, cp1, cp2: celptr;       { cell pointer }
    c:            btsinx;       { file name count }
    sp:           shtptr;       { sheet pointer }
    vi:           viewinx;
    si:           sizeinx;

{ skip figures list }

procedure skpfigs;

var b:  byte; { byte holder }
    c1: byte; { character count }

{ link cell from cell number }

procedure lnkcel;

var p:        celptr;  { cell pointer }
    d:        boolean; { duplicate flag }
    sp1, sp2: shtptr;  { sheet pointer }

begin

   new(sp1); { get a sheet entry }
   p := libcel; { index 1st cell }
   { find that cell }
   while n <> 1 do begin p := p^.next; n := n - 1 end;
   sp1^.csp := p; { set cell reference }
   sp2 := cp^.schema; { index list }
   d := false; { set no duplicate }
   while sp2 <> nil do begin { traverse list }
 
      if sp2^.csp = p then d := true; { duplicate found }
      sp2 := sp2^.next { next entry }

   end;
   if not d then begin { not duplicate, link in }

      sp1^.next := cp^.schema;
      cp^.schema := sp1

   end

end;

begin

   readbyt(f, b); { get figure type }
   while b <> 0 do begin { skip schematic figures }

      case b of { figure }

         1, 2, 8, 9, 19, 20, 21, 22, 23, 24, 25, 26, 27: begin 

            { line, box, layer }
            read32(f, n); { starting }
            read32(f, n); 
            read32(f, n); { ending }
            read32(f, n)

         end;

         3: begin { arc or circle }

            read32(f, n); { starting }
            read32(f, n); 
            read32(f, n); { ending }
            read32(f, n);
            read32(f, n); { center }
            read32(f, n);
            read32(f, n)   { radius }

         end;

         4: begin { char }

            read32(f, n);   { origin }
            read32(f, n); 
            read32(f, n); 
            read32(f, n); 
            readbyt(f, b); { get character count }
            c := b;
            for c1 := 1 to c do begin { read string }
         
               readbyt(f, b) { get a character }

            end; 
            read32(f, n); { scale }
            readbyt(f, b) { rotation }

         end;
     
         5, 6: begin { wire, bus }

            read32(f, n); { starting }
            read32(f, n); 
            read32(f, n); { ending }
            read32(f, n);
            read32(f, n) { node/bus number }

         end;

         7, 11: begin { junction }

            read32(f, n); { center }
            read32(f, n);
            read32(f, n) { node number }

         end;

         10: begin { subcell }

            read32(f, n); { read origin }
            read32(f, n);
            read32(f, n); { read cell number }
            readbyt(f, b); { get cell type }
            { find the corresponding cell }
            if cp <> nil then lnkcel; 
            readbyt(f, b) { rotation }

         end;

         12, 13, 14, 15, 16, 17, 18: begin

            { predefined cell }
            read32(f, n); { read origin }
            read32(f, n);
            readbyt(f, b) { rotation }

         end;

         28: begin 

            { intersection }
            read32(f, n); { starting }
            read32(f, n); 
            read32(f, n); { ending }
            read32(f, n);
            readbyt(f, b); { color }
            readbyt(f, b); { top layer }
            read32(f, n); { top figure }
            readbyt(f, b); { top layer }
            read32(f, n) { top figure }
            
         end;


      end;
      readbyt(f, b) { get next figure }

   end

end;

{ skip sheet with cell structure read }

procedure skpsht(cp: celptr);

var b: byte;
    n: integer;
    c: byte;    { character count }

begin

   { skip bounding box }
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n);
   read32(f, n); 
   read32(f, n);
   read32(f, n);
   read32(f, n);
   { skip node list }
   readbyt(f, c); { read node name count }
   while c <> 0 do begin { skip nodes }

      while c <> 0 do begin { skip cell characters }

         readbyt(f, b); { skip a cell character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { skip ordinal }
      readbyt(f, b); { skip temp indicator }
      readbyt(f, c) { read next cell name count }

   end;
   { skip bus list }
   readbyt(f, c); { read bus name count }
   while c <> 0 do begin { read busses }

      while c <> 0 do begin { skip name characters }

         readbyt(f, b); { skip a name character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { skip temp indicator }
      { skip node list }
      readbyt(f, c); { get node count }
      while c <> 0 do begin { skip bus nodes }

         read32(f, n); { skip node number }
         c := c - 1 { count }

      end;
      readbyt(f, c) { read next cell name count }

   end;
   skpfigs; { skip comment/schema layer }
   skpfigs; { skip overglass cuts layer }
   skpfigs; { skip via/contact layer }
   skpfigs; { skip poly/metals, diff layer }
   skpfigs; { skip wells layer }
   skpfigs; { skip met 2 intersections layer }
   skpfigs; { skip met 1 intersections layer }
   skpfigs  { skip poly intersections layer }

end;

{ mark cell reference tree }

procedure mrkcel(cp: celptr);

var sp: shtptr;

begin

   cp^.ref := true; { set top cell referenced }
   sp := cp^.schema; { index 1st linkage }
   while sp <> nil do begin { traverse }

      mrkcel(sp^.csp); { mark that tree }
      sp := sp^.next { next entry }

   end
      
end;
 
begin

   fn := ''; { clear destination }
   { create filename string }
   for i := 1 to butlen do if libnam[i] <> ' ' then begin

      fn[0] := succ(fn[0]);
      fn[i] := libnam[i]

   end;
   fn := concat(fn, '.cel'); { place extention }
   reset(f, fn); { activate file }
   { perform cell structure pass }
   readbyt(f, b); { read signature }
   readbyt(f, b);
   readbyt(f, b);
   readbyt(f, b); { read cell directory mark }
   { skip cell directory (which we already have read) }
   readbyt(f, b); { read cell name count }
   c := b;
   while c <> 0 do begin { read cell names }

      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { read next cell name count }
      c := b

   end;
   cp := libcel; { index first cell }
   readbyt(f, b); { read section mark }
   while b = ord(ccell) do begin

      cp^.ref := false; { set cell not referenced }
      { cell marked and not our cell, skip entire cell }
      readbyt(f, b); { read cell section mark }
      while b <> ord(ccterm) do begin { read sections }

         if (b = ord(ccschema)) or (b = ord(ccsymbol)) then 
            skpsht(cp); { skip entire sheet }
         readbyt(f, b) { get next section mark }

      end;
      cp := cp^.next; { index next cell }
      readbyt(f, b) { get next cell mark }

   end;
   { mark all referenced cells }
   mrkcel(lcp);
   { form cell cross reference }
   cp := libcel; { index first cell }
   while cp <> nil do begin { traverse }

      if cp^.ref then begin { cell is to be loaded }

         cp1 := cellst; { find matching cell in current list }
         cp2 := nil; { clear found entry }
         while cp1 <> nil do begin { search }

            if cp^.name = cp1^.name then { found, save }
               cp2 := cp1;
            cp1 := cp1^.next

         end;
         if cp2 = nil then begin { no match }

            cp2 := cellst; { find last cell in current list }
            while cp2^.next <> nil do cp2 := cp2^.next;
            { get a new cell pointer }
            new(cp2^.next); 
            cp2 := cp2^.next;
            cp2^.next := nil; { clear next }
            cp2^.schema := nil; { clear out }
            cp2^.symbol := nil; 
            cp2^.layout := nil;
            cp2^.simulate := nil;
            cp2^.name := cp^.name { set cell name }

         end;
         cp^.cross := cp2 { place cross reference }

      end;
      cp := cp^.next { next cell }
      
   end;
   { perform cell load pass }
   reset(f);
   readbyt(f, b); { read signature }
   readbyt(f, b);
   readbyt(f, b);
   readbyt(f, b); { read cell directory mark }
   { skip cell directory (which we already have read) }
   readbyt(f, b); { read cell name count }
   c := b;
   while c <> 0 do begin { read cell names }

      while c <> 0 do begin { read cell characters }

         readbyt(f, b); { get a cell character }
         c := c - 1 { count characters }

      end;
      readbyt(f, b); { read next cell name count }
      c := b

   end;
   cp := libcel; { index first cell }
   readbyt(f, b); { read section mark }
   while b = ord(ccell) do begin

      { cell entry }
      readbyt(f, b); { read cell section mark }
      while b <> ord(ccterm) do begin { read sections }

         if (b = ord(ccschema)) or (b = ord(ccsymbol)) then begin

            { sheet }
            if cp^.ref then begin { cell is referenced }

               if b = ord(ccschema) then begin 

                  { schematic section }
                  if cp^.cross^.schema = nil then begin 

                     { no previous sheet }
                     new(cp^.cross^.schema); { create schematic sheet }
                     readsht(f, cp^.cross^.schema) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.schema) then
                        readsht(f, cp^.cross^.schema)
                  else skpsht(nil) { skip sheet }
                     
               end else if b = ord(ccsymbol) then begin 

                  { symbol section }
                  if cp^.cross^.symbol = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.symbol); { create symbol sheet }
                     readsht(f, cp^.cross^.symbol) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.symbol) then
                        readsht(f, cp^.cross^.symbol)
                  else skpsht(nil) { skip sheet }

               end else if b = ord(cclayout) then begin 

                  { layout section }
                  if cp^.cross^.layout = nil then begin

                     { no previous sheet }
                     new(cp^.cross^.layout); { create symbol sheet }
                     readsht(f, cp^.cross^.layout) { read that sheet }

                  end else { if sheet is blank anyways }
                     if not boundset(cp^.cross^.layout) then
                        readsht(f, cp^.cross^.layout)
                  else skpsht(nil) { skip sheet }

               end

            end else skpsht(nil) { skip entire sheet }

         end;
         readbyt(f, b) { get next section mark }

      end;
      cp := cp^.next; { index next cell }
      readbyt(f, b) { get next cell mark }

   end;
   close(f, lock) { close file }

end;
{}
{**************************************************************

DISPLAY LIBRARY CELLS

Creates a display of the cells in a file library.
The currently selected button is used as the filename button.

**************************************************************}

procedure displayl;

var fn:    string[12]; { dos interface name }
    i:     btsinx;     { index for filename }
    f:     bytfil;     { file }
    b:     byte;       { read holder }
    cp, p: celptr;     { cells lists }
    c:     btsinx;     { file name count }
    x, y:  byte;       { character position }

begin

   if not button[curbut].act and 
      (button[curbut].s <> '        ') then begin 

      butact(curbut); { activate button }
      modbut := curbut;
      libnam := button[curbut].s; { save filename }
      libbut := curbut; { save button }
      libcel := nil; { clear cell list }
      fn := ''; { clear destination }
      { create filename string }
      for i := 1 to butlen do if button[curbut].s[i] <> ' ' then
         begin

         fn[0] := succ(fn[0]);
         fn[i] := button[curbut].s[i]

      end;
      fn := concat(fn, '.cel'); { place extention }
      reset(f, fn); { activate file }
      readbyt(f, b); { read signature }
      readbyt(f, b);
      readbyt(f, b);
      readbyt(f, b); { read cell directory mark }
      readbyt(f, b); { read cell name count }
      c := b;
      cp := nil; { clear last cell }
      while c <> 0 do begin { read cell names }

         { get a new cell pointer }
         if cp = nil then begin new(libcel); cp := libcel end
         else begin new(cp^.next); cp := cp^.next end;
         cp^.next := nil; { clear next }
         cp^.name := '        '; { clear cell name }
         cp^.schema := nil; { clear list for later use }
         i := 1; { index 1st cell character }
         while c <> 0 do begin { read cell characters }

            readbyt(f, b); { get a cell character }
            cp^.name[i] := chr(b); { place character }
            c := c - 1; { count characters }
            i := i + 1

         end;
         readbyt(f, b); { read next cell name count }
         c := b

      end;
      close(f, lock); { close file }
      rescur; { remove cursor }
      lstfmt; { set up screen }
      x := 0; { index 1st character of active area }
      y := 8;
      p := libcel; { index top of list }
      while p <> nil do begin { process entries }

         { place this string }
         plcstr(x*16, y*16, p^.name, 8, black, yellow, true);   
         { increment to next character }
         if y < 47 then y := y + 1
         else begin { end of collumn, next }

            x := x + 8;
            y := 8

         end;
         p := p^.next { index next entry }

      end;
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end else begin { restore regular display }

      butina(curbut); { deactivate button }
      modbut := dsmbut; { restore old mode }
      redraw { refresh the display }

   end

end;
{}
{**************************************************************

CHECK LIBRARY CELL SELECT

Called when the library cell display is active, handles both 
lighting up cells and detecting a selected cell to be loaded.
Cusor must be in active area.

**************************************************************}

procedure chklcell;

var x, y, xi, yi: byte;
    f:            boolean; { cell found flag }
    bs:           butstr; { string entry }
    p:            celptr; { cell pointer }
    i:            btsinx; { index for same }
    b:            buttyp;

procedure selbut;

begin

   { place this string }
   if not ((dspbut.x = x) and (dspbut.y = y)) then begin

      rescur; { remove cursor }
      plcstr(x*16, y*16, bs, 8, black, yellow, true);
      setcur; { restore cursor }
      dspbut.x := x; { save selected button }
      dspbut.y := y;   
      dspsav := bs 

   end

end;

begin

   x := (cur.x - (cur.x mod 128)) div 16; { find character cell }
   y := cur.y div 16;
   if not ((dspbut.x = x) and (dspbut.y = y)) and
      ((dspbut.x <> 0) or (dspbut.y <> 0)) then begin

      { deselect old button }
      rescur; { remove cursor }
      plcstr(dspbut.x, dspbut.y, dspsav, 8, black, yellow, true);
      setcur; { replace cursor }
      dspbut.x := 0; { clear selected display button }
      dspbut.y := 0

   end;
   if inactive(cur) then begin { in active area }

      { find that button (if it exists) }
      xi := 0; { index 1st character of active area }
      yi := 8;
      p := libcel; { index top of list }
      f := false; { set not found }
      while p <> nil do begin { process entries }

         if (xi = x) and (yi = y) then begin { found }

            bs := p^.name; { save name }
            if puck.b[1].a then begin { activate cell }
   
               loadlib(p); { load library cell to internal }
               p := cellst; { index top cell }
               { found our cell }
               while p^.name <> bs do p := p^.next;
               rescur; { remove cursor }
               { place this string }
               plcstr(x*16, y*16, bs, 8, black, lgreen, true);  
               setcur; { replace cursor }
               button[bcname].s := bs; { place cell name to cellname }
               updbut(bcname); { update button }
               curwin^.cc := p; { set current cell }
               celstk := nil; { clear cell stack }
               dispcell; { display current cell }
               butina(libbut); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s); 
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update button }
               updbut(bcposyv)

            end else if puck.b[2].a then begin { set placement cell }

               loadlib(p); { load library cell to internal }
               p := cellst; { index top cell }
               { found our cell }
               while p^.name <> bs do p := p^.next;
               { not already selected for placement }
               placel := p; { place cell pointer }
               { find matching cell }
               b := bcelv; { index 1st button }
               while (b < bceld) and 
                     (button[b].s <> bs) do b := succ(b);
               if button[b].s = bs then begin

                  { matching cell, delete from queue }
                  for b := b to bceld do { move buttons down }
                     button[b].s := button[succ(b)].s;        
                  button[bceld].s := '        ' { clear last cell }     

               end;
               { move down cell stack }
               for b := bceld downto bcela do 
                  button[b].s := button[pred(b)].s;
               button[bcelv].s := bs; { place cell name to cellname }
               { refresh buttons }
               for b := bcelv to bceld do
                  updbut(b); { update button }
               butina(libbut); { deactivate button }
               modbut := dsmbut; { restore old mode }
               { redisplay position indicator }
               realstr(rcur.x*pixsiz, button[bcposxv].s); 
               realstr(rcur.y*pixsiz, button[bcposyv].s);
               updbut(bcposxv); { update buttons }
               updbut(bcposyv); 
               butact(bcelv); { set button active }
               redraw { refresh the display }

            end else selbut; { select button }
            f := true; { flag found }
            p := nil { flag done }

         end else begin

            { increment to next character }
            if yi < 47 then yi := yi + 1
            else begin { end of collumn, next }

               xi := xi + 8;
               yi := 8

            end;
            p := p^.next { index next entry }

         end

      end;
      if not f then begin { select empty space }

         bs := '        '; { clear }
         selbut { select the button }

      end

   end;
   resptr { reset pointer device }
   
end;   
{}
{**************************************************************

PERFORM LIBRARIES LIST MODE

**************************************************************}

procedure dolibs;

begin

   if (curbut = blibv) and puck.b[2].a then
      edtlibv { edit library name }
   else if (curbut in [blibv, bliba, blibb, blibc, blibd]) and 
               (puck.b[1].a or puck.b[2].a or puck.b[3].a) then
      displayl { activate/deactivate display }
   else if modbut = blibv then chklcell; { check each file button }
   resptr { reset pointer device }

end;
{}
end. { module }


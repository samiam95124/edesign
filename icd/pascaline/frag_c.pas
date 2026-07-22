{***************************************************************

FRAGMENT C: UI support routines ported from icda.pas (1992)

Ported per PORTING-SPEC.md. This fragment contains the screen
level draw/text helpers (liner, plcchr, plcstr), the button
initializer and autoarrangers, the vector character generator,
number formatting, and the in-button editor and parsers.

Omitted from the original (see spec):

   elapsed, wait  - timer externals, replaced by graphics.timer
                    logic in the main program.
   getlst, entnam - DOS directory search (intdos), not ported.
   resptr         - pointer (puck) hardware, not ported.

***************************************************************}
{}
{**************************************************************

LINE DRAW REAL

Draws a line between points indicated by coordinate pairs
expressed as real coordinates, in the given color.
The line is clipped to the given region.

port: the original liner was assembly; reconstructed here
from the bliner (bold line real) pattern in icdb.pas, using
the ported viewc/clip/line routines.

***************************************************************}

procedure liner(x1, y1, x2, y2: integer; { line start and end }
                c:              color;   { line color }
                r:              region); { clipping region }

var draw: boolean;
    s, e: point;

begin

   s.x := x1; { place coordinates }
   s.y := y1;
   e.x := x2;
   e.y := y2;
   viewc(s, curwin^.cs^.vp); { convert coordinates }
   viewc(e, curwin^.cs^.vp);
   clip(s.x, s.y, e.x, e.y, draw, r); { clip line }
   if draw then line(screen, s.x, s.y, e.x, e.y, c)

end;
{ port: the plcchr/plcstr copies that were here duplicated the icdb layer
  versions and were removed at integration }
{**************************************************************

INITALIZE BUTTON ARRAY

Loads all the button descriptors into the button array.

**************************************************************}

procedure inibut;

var i: buttyp; { index for buttons }

{ set up single botton entry }

{ port: uiscl - interface pixel constants scaled to character cell }

procedure plcbut(ox, oy: integer;  { screen location }
                 st:     butstr;   { string }
                 ln:     btslen;   { port: was btsinx; may be 0 }
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
   w := uiscl(11); { set margin width }
   for i := 1 to ln do w := w+chrwidth(st[i])+uiscl(1);
   with button[b] do begin

      r.s.x   := ox; { place origin }
      r.s.y   := oy;
      r.e.x   := ox+w-1; { place end }
      r.e.y   := oy+uiscl(23)-1;
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
   plcbut(uiscl(909),  uiscl(156), 'In      ', 2, bin,
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);       
   plcbut(uiscl(936),  uiscl(156), 'Out     ', 3, bout,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);      
   plcbut(uiscl(916),  uiscl(131), 'Pan     ', 3, bpan,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(uiscl(982),  uiscl(131), 'Full    ', 4, bbound, 
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);    
   plcbut(uiscl(976),  uiscl(156), 'Back    ', 4, bback,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(915),  uiscl(181), 'A       ', 1, bviewa, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(181), 'B       ', 1, bviewb, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(964),  uiscl(181), 'C       ', 1, bviewc, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(988),  uiscl(181), 'D       ', 1, bviewd, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(160), 'E       ', 1, bviewe, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(160), 'F       ', 1, bviewf, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(160), 'G       ', 1, bviewg, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(160), 'H       ', 1, bviewh, 
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(905),  uiscl(206), 'Dots    ', 4, bdots,  
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []); 
   plcbut(uiscl(951),  uiscl(206), '+000.00M', 8, bdotsv, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);    
   plcbut(uiscl(915),  uiscl(232), 'A       ', 1, bdotsva, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(232), 'B       ', 1, bdotsvb,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(965),  uiscl(232), 'C       ', 1, bdotsvc,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(988),  uiscl(232), 'D       ', 1, bdotsvd,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(208), 'E       ', 1, bdotsve,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(208), 'F       ', 1, bdotsvf,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(208), 'G       ', 1, bdotsvg,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(208), 'H       ', 1, bdotsvh,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(904),  uiscl(257), 'Lines   ', 5, blines,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []); 
   plcbut(uiscl(951),  uiscl(257), '+000.00M', 8, blinev,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);   
   plcbut(uiscl(915),  uiscl(282), 'A       ', 1, blineva,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(282), 'B       ', 1, blinevb,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(965),  uiscl(282), 'C       ', 1, blinevc,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(988),  uiscl(282), 'D       ', 1, blinevd,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(256), 'E       ', 1, blineve,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(256), 'F       ', 1, blinevf,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(256), 'G       ', 1, blinevg,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(256), 'H       ', 1, blinevh,    
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(904),  uiscl(307), 'Undo    ', 4, bundo,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);     
   plcbut(uiscl(904),  uiscl(332), 'Redo    ', 4, bredo,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(899),  uiscl(357), 'Save    ', 4, bsaveb,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);    
   plcbut(uiscl(943),  uiscl(357), 'Cut     ', 3, bcutb,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(976),  uiscl(357), 'Paste   ', 5, bpasteb,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);   
   plcbut(uiscl(915),  uiscl(382), 'A       ', 1, bblka,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(382), 'B       ', 1, bblkb,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(964),  uiscl(382), 'C       ', 1, bblkc,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(989),  uiscl(382), 'D       ', 1, bblkd,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(352), 'E       ', 1, bblke,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(352), 'F       ', 1, bblkf,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(352), 'G       ', 1, bblkg,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(352), 'H       ', 1, bblkh,      
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(900),  uiscl(532), 'Del     ', 3, bdelete,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);   
   plcbut(uiscl(952),  uiscl(532), 'Rip     ', 3, bdeleten,   
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, []);   
   plcbut(uiscl(900),  uiscl(582), 'Up      ', 2, bup,        
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, [ftlnxt]);
   plcbut(uiscl(932),  uiscl(582), 'Dwn     ', 3, bdown,      
          [smschema, smsymbol, smlayout], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(908),  uiscl(557), 'Mir     ', 3, birmir,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(986),  uiscl(532), '0       ', 1, bir0,       
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(997),  uiscl(557), '90      ', 2, bir90,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(982),  uiscl(582), '180     ', 3, bir180,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(962),  uiscl(557), '270     ', 3, bir270,     
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, right, but, []);
   plcbut(uiscl(967),  uiscl(657), 'Name    ', 4, bname,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]);     
   plcbut(uiscl(912),  uiscl(657), 'Trc     ', 3, btrace,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);    
   plcbut(uiscl(910),  uiscl(682), '        ', 8, bnamev,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, fld, [ftlnxt]);
   plcbut(uiscl(981),  uiscl(682), '000     ', 3, bnord,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(uiscl(907),  uiscl(707), 'Cel     ', 3, bplsym,     
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(uiscl(907),  uiscl(732), 'Psch    ', 4, bplsch,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(uiscl(981),  uiscl(708), 'Erc     ', 3, berc,       
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);      
   plcbut(uiscl(949),  uiscl(307), 'Snap    ', 4, bsnap,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(949),  uiscl(332), 'Any     ', 3, bany,       
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(uiscl(992),  uiscl(307), '45      ', 2, b45,        
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);       
   plcbut(uiscl(992),  uiscl(332), '90      ', 2, b90,        
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);       
   plcbut(uiscl(902),  uiscl(457), 'Line    ', 4, bline,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);     
   plcbut(uiscl(900),  uiscl(507), 'Bline   ', 5, bbline,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(941),  uiscl(457), 'Box     ', 3, bbox,       
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);      
   plcbut(uiscl(961),  uiscl(507), 'Bbox    ', 4, bbbox,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(903),  uiscl(482), 'Cir     ', 3, bcircle,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, [ftlnxt]);   
   plcbut(uiscl(946),  uiscl(482), 'Arc     ', 3, barc,       
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);      
   plcbut(uiscl(979),  uiscl(457), 'Wire    ', 4, bwire,      
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]);     
   plcbut(uiscl(984),  uiscl(482), 'Bus     ', 3, bbus,       
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);      
   plcbut(uiscl(908),  uiscl(607), 'Junc    ', 4, bjunction,  
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, [ftlnxt]); 
   plcbut(uiscl(950),  uiscl(607), '+000.00M', 8, bjuncv,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(uiscl(908),  uiscl(632), 'Conn    ', 4, bconnect,   
          [smschema, smsymbol], black, lgreen, black, yellow, 
          right, but, []);
   plcbut(uiscl(950),  uiscl(632), '+000.00M', 8, bconnv,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, 
          right, fld, []);
   plcbut(uiscl(905),  uiscl(407), 'Text    ', 4, btext,      
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, right, but, []);     
   plcbut(uiscl(951),  uiscl(407), '+000.00M', 8, btsizv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, fld, []);     
   plcbut(uiscl(916),  uiscl(432), 'A       ', 1, btexta,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(940),  uiscl(432), 'B       ', 1, btextb,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(965),  uiscl(432), 'C       ', 1, btextc,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(989),  uiscl(432), 'D       ', 1, btextd,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(960),  uiscl(400), 'E       ', 1, btexte,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(400), 'F       ', 1, btextf,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(992),  uiscl(400), 'G       ', 1, btextg,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(1008), uiscl(400), 'H       ', 1, btexth,     
          [], 
          black, lgreen, black, yellow, right, but, []);
   { layout specific buttons }
   plcbut(uiscl(896),  uiscl(560), 'Met 1   ', 5, bmet1,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(560), 'Vis     ', 3, bmet1vis,   
          [smlayout], black, lblue,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(576), 'Met 2   ', 5, bmet2,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(576), 'Vis     ', 3, bmet2vis,   
          [smlayout], black, lcyan,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(592), 'Poly    ', 4, bpoly,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(592), 'Vis     ', 3, bpolyvis,   
          [smlayout], black, lred,   black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(608), 'Via     ', 3, bvia,       
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(608), 'Vis     ', 3, bviavis,    
          [smlayout], black, gray,   black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(624), 'Cont    ', 4, bcont,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(624), 'Vis     ', 3, bcontvis,   
          [smlayout], white, black,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(640), 'Ndiff   ', 5, bndiff,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(640), 'Vis     ', 3, bndiffvis,  
          [smlayout], black, green,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(656), 'Pdiff   ', 5, bpdiff,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(656), 'Vis     ', 3, bpdiffvis,  
          [smlayout], black, magenta, black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(672), 'Nwell   ', 5, bnwell,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(672), 'Vis     ', 3, bnwellvis,  
          [smlayout], black, yellow, black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(688), 'Pwell   ', 5, bpwell,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(688), 'Vis     ', 3, bpwellvis,  
          [smlayout], black, brown,  black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(704), 'Ccut    ', 4, bccut,      
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(976),  uiscl(704), 'Vis     ', 3, bccutvis,   
          [smlayout], black, dwhite, black, white, right, but, []);
   plcbut(uiscl(896),  uiscl(720), 'Insides ', 7, binsides,   
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(896),  uiscl(736), 'Place   ', 5, bplace,     
          [smlayout], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(896),  uiscl(752), 'Drc     ', 3, bdrc,       
          [smlayout], black, lgreen, black, yellow, right, but, []);
   { simulator specific buttons }
   plcbut(uiscl(896),  uiscl(496), 'Dwave   ', 5, bdwave,     
          [smsimulate], black, lgreen, black, yellow, right, but, []);
   plcbut(uiscl(896),  uiscl(512), 'Awave   ', 5, bawave,     
          [smsimulate], black, lgreen, black, yellow, right, but, []);
   { define top side buttons }
   plcbut(uiscl(256),  0,   'Symbol  ', 6, bsymbol,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(352),  0,   'Schemat ', 7, bschema,    
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);   
   plcbut(uiscl(464),  0, 'Layout  ', 6, blayout,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);   
   plcbut(uiscl(560),  0, 'Simulate', 8, bsimulate,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []); 
   plcbut(0,    uiscl(32), 'Load    ', 4, bload,  
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(uiscl(64),   uiscl(32), 'Save    ', 4, bsave,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(uiscl(128),  uiscl(32), '        ', 8, bfname,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(0,    uiscl(48), 'Newfile ', 7, bnew,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);      
   plcbut(uiscl(128),  uiscl(48), '        ', 8, bcname, 
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(0,    uiscl(64), 'Files   ', 5, bdisplay,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);  
   plcbut(uiscl(128),  uiscl(64), 'Newcell ', 7, bnewc,   
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(128),  uiscl(80), 'Print   ', 5, bprint,  
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(0,    uiscl(80), 'Cells   ', 5, bcells,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(0,    uiscl(96), 'Exit    ', 4, bexit,   
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);     
   plcbut(0,    uiscl(112), 'LAST    ', 4, blast,   
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(64),   uiscl(112), 'NEXT    ', 4, bnext,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(32), '        ', 8, blibv,    
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(48), '        ', 8, bliba, 
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(64), '        ', 8, blibb,  
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(80), '        ', 8, blibc,  
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(96), '        ', 8, blibd,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(32), '        ', 8, bcelv,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(48), '        ', 8, bcela,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(64), '        ', 8, bcelb,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(80), '        ', 8, bcelc,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(384),  uiscl(96), '        ', 8, bceld,      
          [{smschema, smsymbol, smlayout}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(256),  uiscl(16), 'Proximty', 8, bprox,      
          [{smschema, smsymbol, smlayout, smsimulate}], black, lgreen, 
          black, yellow, top, but, []);
   plcbut(uiscl(512),  uiscl(32), 'Nmos    ', 4, bnmos,      
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(592),  uiscl(32), 'Pmos    ', 4, bpmos,      
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(512),  uiscl(48), 'Res     ', 3, bres,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(560),  uiscl(48), 'Cap     ', 3, bcap,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(608),  uiscl(48), 'Diode   ', 5, bdiode,     
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(512),  uiscl(64), 'Vdd     ', 3, bvdd,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(592),  uiscl(64), 'Vss     ', 3, bvss,       
          [{smschema, smsymbol}], black, lgreen, black, yellow, top, but, []);
   plcbut(uiscl(651),  uiscl(52), 'Ruler   ', 5, bruler,     
          [smschema, smsymbol, smlayout, smsimulate], 
          black, lgreen, black, yellow, top, but, []);    
   plcbut(uiscl(703),  uiscl(52), '+000.00M', 8, brulerv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(651),  uiscl(77), '    X   ', 5, brulx,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(703),  uiscl(77), '+000.00M', 8, brulxv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(651),  uiscl(102), '    Y   ', 5, bruly,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(703),  uiscl(102), '+000.00M', 8, brulyv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(771),  uiscl(10), 'Pos X   ', 5, bcposx,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(10), '+000.00M', 8, bcposxv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(31), '    Y   ', 5, bcposy,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(31), '+000.00M', 8, bcposyv,    
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(52), 'Org X   ', 5, borgx,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(52), '+000.00M', 8, borgxv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(77), '    Y   ', 5, borgy,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(77), '+000.00M', 8, borgyv,     
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(772),  uiscl(102), 'Scale   ', 5, bscl,       
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(825),  uiscl(102), '00000   ', 8, bsclv,      
          [{smschema, smsymbol, smlayout, smsimulate}], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(16), 'Rul time', 8, brtime,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(16), '+000.00M', 8, brtimev,   
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(32), 'Rul volt', 8, brvolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(32), '+000.00M', 8, brvoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(48), 'Pos time', 8, bctime,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(48), '+000.00M', 8, bctimev,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(64), 'Pos volt', 8, bcvolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(64), '+000.00M', 8, bcvoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(80), 'Org time', 8, botime,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(80), '+000.00M', 8, botimev,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(432),  uiscl(96), 'Org volt', 8, bovolt,     
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   plcbut(uiscl(560),  uiscl(96), '+000.00M', 8, bovoltv,    
          [smsimulate], 
          black, lgreen, black, yellow, top, fld, []);
   { buttons for printer control pop-up }
   plcbut(uiscl(448),  uiscl(416), '+000.00M', 8, bmaxx,      
          [smprint], black, lgreen, black, yellow, none, fld, []);      
   plcbut(uiscl(448),  uiscl(432), '+000.00M', 8, bmaxy,  
          [smprint], black, lgreen, black, yellow, none, fld, []); 
   plcbut(uiscl(448),  uiscl(448), '+000.00M', 8, boffx,   
          [smprint], black, lgreen, black, yellow, none, fld, []);
   plcbut(uiscl(448),  uiscl(464), '+000.00M', 8, boffy,   
          [smprint], black, lgreen, black, yellow, none, fld, []); 
   plcbut(uiscl(448),  uiscl(544), 'A       ', 1, bseta, 
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(464),  uiscl(544), 'B       ', 1, bsetb,   
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(480),  uiscl(544), 'C       ', 1, bsetc,  
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(496),  uiscl(544), 'D       ', 1, bsetd,     
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(512),  uiscl(544), 'E       ', 1, bsete,    
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(528),  uiscl(544), 'F       ', 1, bsetf,    
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(544),  uiscl(544), 'G       ', 1, bsetg,   
          [smprint], black, lgreen, black, yellow, none, but, []);
   plcbut(uiscl(560),  uiscl(544), 'H       ', 1, bseth,  
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

   { port: uiscl - interface pixel constants scaled to character cell }
   plcbut(bmbtop,    curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.s.y,
                     curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.s.y+uiscl(2+5)-1);
   plcbut(bmbleft,   curwin^.wv.r.s.x,       curwin^.wv.r.s.y+uiscl(25),
                     curwin^.wv.r.s.x+uiscl(2+5)-1, curwin^.wv.r.e.y-uiscl(25));
   plcbut(bmbright,  curwin^.wv.r.e.x-uiscl(2+5)+1, curwin^.wv.r.s.y+uiscl(25),
                     curwin^.wv.r.e.x,       curwin^.wv.r.e.y-uiscl(25));
   plcbut(bmbbottom, curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.e.y-uiscl(2+5)+1,
                     curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.e.y);
   plcbut(bmbtoplt,  curwin^.wv.r.s.x,       curwin^.wv.r.s.y,
                     curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.s.y+uiscl(2+5)-1);
   plcbut(bmbtopll,  curwin^.wv.r.s.x,       curwin^.wv.r.s.y,
                     curwin^.wv.r.s.x+uiscl(2+5)-1, curwin^.wv.r.s.y+uiscl(25));
   plcbut(bmbtoprt,  curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.s.y,
                     curwin^.wv.r.e.x,       curwin^.wv.r.s.y+uiscl(2+5)-1);
   plcbut(bmbtoprr,  curwin^.wv.r.e.x-uiscl(2+5)+1, curwin^.wv.r.s.y,
                     curwin^.wv.r.e.x,       curwin^.wv.r.s.y+uiscl(25));
   plcbut(bmbbotlb,  curwin^.wv.r.s.x,       curwin^.wv.r.e.y-uiscl(2+5)+1,
                     curwin^.wv.r.s.x+uiscl(25),    curwin^.wv.r.e.y);
   plcbut(bmbbotll,  curwin^.wv.r.s.x,       curwin^.wv.r.e.y-uiscl(25),
                     curwin^.wv.r.s.x+uiscl(2+5)-1, curwin^.wv.r.e.y);
   plcbut(bmbbotrb,  curwin^.wv.r.e.x-uiscl(25),    curwin^.wv.r.e.y-uiscl(2+5)+1,
                     curwin^.wv.r.e.x,       curwin^.wv.r.e.y);
   plcbut(bmbbotrr,  curwin^.wv.r.e.x-uiscl(2+5)+1, curwin^.wv.r.e.y-uiscl(25),
                     curwin^.wv.r.e.x,       curwin^.wv.r.e.y);
   plcbut(bctrl,     curwin^.wv.r.s.x+uiscl(2+5+2),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.s.x+uiscl(2+5+2+19)-1,
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);
   plcbut(bmovew,    curwin^.wv.r.s.x+uiscl(2+5+2+19+2),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.e.x-uiscl(29+19)-uiscl(2)-1,
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);
   plcbut(bmin,      curwin^.wv.r.e.x-uiscl(29+19),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.e.x-uiscl(29)-1,
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);
   plcbut(bmax,      curwin^.wv.r.e.x-uiscl(29)+uiscl(2),
                     curwin^.wv.r.s.y+uiscl(2+5+2),
                     curwin^.wv.r.e.x-uiscl(2+5+2),
                     curwin^.wv.r.s.y+uiscl(2+5+2+19)-1);

end;
{}
{**************************************************************

ARRANGE BUTTONS TOP

Arranges the buttons for the current window. Called after
a window size change.

**************************************************************}

{ port: uiscl - button cell height/spacing scaled to character cell
  (also marginr/tfit/arrbutr/adjlin below) }

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
            y := y+uiscl(23)+uiscl(1+2); { next row }       
            if y > bm then begin { error, overflow }

               writeln('Error: window overflow');
               while true do

            end

         end;
         button[b].r.s.x := x; { set button position }
         button[b].r.s.y := y;
         button[b].r.e.x := x+button[b].m;
         button[b].r.e.y := y+uiscl(23);
         x := x+button[b].m+uiscl(1+2) { find next button position }
  
      end;
      if b = bdisplay then b := bnull { end of list }
      else if b <> bnull then b := succ(b) { next button } 

   end;
   y := y+uiscl(23); { next row }
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

               x1 := x1+button[b1].m+uiscl(1+2); { find next button position }
               b1 := succ(b1);
               l := l+button[b1].m+uiscl(1+2); { find virtual button length }
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
            y := y+uiscl(23)+uiscl(1+2); { next row }       
            if y+uiscl(23)+uiscl(1+2) > bm then begin 

               { overlow, end }
               fg := false; { set bad fit }
               b := bnull

            end

         end;
         x := x+button[b].m+uiscl(1+2) { find next button position }
  
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
            l := l+button[b1].m+uiscl(1+2) { find virtual button length }

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

   al := (curwin^.rm.e.x-(x-uiscl(1+2))) div bc; { find adjustment length }
   rmd := (curwin^.rm.e.x-(x-uiscl(1+2))) mod bc; { find adjustment remainder }
   for i := 1 to bc do begin { proportion button spacing }

      { distribute remainder among buttons, starting left }
      if rmd <> 0 then begin add := 1; rmd := rmd-1 end
      else add := 0;
      button[fb].r.s.x := xl; { set button position }
      button[fb].r.s.y := y;
      button[fb].r.e.x := xl+button[fb].m+al+add;
      button[fb].r.e.y := y+uiscl(23);
      { find next button position }
      xl := xl+button[fb].m+al+add+uiscl(1+2);
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

               x1 := x1+button[b1].m+uiscl(1+2); { find next button position }
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
            y := y+uiscl(23)+uiscl(1+2); { next row }       
            xl := x; { set first on line index }
            bc := 1 { set first count }

         end;
         bc := bc + 1; { count buttons on line }
         x := x+button[b].m+uiscl(1+2) { find next button position }
  
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

      else { port: characters without figures are ignored }

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
               var p:  btslen; { port: was btsinx; edit drives to 0 }
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
{}
{ UNRESOLVED: identifiers referenced by this fragment but defined
  elsewhere:

  From the base layer (hand-written adapter in icdui.pas):

     plchr      - place single character (replaces bitmap setchr)
     chrwidth   - character pixel width (replaces alphal[])
     chrheight  - character pixel height (replaces constant 16)

  From the ported icdb.pas fragment (appears before this one):

     viewc      - convert real point to screen point (used by liner)
     clip       - Cohen-Sutherland line clipper (used by liner)
     line       - viewport level line draw
     block      - viewport level filled block draw
     setpix     - viewport level set pixel
     setcur     - draw cursor into place (used by edit/getint/getrnm)
     rescur     - remove cursor (used by edit/getint/getrnm)

  From other fragments (icdc.pas port):

     plcmsg     - place message string (used by edit/getint/getrnm)

  From icddef (types and globals, all assumed visible):

     color, region, point, viewport, buttyp, butrec, butstr,
     btsinx, modset, formset, loctyp, distyp, msgtyp, button,
     curwin, screen, curscm, cur, edtpos, errmsg, blank,
     chrwdt, chrhdt, scalem, butlen, microchr

  Notes:

  - No keyboard externals are referenced: edit/edtbut take the
    already-read character(s) as parameters in the original code,
    so no uigetchar/uicharrdy hooks were needed.
  - elapsed/wait were not ported (spec rule 5); no ported routine
    in this fragment called wait.
  - getlst/entnam (DOS intdos directory search) and resptr (puck
    hardware) were not ported. }

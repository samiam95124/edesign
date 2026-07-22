{******************************************************************************

ICD common definitions module

Port of define.pas (constants and types) merged with the var section of
common.pas (shared globals) from the original SVS Pascal ICD sources.

******************************************************************************}

module icddef;

const

      maxint    = 2147483647; { redefine for 32 bits }

      tgborder  = 5;     { target border space }
      pi        = 3.141592653589793;
      linmax    = 10000; { maximum length of screen line }
      scalem    = 100;   { scale accuracy multiplier }
      normscale = 300;   { normal magnification scale }
      dotmin    = 8;     { minimum grid dot spacing to display dot grid }
      linemin   = 8;     { minimum grid dot spacing to display line grid }
      bbborder  = 10;    { bounding box default border }
      butlen    = 8;     { number of characters in a button }
      msglen    = 35;    { number of characters in a message }
      ttllen    = 40;    { number of characters in window title }
      dragmgn   = 10;    { number of pixels to consitute a drag }
      dotmax    = 1024;  { number of dots in a vector }
      chrwdt    = 4;     { width factor of vector character }
      chrhdt    = 11;    { height factor of vector character }
      chrspc    = 2;     { space between vector characters }
      dftsiz    = 0.000001; { default size of virtual pixel (meters) }
      dftsizl   = 0.000000001; { same for layout only }
      dftchr    = 300;   { default size of vector character (in virtual
                           pixels) }
      dftdg     = 1500; { default dot grid spacing (in vpixels) }
      dftlg     = 30000; { default line grid spacing (in vpixels) }
      dftjun    = 750; { default size of junction (in vpixels) }
      dftcon    = 1000; { default size of connector (in vpixels) }
      dftlgsim  = 4800; { default line grid for simulation }
      dftdgsim  = 300; { default dot grid for simulation }
      viewmax   = 8; { number of stored views }
      sizemax   = 8; { number of stored text sizes }
      blkmax    = 8; { number of stored blocks }
      prtmax    = 8; { number of printer parameter saves }
      { special character definitions }
      copychr   = 0; { copright character }
      microchr  = 1; { micro character }
      selrng    = 5; { range to be within to select object
                       (in screen pixels) }
      { printer buffer dementions. These are set to the maximum of
        the dementions of any printer we support.
        Presently, exactly one line is contained, based on the
        theory that the last line can be printed while the next
        line is prepared. }
      pbxmax    = 2519;
      pbymax    = 23;
      timeout   = 30000; { number of idle hundreth seconds
                         before screen blank (5 min) }
      introt    = 3000; { number of idle hundreth seconds
                          before automatic intro proceed (30 sec) }
      detime    = 1000; { device error message hold time (10 sec) }
      figet     = 3; { figet factor for pointer idle detect }
      timesiz   = 8.33333333e-13; { time value of virtual pixel }
      voltsiz   = 0.001666666666; { voltage value of virtual pixel }
      trcsiz    = 4800; { height of trace, in virtual pixels }
      stpsiz    = 1200; { length of trace step, in virtual pixels }
      fillen    = 13; { number of characters in filename }
      labmax    = 20;  { number of character in label }

type

     { port: integer/real/byte redefinitions deleted; sbyte deleted (unused) }

     point  = record x, y: integer end; { coordinate point }
     rpoint = record x, y: real end; { demension pair (meters) }
     bpoint = record x, y: byte end; { char cell coordinates }
     region = record s, e: point end; { rectangular region }
     sarc   = record { arc specification }

                 s: point; { start point }
                 e: point; { end point (c-clockwise) }
                 c: point; { center }
                 r: integer { radius }

              end;
     color  = (black, blue, green, cyan, red, magenta, brown,
               dwhite, gray, lblue, lgreen, lcyan, lred, lmagenta,
               yellow, white);
     chrptr = ^chrrec; { character record pointer }
     chrrec = record { character record }

                 c:    char; { the character }
                 next: chrptr { next entry }

              end;
     chars  = record { character string specification }

                 r: region;  { enclosure box }
                 l: chrptr; { character list start }
                 s: integer { character scale }

              end;
     shtptr  = ^shtrec; { sheet record pointer }
     celtyp = (ctsch, ctsym, ctlay); { placement cell type }
     celref = record { cell subreference }

                 o:  point;  { upper left origin }
                 cp: shtptr; { subcell }
                 ct: celtyp; { type of cell }

              end;
     nodptr = ^nodety; { node entry pointer }
     drwptr = ^drwety; { drawing entry pointer }
     namptr = ^namrec; { name save pointer }
     btsinx = 1..butlen; { index for button string }
     btslen = 0..butlen; { port: length of button string (0 allowed) }
     butstr = packed array [btsinx] of char;
     msginx = 1..msglen; { index for message string }
     msgstr = packed array [msginx] of char;
     msgtyp = (mnone,    { none (blank message) }
               minvn,    { invalid number }
               movfn);   { integer overflow }
     ttlinx = 1..ttllen; { title string index }
     ttlstr = packed array [ttlinx] of char;
     busptr = ^busety; { bus entry pointer }
     busfig = record { bus figure entry }

                 l:  region; { start and end of bus line }
                 bl: drwptr; { list link for lines in bus }
                 bh: busptr  { link to attached bus }

              end;
     { port: lininx/linarr (screen pixel save buffer) deleted; save-under
       replaced by xor rubber-banding }
     { button codes }
     buttyp = (bnull,     { no button }
               bin,       { zoom in }
               bout,      { zoom out }
               bpan,      { pan }
               bbound,    { go bounding box }
               bback,     { last view }
               bviewa,    { view A }
               bviewb,    { view B }
               bviewc,    { view C }
               bviewd,    { view D }
               bviewe,    { view E }
               bviewf,    { view F }
               bviewg,    { view G }
               bviewh,    { view H }
               bdots,     { toggle dot grid }
               bdotsv,    { grid size variable }
               bdotsva,   { dot grid size A }
               bdotsvb,   { dot grid size B }
               bdotsvc,   { dot grid size C }
               bdotsvd,   { dot grid size D }
               bdotsve,   { dot grid size E }
               bdotsvf,   { dot grid size F }
               bdotsvg,   { dot grid size G }
               bdotsvh,   { dot grid size H }
               blines,    { toggle line grid }
               blinev,    { line grid size variable }
               blineva,   { line grid size A }
               blinevb,   { line grid size B }
               blinevc,   { line grid size C }
               blinevd,   { line grid size D }
               blineve,   { line grid size E }
               blinevf,   { line grid size F }
               blinevg,   { line grid size G }
               blinevh,   { line grid size H }
               bundo,     { undo }
               bredo,     { redo }
               bsaveb,    { save block }
               bcutb,     { cut block }
               bpasteb,   { paste block }
               bblka,     { block save A }
               bblkb,     { block save B }
               bblkc,     { block save C }
               bblkd,     { block save D }
               bblke,     { block save E }
               bblkf,     { block save F }
               bblkg,     { block save G }
               bblkh,     { block save H }
               bdelete,   { delete }
               bdeleten,  { delete network }
               bname,     { set node name }
               btrace,    { trace node }
               bnamev,    { node name }
               bnord,     { name ordinal }
               bsnap,     { toggle snap }
               b45,       { line limit 45 deg }
               b90,       { line limit 90 deg }
               bany,      { line limit any }
               bline,     { line draw mode }
               bbline,    { bold line }
               bbox,      { box draw mode }
               bbbox,     { bold box }
               bcircle,   { circle draw mode }
               barc,      { arc draw mode }
               bwire,     { wire place mode }
               bbus,      { bus place mode }
               bjunction, { junction place mode }
               bjuncv,    { junction value field }
               bconnect,  { connector place mode }
               bconnv,    { connector value field }
               btext,     { place text }
               btsizv,    { text size variable }
               btexta,    { text size a }
               btextb,    { text size b }
               btextc,    { text size c }
               btextd,    { text size d }
               btexte,    { text size e }
               btextf,    { text size f }
               btextg,    { text size g }
               btexth,    { text size h }
               bmet1,     { metal one }
               bmet1vis,  { metal one visibility }
               bmet2,     { metal two }
               bmet2vis,  { metal two visibility }
               bpoly,     { poly }
               bpolyvis,  { poly visibility }
               bvia,      { via }
               bviavis,   { via visibility }
               bcont,     { contact }
               bcontvis,  { contact visibility }
               bndiff,    { N-diff }
               bndiffvis, { N-diff visibility }
               bpdiff,    { P-diff }
               bpdiffvis, { P-diff visibility }
               bnwell,    { N-well }
               bnwellvis, { N-well visibility }
               bpwell,    { P-well }
               bpwellvis, { P-well visibility }
               bccut,     { contact cut }
               bccutvis,  { contact cut visibility }
               binsides,  { show insides }
               bplsch,    { place schematic mode }
               bplsym,    { place symbol mode }
               bup,       { up cell level }
               bdown,     { down cell level }
               berc,      { run rules check }
               birmir,    { instance mirror }
               bir0,      { instance rotate 0 }
               bir90,     { instance rotate 90 }
               bir180,    { instance rotate 180 }
               bir270,    { instance rotate 270 }
               bsymbol,   { select symbol sheet }
               bschema,   { select schema sheet }
               blayout,   { select layout sheet }
               bsimulate, { select simulate sheet }
               bload,     { load cell }
               bsave,     { save cell }
               bfname,    { filename }
               bcname,    { cellname }
               bexit,     { exit program }
               bnew,      { clear file }
               bnewc,     { clear cell }
               bprint,    { print sheet }
               bcells,    { display cells }
               blast,     { last page }
               bnext,     { next page }
               blibv,     { current library select }
               bliba,     { lib queue a }
               blibb,     { lib queue b }
               blibc,     { lib queue c }
               blibd,     { lib queue d }
               bcelv,     { current cell select }
               bcela,     { cell queue a }
               bcelb,     { cell queue b }
               bcelc,     { cell queue c }
               bceld,     { cell queue d }
               bprox,     { proximity indicator }
               bnmos,     { place nmos }
               bpmos,     { place pmos }
               bres,      { place resistor }
               bcap,      { place capacitor }
               bdiode,    { place diode }
               bvdd,      { place vdd }
               bvss,      { place vss }
               bruler,    { ruler }
               brulerv,   { ruler variable }
               brulx,     { ruler x }
               brulxv,    { ruler x variable }
               bruly,     { ruler y }
               brulyv,    { ruler y variable }
               bcposx,    { cursor position x }
               bcposxv,   { cursor position x variable }
               bcposy,    { cursor position y }
               bcposyv,   { cursor position y variable }
               borgx,     { origin x }
               borgxv,    { origin x variable }
               borgy,     { origin y }
               borgyv,    { origin y variable }
               bscl,      { scale }
               bsclv,     { scale variable }
               bmaxx,     { maximum demension printer x }
               bmaxy,     { maximum demension printer y }
               boffx,     { offset demension x }
               boffy,     { offset demension y }
               bseta,     { print setup saves }
               bsetb,
               bsetc,
               bsetd,
               bsete,
               bsetf,
               bsetg,
               bseth,
               bplace,    { place cell }
               bdrc,      { drc }
               bdwave,    { digital waveform edit }
               bawave,    { analog waveform edit }
               bctime,    { cursor time indicator }
               bctimev,   { cursor time value value }
               bcvolt,    { cursor voltage indicator }
               bcvoltv,   { cursor voltage value }
               botime,    { cursor time indicator }
               botimev,   { cursor time value value }
               bovolt,    { cursor voltage indicator }
               bovoltv,   { cursor voltage value }
               brtime,    { ruler time indicator }
               brtimev,   { ruler time value }
               brvolt,    { ruler voltage indicator }
               brvoltv,   { ruler voltage value }
               bmbtop,    { move bar top }
               bmbleft,   { move bar left }
               bmbright,  { move bar right }
               bmbbottom, { move bar bottom }
               bmbtoplt,  { move bar top left top }
               bmbtopll,  { move bar top left left }
               bmbtoprt,  { move bar top right top }
               bmbtoprr,  { move bar top right right }
               bmbbotlb,  { move bar bottom left bottom }
               bmbbotll,  { move bar bottom left left }
               bmbbotrb,  { move bar bottom right bottom }
               bmbbotrr,  { move bar bottom right right }
               bmax,      { maximize }
               bmin,      { minimize }
               bctrl,     { window control }
               bmovew,    { move window bar }
               bdisplay); { display avalible cells }
     butsts =  (unset, inact, act, select, una); { button status }
     figtyp = (tend, tline, tbox, tarc, tchar, twire, tbus,
               tjunction, tbline, tbbox, tcell, tconnect,
               tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss,
               tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
               tnwell, tpwell, tccut, tinter, tcont, ttrc, tatrc);
     rotmod = (rm0, rm90, rm180, rm270, rmm0, rmm90, rmm180,
               rmm270);
     { screen menu modes }
     scnmod = (smsymbol, smschema, smlayout, smsimulate,
               smprint);
     modset = set of scnmod; { set of same }
     loctyp = (top, right, none); { location of button }
     distyp = (but, fld, cust); { entry/display field }
     { button placement formatting }
     formtyp = (ftnone,   { no format }
                ftnext,   { start this button on new line }
                ftnobrk,  { do not break this button from last }
                ftlnxt);  { link next button }
     formset = set of formtyp; { set of formatters }
     butrec =  record { button descriptors }

                  r:   region;  { bounding box of button }
                  s:   butstr;  { button string }
                  l:   btslen;  { port: was btsinx; length may be 0 }
                  m:   integer; { minimum pixel length }
                  act: boolean; { button active }
                  dis: boolean; { button disabled }
                  alt: boolean; { button on alert }
                  sm:  modset;  { applicable screen mode }
                  acf: color;   { "active" color foreground }
                  acb: color;   { "active" color background }
                  icf: color;   { "inactive" color foreground }
                  icb: color;   { "inactive" color backround }
                  loc: loctyp;  { location of button }
                  typ: distyp;  { appearance type of button }
                  fmt: formset  { placement formatting }

               end;
     dotinx =  1..dotmax; { dot vector index }
     { cell file partition marker codes }
     celseg = (ccfterm, ccterm, cceldir, ccell, ccschema, cclayout,
               ccwave, ccsymbol);
     { Viewport specification
       A viewport is a complete specification of the parameters
       that define a window.  }
     viewport = record { viewport parameters, in real }

                   v: region; { viewport rectangle screen }
                   r: region; { viewport rectangle real }
                   s: point;  { scale }
                   m: point;  { multiplier }
                   c: region  { clipping rectangle screen }

                end;
     viewrec = record { view specification }

                  vp:   viewport; { viewport }
                  a:    boolean   { view active flag }

               end;
     viewinx = 1..viewmax; { index for viewer array }
     viewarr = array [viewinx] of viewrec;
     sizerec = record { size specification }

                  s:    integer; { size }
                  a:    boolean  { size active flag }

               end;
     sizeinx = 1..sizemax; { index for size array }
     sizearr = array [sizeinx] of sizerec;
     { layer codes }
     laytyp  = (ltcell,  { cells layer }
                ltfig,   { figures layer }
                ltovg,   { overglass layer }
                ltvia,   { via layer }
                ltism2,  { met 2 intersections layer }
                ltism1,  { met 1 intersections layer }
                ltisply, { poly intersections layer }
                ltmet2,  { metal 2 layer }
                ltcont,  { contact layer }
                ltpmd,   { poly, metals and diff layer }
                ltwell); { wells layer }
     laylst  = array [laytyp] of drwptr; { layers pointer array }
     blkinx  = 1..blkmax; { index for block array }
     blkrec  = record { block storage }

                  l: laylst;              { figure list }
                  n: namptr;              { name list }
                  sx, sy, ex, ey: integer { bounding box }

               end;
     blkarr  = array [blkinx] of blkrec; { block storage array }
     celptr  = ^celrec; { cell record pointer }
     shtrec  = record { sheet control record }

                  dl:         laylst; { drawing lists }
                  nl:         nodptr; { node list }
                  bl:         busptr; { bus list }
                  nc:         integer; { node counter }
                  vp:         viewport; { viewport for sheet }
                  lvp:        viewport; { last viewport for sheet }
                  bbsx, bbsy,
                  bbex, bbey: integer; { bounding box }
                  bs:         boolean; { bounds set flag }
                  sbbsx, sbbsy,
                  sbbex, sbbey: integer; { symbol bounding box }
                  sbs:        boolean; { symbol bounds set flag }
                  ds:         integer; { dot grid size }
                  ls:         integer; { line grid size }
                  js:         integer; { junction size }
                  cs:         integer; { connector size }
                  ts:         integer; { text size }
                  sv:         viewarr; { stored views }
                  sts:        sizearr; { stored text sizes }
                  sds:        sizearr; { stored dot grid sizes }
                  sls:        sizearr; { stored line grid sizes }
                  csp:        celptr;  { used during external loads }
                  next:       shtptr;  { used during external loads }

               end;
     celrec  = record { cell record }

                  name:     butstr;  { filename }
                  schema:   shtptr;  { schematic sheet }
                  symbol:   shtptr;  { symbol sheet }
                  layout:   shtptr;  { layout sheet }
                  simulate: shtptr;  { simulate sheet }
                  ref:      boolean; { used during external loads }
                  cross:    celptr;  { used during external loads }
                  next:     celptr   { next entry }

               end;
     csvptr = ^csvrec; { cell save record pointer }
     csvrec = record { cell save record }

                 cp: celptr; { cell }
                 next: csvptr { next }

              end;
     winptr = ^winrec;
     winrec = record { window control record }

                 { r:  region;  screen space occupied by window }
                 wv: viewport; { window whole viewport }
                 cr: region;   { client area region }
                 tv: viewport; { target viewport }
                 tr: region;   { target area }
                 cs: shtptr;   { current sheet in display }
                 cc: celptr;   { current cell }
                 ar: region;   { active area }
                 aa: real;     { aspect ratio angle }
                 tm: region;   { top menu area, including border }
                 rm: region;   { right menu area, including border }
                 sr: region;   { saved region, for max negation }
                 lc: color;    { lit area color }
                 sc: color;    { shadow area color }
                 bc: color     { backround color }

              end;
     busety = record { bus entry }

                 name: butstr;  { bus name }
                 tmp:  boolean; { bus name is a temp }
                 nl:   nodptr;  { nodes chain pointer }
                 bl:   drwptr;  { bus lines pointer }
                 sl:   busptr;  { used for bus smashing }
                 next: busptr   { next entry }

              end;
     nodety = record { node entry }

                 name: butstr;  { node name }
                 nord: byte;    { node ordinal }
                 tmp:  boolean; { node name is a temp }
                 nl:   drwptr;  { first wire in node set }
                 sl:   nodptr;  { used for node smashing }
                 bl:   nodptr;  { bus membership linkage }
                 bh:   busptr;  { bus entry head }
                 next: nodptr   { next node in list }

              end;
     { note that there are 16 states of a node, the
       perfect number for table lookups. They are
       also broken evenly into indeterminate and
       determinate states. }
     nodest  = (         { node states }
     { indeterminate }
                nsundef,   { unspecified }
                nsindet,   { stored indeterminate }
                nsindrh,   { indeterminate driven by high }
                nsindrl,   { indeterminate driven by low }
                nswidh,    { weak indeterminate driven by high }
                nswidl,    { weak indeterminate driven by low }
                nscont,    { conflicting drives }
                nswcont,   { conflicting weak drives }
     { determinate }
                nshigh,    { driven high }
                nslow,     { driven low }
                nsstrh,    { stored high }
                nsstrl,    { stored low }
                nswhigh,   { weak driven high }
                nswlow,    { weak driven low }
                nsvdd,     { high supply rail }
                nsvss      { low supply rail }
                );
     trcptr = ^trcrec; { pointer to trace record }
     trcrec = record { trace record }

                 time:  integer; { time of assertion }
                 state: nodest;  { state of assertion }
                 next:  trcptr   { next entry }

              end;
     atrcptr = ^atrcrec; { pointer to trace record }
     atrcrec = record { trace record }

                 time:  real;    { time of assertion }
                 v:     real;    { value of assertion }
                 next:  atrcptr  { next entry }

              end;
     drwety = record { drawing entry }

                 cl:     color;   { color }
                 rm:     rotmod;  { rotation mode }
                 next:   drwptr;   { next entry }
                 case typ: figtyp of { figure type }

                    tend,
                    tcont:     (); { port: tcont added, all tag values
                                     must be covered }
                    tline,
                    tbline:    (l:  region); { line }
                    tbox,
                    tbbox,
                    tmet1,
                    tmet2,
                    tpoly,
                    tvia,
                    tndiff,
                    tpdiff,
                    tnwell,
                    tpwell,
                    tccut:     (b:  region); { rectangle }
                    tinter:    ( { intersection }

                       ir: region;  { region }
                       itt: figtyp; { type of top layer }
                       ipt: drwptr; { pointer to top layer }
                       itb: figtyp; { type of bottom layer }
                       ipb: drwptr  { pointer to bottom layer }

                    );
                    tarc:      (a:  sarc);   { arc/circle }
                    tchar:     (c:  chars);  { character string }
                    tbus:      (bs: busfig); { bus }
                    tcell:     (cr: celref); { subcell reference }
                    tnmos,
                    tpmos,
                    tcap,
                    tres,
                    tdiode,
                    tvdd,
                    tvss:      (o:  point); { fixed cell origin }
                    twire,
                    tjunction,
                    tconnect:  ( { node list types }

                       nl: drwptr; { list link for wires in node }
                       nh: nodptr;  { link to attached node }
                       case figtyp of { node entries }

                          tend, tline, tbox, tarc, tchar, tbus,
                          tbline, tbbox, tcell, tnmos, tpmos, tcap,
                          tres, tdiode, tvdd, tvss,
                          { port: added, all tag values must be covered }
                          tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
                          tnwell, tpwell, tccut, tinter, tcont, ttrc,
                          tatrc: ();
                          twire: (w: region);
                          tjunction,
                          tconnect: (j: point)

                       { end }

                    );
                    ttrc: ( { trace list }

                       ts: point; { start location of trace }
                       tl: trcptr { trace list }

                    );
                    tatrc: ( { trace list }

                       as: point; { start location of trace }
                       al: atrcptr { trace list }

                    )

                 { end }

              end;
     namrec = record { name/ordinal save entry }

                 name: butstr;  { name }
                 nord: byte;    { ordinal }
                 tmp:  boolean; { is a temp }
                 next: namptr   { next entry }

              end;
     { printer output buffer }
     prtarr = array [0..pbxmax, 0..pbymax] of color;
     prtrec = record { printer parameter save record }

                 mx:  rpoint; { maximum }
                 off: rpoint; { offset }
                 a:   boolean { active flag }

              end;
     prtinx = 1..prtmax; { index for viewer array }
     ptrarr = array [prtinx] of prtrec;
     { Puck control section.
       The puck control record contains all the data
       required to determine the complete puck status.
       It is updated each time the tablet is queryed.
       The current location of the puck, its valid/invalid
       status (puck in proimity of tablet), and the status
       of all puck buttons is kept. In addition, serveral
       communications flags are kept, which are set by the
       puck routine, and cleared only by external software.
       These flags indicate puck movement, button assertion,
       button deassertion, button drag, and the puck location
       at assertion or deassertion. }
     pckbut = record { puck button control record }

                 s:  boolean; { current switch close status }
                 l:  boolean; { last switch close status }
                 a:  boolean; { assertion flag (CMF) }
                 d:  boolean; { deassertion flag (CMF) }
                 dg: boolean; { drag flag }
                 ap: point; { assertion location }
                 dp: point  { deassertion location }

              end;
     pckinx = 1..4; { index for puck buttons }
     pckctl = record { puck control record }

                 b:  array [pckinx] of pckbut; { puck buttons }
                 cl: point; { current location of puck }
                 ol: point; { last location of puck }
                 m:  boolean; { puck movement flag (CMF) }
                 v:  boolean  { puck valid flag }

              end;
     { device errors }
     devcod = (deptr,  { pointer device initalize }
               devid,  { display device initalize }
               delab); { parameter label too long }
     bytfil = file of boolean; { byte file }
     filinx = 1..fillen; { index for filename }
     { file name }
     filnam = packed array [filinx] of char;
     filptr = ^filety; { pointer to file name entry }
     filety = record { file name record }

                 name: filnam; { name of file }
                 next: filptr  { next entry }

              end;
     labinx = 1..labmax; { index for label }
     labtyp = packed array [labinx] of char; { label }
     trcarr  = array [color] of boolean; { trace color tracking }

var

    maxx:           integer; { demensions of display screen }
    maxy:           integer;
    minx:           integer;
    miny:           integer;
    screen:         viewport; { whole screen viewport }
    rw:             region; { demensions of real world }
    cur:            point; { cursor coordinates }
    rcur:           point; { real version of same }
    mcur:           point; { cursor mark location on screen }
    { port: cursav (under cursor save) deleted; xor rubber-banding }
    curdwn:         boolean; { cursor on screen flag }
    { object on screen tracking }
    zbxdwn:         boolean; { zoom box on screen flag }
    mrkdwn:         boolean; { marker on screen flag }
    rlmdwn:         boolean; { ruler mark on screen flag }
    lindwn:         boolean; { line cursor down flag }
    boxdwn:         boolean; { box cursor down flag }
    cirdwn:         boolean; { circle cursor down flag }
    arcdwn:         boolean; { arc cursor down flag }
    tcrdwn:         boolean; { text cursor down flag }
    cntdrw:         boolean; { continous draw mode }
    modbut:         buttyp;  { current mode button }
    vimbut:         buttyp;  { viewing mode in progress button }
    { drawing/manipulation mode in progress button }
    drmbut:         buttyp;
    dsmbut:         buttyp;
    arcsph:         boolean; { arc draw 2nd phase }
    arcflat:        boolean; { arc is flat }
    cedbut:         buttyp;  { button in edit }
    str:            point; { start of line }
    tstr:           point; { true start of line }
    endp:           point; { end of line }
    cen:            point; { center of circle }
    tcen:           point; { true center of circle }
    rad:            integer; { radius of circle }
    mrk:            point; { marker coordinates }
    rmrk:           point; { real version of same }
    zb:             region; { zoom box coordinates }
    tcur:           point; { text entry cursor }
    sizb:           region; { size adjust cursor box }
    movoff:         point; { move offset cursor }
    cscale:         integer; { character size scale }
    { port: lines (under line save) deleted; xor rubber-banding }
    smslst:         nodptr; { node smash list }
    bsmlst:         busptr; { bus smash list }
    savlst:         laylst; { save list }
    namlst:         namptr; { name save list }
    { ?? moved to curwin:
         asan:           real;    aspect ratio angle }
    { save bounding box, or least and most points }
    savb:           region;
    button:         array [buttyp] of butrec; { button descriptors }
    curbut:         buttyp; { currently active button }
    pixsiz:         real; { size of a virtual pixel (meters) }
    edtpos:         btslen; { port: was btsinx; edit drives it to 0 }
    tcolor:         color; { current trace color }
    dsplst:         filptr;  { cell display list }
    dspnum:         integer; { number of current screen list start }
    dspbut:         bpoint; { location of selected cell display button }
    dspsav:         butstr; { save for last cell button string }
    trcclrs:        set of color; { possible trace colors }
    trcclr:         color; { current color }
    trctrk:         trcarr; { trace node tracking array }
    blocks:         blkarr; { block storage array }
    cellst:         celptr; { cells in file list }
    placel:         celptr; { current placement cell }
    butsav:         butstr; { save for buttons in edit }
    textrot:        boolean; { text placement is rotated }
    texttop:        drwptr; { text top entry }
    celstk:         csvptr; { cell viewer stack }
    prtbuf:         prtarr; { printer output buffer }
    pmax:           point; { printer buffer maximums }
    poff:           point; { offset of buffer in frame }
    pscl:           integer; { scale of printer buffer }
    ptrmax:         rpoint; { printer maximum x (meters) }
    ptroff:         rpoint; { printer offset x (meters) }
    ptrdpm:         real; { printer dots per meter }
    ptrdl:          byte; { printer color dither limit }
    trnfrm:         rotmod; { current transformation mode }
    prtsav:         ptrarr; { printer parameter saves }
    targvp:         viewport; { target viewport }
    { port: restored; the original commented this out as "moved to curwin"
      but chktar (icdc.pas) still references the global }
    targbnd:        region; { target bounding box }
    plcsiz:         point;  { demensions of placement cell }
    libcel:         celptr; { library cell list }
    libnam:         butstr; { library cell name }
    libbut:         buttyp; { library button }
    puck:           pckctl; { puck control record }
    errmsg:         boolean; { error message onscreen }
    terminate:      boolean; { terminate program flag }
    blank:          boolean; { screen blank flag }
    aniloc:         point; { blank animator current location }
    aninxt:         point; { blank animator next increment }
    curscm:         modset; { current screen mode }

     { fabricator data block. Here are all the fabrication
       parameters and design rules that ICD needs per process.
       Although we try to be general, the rules are basically
       a collection of all DR's encountered, and may grow
       as fabs are added. To this end, end padding is usually
       added to the output file for future extention. }

    fabpar: record

       { design rules }
       { rules on each layer, or general rules }
       layrul: array [laytyp] of record

          size:  integer; { minimum feature size }
          space: array [figtyp] of integer; { minimum feature spacing }
          exact: integer; { exact x and y size, if fixed,
                            otherwise 0 if unrestricted }
          align: integer { alignment grid }

       end;
       { process type }
       prctyp: (ptnowell, { no well (SOI or other) }
                ptnwell,  { N-well }
                ptpwell,  { P-well }
                pttwell); { twin-well }

    end;

    { port: alphal character widths table deleted; replaced by
      chrwidth/strwidth in icdui }
    curwin: winptr; { current active window }
    bakclr: color; { windows backround color }
    bakshw: color; { windows backround shadow }
    baklgt: color; { windows backround lighted }

begin { constructor }
end;

begin { destructor }
end.

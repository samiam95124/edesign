{$i c:\propas\doslib}

const maxx      = 1023;  { demensions of standard screen }
      maxy      = 767;
      minx      = 0;
      miny      = 0;
      aminx     = 0;     { demensions of active area }
      aminy     = 129;
      amaxx     = 894;
      amaxy     = 767;
      tgminx    = 897;   { demensions of target display }
      tgminy    = 0;
      tgmaxx    = 1023;
      tgmaxy    = 126;
      tgborder  = 5;     { target border space }
      pi        = 3.141592653589793;
      linmax    = 10000; { maximum length of screen line }
      scalem    = 100;   { scale accuracy multiplier }
      dotmin    = 8;     { minimum grid dot spacing to display dot grid }
      linemin   = 8;     { minimum grid dot spacing to display line grid }
      normscale = 300;   { normal magnification scale }
      bbborder  = 10;    { bounding box default border }
      butlen    = 8;     { number of characters in a button }
      msglen    = 35;    { number of characters in a message }
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
      timeout   = 300; { number of idle seconds before screen 
                         blank (5 min) }
      figet     = 3; { figet factor for pointer idle detect }
      timesiz   = 0.000000000001; { time value of virtual pixel }
      voltsiz   = 0.001666666666; { voltage value of virtual pixel }
      trcsiz    = 4800; { height of trace, in virtual pixels }
      stpsiz    = 1000; { length of trace step }
  
type color  = (black, blue, green, cyan, red, magenta, brown,
               dwhite, gray, lblue, lgreen, lcyan, lred, lmagenta,
               yellow, white);
     point  = record x, y: integer end; { coordinate point }
     rpoint = record x, y: real end; { demension pair (meters) }
     wpoint = record x, y: word end; { coordinate point (onscreen) }
     bpoint = record x, y: byte end; { char cell coordinates }
     region = record s, e: point end; { rectangular region }
     sarc   = record { arc specification }
            
                 s: point; { start point }
                 e: point; { end point (c-clockwise) }
                 c: point; { center }
                 r: integer { radius }
    
              end;
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
     butstr = packed array [btsinx] of char;
     msginx = 1..msglen; { index for message string }
     msgstr = packed array [msginx] of char;
     msgtyp = (mnone,    { none (blank message) }
               minvn,    { invalid number }
               movfn);   { integer overflow }
     busptr = ^busety; { bus entry pointer }
     busfig = record { bus figure entry }
  
                 l:  region; { start and end of bus line }
                 bl: drwptr; { list link for lines in bus }
                 bh: busptr  { link to attached bus }

              end;
     lininx = 1..linmax; { index for line save }
     linarr = array[lininx] of color; { screen pixel save buffer }
     { button codes }
     buttyp = (bnull,     { no button }
               bpan,      { pan }
               bin,       { zoom in }
               bout,      { zoom out }
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
               bline,     { line draw mode }
               bsnap,     { toggle snap }
               bbox,      { box draw mode }
               bbline,    { bold line }
               bbbox,     { bold box }
               bany,      { line limit any }
               b45,       { line limit 45 deg }
               bcircle,   { circle draw mode } 
               b90,       { line limit 90 deg }
               barc,      { arc draw mode }
               bwire,     { wire place mode }
               bbus,      { bus place mode }
               bjunction, { junction place mode }
               bjuncv,    { junction value field }
               bconnect,  { connector place mode }
               bconnv,    { connector value field }
               bundo,     { undo }
               bredo,     { redo }
               bcutb,     { cut block }
               bpasteb,   { paste block }
               bsaveb,    { save block }
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
               btrace,    { trace node }
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
               bname,     { set node name }
               bnord,     { name ordinal }
               bnamev,    { node name }
               berc,      { run rules check }
               bup,       { up cell level }
               bdown,     { down cell level }
               bplsch,    { place schematic mode }
               bplsym,    { place symbol mode }
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
               bdisplay); { display avalible cells }
     butsts =  (unset, inact, act, select, una); { button status }
     figtyp = (tend, tline, tbox, tarc, tchar, twire, tbus, 
               tjunction, tbline, tbbox, tcell, tconnect,
               tnmos, tpmos, tcap, tres, tdiode, tvdd, tvss,
               tmet1, tmet2, tpoly, tvia, tndiff, tpdiff,
               tnwell, tpwell, tccut, tinter, tcont, ttrc);
     rotmod = (rm0, rm90, rm180, rm270, rmm0, rmm90, rmm180, 
               rmm270);
     { screen menu modes }
     scnmod = (smsymbol, smschema, smlayout, smsimulate,
               smprint);
     modset = set of scnmod; { set of same }
     butrec =  record { button descriptors }

                  x, y:   byte;     { address of button origin }
                  x1, y1,
                  x2, y2: word;     { screen bounding address }
                  s:      butstr;   { button string }
                  l:      btsinx;   { length of string }
                  act:    boolean;  { button active }
                  sel:    boolean;  { button selected }
                  dis:    boolean;  { button disabled }
                  man:    boolean;  { button is manually selected }
                  alt:    boolean;  { button on alert }
                  sm:     modset;   { applicable screen mode }
                  acf:    color;    { "active" color foreground }
                  acb:    color;    { "active" color background }
                  icf:    color;    { "inactive" color foreground }
                  icb:    color    { "inactive" color backround }

               end;
     dotinx =  1..dotmax; { dot vector index }
     dotvec =  array[dotinx] of word; { dot vector }
     { cell file partition marker codes }
     celseg = (ccfterm, ccterm, cceldir, ccell, ccschema, cclayout, 
               ccwave, ccsymbol);
     { Viewport specification
       A viewport is a complete specification of the parameters
       that define a window.  }
     viewport = record { viewport parameters, in real }

                   r: region; { viewport rectangle real }
                   s: integer; { scale }
                   v: region   { viewport rectangle screen }

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
     trcarr  = array [color] of boolean; { trace color tracking }
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
     drwety = record { drawing entry }
                 
                 cl:     color;   { color }
                 rm:     rotmod;  { rotation mode }
                 next:   drwptr;   { next entry }
                 case typ: figtyp of { figure type }

                    tend:      ();
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
                          tres, tdiode, tvdd, tvss: ();
                          twire: (w: region);
                          tjunction,
                          tconnect: (j: point)

                       { end }

                    );
                    ttrc: ( { trace list }

                       ts: point; { start location of trace }
                       tl: trcptr { trace list }

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
                 ap: wpoint; { assertion location }
                 dp: wpoint  { deassertion location }

              end;
     pckinx = 1..4; { index for puck buttons }
     pckctl = record { puck control record }

                 b:  array [pckinx] of pckbut; { puck buttons }
                 cl: wpoint; { current location of puck }
                 ol: wpoint; { last location of puck }
                 m:  boolean; { puck movement flag (CMF) }
                 v:  boolean  { puck valid flag }

              end;
     { device errors }
     devcod = (deptr); 
     bytfil = file of byte; { byte file }

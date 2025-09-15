unit common;

interface

{$i \edesign\icd\define.pas}

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
    cursav:         array[1..100] of color; { under cursor save }
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
    lines:          linarr; { under line save }
    smslst:         nodptr; { node smash list }
    bsmlst:         busptr; { bus smash list }
    savlst:         laylst; { save list }
    namlst:         namptr; { name save list }
    { ?? moved to curwin: 
         asan:           real; { aspect ratio angle }
    { save bounding box, or least and most points }
    savb:           region;
    button:         array [buttyp] of butrec; { button descriptors }
    curbut:         buttyp; { currently active button }
    pixsiz:         real; { size of a virtual pixel (meters) }
    edtpos:         btsinx; { current edit position }
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
    { ?? moved to cuwin: 
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

    { character widths table }
    var alphal: array [0..127] of 0..16;
    curwin: winptr; { current active window }
    bakclr: color; { windows backround color }
    bakshw: color; { windows backround shadow }
    baklgt: color; { windows backround lighted }

implementation { none }
       
end. { unit }       

                title   'Pixel routines'
                name    pixel
                page    55,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; PIXEL ACCESS ROUTINES                                       ;
;                                                             ;
; This package is a base for access to a high res graphics    ;
; mode. The following routines are implemented:               ;
;                                                             ;
;    iniscn          - initialize screen graphics mode        ;
;    resscn          - reset screen to former mode            ;
;    getpix(x, y)    - get a single pixel                     ;
;    setpix(x, y, c) - set a single pixel                     ;
;                                                             ;
; These will allow virtually screen function to be performed. ;
; Other functions are required because of speed.              ;
; The package is essentially general to any video "UGA" card, ;
; but the card must have the following characteristics:       ;
;                                                             ;
;    1. Must be bank selectable by 64kb segments.             ;
;                                                             ;
; Most cards comply with these requirements, and the VESA     ;
; standard requirements also dictate them (even though we     ;
; may not use the VESA calls).                                ;
; The code custom tailored to drive the card in question is   ;
; restricted to the following routines:                       ;
;                                                             ;
;    opnvid - sets the applicable video mode and performs     ;
;    any special setup.                                       ;
;                                                             ;
;    clsvid - performs any card reset required. DOES NOT      ;
;    reset the old video mode.                                ;
;                                                             ;
;    vidseg(s) - selects a given 64kb video segment, 0-n.     ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extern  syscall linepl:near
        extern  syscall linespl:near
        extern  syscall linerpl:near
        extern  syscall blockpl:near
        extern  syscall setchrpl:near
        extern  syscall linepk:near
        extern  syscall linespk:near
        extern  syscall linerpk:near
        extern  syscall blockpk:near
        extern  syscall setchrpk:near

        public  segvid          
        public  linbyt
        public  linep
        public  linesp
        public  linerp
        public  blockp
        public  setchrp

vidbuf  equ     0a0000h         ; address of video buffer
equflg  equ     410h            ; equipment flag in BIOS

; 
; Format of viewport record
;
viewvsx equ     0               ; viewport rectangle screen
viewvsy equ     4
viewvex equ     8
viewvey equ     12
viewrsx equ     16              ; viewport rectangle real
viewrsy equ     20
viewrex equ     24
viewrey equ     28
viewsx  equ     32              ; viewport scale
viewsy  equ     36      
viewmx  equ     40              ; viewport multiplier
viewmy  equ     44
viewcsx equ     48              ; clipping rectangle screen
viewcsy equ     52
viewcex equ     56
viewcey equ     60

        .386
        .model  small, c

        .code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CARD SPECIFIC ROUTINES TABLE                                ;
;                                                             ;
; Contains a table of the routines required to operate a      ;
; video card. The format of each entry header is:             ;
;                                                             ;
;    Driver id(s): a 10 character string, with the upper      ;
;    case driver identification. More than one such ID may    ;
;    be assigned to a single driver.                          ;
;                                                             ;
;    zero byte: terminates the driver id string list.         ;
;                                                             ;
;    address next: contains the address of the next driver    ;
;    set, or 0 if end of the driver list.                     ;
;                                                             ;
;    x size: number of pixels in x.                           ;
;                                                             ;
;    y size: number of pixels in y.                           ;
;                                                             ;
;    pitch: number of bytes in a scan line.                   ;
;                                                             ;
;    mode number: a 16 bit mode number.                       ;
;                                                             ;
;    opnvid address: address of the video open routine.       ;
;                                                             ;
;    clsvid address: address of the video close routine.      ;
;                                                             ;
;    segvid address: address of the video segment select      ;
;    routine.                                                 ;
;                                                             ;
;    driver code: the code for all routines in the driver.    ;
;                                                             ;
; The description of each driver routine follows:             ;
;                                                             ;
; OPEN VIDEO CARD                                             ;
;                                                             ;
; Selects the mode and enables the card. The mode number from ;
; the table is passed in ax. This can allow multiple table    ;
; entries for many cards. The driver string used to match is  ;
; passed in ebx. This allows parameters to be passed to the   ;
; particular driver.                                          ;
;                                                             ;
; CLOSE VIDEO CARD                                            ;
;                                                             ;
; Performs any card reset prior to restoring old mode.        ;
;                                                             ;
; SELECT VIDEO MEMORY SEGMENT                                 ;
;                                                             ;
; Selects a 64kb segment of video memory.                     ;
; ah contains the segment number.                             ;
;                                                             ;
; All routines modify eax.                                    ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dvrtbl:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; VGA640                                                      ;
;                                                             ;
; Standard VGA 640x480 mode. Mostly for test/demo purposes.   ;
;                                                             ;
;    tested 2/92                                              ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vga:
        db      'VGA640X480X16       '
        db      0
        dd      vgaend     
        dd      640
        dd      480
        dd      80
        dw      00012h
        dd      vgaopn 
        dd      vgacls
        dd      vgaseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
vgaopn  proc syscall
        int     10h             ; set mode
        ret                     ; exit
vgaopn  endp

vgacls  proc syscall
        ret                     ; no closure required
vgacls  endp

vgaseg  proc syscall
        ret                     ; no segmentation required
vgaseg  endp

vgaend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; VESA                                                        ;
;                                                             ;
; For boards following the VESA standard.                     ;
;                                                             ;
;    tested 2/92                                              ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vesa:
        db      'VESA800X600X16      '
        db      0
        dd      vesaend     
        dd      800
        dd      600
        dd      100
        dw      00102h
        dd      vesaopn 
        dd      vesacls
        dd      vesaseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
vesaopn proc syscall
        mov     bx,ax
        mov     ax,04f02h       ; set VESA set super VGA mode
        int     10h             ; set mode
        ret                     ; exit
vesaopn endp

vesacls proc syscall
        ret                     ; no closure required
vesacls endp

vesaseg proc syscall
        ret                     ; no segmentation required
vesaseg endp

vesaend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; VESA BYTE MODE                                              ;
;                                                             ;
; Implements the VESA 6Ah mode driver. This is provided as    ;
; an alternative to the standard (newer) vesa modes.          ;
; Since some manufacterers have implemented the 6Ah code in   ;
; the prom bios, it may work where a VESA bios extender is    ;
; not avalible or is unusable.                                ;
;                                                             ;
;    tested 2/92                                              ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vesab:
        db      'VESAB800X600X16     '
        db      0
        dd      vesabend     
        dd      800
        dd      600
        dd      100
        dw      0006ah
        dd      vesabopn 
        dd      vesabcls
        dd      vesabseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
vesabopn proc syscall
        int     10h             ; set mode
        ret                     ; exit
vesabopn endp

vesabcls proc syscall
        ret                     ; no closure required
vesabcls endp

vesabseg proc syscall
        ret                     ; no segmentation required
vesabseg endp

vesabend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; WESTERN DIGITAL WD90C00                                     ;
;                                                             ;
; Boards using the Western Digital WD90C00 SVGA controller    ;
; chip.                                                       ;
;                                                             ;
;    tested 2/92 800x600x16                                   ;
;                1024x768x16                                  ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pvga:
        db      'WD1024X768X16       '
        db      0
        dd      pvga02    
        dd      1024
        dd      768
        dd      128
        dw      0005dh
        dd      pvgaopn 
        dd      pvgacls
        dd      pvgaseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl

pvga02:
        db      'WD800X600X16        '
        db      0
        dd      pvgaend    
        dd      800
        dd      600
        dd      100
        dw      00058h
        dd      pvgaopn 
        dd      pvgacls
        dd      pvgaseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
pvgaopn proc syscall
        push    dx
        int     10h             ; set mode
        mov     dx,3ceh         ; get controller address
        mov     ax,0050fh       ; unlock extended registers
        out     dx,ax
        pop     dx
        ret                     ; exit
pvgaopn endp

pvgacls proc syscall
        push    dx
        mov     dx,3ceh         ; get controller address
        mov     ax,0000fh       ; relock extended registers
        out     dx,ax
        pop     dx
        ret                     ; exit
pvgacls endp

pvgaseg proc syscall
        push    ax
        push    dx
        mov     dx,3ceh         ; get controller address
        shl     ah,4            ; place segment number
        mov     al,009h         ; set proa index value
        out     dx,ax           ; set segment
        pop     dx
        pop     ax
        ret                     ; exit
pvgaseg endp

pvgaend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; TSENG LABS ET4000                                           ;
;                                                             ;
; Boards using the Tseng labs ET4000 SVGA controller chip.    ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

et4000:
        db      'TSENG800X600X16     '
        db      0
        dd      et4000b     
        dd      800
        dd      600
        dd      100
        dw      00029h
        dd      et4000opn 
        dd      et4000cls
        dd      et4000seg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl

et4000b:
        db      'TSENG1024X768X16    '
        db      0
        dd      et4000end     
        dd      1024
        dd      768
        dd      128
        dw      00037h
        dd      et4000opn 
        dd      et4000cls
        dd      et4000seg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
et4000opn proc syscall
        push    dx
        int     10h             ; set mode
        mov     dx,03bfh
        mov     al,3
        out     dx,al
        mov     dx,3d8h
        mov     al,0a0h
        out     dx,al
        pop     dx
        ret                     ; exit
et4000opn endp

et4000cls proc syscall
        ret                     ; exit
et4000cls endp

et4000seg proc syscall
        push    ax
        push    dx
        mov     al,ah           ; copy segment to upper nybble
        shl     ah,4            ; place segment number
        or      al,ah
        mov     dx,03cdh        ; index GCD segment select
        out     dx,al           ; set segment
        pop     dx
        pop     ax
        ret                     ; exit
et4000seg endp

et4000end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; ATI VGA WONDER                                              ;
;                                                             ;
; ATI vga wonder and compatible boards.                       ;
; Note that the ATI wonder uses a "unique" packed mode, and   ;
; must therefore use all it's own draw routines.              ;
; Because of this, the drawing is somewhat slower, the main   ;
; impact being on block draws.                                ;
;                                                             ;
;    Tested 2/92 800x600x16                                   ;
;                1024x768x16                                  ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ati:
        db      'ATI1024X768X16      '
        db      0
        dd      ati02     
        dd      1024
        dd      768
        dd      512
        dw      00065h
        dd      atiopn 
        dd      aticls
        dd      atiseg
        dd      getpxpk         ; packed version
        dd      setpxpk
        dd      linepk
        dd      linespk
        dd      linerpk
        dd      blockpk
        dd      setchrpk

ati02:
        db      'ATI800X600X16       '
        db      0
        dd      atiend    
        dd      800
        dd      600
        dd      100
        dw      00054h
        dd      atiopn 
        dd      aticls
        dd      atiseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
atiopn  proc syscall
        push    edx
        int     10h             ; set mode
        mov     eax,0c0010h     ; get extended port address
        movzx   eax,word ptr [eax]
        mov     [data1],eax     ; save for later routines
        pop     edx
        ret                     ; exit
atiopn  endp

aticls  proc syscall           
        ret                     ; no closure required
aticls  endp

atiseg  proc syscall
        push    ax
        push    dx
        shl     ah,1            ; shift page number into place
        mov     dx,word ptr [data1] ; get extended register address
        mov     al,0b2h         ; set page select index
        out     dx,al
        inc     dx
        in      al,dx           ; get current page reg
        dec     dx
        and     al,0e1h         ; mask off page number
        or      ah,al           ; combine with new
        mov     al,0b2h         ; set page select index
        out     dx,ax           ; activate page
        pop     dx
        pop     ax
        ret                     ; exit
atiseg  endp

atiend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; OAK TECHNOLOGY                                              ;
;                                                             ;
; Boards based on the OTI-037, OTI-067, and OTI-077           ;
; controllers.                                                ;
;                                                             ;
;    Tested 2/92 on OTI-037C, which does 800x600x16 only.     ;
;                Bios was OAK brand.                          ;
;    Tested 2/92 on OTI-077, 800x600, 1024x768, 1280x1024.    ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

oti:
        db      'OTI800X600X16       '
        db      0
        dd      otib     
        dd      800
        dd      600
        dd      100
        dw      00052h
        dd      otiopn 
        dd      oticls
        dd      otiseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl

otib:
        db      'OTI1024X768X16      '
        db      0
        dd      otic     
        dd      1024
        dd      768
        dd      128
        dw      00056h
        dd      otiopn 
        dd      oticls
        dd      otiseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl

otic:
        db      'OTI1280X1024X16     '
        db      0
        dd      otiend     
        dd      1280
        dd      1024
        dd      160
        dw      00058h
        dd      otiopn 
        dd      oticls
        dd      otiseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
otiopn  proc syscall
        int     10h             ; set mode
        ret                     ; exit
otiopn  endp

oticls  proc syscall
        ret                     ; exit
oticls  endp

otiseg  proc syscall
        push    ax
        push    dx
        mov     al,ah           ; copy segment to upper nybble
        shl     ah,4            ; place segment number
        or      ah,al
        mov     dx,03deh        ; index extended register
        mov     al,011h         ; set segment index
        out     dx,ax           ; set segment
        pop     dx
        pop     ax
        ret                     ; exit
otiseg  endp

otiend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; TRIDENT/EVEREX                                              ;
;                                                             ;
; Boards based on the 8800BR, 8800CS, and 8900 chips.         ;
;                                                             ;
;    Failed 2/92, on a generic. Same card failed to recognize ;
;                 ANY standard trident mode numbers (as 02).  ;
;                 I suspect the bios may be vga only, with    ;
;                 extended drivers implemented externally.    ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trid:
        db      'TRIDENT800X600X16   '
        db      'EVEREXVP800X600X16  '
        db      0
        dd      tridb     
        dd      800
        dd      600
        dd      100
        dw      00002h
        dd      tridopn 
        dd      tridcls
        dd      tridseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl

tridb:
        db      'TRIDENT1024X768X16  '
        db      'EVEREXVP1024X768X16 '
        db      0
        dd      tridend     
        dd      1024
        dd      768
        dd      128
        dw      00020h
        dd      tridopn 
        dd      tridcls
        dd      tridseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
tridopn proc syscall
        int     10h             ; set mode
        ret                     ; exit
tridopn endp

tridcls proc syscall
        ret                     ; exit
tridcls endp

tridseg proc syscall
        ret                     ; exit
tridseg endp

tridend:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; GENERIC                                                     ;
;                                                             ;
; This driver gets the mode number from the driver string.    ;
; Works for any mode that does not require bank switching,    ;
; as in 640x480x16, 800x600x16.                               ;
;                                                             ;
;    tested 2/92                                              ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gen:
        db      'GEN800X600X16=**    '
        db      0
        dd      0               ; end of table     
        dd      800
        dd      600
        dd      100
        dw      0
        dd      genopn 
        dd      gencls
        dd      genseg
        dd      getpxpl         ; planar version
        dd      setpxpl
        dd      linepl
        dd      linespl
        dd      linerpl
        dd      blockpl
        dd      setchrpl
        
genopn  proc syscall
        mov     al,[ebx+14]     ; convert mode number
        cmp     al,'A'
        jl      genopn01
        sub     al,'A'
        add     al,10
        jmp     genopn02
genopn01:
        sub     al,'0'
genopn02:       
        shl     al,4
        mov     ah,al           ; save upper nybble
        mov     al,[ebx+15]     ; convert mode number
        cmp     al,'A'
        jl      genopn03
        sub     al,'A'
        add     al,10
        jmp     genopn04
genopn03:
        sub     al,'0'
genopn04:       
        or      al,ah           ; form complete byte
        mov     ah,0
        int     10h             ; set mode
        ret                     ; exit
genopn  endp

gencls  proc syscall
        ret                     ; no closure required
gencls  endp

genseg  proc syscall
        ret                     ; no segmentation required
genseg  endp

genend:

; End of driver table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; INITIALIZE GRAPHIC SCREEN                                   ;
;                                                             ;
; Sets the graphics screen to the 1024*768 16 color mode.     ;
; If the current screen type is a MDA, we assume that we are  ;
; running in a dual monitor system. In this case, the adapter ;
; is switched to the VGA, that is initalized, and the         ;
; original monitor restored. This allows dual monitor         ;
; debugging. In a non-debug situation, it just means that we  ;
; automatically hunt for the VGA card.                        ;
; Note: should check what cards are actually installed.       ;
;                                                             ;
; procedure iniscn(var maxx, maxy: integer; var s: string20)  ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

maxxa   =       8               ; address of maximum x
maxya   =       12              ; address of maximum y
dvrs    =       16              ; address of driver string

iniscn  proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        push    esi
        push    edi

; Set driver invalid

        mov     eax,0   
        mov     [dimx],eax
        mov     [dimy],eax

; Search driver string

        mov     edx,dvrtbl      ; index drivers table
iniscn01:
        mov     ebx,[ebp+dvrs]  ; get address of string
        mov     ah,0            ; clear compare flag
        mov     cx,20           ; set length of string
iniscn02:     
        mov     al,[edx]        ; compare string characters
        sub     al,'*'          ; check wildcard
        jz      iniscn020       ; yes, skip compare
        mov     al,[edx]        ; compare string characters
        sub     al,[ebx]
iniscn020:
        inc     edx             ; next
        inc     ebx
        or      al,ah           ; find net compare
        mov     ah,al           ; save
        loopw   iniscn02        ; loop for all characters
        or      ah,ah           ; check compare
        jz      iniscn03        ; found, go
        mov     al,[edx]        ; check termination
        or      al,al
        jnz     iniscn01        ; compare next driver string
        inc     edx             ; skip terminator
        mov     edx,[edx]       ; get next header address
        or      edx,edx         ; check end of table    
        jnz     iniscn01        ; go next driver
        jmp     iniscn05        ; driver not found

; Driver found, install

iniscn03:     
        mov     al,[edx]        ; find end of strings
        inc     edx
        or      al,al
        jnz     iniscn03        ; loop
        mov     eax,[edx+4]     ; set maximum x
        dec     eax
        mov     [dimx],eax
        mov     eax,[edx+8]     ; set maximum y
        dec     eax
        mov     [dimy],eax
        mov     eax,[edx+12]    ; set pitch
        mov     [linbyt],eax
        mov     eax,[edx+18]    ; set open routine
        mov     [opnvid],eax
        mov     eax,[edx+22]    ; set close routine
        mov     [clsvid],eax
        mov     eax,[edx+26]    ; set segment select routine
        mov     [segvid],eax
        mov     eax,[edx+30]    ; set getpix routine
        mov     [getpxp],eax
        mov     eax,[edx+34]    ; set setpix routine
        mov     [setpxp],eax
        mov     eax,[edx+38]    ; set line draw routine
        mov     [linep],eax
        mov     eax,[edx+42]    ; set line save routine
        mov     [linesp],eax
        mov     eax,[edx+46]    ; set line restore routine
        mov     [linerp],eax
        mov     eax,[edx+50]    ; set block routine
        mov     [blockp],eax
        mov     eax,[edx+54]    ; set character routine
        mov     [setchrp],eax
        mov     cx,[edx+16]     ; get mode number
        
; Initalize card

        mov     ax,00f00h       ; get current mode
        int     10h
        mov     [modsav],al     ; save
        mov     edx,equflg
        mov     al,[edx]        ; get EQUIP_FLAG
        mov     [equsav],al     ; save
        mov     ah,al

; Check if running on an MDA

        and     al,00110000b    ; mask adapter type
        cmp     al,00110000b    ; check monochrome
        jnz     iniscn04        ; no, skip

; on MDA, switch displays and initalize VGA

        mov     al,[equsav]     ; get EQUIP_FLAG
        and     al,11001111b    ; mask off select bits
        or      al,00100000b    ; set color (vga)
        mov     [edx],al        ; update
        mov     ax,cx           ; place mode number
        mov     ebx,[ebp+dvrs]  ; get address of string
        call    [opnvid]        ; select high res mode
        mov     al,[equsav]     ; replace old select
        mov     [edx],al        ; replace old select
        mov     ax,00007h       ; set MDA mode
        int     10h
        jmp     iniscn05        ; exit

; on VGA, just initalize

iniscn04:        
        mov     ax,cx           ; place mode number
        mov     ebx,[ebp+dvrs]  ; get address of string
        call    [opnvid]        ; select high res mode
iniscn05:

; Return screen demension parameters

        mov     ebx,[ebp+maxxa] ; get maximum x address
        mov     eax,[dimx]      ; get maximum x
        mov     [ebx],eax       ; place
        mov     ebx,[ebp+maxya] ; get maximum y address
        mov     eax,[dimy]      ; get maximum y
        mov     [ebx],eax       ; place
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
iniscn  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; RESET SCREEN MODE                                           ;
;                                                             ;
; Resets the screen mode to normal.                           ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resscn  proc    syscall
        mov     al,[equsav]     ; get old equipment flag
        mov     edx,equflg
        mov     [edx],al        ; replace
        mov     al,[modsav]     ; get old mode
        mov     ah,000h         ; set mode
        int     10h
        call    [clsvid]        ; close video card
        ret
resscn  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; FIND PIXEL ADDRESS                                          ;
;                                                             ;
; Finds the address and mask of the given pixel.              ;
; Also sets the proper 64k segment for the address.           ;
;                                                             ;
; In parameters: eax = y coordinate                           ;
;                ebx = x coordinate                           ;
;                                                             ;
; Out parameters: ah  = bit mask                              ;
;                 al  = video segment number                  ;
;                 ebx = address of byte in video memory       ;
;                 cl = number of bits to shift left           ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pixadd  proc    syscall
        push    edx             ; save registers
        mov     cl,bl           ; cl := low-order byte of x
        mul     [linbyt]        ; eax := y * bytes per line
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        call    [segvid]        ; select segment
        mov     al,ah           ; place segment
        and     cl,7            ; cl := x & 7
        xor     cl,7            ; cl := number of bits to shift left
        mov     ah,1            ; ah := unshifted bit mask
        pop     edx             ; restore registers
        ret
pixadd  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; GET PIXEL                                                   ;
;                                                             ;
; Gets a pixel from the screen. Designed to                   ;
; be called by pascal, the format is:                         ;
;                                                             ;
; function getpix(vp:   viewport; { viewport }                ;
;                 x, y: integer)  { point coordinates }       ;
;                 : color;        { returned color }          ;
;                                                             ;
; The coordinates are 32 bit signed virtual pixels. The       ;
; contents of the screen pixel corresponding to that pixel is ;
; returned. In 1:1 scale, this will be one screen pixel for   ;
; each virtual pixel. In other scales, many virtual pixels    ;
; may be assigned to a single screen pixel.                   ;
; Accesses to virtual pixels off screen will return black.    ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vp      equ     8               ; pointer to viewport record
x       equ     12              ; x coordinate
y       equ     16              ; y coordinate

getpix  proc    syscall
        jmp     [getpxp]        ; goto proper routine
getpix  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; get pixel planar                                            ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getpxpl:
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers used
        push    esi
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x]     ; get x
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ecx,[edi+viewsx] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsx] ; check x >= clip(xs)
        jnge    getpxpl02       ; no, exit
        cmp     eax,[edi+viewcex] ; check x <= clip(xe)
        jnle    getpxpl02       ; no exit
        mov     ebx,eax         ; place x
        mov     eax,[ebp+y]     ; get y
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ecx,[edi+viewsy] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsy] ; check x >= clip(xs)
        jnge    getpxpl02       ; no, exit
        cmp     eax,[edi+viewcey] ; check x <= clip(xe)
        jnle    getpxpl02       ; no exit

; convert to screen address and bit mask

        mov     cl,bl           ; save bit offset
        mul     [linbyt]        ; find lines offset
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        call    [segvid]        ; select segment
        and     cl,7            ; mask bit offset
        mov     ch,080h         ; find bit mask
        shr     ch,cl

; load bit

        mov     esi,ebx         ; save address
        xor     bl,bl           ; bl is used to accumulate the pixel 
                                ; value
        mov     dx,3ceh         ; dx := graphics controller port
        mov     al,4            ; select read map select register
        out     dx,al
        inc     dx              ; index data
        mov     al,3            ; set initial bit plane number
getpxpl01:
        out     dx,al           ; select bit plane
        mov     bh,[esi]        ; bh := byte from current bit plane
        and     bh,ch           ; mask one bit
        neg     bh              ; bit 7 of bh := 1 
                                ; (if masked bit = 1)
                                ; bit 7 of bh := 0
                                ; (if masked bit = 0)
        rol     bx,1            ; bit 0 of bl := next bit from pixel
                                ; value
        dec     al              ; ah := next bit plane number
        jge     getpxpl01        
        movzx   ax,bl           ; ax := pixel value
        jmp     getpxpl03       ; exit
getpxpl02:
        mov     ax,0            ; set "nowhere" color to black
getpxpl03:
        pop     esi             ; restore used registers
        pop     ebx
        pop     ebp             ; unlink
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; get pixel packed                                            ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getpxpk:
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers used
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x]     ; get x
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx]    ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ecx,[edi+viewsx] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsx] ; check x >= clip(xs)
        jnge    getpxpl02       ; no, exit
        cmp     eax,[edi+viewcex] ; check x <= clip(xe)
        jnle    getpxpl02       ; no exit
        mov     ebx,eax         ; place x
        mov     eax,[ebp+y]     ; get y
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ecx,[edi+viewsy] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsy] ; check x >= clip(xs)
        jnge    getpxpl02       ; no, exit
        cmp     eax,[edi+viewcey] ; check x <= clip(xe)
        jnle    getpxpl02       ; no exit

; convert to screen address and bit mask

        mov     cl,bl           ; save nybble offset
        mul     [linbyt]        ; find lines offset
        shr     ebx,1           ; convert to byte offset w/
                                ; nybble in carry
        add     bx,ax           ; offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        call    [segvid]        ; select segment

; load bit

        mov     al,[ebx]        ; get video byte
        test    cl,1            ; check if odd numbered adress
        jnz     getpxpk01       ; and skip if so
        shr     al,4            ; shift upper nybble down
getpxpk01:
        and     ax,00fh         ; mask result
        pop     ebx             ; restore used registers
        pop     ebp             ; unlink
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; SET PIXEL                                                   ;
;                                                             ;
; Sets a pixel on the screen to a given color. Designed to    ;
; be called by pascal, the format is:                         ;
;                                                             ;
; procedure setpix(var vp:   viewport; { viewport }           ;
;                  x, y:     integer;  { point coordinates }  ;
;                  c:        color);   { returned color }     ;
;                                                             ;
; The coordinates are 32 bit signed virtual pixels. The       ;
; contents of the screen pixel corresponding to that pixel is ;
; returned. In 1:1 scale, this will be one screen pixel for   ;
; each virtual pixel. In other scales, many virtual pixels    ;
; may be assigned to a single screen pixel.                   ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vp      equ     8               ; pointer to viewport record
x       equ     12              ; x coordinate
y       equ     16              ; y coordinate
clr     equ     20              ; color

setpix  proc    syscall
        jmp     [setpxp]        ; goto proper routine 
setpix  endp

; set pixel planar

setpxpl:
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers used
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x]     ; get x
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ecx,[edi+viewsx] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsx] ; check x >= clip(xs)
        jnge    setpxpl01       ; no, exit
        cmp     eax,[edi+viewcex] ; check x <= clip(xe)
        jnle    setpxpl01       ; no exit
        mov     ebx,eax         ; place x
        mov     eax,[ebp+y]     ; get y
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ecx,[edi+viewsy] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsy] ; check x >= clip(xs)
        jnge    setpxpl01       ; no, exit
        cmp     eax,[edi+viewcey] ; check x <= clip(xe)
        jnle    setpxpl01       ; no exit

; convert to screen address

        mov     cl,bl           ; save bit offset
        mul     [linbyt]        ; find lines offset
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        call    [segvid]        ; select segment

; set bit

        mov     dx,3ceh         ; get controller address
        mov     ah,[ebp+clr]    ; set color
        xor     al,al
        out     dx,ax
        mov     ax,00f01h       ; set bit plane mask
        out     dx,ax
        mov     ah,0
        mov     al,8            ; select bit mask register
        out     dx,ax
        and     cl,7            ; mask bit offset
        mov     al,080h         ; find bit mask
        shr     al,cl
        mov     ah,al           ; place
        mov     al,8            ; select bit mask register
        out     dx,ax           ; set bit mask
        or      [ebx],al        ; execute
setpxpl01:
        pop     ebx             ; restore registers used
        pop     ebp             ; unlink
        ret

; set pixel packed

setpxpk:
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers used
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x]     ; get x
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ecx,[edi+viewsx] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsx] ; check x >= clip(xs)
        jnge    getpxpl02       ; no, exit
        cmp     eax,[edi+viewcex] ; check x <= clip(xe)
        jnle    getpxpl02       ; no exit
        mov     ebx,eax         ; place x
        mov     eax,[ebp+y]     ; get y
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ecx,[edi+viewsy] ; get scale
        shr     ecx,1           ; / 2
        cmp     ecx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        cmp     eax,[edi+viewcsy] ; check x >= clip(xs)
        jnge    setpxpl01       ; no, exit
        cmp     eax,[edi+viewcey] ; check x <= clip(xe)
        jnle    setpxpl01       ; no exit

; convert to screen address

        mov     cl,bl           ; save nybble offset
        mul     [linbyt]        ; find lines offset
        shr     ebx,1           ; convert to byte offset w/
                                ; nybble in carry
        add     bx,ax           ; offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        call    [segvid]        ; select segment

; convert to screen address

        mov     al,[ebp+clr]    ; get color
        mov     ah,00fh         ; set mask
        test    cl,1            ; check if odd numbered adress
        jnz     setpxpk01       ; and skip if so
        shl     al,4            ; shift upper nybble down
        not     ah              ; set mask for upper nybble
setpxpk01:
        and     al,ah           ; mask nybble
        not     ah              ; set to keep mask
        and     [ebx],ah        ; preserve existing pixel
        or      [ebx],al        ; set new pixel
        pop     ebx             ; restore used registers
        pop     ebp             ; unlink
        ret

        .data

modsav  db      0               ; save for video mode
equsav  db      0               ; save for equipment flags
opnvid  dd      0               ; routine address for video open
clsvid  dd      0               ; routine address for video close
segvid  dd      0               ; routine address for video segment
setpxp  dd      0               ; setpix routine
getpxp  dd      0               ; getpix routine
linep   dd      0               ; line draw vector
linesp  dd      0               ; line draw with save vector
linerp  dd      0               ; line restore vector
blockp  dd      0               ; block draw vector
setchrp dd      0               ; draw character vector
dimx    dd      0               ; screen demension of x
dimy    dd      0               ; screen demension of y
linbyt  dd      0               ; number of bytes in line
data1   dd      0               ; card specific data 1
data2   dd      0               ; ""   ""       ""   2
data3   dd      0               ; ""   ""       ""   3
data4   dd      0               ; ""   ""       ""   4


        end

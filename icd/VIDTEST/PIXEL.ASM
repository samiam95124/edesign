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
;    clear           - clear screen to all white              ;
;    getpix(x, y)    - get a single pixel                     ;
;    setpix(x, y, c) - set a single pixel                     ;
;                                                             ;
; These will allow virtually screen function to be performed. ;
; Other functions are required because of speed.              ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rmwbits         equ     18h             ; read-modify-write bits
hline           equ     128             ; bytes in one horizontal line
originoffset    equ     0               ; byte offset of (0,0)
videobuffer     equ     0a0000h         ; address of video buffer
equflg          equ     410h            ; equipment flag in BIOS

                .386
                .model  small,c

                .code

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

iniscn  proc    c
        mov     ax,00f00h       ; get current mode
        int     10h
        mov     [modsav],al     ; save
        mov     edx,equflg
        mov     al,[edx]        ; get EQUIP_FLAG
        mov     [equsav],al     ; save
        mov     cl,al

; Check if running on an MDA

        and     al,00110000b    ; mask adapter type
        cmp     al,00110000b    ; check monocrome
        jnz     iniscn01        ; no, skip

; on MDA, switch displays and initalize VGA

        mov     al,cl           ; get EQUIP_FLAG
        and     al,11001111b    ; mask off select bits
        or      al,00100000b    ; set color (vga)
        mov     [edx],al        ; update
        mov     ax,0005dh       ; set 1024x768 mode for wd            
        int     10h             
        mov     [edx],cl        ; replace old select
        mov     ax,00007h       ; set MDA mode
        int     10h
        jmp     iniscn02        ; exit

; on VGA, just initalize

iniscn01:        
        mov     ax,0005dh       ; set 1024x768 mode for wd
        int     10h
iniscn02:
        mov     dx,3ceh         ; get controller address
        mov     ax,0050fh       ; unlock extended registers
        out     dx,ax
        ret
iniscn  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; RESET SCREEN MODE                                           ;
;                                                             ;
; Resets the screen mode to normal.                           ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resscn  proc    c
        mov     al,[equsav]     ; get old equipment flag
        mov     edx,equflg
        mov     [edx],al        ; replace
        mov     al,[modsav]     ; get old mode
        mov     ah,000h         ; set mode
        int     10h
        mov     dx,3ceh         ; get controller address
        mov     ax,0000fh       ; relock extended registers
        out     dx,ax
        ret
resscn  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; FIND PIXEL ADDRESS                                          ;
;                                                             ;
; Finds the address and mask of the given pixel.              ;
;                                                             ;
; In parameters: eax = y coordinate                           ;
;                ebx = x coordinate                           ;
;                                                             ;
; Out parameters: ah = bit mask                               ;
;                 ebx = address of byte in video memory       ;
;                 cl = number of bits to shift left           ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pixadd  proc    c
        push    edx             ; save registers
        mov     cl,bl           ; cl := low-order byte of x
        mov     edx,hline       ; eax := y * bytes per line
        mul     edx
        shr     ebx,3           ; ebx := x/8
        add     bx,ax           ; bx := y*bytesperline + x/8
        add     ebx,videobuffer
        mov     dx,03ceh        ; index grapics controller
        shr     eax,4           ; place 64kb offset in ah
        and     ax,0f000h       ; mask
        mov     al,09h          ; proa index value
        out     dx,ax           ; set proa
        and     cl,7            ; cl := x & 7
        xor     cl,7            ; cl := number of bits to shift left
        mov     ah,1            ; ah := unshifted bit mask
        pop     edx             ; restore registers
        ret
pixadd  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CLEAR SCREEN                                                ;
;                                                             ;
; Clears the screen to all white.                             ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear   proc    c
        push    edi             ; save registers
        mov     dx,03ceh        ; index grapics controller
        mov     al,9h           ; index for pr0a
        mov     ah,0h           ; hi_offset
        out     dx,ax           ; set it
        cld
        mov     edi,videobuffer ; index video buffer
        mov     al,0ffh         ; data value
        mov     ecx,10000h      ; 64k bytes
        rep     stosb           ; fill 32k with zero
        mov     al,9h           ; index for pr0a
        mov     ah,010h         ; hi_offset
        out     dx,ax           ; set it
        cld
        mov     edi,videobuffer ; index video buffer
        mov     al,0ffh         ; data value
        mov     ecx,8000h       ; 32k bytes
        rep     stosb           ; fill 32k with zero
        mov     al,0fh          ; pr5 index value
        pop     edi             ; restore registers
        ret
clear   endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; GET PIXEL                                                   ;
;                                                             ;
; Gets a pixel from the screen. Designed to                   ;
; be called by pascal, the format is:                         ;
;                                                             ;
;    getpix(x,  { x coordinate }                              ;
;           y)  { y coordinate }                              ;
;           :c; { color }                                     ;
;                                                             ;
; The x coordinate is from 0 to 1023, and the y coordinate is ;
; from 0 to 767. The color is from 0 to 15.                   ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getpix  proto   c x: dword, y: dword

getpix  proc    c x: dword, y: dword
        push    ebx             ; save registers used
        mov     eax,y           ; get coordinates
        mov     ebx,x
        call    pixadd          ; ah := bit mask
        mov     ch,ah
        shl     ch,cl           ; ch := bit mask in proper position
        xor     bl,bl           ; bl is used to accumulate the pixel 
                                ; value
        mov     ax,304h         ; ah := initial bit plane number
                                ; al := read map select register
                                ; number
        mov     dx,3ceh         ; dx := graphics controller port
getpix01:
        out     dx,ax           ; select bit plane
        mov     bh,[ebx]        ; bh := byte from current bit plane
        and     bh,ch           ; mask one bit
        neg     bh              ; bit 7 of bh := 1 
                                ; (if masked bit = 1)
                                ; bit 7 of bh := 0
                                ; (if masked bit = 0)
        rol     bx,1            ; bit 0 of bl := next bit from pixel
                                ; value
        dec     ah              ; ah := next bit plane number
        jge     getpix01        
        mov     al,bl           ; al := pixel value
        xor     ah,ah           ; ax := pixel value
        pop     ebx             ; restore used registers
        ret
getpix  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; SET PIXEL                                                   ;
;                                                             ;
; Sets a pixel on the screen to a given color. Designed to    ;
; be called by pascal, the format is:                         ;
;                                                             ;
;    setpix(x,    { x coordinate }                            ;
;           y,    { y coordinate }                            ;
;           clr); { color }                                   ;
;                                                             ;
; The x coordinate is from 0 to 1023, and the y coordinate is ;
; from 0 to 767. The color is from 0 to 15.                   ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setpix  proto   c x: dword, y: dword, clr: byte

setpix  proc    c x: dword, y: dword, clr: byte
        push    ebx             ; save registers used
        mov     dx,3ceh         ; get controller address
        mov     ah,clr          ; set color
        xor     al,al
        out     dx,ax
        mov     ax,00f01h       ; set bit plane mask
        out     dx,ax
        mov     ah,0
        mov     al,3            ; set function and select
        out     dx,ax
        mov     eax,y           ; get coordinates
        mov     ebx,x
        call    pixadd          ; ah := bit mask
        shl     ah,cl           ; ah := bit mask in proper position
        mov     al,8            ; al := bit mask register number
        out     dx,ax
        or      [ebx],al        ; set pixel
        xor     ax,ax           ; ah := 0, al := 0
        out     dx,ax           ; restore set/reset register
        inc     ax              ; ah := 0, al := 1
        out     dx,ax           ; restore enable set/reset register
        mov     al,3            ; ah := 0, al := 3
        out     dx,ax           ; al := data rotate/func select reg #
        mov     ax,0ff08h       ; ah := 11111111b, al := 8
        out     dx,ax           ; restore bit mask register
        pop     ebx             ; restore registers used
        ret

setpix  endp

        .data

modsav  db      0               ; save for video mode
equsav  db      0               ; save for equipment flags

        end

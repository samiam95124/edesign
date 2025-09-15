!!!! THIS FILE NOT UP TO DATE: SEE PRINTER.PAS !!!!!!

        TITLE   'printer output routines'
        name    draw
        page    55,132
;
_text   segment byte public 'CODE'
        assume  cs:_text
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; TRANSLATE AND OUTPUT PIXEL BUFFER                           ;
;                                                             ;
; Translates a pixel buffer to an output buffer  for the      ;
; fujitsu DL3400 printer.                                     ;
; The buffer is N times of 24 bytes, each byte of which       ;
; contains a color encoded in VGA 16 value colors.            ;
; A max parameter gives us the number of 24 byte sections to  ;
; output.                                                     ;
; We encode the values into 24 bit words, then output these   ;
; to the printer.                                             ;
; Note that only black and white is presently supported.      ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; procedure outbuf(var prtbuf: array[0..pmaxx, 0..23] of color;
;                  pmaxx: word);

prtbufs equ     word ptr [bp+10] ; stack frame addressing
prtbuf  equ     word ptr [bp+8]
pmaxx   equ     word ptr [bp+6]
linbuf  equ     word ptr [bp-(3*2448)]

        public  outbuf
outbuf  proc    far

        push    bp              ; preserve caller registers
        mov     bp,sp
        sub     sp,3*2448      ; stack space for printer buffer

; index pixel buffer 

        mov     es,prtbufs       
        mov     di,prtbuf

; index printer output buffer

        mov     si,bp
        sub     si,3*2448

        mov     dx,pmaxx        ; set number of 24 bit words
        inc     dx              ; adjust

; translate

xlate:

; high byte

        mov     ah,080h         ; set bit mask
        mov     al,000h
        mov     ss:[si],al      ; set clear byte
highb:
        mov     al,es:[di]      ; load pixel value
        cmp     al,00fh         ; test for white
        je      highb01         ; yes, skip
        or      ss:[si],ah      ; add bit
highb01:
        inc     di              ; next pixel        
        ror     ah,1            ; next bit  
        jnc     highb           ; loop for all bits
        inc     si              ; next         

; mid byte

        mov     al,000h
        mov     ss:[si],al      ; set clear byte
midb:
        mov     al,es:[di]      ; load pixel value
        cmp     al,00fh         ; test for white
        je      midb01          ; yes, skip
        or      ss:[si],ah      ; add bit
midb01:
        inc     di              ; next pixel        
        ror     ah,1            ; next bit  
        jnc     midb            ; loop for all bits
        inc     si              ; next         

; low byte

        mov     al,000h
        mov     ss:[si],al      ; set clear byte
lowb:
        mov     al,es:[di]      ; load pixel value
        cmp     al,00fh         ; test for white
        je      lowb01          ; yes, skip
        or      ss:[si],ah      ; add bit
lowb01:
        inc     di              ; next pixel        
        ror     ah,1            ; next bit  
        jnc     lowb            ; loop for all bits
        inc     si              ; next         

        dec     dx              ; count
        jnz     xlate           ; loop for all groups

; output preamble to printer 

        mov     ah,0
        mov     al,27           ; set color of line to black
        mov     dx,0
        int     17h

        mov     ah,0
        mov     al,114
        mov     dx,0
        int     17h

        mov     ah,0
        mov     al,0
        mov     dx,0
        int     17h

        mov     ah,0
        mov     al,13           ; return to line start
        mov     dx,0
        int     17h

        mov     ah,0
        mov     al,27           ; line preamble
        mov     dx,0
        int     17h

        mov     ah,0
        mov     al,42
        mov     dx,0
        int     17h
        
        mov     ah,0
        mov     al,39
        mov     dx,0
        int     17h

        mov     bx,pmaxx        ; output number of 24 bit words 
        inc     bx              ; adjust
        mov     ah,0
        mov     al,bl
        mov     dx,0
        int     17h

        mov     ah,0
        mov     al,bh
        mov     dx,0
        int     17h

; index printer output buffer

        mov     si,bp
        sub     si,3*2448

; output contents of buffer

bufout:
        mov     ah,0
        mov     al,ss:[si]      ; output byte
        mov     dx,0
        int     17h
        inc     si              ; next byte
        mov     ah,0
        mov     al,ss:[si]      ; output byte
        mov     dx,0
        int     17h
        inc     si              ; next byte
        mov     ah,0
        mov     al,ss:[si]      ; output byte
        mov     dx,0
        int     17h
        inc     si              ; next byte
        dec     bx              ; count bytes
        jnz     bufout          ; loop till done

        mov     ah,0
        mov     al,13           ; return to line start
        mov     dx,0
        int     17h

        mov     sp,bp           ; restore registers and return
        pop     bp
        pop     cx              ; save return address
        pop     es
        add     sp,3*2          ; remove parameters
        push    es              ; restore return address
        push    cx        
        ret

outbuf  endp

_text   ends

        end

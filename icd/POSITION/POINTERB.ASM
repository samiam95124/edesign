                title   'pointer device access routines'
                name    auxio
                page    55,132

comm_data       equ     03f8h           ; port assignments for COM1
com_ier         equ     03f9h
comm_mcr        equ     03fch
comm_stat       equ     03fdh

        .386
        .model  small, c

        .code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; INITALIZE COM1:                                             ;
;                                                             ;
; Initalizes COM1: to 9600 baud, 8 bits, odd parity, one      ;
; stop bit, as required by the Summagraphics tablet.          ;
; The uart is cleared of any garbage waiting.                 ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

iniaux  proc    syscall
        mov     dx,0            ; set COM1:
        mov     ax,000ebh       ; set 9600,8,o,1
        int     20              ; initalize port
        ret                     ; exit
iniaux  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CHECK STATUS COM1:                                          ;
;                                                             ;
; Returns status of character waiting for COM1:. This is      ;
; 0 if no character awaits, or 0ffh if one is.                ;
;                                                             ;
; function stsaux: byte;                                      ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stsaux  proc    syscall
        mov     dx,comm_stat    ; index status port
        in      al,dx           ; get status
        and     ax,001h         ; mask
        jz      stsaux01        ; not ready, exit
        mov     ax,0ffh         ; else set ready code
stsaux01:
        ret
stsaux  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; INPUT COM1:                                                 ;
;                                                             ;
; Inputs a single character from COM1:.                       ;
; Features a timeout to insure that this routine will not     ;
; hangup. There is no error indication for this.              ;
;                                                             ;
; function getaux: byte;                                      ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getaux  proc    syscall
        push    ebx             ; save registers used
        mov     bx,10000        ; set timeout value
        mov     dx,comm_stat    ; index status port
getaux01:
        in      al,dx           ; get status
        and     al,001h         ; mask
        jnz     getaux02        ; ready, skip
        dec     bx              ; process timeout
        mov     al,bl           ; check timeout occurred
        or      al,bh
        jnz     getaux01        ; no, loop
getaux02:
        mov     dx,comm_data    ; index data port
        in      al,dx           ; get byte      
        movzx   ax,al           ; extend to word
        pop     ebx             ; restore registers
        ret
getaux  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; OUTPUT COM1:                                                ;
;                                                             ;
; Outputs a single byte to the COM1: port.                    ;
;                                                             ;
; procedure putaux(b: byte);                                  ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

putaux  proc    syscall b: byte
        mov     dx,comm_stat    ; index status port
putaux01:
        in      al,dx           ; get status
        and     al,020h         ; mask
        jz      putaux01        ; loop till ready
        mov     al,b            ; get byte to output
        mov     dx,comm_data    ; index data port
        out     dx,al           ; output byte
        ret                     ; exit
putaux  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; INITALIZE MOUSE DRIVER                                      ;
;                                                             ;
; procedure inims; cexternal;                                 ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inims   proc    syscall
        mov     ax,00000h       ; reset mouse and get status
        int     33h             ; execute
        ret                     ; exit
inims   endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; READ MOTION COUNTERS                                        ;
;                                                             ;
; procedure readmot(var x, y: integer); cexternal;            ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

motx    =       8
moty    =       12

readmot proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        mov     ax,0000bh       ; read motion counters
        int     33h             ; execute
        movsx   ecx,cx          ; extend x
        movsx   edx,dx          ; extend y
        mov     ebx,[ebp+motx]  ; get address of x
        mov     [ebx],ecx       ; place
        mov     ebx,[ebp+moty]  ; get address of y
        mov     [ebx],edx       ; place
        pop     ebx             ; restore registers and return
        pop     ebp             ; unlink
        ret
readmot endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; READ BUTTON STATUS                                          ;
;                                                             ;
; Reads the current button press status.                      ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

readsts proc    syscall
        mov     ax,00003h       ; get mouse button status
        int     33h             ; execute
        movzx   eax,bx          ; extend
        ret
readsts endp

        end


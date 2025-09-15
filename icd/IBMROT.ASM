                title   'IBM PC system routines'
                name    pixel
                page    55,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; IBM PC SPECIFIC SYSTEM ROUTINES                             ;
;                                                             ;
; Contains various system routines.                           ;
; To avoid various DOS oddities, the lowest level             ;
; implementation as possible is used.                         ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                .386
                .model  small, c

                .code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; GET KEYBOARD STATUS                                         ;
;                                                             ;
; Gets the current status of keyboard character waiting.      ;
;                                                             ;
; function kbdrdy: byte;                                      ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kbdrdy  proc    syscall
        mov     ah,001h         ; get keyboard status
        int     16h
        mov     ax,0ffh         ; set ready status
        jnz     kbdrdy01        ; yes, go
        mov     ax,000h         ; set not ready status
kbdrdy01:
        ret                     ; exit
kbdrdy  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; GET KEYBOARD CHARACTER                                      ;
;                                                             ;
; Gets the next keyboard character.                           ;
;                                                             ;
; function kbdinp: byte;                                      ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kbdinp  proc    syscall
        mov     ah,007h         ; get keyboard character
        int     21h
        movzx   ax,al           ; extend to word
        ret                     ; exit
kbdinp  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; GET CURRENT TIME                                            ;
;                                                             ;
; Loads the number of hundreth seconds since midnight.        ;
;                                                             ;
; function gettim: integer                                    ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gettim  proc    syscall
        push    ebx             ; save registers used
        mov     ah,02ch         ; get system time
        int     21h
        movzx   ebx,dl          ; place hundreths
        movzx   eax,dh          ; place seconds
        mov     edx,100         ; find hundreths
        mul     edx
        add     ebx,eax         ; add in
        movzx   eax,cl          ; place minutes
        mov     edx,60*100      ; find hundreths
        mul     edx
        add     ebx,eax         ; add in
        movzx   eax,ch          ; place hours
        mov     edx,60*(60*100) ; find hundreths
        mul     edx
        add     eax,ebx         ; add and place
        pop     ebx             ; restore registers
        ret                     ; exit
gettim  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CONVERT WORD                                                ;
;                                                             ;
; Converts one word to another. Simply for type convertion.   ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

convert proc    syscall x: word
        mov     ax,x            ; get the word
        ret                     ; exit
convert endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CLEAR INTERRUPT FLAG                                        ;
;                                                             ;
; Clears the interrupt enable flag. Used to disable           ;
; interrupts.                                                 ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clrint  proc    syscall
        cli                     ; clear interupt flag
        ret                     ; exit
clrint  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CLEAR INTERRUPT FLAG                                        ;
;                                                             ;
; Clears the interrupt enable flag. Used to disable           ;
; interrupts.                                                 ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setint  proc    syscall
        sti                     ; set interupt flag
        ret                     ; exit
setint  endp

        end

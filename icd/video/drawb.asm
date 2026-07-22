        TITLE   'drawing primitive routines'
        name    drawb
        page    55,132

        .386
        .model  small, c

vidbuf  equ     0a0000h         ; address of video buffer
rmwbit  equ     0               ; value for data rotate/func select reg
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

        extern  syscall pixadd:near ; calculate pixel address  
        extern  segvid:dword    ; change video segment (vector)  
        extern  varseg:byte     ; current video segment
        extern  linbyt:dword    ; number of bytes in line
        extern  setchrp:dword   ; draw character vector
        .code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; INITALIZE CHARACTER TABLE                                   ;
;                                                             ;
; The assembly version does not require initalization.        ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inialpha proc    syscall
        ret
inialpha endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW CHARACTER                                              ;
;                                                             ;
; Place character on screen. The character generator          ;
; considers the screen to be a matrix of 16 x 16 cells.       ;
; Only the forground colors are set.                          ;
;                                                             ;
; procedure setchr(x, y: integer; c: char; clr: color)        ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vp      equ     8               ; pointer to viewport record
x       equ     12              ; x address
y       equ     16              ; y address
char    equ     20              ; character to place
clr     equ     22              ; foreground color

setchr  proc    syscall
        jmp     [setchrp]       ; goto proper routine
setchr  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW CHARACTER PLANAR                                       ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setchrpl proc   syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        push    esi
        push    edi
        mov     dx,03ceh        ; index video controller
        mov     ah,[ebp+clr]    ; ah := pixel value
        xor     al,al           ; al := set/reset register number
        out     dx,ax
        mov     ax,0f01h        ; ah := 1111b (bit plane mask for
                                ;  enable set/reset)
        out     dx,ax           ; al := enable set/reset register #
        mov     ah,rmwbit       ; bits 3 and 4 of ah := function
        mov     al,3            ; al := data rotate/func select reg #
        out     dx,ax
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
        cmp     ebx,[edi+viewcex] ; check x > clip(xe)
        jg      setc03          ; yes, exit
        cmp     eax,[edi+viewcey] ; check y > clip(ye)
        jg      setc03          ; yes, exit
        mov     ecx,ebx         ; check x+15 < clip(xs)
        add     ecx,15
        cmp     ecx,[edi+viewcsx]
        jl      setc03          ; yes, exit
        mov     ecx,eax         ; check y+15 < clip(ys)
        add     ecx,15
        cmp     ecx,[edi+viewcsy]
        jl      setc03          ; yes, exit

; convert to address

        push    eax             ; save y
        push    ebx             ; save x
        mov     cl,bl           ; cl := low-order byte of x
        mul     [linbyt]        ; eax := y * bytes per line
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        call    [segvid]        ; select segment
        mov     [varseg],ah     ; place segment
        and     cl,7            ; cl := x & 7
        xor     cl,7            ; cl := number of bits to shift left
        mov     esi,ebx         ; save buffer address
        mov     edi,offset chrtbl ; index character table
        movzx   eax,byte ptr [ebp+char] ; get character
        and     ax,07fh         ; remove high bit
        add     ax,ax           ; * 32 for each character
        add     ax,ax
        add     ax,ax
        add     ax,ax
        add     ax,ax
        add     edi,eax         ; offset to proper character
        pop     ebx             ; restore x
        pop     eax             ; restore y
        
; mask clipping within character

        push    eax             ; save y
        mov     ebp,[ebp+vp]    ; get pointer to viewport record
        mov     ch,16           ; set default lines
        mov     edx,[ebp+viewcsy] ; find clip(ys)-y
        sub     edx,eax
        jle     setc000         ; clip(ys) <= y, skip
        sub     ch,dl           ; adjust count
        shl     edx,1           ; * 2 (for bytes in character line)
        add     edi,edx         ; offset lines in character
        shr     edx,1           ; restore
        mov     eax,edx         ; find line offset in buffer
        mul     [linbyt]        
        add     si,ax
        jc      setc000         ; skip no new page
        mov     ah,[varseg]     ; set next segment
        inc     ah
        mov     [varseg],ah
        call    [segvid]        ; select segment
setc000:
        pop     eax             ; restore y
        mov     edx,eax         ; get y
        add     edx,15          ; offset to end of character
        sub     edx,[ebp+viewcey] ; find y+15-clip(ye)
        jle     setc001         ; clip(ye) <= y, skip
        sub     ch,dl           ; adjust count
setc001:
        mov     eax,00000ffffh  ; set mask
        mov     edx,[ebp+viewcsx] ; find clip(xs)-x
        sub     edx,ebx
        jle     setc002         ; clip(xs) <= x, skip
        xchg    edx,ecx         ; rotate mask
        shr     eax,cl
        xchg    edx,ecx         ; restore
setc002:
        push    eax             ; save mask
        mov     eax,00000ffffh  ; set mask
        mov     edx,ebx         ; get x
        add     edx,15          ; offset to end of character
        sub     edx,[ebp+viewcex] ; find x+15-clip(xe)
        jle     setc003         ; clip(xe) <= x, skip
        xchg    edx,ecx         ; rotate mask
        shl     eax,cl
        xchg    edx,ecx         ; restore
setc003:
        pop     ebx             ; get 1st mask
        and     eax,ebx         ; find resultant mask
        mov     ebp,eax         ; place mask

; draw character body

        inc     cl              ; adjust shift count
        mov     dx,03ceh        ; index video controller
setc01:
        movzx   ebx,word ptr [edi] ; get word
        and     ebx,ebp         ; mask
        shl     ebx,cl          ; shift into place
        mov     eax,ebx         ; place
        shr     eax,8
        mov     al,8            ; set mask register
        out     dx,ax           ; output to mask register
        or      [esi],al        ; update to video memory
        add     si,1            ; next byte
        jnc     setc010         ; no carry, skip
        mov     ah,[varseg]     ; set next segment
        inc     ah
        mov     [varseg],ah
        call    [segvid]        ; select segment
setc010:
        mov     ah,bh           ; place
        out     dx,ax           ; output to mask register
        or      [esi],al        ; update to video memory
        add     si,1            ; next byte
        jnc     setc011         ; no carry, skip
        mov     ah,[varseg]     ; set next segment
        inc     ah
        mov     [varseg],ah
        call    [segvid]        ; select segment
setc011:
        mov     ah,bl           ; place
        out     dx,ax           ; output to mask register
        or      [esi],al        ; update to video memory
        inc     edi             ; next word
        inc     edi
        mov     eax,linbyt      ; offset to next line
        dec     ax
        dec     ax
        add     si,ax           ; offset next line
        jnc     setc02          ; no carry, skip

; Because we only draw downwards, only one segment crossing is
; considered.

        mov     ah,[varseg]     ; set next segment
        inc     ah
        mov     [varseg],ah
        call    [segvid]        ; select segment
setc02:
        dec     ch              ; count
        jnz     setc01          ; loop

; Restore video registers and exit

setc03:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
setchrpl endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW CHARACTER PACKED                                       ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setchrpk proc   syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        push    esi
        push    edi
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
        cmp     ebx,[edi+viewcex] ; check x > clip(xe)
        jg      setcpk06        ; yes, exit
        cmp     eax,[edi+viewcey] ; check y > clip(ye)
        jg      setcpk06        ; yes, exit
        mov     ecx,ebx         ; check x+15 < clip(xs)
        add     ecx,15
        cmp     ecx,[edi+viewcsx]
        jl      setcpk06        ; yes, exit
        mov     ecx,eax         ; check y+15 < clip(ys)
        add     ecx,15
        cmp     ecx,[edi+viewcsy]
        jl      setcpk06        ; yes, exit

; convert to address

	mul	word ptr [linbyt] ; multiply y by pitch
        mov     cl,bl           ; save x lower
	shr	ebx,1		; convert pixel to byte number
	add	eax,ebx		; add to previous product
        add     eax,vidbuf      ; offset by video base
        mov     esi,eax         ; save buffer address
	mov	ah,dl		; Copy page number into ah
	mov	[varseg],Ah	; Save page number
	call	[segvid]	; Select proper page
	mov	bx,00ff0h	; Set initial mask (assume x even)
				; bl=src mask, bh=dst mask
        test    cl,1            ; test x even
        jz      setcpk00        ; yes, skip
        not     bx              ; else flip
setcpk00:
        mov     edi,offset chrtbl ; index character table
        movzx   eax,byte ptr [ebp+char] ; get character
        and     ax,07fh         ; remove high bit
        add     ax,ax           ; * 32 for each character
        add     ax,ax
        add     ax,ax
        add     ax,ax
        add     ax,ax
        add     edi,eax         ; offset to proper character
        mov     al,[ebp+clr]    ; get color
        mov     ah,al           ; copy to high nybble
        shl     al,4
        or      al,ah     

; draw character body

        mov     ch,16           ; set number of lines to copy
setcpk01:
        push    bx              ; save mask
        push    esi             ; save buffer address
        mov     cl,16           ; set number of bits to place
        mov     dx,word ptr [edi] ; get word
        inc     edi             ; next
        inc     edi
setcpk02:
        shl     dx,1            ; test top bit
        jnc     setcpk03        ; not set, skip write
	mov	ah,al		; Fetch source color
	and	ah,bl		; Clear the 'other' nibble
	and	[esi],bh 	; Clear nibble at destination
	or	[esi],ah 	; Combine source and destination
setcpk03:
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
        jns     setcpk04        ; no, skip
        add     si,1            ; next byte
        jnc     setcpk04        ; go no page overflow
	mov	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]  	; Select new page number
	mov	[varseg],ah	; Save updated page, restore AL
setcpk04:        
        dec     cl              ; count bits
        jnz     setcpk02        ; more, loop
        pop     esi             ; restore buffer address
        pop     bx              ; restore mask
        add     si,word ptr [linbyt] ; next line
        jnc     setcpk05        ; go no page overflow
	mov	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]  	; Select new page number
	mov	[varseg],ah	; Save updated page, restore AL
setcpk05:
        dec     ch              ; count lines
        jnz     setcpk01        ; more, loop
setcpk06:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
setchrpk endp

        .data
;
; Character table
; Defines 16x16 characters as 32 bytes of data each.
; Note that not all characters are defined, as we do
; not presently require all characters.
; Note that the control characters are used to store 
; special characters.
; Notes on format:
; The outer edge of each character is reserved for 
; a possible cell border. Each "button" is bordered
; with a single strip of pixels, so that when all buttons
; are abutted, two pixel separation lines result.
; We also maintain two pixels of "white space" between
; character black space and the border, for appearance.
; In general, it is a good assumtion that anything less than
; two pixels wide will not be properly visable. Thus,
; each character attempts to maintain double pixel drawing
; width. There are execptions.
;

; 00H: copyright

chrtbl  dw      0011111100000000b
        dw      0100000010000000b
        dw      1001111001000000b
        dw      1010000101000000b
        dw      1010000001000000b
        dw      1010000001000000b
        dw      1010000101000000b
        dw      1001111001000000b
        dw      0100000010000000b
        dw      0011111100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 01H: micro

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0110000110000000b                                         
        dw      0110000110000000b                                    
        dw      0110110110000000b                                   
        dw      0111100110000000b                                         
        dw      0111111110000000b                                   
        dw      1101111100000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b                                    
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 02H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 03H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 04H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 05H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 06H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 07H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 08H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 09H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 0AH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 0BH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 0CH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 0DH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 0EH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 0FH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 10H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 11H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 12H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 13H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 14H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 15H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 16H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 17H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 18H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 19H: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 1AH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 1BH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 1CH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 1DH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 1EH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 1FH: unused

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 20H: ' '

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

; 21H: '!'

        dw      1100000000000000b                                    
        dw      1100000000000000b                                     
        dw      1100000000000000b                                  
        dw      1100000000000000b                                      
        dw      1100000000000000b                                         
        dw      1100000000000000b                                    
        dw      1100000000000000b                                   
        dw      1100000000000000b                                         
        dw      0000000000000000b                                   
        dw      1100000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 22H: '"'

        dw      1101100000000000b                                    
        dw      1101100000000000b                                     
        dw      1101100000000000b                                  
        dw      1101100000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 23H: '#'

        dw      0011001100000000b                                    
        dw      0011001100000000b                                     
        dw      0111111110000000b                                  
        dw      0011001100000000b                                      
        dw      0011001100000000b                                         
        dw      0110011000000000b                                    
        dw      0110011000000000b                                   
        dw      1111111100000000b                                         
        dw      0110011000000000b                                   
        dw      0110011000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 24H: '$'

        dw      0011000000000000b                                    
        dw      0111100000000000b                                     
        dw      1100110000000000b                                  
        dw      1100110000000000b                                      
        dw      1100000000000000b                                         
        dw      0111100000000000b                                    
        dw      0000110000000000b                                   
        dw      0000110000000000b                                         
        dw      1100110000000000b                                   
        dw      0111100000000000b                                     
        dw      0011000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 25H: '%'

        dw      0111000001100000b                                    
        dw      1101100011000000b                                     
        dw      1101100110000000b                                  
        dw      1101101100000000b                                      
        dw      0111011000000000b                                         
        dw      0000110111000000b                                    
        dw      0001101101100000b                                   
        dw      0011001101100000b                                         
        dw      0110001101100000b                                   
        dw      1100000111000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 26H: '&'

        dw      0011100000000000b                                    
        dw      0110110000000000b                                     
        dw      0110110000000000b                                  
        dw      0110110000000000b                                      
        dw      0011100000000000b                                         
        dw      0111000000000000b                                    
        dw      1101101000000000b                                   
        dw      1100111000000000b                                         
        dw      1100110000000000b                                   
        dw      0111111000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 27H: '''

        dw      0011000000000000b                                    
        dw      0011000000000000b                                     
        dw      0110000000000000b                                  
        dw      1100000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 28H: '('

        dw      0110000000000000b                                    
        dw      1100000000000000b                                     
        dw      1100000000000000b                                  
        dw      1100000000000000b                                      
        dw      1100000000000000b                                         
        dw      1100000000000000b                                    
        dw      1100000000000000b                                   
        dw      1100000000000000b                                         
        dw      1100000000000000b                                   
        dw      1100000000000000b                                     
        dw      1100000000000000b                                   
        dw      1100000000000000b                                    
        dw      0110000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 29H: ')'

        dw      1100000000000000b                                    
        dw      0110000000000000b                                     
        dw      0110000000000000b                                  
        dw      0110000000000000b                                      
        dw      0110000000000000b                                         
        dw      0110000000000000b                                    
        dw      0110000000000000b                                   
        dw      0110000000000000b                                         
        dw      0110000000000000b                                   
        dw      0110000000000000b                                     
        dw      0110000000000000b                                   
        dw      0110000000000000b                                    
        dw      1100000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 2AH: '*'

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      1100110000000000b                                  
        dw      0111100000000000b                                      
        dw      0011000000000000b                                         
        dw      1111110000000000b                                    
        dw      0011000000000000b                                   
        dw      0111100000000000b                                         
        dw      1100110000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 2BH: '+'
    
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0011000000000000b                                  
        dw      0011000000000000b                                      
        dw      0011000000000000b                                         
        dw      1111110000000000b                                    
        dw      0011000000000000b                                   
        dw      0011000000000000b                                         
        dw      0011000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 2CH: ','

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0110000000000000b                                   
        dw      0110000000000000b                                     
        dw      1100000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 2DH: '-'

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      1111000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
                         
; 2EH: '.'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
                        
; 2FH: '/'

        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 30H: '0'
  
        dw      0111100000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      0111100000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 31H: '1'

        dw      0011000000000000b
        dw      1111000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 32H: '2'

        dw      0111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0000110000000000b
        dw      0001100000000000b
        dw      0011000000000000b
        dw      0110000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 33H: '3'

        dw      0111100000000000b
        dw      1100110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0011100000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 34H: '4'

        dw      0000110000000000b  
        dw      0001110000000000b  
        dw      0011110000000000b  
        dw      0011110000000000b  
        dw      0110110000000000b  
        dw      0110110000000000b  
        dw      1100110000000000b  
        dw      1111110000000000b  
        dw      0000110000000000b  
        dw      0000110000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 35H: '5'

        dw      1111110000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111100000000000b
        dw      1100110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 36H: '6'

        dw      0111100000000000b
        dw      1100110000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 37H: '7'

        dw      1111110000000000b
        dw      0000110000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0011000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 38H: '8'
    
        dw      0111100000000000b                                         
        dw      1100110000000000b                                            
        dw      1100110000000000b                                  
        dw      1100110000000000b                                        
        dw      0111100000000000b                                     
        dw      1100110000000000b                                          
        dw      1100110000000000b                                     
        dw      1100110000000000b                                       
        dw      1100110000000000b                                     
        dw      0111100000000000b                                   
        dw      0000000000000000b                                  
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                        
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      

; 39H: '9'

        dw      0111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0111110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 3AH: ':'

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      1100000000000000b                                  
        dw      1100000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      1100000000000000b                                   
        dw      1100000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 3BH: ';'
    
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0110000000000000b                                  
        dw      0110000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0110000000000000b                                   
        dw      0110000000000000b                                     
        dw      1100000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 3CH: '<'

        dw      0000000000000000b                                    
        dw      0000110000000000b                                     
        dw      0001100000000000b                                  
        dw      0011000000000000b                                      
        dw      0110000000000000b                                         
        dw      1100000000000000b                                    
        dw      0110000000000000b                                   
        dw      0011000000000000b                                         
        dw      0001100000000000b                                   
        dw      0000110000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 3DH: '='

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      1111110000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      1111110000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 3EH: '>'

        dw      0000000000000000b                                    
        dw      1100000000000000b                                     
        dw      0110000000000000b                                  
        dw      0011000000000000b                                      
        dw      0001100000000000b                                         
        dw      0000110000000000b                                    
        dw      0001100000000000b                                   
        dw      0011000000000000b                                         
        dw      0110000000000000b                                   
        dw      1100000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 3FH: '?'

        dw      0111100000000000b                                    
        dw      1100110000000000b                                     
        dw      1100110000000000b                                  
        dw      0000110000000000b                                      
        dw      0001100000000000b                                         
        dw      0011000000000000b                                    
        dw      0011000000000000b                                   
        dw      0000000000000000b                                         
        dw      0011000000000000b                                   
        dw      0011000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 40H: '@'

        dw      0000111111100000b                                    
        dw      0011100000110000b                                     
        dw      1110011110011000b                                  
        dw      1100110011011000b                                      
        dw      1101100011011000b                                         
        dw      1101100010011000b                                    
        dw      1100111111110000b                                   
        dw      1110000000000000b                                         
        dw      0011100000111000b                                   
        dw      0000111111100000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 41H: 'A'

        dw      0001100000000000b  
        dw      0001100000000000b  
        dw      0011110000000000b  
        dw      0011110000000000b  
        dw      0010010000000000b  
        dw      0110011000000000b  
        dw      0110011000000000b  
        dw      0111111100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 42H: 'B'

        dw      1111111000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1111111000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1111111000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 43H: 'C'
    
        dw      0011110000000000b
        dw      0110011000000000b
        dw      1100001000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100001000000000b
        dw      0110011000000000b
        dw      0011110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 44H: 'D'

        dw      1111110000000000b
        dw      1100011000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100011000000000b
        dw      1111110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 45H: 'E'

        dw      1111111000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1111110000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1111111000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 46H: 'F'
    
        dw      1111111000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111110000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 47H: 'G'

        dw      0011111000000000b
        dw      0110001100000000b
        dw      1100000100000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100111100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      0110001100000000b
        dw      0011110100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 48H: 'H'

        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1111111100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 49H: 'I'
    
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 4AH: 'J'

        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 4BH: 'K'

        dw      1100011000000000b
        dw      1100110000000000b
        dw      1101100000000000b
        dw      1111000000000000b
        dw      1110000000000000b
        dw      1111000000000000b
        dw      1101100000000000b
        dw      1100110000000000b
        dw      1100011000000000b
        dw      1100001100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 4CH: 'L'
    
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111111000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 4DH: 'M'

        dw      1100000011000000b  
        dw      1100000011000000b  
        dw      1110000111000000b  
        dw      1110000111000000b  
        dw      1111001111000000b  
        dw      1111001111000000b  
        dw      1101111011000000b  
        dw      1101111011000000b  
        dw      1100110011000000b  
        dw      1100110011000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 4EH: 'N'  

        dw      1100001100000000b
        dw      1110001100000000b
        dw      1111001100000000b
        dw      1111001100000000b
        dw      1101101100000000b
        dw      1101101100000000b
        dw      1100111100000000b
        dw      1100111100000000b
        dw      1100011100000000b
        dw      1100001100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

;4FH: 'O'

        dw      0011110000000000b
        dw      0110011000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      0110011000000000b
        dw      0011110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 50H: 'P'

        dw      1111111000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1111111000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 51H: 'Q'

        dw      0011110000000000b  
        dw      0110011000000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100111100000000b  
        dw      0110011000000000b  
        dw      0011111100000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 52H: 'R'

        dw      1111111000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1111111000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      1100000110000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 53H: 'S'

        dw      0111110000000000b
        dw      1100011000000000b
        dw      1100011000000000b
        dw      1100000000000000b
        dw      0111000000000000b
        dw      0001110000000000b
        dw      0000011000000000b
        dw      1100011000000000b
        dw      1100011000000000b
        dw      0111110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 54H: 'T'

        dw      1111111100000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 55H: 'U' 
      
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      1100001100000000b  
        dw      0110011000000000b  
        dw      0011110000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 56H: 'V'

        dw      1100001100000000b
        dw      1100001100000000b
        dw      0110011000000000b
        dw      0110011000000000b
        dw      0110011000000000b
        dw      0010010000000000b
        dw      0011110000000000b
        dw      0011110000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 57H: 'W'

        dw      1100001100001100b
        dw      1100001100001100b
        dw      1100001100001100b
        dw      0110011110011000b
        dw      0110011110011000b
        dw      0011010010110000b
        dw      0011110011110000b
        dw      0001100001100000b
        dw      0001100001100000b
        dw      0001100001100000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 58H: 'X'

        dw      1100000110000000b
        dw      1100000110000000b
        dw      0110001100000000b
        dw      0011011000000000b
        dw      0001110000000000b
        dw      0001110000000000b
        dw      0011011000000000b
        dw      0110001100000000b
        dw      1100000110000000b
        dw      1100000110000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 59H: 'Y'

        dw      1100000011000000b                                      
        dw      1100000011000000b                                       
        dw      0110000110000000b                                    
        dw      0011001100000000b                                        
        dw      0001111000000000b                                           
        dw      0000110000000000b                                      
        dw      0000110000000000b                                     
        dw      0000110000000000b                                           
        dw      0000110000000000b                                     
        dw      0000110000000000b                                       
        dw      0000000000000000b                                     
        dw      0000000000000000b                                      
        dw      0000000000000000b                                  
        dw      0000000000000000b                                    
        dw      0000000000000000b                                         
        dw      0000000000000000b                                  

; 5AH: 'Z'

        dw      1111111110000000b
        dw      0000000110000000b
        dw      0000001100000000b
        dw      0000011000000000b
        dw      0000110000000000b
        dw      0001100000000000b
        dw      0011000000000000b
        dw      0110000000000000b
        dw      1100000000000000b
        dw      1111111110000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 5BH: '['

        dw      1110000000000000b                                    
        dw      1100000000000000b                                     
        dw      1100000000000000b                                  
        dw      1100000000000000b                                      
        dw      1100000000000000b                                         
        dw      1100000000000000b                                    
        dw      1100000000000000b                                   
        dw      1100000000000000b                                         
        dw      1100000000000000b                                   
        dw      1100000000000000b                                     
        dw      1100000000000000b                                   
        dw      1100000000000000b                                    
        dw      1110000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 5CH: '\'

        dw      1100000000000000b                                    
        dw      1100000000000000b                                     
        dw      1100000000000000b                                  
        dw      1100000000000000b                                      
        dw      0110000000000000b                                         
        dw      0110000000000000b                                    
        dw      0110000000000000b                                   
        dw      0110000000000000b                                         
        dw      0011000000000000b                                   
        dw      0011000000000000b                                     
        dw      0011000000000000b                                   
        dw      0011000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 5DH: ']'

        dw      1110000000000000b                                    
        dw      0110000000000000b                                     
        dw      0110000000000000b                                  
        dw      0110000000000000b                                      
        dw      0110000000000000b                                         
        dw      0110000000000000b                                    
        dw      0110000000000000b                                   
        dw      0110000000000000b                                         
        dw      0110000000000000b                                   
        dw      0110000000000000b                                     
        dw      0110000000000000b                                   
        dw      0110000000000000b                                    
        dw      1110000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 5EH: '^'

        dw      0010000000000000b                                    
        dw      0111000000000000b                                     
        dw      1101100000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 5FH: '_'

        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      1111111100000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 60H: '`'

        dw      1100000000000000b                                    
        dw      1100000000000000b                                     
        dw      1100000000000000b                                  
        dw      0110000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 61H: 'a'

        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0111100000000000b  
        dw      1100110000000000b  
        dw      0011110000000000b  
        dw      0110110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      0111110000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 62H: 'b'

        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 63H: 'c'
    
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0111100000000000b
        dw      1100110000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 64H: 'd'

        dw      0000110000000000b
        dw      0000110000000000b
        dw      0000110000000000b
        dw      0111110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0111110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 65H: 'e'

        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0111100000000000b  
        dw      1100110000000000b  
        dw      1111110000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100110000000000b  
        dw      0111100000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 66H: 'f' 
           
        dw      0011000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      1111000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 67H: 'g' 
           
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0111110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0111110000000000b
        dw      0000110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 68H: 'h'

        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 69H: 'i'
    
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      0000000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      1100000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 6AH: 'j' 

        dw      0110000000000000b
        dw      0110000000000000b
        dw      0000000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 6BH: 'k' 

        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100110000000000b
        dw      1101100000000000b
        dw      1111000000000000b
        dw      1110000000000000b
        dw      1111000000000000b
        dw      1101100000000000b
        dw      1100110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 6CH: 'l'
    
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 6DH: 'm'

        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      1111111110000000b  
        dw      1100110011000000b  
        dw      1100110011000000b  
        dw      1100110011000000b  
        dw      1100110011000000b  
        dw      1100110011000000b  
        dw      1100110011000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 6EH: 'n'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 6FH: 'o'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 70H: 'p'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1111100000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1100110000000000b
        dw      1111100000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
                        
; 71H: 'q'

        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0111110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      0111110000000000b  
        dw      0000110000000000b  
        dw      0000110000000000b  
        dw      0000110000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 72H: 'r'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1111000000000000b
        dw      1110000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      1100000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 73H: 's'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0111100000000000b
        dw      1100110000000000b
        dw      1100000000000000b
        dw      0111100000000000b
        dw      0000110000000000b
        dw      1100110000000000b
        dw      0111100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 74H: 't'

        dw      0110000000000000b
        dw      0110000000000000b
        dw      1111000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0110000000000000b
        dw      0011000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 75H: 'u'
    
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      1100110000000000b  
        dw      0111110000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  
        dw      0000000000000000b  

; 76H: 'v'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1100001100000000b
        dw      1100001100000000b
        dw      0110011000000000b
        dw      0110011000000000b
        dw      0011110000000000b
        dw      0001100000000000b
        dw      0001100000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 77H: 'w'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1100000011000000b
        dw      1100110011000000b
        dw      0110110110000000b
        dw      0110110110000000b
        dw      0111111110000000b
        dw      0011001100000000b
        dw      0011001100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 78H: 'x'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1100001100000000b
        dw      0110011000000000b
        dw      0011110000000000b
        dw      0001100000000000b
        dw      0011110000000000b
        dw      0110011000000000b
        dw      1100001100000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 79H: 'y'

        dw      0000000000000000b                                      
        dw      0000000000000000b                                       
        dw      0000000000000000b                                    
        dw      1100001100000000b                                        
        dw      1100001100000000b                                           
        dw      0110011000000000b                                      
        dw      0110011000000000b                                     
        dw      0011110000000000b                                           
        dw      0011110000000000b                                     
        dw      0001100000000000b                                       
        dw      0001100000000000b                                     
        dw      0011000000000000b                                      
        dw      0110000000000000b                                  
        dw      0000000000000000b                                    
        dw      0000000000000000b                                         
        dw      0000000000000000b                                  

; 7AH: 'z'

        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      1111110000000000b
        dw      0000110000000000b
        dw      0001100000000000b
        dw      0011000000000000b
        dw      0110000000000000b
        dw      1100000000000000b
        dw      1111110000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b
        dw      0000000000000000b

; 7BH: '{'

        dw      0011000000000000b                                    
        dw      0110000000000000b                                     
        dw      0110000000000000b                                  
        dw      0110000000000000b                                      
        dw      0110000000000000b                                         
        dw      0110000000000000b                                    
        dw      1100000000000000b                                   
        dw      0110000000000000b                                         
        dw      0110000000000000b                                   
        dw      0110000000000000b                                     
        dw      0110000000000000b                                   
        dw      0110000000000000b                                    
        dw      0011000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 7CH: '|'

        dw      1100000000000000b                                    
        dw      1100000000000000b                                     
        dw      1100000000000000b                                  
        dw      1100000000000000b                                      
        dw      1100000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      1100000000000000b                                   
        dw      1100000000000000b                                     
        dw      1100000000000000b                                   
        dw      1100000000000000b                                    
        dw      1100000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 7DH: '}'

        dw      1100000000000000b                                    
        dw      0110000000000000b                                     
        dw      0110000000000000b                                  
        dw      0110000000000000b                                      
        dw      0110000000000000b                                         
        dw      0110000000000000b                                    
        dw      0011000000000000b                                   
        dw      0110000000000000b                                         
        dw      0110000000000000b                                   
        dw      0110000000000000b                                     
        dw      0110000000000000b                                   
        dw      0110000000000000b                                    
        dw      1100000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 7EH: '~'

        dw      1110100000000000b                                    
        dw      1011100000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b
        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                

; 7FH: DEL

        dw      0000000000000000b                                  
        dw      0000000000000000b                                       
        dw      0000000000000000b                                
        dw      0000000000000000b                                    
        dw      0000000000000000b                                     
        dw      0000000000000000b                                  
        dw      0000000000000000b                                      
        dw      0000000000000000b                                         
        dw      0000000000000000b                                    
        dw      0000000000000000b                                   
        dw      0000000000000000b                                         
        dw      0000000000000000b                                   
        dw      0000000000000000b                                     
        dw      0000000000000000b                                   
        dw      0000000000000000b                                    
        dw      0000000000000000b

        end

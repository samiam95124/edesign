        TITLE   'drawing primitive routines'
        name    draw
        page    55,132

        .386
        .model  small, c

vidbuf  equ     0a0000h         ; address of video buffer
bytoff  equ     3               ; used to convert pixels to bute offset
rmwbit  equ     0               ; value for data rotate/func select reg
bytshf  equ     3               ; used to convert pixels to bute offset

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

        public  varseg

        extern  syscall pixadd:near ; calculate pixel address  
        extern  segvid:dword    ; change video segment (vector)  
        extern  linbyt:dword    ; number of bytes in line
        extern  linep:dword     ; line draw vector
        extern  linesp:dword    ; line draw with save vector
        extern  linerp:dword    ; line restore vector
        extern  blockp:dword    ; block draw vector
        .code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; CLIP LINE                                                   ;
;                                                             ;
; Clips the line with the points:                             ;
;                                                             ;
;    eax: x1                                                  ;
;    ebx: x2                                                  ;
;    ecx: x3                                                  ;
;    edx: x4                                                  ;
;                                                             ;
; Expects the viewport at [edi].                              ;
; If the line is entirely clipped out, carry is returned set. ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


clipline proc   syscall
        push    ebp             ; save registers
        mov     ebp,eax         ; save x1
        mov     esi,ebx         ; save y1
        cmp     esi,edx         ; check line horizontal
        jz      clipline18      ; yes, go
        cmp     ebp,ecx         ; check line vertical
        jz      clipline21      ; yes, go
        mov     bx,0            ; clear compare codes
        cmp     ebp,[edi+viewcsx] ; set compare codes for start
        jnl     clipline01      
        or      bl,0001b
clipline01:
        cmp     esi,[edi+viewcsy]
        jnl     clipline02
        or      bl,0010b
clipline02:
        cmp     ebp,[edi+viewcex]
        jng     clipline03
        or      bl,0100b
clipline03:
        cmp     esi,[edi+viewcey]
        jng     clipline04
        or      bl,1000b
clipline04:
        cmp     ecx,[edi+viewcsx] ; set compare codes for end
        jnl     clipline05      
        or      bh,0001b
clipline05:
        cmp     edx,[edi+viewcsy]
        jnl     clipline06
        or      bh,0010b
clipline06:
        cmp     ecx,[edi+viewcex]
        jng     clipline07
        or      bh,0100b
clipline07:
        cmp     edx,[edi+viewcey]
        jng     clipline08
        or      bh,1000b
clipline08:
        mov     al,bl           ; check inside status
        or      al,bh
        jz      clipline25      ; yes, exit good
        mov     al,bl           ; check outside status
        and     al,bh
        jnz     clipline24      ; yes, exit clipped out
        or      bl,bl           ; check 1st point inside
        jnz     clipline09      ; no, skip
        xchg    bh,bl           ; yes, swap endpoints
        xchg    ebp,ecx
        xchg    esi,edx

; clip left

clipline09:
        shr     bl,1            ; check clip left
        jnc     clipline10      ; no, skip
        push    ebx             ; save compare codes
        push    edx             ; save y2
        mov     eax,edx         ; find y2-y1
        sub     eax,esi
        mov     ebx,[edi+viewcsx] ; find clip(xs)-x1
        sub     ebx,ebp
        imul    ebx             ; multiply
        mov     ebx,ecx         ; find x2-x1
        sub     ebx,ebp 
        idiv    ebx             ; divide
        pop     edx             ; restore y2
        pop     ebx             ; restore compare codes
        add     esi,eax         ; add to y1
        mov     ebp,[edi+viewcsx] ; set x1 := clip(xs)
        jmp     clipline13      ; go next compare

; clip above 

clipline10:
        shr     bl,1            ; check clip above
        jnc     clipline11      ; no, skip
        push    ebx             ; save compare codes
        push    edx             ; save y2
        mov     eax,ecx         ; find x2-x1
        sub     eax,ebp
        mov     ebx,edx         ; find y2-y1
        sub     ebx,esi 
        push    ebx             ; save
        mov     ebx,[edi+viewcsy] ; find clip(ys)-y1
        sub     ebx,esi
        imul    ebx             ; multiply
        pop     ebx             ; restore y2-y1
        idiv    ebx             ; divide
        pop     edx             ; restore y2
        pop     ebx             ; restore compare codes
        add     ebp,eax         ; add to x1
        mov     esi,[edi+viewcsy] ; set y1 := clip(ys)
        jmp     clipline13      ; go next compare

; clip right

clipline11:
        shr     bl,1            ; check clip right
        jnc     clipline12      ; no, skip
        push    ebx             ; save compare codes
        push    edx             ; save y2
        mov     eax,edx         ; find y2-y1
        sub     eax,esi
        mov     ebx,[edi+viewcex] ; find clip(xe)-x1
        sub     ebx,ebp
        imul    ebx             ; multiply
        mov     ebx,ecx         ; find x2-x1
        sub     ebx,ebp 
        idiv    ebx             ; divide
        pop     edx             ; restore y2
        pop     ebx             ; restore compare codes
        add     esi,eax         ; add to y1
        mov     ebp,[edi+viewcex] ; set x1 := clip(xe)
        jmp     clipline13      ; go next compare

; clip below

clipline12:
        shr     bl,1            ; check clip below
        jnc     clipline13      ; no, skip
        push    ebx             ; save compare codes
        push    edx             ; save y2
        mov     eax,ecx         ; find x2-x1
        sub     eax,ebp
        mov     ebx,edx         ; find y2-y1
        sub     ebx,esi 
        push    ebx             ; save
        mov     ebx,[edi+viewcey] ; find clip(ye)-y1
        sub     ebx,esi
        imul    ebx             ; multiply
        pop     ebx             ; restore y2-y1
        idiv    ebx             ; divide
        pop     edx             ; restore y2
        pop     ebx             ; restore compare codes
        add     ebp,eax         ; add to x1
        mov     esi,[edi+viewcey] ; set x1 := clip(xe)
clipline13:        
        mov     bl,0            ; set compare codes for start
        cmp     ebp,[edi+viewcsx]
        jnl     clipline14      
        or      bl,0001b
clipline14:
        cmp     esi,[edi+viewcsy]
        jnl     clipline15
        or      bl,0010b
clipline15:
        cmp     ebp,[edi+viewcex]
        jng     clipline16
        or      bl,0100b
clipline16:
        cmp     esi,[edi+viewcey]
        jng     clipline08      ; loop next compare
        or      bl,1000b
        jmp     clipline08      ; loop next compare

; clip horizontal line

clipline18:
        cmp     esi,[edi+viewcsy] ; check y < clip(ys)
        jl      clipline24      ; yes, exit clipped out
        cmp     esi,[edi+viewcey] ; check y > clip(ye)
        jg      clipline24      ; yes, exit clipped out
        cmp     ebp,ecx         ; check x1 > x2
        jng     clipline19      ; no, skip
        xchg    ebp,ecx         ; trade
clipline19:
        cmp     ebp,[edi+viewcex] ; check x1 > clip(xe)
        jg      clipline24      ; yes, exit clipped out
        cmp     ecx,[edi+viewcsx] ; check x2 < clip(xs)
        jl      clipline24      ; yes, exit clipped out
        cmp     ecx,[edi+viewcex] ; check x2 > clip(xe)
        jng     clipline20      ; no, skip
        mov     ecx,[edi+viewcex] ; clip right
clipline20:
        cmp     ebp,[edi+viewcsx] ; check x1 < clip(xs)
        jnl     clipline25      ; no, exit
        mov     ebp,[edi+viewcsx] ; clip left 
        jmp     clipline25      ; exit
        
; clip vertical line

clipline21:
        cmp     ebp,[edi+viewcsx] ; check x < clip(xs)
        jl      clipline24      ; yes, exit clipped out
        cmp     ebp,[edi+viewcex] ; check x > clip(xe)
        jg      clipline24      ; yes, exit clipped out
        cmp     esi,edx         ; check y1 > y2
        jng     clipline22      ; no, skip
        xchg    esi,edx         ; trade
clipline22:
        cmp     esi,[edi+viewcey] ; check y1 > clip(ye)
        jg      clipline24      ; yes, exit clipped out
        cmp     edx,[edi+viewcsy] ; check y2 < clip(ys)
        jl      clipline24      ; yes, exit clipped out
        cmp     edx,[edi+viewcey] ; check y2 > clip(ye)
        jng     clipline23      ; no, skip
        mov     edx,[edi+viewcey] ; clip right
clipline23:
        cmp     esi,[edi+viewcsy] ; check y1 < clip(ys)
        jnl     clipline25      ; no, exit
        mov     esi,[edi+viewcsy] ; clip left 
        jmp     clipline25      ; exit
        
clipline24:
        stc                     ; set line clipped out
        jmp     clipline26      ; exit
clipline25:
        clc                     ; set line not clipped out
clipline26:
        mov     ebx,esi         ; restore y1
        mov     eax,ebp         ; restore x1
        pop     ebp             ; clean up and return
        ret
clipline endp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW LINE                                                   ;
;                                                             ;
; Draws a line between the start and end points.              ;
;                                                             ;
; procedure line(var vp:         viewport; { viewport }       ;
;                x1, y1, x2, y2: integer;  { line start and   ;
;                                            end }            ;
;                c:              color);   { color }          ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vp      =       8               ; pointer to viewport record
x1      =       12
y1      =       16
x2      =       20
y2      =       24
clr     =       28

line    proc    syscall
        jmp     [linep]         ; goto proper routine
line    endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; LINE DRAW PLANAR                                            ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

linepl  proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers
        push    esi
        push    edi        
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place paramters
        pop     ecx
        pop     ebx
        pop     eax
        call    clipline        ; clip the line eax,ebx-ecx,edx
        jc      endline         ; exit if line clipped out
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx


; Compute address of first pixel, select color

        mov     eax,[ebp+y1]    ; get y
        mul     [linbyt]        ; find lines offset
        mov     ebx,[ebp+x1]    ; get x
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        mov     [varseg],ah     ; and save
        call    [segvid]        ; select segment
        push    ebx             ; save video address
	mov	ecx,[ebp+x1]	; Fetch x1
	and	cl,7		; Get bit position within first byte
	mov	bl,80h		; Assume first bit
	shr	bl,cl		; Rotate mask bit into place
	mov	[fstmsk],bl	; Save mask

; Load set/reset registers with current color, select bit mask reg

	mov	al,[ebp+clr]    ; get color
	mov	dx,03ceh	; Use color for set/reset value
	mov	ah,al
	mov	al,0
	out	dx,ax
	mov	ax,00F01h	; Enable set/reset
	out	dx,ax
	mov	ax,0FF08h	; Set bit mask to FFh
	out	dx,ax
	mov	ax,00007h       ; Set color don't care to 00h
	out	dx,ax
	mov	al,5		; Index of mode reg
	out	dx,al		; Select mode reg
	inc	dx
	in	al,dx		; Read previous value
	or	al,0bh		; Enable color compare, write mode 3
	out	dx,al

; Compute dx and dy and determine which coordinate is major

	mov	eax,[linbyt]    ; Set raster increment
	mov	[pitch],ax
	mov	esi,[ebp+x2]	; Compute dx (X1-X0) in SI
	sub	esi,[ebp+x1]
	mov	[deltax],esi	; Save in local variable
	jge	dxpos		; If dx is negative, make it positive
	neg	esi
dxpos:
	mov	edi,[ebp+y2]	; Compute dy (Y1-Y0) in DI
	sub	edi,[ebp+y1]
	jge	dypos		; If dy is negative, make it positive
	neg	[pitch]		; Also, invert the pitch
	neg	edi
dypos:

; Figure out which coordinate is the major one

	or	esi,esi		; Check for vertical line
	je	vertical
	or	edi,edi		; Check for horizontal line
	je	horizontal
	cmp	esi,edi		; Check that dx > dy
	jl	ymajorjump
	jmp	xmajor
ymajorjump:
	jmp	ymajor

; Vertical Line

vertical:
	mov    	ecx,edi		; Set up counter
	inc	ecx		; Number of pixels is one greater
	pop	edi		; Fetch offset
	mov	bx,[pitch]	; Fetch pitch
	or	bx,bx		; Check for y decreasing
	jns	vertset         ; go

; Y1 < Y0, but we want to draw down only, so compute address of
; (X1,Y1) and start from there

	neg	bx
	xchg	esi,ecx		; Preserve counter
	mov	eax,[ebp+y2]	; Fetch y coordinate
	mul	[linbyt]        ; multiply by raster width
	mov	ecx,[ebp+x2]	; add x coordinate/8
	shr	ecx,3           ; convert to byte offset
	add	eax,ecx         ; offset
        movzx   ecx,ax          ; set up offset
        add     ecx,vidbuf      ; offset to video buffer
        mov     edi,ecx         ; save
        shr     eax,8           ; place 64kb offset in ah
	mov	[varseg],ah	; Save page number for later
	call	[segvid]
	xchg	esi,ecx		; Restore counter
	mov	al,[fstmsk]	; Fetch mask
vertset:
        mov     esi,ecx         ; save total count
vertpag:
        mov     ax,65535        ; find left in page
        mov     dx,0
        sub     ax,di
        div     bx              ; find number of lines
        inc     ax              ; adjust
        cmp     si,ax           ; check remainder < lines
        jc      vertend         ; yes, go
        sub     si,ax           ; find new total
        mov     cx,ax           ; place subtotal
	mov	al,[fstmsk]	; Fetch mask
vertloop:
	and	[edi],al	; Latch data, then set to new value
	add	di,bx		; Update offset
	loopw	vertloop
	mov	ah,[varseg]	; fetch page number
	inc	ah		; Advance page number
	call	[segvid]
	mov	[varseg],ah	; save page number
        or      si,si           ; check end of all
        jnz     vertpag         ; go next page if not
        jmp     endline         ; exit
vertend:
        mov     cx,si           ; place count
	mov	al,[fstmsk]	; Fetch mask
vertendl: 
	and	[edi],al	; Latch data, then set to new value
	add	di,bx		; Update offset
	loopw	vertendl
        jmp     endline         ; exit
        
; Horizontal line

horizontal:
	pop	edi		; Fetch offset

; Draw pixels from the leading partial byte

	mov	eax,[ebp+x1]	; Fetch x coordinate (assume x1 > x0)
	cmp	[deltax],0	; Is x1 > x0?
	jns	HorzInOrder

; X1 < X0, but we want to draw right only, so compute address of
; (X1,Y1) and start from there

	mov	eax,[ebp+y2]	; Fetch y coordinate
	mul	[linbyt]        ; multiply by raster width
	mov	ecx,[ebp+x2]	; add x coordinate/8
	shr	ecx,3           ; convert to byte offset
	add	eax,ecx         ; offset
        movzx   ecx,ax          ; set up offset
        add     ecx,vidbuf      ; offset to video buffer
        mov     edi,ecx         ; save
        shr     eax,8           ; place 64kb offset in ah
	mov	[varseg],ah	; Save page number for later
	call	[segvid]

	mov	edx,03cfh       ; Put gr ctrl data register in DX
	mov	eax,[ebp+x2]

horzinorder:
	mov	ecx,esi		; Set counter of pixels
	inc	ecx
	and	eax,7		; Check for partial byte
	jz	horzfull
	mov	bl,0ffh 	; Compute the mask
	xchg	bh,cl		; Preserve counter (CL into BH)
	mov	cl,al
	shr	bl,cl
	xchg	bh,cl		; Restore counter
	add	ecx,eax   	; Update counter
	sub	ecx,8
	jge	maskset	        ; Modify mask if only one byte
	neg	ecx
	shr	bl,cl
	shl	bl,cl
	xor	ecx,ecx		; Set bit count to zero
maskset:
	mov	al,bl		; Fetch mask
	and	[edi],al	; Latch data, write new data
	inc	di		; Advance to next byte

; Draw the middle complete bytes

horzfull:
	mov	ebx,ecx		; Check if any bytes to set
	cmp	ebx,8
	jl	horztrailing
	shr	ecx,3		; Compute count
        mov     edx,ecx         ; save
horzfull01:
        mov     cx,65535        ; find bytes left in page
        sub     cx,di
        movzx   ecx,cx          ; expand
        inc     ecx             ; adjust
        cmp     edx,ecx         ; check rem < left
        jle     horzfull02      ; yes, go
        sub     edx,ecx         ; find new total
	mov	ah,[edi]	; 'Prime' latch with FFh
	mov	eax,0ffffffffh 	; Set CPU mask
        cmp     ecx,4           ; check >= 4 bytes to make dwords
        jc      horzfull03      ; no, skip
        push    ecx             ; save count
        shr     ecx,2           ; find dword count
        rep     stosd           ; place
        pop     ecx             ; restore count
        and     ecx,3           ; mask for remainder
horzfull03:
	rep	stosb		; Fill bytes
        movzx   edi,di          ; clear overflow
        add     edi,vidbuf
	mov	ah,[varseg]	; fetch page number
	inc	ah		; Advance page number
	call	[segvid]
	mov	[varseg],ah	; save page number
        or      edx,edx         ; check end
        jnz     horzfull01      ; no, loop
        jmp     horztrailing    ; go
horzfull02:
        mov     ecx,edx         ; set remainder as count
	mov	ah,[edi]	; 'Prime' latch with FFh
	mov	eax,0ffffffffh 	; Set CPU mask
        cmp     ecx,4           ; check >= 4 bytes to make dwords
        jc      horzfull04      ; no, skip
        push    ecx             ; save count
        shr     ecx,2           ; find dword count
        rep     stosd           ; place
        pop     ecx             ; restore count
        and     ecx,3           ; mask for remainder
horzfull04:
	rep	stosb		; Fill bytes
        movzx   edi,di          ; clear overflow
        add     edi,vidbuf

; Draw the trailing partial byte

horztrailing:
	and	bl,7
	jz	horzdone
	mov	al,0ffh 	; Compute mask
	mov	ecx,ebx
	shr	al,cl
	not	al
	and	[edi],al	; Latch data, write new data

horzdone:
	jmp	endline

; Diagonal line for x-major

; Compute constants for x-major

xmajor:
	mov	ecx,esi		; Set counter to dx+1
	inc	ecx
	sal	edi,1		; D1 = dy*2
	mov	ebx,edi		; D  = dy*2-dx
	sub	ebx,esi
	neg	esi		; D2 = dy*2-dx-dx
	add	esi,ebx
	mov	[d1],edi	; Save d1
	mov	[d2],esi	; Save d2
	pop	edi		; Restore offset of first pixel
	mov	al,[fstmsk]	; Fetch the initial mask
	mov	ah,[edi]	; Load initial latches
	xor	esi,esi		; Keep 0 in SI

; Jump according to sign of dx and dy

	or	[pitch],si	; Check if dy is positive
	jns	xmypos
	neg	[pitch]		; Restore pitch
	or	[deltax],esi
	js	xnynjump
	jmp	xpyn		; Go do dy negative dx positive
xnynjump:
	jmp	xnyn		; Go do both dy and dx negative

xmypos:
	or	[deltax],esi	; Check if dx also positive
	jns	xpyp		; Jump if both dx and dy are positive
	jmp	xnyp		; Jump if dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and x major

xpyp:
	xor	dl,dl		; Clear mask accumulator
        mov     ah,[varseg]     ; get segment
xpypnext:			; Loop over pixels to be set
	or	dl,al		; Add next bit into mask accumulator
	ror	al,1		; Update mask
	jnc	xpypskip	; Skip update if not in next byte
	and	[edi],dl 	; Load latches, change pixels, in last
	add	di,1		; Advance to the next byte
        jnc     xpypskip2       ; no overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpypskip2:
	xor	dl,dl		; Reset mask accumulator
xpypskip:
	or	ebx,ebx		; If d >= 0 then ...
	js	xpypdneg
	and	[edi],dl 	; Set previous scanline pixels
	xor	dl,dl		; Reset mask accumulator
	add	ebx,[d2]	; ... d = d + d2
	add	di,[pitch]	; Update offset
	jnc	xpypskip1       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpypskip1:
	loop	xpypnext
	jmp	endline
xpypdneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xpypnext
	and	[edi],dl 	; Set (possible) last partial byte
	jmp	endline

; Draw line where DX < 0 and DY > 0 and X major

xnyp:
        mov     ah,[varseg]     ; get segment
xnypnext:			; Loop over pixels to be set
	and	[edi],al 	; Latch data, then set to new value
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     xnypskip1       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnypskip1:
	or	ebx,ebx		; If d >= 0 then ...
	js	xnypdneg
	add	ebx,[d2]	; ... d = d + d2
	add	di,[pitch]	; Update offset
        jnc     xnypskip        ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xnypskip:
	loop	xnypnext
	jmp	endline
xnypdneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xnypnext
	jmp	endline

; Draw line where DX > 0 and DY < 0 and x major

xpyn:
        mov     ah,[varseg]     ; get segment
xpynnext:			; Loop over pixels to be set
	and	[edi],al 	; Latch data, then set to new value
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     xpynskip1       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpynskip1:
	or	ebx,ebx		; If d >= 0 then ...
	js	xpyndneg
	add	ebx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; Update offset
        jnc     xpynskip        ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xpynskip:
	loop	xpynnext
	jmp	endline
xpyndneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xpynnext
	jmp	endline

; Draw line where DX < 0 and DY < 0 and x major

xnyn:
        mov     ah,[varseg]     ; get segment
xnynnext:			; Loop over pixels to be set
	and	[edi],al 	; Latch data, then set to new value
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     xnynskip1       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnynskip1:        
	or	ebx,ebx		; If d >= 0 then ...
	js	xnyndneg
	add	ebx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; Update offset
        jnc     xnynskip        ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnynskip:
	loop	xnynnext
	jmp	endline
xnyndneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xnynnext
	jmp	endline

; Diagonal line for y-major

; Compute constants for dx < dy

ymajor:
	mov	ecx,edi		; Set counter to dy+1
	inc	ecx
	sal	esi,1		; D1 = dx * 2
	mov	ebx,esi		; D  = dx * 2 - dy
	sub	ebx,edi
	neg	edi		; D2 = -dy + dx * 2 - dy
	add	edi,ebx
	mov	[d2],edi	; Save d2
	mov	[d1],esi	; Save d1
	pop	edi		; Restore address of first pixel
	mov	al,[fstmsk]	; Fetch mask
	xor	esi,esi		; Keep 0 in SI

; Jump according to sign of dx and dy
  
	or	[pitch],si	; Check if dy is positive
	jns	ymypos
	neg	[pitch]
	or	[deltax],esi
	js	nxnyjump
	jmp	pxny		; Go do dy negative dx positive
nxnyjump:
	jmp	nxny		; Go do both dy and dx negative

ymypos:
	or	[deltax],esi	; Check if dx also positive
	jns	pxpy		; Jump if both dx and dy are positive
	jmp	nxpy		; Jump if dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and y major
  
pxpy:
        mov     ah,[varseg]     ; get segment
pxpynext:
	and	[edi],al 	; Latch data, then set to new value
	add	di,[pitch]	; Update offset
        jnc     pxpyskip        ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxpyskip:
	or	ebx,ebx		; If d >= 0 then ...
	js	pxpydneg
	add	ebx,[d2]	; ... d = d + d2
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     pxpyskip1       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxpyskip1:
	loop	pxpynext
	jmp	endline
pxpydneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	pxpynext
	jmp	endline

; Draw line where DX < 0 and DY > 0 and y major
  
nxpy:
        mov     ah,[varseg]     ; get segment
nxpynext:
	and	[edi],al 	; Latch data, then set to new value
	add	di,[pitch]	; Update offset
        jnc     nxpyskip        ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
nxpyskip:
	or	ebx,ebx		; If d >= 0 then ...
	js	nxpydneg
	add	ebx,[d2]	; ... d = d + d2
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     nxpyskip1       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxpyskip1:
	loop	nxpynext
	jmp	endline
nxpydneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	nxpynext
	jmp	endline

; Draw line where DX > 0 and DY < 0 and y major
  
pxny:
        mov     ah,[varseg]     ; get segment
pxnynext:
	and	[edi],al 	; Latch data, then set to new value
	sub	di,[pitch]	; Update offset
        jnc     pxnyskip        ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
pxnyskip:
	or	ebx,ebx		; If d >= 0 then ...
	js	pxnydneg
	add	ebx,[d2]	; ... d = d + d2
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     pxnyskip1       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxnyskip1:
	loop	pxnynext
	jmp	endline
pxnydneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	pxnynext
	jmp	endline

; Draw line where DX < 0 and DY < 0 and y major
  
nxny:
        mov     ah,[varseg]     ; get segment
nxnynext:
	and	[edi],al 	; Latch data, then set to new value
	sub	di,[pitch]	; Update offset
        jnc     nxnyskip        ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxnyskip:
	or	ebx,ebx		; If d >= 0 then ...
	js	nxnydneg
	add	ebx,[d2]	; ... d = d + d2
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     nxnyskip1       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxnyskip1:
	loop	nxnynext
	jmp	endline
nxnydneg:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	nxnynext
	jmp	endline

; exit

endline:
        mov     dx,03ceh        ; reset mode register
        mov     ax,00005h       
        out     dx,ax
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
linepl  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; LINE DRAW PACKED                                            ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

linepk  proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers
        push    esi
        push    edi        
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place paramters
        pop     ecx
        pop     ebx
        pop     eax
        call    clipline        ; clip the line eax,ebx-ecx,edx
        jc      linedone        ; exit if line clipped out
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; Convert (x,y) starting point to video address and select page

	mov	eax,[ebp+y1]	; Convert (x,y) to address
	mul	word ptr [linbyt] ; multiply y by pitch
	mov	ecx,[ebp+x1]	; fetch x
	shr	ecx,1		; convert pixel to byte number
	add	eax,ecx		; add to previous product
        add     eax,vidbuf      ; offset by video base
	push	eax		; Save address on stack for later
	mov	ah,dl		; Copy page number into ah
	mov	[varseg],Ah	; Save page number
	call	[segvid]	; Select proper page
	mov	bx,00ff0h	; Set initial mask (assume x even)
				; bl=src mask, bh=dst mask
	mov	eax,[ebp+x1]	; Move bit0 of x into sign bit
	ror	ax,1
	cwd			; Set dx to ffff if x is odd
	xor	bx,dx		; Invert masks if x was odd
	mov	al,[ebp+clr]	; Duplicate color into high nibble
	and	al,0fh
	shl	al,4
	or	[ebp+clr],al

; Compute dx and dy and determine which coordinate is major

	mov	eax,[linbyt]    ; set raster increment
	mov     [pitch],ax
	mov	esi,[ebp+x2]	; compute dx reg-si
	sub	esi,[ebp+x1]
	mov	deltax,esi
	jge	dxispos
	neg	esi
dxispos:
	mov	edi,[ebp+y2]	; compute dy reg-di
	sub	edi,[ebp+y1]
	jge	dyispos
	neg	[pitch]
	neg	edi
dyispos:

; Determine which coordinate is the major one

	cmp	esi,edi		; check that dx > dy
	jge	xmajor
	jmp	ymajor

; Compute constants for x-major

xmajor:
	mov	ecx,esi		; set counter to dx+1
	inc	ecx
	sal	edi,1		; d1 = dy*2
	mov	edx,edi		; d  = dy*2-dx
	sub    	edx,esi
	neg	esi		; d2 = dy*2-dx-dx
	add	esi,edx
	mov	[d1],edi	; save d1
	mov	[d2],esi	; save d2
	pop	edi		; restore offset of first pixel

; Jump according to sign of dx and dy

	test	[pitch],08000h  ; Check if dy is positive
	jz	yp
	neg	[pitch]         ; Restore pitch
	test	[deltax],08000h
	jnz	xnyn
	jmp	xpyn 	        ; go do dy negative dx positive
yp:
	test	[deltax],08000h ; ...no, check if dx also positive
	jnz	xnyp 	        ; ...dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and x is the major coordinate

xpyp:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next0:		        	; Loop over pixels to be set
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	page0	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	page0
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]  	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page0:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dneg0
	add	edx,[d2]   	; ... d = d + d2
	add	di,[pitch]	; update offset
	jnc	fix00
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fix00           ; go
dneg0:
	add	edx,[d1]	; if d < 0 then d = d + d1
fix00:
	loop	next0
	jmp	linedone

; Draw line where DX < 0 and DY > 0 and X major

xnyp:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next3:			        ; Loop over pixels to be set
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	page3	        ; if upper nibble set skip update
	sub	di,1		; else must point to next byte
	jnc	page3
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page3:
	test	edx,8000h	; if d >= 0 then ...
	jnz     dneg3
	add	edx,[d2]        ; ... d = d + d2
	add	di,[pitch]	; update offset
	jnc	fix33
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fix33           ; go
dneg3:
	add	edx,[d1]	; if d < 0 then d = d + d1
fix33:
	loop	next3
	jmp	linedone

; Draw line where DX > 0 and DY < 0 and x major

xpyn:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next7:			        ; Loop over pixels to be set
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	page7	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	page7
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page7:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dneg7
	add     edx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; update offset
	jnc	fix77
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fix77           ; go
dneg7:
	add	edx,[d1]	; if d < 0 then d = d + d1
fix77:
	loop	next7
	jmp	linedone

; Draw line where DX < 0 and DY < 0 and x major

xnyn:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next4:			        ; Loop over pixels to be set
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	page4	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc     page4
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page4:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dneg4
	add	edx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; update offset
	jnc	fix44
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fix44           ; go
dneg4:
	add	edx,[d1]	; if d < 0 then d = d + d1
fix44:
	loop	next4
	jmp	linedone

; Compute constants for dx < dy

ymajor:
	mov	ecx,edi		; set counter to dy+1
	inc	ecx
	sal	esi,1		; d1 = dx * 2
	mov	edx,esi		; d  = dx * 2 - dy
	sub	edx,edi
	neg	edi		; d2 = -dy + dx * 2 - dy
	add	edi,edx
	mov	[d2],edi 	; save d2
	mov	[d1],esi 	; save d1
	pop	edi		; Restore address of first pixel

; Jump according to sign of dx and dy

	test	[pitch],08000h ; Check if dy is positive
	jz	py
	neg	[pitch]
	test	[deltax],08000h
	jnz	nxny
	jmp	pxny 	        ; go do dy negative dx positive
py:
	test	[deltax],08000h ; ...no, check if dx also positive
	jnz	nxpy 	        ; ...dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and y major

pxpy:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next1:
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	add	di,[pitch]	; update offset
	jnc	page1
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page1:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dneg1
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	loop1   	; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	loop1
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loop1           ; go
dneg1:
	add	edx,[d1]	; if d < 0 then d = d + d1
loop1:
	loop	next1
	jmp	linedone

; Draw line where DX < 0 and DY > 0 and y major

nxpy:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next2:
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	add	di,[pitch]	; update offset
	jnc	page2
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page2:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dneg2
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	loop2	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc	loop2
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loop2           ; go
dneg2:
	add	edx,[d1]	; if d < 0 then d = d + d1
loop2:
	loop	next2
	jmp	linedone

; Draw line where DX > 0 and DY < 0 and y major

pxny:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next6:
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	sub	di,[pitch]	; update offset
	jnc	page6
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page6:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dneg6
        add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	loop6	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	loop6
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loop6           ; go
dneg6:
	add	edx,[d1]	; if d < 0 then d = d + d1
loop6:
	loop	next6
	jmp	linedone

; Draw line where DX < 0 and DY < 0 and y major

nxny:
	mov	ah,[ebp+clr]	; Fetch color of the pixel
next5:
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	sub	di,[pitch]	; update offset
	jnc	page5
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
page5:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dneg5
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	loop5	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc	loop5
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
        dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loop5           ; go
dneg5:
	add	edx,[d1]	; if d < 0 then d = d + d1
loop5:
	loop	next5
	jmp	linedone

; Clean up and return to caller

linedone:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
linepk  endp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW LINE WITH SAVE                                         ;
;                                                             ;
; Draws a line between the start and end points. Saves the    ;
; pixels under the line to the given buffer.                  ;
;                                                             ;
; procedure linesav(x1, y1, x2, y2: integer; c: color;        ;
;                   var lines: linarr; var i: lininx)         ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


vp      =       8               ; pointer to viewport record
x1      =       12
y1      =       16
x2      =       20
y2      =       24
clr     =       28
lines   =       30
i       =       34

linesav proc    syscall
        jmp     [linesp]        ; goto proper routine
linesav endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; LINE DRAW WITH SAVE PLANAR                                  ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Routine to load a the current pixel to the save buffer
; Expects: al  = bit mask
;          edi = video address

plcpix  proc    syscall
        push    ax              ; save
        push    ebx
        push    cx
        push    dx
	mov	dx,03ceh	; Use color for set/reset value
        mov     ch,al           ; place bit mask
        mov     ax,00005h       ; reset mode
        out     dx,ax
        xor     bl,bl           ; clear bit accumulator 
        mov     ax,304h         ; ah := initial bit plane number
                                ; al := read map select register number
plcp01: out     dx,ax           ; select bit plane
        mov     bh,[edi]        ; get byte from current bit plane
        and     bh,ch           ; mask the bit
        neg     bh              ; move that bit to 7
        rol     bx,1            ; and accumulate in bl
        dec     ah              ; set next bit plane number
        jge     plcp01          ; loop next bit
        mov     al,bl           ; place result
        mov     ebx,[pixarr]    ; get target address
        mov     [ebx],al        ; place bit value
        inc     ebx             ; next location
        mov     [pixarr],ebx    ; replace
        mov     ax,00b05h       ; reset mode
        out     dx,ax
        pop     dx              ; restore
        pop     cx
        pop     ebx
        pop     ax
        ret
plcpix  endp  

linespl proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        push    esi
        push    edi
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place paramters
        pop     ecx
        pop     ebx
        pop     eax
        call    clipline        ; clip the line eax,ebx-ecx,edx
        jc      endlines        ; exit if line clipped out
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; offset to index

        mov     ebx,[ebp+i]     ; get index
        movzx   eax,word ptr [ebx]
        dec     eax             ; adjust to 0
        add     eax,[ebp+lines] ; offset array
        mov     [pixarr],eax    ; save

; Compute address of first pixel, select color

        mov     eax,[ebp+y1]    ; get y
        mul     [linbyt]        ; find lines offset
        mov     ebx,[ebp+x1]    ; get x
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        mov     [varseg],ah     ; and save
        call    [segvid]        ; select segment
        push    ebx             ; save video address
	mov	ecx,[ebp+x1]	; Fetch x1
	and	cl,7		; Get bit position within first byte
	mov	bl,80h		; Assume first bit
	shr	bl,cl		; Rotate mask bit into place
	mov	[fstmsk],bl	; Save mask

; Load set/reset registers with current color, select bit mask reg

	mov	al,[ebp+clr]    ; get color
	mov	dx,03ceh	; Use color for set/reset value
	mov	ah,al
	mov	al,0
	out	dx,ax
	mov	ax,00F01h	; Enable set/reset
	out	dx,ax
	mov	ax,0FF08h	; Set bit mask to FFh
	out	dx,ax
	mov	ax,00007h       ; Set color don't care to 00h
	out	dx,ax
	mov	al,5		; Index of mode reg
	out	dx,al		; Select mode reg
	inc	dx
	in	al,dx		; Read previous value
	or	al,0bh		; Enable color compare, write mode 3
	out	dx,al

; Compute dx and dy and determine which coordinate is major

	mov	eax,[linbyt]    ; Set raster increment
	mov	[pitch],ax
	mov	esi,[ebp+x2]	; Compute dx (X1-X0) in SI
	sub	esi,[ebp+x1]
	mov	[deltax],esi	; Save in local variable
	jge	dxposs		; If dx is negative, make it positive
	neg	esi
dxposs:
	mov	edi,[ebp+y2]	; Compute dy (Y1-Y0) in DI
	sub	edi,[ebp+y1]
	jge	dyposs		; If dy is negative, make it positive
	neg	[pitch]		; Also, invert the pitch
	neg	edi
dyposs:

; Figure out which coordinate is the major one

	or	esi,esi		; Check for vertical line
	je	verticals
	or	edi,edi		; Check for horizontal line
	je	horizontals
	cmp	esi,edi		; Check that dx > dy
	jl	ymajorjumps
	jmp	xmajors
ymajorjumps:
	jmp	ymajors

; Vertical Line

verticals:
	mov    	ecx,edi		; Set up counter
	inc	ecx		; Number of pixels is one greater
	pop	edi		; Fetch offset
	mov	bx,[pitch]	; Fetch pitch
	or	bx,bx		; Check for y decreasing
	jns	vertsets        ; go

; Y1 < Y0, but we want to draw down only, so compute address of
; (X1,Y1) and start from there

	neg	bx
	xchg	esi,ecx		; Preserve counter
	mov	eax,[ebp+y2]	; Fetch y coordinate
	mul	[linbyt]        ; multiply by raster width
	mov	ecx,[ebp+x2]	; add x coordinate/8
	shr	ecx,3           ; convert to byte offset
	add	eax,ecx         ; offset
        movzx   ecx,ax          ; set up offset
        add     ecx,vidbuf      ; offset to video buffer
        mov     edi,ecx         ; save
        shr     eax,8           ; place 64kb offset in ah
	mov	[varseg],ah	; Save page number for later
	call	[segvid]
	xchg	esi,ecx		; Restore counter
	mov	al,[fstmsk]	; Fetch mask
vertsets:
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        mov     esi,ecx         ; save total count
vertpags:
        mov     ax,65535        ; find left in page
        mov     dx,0
        sub     ax,di
        div     bx              ; find number of lines
        inc     ax              ; adjust
        cmp     si,ax           ; check remainder < lines
        jc      vertends        ; yes, go
        sub     si,ax           ; find new total
        mov     cx,ax           ; place subtotal
	mov	al,[fstmsk]	; Fetch mask
vertloops:
        call    plcpix          ; save current pixel
	and	[edi],al	; Latch data, then set to new value
	add	di,bx		; Update offset
	loopw	vertloops
	mov	ah,[varseg]	; fetch page number
	inc	ah		; Advance page number
	call	[segvid]
	mov	[varseg],ah	; save page number
        or      si,si           ; check end of all
        jnz     vertpags        ; go next page if not
        jmp     endlines        ; exit
vertends:
        mov     cx,si           ; place count
	mov	al,[fstmsk]	; Fetch mask
vertendls: 
        call    plcpix          ; save current pixel
	and	[edi],al	; Latch data, then set to new value
	add	di,bx		; Update offset
	loopw	vertendls
        jmp     endlines        ; exit
        
; Horizontal line

horizontals:
	pop	edi		; Fetch offset

; Draw pixels from the leading partial byte

	mov	eax,[ebp+x1]	; Fetch x coordinate (assume x1 > x0)
	cmp	[deltax],0	; Is x1 > x0?
	jns	HorzInOrders

; X1 < X0, but we want to draw right only, so compute address of
; (X1,Y1) and start from there

	mov	eax,[ebp+y2]	; Fetch y coordinate
	mul	[linbyt]        ; multiply by raster width
	mov	ecx,[ebp+x2]	; add x coordinate/8
	shr	ecx,3           ; convert to byte offset
	add	eax,ecx         ; offset
        movzx   ecx,ax          ; set up offset
        add     ecx,vidbuf      ; offset to video buffer
        mov     edi,ecx         ; save
        shr     eax,8           ; place 64kb offset in ah
	mov	[varseg],ah	; Save page number for later
	call	[segvid]
	mov	edx,03cfh       ; Put gr ctrl data register in DX
	mov	eax,[ebp+x2]
horzinorders:
	mov	ecx,esi		; Set counter of pixels
	inc	ecx
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        mov     al,[fstmsk]     ; get mask
        mov     ah,[varseg]     ; get segment
horizs01:
        call    plcpix          ; save pixel
	and	[edi],al	; Latch data, then set to new value
        ror     al,1            ; rotate mask
        jnc     horizs02        ; skip no new byte
        add     di,1            ; next byte
        jnc     horizs02        ; skip no new page
        inc     ah              ; set next page
        call    [segvid]
horizs02:
        loop    horizs01        ; loop next pixel
        jmp     endlines        ; exit

; Diagonal line for x-major

; Compute constants for x-major

xmajors:
	mov	ecx,esi		; Set counter to dx+1
	inc	ecx
        push    esi
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        pop     esi
	sal	edi,1		; D1 = dy*2
	mov	ebx,edi		; D  = dy*2-dx
	sub	ebx,esi
	neg	esi		; D2 = dy*2-dx-dx
	add	esi,ebx
	mov	[d1],edi	; Save d1
	mov	[d2],esi	; Save d2
	pop	edi		; Restore offset of first pixel
	mov	al,[fstmsk]	; Fetch the initial mask
	mov	ah,[edi]	; Load initial latches
	xor	esi,esi		; Keep 0 in SI

; Jump according to sign of dx and dy

	or	[pitch],si	; Check if dy is positive
	jns	xmyposs
	neg	[pitch]		; Restore pitch
	or	[deltax],esi
	js	xnynjumps
	jmp	xpyns		; Go do dy negative dx positive
xnynjumps:
	jmp	xnyns		; Go do both dy and dx negative

xmyposs:
	or	[deltax],esi	; Check if dx also positive
	jns	xpyps		; Jump if both dx and dy are positive
	jmp	xnyps		; Jump if dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and x major

xpyps:
	xor	dl,dl		; Clear mask accumulator
        mov     ah,[varseg]     ; get segment
xpypnexts:			; Loop over pixels to be set
	or	dl,al		; Add next bit into mask accumulator
	ror	al,1		; Update mask
	jnc	xpypskips	; Skip update if not in next byte
        call    plcpix          ; save current pixel
	and	[edi],dl 	; Load latches, change pixels, in last
	add	di,1		; Advance to the next byte
        jnc     xpypskips2      ; no overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpypskips2:
	xor	dl,dl		; Reset mask accumulator
xpypskips:
	or	ebx,ebx		; If d >= 0 then ...
	js	xpypdnegs
	and	[edi],dl 	; Set previous scanline pixels
	xor	dl,dl		; Reset mask accumulator
	add	ebx,[d2]	; ... d = d + d2
	add	di,[pitch]	; Update offset
	jnc	xpypskips1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpypskips1:
	loop	xpypnexts
	jmp	endlines
xpypdnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xpypnexts
	and	[edi],dl 	; Set (possible) last partial byte
	jmp	endlines        ; exit

; Draw line where DX < 0 and DY > 0 and X major

xnyps:
        mov     ah,[varseg]     ; get segment
xnypnexts:			; Loop over pixels to be set
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     xnypskips1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnypskips1:
	or	ebx,ebx		; If d >= 0 then ...
	js	xnypdnegs
	add	ebx,[d2]	; ... d = d + d2
	add	di,[pitch]	; Update offset
        jnc     xnypskips       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xnypskips:
	loop	xnypnexts
	jmp	endlines
xnypdnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xnypnexts
	jmp	endlines

; Draw line where DX > 0 and DY < 0 and x major

xpyns:
        mov     ah,[varseg]     ; get segment
xpynnexts:			; Loop over pixels to be set
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     xpynskips1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpynskips1:
	or	ebx,ebx		; If d >= 0 then ...
	js	xpyndnegs
	add	ebx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; Update offset
        jnc     xpynskips       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xpynskips:
	loop	xpynnexts
	jmp	endlines
xpyndnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xpynnexts
	jmp	endlines

; Draw line where DX < 0 and DY < 0 and x major

xnyns:
        mov     ah,[varseg]     ; get segment
xnynnexts:			; Loop over pixels to be set
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     xnynskips1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnynskips1:        
	or	ebx,ebx		; If d >= 0 then ...
	js	xnyndnegs
	add	ebx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; Update offset
        jnc     xnynskips       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnynskips:
	loop	xnynnexts
	jmp	endlines
xnyndnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xnynnexts
	jmp	endlines

; Diagonal line for y-major

; Compute constants for dx < dy

ymajors:
	mov	ecx,edi		; Set counter to dy+1
	inc	ecx
        push    esi
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        pop     esi
	sal	esi,1		; D1 = dx * 2
	mov	ebx,esi		; D  = dx * 2 - dy
	sub	ebx,edi
	neg	edi		; D2 = -dy + dx * 2 - dy
	add	edi,ebx
	mov	[d2],edi	; Save d2
	mov	[d1],esi	; Save d1
	pop	edi		; Restore address of first pixel
	mov	al,[fstmsk]	; Fetch mask
	xor	esi,esi		; Keep 0 in SI

; Jump according to sign of dx and dy
  
	or	[pitch],si	; Check if dy is positive
	jns	ymyposs
	neg	[pitch]
	or	[deltax],esi
	js	nxnyjumps
	jmp	pxnys		; Go do dy negative dx positive
nxnyjumps:
	jmp	nxnys		; Go do both dy and dx negative

ymyposs:
	or	[deltax],esi	; Check if dx also positive
	jns	pxpys		; Jump if both dx and dy are positive
	jmp	nxpys		; Jump if dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and y major
  
pxpys:
        mov     ah,[varseg]     ; get segment
pxpynexts:
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	add	di,[pitch]	; Update offset
        jnc     pxpyskips       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxpyskips:
	or	ebx,ebx		; If d >= 0 then ...
	js	pxpydnegs
	add	ebx,[d2]	; ... d = d + d2
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     pxpyskips1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxpyskips1:
	loop	pxpynexts
	jmp	endlines
pxpydnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	pxpynexts
	jmp	endlines

; Draw line where DX < 0 and DY > 0 and y major
  
nxpys:
        mov     ah,[varseg]     ; get segment
nxpynexts:
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	add	di,[pitch]	; Update offset
        jnc     nxpyskips       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
nxpyskips:
	or	ebx,ebx		; If d >= 0 then ...
	js	nxpydnegs
	add	ebx,[d2]	; ... d = d + d2
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     nxpyskips1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxpyskips1:
	loop	nxpynexts
	jmp	endlines
nxpydnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	nxpynexts
	jmp	endlines

; Draw line where DX > 0 and DY < 0 and y major
  
pxnys:
        mov     ah,[varseg]     ; get segment
pxnynexts:
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	sub	di,[pitch]	; Update offset
        jnc     pxnyskips       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
pxnyskips:
	or	ebx,ebx		; If d >= 0 then ...
	js	pxnydnegs
	add	ebx,[d2]	; ... d = d + d2
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     pxnyskips1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxnyskips1:
	loop	pxnynexts
	jmp	endlines
pxnydnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	pxnynexts
	jmp	endlines

; Draw line where DX < 0 and DY < 0 and y major
  
nxnys:
        mov     ah,[varseg]     ; get segment
nxnynexts:
        call    plcpix          ; save current pixel
	and	[edi],al 	; Latch data, then set to new value
	sub	di,[pitch]	; Update offset
        jnc     nxnyskips       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxnyskips:
	or	ebx,ebx		; If d >= 0 then ...
	js	nxnydnegs
	add	ebx,[d2]	; ... d = d + d2
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     nxnyskips1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxnyskips1:
	loop	nxnynexts
	jmp	endlines
nxnydnegs:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	nxnynexts
	jmp	endlines

; exit

endlines:
        mov     dx,03ceh        ; reset mode register
        mov     ax,00005h       
        out     dx,ax
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
linespl endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; LINE DRAW WITH SAVE PACKED                                  ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

linespk proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers
        push    esi
        push    edi      
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place paramters
        pop     ecx
        pop     ebx
        pop     eax
        call    clipline        ; clip the line eax,ebx-ecx,edx
        jc      linedones       ; exit if line clipped out
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; Set up save address
  
        mov     ebx,[ebp+i]     ; get index
        movzx   eax,word ptr [ebx]
        dec     eax             ; adjust to 0
        add     eax,[ebp+lines] ; offset array
        push    eax             ; save

; Convert (x,y) starting point to video address and select page

	mov	eax,[ebp+y1]	; Convert (x,y) to address
	mul	word ptr [linbyt] ; multiply y by pitch
	mov	ecx,[ebp+x1]	; fetch x
	shr	ecx,1		; convert pixel to byte number
	add	eax,ecx		; add to previous product
        add     eax,vidbuf      ; offset by video base
	push	eax		; Save address on stack for later
	mov	ah,dl		; Copy page number into ah
	mov	[varseg],Ah	; Save page number
	call	[segvid]	; Select proper page
	mov	bx,00ff0h	; Set initial mask (assume x even)
				; bl=src mask, bh=dst mask
	mov	eax,[ebp+x1]	; Move bit0 of x into sign bit
	ror	ax,1
	cwd			; Set dx to ffff if x is odd
	xor	bx,dx		; Invert masks if x was odd
	mov	al,[ebp+clr]	; Duplicate color into high nibble
	and	al,0fh
	shl	al,4
	or	[ebp+clr],al

; Compute dx and dy and determine which coordinate is major

	mov	eax,[linbyt]    ; set raster increment
	mov     [pitch],ax
	mov	esi,[ebp+x2]	; compute dx reg-si
	sub	esi,[ebp+x1]
	mov	deltax,esi
	jge	dxisposs
	neg	esi
dxisposs:
	mov	edi,[ebp+y2]	; compute dy reg-di
	sub	edi,[ebp+y1]
	jge	dyisposs
	neg	[pitch]
	neg	edi
dyisposs:

; Determine which coordinate is the major one

	cmp	esi,edi		; check that dx > dy
	jge	xmajors
	jmp	ymajors

; Compute constants for x-major

xmajors:
	mov	ecx,esi		; set counter to dx+1
	inc	ecx
        mov     edx,[ebp+i]     ; index index
        add     [edx],cx        ; offset
	sal	edi,1		; d1 = dy*2
	mov	edx,edi		; d  = dy*2-dx
	sub    	edx,esi
	neg	esi		; d2 = dy*2-dx-dx
	add	esi,edx
	mov	[d1],edi	; save d1
	mov	[d2],esi	; save d2
	pop	edi		; restore offset of first pixel

; Jump according to sign of dx and dy

	test	[pitch],08000h  ; Check if dy is positive
	jz	yps
	neg	[pitch]         ; Restore pitch
	test	[deltax],08000h
	jnz	xnyns
	jmp	xpyns 	        ; go do dy negative dx positive
yps:
	test	[deltax],08000h ; ...no, check if dx also positive
	jnz	xnyps 	        ; ...dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and x is the major coordinate

xpyps:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts0:		        	; Loop over pixels to be set
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	pages0	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	pages0
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]  	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages0:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dnegs0
	add	edx,[d2]   	; ... d = d + d2
	add	di,[pitch]	; update offset
	jnc	fixs00
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixs00           ; go
dnegs0:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixs00:
	loop	nexts0
	jmp	linedones

; Draw line where DX < 0 and DY > 0 and X major

xnyps:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts3:			        ; Loop over pixels to be set
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	pages3	        ; if upper nibble set skip update
	sub	di,1		; else must point to next byte
	jnc	pages3
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages3:
	test	edx,8000h	; if d >= 0 then ...
	jnz     dnegs3
	add	edx,[d2]        ; ... d = d + d2
	add	di,[pitch]	; update offset
	jnc	fixs33
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixs33           ; go
dnegs3:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixs33:
	loop	nexts3
	jmp	linedones

; Draw line where DX > 0 and DY < 0 and x major

xpyns:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts7:			        ; Loop over pixels to be set
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	pages7	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	pages7
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages7:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dnegs7
	add     edx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; update offset
	jnc	fixs77
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixs77           ; go
dnegs7:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixs77:
	loop	nexts7
	jmp	linedones

; Draw line where DX < 0 and DY < 0 and x major

xnyns:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts4:			        ; Loop over pixels to be set
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	pages4	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc     pages4
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages4:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dnegs4
	add	edx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; update offset
	jnc	fixs44
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixs44           ; go
dnegs4:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixs44:
	loop	nexts4
	jmp	linedones

; Compute constants for dx < dy

ymajors:
	mov	ecx,edi		; set counter to dy+1
	inc	ecx
        mov     edx,[ebp+i]     ; index index
        add     [edx],cx        ; offset
	sal	esi,1		; d1 = dx * 2
	mov	edx,esi		; d  = dx * 2 - dy
	sub	edx,edi
	neg	edi		; d2 = -dy + dx * 2 - dy
	add	edi,edx
	mov	[d2],edi 	; save d2
	mov	[d1],esi 	; save d1
	pop	edi		; Restore address of first pixel

; Jump according to sign of dx and dy

	test	[pitch],08000h ; Check if dy is positive
	jz	pys
	neg	[pitch]
	test	[deltax],08000h
	jnz	nxnys
	jmp	pxnys 	        ; go do dy negative dx positive
pys:
	test	[deltax],08000h ; ...no, check if dx also positive
	jnz	nxpys 	        ; ...dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and y major

pxpys:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts1:
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	add	di,[pitch]	; update offset
	jnc	pages1
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages1:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegs1
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	loops1   	; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	loops1
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loops1           ; go
dnegs1:
	add	edx,[d1]	; if d < 0 then d = d + d1
loops1:
	loop	nexts1
	jmp	linedones

; Draw line where DX < 0 and DY > 0 and y major

nxpys:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts2:
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	add	di,[pitch]	; update offset
	jnc	pages2
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages2:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegs2
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	loops2	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc	loops2
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loops2           ; go
dnegs2:
	add	edx,[d1]	; if d < 0 then d = d + d1
loops2:
	loop	nexts2
	jmp	linedones

; Draw line where DX > 0 and DY < 0 and y major

pxnys:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts6:
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	sub	di,[pitch]	; update offset
	jnc	pages6
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages6:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegs6
        add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	loops6	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	loops6
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loops6          ; go
dnegs6:
	add	edx,[d1]	; if d < 0 then d = d + d1
loops6:
	loop	nexts6
	jmp	linedones

; Draw line where DX < 0 and DY < 0 and y major

nxnys:
        pop     esi             ; get save address
	mov	ah,[ebp+clr]	; Fetch color of the pixel
nexts5:
        mov     al,[edi]        ; save existing color
        mov     [esi],al
        inc     esi             ; next
	mov	al,ah		; Fetch source color
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	sub	di,[pitch]	; update offset
	jnc	pages5
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pages5:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegs5
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	loops5	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc	loops5
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
        dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loops5          ; go
dnegs5:
	add	edx,[d1]	; if d < 0 then d = d + d1
loops5:
	loop	nexts5
	jmp	linedones

; Clean up and return to caller

linedones:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
linespk endp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW LINE FROM BUFFER                                       ;
;                                                             ;
; Draws a line between the start and end points. The pixels   ;
; used are recovered from the buffer.                         ;
;                                                             ;
; procedure linerst(x1, y1, x2, y2: integer;                  ;
;                   var lines: linarr; var i: lininx)         ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vp      =       8               ; pointer to viewport record
x1      =       12
y1      =       16
x2      =       20
y2      =       24
lines   =       28
i       =       32

linerst proc    syscall
        jmp     [linerp]        ; goto proper routine
linerst endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; LINE RESTORE PLANAR                                         ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Routine to restore the current pixel from the save buffer
; Expects: ah  = bit mask
;          edi = video address
;          

rstpix  proc    syscall
        push    ax              ; save
        push    ebx
        push    dx
	mov	dx,03ceh	; Use color for set/reset value
        mov     ebx,[pixarr]    ; get next pixel address
        mov     ah,[ebx]        ; get bit value
        inc     ebx             ; next location
        mov     [pixarr],ebx    ; replace
        xor     al,al           ; place set/reset register number
        out     dx,ax           ; activate
        pop     dx              ; restore
        pop     ebx
        pop     ax
        ret
rstpix  endp  

linerpl proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        push    esi
        push    edi
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place paramters
        pop     ecx
        pop     ebx
        pop     eax
        call    clipline        ; clip the line eax,ebx-ecx,edx
        jc      endliner        ; exit if line clipped out
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; offset to index

        mov     ebx,[ebp+i]     ; get index
        movzx   eax,word ptr [ebx]
        dec     eax             ; adjust to 0
        add     eax,[ebp+lines] ; offset array
        mov     [pixarr],eax    ; save

; Compute address of first pixel, select color

        mov     eax,[ebp+y1]    ; get y
        mul     [linbyt]        ; find lines offset
        mov     ebx,[ebp+x1]    ; get x
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        mov     [varseg],ah     ; and save
        call    [segvid]        ; select segment
        push    ebx             ; save video address
	mov	ecx,[ebp+x1]	; Fetch x1
	and	cl,7		; Get bit position within first byte
	mov	bl,80h		; Assume first bit
	shr	bl,cl		; Rotate mask bit into place
	mov	[fstmsk],bl	; Save mask

; Load set/reset registers with current color, select bit mask reg

	mov	al,[ebp+clr]    ; get color
	mov	dx,03ceh	; Use color for set/reset value
	mov	ah,al
	mov	al,0
	out	dx,ax
	mov	ax,00F01h	; Enable set/reset
	out	dx,ax
	mov	ax,0FF08h	; Set bit mask to FFh
	out	dx,ax
	mov	ax,00007h       ; Set color don't care to 00h
	out	dx,ax
	mov	al,5		; Index of mode reg
	out	dx,al		; Select mode reg
	inc	dx
	in	al,dx		; Read previous value
	or	al,0bh		; Enable color compare, write mode 3
	out	dx,al

; Compute dx and dy and determine which coordinate is major

	mov	eax,[linbyt]    ; Set raster increment
	mov	[pitch],ax
	mov	esi,[ebp+x2]	; Compute dx (X1-X0) in SI
	sub	esi,[ebp+x1]
	mov	[deltax],esi	; Save in local variable
	jge	dxposr		; If dx is negative, make it positive
	neg	esi
dxposr:
	mov	edi,[ebp+y2]	; Compute dy (Y1-Y0) in DI
	sub	edi,[ebp+y1]
	jge	dyposr		; If dy is negative, make it positive
	neg	[pitch]		; Also, invert the pitch
	neg	edi
dyposr:

; Figure out which coordinate is the major one

	or	esi,esi		; Check for vertical line
	je	verticalr
	or	edi,edi		; Check for horizontal line
	je	horizontalr
	cmp	esi,edi		; Check that dx > dy
	jl	ymajorjumpr
	jmp	xmajorr
ymajorjumpr:
	jmp	ymajorr

; Vertical Line

verticalr:
	mov    	ecx,edi		; Set up counter
	inc	ecx		; Number of pixels is one greater
	pop	edi		; Fetch offset
	mov	bx,[pitch]	; Fetch pitch
	or	bx,bx		; Check for y decreasing
	jns	vertsetr        ; go

; Y1 < Y0, but we want to draw down only, so compute address of
; (X1,Y1) and start from there

	neg	bx
	xchg	esi,ecx		; Preserve counter
	mov	eax,[ebp+y2]	; Fetch y coordinate
	mul	[linbyt]        ; multiply by raster width
	mov	ecx,[ebp+x2]	; add x coordinate/8
	shr	ecx,3           ; convert to byte offset
	add	eax,ecx         ; offset
        movzx   ecx,ax          ; set up offset
        add     ecx,vidbuf      ; offset to video buffer
        mov     edi,ecx         ; save
        shr     eax,8           ; place 64kb offset in ah
	mov	[varseg],ah	; Save page number for later
	call	[segvid]
	xchg	esi,ecx		; Restore counter
	mov	al,[fstmsk]	; Fetch mask
vertsetr:
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        mov     esi,ecx         ; save total count
vertpagr:
        mov     ax,65535        ; find left in page
        mov     dx,0
        sub     ax,di
        div     bx              ; find number of lines
        inc     ax              ; adjust
        cmp     si,ax           ; check remainder < lines
        jc      vertendr        ; yes, go
        sub     si,ax           ; find new total
        mov     cx,ax           ; place subtotal
	mov	al,[fstmsk]	; Fetch mask
vertloopr:
        call    rstpix          ; restore pixel
	and	[edi],al	; Latch data, then set to new value
	add	di,bx		; Update offset
	loopw	vertloopr
	mov	ah,[varseg]	; fetch page number
	inc	ah		; Advance page number
	call	[segvid]
	mov	[varseg],ah	; save page number
        or      si,si           ; check end of all
        jnz     vertpagr        ; go next page if not
        jmp     endliner        ; exit
vertendr:
        mov     cx,si           ; place count
	mov	al,[fstmsk]	; Fetch mask
vertendlr: 
        call    rstpix          ; restore pixel
	and	[edi],al	; Latch data, then set to new value
	add	di,bx		; Update offset
	loopw	vertendlr
        jmp     endliner        ; exit
        
; Horizontal line

horizontalr:
	pop	edi		; Fetch offset

; Draw pixels from the leading partial byte

	mov	eax,[ebp+x1]	; Fetch x coordinate (assume x1 > x0)
	cmp	[deltax],0	; Is x1 > x0?
	jns	HorzInOrderr

; X1 < X0, but we want to draw right only, so compute address of
; (X1,Y1) and start from there

	mov	eax,[ebp+y2]	; Fetch y coordinate
	mul	[linbyt]        ; multiply by raster width
	mov	ecx,[ebp+x2]	; add x coordinate/8
	shr	ecx,3           ; convert to byte offset
	add	eax,ecx         ; offset
        movzx   ecx,ax          ; set up offset
        add     ecx,vidbuf      ; offset to video buffer
        mov     edi,ecx         ; save
        shr     eax,8           ; place 64kb offset in ah
	mov	[varseg],ah	; Save page number for later
	call	[segvid]
	mov	edx,03cfh       ; Put gr ctrl data register in DX
	mov	eax,[ebp+x2]
horzinorderr:
	mov	ecx,esi		; Set counter of pixels
	inc	ecx
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        mov     al,[fstmsk]     ; get mask
        mov     ah,[varseg]     ; get segment
horizr01:
        call    rstpix          ; restore pixel
	and	[edi],al	; Latch data, then set to new value
        ror     al,1            ; rotate mask
        jnc     horizr02        ; skip no new byte
        add     di,1            ; next byte
        jnc     horizr02        ; skip no new page
        inc     ah              ; set next page
        call    [segvid]
horizr02:
        loop    horizr01        ; loop next pixel
        jmp     endliner        ; exit

; Diagonal line for x-major

; Compute constants for x-major

xmajorr:
	mov	ecx,esi		; Set counter to dx+1
	inc	ecx
        push    esi
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        pop     esi
	sal	edi,1		; D1 = dy*2
	mov	ebx,edi		; D  = dy*2-dx
	sub	ebx,esi
	neg	esi		; D2 = dy*2-dx-dx
	add	esi,ebx
	mov	[d1],edi	; Save d1
	mov	[d2],esi	; Save d2
	pop	edi		; Restore offset of first pixel
	mov	al,[fstmsk]	; Fetch the initial mask
	mov	ah,[edi]	; Load initial latches
	xor	esi,esi		; Keep 0 in SI

; Jump according to sign of dx and dy

	or	[pitch],si	; Check if dy is positive
	jns	xmyposr
	neg	[pitch]		; Restore pitch
	or	[deltax],esi
	js	xnynjumpr
	jmp	xpynr		; Go do dy negative dx positive
xnynjumpr:
	jmp	xnynr		; Go do both dy and dx negative

xmyposr:
	or	[deltax],esi	; Check if dx also positive
	jns	xpypr		; Jump if both dx and dy are positive
	jmp	xnypr		; Jump if dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and x major

xpypr:
	xor	dl,dl		; Clear mask accumulator
        mov     ah,[varseg]     ; get segment
xpypnextr:			; Loop over pixels to be set
	or	dl,al		; Add next bit into mask accumulator
	ror	al,1		; Update mask
	jnc	xpypskipr	; Skip update if not in next byte
        call    rstpix          ; restore pixel
	and	[edi],dl 	; Load latches, change pixels, in last
	add	di,1		; Advance to the next byte
        jnc     xpypskipr2      ; no overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpypskipr2:
	xor	dl,dl		; Reset mask accumulator
xpypskipr:
	or	ebx,ebx		; If d >= 0 then ...
	js	xpypdnegr
	and	[edi],dl 	; Set previous scanline pixels
	xor	dl,dl		; Reset mask accumulator
	add	ebx,[d2]	; ... d = d + d2
	add	di,[pitch]	; Update offset
	jnc	xpypskipr1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpypskipr1:
	loop	xpypnextr
	jmp	endliner
xpypdnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xpypnextr
	and	[edi],dl 	; Set (possible) last partial byte
	jmp	endliner        ; exit

; Draw line where DX < 0 and DY > 0 and X major

xnypr:
        mov     ah,[varseg]     ; get segment
xnypnextr:			; Loop over pixels to be set
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     xnypskipr1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnypskipr1:
	or	ebx,ebx		; If d >= 0 then ...
	js	xnypdnegr
	add	ebx,[d2]	; ... d = d + d2
	add	di,[pitch]	; Update offset
        jnc     xnypskipr       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xnypskipr:
	loop	xnypnextr
	jmp	endliner
xnypdnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xnypnextr
	jmp	endliner

; Draw line where DX > 0 and DY < 0 and x major

xpynr:
        mov     ah,[varseg]     ; get segment
xpynnextr:			; Loop over pixels to be set
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     xpynskipr1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
xpynskipr1:
	or	ebx,ebx		; If d >= 0 then ...
	js	xpyndnegr
	add	ebx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; Update offset
        jnc     xpynskipr       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xpynskipr:
	loop	xpynnextr
	jmp	endliner
xpyndnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xpynnextr
	jmp	endliner

; Draw line where DX < 0 and DY < 0 and x major

xnynr:
        mov     ah,[varseg]     ; get segment
xnynnextr:			; Loop over pixels to be set
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     xnynskipr1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnynskipr1:        
	or	ebx,ebx		; If d >= 0 then ...
	js	xnyndnegr
	add	ebx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; Update offset
        jnc     xnynskipr       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
xnynskipr:
	loop	xnynnextr
	jmp	endliner
xnyndnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	xnynnextr
	jmp	endliner

; Diagonal line for y-major

; Compute constants for dx < dy

ymajorr:
	mov	ecx,edi		; Set counter to dy+1
	inc	ecx
        push    esi
        mov     esi,[ebp+i]     ; index index
        add     [esi],cx        ; offset
        pop     esi
	sal	esi,1		; D1 = dx * 2
	mov	ebx,esi		; D  = dx * 2 - dy
	sub	ebx,edi
	neg	edi		; D2 = -dy + dx * 2 - dy
	add	edi,ebx
	mov	[d2],edi	; Save d2
	mov	[d1],esi	; Save d1
	pop	edi		; Restore address of first pixel
	mov	al,[fstmsk]	; Fetch mask
	xor	esi,esi		; Keep 0 in SI

; Jump according to sign of dx and dy
  
	or	[pitch],si	; Check if dy is positive
	jns	ymyposr
	neg	[pitch]
	or	[deltax],esi
	js	nxnyjumpr
	jmp	pxnyr		; Go do dy negative dx positive
nxnyjumpr:
	jmp	nxnyr		; Go do both dy and dx negative

ymyposr:
	or	[deltax],esi	; Check if dx also positive
	jns	pxpyr		; Jump if both dx and dy are positive
	jmp	nxpyr		; Jump if dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and y major
  
pxpyr:
        mov     ah,[varseg]     ; get segment
pxpynextr:
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	add	di,[pitch]	; Update offset
        jnc     pxpyskipr       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxpyskipr:
	or	ebx,ebx		; If d >= 0 then ...
	js	pxpydnegr
	add	ebx,[d2]	; ... d = d + d2
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     pxpyskipr1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxpyskipr1:
	loop	pxpynextr
	jmp	endliner
pxpydnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	pxpynextr
	jmp	endliner

; Draw line where DX < 0 and DY > 0 and y major
  
nxpyr:
        mov     ah,[varseg]     ; get segment
nxpynextr:
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	add	di,[pitch]	; Update offset
        jnc     nxpyskipr       ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
nxpyskipr:
	or	ebx,ebx		; If d >= 0 then ...
	js	nxpydnegr
	add	ebx,[d2]	; ... d = d + d2
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     nxpyskipr1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxpyskipr1:
	loop	nxpynextr
	jmp	endliner
nxpydnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	nxpynextr
	jmp	endliner

; Draw line where DX > 0 and DY < 0 and y major
  
pxnyr:
        mov     ah,[varseg]     ; get segment
pxnynextr:
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	sub	di,[pitch]	; Update offset
        jnc     pxnyskipr       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
pxnyskipr:
	or	ebx,ebx		; If d >= 0 then ...
	js	pxnydnegr
	add	ebx,[d2]	; ... d = d + d2
	ror	al,1		; Update mask
	adc	di,si		; and address (if needed)
        jnc     pxnyskipr1      ; no page overflow, skip
	inc	ah      	; Select next page
	call	[segvid]
pxnyskipr1:
	loop	pxnynextr
	jmp	endliner
pxnydnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	pxnynextr
	jmp	endliner

; Draw line where DX < 0 and DY < 0 and y major
  
nxnyr:
        mov     ah,[varseg]     ; get segment
nxnynextr:
        call    rstpix          ; restore pixel
	and	[edi],al 	; Latch data, then set to new value
	sub	di,[pitch]	; Update offset
        jnc     nxnyskipr       ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxnyskipr:
	or	ebx,ebx		; If d >= 0 then ...
	js	nxnydnegr
	add	ebx,[d2]	; ... d = d + d2
	rol	al,1		; Update mask
	sbb	di,si		; and address (if needed)
        jnc     nxnyskipr1      ; no page overflow, skip
	dec	ah      	; Select previous page
	call	[segvid]
nxnyskipr1:
	loop	nxnynextr
	jmp	endliner
nxnydnegr:
	add	ebx,[d1]	; If d < 0 then d = d + d1
	loop	nxnynextr
	jmp	endliner

; exit

endliner:
        mov     dx,03ceh        ; reset mode register
        mov     ax,00005h       
        out     dx,ax
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
linerpl endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; LINE RESTORE PACKED                                         ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

linerpk proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers
        push    esi
        push    edi      
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place paramters
        pop     ecx
        pop     ebx
        pop     eax
        call    clipline        ; clip the line eax,ebx-ecx,edx
        jc      linedoner       ; exit if line clipped out
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; Set up save address
  
        mov     ebx,[ebp+i]     ; get index
        movzx   eax,word ptr [ebx]
        dec     eax             ; adjust to 0
        add     eax,[ebp+lines] ; offset array
        push    eax             ; save

; Convert (x,y) starting point to video address and select page

	mov	eax,[ebp+y1]	; Convert (x,y) to address
	mul	word ptr [linbyt] ; multiply y by pitch
	mov	ecx,[ebp+x1]	; fetch x
	shr	ecx,1		; convert pixel to byte number
	add	eax,ecx		; add to previous product
        add     eax,vidbuf      ; offset by video base
	push	eax		; Save address on stack for later
	mov	ah,dl		; Copy page number into ah
	mov	[varseg],Ah	; Save page number
	call	[segvid]	; Select proper page
	mov	bx,00ff0h	; Set initial mask (assume x even)
				; bl=src mask, bh=dst mask
	mov	eax,[ebp+x1]	; Move bit0 of x into sign bit
	ror	ax,1
	cwd			; Set dx to ffff if x is odd
	xor	bx,dx		; Invert masks if x was odd
	mov	al,[ebp+clr]	; Duplicate color into high nibble
	and	al,0fh
	shl	al,4
	or	[ebp+clr],al

; Compute dx and dy and determine which coordinate is major

	mov	eax,[linbyt]    ; set raster increment
	mov     [pitch],ax
	mov	esi,[ebp+x2]	; compute dx reg-si
	sub	esi,[ebp+x1]
	mov	deltax,esi
	jge	dxisposr
	neg	esi
dxisposr:
	mov	edi,[ebp+y2]	; compute dy reg-di
	sub	edi,[ebp+y1]
	jge	dyisposr
	neg	[pitch]
	neg	edi
dyisposr:

; Determine which coordinate is the major one

	cmp	esi,edi		; check that dx > dy
	jge	xmajorr
	jmp	ymajorr

; Compute constants for x-major

xmajorr:
	mov	ecx,esi		; set counter to dx+1
	inc	ecx
        mov     edx,[ebp+i]     ; index index
        add     [edx],cx        ; offset
	sal	edi,1		; d1 = dy*2
	mov	edx,edi		; d  = dy*2-dx
	sub    	edx,esi
	neg	esi		; d2 = dy*2-dx-dx
	add	esi,edx
	mov	[d1],edi	; save d1
	mov	[d2],esi	; save d2
	pop	edi		; restore offset of first pixel

; Jump according to sign of dx and dy

	test	[pitch],08000h  ; Check if dy is positive
	jz	ypr
	neg	[pitch]         ; Restore pitch
	test	[deltax],08000h
	jnz	xnynr
	jmp	xpynr 	        ; go do dy negative dx positive
ypr:
	test	[deltax],08000h ; ...no, check if dx also positive
	jnz	xnypr 	        ; ...dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and x is the major coordinate

xpypr:
        pop     esi             ; get save address
nextr0:		        	; Loop over pixels to be set
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	pager0	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	pager0
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]  	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager0:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dnegr0
	add	edx,[d2]   	; ... d = d + d2
	add	di,[pitch]	; update offset
	jnc	fixr00
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixr00           ; go
dnegr0:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixr00:
	loop	nextr0
	jmp	linedoner

; Draw line where DX < 0 and DY > 0 and X major

xnypr:
        pop     esi             ; get save address
nextr3:			        ; Loop over pixels to be set
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	pager3	        ; if upper nibble set skip update
	sub	di,1		; else must point to next byte
	jnc	pager3
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager3:
	test	edx,8000h	; if d >= 0 then ...
	jnz     dnegr3
	add	edx,[d2]        ; ... d = d + d2
	add	di,[pitch]	; update offset
	jnc	fixr33
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixr33           ; go
dnegr3:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixr33:
	loop	nextr3
	jmp	linedoner

; Draw line where DX > 0 and DY < 0 and x major

xpynr:
        pop     esi             ; get save address
nextr7:			        ; Loop over pixels to be set
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	pager7	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	pager7
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager7:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dnegr7
	add     edx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; update offset
	jnc	fixr77
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixr77           ; go
dnegr7:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixr77:
	loop	nextr7
	jmp	linedoner

; Draw line where DX < 0 and DY < 0 and x major

xnynr:
        pop     esi             ; get save address
nextr4:			        ; Loop over pixels to be set
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	pager4	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc     pager4
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager4:
	test	edx,8000h	; if d >= 0 then ...
	jnz	dnegr4
	add	edx,[d2]	; ... d = d + d2
	sub	di,[pitch]	; update offset
	jnc	fixr44
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     fixr44           ; go
dnegr4:
	add	edx,[d1]	; if d < 0 then d = d + d1
fixr44:
	loop	nextr4
	jmp	linedoner

; Compute constants for dx < dy

ymajorr:
	mov	ecx,edi		; set counter to dy+1
	inc	ecx
        mov     edx,[ebp+i]     ; index index
        add     [edx],cx        ; offset
	sal	esi,1		; d1 = dx * 2
	mov	edx,esi		; d  = dx * 2 - dy
	sub	edx,edi
	neg	edi		; d2 = -dy + dx * 2 - dy
	add	edi,edx
	mov	[d2],edi 	; save d2
	mov	[d1],esi 	; save d1
	pop	edi		; Restore address of first pixel

; Jump according to sign of dx and dy

	test	[pitch],08000h ; Check if dy is positive
	jz	pyr
	neg	[pitch]
	test	[deltax],08000h
	jnz	nxnyr
	jmp	pxnyr 	        ; go do dy negative dx positive
pyr:
	test	[deltax],08000h ; ...no, check if dx also positive
	jnz	nxpyr 	        ; ...dx is negative and dy positive

; Draw line where DX > 0 and DY > 0 and y major

pxpyr:
        pop     esi             ; get save address
nextr1:
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	add	di,[pitch]	; update offset
	jnc	pager1
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager1:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegr1
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	loopr1   	; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	loopr1
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loopr1           ; go
dnegr1:
	add	edx,[d1]	; if d < 0 then d = d + d1
loopr1:
	loop	nextr1
	jmp	linedoner

; Draw line where DX < 0 and DY > 0 and y major

nxpyr:
        pop     esi             ; get save address
nextr2:
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	add	di,[pitch]	; update offset
	jnc	pager2
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager2:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegr2
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	loopr2	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc	loopr2
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loopr2           ; go
dnegr2:
	add	edx,[d1]	; if d < 0 then d = d + d1
loopr2:
	loop	nextr2
	jmp	linedoner

; Draw line where DX > 0 and DY < 0 and y major

pxnyr:
        pop     esi             ; get save address
nextr6:
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	sub	di,[pitch]	; update offset
	jnc	pager6
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager6:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegr6
        add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	jns	loopr6	        ; if upper nibble clear skip update
	add	di,1		; if upper nibble set get next byte
	jnc	loopr6
	xchg	ah,[varseg]	; Preserve AL, and fetch page number
	inc	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loopr6          ; go
dnegr6:
	add	edx,[d1]	; if d < 0 then d = d + d1
loopr6:
	loop	nextr6
	jmp	linedoner

; Draw line where DX < 0 and DY < 0 and y major

nxnyr:
        pop     esi             ; get save address
nextr5:
	mov	al,[esi]	; Fetch source color
        inc     esi             ; next
	and	al,bl		; Clear the 'other' nibble
	and	[edi],bh 	; Clear nibble at destination
	or	[edi],al 	; Combine source and destination
	sub	di,[pitch]	; update offset
	jnc	pager5
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
	dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
pager5:
	test	edx,08000h	; if d >= 0 then ...
	jnz	dnegr5
	add	edx,[d2]	; ... d = d + d2
	not	ebx		; Swap masks
	or	bl,bl		; Check if need to move into next byte
	js	loopr5	        ; if upper nibble set skip update
	sub	di,1		; if upper nibble clear get next byte
	jnc	loopr5
	xchg	ah,[varseg]	; Preserve ah, and fetch page number
        dec	ah		; Update page number
	call	[segvid]	; Select new page number
	xchg	ah,[varseg]	; Save updated page, restore AL
        jmp     loopr5          ; go
dnegr5:
	add	edx,[d1]	; if d < 0 then d = d + d1
loopr5:
	loop	nextr5
	jmp	linedoner

; Clean up and return to caller

linedoner:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
linerpk endp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; DRAW BLOCK                                                  ;
;                                                             ;
; Draws a filled block with corners at the start and end      ;
; points.                                                     ;
;                                                             ;
; procedure block(x1, y1, x2, y2: word; c: color)             ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vp      =       8               ; pointer to viewport record
x1      =       12
y1      =       16
x2      =       20
y2      =       24
clr     =       28

block   proc    syscall
        jmp     [blockp]        ; goto proper routine
block   endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; BLOCK DRAW PLANAR                                           ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blockpl proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; save registers
        push    esi
        push    edi        
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place parameters
        pop     ecx
        pop     ebx
        pop     eax

; rationalize box

        cmp     eax,ecx         ; check x1 > x2
        jng     blockpl01       ; no, skip
        xchg    eax,ecx         ; else trade
blockpl01:
        cmp     ebx,edx         ; check y1 > y2
        jng     blockpl02       ; no, skip
        xchg    ebx,edx
blockpl02:

; check any part of block lies within clipping area

        cmp     eax,[edi+viewcex] ; check x1 > clip(xe)
        jg      endrect           ; yes, exit
        cmp     ecx,[edi+viewcsx] ; check x2 < clip(xs)
        jl      endrect           ; yes, exit
        cmp     ebx,[edi+viewcey] ; check y1 > clip(ye)
        jg      endrect           ; yes, exit
        cmp     edx,[edi+viewcsy] ; check y2 < clip(ys)
        jl      endrect           ; yes, exit

; clip

        cmp     eax,[edi+viewcsx] ; check x1 < clip(xs)
        jnl     blockpl03       ; no, skip
        mov     eax,[edi+viewcsx] ; clip
blockpl03:
        cmp     ecx,[edi+viewcex] ; check x2 > clip(xe)
        jng     blockpl04       ; no, skip
        mov     ecx,[edi+viewcex] ; clip
blockpl04:
        cmp     ebx,[edi+viewcsy] ; check y1 < clip(ys)
        jnl     blockpl05       ; no, skip
        mov     ebx,[edi+viewcsy] ; clip
blockpl05:
        cmp     edx,[edi+viewcey] ; check y2 > clip(ye)
        jng     blockpl06       ; no, skip
        mov     edx,[edi+viewcey] ; clip
blockpl06:
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; Compute address of first pixel, load set/reset (color) register

; Compute page number and select the page


        mov     eax,[ebp+y1]    ; get y
        mul     [linbyt]        ; find lines offset
        mov     ebx,[ebp+x1]    ; get x
        shr     ebx,3           ; convert to byte offset
        add     eax,ebx         ; offset
        movzx   ebx,ax          ; set up offset
        add     ebx,vidbuf      ; offset to video buffer
        shr     eax,8           ; place 64kb offset in ah
        mov     [varseg],ah     ; and save
        mov     [fstpag],ah
        call    [segvid]        ; select segment
        mov     edi,ebx         ; save video address

; Load set/reset registers with current color, select bit mask reg

        mov     al,[ebp+clr]
        mov     dx,03ceh        ;Use color for set/reset value
        mov     ah,al
        mov     al,0
        out     dx,ax
        mov     al,1
        mov     ah,0fh
        out     dx,ax
        mov     al,8            ;Select bit mask register
        out     dx,al
        inc     dx
        mov     ecx,[ebp+x2]    ; Compute number of pixels in a line
        sub     ecx,[ebp+x1]
        inc     ecx
        mov     esi,[ebp+y2]    ; Compute number of lines to do
        sub     esi,[ebp+y1]
        inc     esi

; Draw the rectangle (in three strips = lead, full middle, trail)

; Draw pixels from the leading partial byte

        mov     eax,[ebp+x1]    ; Fetch x coordinate
        and     eax,7           ; Check for partial byte
        jz      full01
        xchg    bh,cl           ; Preserve counter (CL into BH)
        mov     bl,0ffh         ; Compute the mask
        mov     cl,al
        shr     bl,cl
        xchg    bh,cl           ; Restore counter
        add     ecx,eax         ; Update counter
        sub     ecx,8
        jge     masksetrc       ; Modify mask if only one byte
        neg     ecx
        shr     bl,cl
        shl     bl,cl
        xor     ecx,ecx         ; Indicate no more bytes
masksetrc:
        mov     al,bl           ; Fetch mask
        out     dx,al           ; Set mask register
        push    ecx             ; Preserve counters
        push    edi             ; Save first byte offset
        mov     ecx,esi         ; Number of lines to do
        mov     ebx,[linbyt]
        mov     ah,[varseg]     ; get page
leadloop:
        mov     al,[edi]        ; Latch data
        mov     [edi],al        ; Write new data
        add     di,bx           ; Point to next raster
        jnc     leadloop01      ; go no new page
        inc     ah              ; Advance to next page
        call    [segvid]
leadloop01:
        loop    leadloop
        pop     edi
        pop     ecx
        mov     ah,[varseg]     ; get starting segment
        call    [segvid]        ; select
        add     di,1            ; Point to first full byte
        jnc     full            ; go no new page
        inc     ah              ; Advance to next page
        call    [segvid]
        jmp     full            ; skip

; Draw pixels from the middle complete bytes

full01:
        mov     ah,[varseg]     ; get page
full:
        mov     [lstmsk],cl     ; Save count of bits in last byte
        and     [lstmsk],7
        mov     al,0ffh         ; Set mask
        out     dx,al
        shr     ecx,3           ; find whole bytes
        or      ecx,ecx
        jz      trail           ; skip if no full bytes
        push    ax              ; save starting page number
        mov     ebx,[linbyt]    ; Compute line to line increment
        sub     ebx,ecx
        inc     ebx
        push    esi
        push    edi
outerloop:
        push    ecx             ; save count
        mov     edx,ecx         ; save count
outerloop01:        
        mov     cx,65535        ; find bytes left in page
        sub     cx,di
        movzx   ecx,cx          ; expand
        inc     ecx             ; adjust
        cmp     edx,ecx         ; check rem < left
        jle     outerloop02     ; yes, go
        sub     edx,ecx         ; find new total
        cmp     ecx,4           ; check >= 4 bytes to make dword
        jc      outerloop03     ; no, skip
        push    ecx             ; save count
        shr     ecx,2           ; find dword count
        rep     stosd           ; place
        pop     ecx             ; restore count
        and     ecx,3           ; mask for remainder
outerloop03:
        rep     stosb           ; draw
        movzx   edi,di          ; clear overflow
        add     edi,vidbuf
	inc	ah		; Advance page number
	call	[segvid]
        or      edx,edx         ; check end
        jnz     outerloop01     ; no, loop
        jmp     outerupdate     ; go
outerloop02:
        mov     ecx,edx         ; set remainder as count
        cmp     ecx,4           ; check >= 4 bytes to make dwords
        jc      outerloop04     ; no, skip
        push    ecx             ; save count
        shr     ecx,2           ; find dword count
        rep     stosd           ; place
        pop     ecx             ; restore count
        and     ecx,3           ; mask for remainder
outerloop04:
        rep     stosb           ; draw
        dec     edi             ; Point to last byte drawn
        add     di,bx           ; Point to next line
        jnc     outerupdate     ; go no new page
	inc	ah		; Advance page number
	call	[segvid]
outerupdate:
        pop     ecx             ; restore count
        dec     esi             ; Update counter of lines
        jg      outerloop       ; If not done, go do another line
        pop     edi             ; Restore pointer
        pop     esi             ; Restore line counter
        pop     ax              ; restore starting page number
        call    [segvid]        ; select
        add     di,cx           ; Point to the trailing byte
        jnc     trail           ; go no new page
	inc	ah		; Advance page number
	call	[segvid]

; Draw pixels from the trailing partial byte

trail:
        mov     cl,[lstmsk]     ; Compute number of trailing bits
        or      cl,cl
        jz      endrect
        mov     ebx,[linbyt]    ; Get line to line increment
        mov     al,0ffh         ; Compute mask
        shr     al,cl
        not     al
        mov     dx,03cfh        ; index mask
        out     dx,al           ; Set the mask
        mov     ecx,esi         ; Counter of bytes to do
trailloop:
        mov     al,[edi]        ; Latch data
        mov     [edi],al        ; Set new data
        add     di,bx           ; Point to next line
        jnc     trailloop01     ; go no page
        inc     ah              ; Advance to next page
        call    [segvid]
trailloop01:
        loop    trailloop
        jmp     endrect

; Clean up and return to caller

endrect:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
blockpl endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                             ;
; BLOCK DRAW PACKED                                           ;
;                                                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blockpk proc    syscall
        push    ebp             ; link parameters
        mov     ebp,esp
        push    ebx             ; preserve caller registers
        push    esi
        push    edi
        mov     edi,[ebp+vp]    ; get pointer to viewport record

; convert coordinates and clip

        mov     eax,[ebp+x1]    ; get x1
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y1]    ; get y1
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+x2]    ; get x2
        sub     eax,[edi+viewrsx] ; remove real offset
        imul    dword ptr [edi+viewmx] ; * multiplier
        idiv    dword ptr [edi+viewsx] ; / scale
        add     eax,[edi+viewvsx] ; offset for screen port
        mov     ebx,[edi+viewsx] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        push    eax             ; save
        mov     eax,[ebp+y2]    ; get y2
        sub     eax,[edi+viewrsy] ; remove real offset
        imul    dword ptr [edi+viewmy] ; * multiplier
        idiv    dword ptr [edi+viewsy] ; / scale
        add     eax,[edi+viewvsy] ; offset for screen port
        mov     ebx,[edi+viewsy] ; get scale
        shr     ebx,1           ; / 2
        cmp     ebx,edx         ; check mod > scale / 2
        adc     eax,0           ; round up if so
        mov     edx,eax         ; place parameters
        pop     ecx
        pop     ebx
        pop     eax

; rationalize box

        cmp     eax,ecx         ; check x1 > x2
        jng     blockpk01       ; no, skip
        xchg    eax,ecx         ; else trade
blockpk01:
        cmp     ebx,edx         ; check y1 > y2
        jng     blockpk02       ; no, skip
        xchg    ebx,edx
blockpk02:

; check any part of block lies within clipping area

        cmp     eax,[edi+viewcex] ; check x1 > clip(xe)
        jg      endrect           ; yes, exit
        cmp     ecx,[edi+viewcsx] ; check x2 < clip(xs)
        jl      endrect           ; yes, exit
        cmp     ebx,[edi+viewcey] ; check y1 > clip(ye)
        jg      endrect           ; yes, exit
        cmp     edx,[edi+viewcsy] ; check y2 < clip(ys)
        jl      endrect           ; yes, exit

; clip

        cmp     eax,[edi+viewcsx] ; check x1 < clip(xs)
        jnl     blockpk03       ; no, skip
        mov     eax,[edi+viewcsx] ; clip
blockpk03:
        cmp     ecx,[edi+viewcex] ; check x2 > clip(xe)
        jng     blockpk04       ; no, skip
        mov     ecx,[edi+viewcex] ; clip
blockpk04:
        cmp     ebx,[edi+viewcsy] ; check y1 < clip(ys)
        jnl     blockpk05       ; no, skip
        mov     ebx,[edi+viewcsy] ; clip
blockpk05:
        cmp     edx,[edi+viewcey] ; check y2 > clip(ye)
        jng     blockpk06       ; no, skip
        mov     edx,[edi+viewcey] ; clip
blockpk06:
        mov     [ebp+x1],eax    ; replace with resultant line
        mov     [ebp+y1],ebx
        mov     [ebp+x2],ecx
        mov     [ebp+y2],edx

; Compute address of first pixel (upper left corner), and dimensions

	mov	eax,[ebp+y1]	; Convert (x,y) to Page:Offset
	mul	word ptr [linbyt] ; multiply y by pitch
	mov	ecx,[ebp+x1]	; fetch x
	shr	ecx,1		; convert pixel to byte number
	add	eax,ecx		; add to previous product
        add     eax,vidbuf      ; offset by video base
        mov     edi,eax         ; place in edi
	mov	ah,dl		; Copy page number into ah
	mov	[fstpag],ah	; Save page number for later
	mov	[varseg],ah
	call	[segvid]	; Select proper page

; Compute dimensions

	mov	ecx,[ebp+x2]	; Set counter of bytes to do
	sub	ecx,[ebp+x1]	; as (x2 - x1 + 1)
	inc	ecx
	mov	edx,[ebp+y2]	; Set counter of rasters to do
	sub	edx,[ebp+y1]	; as (y2 - y1 + 1)
	inc	edx

; Load color into all four nibbles of ax

	mov	al,[ebp+clr]	; Fetch color
	mov	ah,al		; Duplicate color in both bytes
	shl	ah,1
	shl	ah,1
	shl	ah,1
	shl	ah,1
	or	ah,al
	mov	al,ah

; Fill leading partial byte (low nibble for x odd) for each row

	test	dword ptr [ebp+x1],1 ; Check if x is odd
	jz	leaddone
	dec	ecx		; Update couter
	push	ecx		; Preserve counter for next two passes
	push	edi		; Preserve address of first pixel
	mov	bl,0f0h 	; Setup mask for destination
	and	al,00fh		; Setup source color
	mov	ecx,edx		; Fetch counter of rows
leadloop:			; Loop over rows
	and	[edi],bl 	; Clear destination bits
	or	[edi],al 	; Set cleared bits to rectangle color
	add	di,word ptr [linbyt] ; Point to next raster
	jc	fixlead	        ; Fix page number if needed
	loop	leadloop	; Check if all raster done
	jmp	leadfilled
fixlead:
	xchg	ah,[varseg]	; Fetch page number, and preserve AL
	inc	ah		; Adjust page number
	call	[segvid]	; Select next page
	xchg	ah,[varseg]	; Save updated page no., restore AL
	loop	leadloop

leadfilled:
	pop	edi		; Restore initial point and counter
	inc	di		; Advance past the lead byte
	pop	ecx
	xchg	ah,[fstpag]	; Select initial page
	mov	[varseg],ah
	call	[segvid]
        xchg    ah,[fstpag]
	mov	al,ah		; Restore color into both bytes
leaddone:
	xor	esi,esi		; Clear SI (to	use ADC later on)
	shr	ecx,1		; Convert pixel count to byte count
	adc	esi,esi		; Keep last bit of CX in SI

; Fill middle strip of the rectangle (full bytes)

	or      ecx,ecx		; Skip middle bytes fill if counter 0
	jz	trail
	push	edx		; Preserve row counter
	mov	ebx,[linbyt]    ; Compute pitch increment
	sub	ebx,ecx
	mov	[pitch],bx
scanloop:
	push	ecx		; Preserve pixel counter

; Fill first page if page boundary may be crossed

	mov	ebx,ecx		; Check if within page
	add	bx,di
	jnc	scaninpage
	sub	ecx,ebx		; Number of bytes to do in this page
	shr	ecx,1		; Adjust for move of words
	rep	stosw		; Write new data
	adc	ecx,ecx
	rep	stosb
        and     edi,00000ffffh  ; keep address in video segment
        or      edi,vidbuf
	mov	ecx,ebx		; Number of bytes to do in next page
	xchg	ah,[varseg]	; Fetch page number, and preserve AL
	inc	ah		; Adjust page number
	call	[segvid]	; Select next page
	xchg	ah,[varseg]	; Save updated page no., restore AL
	jcxz	scandone

; Fill second (or only page)

scaninpage:
	shr	ecx,1		; Adjust for move of words
	rep	stosw		; Write all words of data
	adc	ecx,ecx		; Write the last odd byte of data
	rep	stosb
        and     edi,00000ffffh  ; keep address in video segment
        or      edi,vidbuf
scandone:

	pop	ecx		; Restore counter of bytes in a raster
	add	di,[pitch]	; Compute ptr to byte in next raster
	jc	rectfixpage
	dec	edx		; check if more rasters to do
	jg	scanloop
	jmp	middledone

rectfixpage:
	xchg	ah,[varseg]	; Fetch page number, and preserve AL
	inc	ah		; Update page number
	call	[segvid]	; Compute and select new page number
	xchg	ah,[varseg]	; Save updated page no., restore AL
	dec	edx		; check if more rasters to do
	jg      scanloop

middledone:
	pop	edx		; Restore row counter

; Fill trailing partial byte in each row

trail:
	or	esi,esi		; Check for trailing pixel
	jz	endrect         ; no, exit
	mov	bl,00fh		; Setup mask for destination
	and	al,0f0h 	; Setup source color
	mov	esi,edx		; Save counter of rows
	mov	[ebp+clr],al	; Save color
	mov	eax,[ebp+y1]	; Compute address of last pixel
	mov	ecx,[ebp+x2]	; in the first row
	mul	word ptr [linbyt]
	shr	ecx,1
	add	eax,ecx
        add     eax,vidbuf      ; offset by video base
        mov     edi,eax         ; place in edi
	mov	ah,dl		; Select page
	mov	[varseg],ah
	call	[segvid]
	mov	al,[ebp+clr]	; Fetch pixel color
	mov	ecx,esi		; Fetch counter of rows
trailloop:			; Loop over rows
	and	[edi],bl 	; Clear destination bits
	or	[edi],al 	; Set cleared bits to rectangle color
	add	di,word ptr [linbyt] ; Point to next raster
	jnc	fixtrail	; Fix page number if needed
	mov	ah,[varseg]	; Fetch page number, and preserve AL
	inc	ah		; Adjust page number
	call	[segvid]	; Select next page
	mov	[varseg],ah	; Save updated page no., restore AL
fixtrail:
	loop	trailloop	; Check if all raster done

; Clean up and return to caller

endrect:
        pop     edi             ; restore registers and return
        pop     esi
        pop     ebx
        pop     ebp             ; unlink
        ret
blockpk endp

        .data

vrtinc  dd      0
varir1  dw      0
varir2  dw      0
varseg  db      0
varrot  dd      0
pixarr  dd      0               ; pixel address save

d1	dd      0
d2	dd      0
pitch	dw      0               ; save for line pitch
deltax 	dd      0
fstpag  db      0
fstmsk  db      0
lstmsk  db      0

        end

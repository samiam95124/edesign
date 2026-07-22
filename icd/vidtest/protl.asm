;  protl.asm of 07-Oct-91
;
;  SVS C3 C and MASM example.
;  
;  Called from main program in PMAIN.P
;  Assemble with ML -c -Cx PROTL.ASM

        .386
        .MODEL  small, c

rotl    PROTO C value:DWORD, shift:SWORD
        .CODE

rotl    PROC  C value:DWORD, shift:SWORD
        push    ecx            ; Preserve ecx
        mov     eax, value     ; Load Arg1 into AX
        mov     cx, shift      ; Load Arg2 into CX
        rol     eax, cl        ; Do actual rotation
        pop     ecx            ; Restore ecx
                               ; Leave return value in AX
        ret
rotl    ENDP
        END

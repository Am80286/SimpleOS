[section .data]
; Unreal Mode GDT

UNRAEL_CODE_SEG                                         equ         UNREAL_GDT_CODE - UNREAL_GDT_START
UNREAL_FLAT_SEG                                         equ         UNREAL_GDT_FLAT - UNREAL_GDT_START

UNREAL_GDT_START:
    dq 0x0

UNREAL_GDT_CODE:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 00000000b
    db 0

UNREAL_GDT_FLAT:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0

UNREAL_GDT_END:

UNREAL_PMODE_GDT_DESCRIPTOR:
    dw UNREAL_GDT_END - UNREAL_GDT_START - 1
    dd UNREAL_GDT_START

[bits 16]
[section .text]

[global INIT_UNREAL]
    INIT_UNREAL:
        cli
        push es
        push ds

        lgdt [UNREAL_PMODE_GDT_DESCRIPTOR]

        mov  eax, cr0          ; switch to pmode by
        or al, 1                ; set pmode bit
        mov  cr0, eax
        jmp UNRAEL_CODE_SEG:.pmode

    .pmode:
        mov  bx, UNREAL_FLAT_SEG          ; select descriptor 2
        mov  ds, bx            ; 10h = 10000b
        mov  es, bx
        mov  fs, bx
        mov  gs, bx

        and al, 0xfe            ; back to realmode
        mov  cr0, eax          ; by toggling bit again
        jmp 0x0:.unreal

    .unreal:
        pop ds
        pop es
        sti

        retf
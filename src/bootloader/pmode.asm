[SECTION .data]

    CODE_SEG                                            equ         GDT_CODE - GDT_START
    DATA_SEG                                            equ         GDT_DATA - GDT_START

GDT_START:
    dq 0x0

GDT_CODE:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10011010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

; data segment descriptor
GDT_DATA:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10010010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

GDT_END:

GDT_DESCRIPTOR:

    dw GDT_END - GDT_START - 1 ; size (16 bit)
    dd GDT_START ; address (32 bit)

GDT_DESCRIPTOR_END:

[bits 16]
[SECTION .text]
    INIT_32:
        cli
        lgdt [GDT_DESCRIPTOR]
        mov eax, cr0
        or eax, 0x1
        mov cr0, eax
        jmp CODE_SEG:.init_pmode

[bits 32]
    .init_pmode:
        mov ax, DATA_SEG
        mov ds, ax
        mov ss, ax
        mov es, ax
        mov fs, ax
        mov gs, ax

        ret

;
;
;      _____            __    ____  ____
;     / __(_)_ _  ___  / /__ / __ \/ __/
;    _\ \/ /  ' \/ _ \/ / -_) /_/ /\ \  
;   /___/_/_/_/_/ .__/_/\__/\____/___/  
;              /_/                      
;
;
;
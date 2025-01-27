[bits 16]
[section .text]
    INIT_UNREAL:
        cli
        push ds

        lgdt [UNREAL_PMODE_GDT_DESCRIPTOR]

        mov  eax, cr0          ; switch to pmode by
        or al, 1                ; set pmode bit
        mov  cr0, eax
        jmp 0x8:.pmode

    .pmode:
        mov  bx, 0x10          ; select descriptor 2
        mov  ds, bx            ; 10h = 10000b

        and al, 0xfe            ; back to realmode
        mov  cr0, eax          ; by toggling bit again
        jmp 0x0:.unreal

    .unreal:
        pop ds
        sti

        retf
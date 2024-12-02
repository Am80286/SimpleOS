[SECTION .data]
    LINUX_ZIMAGE_BOOTSEC_ADDR                           equ         0x90000      ; from the Linux x86 Boot Protocl specification
    LINUX_ZIMAGE_SETUP_ADDR                             equ         0x90200      ; from the spec as well
    LINUX_ZIMAGE_MAIN_ADDR                              equ         0x10000     ; from the spec as well
    LINUX_ZIMAGE_LOW_LOAD_ADDR                          equ         0x10000     ; from the spec as well

    LINUX_ZIMAGE_LOW_BUFFER_SEG                         equ         0x1000
    LINUX_ZIMAGE_HIGH_BUFFER_ADDR                       equ         0x200000

[bits 16]
[SECTION .text]
    LINUX_16_LOAD: ; must be called form the main loader.asm
        pop si     ; I mighr relocate this to loader.asm, but I'm not sure
        add si, 64 ; get the kernel path
        call LOAD_ZIMAGE_FILE

    LOAD_ZIMAGE_FILE: ; DS:SI - file path
        pusha

        mov dx, LINUX_ZIMAGE_LOW_BUFFER_SEG
        xor bx, bx
        call READ_FILE_BY_PATH

    .move_file_to_high_buffer:
        mov ecx, dword[FILE_SIZE]
        shr ecx, 2 ; divide by 4, because we're moving data in 4 byte chunks
        mov esi, edx
        shl esi, 4 ; multiply bu 16 to convert the segment to an absolute address
        mov edi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR

        db 0x67     ; adress size override
        rep movsd   

    .load_setup:
        ; calcuating setup size
        mov esi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR
        xor eax, eax
        mov al, byte[esi + 0x1f1]
        mov bx, word[BPB_BytesPerSec]
        mul bx
        push ax
        shr ax, 2
        xor ecx, ecx
        mov ecx, eax

        ; calculating the setup address in the high memory buffer
        pop ax
        add ax, word[BPB_BytesPerSec]
        add esi, eax
        mov edi, LINUX_ZIMAGE_SETUP_ADDR
        db 0x67 ; adress size override prefix
        rep movsd

    .load_kernel_bulk:
        mov esi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR

        .a
        mov ax, 0x0e01
        int 10h
        jmp $

        


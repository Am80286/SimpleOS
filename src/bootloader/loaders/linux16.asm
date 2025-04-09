%include "fatfs.inc"

LINUX_ZIMAGE_BOOTSEC_ADDR                           equ         0x90000      ; from the Linux x86 Boot Protocl specification
LINUX_ZIMAGE_SETUP_ADDR                             equ         0x90200      ; from the spec as well
LINUX_ZIMAGE_SETUP_SEG                              equ         0x9020      ; from the spec as well
LINUX_ZIMAGE_MAIN_ADDR                              equ         0x00100000     ; from the spec as well

LINUX_ZIMAGE_LOW_BUFFER_SEG                         equ         0x2000
LINUX_ZIMAGE_HIGH_BUFFER_ADDR                       equ         0x200000

[bits 16]
[section .text]

[global LINUX_16_LOAD]
    LINUX_16_LOAD: ; must be called form the main loader.asm
        pop si     ; I mighr relocate this to loader.asm, but I'm not sure
        add si, 64 ; get the kernel path
        call LOAD_ZIMAGE_FILE

    LOAD_ZIMAGE_FILE: ; DS:SI - file path
        pusha

        mov dx, LINUX_ZIMAGE_LOW_BUFFER_SEG
        xor bx, bx
        call LOAD_FILE_BY_PATH

    .move_file_to_high_buffer:
        mov ecx, dword[FILE_SIZE]
        shr ecx, 2 ; divide by 4, because we're moving data in 4 byte chunks
        mov esi, edx
        shl esi, 4 ; multiply bu 16 to convert the segment to an absolute address
        mov edi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR

        db 0x67     ; adress size override
        rep movsd

    .load_bootsec:
        mov esi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR
        mov edi, LINUX_ZIMAGE_BOOTSEC_ADDR
        mov cx, word[BPB_BytesPerSec]
        shr ecx, 2

        db 0x67     ; adress size override prefix
        rep movsd

    .load_setup:
        ; calcuating setup size
        mov esi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR
        xor eax, eax
        mov al, byte[esi + 0x1f1]
        mov bx, word[BPB_BytesPerSec]
        mul bx
        push eax
        shr ax, 2
        mov ecx, eax

        ; calculating the setup address in the high memory buffer

        xor ebx, ebx
        mov bx, word[BPB_BytesPerSec]
        add esi, ebx
        mov edi, LINUX_ZIMAGE_SETUP_ADDR

        push esi
        db 0x67 ; adress size override prefix
        rep movsd

        mov dword[LINUX_ZIMAGE_BOOTSEC_ADDR + 0x214], LINUX_ZIMAGE_MAIN_ADDR

    .load_kernel_bulk:
        mov esi, LINUX_ZIMAGE_HIGH_BUFFER_ADDR
        mov ecx, dword[esi + 0x1f4]
        shl ecx, 2

        pop esi
        pop eax
        add esi, eax

        mov edi, LINUX_ZIMAGE_MAIN_ADDR

        db 0x67 ; adress size override prefix
        rep movsd

    .jump_to_setup:
    
        push LINUX_ZIMAGE_SETUP_SEG
        push word 0
        retf
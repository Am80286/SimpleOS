%include "fatfs.inc"
%include "error.inc"

READ_LBA_LOW_BUFFER_SEG                             equ         0x1000

[bits 16]
[section .text]

[global READ_LBA_EXTENDED]
    READ_LBA_EXTENDED: ; same as READ_LBA, but can read into extended memory (uses unreal mode)
        pushad
        push cx  ; CX - amount of sectors to read
        push ebx ; ES:EBX - buffer
        push ax  ; AX - LBA 

        mov ax, word[BPB_Heads]
        mul word[BPB_SecPerTrack]
        mov bx, ax
        pop ax
        xor dx, dx
        div bx ; At this moment AX is Cylinder DX is temp

        push ax

        mov ax, dx
        xor dx, dx
        div word[BPB_SecPerTrack]
        inc dx ; At this moment AX is head DX is sector

        mov cx, dx ; CL - sector
        xor dx, dx
        mov dh, al ; DH - head

        pop bx  
        mov ch, bl ; CH - cylinder

        pop edi
        pop ax

        push es
        mov bx, READ_LBA_LOW_BUFFER_SEG
        mov es, bx
        xor bx, bx
        mov ah, 0x02
        mov dl, [BOOT_DISK]

        int 13h
        jc LBA_READ_ERROR
        pop es

        mov esi, READ_LBA_LOW_BUFFER_SEG
        shl esi, 4

        xor ebx, ebx
        mov bl, al
        xor eax, eax
        mov ax, word[BPB_BytesPerSec]
        mul ebx
        shr eax, 2
        mov ecx, eax

        db 0x67 ; adress sie override prefix
        rep movsd

    .done:
        popad
        ret

[global READ_LBA]
    READ_LBA:
        pusha
        push cx ; CX - amount of sectors to read
        push bx ; ES:BX - buffer
        push ax ; AX - LBA 

        mov ax, word[BPB_Heads]
        mul word[BPB_SecPerTrack]
        mov bx, ax
        pop ax
        xor dx, dx
        div bx ; At this moment AX is Cylinder DX is temp

        push ax

        mov ax, dx
        xor dx, dx
        div word[BPB_SecPerTrack]
        inc dx ; At this moment AX is head DX is sector

        mov cx, dx ; CL - sector
        xor dx, dx
        mov dh, al ; DH - head

        pop bx  
        mov ch, bl ; CH - cylinder

        pop bx
        pop ax
        mov ah, 0x02
        mov dl, [BOOT_DISK]
        
        int 13h
        jc LBA_READ_ERROR

    .done:
        popa
        ret

[global WRITE_LBA]
    WRITE_LBA:
        pusha
        push cx ; CX - amount of sectors to read
        push bx ; ES:BX - buffer
        push ax ; AX - LBA 

        mov ax, word[BPB_Heads]
        mul word[BPB_SecPerTrack]
        mov bx, ax
        pop ax
        xor dx, dx
        div bx ; At this moment AX is Cylinder DX is temp

        push ax

        mov ax, dx
        xor dx, dx
        div word[BPB_SecPerTrack]
        inc dx ;At this moment AX is head DX is sector

        mov cx, dx ; CL - sector
        xor dx, dx
        mov dh, al ; DH - head

        pop bx  
        mov ch, bl ; CH - cylinder

        pop bx
        pop ax
        mov ah, 0x03
        mov dl, [BOOT_DISK]
        
        int 13h
        jc CRIT_ERROR

    .done:
        popa
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
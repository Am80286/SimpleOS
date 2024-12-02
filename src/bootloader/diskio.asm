[bits 16]
[SECTION .text]
    READ_LBA_EXTENDED: ; same as READ_LBA, but can read into extended memory (uses unreal mode)
        pusha
        push cx ; CX - amount of sectors to read
        push ax ; AX - LBA 
                ; 0:EBX - buffer

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

        pop ax
        mov ah, 0x02
        mov dl, [BOOT_DISK]
        
        int 13h
        jc CRIT_ERROR

    .done:
        popa
        ret

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
        jc CRIT_ERROR

    .done:
        popa
        ret

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
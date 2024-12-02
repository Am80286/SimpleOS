[SECTION .data]
    FILE_CLUSTER                                        dw          0
    FILE_SIZE                                           dd          0

[bits 16]
[SECTION .text]
    READ_FILE_BY_PATH: ; DS:SI - pointer to a file path string (unix style), DX:BX - load adress, ES must equal DS
        pusha

        push es
        mov es, dx
        mov di, bx
        call LOAD_ROOT_DIR
        pop es

        mov di, FILE_NAME_BUFFER

    .get_next_dir:
        push di
        mov cx, 32

    .zero_out_buffers:
        mov al, 0
        stosb
        dec cx
        cmp cx, 0
        jne .zero_out_buffers
        
        pop di

    .read_string_bytes:
        lodsb
        
        cmp al, '/'
        je .read_dir
        cmp al, 0
        je .read_final_file
    
        stosb

        jmp .read_string_bytes

    .read_final_file:               ; this can definitely be optimized
        mov si, FILE_NAME_BUFFER        ; two almost identical pieces of code for
        mov di, FAT_FILENAME_BUFFER     ; .read_dir and .read_final_file
        call STRING_TO_FAT_FILENAME

        mov si, di
        mov di, bx

        mov ax, 64
        push es
        mov es, dx
        call SEARCH_DIR
        pop es
        jc CRIT_ERROR

        call LOAD_DIR_ENTRY

        jmp .done
        
    .read_dir:
        push si
        mov si, FILE_NAME_BUFFER
        mov di, FAT_FILENAME_BUFFER
        call STRING_TO_FAT_FILENAME

        mov si, di
        mov di, bx

        mov ax, 64     ; This needs to be properly calculated !!!
        push es
        mov es, dx
        call SEARCH_DIR
        pop es
        jc CRIT_ERROR

        call LOAD_DIR_ENTRY

        mov di, FILE_NAME_BUFFER ; returning the filename buffer pointer
        pop si

        jmp .get_next_dir

    .done:
        popa
        ret
        
    INIT_BOOT_DISK:
        pusha

        mov ah, 0x02
        mov al, 1
        xor ch, ch
        xor dh, dh
        mov cl, 1
        mov dl, byte[BOOT_DISK]
        mov bx, DISK_MBR_START
        int 13h

        push es

        xor ax, ax
        mov es, ax
        mov ah, 0x08
        int 13h
        jc CRIT_ERROR
        pop es

        inc dh
        mov [BPB_Heads], dh
        and cl, 0x3f
        xor ch, ch
        mov [BPB_SecPerTrack], cx

        mov ax, [BPB_SecPerFat]
        mov bx, [BPB_FatNum]
        mul bx
        add ax, [BPB_RsvdSecCnt]
        push ax
        mov ax, 32
        mov bx, [BPB_RootEntCnt]
        mul bx
        add ax, [BPB_BytesPerSec]
        dec ax
        mov bx, [BPB_BytesPerSec]
        div bx
        pop bx
        add ax, bx
        mov [DISK_DATA_START_SEC], ax

        popa
        ret

    SEARCH_DIR: ; DS:SI - pointer to name string, ES:DI - pointer to directory, AX - number of entries to check
        pusha
        xor bx, bx
        cld

        .loop:
        mov cx, 11
        push si
        push di
        repe cmpsb
        pop di
        pop si

        je .found

        inc bx
        add di, 32
        cmp bx, ax
        jl .loop

        stc
        jmp .done
        
    .found: ;directory entry pointer is in DI register
        mov ax, word[es:di + 26]
        mov [FILE_CLUSTER], ax
        mov ax, word[es:di + 28]
        mov [FILE_SIZE], ax
        mov ax, word[es:di + 30]
        mov [FILE_SIZE + 2], ax

    .done:
        popa
        ret

    LOAD_ROOT_DIR: ; ES:DI - load adress 
        pusha
        push di
        
        mov al, [BPB_FatNum]
        xor ah, ah
        mov bx, [BPB_SecPerFat]
        mul bx
        add ax, [BPB_RsvdSecCnt]

        push ax ;Root dir start sector
        
        mov ax, [BPB_RootEntCnt],
        shl ax, 5
        xor dx, dx
        div word[BPB_BytesPerSec]

        test dx, dx
        jz .done 
        inc ax

    .done:
        mov cx, ax ;AX - root dir sector count 
        pop ax
        pop bx ; getting load adress from stack
        call READ_LBA

        popa
        ret

    LOAD_DIR_ENTRY: ; FILE_CLUSTER - first cluster of a directory entry, DX:BX - load adress
        pusha
        push es
        push dx

    .loop:
        pop ax
        mov es, ax
        push ax

        xor ch, ch
        mov cl, byte[BPB_SecPerClus]
        mov ax, word[FILE_CLUSTER]
        sub ax, 2
        mul cx
        add ax, [DISK_DATA_START_SEC]

        call READ_LBA

        mov ax, word[BPB_BytesPerSec]
        xor dh, dh
        mov dl, byte[BPB_SecPerClus]
        mul dx
        add bx, ax

        cmp bx, 0
        jne .read_fat ; if end of the current segment is reached
        pop ax
        add ax, 0x1000  ; switch the segment
        push ax

    .read_fat:
        push bx

        xor dx, dx
        mov ax, word[FILE_CLUSTER]
        shl ax, 1
        mov bx, word[BPB_BytesPerSec]
        div bx
        add ax, word[BPB_RsvdSecCnt]
        mov bx, BUFFER_SEG
        mov es, bx
        xor bx, bx
        mov cx, 1

        call READ_LBA

        mov si, dx
        mov ax, word[es:si]

    .after_next_clus:
        cmp ax, 0xFFF8
        pop bx
        jae .done

        mov word[FILE_CLUSTER], ax
        jmp .loop

    .done:
        pop dx
        pop es
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
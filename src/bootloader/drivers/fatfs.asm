[bits 16]
[section .text]
    LOAD_FILE_BY_PATH_EXTENDED:     ; DS:SI - pointer to a file path string (unix style), DX:EBX - load adress, ES must equal DS
        pushad                      ; yet another reimplementation for loading stuff into high memory

        push es
        mov es, dx
        mov edi, ebx
        call LOAD_ROOT_DIR_EXTENDED
        pop es

        mov di, FILE_NAME_BUFFER

    .get_next_dir:
        push di
        mov cx, 32

    .zero_out_buffers:
        xor al, al
        stosb
        dec cx
        test cx, cx
        jnz .zero_out_buffers
        
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
        mov esi, FILE_NAME_BUFFER        ; two almost identical pieces of code for
        mov edi, FAT_FILENAME_BUFFER     ; .read_dir and .read_final_file
        call STRING_TO_FAT_FILENAME

        mov esi, edi
        mov edi, ebx

        mov ax, 0xffff
        push es
        mov es, dx
        call SEARCH_DIR_EXTENDED
        pop es
        jc FILE_NOT_FOUND_ERROR

        call LOAD_DIR_ENTRY_EXTENDED

        jmp .done
        
    .read_dir:
        push esi
        mov esi, FILE_NAME_BUFFER
        mov edi, FAT_FILENAME_BUFFER
        call STRING_TO_FAT_FILENAME

        mov esi, edi

        mov edi, ebx

        mov ax, 0xffff
        push es
        mov es, dx

        call SEARCH_DIR_EXTENDED
        pop es
        jc FILE_NOT_FOUND_ERROR

        call LOAD_DIR_ENTRY_EXTENDED

        mov edi, FILE_NAME_BUFFER ; returning the filename buffer pointer
        pop esi

        jmp .get_next_dir

    .done:
        popad
        ret

    LOAD_FILE_BY_PATH: ; DS:SI - pointer to a file path string (unix style), DX:BX - load adress, ES must equal DS
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
        test cx, cx
        jnz .zero_out_buffers
        
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

        mov ax, 0xffff
        push es
        mov es, dx
        call SEARCH_DIR
        pop es
        jc FILE_NOT_FOUND_ERROR

        call LOAD_DIR_ENTRY

        jmp .done
        
    .read_dir:
        push si
        mov si, FILE_NAME_BUFFER
        mov di, FAT_FILENAME_BUFFER
        call STRING_TO_FAT_FILENAME

        mov si, di
        mov di, bx

        mov ax, 0xffff
        push es
        mov es, dx
        call SEARCH_DIR
        pop es
        jc FILE_NOT_FOUND_ERROR

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
        jc DRIVE_INIT_ERROR
        pop es

        inc dh
        mov [BPB_Heads], dh
        and cl, 0x3f
        xor ch, ch
        mov [BPB_SecPerTrack], cx

        mov ax, [BPB_SecPerFat]
        xor bh, bh
        mov bl, [BPB_FatNum]
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

    ; Determining the filesystem type

        mov ax, word[BPB_TotalSecCnt16]
        test ax, ax
        jz .use32_bit_value
        
        xor dx, dx
        sub ax, word[DISK_DATA_START_SEC]
        xor bx, bx
        mov bl, byte[BPB_SecPerClus]
        div bx

        jmp .check_type

    .use32_bit_value:
        ; Gotta implemet that only using 16 bit registers for compatibilty
        xor edx, edx 
        mov eax, dword[BPB_TotSecCnt32]
        xor ebx, ebx
        mov bx, word[DISK_DATA_START_SEC]
        sub eax, ebx
        xor ebx, ebx
        mov bl, byte[BPB_SecPerClus]
        div ebx

    .check_type:
        cmp ax, 4085
        jbe .type_fat12
        cmp ax, 65525
        jbe .type_fat16
        ja .type_fat32

    .type_fat12:
        mov byte[DISK_FS_TYPE], 0x01
        jmp .done

    .type_fat16:
        mov byte[DISK_FS_TYPE], 0x02
        jmp .done

    .type_fat32:
        mov byte[DISK_FS_TYPE], 0x03

    .done:
        popa
        ret

    SEARCH_DIR_EXTENDED:  ; DS:ESI - pointer to name string, ES:EDI - pointer to directory, AX - number of entries to check
        pushad            ; same as SEARCH_DIR but works with high memory
        xor bx, bx
        cld

        .loop:
        mov ecx, 11
        push esi
        push edi
        db 0x67 ; adress size override prefix
        repe cmpsb
        pop edi
        pop esi

        je .found

        inc bx
        add edi, 32
        cmp bx, ax
        jb .loop

        stc
        jmp .done
        
    .found: ;directory entry pointer is in DI register
        mov ax, word[es:edi + 26]
        mov [FILE_CLUSTER], ax
        mov eax, dword[es:edi + 28]
        mov [FILE_SIZE], eax

    .done:
        popad
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
        jb .loop

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

    LOAD_ROOT_DIR_EXTENDED: ; ES:EDI - load adress 
        pushad
        push edi
        
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
        pop ebx ; getting load adress from stack
        call READ_LBA_EXTENDED

        popad
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
        mov es, dx

    .loop:
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

        test bx, bx
        jnz .read_fat   ; If end of the current segment is reached
        mov ax, es      ; get the current value of the segment
        add ax, 0x1000  ; switch the segment
        mov es, ax

    ; Okay so this might look little complex, but all it does is it chooses the read algoritm based on the fat type

    .read_fat:
        cmp byte[DISK_FS_TYPE], 0x01
        je .fat12
        cmp byte[DISK_FS_TYPE], 0x02
        je .fat16

        jmp CRIT_ERROR

        .fat16:
            push bx
            push es

            xor dx, dx
            mov ax, word[FILE_CLUSTER]
            shl ax, 1
            div word[BPB_BytesPerSec]
            add ax, word[BPB_RsvdSecCnt]
            mov cx, 1

            mov bx, BOOTLOADER_DS
            mov es, bx
            mov bx, FAT_SECTOR_BUFFER_POINTER

            cmp ax, word[PREVIOUS_FAT_SECTOR]
            je .skip16

            call READ_LBA
            mov word[PREVIOUS_FAT_SECTOR], ax

        .skip16:
            add dx, bx
            mov si, dx
            mov ax, word[es:si]

            pop es
            pop bx

            cmp ax, 0xFFF8
            jae .done

            jmp .after_next_clus

        .fat12:
            push bx
            push es

            mov ax, word[FILE_CLUSTER]
            mov dx, ax
            shr ax, 1
            add ax, dx
            xor dx, dx
            div word[BPB_BytesPerSec]
            add ax, word[BPB_RsvdSecCnt]
            mov cx, 1

            mov bx, BOOTLOADER_DS
            mov es, bx
            mov bx, FAT_SECTOR_BUFFER_POINTER

            cmp ax, word[PREVIOUS_FAT_SECTOR]
            je .skip12
        
            call READ_LBA
            mov word[PREVIOUS_FAT_SECTOR], ax

        .skip12:
            add dx, bx
            mov si, dx
            mov ax, word[es:si]

            test word[FILE_CLUSTER], 1
            jz .even

        .odd:
            shr ax, 4
            jmp .next_clus

        .even:
            and ax, 0xfff

        .next_clus:
            pop es
            pop bx

            cmp ax, 0xff8
            jae .done

    .after_next_clus
        mov word[FILE_CLUSTER], ax
        jmp .loop

    .done:
        pop es
        popa
        ret

LOAD_DIR_ENTRY_EXTENDED: ; FILE_CLUSTER - first cluster of a directory entry, DX:EBX - load adress
        pushad
        push es
        mov es, dx

    .loop:
        xor ch, ch
        mov cl, byte[BPB_SecPerClus]
        mov ax, word[FILE_CLUSTER]
        sub ax, 2
        mul cx
        add ax, [DISK_DATA_START_SEC]

        call READ_LBA_EXTENDED

        xor eax, eax
        mov ax, word[BPB_BytesPerSec]
        xor dh, dh
        mov dl, byte[BPB_SecPerClus]
        mul dx
        add ebx, eax

        test ebx, ebx
        jnz .read_fat   ; If end of the current segment is reached
        mov ax, es      ; get the current value of the segment
        add ax, 0x1000  ; switch the segment
        mov es, ax

    ; Okay so this might look little confusing, but all it does is it chooses the read algoritm based on the fat type

    .read_fat:
        cmp byte[DISK_FS_TYPE], 0x01
        je .fat12
        cmp byte[DISK_FS_TYPE], 0x02
        je .fat16

        jmp CRIT_ERROR

        .fat16:
            push es
            push ebx

            xor edx, edx
            mov ax, word[FILE_CLUSTER]
            shl ax, 1
            div word[BPB_BytesPerSec]
            add ax, word[BPB_RsvdSecCnt]
            mov cx, 1

            xor ebx, ebx
            mov bx, BOOTLOADER_DS
            mov es, bx
            mov bx, FAT_SECTOR_BUFFER_POINTER

            cmp ax, word[PREVIOUS_FAT_SECTOR]
            je .skip16

            call READ_LBA
            mov word[PREVIOUS_FAT_SECTOR], ax

        .skip16:
            add edx, ebx
            mov esi, edx
            mov ax, word[es:esi]

            pop ebx
            pop es

            cmp ax, 0xFFF8
            jae .done

            jmp .after_next_clus

        .fat12:
            push es
            push ebx

            xor edx, edx
            mov ax, word[FILE_CLUSTER]
            mov dx, ax
            shr ax, 1
            add ax, dx
            xor dx, dx
            div word[BPB_BytesPerSec]
            add ax, word[BPB_RsvdSecCnt]
            mov cx, 1

            xor ebx, ebx
            mov bx, BOOTLOADER_DS
            mov es, bx
            mov bx, FAT_SECTOR_BUFFER_POINTER

            cmp ax, word[PREVIOUS_FAT_SECTOR]
            je .skip12

            call READ_LBA
            mov word[PREVIOUS_FAT_SECTOR], ax

        .skip12:
            add edx, ebx
            mov esi, edx
            mov ax, word[es:esi]

            test word[FILE_CLUSTER], 1
            jz .even

        .odd:
            shr ax, 4
            jmp .next_clus

        .even:
            and ax, 0xfff

        .next_clus:
            pop ebx
            pop es

            cmp ax, 0xff8
            jae .done

    .after_next_clus
        mov word[FILE_CLUSTER], ax
        jmp .loop

    .done:
        pop es
        popad
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
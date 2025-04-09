%include "diskio.inc"
%include "stringlib.inc"
%include "error.inc"
%include "system.inc"

FAT_SECTOR_BUFFER_POINTER                           equ         end

[section .data]

[global BPB_BytesPerSec]
[global BPB_Heads]
[global BPB_SecPerTrack]
DISK_MBR_START:

    times 3                                             db          0xff
    BS_OEMName                                          db          "MSWIN4.1"
    BPB_BytesPerSec                                     dw          512
    BPB_SecPerClus                                      db          16
    BPB_RsvdSecCnt                                      dw          16
    BPB_FatNum                                          db          2
    BPB_RootEntCnt                                      dw          512
    BPB_TotalSecCnt16                                   dw          0
    BPB_Media_Desc_Type                                 db          0xf8
    BPB_SecPerFat                                       dw          256
    BPB_SecPerTrack                                     dw          63
    BPB_Heads                                           dw          32
    BPB_HiddenSectors                                   dd          0
    BPB_TotSecCnt32                                     dd          1048576

    EBR_BootDrvNumber                                   db          0
                                                        db          0
    EBR_Signature                                       db          0x29
    EBR_VolumeId                                        db          0xFF, 0xFF,0xFF, 0xFF
    EBR_VolumeLbl                                       db          "NO NAME "
    EBR_SysId                                           db          "FAT16   "
    times 512 - 59                                      db          0            ; (0_0)

DISK_MBR_END:

[global BOOT_DISK]
    BOOT_DISK                                           db          0

    PREVIOUS_FAT_SECTOR                                 dw          0
    DISK_DATA_START_SEC                                 dw          0

[global FILE_SIZE]
    FILE_SIZE                                           dd          0

    FILE_CLUSTER                                        dw          0

    ; A variable that describes the filesystem type
    ; 0x01 - FAT 12
    ; 0x02 - FAT 16
    ; 0x03 - FAT 32
    DISK_FS_TYPE                                        db          0

    FILE_NAME_BUFFER times 16                           db          0
    FAT_FILENAME_BUFFER times 16                        db          0

[bits 16]
[section .text]
    ; This is a function made for reading a file by it's absoulte unix style path.
    ; Works both with low and high memory, pretty much a hybrid of the old 
    ; LOAD_FILE_BY_PATH and LOAD_FILE_BY_PATH_EXTENEDED.
    ; DS:SI - pointer to a file path string (unix style), DX:EBX - load adress, ES must equal DS

[global LOAD_FILE_BY_PATH]
    LOAD_FILE_BY_PATH:
        pushad

        mov di, FILE_NAME_BUFFER

        cmp byte[ds:si], '/'
        jne .get_next_dir

        inc si ; skip the first /

        cmp ebx, 0x10000
        jae .extended

        call LOAD_ROOT_DIR
        jmp .get_next_dir

    .extended
        call LOAD_ROOT_DIR_EXTENDED
    
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
        call SEARCH_DIR
        pop es
        jc FILE_NOT_FOUND_ERROR

        call LOAD_DIR_ENTRY

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

        call SEARCH_DIR
        pop es
        jc FILE_NOT_FOUND_ERROR

        call LOAD_DIR_ENTRY

        mov edi, FILE_NAME_BUFFER ; returning the filename buffer pointer
        pop esi

        jmp .get_next_dir

    .done:
        popad
        ret
        
[global INIT_BOOT_DISK]
    INIT_BOOT_DISK: ; DL - boot disk number
        pusha

        mov byte[BOOT_DISK], dl

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

    SEARCH_DIR:  ; DS:ESI - pointer to name string, ES:EDI - pointer to directory, AX - number of entries to check
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

    LOAD_ROOT_DIR_EXTENDED: ; DX:EBX - load adress 
        pushad
        push es
        push ebx

        mov es, dx
        
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

        pop es
        popad
        ret

    LOAD_ROOT_DIR: ; ES:BX - load adress 
        pusha
        push es
        push bx

        mov es, dx

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

        pop es
        popa
        ret

    LOAD_DIR_ENTRY: ; FILE_CLUSTER - first cluster of a directory entry, DX:BX - load adress
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

        cmp ebx, 0x10000 ; Check if we need to use READ_LBA_EXTENDED
        jae .extended

        call READ_LBA
        jmp .offsetts

    .extended:
        call READ_LBA_EXTENDED

    .offsetts:
        xor eax, eax
        mov ax, word[BPB_BytesPerSec]
        xor dh, dh
        mov dl, byte[BPB_SecPerClus]
        mul dx
        add ebx, eax

        cmp ebx, 0x10000
        jae .read_fat

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
            push ebx
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
            pop ebx

            cmp ax, 0xFFF8
            jae .done

            jmp .after_next_clus

        .fat12:
            push ebx
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
            pop ebx

            cmp ax, 0xff8
            jae .done

    .after_next_clus:
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
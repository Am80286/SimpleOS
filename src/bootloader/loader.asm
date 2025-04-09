;    This file is part of SimpleOS.
;
;    SimpleOS is free software: you can redistribute it and/or modify it under the terms of the 
;    GNU General Public License as published by the Free Software Foundation, either version 3 
;    of the License, or (at your option) any later version.
;
;    SimpleOS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
;    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
;    See the GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License along with SimpleOS. 
;    If not, see <https://www.gnu.org/licenses/>.

%include "screen.inc"
%include "pcspk.inc"
%include "fatfs.inc"
%include "unreal.inc"
%include "gate_a20.inc"
%include "linux16.inc"
%include "system.inc"
%include "stringlib.inc"
%include "error.inc"

VAR_TABLE_TERMINATOR                                equ         0xFC88

KERNEL_TABLE_TERMINATOR                             equ         0xFC99
KERNEL_ENTRY_SIZE                                   equ         139     ; TODO: make auto detection for this value
KERNEL_ENTRY_SIG                                    equ         0

CONFIG_FILE_POINTER                                 equ         end + 512 ; +512 because this is a buffer for FAT sectors

;[org 0x8000]
[section .data]
    ; no memory manager so the spcae for the mbr has to preallocated here
    ; all the values are placeholders and get overwritten

    BOOT_BEEP_ENABLE                                    db          0
    BOOT_STRING_COLOR                                   db          0x1f ; BIOS color attribute https://en.wikipedia.org/wiki/BIOS_color_attributes
    BOOT_WAIT_TIME                                      db          5
    BOOT_CLEAR_SCREEN                                   db          0
    AUTOBOOT_ENTRY                                      db          0

    BANNER                                              db          "-================================-", " SimpleBoot ", "-======================= ", "v0.1", " ===-", 0
    BOOT_MENU_MSG                                       db          ENDL, RETC, "  Available Kernels:", ENDL, RETC, ENDL, RETC, 0
    INVALID_INPUT_MSG                                   db          "Invald input!", 0
    BOOTING_KERNEL_MSG                                  db          "Booting selected kernel...", 0
    KENREL_PATH_MSG                                     db          ENDL, RETC, "  Path: ", 0

    LOADING_MSG                                         db          "Loading.....", 0
    
    CONFIG_MENU_ENTRY_DECLARATOR                        db          "menu_entry_start:"

    BOOT_CONFIG_FILE_PATH                               db          "/boot/boot.cfg", 0
    BOOT_BANNER_FILE_PATH times 64                      db          0

    KERNEL_TABLE_POINTER                                dw          0
    KERNEL_ENTRY_COUNTER                                dw          0

; Variable types:
; 0x01 - hex word
; 0x02 - hex byte
; 0x03 - dec word
; 0x04 - dec byte
; 0x05 - string
; 0x06 - bool
; 0x07 - hex dword

 ;Kernel entry structure: size 139 bytes

; KERNEL_NAME times 64                              db          0
; KERNEL_PATH times 64                              db          0
; KERNEL_LOAD_SEG                                   dw          0
; KERNEL_LOAD_OFF                                   dw          0
; KENREL_PROTECTED_MODE                             db          0 bool
; KERNEL_LINUX16                                    db          0 bool
; KERNEL_DEFAULT                                    db          0 bool
; KENREL_LOAD_ADDR                                  dd          0

VAR_TABLE_CURRENT_POINTER                               dw          VAR_TABLE_START

VAR_TABLE_START:

    VAR_BOOT_STRING_COLOR_NAME                          db          "boot_string_color", 0
    VAR_BOOT_STRING_COLOR_TYPE                          db          0x02
    VAR_BOOT_STRING_COLOR_POINTER                       dw          BOOT_STRING_COLOR

    VAR_BOOT_WAIT_TIME                                  db          "boot_wait_time", 0
    VAR_BOOT_WAIT_TIME_TYPE                             db          0x04
    VAR_BOOT_WAIT_TIME_POINTER                          dw          BOOT_WAIT_TIME

    VAR_BOOT_BANNER_PATH_NAME                           db          "boot_banner_path", 0
    VAR_BOOT_BANNER_PATH_TYPE                           db          0x05
    VAR_BOOT_BANNER_PATH_POINTER                        dw          BOOT_BANNER_FILE_PATH

    VAR_MENU_NAME                                       db          "menu_name", 0
    VAR_MENU_NAME_TYPE                                  db          0x05
    VAR_MENU_NAME_POINTER                               dw          0

    VAR_KERNEL_PATH_NAME                                db          "kernel_path", 0
    VAR_KERNEL_PATH_TYPE                                db          0x05
    VAR_KERNEL_PATH_POINTER                             dw          0

    VAR_KERNEL_OFF_NAME                                 db          "load_off", 0
    VAR_KERNEL_OFF_TYPE                                 db          0x01
    VAR_KERNEL_OFF_POINTER                              dw          0

    VAR_KERNEL_SEG_NAME                                 db          "load_seg", 0
    VAR_KERNEL_SEG_TYPE                                 db          0x01
    VAR_KERNEL_SEG_POINTER                              dw          0

    VAR_KERNEL_DEFAULT_NAME                             db          "mmap_enable", 0
    VAR_KERNEL_DEFAULT_TYPE                             db          0x06
    VAR_KERNEL_DEFAULT_POINTER                          dw          0

    VAR_KERNEL_PMODE_NAME                               db          "protected_mode", 0
    VAR_KERNEL_PMODE_TYPE                               db          0x06
    VAR_KERNEL_PMODE_POINTER                            dw          0

    VAR_KERNEL_LINUX_16_NAME                            db          "linux16", 0
    VAR_KERNEL_LINUX_16_TYPE                            db          0x06
    VAR_KERNEL_LINUX_16_POINTER                         dw          0

    VAR_KERNEL_LOAD_ADDR_NAME                           db          "load_addr", 0
    VAR_KERNEL_LOAD_ADDR_TYPE                           db          0x07
    VAR_KENREL_LOAD_ADDR_POINTER                        dw          0

    VAR_BOOT_BEEP_ENABLE_NAME                           db          "boot_beep_enable", 0
    VAR_BOOT_BEEP_TYPE                                  db          0x06
    VAR_BOOT_BEEP_POINTER                               dw          BOOT_BEEP_ENABLE

    VAR_BOOT_CLEAR_SCREEN_NAME                          db          "clear_screen_after_boot", 0
    VAR_BOOT_CLEAR_SCREEN_TYPE                          db          0x06
    VAR_BOOT_CLEAR_SCREEN_POINTER                       dw          BOOT_CLEAR_SCREEN

    VAR_AUTOBOOT_ENTRY_NAME                             db          "autoboot_entry", 0
    VAR_AUTOBOOT_ENTRY_TYPE                             db          0x04
    VAR_AUTOBOOT_ENTRY_POINTER                          dw          AUTOBOOT_ENTRY

VAR_TABLE_END:                                          dw          VAR_TABLE_TERMINATOR

; Protected Mode GDT
PMODE_CODE_SEG                                            equ         PMODE_GDT_CODE - PMODE_GDT_START
PMODE_DATA_SEG                                            equ         PMODE_GDT_DATA - PMODE_GDT_START

PMODE_GDT_START:
    dq 0x0

PMODE_GDT_CODE:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10011010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

; data segment descriptor
PMODE_GDT_DATA:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10010010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

PMODE_GDT_END:

PMODE_GDT_DESCRIPTOR:

    dw PMODE_GDT_END - PMODE_GDT_START - 1 ; size (16 bit)
    dd PMODE_GDT_START ; address (32 bit)

    CONFIG_LINE_BUFFER  times 128                       db          0
    CONFIG_VAR_NAME_BUFFER times 32                     db          0
    CONFIG_VAR_STRING_VAL_BUFFER times 64               db          0

[bits 16]
[CPU 386]
[section .text]

[global BOOT_START]
    BOOT_START:
        xor ax, ax
        mov es, ax
        mov ds, ax
        mov gs, ax
        mov fs, ax
        mov ss, ax

        call INIT_BOOT_DISK

        mov al, dl      ; For debugging
        out 0x80, al    ; Outputs the boot disk number to the POST port

        call ENABLE_A20

        push cs
        call INIT_UNREAL

        call INIT_SCRREEN

        ; Reading the config file
        mov dx, ds
        mov ebx, CONFIG_FILE_POINTER
        mov si, BOOT_CONFIG_FILE_PATH

        call LOAD_FILE_BY_PATH

        call KERNEL_TABLE_INIT

        call BOOT_CONFIG_INIT

        mov al, byte[AUTOBOOT_ENTRY]
        test al, al
        jnz UI_INPUT

        call PRINT_BANNERS

        call BOOT_MENU_INIT

        call PLAY_BOOTUP_SOUND

        xor al, al
        jmp UI_INPUT

    UI_INPUT:
        mov cx, word[KERNEL_ENTRY_COUNTER]
        test al, al
        jnz .find_kernel_entry

    .get_keyboard_input:
        xor ah, ah
        int 16h

        cmp al, '0'
        jb .get_keyboard_input
        cmp al, '9'
        ja .get_keyboard_input
        
        sub al, 48  ; convert the character to a number
        cmp al, cl  ; check if the number is within range
        jg .get_keyboard_input

    .find_kernel_entry:
        mov bl, al
        dec bl
        mov ax, KERNEL_ENTRY_SIZE
        mul bl
        add ax, word[KERNEL_TABLE_POINTER]

        ; checking to see if wee need to clear the screen
        cmp byte[BOOT_CLEAR_SCREEN], 0
        je .load_kernel
        push ax

        call CLEAR_SCREEN
        
        pop ax

    .load_kernel:
        push ax

        mov si, LOADING_MSG
        call PRINT

        mov si, ax
        call PRINT
        NEWLINE 1

        add si, 128
        mov dx, word[ds:si] ; keeping load segment in the AX regidter
        add si, 2
        mov bx, word[ds:si]
        add si, 2
        cmp byte[ds:si], 1
        je .pmode
        inc si
        cmp byte[ds:si], 1
        je LINUX_16_LOAD

    ; loading the file and making a jump to the kernel code
        pop si
        add si, 64
        call LOAD_FILE_BY_PATH
        
        push dx ; load kernel segment
        push bx ; load kernel offset

        shr bx, 4   
        add dx, bx  ; adding the offset to the load segment
        
        mov ds, dx
        mov es, dx

        retf    ; jump to the kernel
    
    .pmode:
        mov si, word[esp] ; Read the stack without popping 

        add si, 135
        cmp dword[ds:si], 0
        je .load_to_low_mem

    ; loading into high memory
        mov ebx, dword[ds:si]
        pop si
        add si, 64
        call LOAD_FILE_BY_PATH
        jmp .init_32
        
    .load_to_low_mem:
        pop si
        add si, 64
        call LOAD_FILE_BY_PATH
        xor ebx, ebx

    .init_32:
        cli
        lgdt [PMODE_GDT_DESCRIPTOR]
        mov eax, cr0
        or eax, 0x1
        mov cr0, eax

        jmp dword PMODE_CODE_SEG:.init_pmode

[bits 32]
    .init_pmode:
        mov ax, PMODE_DATA_SEG
        mov ds, ax
        mov ss, ax
        mov es, ax
        mov fs, ax
        mov gs, ax

        test ebx, ebx
        jnz .loaded_high

        ;loaded low
        xor eax, eax
        mov ax, dx
        shl eax, 4
        add eax, ebx
        
        jmp eax

    .loaded_high:

        jmp ebx

[bits 16]
    PLAY_BOOTUP_SOUND:
        cmp byte[BOOT_BEEP_ENABLE], 0
        je .done

        mov ax, 1200
        mov cx, 0x0004
        mov dx, 0x5730
        call PLAY_PC_SPEAKER_TONE

    .done:
        ret

    PRINT_BANNERS:
        cmp word[BOOT_BANNER_FILE_PATH], 0
        je .default_banner

    .custom_banner:
        mov bx, word[KERNEL_TABLE_POINTER]
        mov ax, word[KERNEL_ENTRY_COUNTER]
        mov cx, KERNEL_ENTRY_SIZE
        mul cx
        add bx, ax
        mov dx, ds
        mov si, BOOT_BANNER_FILE_PATH
        call LOAD_FILE_BY_PATH
        mov si, bx
        call PRINT_TXT

        jmp .done

    .default_banner:
        ;setting up colors for the logo
        xor cx, cx
        mov dx, 79
        mov ah, 0x07
        mov al, 1
        mov bh, byte[BOOT_STRING_COLOR] ; blue background and white foregoround
        int 10h

        mov si, BANNER
        call PRINT

    .done:
        ret

    BOOT_MENU_INIT: ; probably a good idea to rework the whole alogoritm for placig all spaces, bracets, etc
        pusha

        mov si, BOOT_MENU_MSG
        call PRINT

        mov si, word[KERNEL_TABLE_POINTER]
        mov cx, word[KERNEL_ENTRY_COUNTER]
        xor bx, bx

        mov ah, 0x0e

    .print_kernel_entry:
        inc bx

        SPACE 2

        mov al, '('
        int 10h
        mov al, bl
        add al, 48  ; convert the numeric value to a character
        int 10h
        mov al, ')'
        int 10h
        SPACE 1

        call PRINT

        push si
        mov si, KENREL_PATH_MSG
        call PRINT
        pop si

        push si
        add si, 64
        call PRINT
        pop si

        NEWLINE 2

        add si, KERNEL_ENTRY_SIZE
        dec cx
        jcxz .done
        jmp .print_kernel_entry

    .done:
        popa
        ret

    KERNEL_TABLE_INIT:
        pusha 

        mov ax, word[FILE_SIZE]                 ; get the size of the loaded config file
        add ax, CONFIG_FILE_POINTER
        mov word[KERNEL_TABLE_POINTER], ax

        popa
        ret

    BOOT_CONFIG_INIT: ; ES must equal DS
        pusha

        mov di, CONFIG_LINE_BUFFER
        mov si, CONFIG_FILE_POINTER
        mov cx, word[FILE_SIZE]
        inc cx

    .read_file_bytes:
        dec cx
        jcxz .done

        lodsb

        cmp al, 0x0a
        je .line_end_reached
        cmp al, '#'
        je .comment_reached
        ;cmp al, ' '
        ;je .read_file_bytes

        stosb

        jmp .read_file_bytes

    .comment_reached:
        dec cx
        jcxz .done

        lodsb
        cmp al, 0x0a
        jne .comment_reached

        cmp di, CONFIG_LINE_BUFFER
        jne .line_end_reached

        jmp .read_file_bytes

    .line_end_reached:
        cmp di, CONFIG_LINE_BUFFER
        je .read_file_bytes

        ;inc di
        mov byte[ds:di], 0

        push si
        mov di, CONFIG_LINE_BUFFER
        mov si, di

        call PARSE_CONFIG_LINE

    .after_line_parsed:
        pop si
        jmp .read_file_bytes

    .done:
        popa
        ret

    PARSE_CONFIG_LINE:
        pusha

        mov si, CONFIG_LINE_BUFFER
        mov di, CONFIG_VAR_NAME_BUFFER

        .read_line_bytes:
        lodsb
        cmp al, 0
        je .done
        cmp al, ' '
        je .read_line_bytes
        cmp al, '"'
        je .string_reached
        cmp al, '='
        je .var_value_reached

        stosb

        jmp .read_line_bytes

    .string_reached:
        lodsb
        cmp al, '"'
        je .done

        stosb
        jmp .string_reached

    .var_value_reached:
        mov byte[es:di], 0
        mov di, CONFIG_VAR_STRING_VAL_BUFFER

        jmp .read_line_bytes

    .done:
        mov byte[es:di], 0

        ;mov si, CONFIG_VAR_NAME_BUFFER
        ;call PRINT
        ;mov ah, 0x0e
        ;mov al, ENDL
        ;int 10h 
        ;mov al, RETC
        ;int 10h

        ;mov si, CONFIG_VAR_STRING_VAL_BUFFER
        ;call PRINT
        ;mov ah, 0x0e
        ;mov al, ENDL
        ;int 10h 
        ;mov al, RETC
        ;int 10h

        call CHECK_FOR_KERNEL_ENTRY_DECLARATION

        call APPLY_CONFIG_VAR

        popa
        ret

    CHECK_FOR_KERNEL_ENTRY_DECLARATION:
        pusha

        ; checking for a menu entry declarator
        mov si, CONFIG_VAR_NAME_BUFFER
        mov di, CONFIG_MENU_ENTRY_DECLARATOR
        mov cx, 17
        push si
        repe cmpsb ; comparing the strings using cmpsb
        pop si
        je .menu_entry_decalarator
   
        jmp .done

    .menu_entry_decalarator:
        mov bx, word[KERNEL_ENTRY_COUNTER] ; TODO: change to a byte
        mov ax, KERNEL_ENTRY_SIZE
        mul bx
        add ax, word[KERNEL_TABLE_POINTER]

        mov word[VAR_MENU_NAME_POINTER], ax     ; menu name string

        add ax, 64                              ; adding the size of the 
        mov word[VAR_KERNEL_PATH_POINTER], ax   ; same logic for everything bellow

        add ax, 64
        mov word[VAR_KERNEL_SEG_POINTER], ax

        add ax, 2
        mov word[VAR_KERNEL_OFF_POINTER], ax

        add ax, 2
        mov word[VAR_KERNEL_PMODE_POINTER], ax

        inc ax
        mov word[VAR_KERNEL_LINUX_16_POINTER], ax

        inc ax
        mov word[VAR_KERNEL_DEFAULT_POINTER], ax

        inc ax
        mov word[VAR_KENREL_LOAD_ADDR_POINTER], ax

        inc bx
        mov word[KERNEL_ENTRY_COUNTER], bx

        .done:
        popa
        ret

    APPLY_CONFIG_VAR: 
        pushad
    
        mov si, VAR_TABLE_START
        mov word[VAR_TABLE_CURRENT_POINTER], si
        mov di, CONFIG_VAR_NAME_BUFFER
        xor cx, cx
        
        push si                     ; calculating the variable name length
        mov si, di

    .get_var_name_length:
        inc cx
        lodsb
        cmp al, 0
        jne .get_var_name_length

        dec cx                      ; decrement the counter, since the counter stops on the 0 byte terminator
        pop si

    .search_var_name:
        push cx         ; saving var name length
        push di         ; saving pointer to the variable name
        repe cmpsb
        pop di
        pop cx
        je .found

    .find_next_var_table_entry:             ;skipping to the next var table entry
        mov si, word[VAR_TABLE_CURRENT_POINTER]

    .skip_var_name:
        lodsb
        cmp al, 0
        jne .skip_var_name
        
        add si, 3   ; offset at which the next var table entry should be
        mov word[VAR_TABLE_CURRENT_POINTER], si

        cmp word[ds:si], VAR_TABLE_TERMINATOR
        je .done    ; skipping a var if it's not in the var table

        jmp .search_var_name

    .found:
        inc si
        lodsb
        cmp al, 0x07
        je .apply_hex_dword
        cmp al, 0x06
        je .apply_bool
        cmp al, 0x05
        je .apply_string
        cmp al, 0x04
        je .apply_dec_byte
        cmp al, 0x03
        je .apply_dec_word
        cmp al, 0x02
        je .apply_hex_byte
        cmp al, 0x01
        je .apply_hex_word
        jmp CRIT_ERROR                     ; TODO: add invalid var type handler
                                           ; TODO: add auto detect of hex and dec

    .apply_dec_word:
        push si                     ; save the var pointer
        mov si, CONFIG_VAR_STRING_VAL_BUFFER
        call DEC_STRING_TO_NUM
        pop si
        mov bx, word[ds:si]         ; not sure if  using lodsw is better
        mov word[ds:bx], dx         ; applying the value
        jmp .done

    .apply_dec_byte:
        push si                     ; save the var pointer
        mov si, CONFIG_VAR_STRING_VAL_BUFFER
        call DEC_STRING_TO_NUM
        pop si
        mov bx, word[ds:si]         ; not sure if  using lodsw is better
        mov byte[ds:bx], dl         ; applying the value
        jmp .done

    .apply_string:
        mov di, word[ds:si]
        mov si, CONFIG_VAR_STRING_VAL_BUFFER

    .write_string_bytes:
        lodsb
        stosb
        cmp al, 0
        jne .write_string_bytes
        jmp .done

    .apply_hex_dword:
        push si
        mov si, CONFIG_VAR_STRING_VAL_BUFFER
        call HEX_STRING_TO_NUM
        pop si
        mov bx, word[ds:si]         ; not sure if  using lodsw is better
        mov dword[ds:bx], edx       ; applying the value
        jmp .done

    .apply_hex_word:
        push si
        mov si, CONFIG_VAR_STRING_VAL_BUFFER
        call HEX_STRING_TO_NUM
        pop si
        mov bx, word[ds:si]         ; not sure if  using lodsw is better
        mov word[ds:bx], dx         ; applying the value
        jmp .done

    .apply_hex_byte:
        push si
        mov si, CONFIG_VAR_STRING_VAL_BUFFER
        call HEX_STRING_TO_NUM
        pop si
        mov bx, word[ds:si]         ; not sure if  using lodsw is better
        mov byte[ds:bx], dl         ; applying the value
        jmp .done

    .apply_bool:
        push si
        mov si, CONFIG_VAR_STRING_VAL_BUFFER
        call BOOL_STRING_TO_NUM
        pop si
        mov bx, word[ds:si]         ; not sure if  using lodsw is better
        mov byte[ds:bx], dl         ; applying the value

    .done:
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
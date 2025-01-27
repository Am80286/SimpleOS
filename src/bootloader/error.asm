[bits 16]
[section .text]   
    CRIT_ERROR:
        push bp
        push sp
        push es
        push ds
        push di
        push si
        push dx
        push cx
        push bx
        push ax

        mov si, CRIT_ERROR_MSG
        call PRINT

        mov si, CRASH_DUMP_MSG
        call PRINT
        
        mov al, 1

        mov si, AX_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, BX_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, CX_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, DX_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, SI_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, DI_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, DS_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, ES_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, SP_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD
        
        mov si, BP_MSG
        call PRINT
        pop dx
        call PRINT_HEX_WORD

        mov si, ANY_KEY_TO_REBOOT_MSG
        call PRINT

        mov ax, 1200
        mov cx, 0x0003
        mov dx, 0x0d40
        call PLAY_PC_SPEAKER_TONE
        call PLAY_PC_SPEAKER_TONE

        xor ah, ah
        int 16h
        jmp 0xffff:0

    FILE_NOT_FOUND_ERROR:
        mov si, FILE_NOT_FOUND_ERROR_MSG
        call PRINT

        jmp CRIT_ERROR

    LBA_READ_ERROR:
        mov si, LBA_READ_ERROR_MSG
        call PRINT
        jmp INT13H_ERROR_CODES

     DRIVE_INIT_ERROR:   
        mov si, DRIVE_INIT_ERROR_MSG
        call PRINT
        jmp INT13H_ERROR_CODES

    INT13H_ERROR_CODES:
        cmp al, 0x01
        je .invalid_command
        cmp al, 0x04
        jmp .write_on_wp
        cmp al, 0x0d
        je .invalid_sector_count
        cmp al, 0x20
        je .controller_failure
        cmp al, 0x40
        je .seek_failure
        cmp al, 0x80
        je .drive_not_ready
        cmp al, 0xaa
        je .drive_not_ready
        jmp .undefined

    .invalid_command:
        mov si, INVALID_COMMAND_ERROR_MSG
        jmp .print_error

    .write_on_wp:
        mov si, SECOTR_NOT_FOUND_ERROR_MSG
        jmp .print_error

    .invalid_sector_count:
        mov si, INVALID_COMMAND_ERROR_MSG
        jmp .print_error

    .controller_failure:
        mov si, CONTROLLER_FAILURE_ERROR_MSG
        jmp .print_error
    
    .seek_failure: 
        mov si, SEEK_FAILURE_ERROR_MSG
        jmp .print_error

    .drive_not_ready:
        mov si, DRIVE_NOT_READY_ERROR_MS
        jmp .print_error

    .undefined:
        mov si, UNDEFINED_ERROR_MSG
        
    .print_error
        call PRINT
        jmp CRIT_ERROR
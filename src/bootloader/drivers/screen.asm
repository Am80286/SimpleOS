[bits 16]
[section .text]
    INIT_SCRREEN:
        mov ax, 0x0003 ; Text mde 80x25
        int 10h

        mov ah, 0x01
        mov cx, 0x2607 ; Invisible cursor
        int 10h
        
        ret

    PRINT:
        pusha
        mov ah, 0x0e

    .loop:
        lodsb
        cmp al, 0
        je .done
        int 0x10
        jmp .loop

    .done:
        popa
        ret

    PRINT_TXT: ; DS:SI - pointer to a loaded TXT file 
        pusha
        mov ah, 0x0e

    .loop:
        lodsb
        cmp al, 0
        je .done
        cmp al, ENDL
        je .line_end
        int 0x10
        jmp .loop

    .line_end:
        int 10h
        mov al, RETC
        int 10h
        jmp .loop

    .done:
        popa
        ret

    CLEAR_SCREEN:
        pusha

        ; Clear the screen
        mov ah, 0x06
        xor al, al
        mov bh, 0x07
        xor cx, cx
        mov dh, 24
        mov dl, 79
        int 10h

        ; Get current video page
        mov ah, 0x0f
        int 10h

        ; Reset cursor position
        mov ah, 0x02
        xor dx, dx
        int 10h

        popa
        ret
    
    ; In place of the old PRINT_HEX_WORD, this updated function can
    ; print hex without needing the HEX_OUT variable and it also 
    ; works for bytes, words, dword.
    ; Value to print - EDX
    ; AL 1 - \n
    ; BL - number to fill zeros to
    ; BH 1 - add 0x prefix

    PRINT_HEX:
        pushad
        push ax

        xor cx, cx

    .loop:
        mov eax, edx
        shr edx, 4

        inc cx

        and eax, 0xF
        cmp eax, 0xA
        jb .set_letter
        
        add eax, 7
        
    .set_letter:
        add eax, 48
        push eax
        
        test edx, edx
        jz .print
        jmp .loop

    .print:
        test bh, bh
        jz .no_prefix

        mov si, HEX_PREFIX
        call PRINT

    .no_prefix:
        test bl, bl
        jz .print_char

        mov ah, 0x0e
        xor bh, bh

        cmp cx, bx
        jae .print_char

        sub bx, cx

    .fill_zero:
        dec bl
        mov al, '0'
        int 10h
        cmp bl, 0
        jnz .fill_zero

    .print_char:
        dec cx
        pop eax
        mov ah, 0x0e
        int 10h
        test cx, cx
        jnz .print_char
        
    .done: 
        pop ax
        cmp al, 0
        je .done
        NEWLINE 1

        popad
        ret
    
    PRINT_DEC: ; EDX - number to print, AL 1 - \n
        pushad
        push ax

        mov eax, edx
        xor cx, cx
        cmp eax, 0
        je .done

    .loop:
        cmp eax, 0
        je .print
        mov ebx, 10
        xor edx, edx
        div ebx
        add dl, 48
        cmp dl, 48
        jl .loop
        push edx
        inc cx
        jmp .loop

    .print:
        dec cx
        pop eax
        mov ah, 0x0e
        int 10h
        cmp cx, 0
        jne .print

        pop ax
        cmp al, 0
        je .done
        mov ah, 0x0e
        mov al, ENDL
        int 10h
        mov al, RETC
        int 10h

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
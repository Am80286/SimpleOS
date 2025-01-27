[bits 16]
[section .text]
    INIT_SCRREEN:
        mov ax, 0x0003
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
    
    PRINT_HEX_WORD:      ;Value to print - DX, AL 1 - \n
        pusha
        push ax

        mov ah, 0x0e
        mov cx, 4

    .loop:
        dec cx
        mov ax, dx
        shr dx, 4
        and ax, 0xF
        mov bx, HEX_OUT
        add bx, cx
        cmp ax, 0xA
        jl .set_letter
        add byte [ds:bx], 7
        
    .set_letter:
        add byte [ds:bx], al
        cmp cx, 'h'
        je .done
        jmp .loop

    .done:
        mov si, HEX_OUT
        call PRINT
        pop ax
        cmp al, 0
        je .reset_leter
        mov ah, 0x0e
        mov al, ENDL
        int 10h
        mov al, RETC
        int 10h

    .reset_leter:
        mov byte[ds:si], 0x30
        inc si
        cmp byte[ds:si], 'h'
        jne .reset_leter

        popa 
        ret
    
    PRINT_DEC: ; DX - number to print, AL 1 - \n
        pusha
        push ax

        mov ax, dx
        xor cx, cx
        cmp ax, 0
        je .done

    .loop:
        cmp ax, 0
        je .print
        mov bx, 10
        xor dx, dx
        div bx
        add dl, 48
        cmp dl, 48
        jl .loop
        push dx
        inc cx
        jmp .loop

    .print:
        dec cx
        pop ax
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
        popa
        ret

    NEWLINE: ; CX - new line count
        pusha
        mov ah, 0x0e
        
    .loop:
        jcxz .done
        mov al, ENDL
        int 10h
        mov al, RETC
        int 10h
        dec cx
        jmp .loop

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
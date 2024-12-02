[bits 16]
[SECTION .text]
    HEX_WORD_STRING_TO_NUM: ; DS:SI - string pointer, DX - result
        push ax             ; This implementation is a little janky, practically the same as the DEC_WORD_STRING_TO_NUM
        push bx             ; gonna have to rewrite it later also
        push cx
        push si

        xor cx, cx
        xor dx, dx

    .find_string_end:
        inc cx
        lodsb
        cmp al, 0
        jne .find_string_end

        mov ax, 1   ; ax is used as a multiplier 
        sub cx, 3
        sub si, 2   ; set the string pointer to the end character
        std         ; setting the DF to iterate backwards through the number string
                    ; this is done bacause we need to know ....
    .convert_char:
        push ax     ; save the multiplier

        lodsb

        cmp al, '9'
        jbe .number_char

    .letter_char:
        sub al, 7

    .number_char:
        sub al, 48
        and al, 0xf ; remove the upper nibble (only needed for lower case letters)
        
        xor bh, bh
        mov bl, al  ; some trickery to multiply everything
        pop ax      ; get the multiplier
        push ax
        
        push dx
        mul bx
        pop dx

        add dx, ax

        pop ax
        shl ax, 4   ; multiply by 16

        dec cx
        jcxz .done
        jmp .convert_char

    .done:
        cld
        pop si
        pop cx
        pop bx
        pop ax
        ret

    DEC_WORD_STRING_TO_NUM: ; DS:SI - string pointer, DX - result
        push ax             ; This implementation is a little janky,
        push bx             ; gonna have to rewrite it later
        push cx
        push si

        xor cx, cx
        xor dx, dx

    .find_string_end:
        lodsb
        inc cx
        cmp al, 0
        jne .find_string_end

        mov ax, 1   ; ax is used as a multiplier 
        sub si, 2   ; set the string pointer to the end character
        std         ; setting the DF to iterate backwards through the number string
                    ; this is done bacause we need to know ....
    .convert_char:
        push ax     ; save the multiplier

        lodsb
        sub al, 48

        xor bh, bh
        mov bl, al  ; some trickery to multiply everything
        pop ax      ; get the multiplier
        push ax

        push dx
        mul bx
        pop dx

        add dx, ax

        pop ax
        mov bl, 10
        mul bl

        dec cx
        jcxz .done
        jmp .convert_char

    .done:
        cld
        pop si
        pop cx
        pop bx
        pop ax
        ret

    BOOL_STRING_TO_NUM ; DS:SI - string pointer, DL - result
        push cx
        push si
        push di

        mov cx, 4
        mov di, CONFIG_BOOL_TRUE
        push si
        repe cmpsb
        pop si
        je .true

        mov cx, 5
        mov di, CONFIG_BOOL_FALSE
        repe cmpsb
        je .false

        jmp CRIT_ERROR             ; TODO: make proper error handling

    .true:
        mov dx, 1
        jmp .done

    .false:
        xor dx, dx

    .done:
        pop di
        pop si
        pop cx
        ret

    STRING_TO_FAT_FILENAME: ; DS:SI - string pointer, ES:DI - output buffer pointer
        pusha               ; A little janky as well, needs much better error handling
        xor cx, cx          ; But I'm in a little bit of a rush, so it's okay for now
        inc cx

    .read_string_bytes:
        lodsb
        cmp al, '.'
        je .dot
        cmp al, 0
        je .string_end

        sub al, 32  ; convert to upper case
        stosb
        inc cx

        jmp .read_string_bytes

    .dot:
        mov bx, 9
        sub bx, cx

    .fill_spaces:
        mov al, ' '
        stosb
        dec bx
        cmp bx, 0
        je .read_string_bytes
        jmp .fill_spaces
        
    .string_end:
        mov bx, 11
        dec cx
        sub bx, cx

    .fill_the_rest:
        mov al, ' '
        stosb
        dec bx
        cmp bx, 0
        je .done
        jmp .fill_the_rest

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

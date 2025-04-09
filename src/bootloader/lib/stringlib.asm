%include "error.inc"

[section .data]
    BOOL_TRUE                                    db          "true"
    BOOL_FALSE                                   db          "false"

[bits 16]
[section .text]

[global HEX_STRING_TO_NUM]
    HEX_STRING_TO_NUM:    ; DS:SI - string pointer, EDX - result
        push eax                ; the same as HEX_WORD_STING_TO_NUM, but for dword values
        push ebx                ; again I don't like how it's implemeted
        push cx
        push si

        xor cx, cx
        xor edx, edx

    .find_string_end:
        inc cx
        lodsb
        cmp al, 0
        jne .find_string_end

        mov eax, 1   ; ax is used as a multiplier 
        sub cx, 3
        sub si, 2   ; set the string pointer to the end character
        std         ; setting the DF to iterate backwards through the number string
                    ; this is done bacause we need to know ....
    .convert_char:
        push eax     ; save the multiplier

        lodsb

        cmp al, '9'
        jbe .number_char

    .letter_char:
        sub al, 7

    .number_char:
        sub al, 48
        and al, 0xf ; remove the upper nibble (only needed for lower case letters)
        
        xor ebx, ebx
        mov bl, al  ; some trickery to multiply everything
        pop eax      ; get the multiplier
        push eax

        push edx
        mul ebx
        pop edx

        add edx, eax

        pop eax
        shl eax, 4   ; multiply by 16

        dec cx
        jcxz .done
        jmp .convert_char

    .done:
        cld
        pop si
        pop cx
        pop ebx
        pop eax
        ret

[global DEC_STRING_TO_NUM]
    DEC_STRING_TO_NUM: ; DS:SI - string pointer, EDX - result
        push eax             ; This implementation is still not the best
        push ebx             ; gonna have to rewrite it later
        push cx
        push si

        xor cx, cx
        xor dx, dx

    .find_string_end:
        lodsb
        inc cx
        cmp al, 0
        jne .find_string_end
        dec cx

        mov eax, 1   ; ax is used as a multiplier 
        sub si, 2   ; set the string pointer to the end character
        std         ; setting the DF to iterate backwards through the number string
                    ; this is done bacause we need to know ....
    .convert_char:
        push eax     ; save the multiplier

        lodsb
        sub al, 48   ; convert car to a number

        xor bh, bh
        mov bl, al  ; some trickery to multiply everything
        mov eax, dword[esp]

        push edx
        mul ebx
        pop edx

        add edx, eax

        pop eax
        mov ebx, 10
        push edx
        mul ebx
        pop edx

        dec cx
        jcxz .done
        jmp .convert_char

    .done:
        cld
        pop si
        pop cx
        pop ebx
        pop eax
        ret

[global BOOL_STRING_TO_NUM]
    BOOL_STRING_TO_NUM: ; DS:SI - string pointer, DL - result
        push cx
        push si
        push di

        mov cx, 4
        mov di, BOOL_TRUE
        push si
        repe cmpsb
        pop si
        je .true

        mov cx, 5
        mov di, BOOL_FALSE
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

[global STRING_TO_FAT_FILENAME]
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
        cmp al, 0x61
        jb .skip_char
        cmp al, 0x7a
        jg .skip_char

        sub al, 32  ; convert to upper case

    .skip_char:
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
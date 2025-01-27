[bits 16]
[section .text]
    PLAY_PC_SPEAKER_TONE:
        pusha

        mov bx, ax
        mov al, 182
        out 43h, al

        mov ax, bx
        out 42h, al

        mov al, ah
        out 42h, al

        in al, 61h
        or al, 03h
        out 61h, al
        
        mov ah, 86h
        int 15h
        in al, 61h
        and al, 0FCh
        out 61h, al

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
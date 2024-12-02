[bits 32]
[SECTION .text]
    TEST_A20:
        pushad

        mov edi, 0x112345  ;odd megabyte address.
        mov esi, 0x012345  ;even megabyte address.
        mov [esi],esi     ;making sure that both addresses contain diffrent values.
        mov [edi],edi     ;(if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi)) 
        cmpsd             ;compare addresses to see if the're equivalent.
    
        je .a20_off

        clc
        jmp .done

    .a20_off:
        stc

    .done:
        popad
        ret

    ENABLE_A20:
        pushad

        ;try fast a 20 gate
        in al, 0x92
        or al, 2
        out 0x92, al

        call TEST_A20

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
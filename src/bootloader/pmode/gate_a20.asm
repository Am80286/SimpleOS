[bits 16]
[section .text]
    ENABLE_A20:
        pusha

        call TEST_A20
        jnc .done

        ; try using fast a20 gate
        in al, 0x92
        or al, 2
        out 0x92, al

        call TEST_A20
        jnc .done

        ; try using bios enable method
        mov     ax, 2403h                ;--- A20-Gate Support ---
        int     15h
        jb      .keyboard_controller                  ;INT 15h is not supported
        test ah, ah
        jnz     .keyboard_controller                  ;INT 15h is not supported

        cmp     al, 1
        jz      .done           ;A20 is already activated

    .keyboard_controller:
        call A20_ENABLE_KEYBOARD_CONTROLLER

        call TEST_A20
        jc CRIT_ERROR

    .done:
        popa
        ret

    A20_ENABLE_KEYBOARD_CONTROLLER:
        cli

        call .wait_io1
	    mov al, 0xad
	    out 0x64, al
	
	    call .wait_io1
	    mov al, 0xd0
	    out 0x64, al
	
	    call .wait_io2
	    in al, 0x60
	    push eax
	
	    call .wait_io1
	    mov al, 0xd1
	    out 0x64, al
	
	    call .wait_io1
	    pop eax
	    or al, 2
	    out 0x60, al
	
	    call .wait_io1
	    mov al, 0xae
	    out 0x64, al
	
	    call .wait_io1
	    sti
	    ret
    .wait_io1:
	    in al, 0x64
	    test al, 2
	    jnz .wait_io1
	    ret
    .wait_io2:
	    in al, 0x64
	    test al, 1
	    jz .wait_io2
	    ret

    .done:
        sti
        ret
        
    TEST_A20:
        push ds
        push es
        push di
        push si

        cli

        xor ax, ax ; ax = 0
        mov es, ax

        not ax ; ax = 0xFFFF
        mov ds, ax

        mov di, 0x0500
        mov si, 0x0510

        mov al, byte [es:di]
        push ax

        mov al, byte [ds:si]
        push ax

        mov byte [es:di], 0x00
        mov byte [ds:si], 0xFF

        cmp byte [es:di], 0xFF

        pop ax
        mov byte [ds:si], al

        pop ax
        mov byte [es:di], al

        stc
        je check_a20__exit

        clc

    check_a20__exit:
        pop si
        pop di
        pop es
        pop ds
        
        sti
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
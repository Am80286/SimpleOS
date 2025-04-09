; A macro for printing \n
%macro NEWLINE 1
    mov ah, 0x0e
    mov al, ENDL
    %rep %1
        int 10h
    %endrep
    mov al, RETC
    %rep %1
       int 10h
    %endrep
%endmacro

; A imple macro for printing spaces
%macro SPACE 1
    mov ah, 0x0e
    mov al, ' '
    %rep %1
        int 10h
    %endrep
%endmacro

; Another simple macor for printing a specific character
%macro PCHAR 2
    mov ah, 0x0e
    mov al, $1
    %rep %2
        int 10h
    %endrep
%endmacro

RETC                                                equ         0x0D
ENDL                                                equ         0x0A

BOOTLOADER_DS                                       equ         0x0000
BOOTLOADER_CS                                       equ         0x0800

[extern end]

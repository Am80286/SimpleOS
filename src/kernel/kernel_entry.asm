[bits 32]
[CPU 386]
[section .text]
[extern kernel_main]
[global _start]
    mov esp, 0x7c00
    mov ebp, esp

    _start:
    call kernel_main
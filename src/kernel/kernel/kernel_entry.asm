[bits 32]
[CPU 386]
[section .text]
[extern kernel_main]
[global _start]
    _start:
    call kernel_main
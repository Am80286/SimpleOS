[bits 32]
[SECTION .text]
[CPU 386]
[extern kernel_main]
[global _start]

_start:
call kernel_main
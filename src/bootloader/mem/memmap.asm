[bits 16]
[section .text]
    READ_MEM_MAP: ; ES:DI - pointer to where the memory map needs to be, CF - set on error
        pushad

    ; First call of the function
        xor ebx, ebx
        mov ecx, 24
        mov eax, 0xe820
        mov edx, 0x0534D4150

        int 15h
        jc .error

        cmp eax, 0x0534D4150
        jne .error
        test ebx, ebx
        jz .error
        jmp .parse_values

    .get_next_memory_map_entry:
        mov ecx, 24
        mov eax, 0xe820
        mov edx, 0x0534D4150

        mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
        
        int 15h
        jc .done

    .parse_values:
        jcxz .skip_entry
        
        test byte[es:di + 20], 1
        je .skip_entry

        mov ecx, dword[es:di + 8]
        or ecx, dword[es:di + 12]
        jz .skip_entry

        add di, 24

    .skip_entry:
        test ebx, ebx
        jnz .get_next_memory_map_entry

    .done:
        clc
        popad
        ret

    .error:
        stc
        popad
        ret
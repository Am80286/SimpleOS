#include <memory.h>
#include <stdint.h>
#include <arch/interrupts.h>
#include <config.h>
#include <kernel.h>
#include <vga.h>

// Called in idt.asm
void page_fault_handler(registers_t regs, uint32_t cr2)
{
    uint32_t fault_addr = cr2;

    // Gathering info about the fault
    int present   = !(regs.err_code & 0x1);          // Page not present
    int write = regs.err_code & 0x2;                 // Write operation?
    int user = regs.err_code & 0x4;                  // Processor was in user-mode?
    int reserved = regs.err_code & 0x8;              // Overwritten CPU-reserved bits of page entry?
    int instruction = regs.err_code & 0x10;          // Caused by an instruction fetch?

    scrprintf("Page fault occured at: 0x%x\nCaused by ", fault_addr);

    if (write){
        scrprintf("a write operation\n");
    } else if (instruction){
        scrprintf("an instruction fetch\n");
    } else {
        scrprintf("a read operation\n");
    }

    if (user){
        scrprintf("CPU was in user mode\n");
    }

    if (present){
        scrprintf("Page not present\n");
    }

    if (reserved) {
        scrprintf("Reserved bits overwritten\n");
    }

    panic("");
}


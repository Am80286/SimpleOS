#ifndef INTERRUPTS_H
#define INTERRUPTS_H

#include <stdint.h>
#include <arch/io.h>

#define IDT_ENTRIES 48

#define IRQ_BASE 32

typedef struct
{
   uint32_t ds;                                     // Data segment selector
   uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax; // Pushed by pusha.
   uint32_t int_no, err_code;                       // Interrupt number and error code (if applicable)
   uint32_t eip, cs, eflags, useresp, ss;           // Pushed by the processor automatically.
} registers_t; 

typedef struct
{
   uint16_t isr_low;             // The lower 16 bits of the address to jump to when this interrupt fires.
   uint16_t kernel_cs;                 // Kernel segment selector.
   uint8_t  reserved;             // This must always be zero.
   uint8_t  flags;               // More flags. See documentation.
   uint16_t isr_high;             // The upper 16 bits of the address to jump to.
} __attribute__((packed)) idt_entry_t;

typedef struct
{
   uint16_t limit;
   uint32_t base;                // The address of the first element in our idt_entry_t array.
} __attribute__((packed)) idtr_t;

typedef void (*isr_t)();

void init_interrupts();

void install_interrupt_handler(uint8_t vector, isr_t handler);

void EOI(uint8_t vector);

#endif
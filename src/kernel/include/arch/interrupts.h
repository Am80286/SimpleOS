#ifndef INTERRUPTS_H
#define INTERRUPTS_H

#include <stdint.h>
#include <arch/io.h>

#define IDT_ENTRIES 48

#define PIC1		0x20		// IO base address for master PIC
#define PIC2		0xA0		// IO base address for slave PIC
#define PIC1_COMMAND	PIC1
#define PIC1_DATA	(PIC1+1)
#define PIC2_COMMAND	PIC2
#define PIC2_DATA	(PIC2+1)

#define PIC_1_REMAP_OFFSET  0x20
#define PIC_2_REMAP_OFFSET  0x28

#define ICW1_ICW4	0x01		// Indicates that ICW4 will be present
#define ICW1_SINGLE	0x02		// Single (cascade) mode
#define ICW1_INTERVAL4	0x04    // Call address interval 4 (8)
#define ICW1_LEVEL	0x08		// Level triggered (edge) mode
#define ICW1_INIT	0x10		// Initialization - required!

#define ICW4_8086	0x01		// 8086/88 (MCS-80/85) mode
#define ICW4_AUTO	0x02		// Auto (normal) EOI
#define ICW4_BUF_SLAVE	0x08    // Buffered mode/slave
#define ICW4_BUF_MASTER	0x0C	// Buffered mode/master
#define ICW4_SFNM	0x10		// Special fully nested (not)

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

void EOI(uint8_t vector);

#endif
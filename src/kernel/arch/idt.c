#include <arch/idt.h>
#include <arch/io.h>
#include <arch/pic.h>
#include <stdint.h>
#include <stdbool.h>
#include <vga.h>

static idt_entry_t idt[IDT_ENTRIES];
static idtr_t idtr;

static isr_t interrupt_handlers[IDT_ENTRIES] = { 0 };

extern void idt_flush(uint32_t ptr);
extern void page_fault_stub();
extern void* isr_stub_table[];


static void idt_set_descriptor(uint8_t vector, void* isr, uint8_t flags) 
{
    idt_entry_t* descriptor = &idt[vector];

    descriptor->isr_low        = (uint32_t)isr & 0xFFFF;
    descriptor->kernel_cs      = 0x08; // this value can be whatever offset your kernel code selector is in your GDT
    descriptor->flags	       = flags;
    descriptor->isr_high       = (uint32_t)isr >> 16;
    descriptor->reserved       = 0;
}

void isr_handler(registers_t regs)
{
	if (interrupt_handlers[regs.int_no] != 0){
        isr_t handler = interrupt_handlers[regs.int_no];
        handler(&regs);
    }

    EOI(regs.int_no);
}

void install_interrupt_handler(uint8_t vector, isr_t handler)
{
	interrupt_handlers[vector] = handler;
}

static void init_idt() 
{
    idtr.base = (uintptr_t)&idt[0];
    idtr.limit = (uint16_t)sizeof(idt_entry_t) * 256 - 1;

    for (uint8_t vector = 0; vector < 48; vector++){
        idt_set_descriptor(vector, isr_stub_table[vector], 0x8E);
    }

    idt_flush((uint32_t)&idtr);
}

void init_interrupts()
{
	pic_init();
	init_idt();
}
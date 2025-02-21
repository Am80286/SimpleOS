#include <stdint.h>
#include <stdbool.h>
#include <arch/interrupts.h>
#include <arch/io.h>
#include <vga.h>

static idt_entry_t idt[IDT_ENTRIES];
static idtr_t idtr;

static isr_t interrupt_handlers[IDT_ENTRIES] = { 0 };

extern void idt_flush(uint32_t ptr);
extern void page_fault_stub();
extern void* isr_stub_table[];

// End of interrupt
inline void EOI(uint8_t vector)
{
	if(vector >= 40)
		outb(PIC2_COMMAND, 0x20);
	
	outb(PIC1_COMMAND, 0x20);
}

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
	if (regs.int_no >= 32) {
		if (interrupt_handlers[regs.int_no] != 0){
			isr_t handler = interrupt_handlers[regs.int_no];
			handler(regs);
		}
		
		EOI(regs.int_no);
	}

	
}

void install_interrupt_handler(uint8_t vector, isr_t handler)
{
	interrupt_handlers[vector] = handler;
}

static void init_idt() 
{
    idtr.base = (uintptr_t)&idt[0];
    idtr.limit = (uint16_t)sizeof(idt_entry_t) * 256 - 1;

	// Initializing protected mode exceptions
    for (uint8_t vector = 0; vector < 48; vector++) {
        idt_set_descriptor(vector, isr_stub_table[vector], 0x8E);
        // vectors[vector] = true;
    }

	idt_set_descriptor(14, &page_fault_stub, 0x8E); // Install the page fault handler

    idt_flush((uint32_t)&idtr);
}

static void pic_remap(int offset1, int offset2)
{
	uint8_t a1;
    uint8_t a2;
	
	a1 = inb(PIC1_DATA);                        // save masks
	a2 = inb(PIC2_DATA);
	
	outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);  // starts the initialization sequence (in cascade mode)
	io_wait();
	outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
	io_wait();
	outb(PIC1_DATA, offset1);                 // ICW2: Master PIC vector offset
	io_wait();
	outb(PIC2_DATA, offset2);                 // ICW2: Slave PIC vector offset
	io_wait();
	outb(PIC1_DATA, 4);                       // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
	io_wait();
	outb(PIC2_DATA, 2);                       // ICW3: tell Slave PIC its cascade identity (0000 0010)
	io_wait();
	
	outb(PIC1_DATA, ICW4_8086);               // ICW4: have the PICs use 8086 mode (and not 8080 mode)
	io_wait();
	outb(PIC2_DATA, ICW4_8086);
	io_wait();
	
	outb(PIC1_DATA, a1);   // restore saved masks.
	outb(PIC2_DATA, a2);
}

void init_interrupts()
{
    pic_remap(PIC_1_REMAP_OFFSET, PIC_2_REMAP_OFFSET);
	init_idt();
}
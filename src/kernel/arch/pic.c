#include <arch/pic.h>
#include <arch/io.h>

void pic_init()
{	
	outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);  // starts the initialization sequence (in cascade mode)
	io_wait();
	outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
	io_wait();
	outb(PIC1_DATA, PIC_1_REMAP_OFFSET);                 // ICW2: Master PIC vector offset
	io_wait();
	outb(PIC2_DATA, PIC_2_REMAP_OFFSET);                 // ICW2: Slave PIC vector offset
	io_wait();
	outb(PIC1_DATA, 4);                       // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
	io_wait();
	outb(PIC2_DATA, 2);                       // ICW3: tell Slave PIC its cascade identity (0000 0010)
	io_wait();
	
	outb(PIC1_DATA, ICW4_8086);               // ICW4: have the PICs use 8086 mode (and not 8080 mode)
	io_wait();
	outb(PIC2_DATA, ICW4_8086);
	io_wait();
	
	outb(PIC1_DATA, 0);   // restore saved masks.
	outb(PIC2_DATA, 0);
}

inline void EOI(uint8_t vector)
{
	if(vector >= 40)
		outb(PIC2_COMMAND, 0x20);
	
	outb(PIC1_COMMAND, 0x20);
}
#include <arch/gdt.h>
#include <arch/interrupts.h>
#include <vga.h>
#include <serial.h>
#include <config.h>

void kernel_main(void)
{
    init_gdt();

    set_terminal_color(VGA_COLOR_GREEN);
	init_terminal();
    
    scrprintf("Kernel build date: %s\n", KERNEL_BUILD_DATE_STIRNG);
    scrprintf("Kernel version: %s\n", KENREL_VER_STRING);

    init_interrupts();
    scrprintf("Initialized interrupts\n");

    if (init_serial_port(SERIAL_DEBUG_PORT, SERIAL_DEBUG_PORT_BAUDRATE)){
        scrprintf("Unable to initalize a debug serial port");
    } else {
        scrprintf("Debug serial port initialized at: 0x%h", SERIAL_DEBUG_PORT);
        serial_printf(SERIAL_DEBUG_PORT, "SimpleOS Debug Serial.....\n\r");
    }
    
	while (1);
}
#ifndef __CONFIG_H__
#define __CONFIG_H__

#include <serial.h>

// Strings for displaying kernel version and build date
#define KENREL_VER_STRING "0.01"
#define KERNEL_BUILD_DATE_STIRNG __DATE__ " " __TIME__

// Parameters for the serial ports that's gonna be used for outputting debug messages
#define SERIAL_DEBUG_PORT COM1
#define SERIAL_DEBUG_PORT_BAUDRATE 9600

// Parameters for my shitty memory manager
// This I think is temporary until I make the bootloader pass the memory map to the kernel
#define MEM_END_PAGE = 0x1000000
#define TOTAL_MEM_FRAMES = MEM_END_PAGE / 0x1000

#endif
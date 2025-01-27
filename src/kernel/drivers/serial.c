#include <stddef.h>
#include <arch/io.h>
#include <serial.h>
#include <libc.h>

static size_t terminal_port;
static uint32_t terminal_port_baud_rate;

static char str_buff[1024];

int init_serial_port(size_t port, uint32_t baud_rate)
{
   outb(port + 1, 0x00);                                       // Disable all interrupts

   outb(port + 7, 0xAE);                                       // Test if the scratch register works

   if(inb(port + 7) != 0xAE)
      return 1;

   outb(port + 3, 0x80);                                       // Enable DLAB (set baud rate divisor)
   outb(port + 0, (UART_CLOCK / baud_rate) && 0xFF);           // Set divisor to 3 (lo byte) 38400 baud
   outb(port + 1, ((UART_CLOCK / baud_rate) >> 8) && 0xFF);    //                  (hi byte)

   outb(port + 3, 0x03);                                       // 8 bits, no parity, one stop bit
   outb(port + 2, 0xC7);                                       // Enable FIFO, clear them, with 14-byte threshold
   outb(port + 4, 0x0B);                                       // IRQs enabled, RTS/DSR set

   outb(port + 4, 0x1E);                                       // Set in loopback mode, test the serial chip
   outb(port + 0, 0xAE);                                       // Test serial chip (send byte 0xAE and check if serial returns same byte)

   if(inb(port + 0) != 0xAE)
      return 1;

   outb(port + 4, 0x0F);                                       // Disable loopback mode

   return 0;
}

int serial_received(size_t port)
{
   return inb(port + 5) & 1;
}

char serial_read(size_t port)
{
   while (serial_received(port) == 0);

   return inb(port);
}

int serial_transmit_empty(size_t port)
{
   return inb(port + 5) & 0x20;
}

void serial_write(size_t port, const char* data, size_t size)
{
	for (size_t i = 0; i < size; i++)
		serial_putc(port, data[i]);
}

void serial_putc(size_t port, char a)
{  
   while (serial_transmit_empty(port) == 0);

   outb(port, a);
}

void serial_puts(size_t port, const char* data)
{
   serial_write(port, data, strlen(data));
}

int serial_printf(size_t port, const char *fmt, ...)
{
   va_list args;
   va_start(args, fmt);
   int ret = vsprintf(str_buff, fmt, args);
   serial_puts(port, str_buff);
   va_end(args);

   return ret;
}
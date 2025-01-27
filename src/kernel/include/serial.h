#ifndef SERIAL_H
#define SERIAL_H

#include <stddef.h>
#include <stdint.h>

#define UART_CLOCK 115200

enum serial_ports {
    COM1 = 0x3f8,
    COM2 = 0x2f8,
    COM3 = 0x3e8,
    COM4 = 0x2e8,
    COM5 = 0x5f8,
    COM6 = 0x4f8,
    COM7 = 0x5e8,
    COM8 = 0x4e8
};

int init_serial_port(size_t port, uint32_t baud_rate);

char serial_read(size_t port);

void serial_putc(size_t port, char a);

void serial_puts(size_t port, const char* data);

int serial_received(size_t port);

int serial_transmit_empty(size_t port);

void serial_write(size_t port, const char* data, size_t size);

int serial_printf(size_t port, const char *fmt, ...);

#endif
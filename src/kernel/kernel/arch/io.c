#include <arch/io.h>
#include <stdint.h>

/* Ports input output functions */
inline void outb(uint16_t port, uint8_t value)
{
    asm volatile("outb %%al, %%dx":: "d"(port), "a"(value));
}

inline void outw(uint16_t port, uint16_t value)
{
    asm volatile("outw %%ax, %%dx":: "d"(port), "a"(value));
}

inline void outl(uint16_t port, uint32_t value)
{
    asm volatile("outl %%eax, %%dx":: "d"(port), "a"(value));
}

inline uint8_t inb(uint16_t port)
{
    uint8_t value;
    asm volatile("inb %%dx, %%al":"=a"(value):"d"(port));
    return value;
}

inline uint16_t inw(uint16_t port)
{
    uint16_t value;
    asm volatile("inw %%dx, %%ax":"=a"(value):"d"(port));
    return value;
}

inline uint32_t inl(uint16_t port)
{
    uint32_t value;
    asm volatile("inl %%dx, %%eax":"=a"(value):"d"(value));
    return value;
}

/* A small delay of 1-4 microseconds */
inline void io_wait(void)
{
    outb(0x80, 0xFF);
}
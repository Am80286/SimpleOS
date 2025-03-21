#include <kernel.h>
#include <config.h>
#include <vga.h>

volatile void panic(const char* msg)
{
    scrprintf("!!! Kernel Panic !!! \n%s\n", msg);
    while (1);
}
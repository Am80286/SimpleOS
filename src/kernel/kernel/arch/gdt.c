#include <stdint.h>
#include <arch/gdt.h>

gdt_entry_t gdt_entries[GDT_ENTRIES];
gdtr_t gdtr;

extern void gdt_flush(uint32_t gdtr);

static void gdt_set_gate(uint32_t entry, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran)
{
   gdt_entries[entry].base_low    = (base & 0xFFFF);
   gdt_entries[entry].base_middle = (base >> 16) & 0xFF;
   gdt_entries[entry].base_high   = (base >> 24) & 0xFF;

   gdt_entries[entry].limit_low   = (limit & 0xFFFF);
   gdt_entries[entry].granularity = (limit >> 16) & 0x0F;

   gdt_entries[entry].granularity |= gran & 0xF0;
   gdt_entries[entry].access      = access;
} 

void init_gdt()
{
   gdtr.limit = (sizeof(gdt_entry_t) * GDT_ENTRIES) - 1;
   gdtr.base  = (uint32_t)&gdt_entries;

   gdt_set_gate(0, 0, 0, 0, 0);                // Null segment
   gdt_set_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF); // Code segment
   gdt_set_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF); // Data segment
   gdt_set_gate(3, 0, 0xFFFFFFFF, 0xFA, 0xCF); // User mode code segment
   gdt_set_gate(4, 0, 0xFFFFFFFF, 0xF2, 0xCF); // User mode data segment

   gdt_flush((uint32_t)&gdtr);
}
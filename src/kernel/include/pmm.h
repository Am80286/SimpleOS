#ifndef PMM_H
#define PMM_H

#include <stdint.h>

#define BLOCK_SIZE 4096
#define BLOCK_ALIGN(addr) (((addr) & 0xFFFFF000) + 0x1000)

extern uint32_t   end;

extern uint32_t*  pmm_bitmap;

extern uint32_t   pmm_bitmap_size;

void free_block(uint32_t addr);

uint32_t alloc_block();

void init_pmm();

#endif
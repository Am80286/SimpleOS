#include <pmm.h>
#include <bitset.h>
#include <kernel.h>
#include <stdint.h>

//uint32_t* pmm_mem_start;

uint32_t* pmm_bitmap;

uint32_t  pmm_bitmap_size;

uint32_t  pmm_total_blocks;

void free_block(uint32_t idx)
{
    bitset_clear(pmm_bitmap, idx);
}

uint32_t alloc_block()
{
    for(int i = 0; i < pmm_total_blocks; i++){
        if(!bitset_test(pmm_bitmap, i)){
            bitset_set(pmm_bitmap, i);
            return i;
        }
    }

    panic("Out of memory");
}

void init_pmm()
{
    pmm_bitmap = (uint32_t*)&end;
    pmm_total_blocks = 1024;
    pmm_bitmap_size = pmm_total_blocks / BITS_PER_BLOCK;
}

#ifndef VMM_H
#define VMM_H

#include <stdint.h>

#define PAGE_SIZE 4096

#define NOT_ALIGN(addr) (((uint32_t)(addr)) & 0x00000FFF)
#define PAGE_ALIGN(addr) ((((uint32_t)(addr)) & 0xFFFFF000) + 0x1000)

#define PAGEDIR_INDEX(vaddr) (((uint32_t)vaddr) >> 22)
#define PAGETABLE_INDEX(vaddr) ((((uint32_t)vaddr) >>12) & 0x3ff)
#define PAGEFRAME_INDEX(vaddr) (((uint32_t)vaddr) & 0xfff)

#define SET_PGBIT(cr0) (cr0 |= 0x80000000)

typedef struct
{
    uint32_t present    : 1;
    uint32_t rw         : 1;
    uint32_t user       : 1;
    uint32_t w_through  : 1;
    uint32_t cache      : 1;
    uint32_t access     : 1;
    uint32_t reserved   : 1;
    uint32_t page_size  : 1;
    uint32_t global     : 1;
    uint32_t available  : 3;
    uint32_t frame      : 20;
} page_dir_entry_t;


typedef struct
{
    uint32_t present    : 1;
    uint32_t rw         : 1;
    uint32_t user       : 1;
    uint32_t reserved   : 2;
    uint32_t accessed   : 1;
    uint32_t dirty      : 1;
    uint32_t reserved2  : 2;
    uint32_t available  : 3;
    uint32_t frame      : 20;
} page_t;

typedef struct
{
    page_t pages[1024];
} page_table_t;

typedef struct
{
    page_dir_entry_t tables[1024];
    page_table_t* ref_tables[1024];
} page_dir_t;

void alloc_page(page_dir_t* dir, uint32_t virtual_addr, uint32_t frame, int writeable, int kernel);

void alloc_range(page_dir_t* dir, uint32_t start_vaddr, uint32_t end_vaddr, int writeable, int kernel);

void free_page(page_dir_t* dir, uint32_t virtual_addr, int free);

void free_range(page_dir_t* dir, uint32_t start_vaddr, uint32_t end_vaddr, int free);

void switch_page_dir(page_dir_t* page_dir);

void init_vmm();

#endif
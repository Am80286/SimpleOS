#include <vmm.h>
#include <pmm.h>
#include <stdint.h>
#include <libc.h>
#include <arch/interrupts.h>
#include <kernel.h>
#include <vga.h>

static void* placement_address;

static int kheap_initialized = 0;

static page_dir_t* kernel_page_dir;


void* virt2phys(page_dir_t* dir, void* virtual_addr) 
{
    uint32_t dir_idx = PAGEDIR_INDEX(virtual_addr);
    uint32_t table_idx = PAGETABLE_INDEX(virtual_addr);
    uint32_t frame_offset = PAGEFRAME_INDEX(virtual_addr);

    if(!dir->ref_tables[dir_idx])
        return NULL;

    page_table_t* table = dir->ref_tables[dir_idx];

    if(!table->pages[table_idx].present)
        return NULL;

    uint32_t t = table->pages[table_idx].frame;
    t = (t << 12) + frame_offset;
    return (void*)t;
}

static void* placement_kmalloc(size_t size, int align)
{
    void* ret = placement_address;

    if(align && NOT_ALIGN(ret))
        ret = (void*) PAGE_ALIGN(ret);

    placement_address = placement_address + size;
    return ret;
}

void alloc_page(page_dir_t* dir, uint32_t virtual_addr, uint32_t frame, int writeable, int kernel)
{   
    uint32_t dir_idx = PAGEDIR_INDEX(virtual_addr);
    uint32_t table_idx = PAGETABLE_INDEX(virtual_addr);
    page_table_t* table = NULL;

    table = dir->ref_tables[dir_idx];

    if(!table){
        if(!kheap_initialized)
            table = placement_kmalloc(sizeof(page_table_t), 1);

        memset(table, 0, sizeof(page_table_t));

        dir->tables[dir_idx].frame = (uint32_t)table >> 12;
        dir->tables[dir_idx].present = 1;
        dir->tables[dir_idx].rw = (writeable) ? 1:0;
        dir->tables[dir_idx].user = (kernel) ? 0:1;
        dir->tables[dir_idx].page_size = 0;
    
        dir->ref_tables[dir_idx] = table;
    }

    if(!table->pages[table_idx].present){
        uint32_t f;

        if(frame)
            f = frame;
        else
            f = alloc_block();

        table->pages[table_idx].frame = f;
        table->pages[table_idx].present = 1;
        table->pages[table_idx].rw = (writeable) ? 1:0;
        table->pages[table_idx].user = (kernel) ? 0:1;
    }
}

void alloc_range(page_dir_t* dir, uint32_t start_vaddr, uint32_t end_vaddr, int writeable, int kernel)
{
    uint32_t start = start_vaddr & 0xFFFFF000;
    uint32_t end = end_vaddr & 0xFFFFF000;

    for(int i = start; i <= end; i += PAGE_SIZE){
        alloc_page(dir, i, 0, writeable, kernel);
    }
}

void free_page(page_dir_t* dir, uint32_t virtual_addr, int free)
{
    uint32_t dir_idx = PAGEDIR_INDEX(virtual_addr);
    uint32_t table_idx = PAGETABLE_INDEX(virtual_addr);
    
    page_table_t* table = dir->ref_tables[dir_idx];

    if(!table)
        panic("Attempted to free memory in a nonexistent page directory");

    if(!table->pages[table_idx].present)
        panic("Attempted to free a nonexistent page");

    if(free)
        free_block(table->pages[table_idx].frame);

    table->pages[table_idx].present = 0;
    table->pages[table_idx].frame = 0;
}

void free_range(page_dir_t* dir, uint32_t start_vaddr, uint32_t end_vaddr, int free)
{
    uint32_t start = start_vaddr & 0xFFFFF000;
    uint32_t end = end_vaddr & 0xFFFFF000;

    for(int i = start; i <= end; i += PAGE_SIZE){
        free_page(dir, i, free);
    }
}

void switch_page_dir(page_dir_t* page_dir)
{
    uint32_t dir = (uint32_t) page_dir;
    asm volatile("mov %0, %%cr3" :: "r"(dir));
}

static void enable_paging()
{
    uint32_t cr0;

    asm volatile("mov %%cr0, %0" : "=r"(cr0));
    SET_PGBIT(cr0);
    asm volatile("mov %0, %%cr0" :: "r"(cr0));
}

void init_vmm()
{
    placement_address = pmm_bitmap + pmm_bitmap_size;

    kernel_page_dir = placement_kmalloc(sizeof(page_dir_t), 1);
    memset(kernel_page_dir, 0, sizeof(page_dir_t));

    alloc_range(kernel_page_dir, 0x0, 0x200000, 1, 1);

    switch_page_dir(kernel_page_dir);
    
    enable_paging();
}

// Called in the page_fault_stub in idt_helper.asm
void page_fault_handler(registers_t* regs, uint32_t cr2)
{
    uint32_t fault_addr = cr2;

    // Gathering info about the fault
    int present   = !(regs->err_code & 0x1);          // Page not present
    int write = regs->err_code & 0x2;                 // Write operation?
    int user = regs->err_code & 0x4;                  // Processor was in user-mode?
    int reserved = regs->err_code & 0x8;              // Overwritten CPU-reserved bits of page entry?
    int instruction = regs->err_code & 0x10;          // Caused by an instruction fetch?

    scrprintf("Page fault occured at: 0x%x\nCaused by ", fault_addr);

    if (write){
        scrprintf("a write operation\n");
    } else if (instruction){
        scrprintf("an instruction fetch\n");
    } else {
        scrprintf("a read operation\n");
    }

    if (user){
        scrprintf("CPU was in user mode\n");
    }

    if (present){
        scrprintf("Page not present\n");
    }

    if (reserved) {
        scrprintf("Reserved bits overwritten\n");
    }

    panic("");
}


#ifndef PCI_H
#define PCI_H

#include <stdint.h>

typedef union
{
    uint32_t bits;
    struct
    {   
        uint32_t always_zero    : 2;
        uint32_t register_off   : 6;
        uint32_t function_num   : 3;
        uint32_t device_num     : 5;
        uint32_t bus_num        : 8;
        uint32_t reserved       : 7;
        uint32_t enable         : 1;
    };
    
} pci_dev_t;

// IO Ports
#define PCI_CONFIG_ADDRESS  0xCF8
#define PCI_CONFIG_DATA     0xCFC

// Device types
#define PCI_HEADER_TYPE_DEVICE      0x00
#define PCI_HEADER_TYPE_BRIDGE      0x01
#define PCI_HEADER_TYPE_CARDBUS     0x02
#define PCI_TYPE_ATA                0x0105
#define PCI_TYPE_BRIDGE             0x0604

#define PCI_VENDOR_NONE                0xFFFF

// Config register offsets 
#define PCI_VENDOR_ID            0x00
#define PCI_DEVICE_ID            0x02
#define PCI_COMMAND              0x04
#define PCI_STATUS               0x06
#define PCI_REVISION_ID          0x08
#define PCI_PROG_IF              0x09
#define PCI_SUBCLASS             0x0a
#define PCI_CLASS                0x0b
#define PCI_CACHE_LINE_SIZE      0x0c
#define PCI_LATENCY_TIMER        0x0d
#define PCI_HEADER_TYPE          0x0e
#define PCI_BIST                 0x0f
#define PCI_BAR0                 0x10
#define PCI_BAR1                 0x14
#define PCI_BAR2                 0x18
#define PCI_BAR3                 0x1C
#define PCI_BAR4                 0x20
#define PCI_BAR5                 0x24
#define PCI_INTERRUPT_LINE       0x3C
#define PCI_SECONDARY_BUS        0x09

#define PCI_DEVICES_ON_BUS 32
#define PCI_FUNCTIONS_ON_DEVICE 32

uint16_t pci_get_device_type(pci_dev_t dev);

uint32_t pci_read(pci_dev_t dev, uint8_t register_off);

void pci_write(pci_dev_t dev, uint8_t register_off, uint32_t value);

pci_dev_t pci_get_device_by_id(uint16_t dev_id, uint16_t ven_id, uint16_t dev_type);

pci_dev_t pci_get_device_by_type(uint16_t dev_type);

void init_pci();

#endif
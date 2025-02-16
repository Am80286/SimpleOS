#include <pci.h>
#include <arch/io.h>
#include <vga.h>

static uint8_t pci_size_map[100];

static pci_dev_t pci_null_dev = { 0 };

uint32_t pci_read(pci_dev_t dev, uint8_t register_off)
{
    dev.enable = 1;
    dev.register_off = (register_off & 0xFC) >> 2;

    outl(PCI_CONFIG_ADDRESS, dev.bits);

    uint32_t ret;

    switch (pci_size_map[register_off]){
        case 8:
            ret = inb(PCI_CONFIG_DATA + (register_off & 3));
            return ret; 
        case 16:
            ret = inw(PCI_CONFIG_DATA + (register_off & 2));
            return ret;
        case 32:
            ret = inl(PCI_CONFIG_DATA);
            return ret;
    }

    return 0xFFEF;
}

void pci_write(pci_dev_t dev, uint8_t register_off, uint32_t value)
{
    dev.enable = 1;
    dev.register_off = (register_off & 0xFC) >> 2;

    outl(PCI_CONFIG_ADDRESS, dev.bits);

    outl(PCI_CONFIG_DATA, value);
}

uint16_t pci_get_device_type(pci_dev_t dev)
{
    uint16_t ret = pci_read(dev, PCI_CLASS) << 8;
    return ret | pci_read(dev, PCI_SUBCLASS);
}

static uint8_t pci_get_secondary_bus(pci_dev_t dev){
    return pci_read(dev, PCI_SECONDARY_BUS);
}

static uint8_t pci_end_reached(pci_dev_t dev)
{
    uint8_t ret = pci_read(dev, PCI_HEADER_TYPE);
    return !ret;
}

// Temporary declaration
static pci_dev_t pci_scan_bus_for_type(uint16_t dev_type, uint8_t bus);

static pci_dev_t pci_check_function_for_type(uint8_t func, uint8_t dev, uint16_t dev_type, uint8_t bus)
{
    pci_dev_t pci_dev = { 0 };
    pci_dev.device_num = dev;
    pci_dev.bus_num = bus;
    pci_dev.function_num = func;

    /*
    if(pci_get_device_type(pci_dev) == PCI_TYPE_BRIDGE){
        pci_scan_bus_for_type(dev_type, pci_get_secondary_bus(pci_dev));
    }
    */
    
    if(dev_type == pci_get_device_type(pci_dev))
        return pci_dev;

    return pci_null_dev;
}

static pci_dev_t pci_scan_device_for_type(uint16_t dev_type, uint8_t bus, uint8_t dev)
{
    pci_dev_t pci_dev = { 0 };
    pci_dev.device_num = dev;
    pci_dev.bus_num = bus;

    if(pci_read(pci_dev, PCI_VENDOR_ID) == PCI_VENDOR_NONE)
        return pci_null_dev;

    pci_dev_t ret = pci_check_function_for_type(0, dev, dev_type, bus);
    
    if(ret.bits)
        return ret;

    for(int func = 1; func < PCI_FUNCTIONS_ON_DEVICE; func++){
        if(pci_read(pci_dev, PCI_VENDOR_ID) != PCI_VENDOR_NONE){
            ret = pci_check_function_for_type(func, dev, dev_type, bus);
            if(ret.bits)
                return ret;
        }
    }
    
    return pci_null_dev;
}

static pci_dev_t pci_scan_bus_for_type(uint16_t dev_type, uint8_t bus)
{
    for(int dev = 0; dev < PCI_DEVICES_ON_BUS; dev++){
        pci_dev_t ret = pci_scan_device_for_type(dev_type, bus, dev);
        
        if(ret.bits)
            return ret;
    }
    
    return pci_null_dev;
}

// Temporary declaration
static pci_dev_t pci_scan_bus_for_id(uint8_t bus, uint16_t dev_id, uint16_t ven_id, uint16_t dev_type);

static pci_dev_t pci_check_function_for_id(uint8_t func, uint8_t dev, uint16_t dev_type, uint16_t dev_id, uint16_t ven_id, uint8_t bus)
{
    pci_dev_t pci_dev = { 0 };
    pci_dev.device_num = dev;
    pci_dev.bus_num = bus;
    pci_dev.function_num = func;

    /*
    if(pci_get_device_type(pci_dev) == PCI_TYPE_BRIDGE){
        pci_scan_bus_for_id(pci_get_secondary_bus(pci_dev), dev_id, ven_id, dev_type);
    }
    */

    if(dev_type == 0xffff || dev_type == pci_get_device_type(pci_dev)){
        uint16_t devid = pci_read(pci_dev, PCI_DEVICE_ID);
        uint16_t venid = pci_read(pci_dev, PCI_VENDOR_ID);

        if(dev_id == devid && ven_id == venid)
            return pci_dev;
    }

    return pci_null_dev;
}

static pci_dev_t pci_scan_device_for_id(uint16_t dev_id, uint16_t ven_id, uint8_t bus, uint8_t dev, uint16_t dev_type)
{
    pci_dev_t pci_dev = { 0 };
    pci_dev.device_num = dev;
    pci_dev.bus_num = bus;

    if(pci_read(pci_dev, PCI_VENDOR_ID) == PCI_VENDOR_NONE)
        return pci_null_dev;

    pci_dev_t ret = pci_check_function_for_id(0, dev, dev_type, dev_id, ven_id, bus);
    
    if(ret.bits)
        return ret;

    for(int func = 1; func < PCI_FUNCTIONS_ON_DEVICE; func++){
        if(pci_read(pci_dev, PCI_VENDOR_ID) != PCI_VENDOR_NONE){
            ret = pci_check_function_for_id(func, dev, dev_type, dev_id, ven_id, bus);
            if(ret.bits)
                return ret;
        }
    }

    return pci_null_dev;
}

static pci_dev_t pci_scan_bus_for_id(uint8_t bus, uint16_t dev_id, uint16_t ven_id, uint16_t dev_type)
{
    for(int dev = 0; dev < PCI_DEVICES_ON_BUS; dev++){
        pci_dev_t ret = pci_scan_device_for_id(dev_id, ven_id, bus, dev, dev_type);
        
        if(ret.bits)
            return ret;
    }
    
    return pci_null_dev;
}

pci_dev_t pci_get_device_by_id(uint16_t dev_id, uint16_t ven_id, uint16_t dev_type)
{
    pci_dev_t ret = pci_scan_bus_for_id(0, dev_id, ven_id, dev_type);
    if(ret.bits)
        return ret;

    for(int func = 1; func < PCI_FUNCTIONS_ON_DEVICE; func++){
        pci_dev_t dev = { 0 };
        dev.function_num = func;

        if(pci_read(dev, PCI_VENDOR_ID) == PCI_VENDOR_NONE)
            break;

        ret = pci_scan_bus_for_id(func, dev_id, ven_id, dev_type);
        if(ret.bits)
            return ret;
    }

    return pci_null_dev;
}

pci_dev_t pci_get_device_by_type(uint16_t dev_type)
{
    pci_dev_t ret = pci_scan_bus_for_type(dev_type, 0);
    if(ret.bits)
        return ret;

    for(int func = 1; func < PCI_FUNCTIONS_ON_DEVICE; func++){
        pci_dev_t dev = { 0 };
        dev.function_num = func;

        if(pci_read(dev, PCI_VENDOR_ID) == PCI_VENDOR_NONE)
            break;

        ret = pci_scan_bus_for_type(dev_type, func);
        if(ret.bits)
            return ret;
    }

    return pci_null_dev;
}

static void pci_size_map_init()
{
    pci_size_map[PCI_VENDOR_ID] =	16;
	pci_size_map[PCI_DEVICE_ID] =	16;
	pci_size_map[PCI_COMMAND]	=	16;
	pci_size_map[PCI_STATUS]	=	16;
	pci_size_map[PCI_SUBCLASS]	=	8;
	pci_size_map[PCI_CLASS]		=	8;
	pci_size_map[PCI_CACHE_LINE_SIZE]	= 8;
	pci_size_map[PCI_LATENCY_TIMER]		= 8;
	pci_size_map[PCI_HEADER_TYPE] = 8;
	pci_size_map[PCI_BIST] = 8;
	pci_size_map[PCI_BAR0] = 32;
	pci_size_map[PCI_BAR1] = 32;
	pci_size_map[PCI_BAR2] = 32;
	pci_size_map[PCI_BAR3] = 32;
	pci_size_map[PCI_BAR4] = 32;
	pci_size_map[PCI_BAR5] = 32;
	pci_size_map[PCI_INTERRUPT_LINE]	= 8;
	pci_size_map[PCI_SECONDARY_BUS]		= 8;
}

void init_pci()
{
    pci_size_map_init();
    // May add some stuff later
}
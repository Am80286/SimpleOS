OUTPUT_FORMAT("binary")
OUTPUT_ARCH("i386")

ENTRY(BOOT_START)
STARTUP(build/bootloader/loader.o)
SECTIONS {
	. = 0x8000;
	.text BLOCK(4K) : ALIGN(4K)
	{
		*(.text)
	}
	data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)
	}

	 end = .;
}
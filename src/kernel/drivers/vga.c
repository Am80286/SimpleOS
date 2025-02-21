#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <unistd.h>
#include <arch/io.h>
#include <vga.h>

uint16_t terminal_row;
uint16_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;

static char str_buff[1024];

static inline uint8_t vga_entry_color(enum vga_color foregrund, enum vga_color background) 
{
	return foregrund | background << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) 
{
	return (uint16_t) uc | (uint16_t) color << 8;
}


static void put_entry_at_terminal(char c, uint8_t color, size_t x, size_t y) 
{
	const size_t index = y * VGA_WIDTH + x;
	terminal_buffer[index] = vga_entry(c, color);
}

void update_cursor(int x, int y)
{
	uint16_t pos = y * VGA_WIDTH + x;

	outb(0x3D4, 0x0F);
	outb(0x3D5, (uint8_t) (pos & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}

volatile void scroll_terminal(uint16_t lines)
{
	if(lines < 1)
		return;

	memset(terminal_buffer + VGA_WIDTH * VGA_HEIGHT, 0, VGA_WIDTH);
	
	for(uint16_t i = 0; i < lines; i++){
		for(int i = 1; i <= VGA_HEIGHT; i++){
			memcpy(terminal_buffer + VGA_WIDTH * i, terminal_buffer + VGA_WIDTH * (i - 1), VGA_WIDTH);
		}
		
		terminal_row--;
	}

	update_cursor(terminal_column, terminal_row);
}

void write_terminal(const char* data, size_t size)
{
	for (size_t i = 0; i < size; i++)
		scrputc(data[i]);
}

void init_terminal(void) 
{
	if(terminal_color == 0)
		terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
		
	terminal_row = 0;
	terminal_column = 0;

	update_cursor(terminal_column, terminal_row);

	terminal_buffer = (uint16_t*) VGA_VIDEO_BUFF;
	for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			terminal_buffer[index] = vga_entry(' ', terminal_color);
		}
	}
}

void scrputs(const char* data) 
{
	write_terminal(data, strlen(data));
	update_cursor(terminal_column, terminal_row);
}

void scrputc(char c)
{
	if(terminal_row + 1 == VGA_HEIGHT)
		scroll_terminal(1);

	switch (c){
		case '\x7f':
		case '\b':
			terminal_column--;
			break;
		case '\r':
		case '\n':
			terminal_column = 0;
			terminal_row++;
			break;
		default:
			put_entry_at_terminal(c, terminal_color, terminal_column, terminal_row);
			
			if(++terminal_column == VGA_WIDTH){
				terminal_column = 0;
				terminal_row++;
			}

			break;
	}

	if(terminal_row + 1 == VGA_HEIGHT)
		scroll_terminal(1);

	update_cursor(terminal_column, terminal_row);
}

void set_terminal_color(uint8_t color) 
{
	terminal_color = color;
}

int scrprintf(const char *fmt, ...)
{
   va_list args;
   va_start(args, fmt);
   int ret = vsprintf(str_buff, fmt, args);
   scrputs(str_buff);
   va_end(args);

   return ret;
}
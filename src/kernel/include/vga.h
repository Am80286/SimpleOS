#ifndef SCREEN_H
#define SCREEN_H

#include <stddef.h>
#include <stdint.h>
#include <libc.h>

#define VGA_VIDEO_BUFF 0xB8000

#define VGA_WIDTH 80
#define VGA_HEIGHT 25

/* BIOS color attributes */
enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
};

void init_terminal(void);

void set_terminal_color(uint8_t color);

void write_terminal(const char* data, size_t size);

void scroll_terminal(uint16_t lines);

void scrputs(const char* data);

void scrputc(char c);

int scrprintf(const char *fmt, ...);

#endif
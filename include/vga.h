#pragma once
#include <stddef.h>
#include <stdint.h>

enum VgaColor {
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

static inline uint8_t vga_color(enum VgaColor fg, enum VgaColor bg) {
    return ((uint8_t) fg) | ((uint8_t) bg << 4);
}

static inline uint16_t vga_entry(char c, uint8_t color) {
    return ((uint16_t) c) | ((uint16_t) color << 8);
}

void terminal_put_entry(uint16_t entry, size_t col, size_t row);
void terminal_put_char(char c);
void terminal_put_str(const char *str);
void terminal_init(void);

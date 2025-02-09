#include <stddef.h>
#include <stdint.h>

#define MIN(x, y) ((x) < (y) ? (x) : (y))

static inline void outb(uint16_t port, uint8_t value) {
    __asm__ volatile ("outb %b0, %w1" : : "a"(value), "Nd"(port) : "memory");
}

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
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char c, uint8_t color) {
    return ((uint16_t) c) | ((uint16_t) color << 8);
}

struct {
    uint16_t *buffer;
    size_t col;
    size_t row;
    uint8_t color;
    size_t width;
    size_t height;
} terminal;

static void terminal_put_entry(uint16_t entry, size_t col, size_t row) {
    col = MIN(col, terminal.width);
    row = MIN(row, terminal.height);
    size_t index = row * terminal.width + col;
    terminal.buffer[index] = entry;
}

static void terminal_put_char(char c) {
    if (c == '\n') {
        terminal.col = 0;
        terminal.row++;
    } else {
        uint16_t entry = vga_entry(c, terminal.color);
        terminal_put_entry(entry, terminal.col, terminal.row);
        terminal.col++;
    }

    if (terminal.col >= terminal.width) {
        terminal.col = 0;
        terminal.row++;
    }

    if (terminal.row >= terminal.height) {
        terminal.row = 0;
    }
}

static void terminal_put_str(const char *str) {
    while (*str) {
        terminal_put_char(*str);
        ++str;
    }
}

static void terminal_init(void) {
    // Disable the cursor on the hardware level first.
    outb(0x3D4, 0x0A);
	outb(0x3D5, 0x20);

    // Now prepare to write to video memory.
    terminal.buffer = (uint16_t*) 0xB8000;
    terminal.col = 0;
    terminal.row = 0;
    terminal.color = vga_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    terminal.width = 80;
    terminal.height = 25;

    uint16_t default_entry = vga_entry(' ', terminal.color);
    for (size_t row = 0; row < terminal.height; ++row) {
        for (size_t col = 0; col < terminal.width; ++col) {
            terminal_put_entry(default_entry, col, row);
        }
    }
}

void kernel_main(void) {
    terminal_init();
    terminal_put_str("Hello, World!\n");
}

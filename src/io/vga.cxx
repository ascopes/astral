#include "astral/io/vga.hxx"

#define MIN(x, y) ((x) < (y) ? (x) : (y))

struct {
    uint16_t *buffer;
    size_t col;
    size_t row;
    uint8_t color;
    size_t width;
    size_t height;
} terminal;

static inline void outb(uint16_t port, uint8_t value) {
    __asm__ volatile ("outb %b0, %w1" : : "a"(value), "Nd"(port) : "memory");
}

void terminal_put_entry(uint16_t entry, size_t col, size_t row) {
    col = MIN(col, terminal.width);
    row = MIN(row, terminal.height);
    size_t index = row * terminal.width + col;
    terminal.buffer[index] = entry;
}

void terminal_put_char(char c) {
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

void terminal_put_str(const char *str) {
    while (*str) {
        terminal_put_char(*str);
        ++str;
    }
}

void terminal_init(void) {
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

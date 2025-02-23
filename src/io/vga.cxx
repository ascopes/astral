#include "astral/io/port.hxx"
#include "astral/io/vga.hxx"

namespace astral::io::vga {

static uint16_t *const VGA_MEMORY_ADDR = (uint16_t *) 0xB8000;
static constexpr size_t VGA_WIDTH = 80;
static constexpr size_t VGA_HEIGHT = 25;

static inline uint16_t vga_entry(char c, VgaColor fg, VgaColor bg) {
    uint16_t color = static_cast<uint16_t>(fg) | static_cast<uint16_t>(bg) << 4;
    return color << 8 | c;
}

VgaDevice::VgaDevice()
    : fg(VgaColor::LIGHT_GREY)
    , bg(VgaColor::BLACK)
    , col(0)
    , row(0)
{
    this->disable_cursor();
    for (size_t index = 0; index < VGA_WIDTH * VGA_HEIGHT; index++) {
        VGA_MEMORY_ADDR[index] = vga_entry(' ', VgaColor::BLACK, VgaColor::BLACK);
    }
}

void VgaDevice::disable_cursor() {
    astral::io::port::outb(0x3D4, 0x0A);
    astral::io::port::outb(0x3D5, 0x20);
}

void VgaDevice::enable_cursor(size_t cursor_start, size_t cursor_end) {
    uint8_t value;

    astral::io::port::outb(0x3D4, 0x0A);
    value = static_cast<uint8_t>((astral::io::port::inb(0x3D5) & 0xC0) | cursor_start);
    astral::io::port::outb(0x3D5, value);

    astral::io::port::outb(0x3D4, 0x0B);
    value = static_cast<uint8_t>((astral::io::port::inb(0x3D5) & 0xE0) | cursor_end);
    astral::io::port::outb(0x3D5, value);
}

VgaCursorPosition VgaDevice::get_cursor_position() const {
    // TODO: implement
    return VgaCursorPosition{};
}

bool VgaDevice::set_cursor_position(size_t x, size_t y) {
    // TODO: implement
    (void) x;
    (void) y;
    return true;
}

void VgaDevice::set_color(VgaColor fg, VgaColor bg) {
    this->fg = fg;
    this->bg = bg;
}

bool VgaDevice::write_char(char c, size_t x, size_t y) {
    if (x >= VGA_WIDTH || y >= VGA_HEIGHT) {
        return false;
    }

    size_t index = x + y * VGA_WIDTH;
    VGA_MEMORY_ADDR[index] = vga_entry(c, this->fg, this->bg);
    return true;
}

void VgaDevice::print(const char *text) {
    char c;
    while ((c = *text)) {
        if (c == '\n') {
            this->col = 0;
            this->row++;
        } else {
            this->write_char(c, this->col, this->row);
            this->col++;
        }

        if (this->col >= VGA_WIDTH) {
            this->col = 0;
            this->row++;
        }

        if (this->row >= VGA_HEIGHT) {
            // Scroll by moving all but the first line back to the first line.
            for (size_t index = VGA_WIDTH; index < VGA_WIDTH * VGA_HEIGHT; index++) {
                VGA_MEMORY_ADDR[index - VGA_WIDTH] = VGA_MEMORY_ADDR[index];
            }
            // Clear the current line
            for (size_t index = VGA_WIDTH * (VGA_HEIGHT - 1); index < VGA_WIDTH * VGA_HEIGHT; index++) {
                VGA_MEMORY_ADDR[index] = vga_entry(' ', this->fg, this->bg);
            }
            
            this->row = VGA_HEIGHT - 1;
        }

        text++;
    }

    set_cursor_position(row, col);
}

} // astral::io::vga

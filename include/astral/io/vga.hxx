#pragma once
#include <stddef.h>
#include <stdint.h>

namespace astral::io::vga {

enum class VgaColor : uint8_t {
    BLACK = 0,
    BLUE = 1,
    GREEN = 2,
    CYAN = 3,
    RED = 4,
    MAGENTA = 5,
    BROWN = 6,
    LIGHT_GREY = 7,
    DARK_GREY = 8,
    LIGHT_BLUE = 9,
    LIGHT_GREEN = 10,
    LIGHT_CYAN = 11,
    LIGHT_RED = 12,
    LIGHT_MAGENTA = 13,
    LIGHT_BROWN = 14,
    WHITE = 15,
};

struct VgaCursorPosition {
    const size_t x;
    const size_t y;
};

class VgaDevice final {
public:
    explicit VgaDevice();
    void disable_cursor();
    void enable_cursor(size_t cursor_start, size_t cursor_end);
    VgaCursorPosition get_cursor_position() const;
    bool set_cursor_position(size_t x, size_t y);
    void set_color(VgaColor fg, VgaColor bg);
    bool write_char(char c, size_t x, size_t y);
    void print(const char *text);

private:
    VgaColor fg;
    VgaColor bg;
    size_t col;
    size_t row;
};

} // namespace astral::io::vga

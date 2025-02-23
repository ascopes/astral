#include "astral/io/vga.hxx"

extern "C" void kernel_main() {
    terminal_init();
    terminal_put_str("Hello, World!\n");
}

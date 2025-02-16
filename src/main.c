#include "vga.h"

void kernel_main(void) {
    terminal_init();
    terminal_put_str("Hello, World!\n");
}

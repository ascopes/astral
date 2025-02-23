#include "astral/io/vga.hxx"

extern "C" void kernel_main() {
    using namespace astral::io::vga;

    VgaDevice vga;
    
    for (size_t i = 0; i < 10000; i++) {
        vga.print("Hello, World! ");
    }
    vga.print("\n");
    vga.print("The end");
}

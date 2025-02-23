#include "astral/io/vga.hxx"

extern "C" void kernel_main() {
    using namespace astral::io::vga;

    VgaDevice vga;
    
    for (size_t i = 0; i < 2001; i++) {
        vga.set_color(static_cast<VgaColor>(1 + i % 15), VgaColor::BLACK);
        vga.print("Hello, World! ");
    }
    vga.print("\n");
    vga.set_color(VgaColor::LIGHT_GREY, VgaColor::BLACK);
    vga.print("The end!");
}

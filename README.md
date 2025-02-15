# astral

Toy OS.

## Requirements

1. Make a GCC crosscompiler, Binutils, and GDB by running `toolchains/compiler/build.sh -a i686-elf`.
2. Install `qemu`, `grub2-mkrescue`, and `xorriso` on the local machine.

## Building

1. Add the cross-compiler to your local shell environment variables with `source ./toolchains/compiler/activate.sh`.
2. Run `make clean build run`.

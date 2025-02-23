# astral

Toy OS.

## Requirements

1. Make the crosscompiler with `./cross-compiler/build.sh -a i686-elf`. This needs Docker or 
   Podman installed to work.
2. Install grub2 and xorriso locally if you wish to build executable ISOs. This would be provided
   in the cross-compiler build scripts but unfortunately I am unable to get a working build of GRUB
   to build from scratch at the time of writing.
3. Install `qemu` if you want to run the image in an emulator... or use VirtualBox or something else.

## Building

1. Run `make clean build run`.

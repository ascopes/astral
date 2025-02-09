# toolchains/compiler

This directory contains a script `build.sh` which can be run to download and build
GNU Binutils, GCC, and GDB into a container running in either Docker or Podman. The
build results are then extracted to the current directory to allow the invocation of
these tools.

The purpose of this is to allow building the host-specific toolchains required to build
native binaries without needing to taint the host development environment with specific
dependencies that may conflict with system-provided versions of the same tools.

## Limitations

This will only work on Linux. On Windows and MacOS, you may need to run a VM or build
your toolchain separately.

## Usage

```commandline
./build.sh -a i686-elf
```

Once this is run, you can add `out/bin` to your `$PATH`. If you are using bash, then you
can just run the following:

```commandline
source ./activate.sh
```

## Notes

### Patching GCC

GCC has to be patched for x86_64 to remove the red zone from libgcc. See
https://wiki.osdev.org/Libgcc_without_red_zone for details.

We do this via a patch in this directory. You might have to recreate this patch
when updating the GCC version. If you do need to do that, make a new patch by
copying `src/gcc-${GCC_VERSION}/gcc/config.gcc` to a local directory, and make a copy
of it there so you have two files (e.g. config.gcc.old and config.gcc). Apply the change
to `config.gcc` only, then run 
`diff -Naru config.gcc.old config.gcc > gcc_x86_64-elf-redzone.patch` to create a new
patch file.

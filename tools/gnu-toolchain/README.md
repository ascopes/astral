# tools/gnu-toolchain

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

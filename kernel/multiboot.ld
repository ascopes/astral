ENTRY(_start)
SECTIONS {
    /*
     * Historically, a 1MIB offset was the recommended place to start, but sources
     * state that UEFI has complicated this somewhat, and in 2016, the multiboot2
     * spec was updated to inform bootloders that we can use anything in a range
     * of addresses as the entrypoint. For now, use 2MiB to be safe.
     */
    . = 2M;

    /*
     * Multiboot header must go first, followed by the text section of the program
     * holding instructions.
     */
    .text BLOCK(4K) : ALIGN(4K)
    {
        *(.multiboot)
        *(.text)
    }

    /* 
     * Readonly data segment.
     */
    .rodata BLOCK(4K) : ALIGN(4K) {
        *(.rodata)
    }

    /* 
     * Read-write initialised data segment.
     */
    .data BLOCK(4K) : ALIGN(4K) {
        *(.data)
    }

    /* 
     * Read-write uninitialised data, and our stack.
     */
    .bss BLOCK(4K) : ALIGN(4K) {
        *(COMMON)
        *(.bss)
    }
}

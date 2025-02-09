# Multiboot v2 entrypoint for the Astral Kernel.
# See https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html
.set MAGIC,         0xE85250D6
.set ARCHITECTURE,  0   # 0 = 32bit protected mode, 4 = MIPS.
.set HEADER_LENGTH, multiboot_end - multiboot_start
.set CHECKSUM,      -(MAGIC + ARCHITECTURE + HEADER_LENGTH)

# The multiboot header.
.section .multiboot
.align 4
multiboot_start:
.long MAGIC
.long ARCHITECTURE
.long HEADER_LENGTH
.long CHECKSUM
.short 0
.short 0
.long  8
multiboot_end:

# We have to set up the initial stack. We will use a 16KiB stack for this
# purpose which will be defined in-memory here and configured within _start
# further down this file.
#
# The System V ABI specifies that this must be 16-byte aligned and grows
# downwards for x86 systems.
.section .bss
.align 16
.set STACK_SIZE, 16384
stack_bottom:
.skip STACK_SIZE
stack_top:

# The linker script will use this as the core entrypoint that the bootloader
# jumps to. This can never "return" as there is physically nothing else we
# can return to.
.section .text
.global _start
.type _start, @function
_start:
    # The following describes the current state of the computer at this point
    # in time:
    #
    # - We are on an x86-compatible processor.
    # - We are in 32-bit protected mode.
    # - We are in the state defined by the multiboot standard:
    #     - The EAX register holds the value 0x2BADB002 (not a typo) - tells us
    #       we are definitely being called by a multiboot-compliant bootloader.
    #     - The EBX register holds the 32-bit physical address of the multiboot 
    #       information structure provided by the bootloader 
    #       in "boot information format" 
    #       (see https:#www.gnu.org/software/grub/manual/multiboot/multiboot.html#Boot-information-format).
    #     - The A20 gate must be enabled.
    #     - The CR0 register must have bit 31 (PG) cleared and bit 0 (PE) set.
    #     - The EFLAGS register must have bit 17 (VM) cleared and bit 9 (IF) 
    #       cleared.
    # - We have full control of the CPU.
    # - We have no libraries or code loaded outside what we have defined.1
    # - We have no security restrictions.
    # - We have no safeguards.
    # - We have no debugging mechanisms.
    # - We have no stack configured.

    # First off, set up the stack.
    mov $stack_top, %esp

    # Initialise critical processor state here. Eventually we can set things like
    # the GDT, paging, etc here.

    # Enter the high level kernel.
    call kernel_main
    jmp _hang

# This should be unreachable, but if it is reached, then put the system in
# a permanent hang loop. We clear interrupts, then wait for the next interrupt
# to arrive with the halt instruction before repeating again indefinitely. This
# prevents us just executing the rest of this binary and exhibiting undefined
# behaviour.
_hang:
    cli
    hlt
    jmp _hang

# Useful information for stack unwinding/call tracing later on.
.size _start, . - _start

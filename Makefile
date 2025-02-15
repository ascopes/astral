TARGET := i686-elf
QEMU_TARGET := i386

TOOLCHAINS_DIR := toolchains/compiler/out/bin

AS := $(TOOLCHAINS_DIR)/$(TARGET)-as
CC := $(TOOLCHAINS_DIR)/$(TARGET)-gcc
LD := $(TOOLCHAINS_DIR)/$(TARGET)-ld
GRUB_MKRESCUE := grub2-mkrescue

ASFLAGS := 
CFLAGS  := \
	-Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align \
	-Wwrite-strings -Wmissing-prototypes -Wmissing-declarations \
	-Wredundant-decls -Wnested-externs -Winline -Wno-long-long \
	-Wconversion -Wstrict-prototypes \
	-Werror \
	-O0 -ggdb \
	-std=c17 \
	-ffreestanding
LDFLAGS := \
	-static \
	-nostdlib \
	-lgcc

C_SOURCES := $(shell find src/ -name "*.c" -type f -print)
ASM_SOURCES := $(shell find src/ -name "*.s" -type f -print)

OBJECTS := \
	$(patsubst src/%.c,obj/%.c.o,$(C_SOURCES)) \
	$(patsubst src/%.s,obj/%.s.o,$(ASM_SOURCES))
	
KERNEL_BIN := obj/astral.bin
KERNEL_ISO := obj/astral.iso

.PHONY: build clean
build: $(KERNEL_BIN) $(KERNEL_ISO)

clean:
	$(RM) -Rf obj/

run: build
	@-echo "QEMU will start paused. Go to machine > pause to unpause it."
	qemu-system-$(QEMU_TARGET) -S -s -cdrom $(KERNEL_ISO)

$(KERNEL_ISO): $(KERNEL_BIN)
	mkdir -p $(KERNEL_ISO).dir/boot/grub
	cp -v grub.cfg $(KERNEL_ISO).dir/boot/grub/grub.cfg
	cp -v $(KERNEL_BIN) $(KERNEL_ISO).dir/boot/kernel.img
	$(GRUB_MKRESCUE) -o $@ $(KERNEL_ISO).dir/

$(KERNEL_BIN): $(OBJECTS)
	$(CC) -T linker.ld $(LDFLAGS) $^ -o $@

obj/%.c.o: src/%.c obj
	$(CC) $(CFLAGS) -c $< -o $@ 

obj/%.s.o: src/%.s obj
	$(AS) $(ASFLAGS) $< -o $@

obj:
	mkdir $@

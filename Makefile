TARGET = i686-elf
QEMU_TARGET = i386
LD_TARGET = elf_i386 

# Tools
TOOLCHAINS_DIR = toolchains/compiler/out/bin
AS = $(TOOLCHAINS_DIR)/$(TARGET)-as
CC = $(TOOLCHAINS_DIR)/$(TARGET)-gcc
LD = $(TOOLCHAINS_DIR)/$(TARGET)-ld
GRUB_MKRESCUE = grub2-mkrescue
LIBGCC_PATH := $(shell $(CC) -print-file-name=libgcc.a)

# Input and output paths
SRC_DIR    = src
OBJ_DIR    = obj
HEADER_DIR = include/

# Input and output files
OBJECTS = \
	$(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.s.o,$(wildcard $(SRC_DIR)/*.s)) \
	$(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.c.o,$(wildcard $(SRC_DIR)/*.c))
	
KERNEL_BIN = $(OBJ_DIR)/astral.elf
KERNEL_ISO = $(OBJ_DIR)/astral.iso

# Compiler configuration
ASFLAGS = 
CFLAGS  = \
	-Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align \
	-Wwrite-strings \
	-Wredundant-decls -Wnested-externs -Winline -Wno-long-long \
	-Wconversion \
	-Werror \
	-I $(HEADER_DIR) \
	-O0 -ggdb \
	-std=c17 \
	-ffreestanding
LDFLAGS = \
	-static \
	-nostdlib \
	$(LIBGCC_PATH)

.PHONY: build
build: $(KERNEL_BIN)

.PHONY: clean
clean:
	$(RM) -Rf $(OBJ_DIR)

.PHONY: iso
iso: $(KERNEL_ISO)

.PHONY: run
run: iso
	@-echo "QEMU will start paused. Go to machine > pause to unpause it."
	qemu-system-$(QEMU_TARGET) -S -s -cdrom $(KERNEL_ISO)

$(KERNEL_ISO): $(KERNEL_BIN)
	mkdir -p $(KERNEL_ISO).dir/boot/grub
	cp -v grub.cfg $(KERNEL_ISO).dir/boot/grub/grub.cfg
	cp -v $(KERNEL_BIN) $(KERNEL_ISO).dir/boot/kernel.img
	$(GRUB_MKRESCUE) -o $@ $(KERNEL_ISO).dir/

$(KERNEL_BIN): $(OBJECTS)
	$(LD) -T linker.ld $(LDFLAGS) $^ -o $@

$(OBJ_DIR):
	mkdir -p $@

$(OBJ_DIR)/%.c.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@ 

$(OBJ_DIR)/%.s.o: $(SRC_DIR)/%.s | $(OBJ_DIR)
	$(AS) $(ASFLAGS) $< -o $@


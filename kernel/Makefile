QEMU_ARCH := x86_64
GNU_ARCH  := i686-elf

AS  := $(GNU_ARCH)-as
CC  := $(GNU_ARCH)-gcc
LD  := $(GNU_ARCH)-ld

GRUB_MKRESCUE := grub2-mkrescue

CFLAGS  := -Wall -Wextra -Werror -O2 -std=c17 -ffreestanding
LDFLAGS := -mno-red-zone -nostdlib -static -lgcc

OBJ_DIR := out

BINARY  := $(OBJ_DIR)/astral.bin
ISO     := $(OBJ_DIR)/astral.iso
OBJECTS := $(addprefix $(OBJ_DIR)/, \
	multiboot2.o \
	main.o \
)
LINKER_SCRIPT := multiboot.ld

.PHONY: build
build: $(BINARY) $(ISO)
	
.PHONY: run
run: build
	echo "QEMU will start paused. Go to machine > pause to unpause it."
	qemu-system-$(QEMU_ARCH) -S -s -cdrom $(ISO)

.PHONY: clean
clean:
	$(RM) -R $(OBJ_DIR)

$(BINARY): $(OBJ_DIR) $(OBJECTS)
	$(CC) -T $(LINKER_SCRIPT) -o $@ $(OBJECTS) $(LDFLAGS)

$(ISO): $(OBJ_DIR) $(BINARY)
	mkdir -p $(OBJ_DIR)/bootfs/boot/grub
	cp $(BINARY) $(OBJ_DIR)/bootfs/boot
	cp grub.cfg $(OBJ_DIR)/bootfs/boot/grub
	$(GRUB_MKRESCUE) \
		--product-name "Astral Kernel" \
		--product-version "v0.0.1" \
		-o $@ $(OBJ_DIR)/bootfs

$(OBJ_DIR):
	mkdir $(OBJ_DIR)

$(OBJ_DIR)/%.o: %.s
	$(AS) $< -o $@

$(OBJ_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

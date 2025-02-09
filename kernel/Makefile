QEMU_ARCH := i386
GNU_ARCH  := i686-elf
# QEMU_ARCH := x86_64
# GNU_ARCH  := x86_64-elf

AS  := $(GNU_ARCH)-as
CC  := $(GNU_ARCH)-gcc
LD  := $(GNU_ARCH)-ld

CFLAGS  := -Wall -Wextra -Werror -O2 -std=c17 -ffreestanding
LDFLAGS := -mno-red-zone -nostdlib -static -lgcc

OBJ_DIR := out

BINARY  := $(OBJ_DIR)/astral.bin
OBJECTS := $(addprefix $(OBJ_DIR)/, \
	multiboot1.o \
	main.o \
)
LINKER_SCRIPT := multiboot1.ld

.PHONY: build
build: $(BINARY)

.PHONY: run
run: build
	qemu-system-$(QEMU_ARCH) -kernel $(BINARY)

.PHONY: clean
clean:
	$(RM) -R $(OBJ_DIR)

$(BINARY): $(OBJ_DIR) $(OBJECTS)
	$(CC) -T $(LINKER_SCRIPT) -o $@ $(OBJECTS) $(LDFLAGS)

$(OBJ_DIR):
	mkdir $(OBJ_DIR)

$(OBJ_DIR)/%.o: %.s
	$(AS) $< -o $@

$(OBJ_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

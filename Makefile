TARGET ?= x86_32

ifeq ($(TARGET),x86_32)
GNU_TARGET  ?= i686-elf
QEMU_TARGET ?= i386
LD_TARGET   ?= elf_i386
else
$(error Unsupported target $(TARGET))
endif

# Tools
TOOLCHAINS_DIR      := cross-compiler/out/bin
CROSS_AS            := $(TOOLCHAINS_DIR)/$(GNU_TARGET)-as
CROSS_CC            := $(TOOLCHAINS_DIR)/$(GNU_TARGET)-gcc
CROSS_CXX           := $(TOOLCHAINS_DIR)/$(GNU_TARGET)-g++
CROSS_LD            := $(TOOLCHAINS_DIR)/$(GNU_TARGET)-ld
CROSS_GRUB_MKRESCUE := $(shell which grub2-mkrescue grub-mkrescue 2>/dev/null | head)
LIBGCC_PATH         := $(shell $(CROSS_CC) -print-file-name=libgcc.a)

# Input and output paths
SRC_DIR        := src
OBJ_DIR        := obj/$(TARGET)
HEADER_DIR     := include/

# Input and output files
OBJECTS := \
	$(patsubst $(SRC_DIR)/%.s,$(OBJ_DIR)/%.s.o,$(shell find $(SRC_DIR) -name "*.s" -print)) \
	$(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.c.o,$(shell find $(SRC_DIR) -name "*.c" -print)) \
	$(patsubst $(SRC_DIR)/%.cxx,$(OBJ_DIR)/%.cxx.o,$(shell find $(SRC_DIR) -name "*.cxx" -print))
	
KERNEL_BIN := $(OBJ_DIR)/astral.elf
KERNEL_ISO := $(OBJ_DIR)/astral.iso

# Compiler configuration
CROSS_ASFLAGS := 
CROSS_CFLAGS  := \
	-Wall -Wextra -pedantic -Wshadow=local -Wpointer-arith -Wcast-align \
	-Wwrite-strings -Wredundant-decls -Wnested-externs -Winline -Wno-long-long \
	-Wconversion -Werror \
	-I $(HEADER_DIR) \
	-O0 -ggdb \
	-std=c17 \
	-ffreestanding
CROSS_CXXFLAGS  := \
	-Wall -Wextra -pedantic -Wshadow=local -Wpointer-arith -Wcast-align \
	-Wwrite-strings -Winline -Wno-long-long -Wconversion -Werror \
	-I $(HEADER_DIR) \
	-O0 -ggdb \
	-std=c++20 \
	-ffreestanding \
	-fno-rtti \
	-fno-exceptions
CROSS_LDFLAGS := \
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

$(OBJ_DIR)/%.s.o: $(SRC_DIR)/%.s
	@mkdir -vp $(@D)
	$(CROSS_AS) $(CROSS_ASFLAGS) $< -o $@

$(OBJ_DIR)/%.c.o: $(SRC_DIR)/%.c
	@mkdir -vp $(@D)
	$(CROSS_CC) $(CROSS_CFLAGS) -c $< -o $@ 

$(OBJ_DIR)/%.cxx.o: $(SRC_DIR)/%.cxx
	@mkdir -vp $(@D)
	$(CROSS_CXX) $(CROSS_CXXFLAGS) -c $< -o $@ 

$(KERNEL_BIN): $(OBJECTS)
	@mkdir -vp $(@D)
	$(CROSS_LD) -T linker.ld $(CROSS_LDFLAGS) $^ -o $@

$(KERNEL_ISO): $(KERNEL_BIN)
	@mkdir -vp $(KERNEL_ISO).dir/boot/grub
	cp -v grub.cfg $(KERNEL_ISO).dir/boot/grub/grub.cfg
	cp -v $(KERNEL_BIN) $(KERNEL_ISO).dir/boot/kernel.img
	$(CROSS_GRUB_MKRESCUE) -o $@ $(KERNEL_ISO).dir/

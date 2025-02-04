#   This file is part of SimpleOS.
#
#    SimpleOS is free software: you can redistribute it and/or modify it under the terms of the 
#    GNU General Public License as published by the Free Software Foundation, either version 3 
#    of the License, or (at your option) any later version.
#
#    SimpleOS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY# 
#    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#    See the GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along with SimpleOS. 
#    If not, see <https://www.gnu.org/licenses/>.

BOOT_VER="0.1"

BUILD_DIR=build
SOURCE_DIR=src
CONFIG_DIR=config
UTIL_DIR=util
LDSCRIPTS_DIR=$(SOURCE_DIR)/ldscripts
KERNEL_INCLUDE_DIR=$(SOURCE_DIR)/kernel/include

FS_NAME="SIMPLE_OS"
DISK_IMAGE_SIZE=512M
DISK_IMAGE=disk.img
FLOPPY_IMAGE=floppy.img
FLOPPY_IMAGE_SIZE=1474560 # A standart 1.4MB floppy

ASM=nasm
LD=ld
QEMU=qemu-system-i386
DD=dd
MCOPY=mcopy
MMD=mmd
MKFS_FAT=mkfs.fat
FALLOCATE=fallocate

DEBUG_QEMU_ARGS= -hda $(BUILD_DIR)/$(DISK_IMAGE) -monitor stdio # -chardev stdio,id=char0,logfile=serial.log,signal=off -serial chardev:char0 #-boot menu=on #-s -S
RUN_QEMU_ARGS=-fda $(BUILD_DIR)/$(FLOPPY_IMAGE)

ASM_FLAGS=-f bin -i$(SOURCE_DIR)/bootloader/drivers -i$(SOURCE_DIR)/bootloader/lib -i$(SOURCE_DIR)/bootloader/loaders -i$(SOURCE_DIR)/bootloader/pmode -i$(SOURCE_DIR)/bootloader/mem -i$(SOURCE_DIR)/bootloader/
KERNEL_ASM_FLAGS=-f elf
KERNEL_CC_FLAGS=-march=i386 -ffreestanding -m32 -fpic -fno-pie -fno-pic -pipe -O2 -nostdlib -fno-stack-protector -I$(KERNEL_INCLUDE_DIR)

KERNEL_OBJS  = 	$(BUILD_DIR)/kernel_entry.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/vga.o $(BUILD_DIR)/io.o \
				$(BUILD_DIR)/libc.o $(BUILD_DIR)/serial.o $(BUILD_DIR)/idt.o $(BUILD_DIR)/interrupts.o \
				$(BUILD_DIR)/gdt.o $(BUILD_DIR)/gdt_flush.o $(BUILD_DIR)/memory.o $(BUILD_DIR)/panic.o

.PHONY: all image image_floppy image_FAT32 boot boot_stage2 kernel clean always bootupdate debug run

all: image image_floppy

image: boot_FAT16 boot_stage2 kernel
	@echo "[IMAGE]  Creating a FAT16 disk image"n
	@$(FALLOCATE) -l $(DISK_IMAGE_SIZE) $(BUILD_DIR)/$(DISK_IMAGE)
	@$(MKFS_FAT) -F 16 -n $(FS_NAME) $(BUILD_DIR)/$(DISK_IMAGE) > /dev/null
	@$(MMD) -i $(BUILD_DIR)/$(DISK_IMAGE) ::/boot
	@$(MMD) -i $(BUILD_DIR)/$(DISK_IMAGE) ::/boot/kernels
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(BUILD_DIR)/loader.bin ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(CONFIG_DIR)/boot.cfg ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(UTIL_DIR)/* ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(CONFIG_DIR)/banner.txt ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(BUILD_DIR)/kernel.bin ::/boot/kernels
	@$(DD) if=$(BUILD_DIR)/$(DISK_IMAGE) of=$(BUILD_DIR)/boot.bin skip=3 seek=3 count=56 iflag=skip_bytes,count_bytes status=none oflag=seek_bytes conv=notrunc
	@$(DD) if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/$(DISK_IMAGE) conv=notrunc status=none

image_fat32: boot_FAT32 boot_stage2 kernel
	@echo "[IMAGE]  Creating a FAT32 disk image"
	@$(FALLOCATE) -l $(DISK_IMAGE_SIZE) $(BUILD_DIR)/$(DISK_IMAGE)
	@$(MKFS_FAT) -F 32 -n $(FS_NAME) $(BUILD_DIR)/$(DISK_IMAGE) > /dev/null
	@$(MMD) -i $(BUILD_DIR)/$(DISK_IMAGE) ::/boot
	@$(MMD) -i $(BUILD_DIR)/$(DISK_IMAGE) ::/boot/kernels
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(BUILD_DIR)/loader.bin ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(CONFIG_DIR)/boot.cfg ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(UTIL_DIR)/* ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(CONFIG_DIR)/banner.txt ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(DISK_IMAGE) $(BUILD_DIR)/kernel.bin ::/boot/kernels
	@$(DD) if=$(BUILD_DIR)/$(DISK_IMAGE) of=$(BUILD_DIR)/boot.bin skip=3 seek=3 count=56 iflag=skip_bytes,count_bytes status=none oflag=seek_bytes conv=notrunc
	@$(DD) if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/$(DISK_IMAGE) conv=notrunc status=none

image_floppy: boot_FAT12 boot_stage2 kernel
	@echo "[IMAGE]  Creating a floppy image"
	@$(FALLOCATE) -l $(FLOPPY_IMAGE_SIZE) $(BUILD_DIR)/$(FLOPPY_IMAGE)
	@$(MKFS_FAT) -F 12 -n $(FS_NAME) $(BUILD_DIR)/$(FLOPPY_IMAGE) > /dev/null
	@$(MMD) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) ::/boot
	@$(MMD) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) ::/boot/kernels
	@$(MCOPY) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) $(BUILD_DIR)/loader.bin ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) $(CONFIG_DIR)/boot.cfg ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) $(UTIL_DIR)/* ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) $(CONFIG_DIR)/banner.txt ::/boot
	@$(MCOPY) -i $(BUILD_DIR)/$(FLOPPY_IMAGE) $(BUILD_DIR)/kernel.bin ::/boot/kernels
	@$(DD) if=$(BUILD_DIR)/$(FLOPPY_IMAGE) of=$(BUILD_DIR)/boot.bin skip=3 seek=3 count=56 iflag=skip_bytes,count_bytes status=none oflag=seek_bytes conv=notrunc
	@$(DD) if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/$(FLOPPY_IMAGE) conv=notrunc status=none

bootupdate:
	@echo "[IMAGE]  Updating MBR"
	@$(DD) if=$(BUILD_DIR)/$(DISK_IMAGE) of=$(BUILD_DIR)/boot.bin skip=3 seek=3 count=56 iflag=skip_bytes,count_bytes status=none oflag=seek_bytes conv=notrunc
	@$(DD) if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/$(DISK_IMAGE) conv=notrunc status=none

boot_FAT12: always
	@echo "[BOOTLOADER]  Compiling Stage 1 FAT12"
	@$(ASM) $(ASM_FLAGS) $(SOURCE_DIR)/bootloader/boot.asm -o $(BUILD_DIR)/boot.bin -D FAT12

boot_FAT16: always
	@echo "[BOOTLOADER]  Compiling Stage 1 FAT16"
	@$(ASM) $(ASM_FLAGS) $(SOURCE_DIR)/bootloader/boot.asm -o $(BUILD_DIR)/boot.bin -D FAT16

boot_FAT32: always
	@echo "[BOOTLOADER]  Compiling Stage 1 FAT32"
	@$(ASM) $(ASM_FLAGS) $(SOURCE_DIR)/bootloader/boot.asm -o $(BUILD_DIR)/boot.bin -D FAT32

boot_stage2: always
	@echo "[BOOTLOADER]  Compiling Stage 2"
	@$(ASM) $(ASM_FLAGS) $(SOURCE_DIR)/bootloader/loader.asm  -o $(BUILD_DIR)/loader.bin

kernel: always $(KERNEL_OBJS)
	@echo "[KERNEL]  Linking kernel"
	@$(LD) -T $(LDSCRIPTS_DIR)/kernel.ld -o $(BUILD_DIR)/kernel.bin $(KERNEL_OBJS)

# Generic rules for building all .C and .ASM files
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/kernel/*/%.c
	@echo "[KERNEL]  Compiling $<"
	@$(CC) -o $@ -c $< $(KERNEL_CC_FLAGS) -I$(KERNEL_INCLUDE_DIR)

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/kernel/kernel/*/%.c
	@echo "[KERNEL]  Compiling $<"
	@$(CC) -o $@ -c $< $(KERNEL_CC_FLAGS) -I$(KERNEL_INCLUDE_DIR)

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/kernel/*/%.asm
	@echo "[KERNEL]  Compiling $<"
	@$(ASM) $< -o $@ $(KERNEL_ASM_FLAGS)

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/kernel/kernel/*/%.asm
	@echo "[KERNEL]  Compiling $<"
	@$(ASM) $< -o $@ $(KERNEL_ASM_FLAGS)

always:
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)/*

run:
	$(QEMU) $(RUN_QEMU_ARGS)

debug: image
	$(QEMU) $(DEBUG_QEMU_ARGS)

#
#
#      _____            __    ____  ____
#     / __(_)_ _  ___  / /__ / __ \/ __/
#    _\ \/ /  ' \/ _ \/ / -_) /_/ /\ \  
#   /___/_/_/_/_/ .__/_/\__/\____/___/  
#              /_/                      
#
#
#

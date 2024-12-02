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
KERNEL_INCLUDE_DIR=$(SOURCE_DIR)/kernel/screen

DISK_IMAGE_SIZE=512M
DISK_IMAGE=disk.img

ASM=nasm
LD=ld
QEMU=qemu-system-i386

DEBUG_QEMU_ARGS=--monitor stdio -hda $(BUILD_DIR)/$(DISK_IMAGE) #-boot menu=on #-s -S
RUN_QEMU_ARGS=-hda $(BUILD_DIR)/$(DISK_IMAGE)

ASM_FLAGS=-f bin
KERNEL_ASM_FLAGS=-f elf
KERNEL_CC_FLAGS=-march=i386 -ffreestanding -m32 -fpic -fno-pie -fno-pic -I$(KERNEL_INCLUDE_DIR)

.PHONY: all image boot kernel_32 clean always debug bootupdate

all: image

image: boot boot_stage2 kernel_32
	fallocate -l $(DISK_IMAGE_SIZE) $(BUILD_DIR)/disk.img
	mkfs.fat -F 16 -n "" $(BUILD_DIR)/disk.img
	mmd -i $(BUILD_DIR)/disk.img ::/boot
	mmd -i $(BUILD_DIR)/disk.img ::/boot/kernels
	mcopy -i $(BUILD_DIR)/disk.img $(BUILD_DIR)/loader.bin ::/boot
	mcopy -i $(BUILD_DIR)/disk.img $(CONFIG_DIR)/boot.cfg ::/boot
	mcopy -i $(BUILD_DIR)/disk.img $(UTIL_DIR)/memtest.bin ::/boot
	mcopy -i $(BUILD_DIR)/disk.img $(CONFIG_DIR)/banner.txt ::/boot
	mcopy -i $(BUILD_DIR)/disk.img $(BUILD_DIR)/kernel.bin ::/boot/kernels
	mcopy -i $(BUILD_DIR)/disk.img /home/dann/Desktop/oldkr.bin ::/boot/kernels
	dd if=$(BUILD_DIR)/disk.img of=$(BUILD_DIR)/boot.bin skip=3 seek=3 count=56 iflag=skip_bytes,count_bytes status=progress oflag=seek_bytes conv=notrunc
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/disk.img conv=notrunc status=progress

#image_fat12: boot_fat12 boot_stage2
#	fallocate -l 1474560 $(BUILD_DIR)/disk.img
#	mkfs.fat -F 12 -n "" $(BUILD_DIR)/disk.img
#	mmd -i $(BUILD_DIR)/disk.img ::/boot
#	mmd -i $(BUILD_DIR)/disk.img ::/boot/kernels
#	mcopy -i $(BUILD_DIR)/disk.img $(BUILD_DIR)/loader.bin ::/boot
#	mcopy -i $(BUILD_DIR)/disk.img $(CONFIG_DIR)/boot.cfg ::/boot
#	mcopy -i $(BUILD_DIR)/disk.img $(UTIL_DIR)/memtest.bin ::/boot
#	mcopy -i $(BUILD_DIR)/disk.img $(BUILD_DIR)/hello.bin ::/boot/kernels
#	mcopy -i $(BUILD_DIR)/disk.img /home/dann/Desktop/oldkr.bin ::/boot/kernels
#	dd if=$(BUILD_DIR)/disk.img of=$(BUILD_DIR)/boot.bin skip=3 seek=3 count=56 iflag=skip_bytes,count_bytes status=progress oflag=seek_bytes conv=notrunc
#	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/disk.img conv=notrunc status=progress

image_fat16: image

bootupdate:
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/disk.img conv=notrunc status=progress

boot: always
	$(ASM) -i $(SOURCE_DIR)/bootloader $(SOURCE_DIR)/bootloader/boot.asm -o $(BUILD_DIR)/boot.bin

boot_stage2: always
	$(ASM) $(ASM_FLAGS) -i $(SOURCE_DIR)/bootloader $(SOURCE_DIR)/bootloader/loader.asm  -o $(BUILD_DIR)/loader.bin

boot_fat16: boot

kernel_32: always
	$(ASM) $(KERNEL_ASM_FLAGS) -i $(SOURCE_DIR)/kernel $(SOURCE_DIR)/kernel/kernel_entry.asm -o $(BUILD_DIR)/kernel_enrty.o
	$(CC) $(KERNEL_CC_FLAGS) -c $(SOURCE_DIR)/kernel/kernel_main.c -o $(BUILD_DIR)/kernel.o
	$(LD) -T $(LDSCRIPTS_DIR)/kernel.ld -o $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/kernel_enrty.o $(BUILD_DIR)/kernel.o

#boot_fat12: always
#	$(ASM) -i $(SOURCE_DIR) $(SOURCE_DIR)/boot.asm -f bin -o $(BUILD_DIR)/boot.bin -D FAT12

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*

run:
	$(QEMU) $(RUN_QEMU_ARGS)

debug: clean image
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
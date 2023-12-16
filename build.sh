#!/bin/bash
rm -rf build
mkdir build

nasm bootloader/mbr.asm -o build/mbr.bin
nasm bootloader/stage1.asm -o build/stage1.bin
nasm bootloader/stage2.asm -o build/stage2.bin
nasm src/runtime_defs.asm -felf64 -o build/runtime_defs.o
gfortran src/kernel.f90 -O3 -c -o build/kernel.a -static -mgeneral-regs-only
ld -Tlinker.ld -Lgfortran -melf_x86_64 -nostdlib --nmagic -o build/kernel.elf build/runtime_defs.o build/kernel.a

cd build
objcopy -O binary kernel.elf kernel.bin
 
cat mbr.bin > boot.bin
cat stage1.bin >> boot.bin
cat stage2.bin >> boot.bin
cat kernel.bin >> boot.bin
qemu-system-x86_64 boot.bin
cd ../
# A Small Bootable Program Written in Fortran 2003

This project uses `gfortran`, `ld`, and `objcopy` to compile Fortran code to a freestanding binary which is then loaded by a simple bootloader written in assembly. It was made as a proof of concept to show that it's possible to write kernels in Fortran. All it does is draw to the screen and halt.

It can boot on any x86-64 PC with support for booting from BIOS. You can run it in QEMU using the `build.sh` file (provided you're on Linux and have QEMU and `nasm` installed), and burn the resulting `boot.bin` in the build directory to a USB if you want to boot it on a real computer.

## Image of this running on a real computer

![20230831_082317](https://github.com/ljgermain/fortranos/assets/154016542/f9676b34-c78d-4c5e-9a73-8b1079785623)

#!/bin/sh

# This script starts the QEMU PC emulator, booting from the
# TEXT-OS floppy disk image

sudo qemu-system-i386 -drive format=raw,file=disk_images/TEXT-OS.flp,index=0,if=floppy

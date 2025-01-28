#!/bin/bash

# MikeOS Build Script
# This script assembles the MikeOS bootloader, kernel, and programs using NASM,
# then creates both floppy and CD images on Linux systems.

# Configuration
FLOPPY_IMAGE="disk_images/TEXT-OS.flp"
ISO_IMAGE="disk_images/TEXT-OS.iso"
MOUNT_DIR="tmp-loop"
FLOPPY_SIZE=1440

# Check for root privileges (required for loopback mounting)
check_root() {
    if [ "$(whoami)" != "root" ]; then
        echo "Error: Root privileges required for loopback mounting"
        echo "Please use 'su' or 'sudo bash' to switch to root"
        exit 1
    fi
}

# Create a new floppy image if it doesn't exist
create_floppy_image() {
    if [ ! -e "$FLOPPY_IMAGE" ]; then
        echo ">>> Creating new TEXT-OS floppy image..."
        mkdosfs -C "$FLOPPY_IMAGE" "$FLOPPY_SIZE" || exit 1
    fi
}

# Assemble the bootloader
build_bootloader() {
    echo ">>> Assembling bootloader..."
    nasm -O0 -w+orphan-labels -f bin \
        -o source/bootload/bootload.bin \
        source/bootload/bootload.asm || exit 1
}

# Assemble the kernel
build_kernel() {
    echo ">>> Assembling TEXT-OS kernel..."
    (cd source && nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm) || exit 1
}

# Assemble all program files
build_programs() {
    echo ">>> Assembling programs..."
    cd programs || exit 1
    for prog in *.asm; do
        nasm -O0 -w+orphan-labels -f bin "$prog" -o "${prog%.asm}.bin" || exit 1
    done
    cd ..
}

# Add bootloader to the floppy image
add_bootloader() {
    echo ">>> Adding bootloader to floppy image..."
    dd status=noxfer conv=notrunc \
        if=source/bootload/bootload.bin \
        of="$FLOPPY_IMAGE" || exit 1
}

# Copy kernel and programs to the mounted floppy image
copy_files() {
    echo ">>> Copying TEXT-OS kernel and programs..."
    rm -rf "$MOUNT_DIR"
    mkdir "$MOUNT_DIR"
    mount -o loop -t vfat "$FLOPPY_IMAGE" "$MOUNT_DIR" || exit 1
    
    # Copy kernel
    cp source/kernel.bin "$MOUNT_DIR/"
    
    # Copy programs and associated files
    cp programs/*.bin programs/template.txt "$MOUNT_DIR/"
    
    # Allow writes to complete
    sleep 0.2
}

# Unmount the floppy image
cleanup_mount() {
    echo ">>> Unmounting loopback floppy..."
    umount "$MOUNT_DIR" || exit 1
    rm -rf "$MOUNT_DIR"
}

# Create the final ISO image
create_iso() {
    echo ">>> Creating CD-ROM ISO image..."
    rm -f "$ISO_IMAGE"
    mkisofs -quiet -V 'TEXT-OS' -input-charset iso8859-1 \
        -o "$ISO_IMAGE" -b TEXT-OS.flp disk_images/ || exit 1
}

# Main build process
main() {
    check_root
    create_floppy_image
    build_bootloader
    build_kernel
    build_programs
    add_bootloader
    copy_files
    cleanup_mount
    create_iso
    echo '>>> Done!'
}

# Execute the build
main
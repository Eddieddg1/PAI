#!/bin/bash

set -e

clear

timedatectl || exit 1
echo "Available disks:"
fdisk -l | grep "Disk /dev/" || exit 1
read -p "Enter the disk to partition (e.g., sda, nvme0n1): " DISK || exit 1

if [[ $DISK == nvme* ]]; then
    PART_SUFFIX="n1"
else
    PART_SUFFIX=""
fi

export DISK PART_SUFFIX || exit 1

(
echo g
echo n
echo
echo
echo +1G
echo y
echo t
echo EFI System
echo n
echo
echo
echo +4G
echo n
echo
echo
echo
echo w
) | fdisk /dev/$DISK || exit 1

mkfs.fat -F 32 /dev/${DISK}${PART_SUFFIX}1 || exit 1
mkswap /dev/${DISK}${PART_SUFFIX}2 || exit 1
mkfs.ext4 /dev/${DISK}${PART_SUFFIX}3 || exit 1

mkdir -p /mnt/boot || exit 1
mount /dev/${DISK}${PART_SUFFIX}1 /mnt/boot || exit 1
swapon /dev/${DISK}${PART_SUFFIX}2 || exit 1
mount /dev/${DISK}${PART_SUFFIX}3 /mnt || exit 1

read -p "Packages?: " PAC || exit 1

pacstrap -K /mnt base base-devel linux linux-firmware fastfetch htop nano plasma sddm networkmanager xorg-server xorg-apps xorg-xinit nvidia-dkms $PAC || exit 1

graphics_card=$(lspci -v | grep -A1 -e VGA -e 3D | grep "VGA compatible controller")

if [ -z "$graphics_card" ]; then
    echo "No VGA compatible controller found."
    exit 1
fi

graphics_model=$(echo "$graphics_card" | sed -n 's/^.*: \(.*\)$/\1/p')

driver_packages=$(pacman -Ss xf86-video | grep "/xf86-video-" | awk '{print $1}')

if [ -z "$driver_packages" ]; then
    echo "No xf86-video driver packages found."
    exit 1
fi

pacstrap -K /mnt $(echo "$driver_packages" | head -n 1) || exit 1

genfstab -U /mnt >> /mnt/etc/fstab || exit 1

mkdir /mnt/git-setup/ || exit 1
cp bootloader-select.sh /mnt/git-setup/ || exit 1
chmod +x /mnt/git-setup/bootloader-select.sh || exit 1
cp locale-user.sh /mnt || exit 1
chmod +x /mnt/locale-user.sh || exit 1
arch-chroot /mnt /bin/bash -c "./locale-user.sh" || exit 1

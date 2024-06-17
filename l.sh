#!/bin/bash

set -e

timedatectl
echo "Available disks:"
fdisk -l | grep "Disk /dev/"
read -p "Enter the disk to partition (e.g., sda, nvme0n1): " DISK

if [[ $DISK == nvme* ]]; then
    PART_SUFFIX="n1p"
else
    PART_SUFFIX=""
fi

export DISK PART_SUFFIX

(
echo g
echo n
echo
echo
echo +1G
echo n
echo
echo
echo +4G
echo n
echo
echo
echo
echo w
) | fdisk /dev/$DISK

mkfs.fat -F 32 /dev/${DISK}${PART_SUFFIX}1
mkswap /dev/${DISK}${PART_SUFFIX}2
mkfs.ext4 /dev/${DISK}${PART_SUFFIX}3

mkdir -p /mnt/boot
mount /dev/${DISK}${PART_SUFFIX}1 /mnt/boot
swapon /dev/${DISK}${PART_SUFFIX}2
mount /dev/${DISK}${PART_SUFFIX}3 /mnt

pacstrap -K /mnt base base-devel linux linux-firmware fastfetch htop nano thunderbird konsole vlc kate git sddm networkmanager awesome

genfstab -U /mnt >> /mnt/etc/fstab

mkdir /mnt/git-setup/
cp /bootloader-select.sh /mnt/git-setup/
chmod +x /mnt/git-setup/bootloader-select.sh
cp /locale-user.sh /mnt
chmod +x /mnt/locale-user.sh
arch-chroot /mnt /bin/bash -c "./locale-user.sh"

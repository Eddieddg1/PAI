#!/bin/bash

set -e

clear

ping -c 1 google.com >/dev/null 2>&1
if [ $? -ne 0 ]; then
iwctl
echo device list
read -p "Which of the devices do you want to use?: " NETWORKDEVICE
echo device $NETWORKDEVICE set-property Powered on
echo station $NETWORKDEVICE scan
echo station $NETWORKDEVICE get-networks
read -p "Which of the networks do you want to connect to?: " NETWORK
echo station $NETWORKDEVICE connect $NETWORK
echo exit
fi

pacman -Syy

read -p "Do you want to enable ParallelDownloads? y/n: " PARALLEL

if [[ $PARALLEL == y || $PARALLEL == ]]; then
    read -p "How many ParallelDownloads do you want? (standard is 5): " PARANUM
    if [[ $PARANUM == ]]; then
        sed -i '/#ParallelDownloads/s/^#//' /etc/pacman.conf
        sed -i '/ParallelDownloads/s/=.*/= 5/' /etc/pacman.conf
    else
        sed -i '/#ParallelDownloads/s/^#//' /etc/pacman.conf
        sed -i "/ParallelDownloads/s/=.*/= $PARANUM/" /etc/pacman.conf
    fi
fi

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

echo "base base-devel linux linux-firmware fastfetch htop nano plasma sddm networkmanager iwd xorg-server xorg-apps xorg-xinit"
read -p "Do you want to add packages? (drivers get added after this): " PAC || exit 1

pacstrap -K /mnt base base-devel linux linux-firmware fastfetch htop nano plasma sddm networkmanager iwd xorg-server xorg-apps xorg-xinit $PAC || exit 1

read -p "Do you want to use open source drivers? y/n: " OPENSOURCE

if [[ $OPENSOURCE == y || $OPENSOURCE == ]]; then
    echo "Available open source driver packages:"
    pacman -Ss xf86-video | grep "/xf86-video-" | awk '{print NR".", $1}'

    driver_count=$(pacman -Ss xf86-video | grep "/xf86-video-" | wc -l)

    if [ $driver_count -eq 0 ]; then
        echo "No open source driver packages found."
        exit 1
    fi

    read -p "Choose the driver package you want to install (enter number): " DRIVER_CHOICE

    if ! [[ "$DRIVER_CHOICE" =~ ^[1-$driver_count]$ ]]; then
        echo "Invalid selection. Please enter a number between 1 and $driver_count."
        exit 1
    fi

    selected_driver=$(pacman -Ss xf86-video | grep "/xf86-video-" | awk 'NR=='$DRIVER_CHOICE'{print $1}')

    pacstrap -K /mnt $selected_driver || exit 1
else
    read -p "You need to specify what drivers you want: " DRIVERS
    pacstrap -K /mnt $DRIVERS || exit 1
fi


genfstab -U /mnt >> /mnt/etc/fstab || exit 1

mkdir /mnt/git-setup/ || exit 1
cp bootloader-select.sh /mnt/git-setup/ || exit 1
chmod +x /mnt/git-setup/bootloader-select.sh || exit 1
cp locale-user.sh /mnt || exit 1
chmod +x /mnt/locale-user.sh || exit 1
arch-chroot /mnt /bin/bash -c "./locale-user.sh" || exit 1

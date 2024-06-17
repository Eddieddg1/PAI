#!/bin/bash

set -e

ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc

locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=sv-latin1" > /etc/vconsole.conf

mkinitcpio -P

echo "Enter root password"
passwd

useradd -m -g users -G wheel,video,kvm,audio -s /bin/bash eddie
echo "Set password: "
passwd eddie
echo "eddie ALL=(ALL) ALL" >> /etc/sudoers

echo "VenerableCreator" >> /etc/hostname

cd /git-setup/
./bootloader-select.sh

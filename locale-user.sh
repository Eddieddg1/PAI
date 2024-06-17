#!/bin/bash

set -e

ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc || exit 1

locale-gen || exit 1
echo "LANG=en_US.UTF-8" > /etc/locale.conf || exit 1
echo "KEYMAP=sv-latin1" > /etc/vconsole.conf || exit 1

mkinitcpio -P || exit 1

echo "Enter root password"
passwd || exit 1

useradd -m -g users -G wheel,video,kvm,audio -s /bin/bash eddie || exit 1
echo "Set password: "
passwd eddie || exit 1
echo "eddie ALL=(ALL) ALL" >> /etc/sudoers || exit 1

echo "VenerableCreator" >> /etc/hostname || exit 1

cd /git-setup/ || exit 1
./bootloader-select.sh || exit 1

#!/bin/bash

set -e
read -p "What timezone? (example Europe/Stockholm): " localtime
if [[ $localtime == ]]; then
  ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime|| exit 1
else
  ln -sf /usr/share/zoneinfo/$localtime /etc/localtime|| exit 1
fi
hwclock --systohc || exit 1

locale-gen || exit 1
read -p "What language? (example en_US.UTF-8): " language
if [[ $language == ]]; then
  echo "LANG=en_US.UTF-8" > /etc/locale.conf || exit 1
else
  echo "LANG=$language" > /etc/locale.conf || exit 1
fi

read -p "What keymap? (example sv-latin1)" keymap
if [[ $keymap == ]]; then
  echo "KEYMAP=sv-latin1" > /etc/vconsole.conf || exit 1
else
  echo "KEYMAP=$keymap" > /etc/vconsole.conf || exit 1
fi

mkinitcpio -P || exit 1

echo "Enter root password"
passwd || exit 1

read -p "Enter username: " usrname

useradd -m -g users -G wheel,video,kvm,audio -s /bin/bash $usrname || exit 1
passwd $usrname || exit 1
echo "$usrname ALL=(ALL) ALL" >> /etc/sudoers || exit 1

read -p "Enter hostname: " hostname

echo "$hostname" >> /etc/hostname || exit 1

./bootloader-select.sh || exit 1

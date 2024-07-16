#!/bin/bash

set -e

echo "Boot loaders: (O)EFISTUB, (X)Unified kernel image, (O)GRUB, (X)Limine, (X)rEFInd, (X)Syslinux, (~)systemd-boot"
echo "(X) = Not currently supported, (O) = Supported, (~) Work In Progress"
read -p "Please make sure to spell it correctly: " boot
case "$boot" in
    "EFISTUB")
        pacman -S --noconfirm efibootmgr
        mkdir -p /boot/efi
        mount /dev/${DISK}${PART_SUFFIX}1 /boot/efi
        efibootmgr --create --disk /dev/${DISK} --part 1 --label "Arch Linux" --loader /vmlinuz-linux --unicode 'root=/dev/${DISK}${PART_SUFFIX}3 rw initrd=\initramfs-linux.img'
        if efibootmgr | grep -q "Arch Linux"; then
            echo "EFISTUB boot entry created successfully."
        else
            echo "Failed to create EFISTUB boot entry." >&2
            exit 1
        fi
        ;;
#    "Unified kernel image")
#        umount /dev/${DISK}${PART_SUFFIX}1
#        mount --mkdir /dev/${DISK}${PART_SUFFIX}1 /boot/efi
#        ;;
    "GRUB")
        pacman -S --noconfirm grub efibootmgr
        mkdir -p /boot/efi
        mount /dev/${DISK}${PART_SUFFIX}1 /boot/efi
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
        grub-mkconfig -o /boot/grub/grub.cfg
        if grub-mkconfig -o /boot/grub/grub.cfg; then
            echo "GRUB configuration file created successfully."
        else
            echo "Failed to create GRUB configuration file." >&2
            exit 1
        fi
        ;;
#    "Limine")
#        sudo pacman -S limine
#        ;;
#    "rEFInd")
#        sudo pacman -S refind
#        ;;
#    "Syslinux")
#        sudo pacman -S syslinux
#        syslinux-install_update -i -a -m
#        ;;
    "systemd-boot")
        mkdir -p /boot
        mount /dev/${DISK}${PART_SUFFIX}1 /boot
        bootctl install
        mkdir -p /boot/loader/entries
        echo "default  arch" > /boot/loader/loader.conf
        cat << EOF > /boot/loader/entries/arch.conf
        title   Arch Linux
        linux   /vmlinuz-linux
        initrd  /initramfs-linux.img
        options root=/dev/${DISK}${PART_SUFFIX}3 rw
EOF
        if bootctl status | grep -q "systemd-boot"; then
            echo "systemd-boot installed successfully."
        else
            echo "Failed to install systemd-boot." >&2
            exit 1
        fi
        ;;
    *)
        echo "Boot loader '$boot' not recognized or not supported."
        exit 1
        ;;
esac

echo "if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec startx /usr/bin/startplasma-x11
fi" >> ~/.bash_profile

systemctl start sddm.service
systemctl enable NetworkManager

exit

reboot

#!/bin/bash

#enhancements:
#   - add connection test (ping)
#   - add sfdiks


echo -e "ArchLinux Installer\nWarning: Before to install arch, set a internet connection and set the next partitions"
echo -e "\t1.- Boot Partition (/boot)\n\t2.- Root Partition (/)\n\t3.- Swap Partition\n"

echo "Please, select one way to install arch"
echo -e "1) Arch dual boot, separate boot partition (boot,swap and root partition)"
echo -e "2) Arch dual boot, same Windows boot partition"
echo -e "9) Exit\n"

read op

if [ $op -eq 1 ];then
    #add checking
    echo "Select boot partition"
    read part_boot
    echo "Select root partition"
    read part_root
    echo "Select swap partition"
    read part_swap
    echo "Enter your profile name"
    read nick_name

    #time config
    timedatectl set-ntp true

    #swap config
    mkswap /dev/$part_swap
    swapon /dev/$part_swap

    #format partitions
    mkfs.ext4 /dev/$part_root
    mkfs.fat -F 32 /dev/$part_boot
    echo -e "[+] Partitions formated"

    #mounting partitions
    mount /dev/$part_root /mnt
    mkdir /mnt/boot
    mount /dev/$part_boot /mnt/boot

    echo -e "[+] Partitions mounted"

    #update mirror list
    pacman -Sy

    #INSTALLING BASE ARCH
    pacstrap /mnt base linux linux-firmware

    #Creating fstab file
    genfstab -U /mnt >> /mnt/etc/fstab


    #when change root the script needs to run it in another script
cat > /mnt/installer_2.sh << EOF
#!/bin/bash

    #Change zone info
    ln -sf /usr/share/zoneinfo/Mexico/General /etc/localtime

    #Hardware clock config
    hwclock --systohc

    #generate locale
    sed -i '/^#en_US\.UTF-8/s/^#//g' /etc/locale.gen
    locale-gen
    #persistent configuration 
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    echo "KEYMAP=us" >> /etc/vconsole.conf


    #Host configuration
    echo "${nick_name}pc" >> /etc/hostname
    echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t${nick_name}pc"

    #Password root
    echo "Enter root's password"
    passwd root

    #Creating user
    useradd -m -G wheel,audio,video,optical,storage $nick_name -s /bin/bash
    echo "Enter ${nick_name}'s password"
    passwd $nick_name

    pacman -S sudo neovim git vim --noconfirm

    #uncomment wheel visudo
    sed -i '/^#\ %wheel\ ALL=(ALL:ALL)\ ALL/s/^# //g' /etc/sudoers


    #GRUB INSTALL
    #   -Add check
    pacman -S grub efibootmgr dosfstools os-prober mtools --noconfirm

    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot --recheck

    #Detect other os
    #uncomment grub os-prober disable
    sed -i '/^#GRUB_DISABLE_OS_PROBER=false/s/^#//g' /etc/default/grub
    os-prober
    grub-mkconfig --output=/boot/grub/grub.cfg


    #Network manager config 
    pacman -Syy && pacman -S archlinux-keyring --noconfirm

    pacman -S networkmanager --noconfirm
    systemctl enable NetworkManager
    
    #Others packages
    #change the next line if the cpu is Intel (intel-ucode)
    pacman -S openssh base-devel dialog lvm2 wpa_supplicant wireless_tools netctl amd-ucode man --noconfirm


    #/etc/fstab backup
    cp /etc/fstab /etc/fstab.bak

EOF

    #Changing arch root
    chmod +x /mnt/installer_2.sh
    arch-chroot /mnt /installer_2.sh

elif [ $op -eq 2 ];then
    echo "ERROR: this option is not available yet"

elif [ $op -eq 9 ];then
    echo "Exiting..."
else
    echo "Warning: select a valid option"

fi



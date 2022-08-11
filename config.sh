#!/bin/bash

#config the variables to use 3th option (Fast Install)

export extra_packs="openssh base-devel dialog lvm2 wpa_supplicant wireless_tools netctl man pavucontrol pulseaudio firefox ranger gnome-keyring htop" #add any package

# The next variables are only if you have selected the fast install
export create_partition "$op_disk"
export nick_name="user_1" #username
export pass_user="user_1" #user's password
export pass_root="root" #root's password
export op_bios_selected=1 # 1 = UEFI | 2 = BIOS
export op_gui="yes" #yes = gui | no = no gui
export gui_str="Xfce" #none = no gui | Options = Gnome, Plasma, Xfce, Mate
export op_win="no" #yes = dual boot | no = no dual boot
export op_vm="yes" #yes = vm | no = pc or laptop
export #The next variables are important for add_extra_packs function
export cpu_str="AMD" # Intel | AMD
export gpu_str="none" # Nvidia | Radeon

./install_arch.sh
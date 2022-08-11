#!/bin/bash

extra_packs="openssh base-devel dialog lvm2 wpa_supplicant wireless_tools netctl man pavucontrol pulseaudio firefox ranger gnome-keyring htop" #add any package

function installer(){

    clear

    echo "Wait a moment..."

    echo "Updating repositories..."
    pacman -Sy > /dev/null
    pacman -S archlinux-keyring --noconfirm > /dev/null
    pacman -S python-pip --noconfirm > /dev/null
    pip install terminaltables > /dev/null

    echo "Verifying internet conection..."
    ping -c 3 8.8.8.8 > /dev/null

    if [[ "$?" -ne 0 ]];then
        echo "There's no internet connection"
        exit 1
    else
        clear
    fi

    #-----------------------1) Arch dual boot ----------------------------
    if [[ "$1" -eq 1 ]] || [[ "$1" -eq 2 ]];then

        ###################---PARTITIONS---##########################
        assign_partitions $1

        ###################---PROFILE---##########################
        read -p "Enter your profile name: " nick_name
        echo -e "\n"    

        create_password $nick_name
        declare -n pass_user="pass_$nick_name" #is necessary create this variable to identify the user name and not depend on $1 of the function create_password
        echo -e "\n"    

        create_password "root"

        ###################---BIOS or UEFI---##########################
        echo "Bios or UEFI?: "

        loop_bios=0

	while [[ "$loop_bios" -ne 1 ]];do
	    echo -e "\n\n\t1) UEFI\n\t2) BIOS\n\n"
	    read -p "Which of these?: " op_bios_selected

	    options=(1 2)
	    if [[ " ${options[*]} " =~ " ${op_bios_selected} " ]];then #compare if the number exists in the array
		    if [[ "$op_bios_selected" -eq 2 ]];then
			verify_disk #creates op_disk variable, it's necessary to install grub on bios 
		    fi

		    loop_bios=1 #breaks loop
	    else
		    echo -e "\nPlease, select a valid option\n"
	    fi

	done


        ###################---GUI---##########################
        echo -e "\n"    
        read -p "Do you want to use graphic interface?[yes/no]: " op_gui

        loop_gui=0

        if [ $op_gui == "yes" ] || [ $op_gui == "YES" ];then
            while [[ "$loop_gui" -ne 1 ]];do
                echo -e "\n\n\t1) Gnome\n\t2) Plasma\n\t3) Xfce\n\t4) Mate\n\t9) Cancel\n"
                read -p "Which of these?: " op_gui_selected

                options=(1 2 3 4 9)
                op_gui_array=("Gnome" "Plasma" "Xfce" "Mate" "None")
                if [[ " ${options[*]} " =~ " ${op_gui_selected} " ]];then #compare if the number exists in the array
                        gui_str=${op_gui_array[$(($op_gui_selected-1))]}
                        loop_gui=1 #breaks loop
                else
                        echo -e "\nPlease, select a valid option\n"
                        
                fi

            done
	else
	    gui_str="None"
        fi


        ###################---OTHER OS---##########################
        #windows question
        loop_win=0
        while [[ "$loop_win" -ne 1 ]];do
            echo -e "\n"
            read -p "Do you have any Windows or Linux installation?[yes/no]: " op_win
            echo -e "\n"
            options_win=( "YES" "yes" "NO" "no" )
            if [[ "${options_win[*]}" =~ "${op_win}" ]];then #compare if the word exists in the array
                loop_win=1
            else
                echo -e "\nPlease, enter a valid option\n"
            fi
        done

        ###################---VM OR PC DRIVERS---##########################
        loop_vm=0
        while [[ "$loop_vm" -ne 1 ]];do
            read -p "Will it be installed in a virtual machine/docker?[yes/no]: " op_vm
            echo -e "\n"
            options_vm_1=( "YES" "yes" )
            options_vm_2=( "NO" "no" )
            if [[ "${options_vm_1[*]}" =~ "${op_vm}" ]];then #if it's a VM
                
                #ADD PACKAGES!!!!!!!!!!!!!
                
                gpu_str="None"
                loop_vm=1 #breaks loop
            elif [[ "${options_vm_2[*]}" =~ "${op_vm}" ]];then #if it's a PC or laptop

                ###################---GPU DRIVERS---##########################
                loop_gpu=0
        
                while [[ "$loop_gpu" -ne 1 ]];do
                    echo -e "\nSelect a GPU\n"
                    echo -e "\n\n\t1) Nvidia\n\t2) Radeon\n"
                    read -p ":" op_gpu
        
                    op_gpu_array=("Nvidia" "Radeon") 

                    if [[ "$op_gpu" -eq 1 ]];then #NVIDIA
                        gpu_str=${op_gpu_array[$(($op_gpu-1))]} #only to show in python script table
                        loop_gpu=1 #breaks loop
        
                    elif [[ "$op_gpu" -eq 2 ]];then #RADEON
                        gpu_str=${op_gpu_array[$(($op_gpu-1))]} #only to show in python script table
                        loop_gpu=1 #breaks loop

                    else
                        echo -e "\nPlease, select a valid option\n"
                            
                    fi
                    echo -e "\n"
        
                done

                loop_vm=1

            else
                echo -e "\nPlease, enter a valid option\n"
            fi
        done


        
        ###################---INTEL OR AMD CPU---##########################
        loop_cpu=0

        while [[ "$loop_cpu" -ne 1 ]];do
            echo -e "\nSelect a CPU\n"
            echo -e "\t1) Intel\n\t2) AMD\n"
            read -p ":" op_cpu

            op_cpu_array=("Intel" "AMD")
            if [[ "$op_cpu" -eq 1 ]];then #INTEL
                cpu_str=${op_cpu_array[$(($op_cpu-1))]} #only to show in python script table
                loop_cpu=1 #breaks loop

            elif [[ "$op_cpu" -eq 2 ]];then #AMD
                cpu_str=${op_cpu_array[$(($op_cpu-1))]} #only to show in python script table
                loop_cpu=1 #breaks loop

            else
                echo -e "\nPlease, select a valid option\n"
                    
            fi
            echo -e "\n"

        done


    elif [[ "$1" -eq 3 ]];then
        #-----------------------3) Fast Installation----------------------------
        verify_disk

    else
        echo -e "\nPlease, select a valid option\n"

    fi


#----------Confirm installation---------------


#Table python script
#NOTE: respect python indentation

add_extra_packs

cat > /mnt/python_table.py << EOF

from terminaltables import AsciiTable

#home variables
home_str='/dev/$part_home' if $1 == 2 else 'uncreated'
home_size='$(lsblk -l | grep $part_home | awk '{print $4}')' if $1 == 2 else 'uncreated'


table_part = [
    ['Partition', 'Label', 'Size'],
    ['/dev/$part_boot', '/boot', '$(lsblk -l | grep $part_boot | awk '{print $4}')'],
    ['/dev/$part_root', '/root', '$(lsblk -l | grep $part_root | awk '{print $4}')'],
    ['/dev/$part_swap', 'swap', '$(lsblk -l | grep $part_swap | awk '{print $4}')'],
    [home_str, '/home', home_size] 
]
table_data = [
    ['Data', 'Value'],
    ['User', '$nick_name'],
    ['Password', 'SET'],
    ['GUI', '$gui_str'],
    ['Other OS', '$op_win'],
    ['VM', '$op_vm'],
    ['CPU', '$cpu_str'],
    ['GPU', '$gpu_str']
]


table_1 = AsciiTable(table_part)
table_2 = AsciiTable(table_data)
print(table_1.table)
print(table_2.table)

EOF
    clear    

    echo -e "\n\t\t\t\tArchLinux Installer\n\n"
    echo -e "\n\nPlease, verify the information\n"

    python3 /mnt/python_table.py
    rm -rf /mnt/python_table.py


    echo -e "\n"
    read -p "Is everything in order? [yes (uppercase) / no]: " confirm
    echo -e "\n"

    if [ $confirm != "YES" ];then
            echo "Aborting..."      
            exit 1
    else    
            echo "Launching installer"
            sleep 3
    fi      


    #time config
    timedatectl set-ntp true

    #[[[[[[[  SWAP PARTITION  ]]]]]]]
    mkswap /dev/$part_swap
    swapon /dev/$part_swap


    #[[[[[[[  ROOT PARTITION  ]]]]]]]
    mkfs.ext4 /dev/$part_root
    mount /dev/$part_root /mnt
    

    #[[[[[[[  HOME PARTITION  ]]]]]]]
    #format home partition if the second way was selected

    #   -add an or operator if there's an encrypt home partition

    if [[ "$1" -eq 2 ]];then
        mkfs.ext4 /dev/$part_home
        mount --mkdir /dev/$part_home /mnt/home
    fi


    #[[[[[[[  BOOT PARTITION  ]]]]]]]
    if [[ "$op_win" == "yes" ]] || [[ "$op_win" == "YES" ]];then #if windows is installed, there's no reason to format the partition
        echo -e "\nOmitting format boot partition\n"
    else
        mkfs.fat -F 32 /dev/$part_boot
    fi
    mount --mkdir /dev/$part_boot /mnt/boot


    echo -e "[+] Partition(s) formated"
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

    function gui_installer(){
        if [[ "$gui_str" != "None" ]];then
            
            pacman -S xorg-server --noconfirm    

            if [[ "$gui_str" == "Gnome" ]];then #gnome
                echo -e "\nInstalling GNOME\n"
                pacman -S gnome gnome-tweaks gnome-shell --noconfirm
                systemctl enable gdm
                
            elif [[ "$gui_str" == "Plasma" ]];then #Plasma
                echo -e "\nInstalling KDE-Plasma\n"
                pacman -S plasma-meta kde-applications --noconfirm
                systemctl enable sddm

            elif [[ "$gui_str" == "Xfce" ]];then #Xfce
                echo -e "\nInstalling XFCE4\n"
                pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm
                systemctl enable lightdm

            elif [[ "$gui_str" == "Mate" ]];then #Mate
                echo -e "\nInstalling Mate\n"
                pacman -S mate mate-extra lightdm lightdm-gtk-greeter --noconfirm
                systemctl enable lightdm

            else
                echo -e "\nInvalid option\n"

            fi    
        fi
    }



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
    echo -e "$pass_root\n$pass_root" | passwd root
    


    #Creating user
    useradd -m -G wheel,audio,video,optical,storage $nick_name -s /bin/bash
    echo -e "$pass_user\n$pass_user" | passwd $nick_name




    pacman -S sudo neovim git vim --noconfirm

    #uncomment wheel visudo
    sed -i '/^#\ %wheel\ ALL=(ALL:ALL)\ ALL/s/^# //g' /etc/sudoers


    #-----------GRUB INSTALL---------------

    # verify if is bios or uefi
    if [[ "$op_bios_selected" -eq 1 ]];then #uefi
	pacman -S grub efibootmgr dosfstools os-prober mtools --noconfirm

	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot --recheck


    elif [[ "$op_bios_selected" -eq 2 ]];then #bios packages
	pacman -S grub dosfstools os-prober mtools --noconfirm
	grub-install --target=i386-pc --recheck /dev/$op_disk

    fi


    #Detect other os
    #uncomment grub os-prober disable
    sed -i '/^#GRUB_DISABLE_OS_PROBER=false/s/^#//g' /etc/default/grub
    os-prober
    grub-mkconfig --output=/boot/grub/grub.cfg


    #Network manager config 
    pacman -Syy && pacman -S archlinux-keyring --noconfirm

    pacman -S networkmanager --noconfirm
    systemctl enable NetworkManager
    
    #--------------Others packages---------------
    pacman -S $extra_packs --noconfirm


    #/etc/fstab backup
    cp /etc/fstab /etc/fstab.bak

    #----------Graphic interface-----------
    if [[ "$gui_str" != "None" ]] || [[ "$gui_str" != "none" ]];then
        gui_installer

    else
        echo -e "\nOmitting GUI\n"
    fi


EOF

    #Changing arch root
    chmod +x /mnt/installer_2.sh
    arch-chroot /mnt /installer_2.sh

    rm -rf /mnt/installer_2.sh


    #umount partitions
    umount -l /mnt
    swapoff /dev/$part_swap

    op=9

    #reboot

}

function add_extra_packs(){
    # Just add extra packages to install

    # Nvidia
    if [[ "$gpu_str" == "Nvidia" ]];then
        echo "Currently nvidia is not supported"
        read -n 1 -p "Press any key to continue..." 

    # Radeon
    elif [[ "$gpu_str" == "Radeon" ]];then
        extra_packs="${extra_packs} xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau"

    fi

    # Intel
    if [[ "$cpu_str" == "Intel" ]];then
        extra_packs="${extra_packs} intel-ucode"

    # AMD
    elif [[ "$cpu_str" == "AMD" ]];then
        extra_packs="${extra_packs} amd-ucode"

    fi
    # vm options (add)
}


function create_partition(){
    #create partitions automatically with sgdisk
    #   sgdisk -n <part number>:<start>:<end> -t <part number>:<type hex> -c <part_number>:<label> /dev/<disk>
    #             ------------- ------  ----        
    # 0 in partition number, set the next partition number
    # 0 in start takes the largest available block in the disk
    # 0 in end takes the largest available block at the end of the disk



    # Parameters
    #   $1 disk

    #change the size of each partition if it's necessary

    #[[[[[[[  BOOT PARTITION  ]]]]]]]
    sgdisk -n 0:0:+512MB -t 0:ef00 -c 0:"EFI system partition" /dev/$1
    part_boot="${1}$(lsblk /dev/$1 -o MAJ:MIN | tail -n 1 | cut -d ':' -f 2)" # partition with its number 

    #[[[[[[[  SWAP PARTITION  ]]]]]]]
    sgdisk -n 0:0:+2GiB -t 0:8200 -c 0:swap /dev/$1
    part_swap="${1}$(lsblk /dev/$1 -o MAJ:MIN | tail -n 1 | cut -d ':' -f 2)" # partition with its number 

    # add home partition

    #[[[[[[[  ROOT PARTITION  ]]]]]]]
    sgdisk -n 0:0:0 -t 0:8300 -c 0:root /dev/$1
    part_root="${1}$(lsblk /dev/$1 -o MAJ:MIN | tail -n 1 | cut -d ':' -f 2)" # partition with its number  

}

function verify_disk(){

        lsblk -l | grep "\ disk\ "

        #verify if the disk exists
        loop_disk=1
        while [[ "$loop_disk" -ne 0 ]];do

            read -p "Select disk (eg. sda): " op_disk 
            
            lsblk -l | awk '{print $1}' | grep -q $op_disk #find disk's name, if it doesn't, $? set to 1, if not, set to 0
            
            if [[ "$?" -ne 0 ]];then
                    echo "[FAILED] $op_disk is not a disk"
            else    
                    echo "[OK] $op_disk selected"
                    read -p "Press any key to continue..."
                    loop_disk=0
                    
            fi      

        done


}


function verify_partition(){
    #first parameter is the status of the previous command
    #second parameter is the length, if it's less than 4 could be the complete disk (sdX) 
    if [ $1 -ne 0 ] || [ $2 -lt 4 ] ;then
            echo "1"
    else
            #select correct partition
            echo "0"
    fi
 
}



function assign_partitions(){
    
    if [[ "$1" -eq 1 ]] ;then #only 3 partitions, $1 is the way to install arch
        lb_parts=( "boot" "root" "swap" ) #array to iterate and assign variable's name  

    elif [[ "$1" -eq 2 ]];then
        lb_parts=( "boot" "root" "swap" "home" ) #it will create part_home
    fi 

    lsblk -l | grep part
    

    for partition in "${lb_parts[@]}";do
        loop_part=1
        while [ $loop_part -ne 0 ];do

            read -p "Select $partition partition (eg. sda3): " part_$partition #create unique variable name (part_boot, part_swap, part_root)
            
            
            #it's necessary to create the next variable, cause the script can't 
            #call the variable like $part_$partition, that's wrong
                
            declare -n part_verify="part_$partition"


            lsblk -l | awk '{print $1}' | grep -q $part_verify #find partition's name, if it doesn't, $? set to 1, if not, set to 0
            loop_part=$(verify_partition $? $(echo $part_verify | awk '{print length}'))             
            
            if [ $loop_part -eq 1 ];then
                    echo "[FAILED] $part_verify is not a partition"
            else    
                    echo "[OK] $part_verify selected for $partition"
                    
            fi      

        done

    done
 
 
}


function create_password(){ 
        #-$1 profile name
            
        loop_pass=0
        
        while [ $loop_pass -ne 1 ];do 
         
                read -p "Enter ${1}'s password: " -s pass_$1 #it creates pass_root and pass_user variable  
                echo -e "\n"
                read -p "Retype the password: " -s pass_2       
                echo -e "\n"
        
                declare -n pass_verify="pass_$1"        
        
                if [ $pass_verify != $pass_2 ];then
                        echo "Passwords do not match"
                else
                        echo "Password set successfully"
                        loop_pass=1 #breaks loop
                fi
        
        done    
        
 
}



function main(){

    op=0
    
    while [ $op -ne 9 ];do
        ##########################################################################################
        ###############                   MAIN MENU                             #################    
        ##########################################################################################

        clear

        echo -e "\n\t\t\t\tArchLinux Installer\n\n"
        echo -e "Warning: Before to install arch, set a internet connection and create the next partitions\n"
        echo -e "\t- Boot Partition (/boot)\n\t- Root Partition (/)\n\t- Swap Partition\n\nIf you want /home in another partition, create and select it later\n"      

        read -n 1 -p "Press any key to continue..." 


        clear
        echo -e "\n\t\t\t\tArchLinux Installer\n\n"
        echo -e "Please, select one way to install arch\n"
        echo -e "\t1) Arch dual boot\n"
        echo -e "\t2) Arch dual boot with home partition\n"
        echo -e "\t3) Fast installation\n"
        echo -e "\t9) Exit\n"

        read -n 1 -p ":" op 

        if [[ "$op" -eq 1 ]];then
            installer "1"

        elif [[ "$op" -eq 2 ]];then
            installer "2"

        elif [[ "$op" -eq 3 ]];then
            installer "3"

        elif [[ "$op" -eq 9 ]];then
            echo -e "\nAborting...\n"
            exit 0
        else
            echo "Warning: select a valid option"
        fi

    done

}

main "$@"
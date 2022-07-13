#!/bin/bash

#enhancements:
#   - add connection test (ping)
#   - add sfdiks


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
 
    lb_parts=( "boot" "root" "swap" ) #array to iterate and assign variable's name  
    for partition in "${lb_parts[@]}";do
        loop_part=1
        while [ $loop_part -ne 0 ];do

                read -p "Select $partition partition: " part_$partition #create unique variable name
                
                
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
        #       -$1 profile name
            
        loop_pass=0
        
        while [ $loop_pass -ne 1 ];do 
         
                read -p "Enter ${1}'s password: " -s pass_$1  
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

 

clear

echo -e "\n\t\t\t\tArchLinux Installer\n\n"
echo -e "Warning: Before to install arch, set a internet connection and set the next partitions\n"
echo -e "\t- Boot Partition (/boot)\n\t- Root Partition (/)\n\t- Swap Partition\n"      

read -n 1 -p "Press any key to continue..." 


clear
echo -e "\n\t\t\t\tArchLinux Installer\n\n"
echo -e "Please, select one way to install arch\n"
echo -e "\t1) Arch dual boot, separate boot partition (boot,swap and root partition)"
echo -e "\t2) Arch dual boot, same Windows boot partition"
echo -e "\t9) Exit\n"

read -n 1 -p ":" op 

clear

pacman -Sy
pacman -S python-pip --noconfirm
pip install terminaltables

ping -c 3 8.8.8.8

if [ $? -ne 0 ];then
    echo "There's no internet connection"
    exit 1
else
    clear
fi


if [ $op -eq 1 ];then
    #add checking
    lsblk -l | grep part #show partitions
 
    assign_partitions

    read -p "Enter your profile name: " nick_name
    echo -e "\n"    

    create_password $nick_name
    declare -n pass_user="pass_$nick_name" #is necessary create this variable to identify the user name and not depend on $1 of the function create_password
    echo -e "\n"    

    create_password "root"

    #confirm installation

    clear

    echo -e "\nPlease, verify the information\n"

    #Table python script

    #NOTE: respect python indentation
cat > /mnt/python_table.py << EOF

from terminaltables import AsciiTable

table_part = [
    ['Partition', 'Label', 'Size'],
    ['/dev/$part_boot', '/boot', '$(lsblk -l | grep $part_boot | awk '{print $4}')'],
    ['/dev/$part_root', '/root', '$(lsblk -l | grep $part_root | awk '{print $4}')'],
    ['/dev/$part_swap', 'swap', '$(lsblk -l | grep $part_swap | awk '{print $4}')']
]
table = AsciiTable(table_part)
print(table.table)

EOF

    python3 /mnt/python_table.py

    rm -rf /mnt/python_table.py

    echo -e "\n\n\tUser =======> $nick_name\n"


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
    echo -e "$pass_root\n$pass_root" | passwd root
    


    #Creating user
    useradd -m -G wheel,audio,video,optical,storage $nick_name -s /bin/bash
    echo -e "$pass_user\n$pass_user" | passwd $nick_name




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

    rm -rf /mnt/installer_2.sh

    #umount partitions



    #reboot

elif [ $op -eq 2 ];then
    echo "ERROR: this option is not available yet"

elif [ $op -eq 9 ];then
    echo "Exiting..."
else
    echo "Warning: select a valid option"

fi



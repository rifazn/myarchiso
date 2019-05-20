#!/bin/bash

### Preinstallation ###

# Update system clock
timedatectl set-ntp true

# Display disk layout
# TODO: Validate user inputs

fdisk -l

read -p "\nWhich partition would you like to install Arch Linux in? " p
read -p "Partion for swap? " s
echo "Arch will be installed in $p"
echo "Swap space will be activated in $s"

read -p "Are you sure you want to install Arch in $p? " yn
case $yn in
	y|Y|yes|YES)
		echo -e "\nInstalling Arch\n"
		;;
	n|N|no|NO)
		echo "Arch not installed. No changes made."
		exit 0
		;;
	# TODO: Loop for unexpected inputs here
esac

# Format partitions
echo -e "Formatting partitions.\n"
mkfs.ext4 $p
mkswap $s
swapon $s
echo -e "Formatting complete.\n"

# Mount filesystem on the installation partition to /mnt
mount $p /mnt
mkdir /mnt/efi
mount $s /mnt/efi

### Installation ###

# Select (Prioritize) mirrors
vim /etc/pacman.d/mirrorlist

# Install the base package and other packages
pacstrap /mnt base base-devel exfat-utils wpa_supplicant networkmanager

### Configuration ###
genfstab -U /mnt >> /mnt/etc/fstab

# Change root
arch-chroot /mnt

# Set the time-zone
ln -sf /usr/share/zoneinfo/Asia/Dhaka /etc/localtime
hwclock --systohc

# Localization

exit 0

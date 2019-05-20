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
vim /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Name of your installation (i.e. hostname, aka "Computer Name")
read -p "What would you like to call your installation (hostname)? cname
echo $cname > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	$cname.localdomain	$cname
EOF

# Start network
ip link
read -p "Name of wireless interface: " wl
ip link set $wl up
systemctl start NetworkManager.service
nmtui-connect

# Set a root password
echo "Enter your root password in the prompt below."
passwd

### Post Instllation ###

# Adding a user with with sudo rights
read -p "Enter name of the user (no spaces): " u
useradd --create-home --groups wheel $u
echo "New user $u added. In the prompt below enter the password for the new user."
passwd $u

# Letting users in 'wheel' group sudo usage rights
# Just uncomment the line wheel = ... ALL ...
# TODO: maybe use sed to do this?
visudo

# Installing graphics drivers
pacman -Sy mesa vulkan-intel intel-media-driver

# Installing the "sway" window manager

pacman -S sway swaylock swayidle gtk3

# Autostart sway on login. Note, no display server is installed to do this.

cat > ~/.bash_profile <<EOF
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  XKB_DEFAULT_LAYOUT=us exec sway
fi
EOF

# Install pulseaudio

pacman -S pulseaudio

# Install video codecs
# TODO: move 'ranger' to somewhere more appropriate

pacman -S gst-plugins-ugly mpv ranger

### DONE ###

# Exit from chroot
exit

# Unmount all mounted partitions
umount -R /mnt

echo -e "\n\n\nAnd thats it! You can now restart o your new Arch Linux setup."

exit 0

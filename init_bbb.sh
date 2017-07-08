#!/bin/bash

# Usage sudo init_bbb.sh <username>

#if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo "Updating the system"
sudo apt-get -y update
sudo apt-get -y upgrade

echo "Copying udev-rules, services and bashrc"
sudo cp -r ./etc /
sudo cp -r ./usr /
sudo cp -r ./home/.bashrc /home/$USER/.bashrc
sudo chown $USER:$USER /home/$USER/.bashrc

echo "Adding gpio and cape group"
sudo groupadd -f cape
sudo groupadd -f gpio

echo "Add current user to gpio and cape group"
sudo usermod -a -G cape $USER
sudo usermod -a -G gpio $USER

echo "Enable capemgr_usr service"
sudo systemctl enable capemgr_usr.service

# Add capemgr v4.4.x+ support
echo "Clone capemgr v4.4.x+"
git clone https://github.com/beagleboard/bb.org-overlays
cd ./bb.org-overlays/
echo "Build and install DTC"
./dtc-overlay.sh
echo "Build and install Overlay capes"
./install.sh
echo "Add capemgr to uEnv.txt"
sudo su -c "echo 'dtb=am335x-boneblack-overlay.dtb' >> /boot/uEnv.txt"
sudo su -c "echo 'cape_disable=bone_capemgr.disable_partno=' >> /boot/uEnv.txt"
sudo su -c "echo 'cape_enable=bone_capemgr.enable_partno=' >> /boot/uEnv.txt"

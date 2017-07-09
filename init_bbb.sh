#!/bin/bash

# Usage sudo init_bbb.sh <username>

#if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo "Updating the system and installing base packages"
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install nfs-kernel-server nfs-common

echo "Copying udev-rules, services and bashrc"
sudo cp -r ./etc /
sudo cp -r ./usr /
sudo cp -r ./home/.bashrc /home/$USER/.bashrc
sudo chown $USER:$USER /home/$USER/.bashrc

echo "Adding gpio, cape and pwm group"
sudo groupadd -f cape
sudo groupadd -f gpio
sudo groupadd -f pwm

echo "Add current user to gpio cape, pwm group"
sudo usermod -a -G cape $USER
sudo usermod -a -G gpio $USER
sudo usermod -a -G pwm $USER

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

echo "Setting up NFS and project folder"
sudo mkdir -p /projects
sudo chown -R $USER:$USER /projects
ln -s /projects /home/$USER/projects

sudo mkdir -p /srv/nfs
sudo mkdir -p /srv/nfs/projects
sudo mkdir -p /srv/nfs/home/$USER
sudo mkdir -p /srv/nfs/root

sudo su -c "echo '/home/$USER/ /srv/nfs/home/$USER none bind 0 0' >> /etc/fstab"
sudo su -c "echo '/projects/ /srv/nfs/projects  none bind 0 0' >> /etc/fstab"
sudo su -c "echo '/ /srv/nfs/root none bind 0 0' >> /etc/fstab"
sudo mount -a

sudo su -c "echo '/srv/nfs 192.168.1.0/24(rw,fsid=0,insecure,no_subtree_check,async)' >> /etc/exports"
sudo su -c "echo '/srv/nfs/root 192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async)' >> /etc/exports"
sudo su -c "echo '/srv/nfs/home 192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async)' >> /etc/exports"
sudo su -c "echo '/srv/nfs/home/$USER 192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async)' >> /etc/exports"
sudo su -c "echo '/srv/nfs/projects 192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async)' >> /etc/exports"

sudo service nfs-kernel-server restart

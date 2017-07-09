# Compile the BBB TI kernel using the instructions given by Robert Nelsen
# https://eewiki.net/display/linuxonarm/BeagleBone+Black
#!/bin/bash

export DISK=/dev/mmcblk0
mkdir build
cd build

echo "----------- Setup crosscompiler -----------"
wget -c https://releases.linaro.org/components/toolchain/binaries/5.4-2017.05/arm-linux-gnueabihf/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf.tar.xz
tar xf gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf.tar.xz
export CC=`pwd`/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-

echo "----------- Setup u-boot -----------"
git clone https://github.com/u-boot/u-boot
cd u-boot/
git checkout v2017.07-rc2 -b tmp

echo "----------- Apply patches to u-boot -----------"
wget -c https://rcn-ee.com/repos/git/u-boot-patches/v2017.07-rc2/0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
wget -c https://rcn-ee.com/repos/git/u-boot-patches/v2017.07-rc2/0002-U-Boot-BeagleBone-Cape-Manager.patch

patch -p1 < 0001-am335x_evm-uEnv.txt-bootz-n-fixes.patch
patch -p1 < 0002-U-Boot-BeagleBone-Cape-Manager.patch

echo "----------- Configure and build u-boot -----------"
make ARCH=arm CROSS_COMPILE=${CC} distclean
make ARCH=arm CROSS_COMPILE=${CC} am335x_evm_defconfig
make ARCH=arm CROSS_COMPILE=${CC}

echo "----------- Download TI-Linux kernel dev -----------"
cd ..
git clone https://github.com/RobertCNelson/ti-linux-kernel-dev.git
cd ti-linux-kernel-dev/
git checkout origin/ti-linux-4.9.y -b tmp

echo "----------- Configure and build kernel -----------"
./build_kernel.sh

echo "----------- Download and apply patches -----------"
# Custom patch to alter the PWM, so that they generate udev events
cd KERNEL
wget -c https://raw.githubusercontent.com/RobertCNelson/linux-dev/master/patches/drivers/pwm/0001-pwm-Create-device-class-for-pwm-channels.patch
git apply 0001-pwm-Create-device-class-for-pwm-channels.patch
cd ..
./tools/rebuild.sh

export kernel_version=$(cat "./KERNEL/include/generated/utsrelease.h" | awk '{print $3}' | sed 's/\"//g')
cd ..

echo "----------- Download Debian 9 -----------"
wget -c https://rcn-ee.com/rootfs/eewiki/minfs/debian-9.0-minimal-armhf-2017-06-18.tar.xz
tar xf debian-9.0-minimal-armhf-2017-06-18.tar.xz

echo "----------- Setup disk and install bootloader -----------"
sudo dd if=/dev/zero of=${DISK} bs=1M count=10
sync
sudo dd if=./u-boot/MLO of=${DISK} count=1 seek=1 bs=128k
sync
sudo dd if=./u-boot/u-boot.img of=${DISK} count=2 seek=1 bs=384k
sync
read -p "Remove and reinsterred SD-card, Press [Enter] to continue"
sudo sfdisk ${DISK} <<-__EOF__
4M,,L,*
__EOF__
sync
sudo mkfs.ext4 -L rootfs -O ^metadata_csum,^64bit ${DISK}p1
sync
sudo mkdir -p /media/rootfs/
sudo mount ${DISK}p1 /media/rootfs/

sudo mkdir -p /media/rootfs/opt/backup/uboot/
sudo cp -v ./u-boot/MLO /media/rootfs/opt/backup/uboot/
sudo cp -v ./u-boot/u-boot.img /media/rootfs/opt/backup/uboot/

echo "----------- Copy root file system -----------"
sudo tar xfvp ./*-*-*-armhf-*/armhf-rootfs-*.tar -C /media/rootfs/
sync
sudo chown root:root /media/rootfs/
sudo chmod 755 /media/rootfs/

echo "----------- Set uname in eEnv.txt -----------"
sudo sh -c "echo 'uname_r=${kernel_version}' >> /media/rootfs/boot/uEnv.txt"

echo "----------- Copy Kernel -----------"
sudo cp -v ./ti-linux-kernel-dev/deploy/${kernel_version}.zImage /media/rootfs/boot/vmlinuz-${kernel_version}

echo "----------- Copy Kernel Device Tree Binaries -----------"
sudo mkdir -p /media/rootfs/boot/dtbs/${kernel_version}/
sudo tar xfv ./ti-linux-kernel-dev/deploy/${kernel_version}-dtbs.tar.gz -C /media/rootfs/boot/dtbs/${kernel_version}/

echo "----------- Copy Kernel Modules -----------"
sudo tar xfv ./ti-linux-kernel-dev/deploy/${kernel_version}-modules.tar.gz -C /media/rootfs/

echo "----------- Setup file systems table -----------"
sudo sh -c "echo '/dev/mmcblk0p1  /  auto  errors=remount-ro  0  1' >> /media/rootfs/etc/fstab"

echo "----------- Setup network -----------"
sudo sh -c "echo 'auto lo' >> /media/rootfs/etc/network/interfaces"
sudo sh -c "echo 'iface lo inet loopback' >> /media/rootfs/etc/network/interfaces"
sudo sh -c "echo 'auto eth0' >> /media/rootfs/etc/network/interfaces"
sudo sh -c "echo 'iface eth0 inet dhcp' >> /media/rootfs/etc/network/interfaces"

echo "----------- Finished don't forget to run init_bbb.sh on the BBB -----------"
sync
sudo umount /media/rootfs

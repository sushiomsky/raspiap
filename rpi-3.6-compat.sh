#!/bin/bash

# This is the Raspberry Pi Kali ARM build script - http://www.kali.org/downloads
# A trusted Kali Linux image created by Offensive Security - http://www.offensive-security.com

if [[ $# -eq 0 ]] ; then
    echo "Please pass version number, e.g. $0 1.0.1"
    exit 0
fi

basedir=`pwd`/rpi-$1

# Package installations for various sections.
# This will build a minimal XFCE Kali system with the top 10 tools.
# This is the section to edit if you would like to add more packages.
# See http://www.kali.org/new/kali-linux-metapackages/ for meta packages you can
# use. You can also install packages, using just the package name, but keep in
# mind that not all packages work on ARM! If you specify one of those, the
# script will throw an error, but will still continue on, and create an unusable
# image, keep that in mind.

arm="abootimg cgpt fake-hwclock ntpdate vboot-utils vboot-kernel-utils uboot-mkimage"
base="initramfs-tools sudo parted e2fsprogs usbutils"
desktop=" "
tools=""
services="hostapd pdnsd udhcpd openssh-server"
extras="aircrack-ng sslstrip"
#hostapd will be replaced with karma patched hostapd we need only init script which come with the package
size=4000 # Size of image in megabytes

export packages="${arm} ${base} ${desktop} ${tools} ${services} ${extras}"
export architecture="armel"

# Check to ensure that the architecture is set to ARMEL since the RPi is the
# only board that is armel.
if [[ $architecture != "armel" ]] ; then
    echo "The Raspberry Pi cannot run the Debian armhf binaries"
    exit 0
fi

# Set this to use an http proxy, like apt-cacher-ng, and uncomment further down
# to unset it.
#export http_proxy="http://localhost:3142/"

mkdir -p ${basedir}
cd ${basedir}

# create the rootfs - not much to modify here, except maybe the hostname.
debootstrap --foreign --arch $architecture kali kali-$architecture http://http.kali.org/kali

cp /usr/bin/qemu-arm-static kali-$architecture/usr/bin/

LANG=C chroot kali-$architecture /debootstrap/debootstrap --second-stage
cat << EOF > kali-$architecture/etc/apt/sources.list
deb http://http.kali.org/kali kali main contrib non-free
deb http://security.kali.org/kali-security kali/updates main contrib non-free
EOF

# Set hostname
echo "ap51" > kali-$architecture/etc/hostname

# So X doesn't complain, we add kali to hosts
cat << EOF > kali-$architecture/etc/hosts
127.0.0.1       ap51    localhost
EOF

cat << EOF > kali-$architecture/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto wlan0
allow-hotplug wlan0
iface wlan0 inet static
address 192.168.100.1
netmask 255.255.255.0

EOF

cat << EOF > kali-$architecture/etc/resolv.conf
nameserver 208.67.222.222
nameserver 8.8.8.8
EOF

cat << EOF > kali-$architecture/etc/default/udhcpd
DHCPD_ENABLED="yes"
DHCPD_OPTS=""
EOF

cat << EOF > kali-$architecture/etc/udhcpd.conf
interface wlan0
start 192.168.100.100
end 192.168.100.250
max_leases 150

#option dns 192.168.100.1
option dns 208.67.222.222
option subnet 255.255.255.0
option router 192.168.100.1 
EOF

cat << EOF > kali-$architecture/etc/default/hostapd
DAEMON_CONF="/etc/hostapd.conf"
#DAEMON_OPTS=""
EOF

cat << EOF > kali-$architecture/etc/hostapd.conf
# config file to use with the Karma'd version of hostapd
# created by Robin Wood - robin@digininja.org - www.digininja.org

interface=wlan0
driver=nl80211
ssid=FreeInternet
channel=1

# Both open and shared auth
auth_algs=3

# no SSID cloaking
ignore_broadcast_ssid=0

# -1 = log all messages
logger_syslog=-1
logger_stdout=-1

# 2 = informational messages
logger_syslog_level=2
logger_stdout_level=2

# Dump file for state information (on SIGUSR1)
# example: kill -USR1 <pid>
dump_file=/tmp/hostapd.dump
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

# 0 = accept unless in deny list
macaddr_acl=0

# only used if you want to do filter by MAC address
#accept_mac_file=/etc/hostapd.accept
#deny_mac_file=/etc/hostapd.deny

# Finally, enable Karma
enable_karma=1

# Black and white listing
# 0 = while
# 1 = black
karma_black_white=1
EOF

export MALLOC_CHECK_=0 # workaround for LP: #520465
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

mount -t proc proc kali-$architecture/proc
mount -o bind /dev/ kali-$architecture/dev/
mount -o bind /dev/pts kali-$architecture/dev/pts

cat << EOF > kali-$architecture/debconf.set
console-common console-data/keymap/policy select Select keymap from full list
console-common console-data/keymap/full select en-latin1-nodeadkeys
EOF


cat << EOF > kali-$architecture/third-stage
#!/bin/bash
dpkg-divert --add --local --divert /usr/sbin/invoke-rc.d.chroot --rename /usr/sbin/invoke-rc.d
cp /bin/true /usr/sbin/invoke-rc.d
echo -e "#!/bin/sh\nexit 101" > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

apt-get update
apt-get install locales-all

debconf-set-selections /debconf.set
rm -f /debconf.set
apt-get update
apt-get -y install git-core binutils ca-certificates initramfs-tools uboot-mkimage
apt-get -y install locales console-common less nano git
echo "root:toor" | chpasswd
sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
apt-get --yes --force-yes install $packages

wget https://raw.githubusercontent.com/sushiomsky/raspiap/master/rc.local -O /etc/rc.local
cd /usr/local/src
git clone https://github.com/sushiomsky/logex.git logex

update-rc.d udhcpd enable
update-rc.d ssh enable
update-rc.d pdnsd enable
update-rc.d rc.local enable

apt-get --ignore-missing install -y build-essential libpcap-dev tmux byobu ettercap-text-only proxychains python-dev python-pypcap subversion git nano vim libnl-dev libssl-dev ruby ruby-dev sqlite3 libsqlite3-dev libsqlite3-ruby1.9.1 python-twisted

wget http://hostap.epitest.fi/releases/hostapd-2.0.tar.gz
tar xvf hostapd-2.0.tar.gz
cd hostapd-2.0/
wget http://pentoo.googlecode.com/svn/portage/trunk/net-wireless/hostapd/files/hostapd-2.0-cui.patch
wget http://pentoo.googlecode.com/svn/portage/trunk/net-wireless/hostapd/files/hostapd-2.0-karma.patch
wget http://pentoo.googlecode.com/svn/portage/trunk/net-wireless/hostapd/files/hostapd-2.0-tls_length_fix.patch
wget http://pentoo.googlecode.com/svn/portage/trunk/net-wireless/hostapd/files/hostapd-2.0-wpe_karma.patch

patch -p1 < hostapd-2.0-cui.patch
patch -p1 < hostapd-2.0-karma.patch
patch -p1 < hostapd-2.0-tls_length_fix.patch
patch -p1 < hostapd-2.0-wpe_karma.patch

#There's a edit in the patch that breaks all the things. Gotta delete this line.
sed '29d' src/ap/pmksa_cache_auth.h > /tmp/out.h
mv /tmp/out.h src/ap/pmksa_cache_auth.h
#make all the things
cd hostapd/
cp defconfig .config
make hostapd
apt-get -y remove hostapd
cp hostapd /usr/sbin/hostapd
make install

update-rc.d hostapd defaults
update-rc.d hostapd enable

apt-get remove -y build-essential libpcap-dev tmux byobu proxychains vim ruby ruby-dev sqlite3 libsqlite3-dev libsqlite3-ruby1.9.1 
apt-get -y autoremove
apt-get -y autoclean

wget https://raw.githubusercontent.com/sushiomsky/raspiap/master/iptables -O /etc/network/if-pre-up.d/iptables

rm -f /usr/sbin/policy-rc.d
rm -f /usr/sbin/invoke-rc.d
dpkg-divert --remove --rename /usr/sbin/invoke-rc.d

rm -f /third-stage
EOF


chmod +x kali-$architecture/third-stage
LANG=C chroot kali-$architecture /third-stage

cat << EOF > kali-$architecture/cleanup
#!/bin/bash
rm -rf /root/.bash_history
apt-get update
apt-get clean
rm -f /0
rm -f /hs_err*
rm -f cleanup
rm -f /usr/bin/qemu*
EOF

chmod +x kali-$architecture/cleanup
LANG=C chroot kali-$architecture /cleanup

umount kali-$architecture/proc/sys/fs/binfmt_misc
umount kali-$architecture/dev/pts
umount kali-$architecture/dev/
umount kali-$architecture/proc

# Create the disk and partition it
echo "Creating image file for Raspberry Pi"
dd if=/dev/zero of=${basedir}/kali-$1-rpi.img bs=1M count=$size
parted kali-$1-rpi.img --script -- mklabel msdos
parted kali-$1-rpi.img --script -- mkpart primary fat32 0 64
parted kali-$1-rpi.img --script -- mkpart primary ext4 64 -1

# Set the partition variables
loopdevice=`losetup -f --show ${basedir}/kali-$1-rpi.img`
device=`kpartx -va $loopdevice| sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
bootp=${device}p1
rootp=${device}p2

# Create file systems
mkfs.vfat $bootp
mkfs.ext4 $rootp

# Create the dirs for the partitions and mount them
mkdir -p ${basedir}/bootp ${basedir}/root
mount $bootp ${basedir}/bootp
mount $rootp ${basedir}/root

echo "Rsyncing rootfs into image file"
rsync -HPavz -q ${basedir}/kali-$architecture/ ${basedir}/root/

# Enable login over serial
echo "T0:23:/sbin/getty -L ttyAMA0 115200 vt100" >> ${basedir}/root/etc/inittab

# Uncomment this if you use apt-cacher-ng otherwise git clones will fail.
#unset http_proxy

# Kernel section. If you want to use a custom kernel, or configuration, replace
# them in this section.
git clone -b rpi-3.6.y --depth 1 https://github.com/raspberrypi/linux ${basedir}/kernel
git clone --depth 1 https://github.com/raspberrypi/tools ${basedir}/tools

cd ${basedir}/kernel
mkdir -p ../patches
wget http://patches.aircrack-ng.org/mac80211.compat08082009.wl_frag+ack_v1.patch -O ../patches/mac80211.patch
#wget https://raw.github.com/offensive-security/kali-arm-build-scripts/master/patches/kali-wifi-injection-3.12.patch -O ../patches/mac80211.patch
patch -p1 --no-backup-if-mismatch < ../patches/mac80211.patch
touch .scmversion
export ARCH=arm
#export CROSS_COMPILE=${basedir}/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-
export CROSS_COMPILE=${basedir}/tools//arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-
wget http://svn.stmlabs.com/svn/raspbmc/patches/kernel-hardfp.patch
patch -p1 < kernel-hardfp.patch

make bcmrpi_defconfig

#KERNEL_VERSION=`make kernelversion`
make -j $(grep -c processor /proc/cpuinfo)
make modules_install INSTALL_MOD_PATH=${basedir}/root
#mkdir -p ${basedir}/root/lib/modules/${KERNEL_VERSION}/build
#make headers_install ARCH=arm INSTALL_HDR_PATH=${basedir}/root/lib/modules/${KERNEL_VERSION}/build

git clone -b next --depth 1 https://github.com/raspberrypi/firmware.git rpi-firmware
cp -rf rpi-firmware/boot/* ${basedir}/bootp/
cp arch/arm/boot/zImage ${basedir}/bootp/kernel.img
cd ${basedir}

#COMPAT WIREELESS DRIVERS
wget https://www.kernel.org/pub/linux/kernel/projects/backports/stable/v3.15-rc1/backports-3.15-rc1-1.tar.gz
tar -xvf backports-3.15-rc1-1.tar.gz
cd backports-3.15-rc1-1
#wget https://www.kernel.org/pub/linux/kernel/projects/backports/2014/05/16/backports-20140516.tar.gz
#tar -xzf backports-20140516.tar.gz
#cd backports-20140516

wget -O../patches/rtlwifi_RegDB_33dBm.patch https://gist.githubusercontent.com/sushiomsky/21cfa382838f2c74b10b/raw/515a8cb49bb52b50bc1b65b7c26c3475073a5518/rtlwifi_RegDB_33dBm.patch
patch -p1 < ../patches/rtlwifi_RegDB_33dBm.patch

wget -O../patches/compatdrivers_chan_qos_frag.patch http://pastie.org/pastes/7977109/download
patch -p1 < ../patches/compatdrivers_chan_qos_frag.patch

#wget https://raw.github.com/offensive-security/kali-arm-build-scripts/master/patches/kali-wifi-injection-3.12.patch -O ../patches/mac80211.patch
wget http://patches.aircrack-ng.org/mac80211.compat08082009.wl_frag+ack_v1.patch -O ../patches/mac80211.patch
patch -p1 < ../patches/mac80211.patch

set -a
CROSS_COMPILE=${CROSS_COMPILE}
ARCH=${ARCH}
KLIB_BUILD=${basedir}/kernel
KLIB=${basedir}/root
set +a

make defconfig-rtlwifi
make 
make install

cat << EOF > ${basedir}/etc/modprobe.d/fbdev-blacklist.conf 
8192cu
EOF
cat << EOF > ${basedir}/etc/modules 
rtl8192cu
EOF

# Create cmdline.txt file
cat << EOF > ${basedir}/bootp/cmdline.txt
dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 elevator=deadline root=/dev/mmcblk0p2 rootfstype=ext4 rootwait
EOF

rm -rf ${basedir}/root/lib/firmware
cd ${basedir}/root/lib
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git firmware
rm -rf ${basedir}/root/lib/firmware/.git

# rpi-wiggle
mkdir -p ${basedir}/root/scripts
wget https://raw.github.com/dweeber/rpiwiggle/master/rpi-wiggle -O ${basedir}/root/scripts/rpi-wiggle.sh
chmod 755 ${basedir}/root/scripts/rpi-wiggle.sh

# lazykali
wget http://lazykali.googlecode.com/files/lazykali.sh -O ${basedir}/root/scripts/lazykali.sh
chmod 755 ${basedir}/root/scripts/lazykali.sh

cd ${basedir}

# Unmount partitions
umount $bootp
umount $rootp
kpartx -dv $loopdevice
losetup -d $loopdevice

# Clean up all the temporary build stuff and remove the directories.
# Comment this out to keep things around if you want to see what may have gone
# wrong.
#echo "Cleaning up the temporary build files..."
#rm -rf ${basedir}/kernel ${basedir}/bootp ${basedir}/root ${basedir}/kali-$architecture ${basedir}/boot ${basedir}/tools ${basedir}/patches

# If you're building an image for yourself, comment all of this out, as you
# don't need the sha1sum or to compress the image, since you will be testing it
# soon.
#echo "Generating sha1sum for kali-$1-rpi.img"
#sha1sum kali-$1-rpi.img > ${basedir}/kali-$1-rpi.img.sha1sum
# Don't pixz on 32bit, there isn't enough memory to compress the images.
#MACHINE_TYPE=`uname -m`
#if [ ${MACHINE_TYPE} == 'x86_64' ]; then
#echo "Compressing kali-$1-rpi.img"
#pixz ${basedir}/kali-$1-rpi.img ${basedir}/kali-$1-rpi.img.xz
#rm ${basedir}/kali-$1-rpi.img
#echo "Generating sha1sum for kali-$1-rpi.img.xz"
#sha1sum kali-$1-rpi.img.xz > ${basedir}/kali-$1-rpi.img.xz.sha1sum
#fi

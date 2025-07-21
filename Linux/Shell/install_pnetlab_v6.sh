#!/bin/bash
clear
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# Script designed to upgrade dependencies in PNETLab UBUNTU 20.04
# Requirement: You need to have UBUNTU 20.04
# CONSTANTS
GREEN='\033[32m'
RED='\033[31m'
NO_COLOR='\033[0m'

KERNEL=pnetlab_kernel.zip
rm /var/lib/dpkg/lock* &>/dev/null
dpkg --configure -a &>/dev/null

URL_KERNEL=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/L/linux-5.17.15-pnetlab-uksm/pnetlab_kernel.zip
URL_PRE_DOCKER=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/D/pre-docker.zip
URL_PNET_GUACAMOLE=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_GUACAMOLE/pnetlab-guacamole_6.0.0-7_amd64.deb
URL_PNET_DYNAMIPS=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_DYNAMIPS/pnetlab-dynamips_6.0.0-30_amd64.deb
URL_PNET_SCHEMA=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_SCHEMA/pnetlab-schema_6.0.0-30_amd64.deb
URL_PNET_VPC=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_VPC/pnetlab-vpcs_6.0.0-30_amd64.deb
URL_PNET_QEMU=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_QEMU/pnetlab-qemu_6.0.0-30_amd64.deb
URL_PNET_DOCKER=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_DOCKER/pnetlab-docker_6.0.0-30_amd64.deb
URL_PNET_PNETLAB=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_PNETLAB/pnetlab_6.0.0-100_amd64.deb
URL_PNET_WIRESHARK=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/P/PNET_WIRESHARK/pnetlab-wireshark_6.0.0-30_amd64.deb
URL_PNET_TPM=https://drive.labhub.eu.org/0:/upgrades_pnetlab/Focal/T/swtpm-focal.zip

lsb_release -r -s | grep -q 20.04
if [ $? -ne 0 ]; then
    echo -e "${RED}Upgrade has been rejected. You need to have UBUNTU 20.04 to use this script${NO_COLOR}"
    exit 0
fi

# On Azure attach data disk
azure_disk_tune() {
    ls -l /dev/disk/by-id/ | grep -q sdc && (
        echo o # Create a new empty DOS partition table
        echo n # Add a new partition
        echo p # Primary partition
        echo 1 # Partition number
        echo   # First sector (Accept default: 1)
        echo   # Last sector (Accept default: varies)
        echo w # Write changes
    ) | sudo fdisk /dev/sdc && (
        mke2fs -F /dev/sdc1
        echo "/dev/sdc1	/opt	ext4	defaults,discard	0 0 " >>/etc/fstab
        mount /opt
    )
}

#permit root access from ssh
sed -i -e "s/.*PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config &>/dev/null
sed -i -e 's/.*DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/' /etc/systemd/system.conf &>/dev/null
systemctl restart ssh &>/dev/null

#install  packages required
add-apt-repository --yes ppa:ondrej/php &>/dev/null
echo "deb [trusted=yes] http://archive.ubuntu.com/ubuntu bionic main universe" | sudo tee /etc/apt/sources.list.d/pnetlab.list
apt-get update


# set passwrod for root
if [ ! -e /opt/ovf/.configured ]; then
    echo root:pnet | chpasswd &>/dev/null
fi

# detect if pnet run will run under  bare metal or kvm hypervisor
systemd-detect-virt -v >/tmp/hypervisor
resize() {
    ROOTLV=$(mount | grep ' / ' | awk '{print $1}')
    echo "$ROOTLV"
    lvextend -l +100%FREE "$ROOTLV"
    echo Resizing ROOT FS
    resize2fs "$ROOTLV"
}
fgrep -e kvm -e none /tmp/hypervisor 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
    grep -q kvm /tmp/hypervisor && resize &>/dev/null
    grep -q none /tmp/hypervisor && resize &>/dev/null
fi
rm /var/lib/dpkg/lock* &>/dev/null
echo -e "${GREEN}Downloading dependencies for PNETLAB ${NO_COLOR}"
#Deps
apt-get install -y ifupdown unzip resolvconf libnet-pcap-perl duc libspice-client-glib-2.0-8 libtinfo5 libncurses5 libncursesw5 ntpdate vim dos2unix apache2 bridge-utils build-essential cpulimit debconf-utils dialog dmidecode genisoimage iptables lib32gcc1 lib32z1 pastebinit libc6 libc6-i386 libelf1 libpcap0.8 libsdl1.2debian logrotate lsb-release lvm2 ntp rsync sshpass autossh plymouth-label python3-pexpect sqlite3 tcpdump telnet uml-utilities zip libguestfs-tools cgroup-tools libyaml-0-2 net-tools python2 mysql-server libavcodec58 libavformat58 libavutil56 libswscale5 libfreerdp-client2-2 libfreerdp-server2-2 libfreerdp-shadow-subsystem2-2 libfreerdp-shadow2-2 libfreerdp2-2 winpr-utils gir1.2-pango-1.0 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpangoxft-1.0-0 pango1.0-tools pkg-config libssh2-1 libtelnet2 libvncclient1 libvncserver1 libwebsockets15 libpulse0 libpulse-mainloop-glib0 libssl1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libwebp6 libwebpmux3 libwebpdemux2 libcairo2 libcairo-gobject2 libcairo-script-interpreter2 libjpeg62 libpng16-16 libtool libuuid1 libossp-uuid16 default-jdk default-jdk-headless rsync sshpass telnet tomcat9 tomcat9-admin tomcat9-docs libaio1 libasound2 libbrlapi0.7 libcacard0 libepoxy0 libfdt1 libgbm1 libgcc-s1 libglib2.0-0 libgnutls30 libibverbs1 libjpeg8 libncursesw6 libnettle7 libnuma1 libpixman-1-0 libpmem1 librdmacm1 libsasl2-2 libseccomp2 libslirp0 libspice-server1 libtinfo6 libusb-1.0-0 libusbredirparser1 libvirglrenderer1 zlib1g qemu-system-common qemu-system-data ipxe-qemu-256k-compat-efi-roms seabios ipxe-qemu udhcpd busybox libsdl2-2.0-0 libxenmisc4.11 libcapstone3 libvdeplug2 libnfs13 ovmf
# PHP
apt-get install -y php-common php7.2 php7.2-cli php7.2-common php7.2-curl php7.2-gd php-imagick php7.2-json php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-readline php7.2-sqlite3 php7.2-xml php7.2-zip libapache2-mod-php7.2
#Set php7.2 default
update-alternatives --set php /usr/bin/php7.2 &>/dev/null

echo -e "${GREEN}Downloading PNETLAB PACKAGES ...${NO_COLOR}"
cd /tmp
echo -e "${GREEN}$DOwnload Packages${NO_COLOR}"
dpkg-query -l | grep linux-image-5.17.15-pnetlab-uksm-2 | grep 5.17.15-pnetlab-uksm-2-1 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_KERNEL
    unzip /tmp/$KERNEL &>/dev/null
    dpkg -i /tmp/pnetlab_kernel/*.deb
fi

dpkg-query -l | grep docker-ce -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PRE_DOCKER
    unzip /tmp/pre-docker.zip &>/dev/null
    dpkg -i /tmp/pre-docker/*.deb
fi

dpkg-query -l | grep swtpm -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_TPM
    unzip /tmp/swtpm-focal.zip &>/dev/null
    dpkg -i /tmp/swtpm-focal/*.deb
fi

dpkg-query -l | grep pnetlab-docker | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_DOCKER
    dpkg -i /tmp/pnetlab-docker_*.deb
fi

dpkg-query -l | grep pnetlab-schema | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_SCHEMA
    dpkg -i /tmp/pnetlab-schema_*.deb
fi

dpkg-query -l | grep pnetlab-guacamole | grep 6.0.0-7 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_GUACAMOLE
    dpkg -i /tmp/pnetlab-guacamole_*.deb
fi

dpkg-query -l | grep pnetlab-vpcs | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_VPC
    dpkg -i /tmp/pnetlab-vpcs_*.deb
fi

dpkg-query -l | grep pnetlab-dynamips | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_DYNAMIPS
    dpkg -i /tmp/pnetlab-dynamips_*.deb
fi

dpkg-query -l | grep pnetlab-wireshark | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_WIRESHARK
    dpkg -i pnetlab-wireshark_6.0.0-30_amd64.deb
fi

dpkg-query -l | grep pnetlab-qemu | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    wget --content-disposition -q --show-progress $URL_PNET_QEMU
    dpkg -i /tmp/pnetlab-qemu_*.deb
fi
fgrep "127.0.1.1 pnetlab.example.com pnetlab" /etc/hosts || echo 127.0.2.1 pnetlab.example.com pnetlab >>/etc/hosts 2>/dev/null
echo pnetlab >/etc/hostname 2>/dev/null

echo -e "${GREEN}installing pnetlab...${NO_COLOR}"
wget --content-disposition -q --show-progress $URL_PNET_PNETLAB
dpkg -i /tmp/pnetlab_6*.deb

# Detect cloud

gcp_tune() {
    cd /sys/class/net/
    for i in ens*; do echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="'$(cat $i/address)'", ATTR{type}=="1", KERNEL=="ens*", NAME="'$i'"'; done >/etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/NAME="ens.*/NAME="eth0"/' /etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/ens4/eth0/' /etc/netplan/50-cloud-init.yaml
    sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    apt-mark hold linux-image-gcp
    mv /boot/vmlinuz-*gcp /root
    update-grub2
}

azure_kernel_tune() {
    apt update
    echo "options kvm_intel nested=1 vmentry_l1d_flush=never" >/etc/modprobe.d/qemu-system-x86.conf
    sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo -i
}

# GCP
dmidecode -t bios | grep -q Google && gcp_tune

# Azure
uname -a | grep -q -- "-azure " && azure_kernel_tune

apt autoremove -y -q
apt autoclean -y -q
echo -e "${GREEN}Upgrade has been done successfully ${NO_COLOR}"
echo -e "${GREEN}Default credentials: username=root password=pnet Make sure reboot if you install pnetlab first time ${NO_COLOR}"

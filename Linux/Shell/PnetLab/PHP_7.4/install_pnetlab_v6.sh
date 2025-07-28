#!/bin/bash
clear
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# Script designed to upgrade dependencies in PNETLab UBUNTU 20.04
# Requirement: You need to have UBUNTU 20.04

# Constants for colors
GREEN='\033[32m'
RED='\033[31m'
NO_COLOR='\033[0m'

KERNEL=pnetlab_kernel.zip

# Remove any dpkg locks and fix broken installs silently
rm -f /var/lib/dpkg/lock* &>/dev/null
dpkg --configure -a &>/dev/null

# URLs for downloads
URL_KERNEL="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/L/linux-5.17.15-pnetlab-uksm/pnetlab_kernel.zip"
URL_PRE_DOCKER="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/D/pre-docker.zip"
URL_PNET_GUACAMOLE="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_GUACAMOLE/pnetlab-guacamole_6.0.0-7_amd64.deb"
URL_PNET_DYNAMIPS="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_DYNAMIPS/pnetlab-dynamips_6.0.0-30_amd64.deb"
URL_PNET_SCHEMA="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_SCHEMA/pnetlab-schema_6.0.0-30_amd64.deb"
URL_PNET_VPC="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_VPC/pnetlab-vpcs_6.0.0-30_amd64.deb"
URL_PNET_QEMU="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_QEMU/pnetlab-qemu_6.0.0-30_amd64.deb"
URL_PNET_DOCKER="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_DOCKER/pnetlab-docker_6.0.0-30_amd64.deb"
URL_PNET_PNETLAB="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_PNETLAB/pnetlab_6.0.0-103_amd64.deb"
URL_PNET_WIRESHARK="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/P/PNET_WIRESHARK/pnetlab-wireshark_6.0.0-30_amd64.deb"
URL_PNET_TPM="https://labhub.eu.org/api/raw/?path=/upgrades_pnetlab/focal/T/swtpm-focal.zip"

# Check Ubuntu version
if ! lsb_release -r -s | grep -q '^20\.04$'; then
    echo -e "${RED}Upgrade has been rejected. You need to have UBUNTU 20.04 to use this script${NO_COLOR}"
    exit 0
fi

# Function to tune Azure data disk if present
azure_disk_tune() {
    if ls -l /dev/disk/by-id/ | grep -q sdc; then
        (
            echo o # Create a new empty DOS partition table
            echo n # Add a new partition
            echo p # Primary partition
            echo 1 # Partition number
            echo   # First sector (default)
            echo   # Last sector (default)
            echo w # Write changes
        ) | sudo fdisk /dev/sdc

        mke2fs -F /dev/sdc1
        echo "/dev/sdc1	/opt	ext4	defaults,discard	0 0" >> /etc/fstab
        mount /opt
    fi
}

# Detect Azure environment and tune disk
if uname -a | grep -q -- "-azure "; then
    azure_disk_tune
fi

apt-get update

# Permit root login via SSH
sed -i -e "s/^.*PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config &>/dev/null
sed -i -e 's/^.*DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/' /etc/systemd/system.conf &>/dev/null
systemctl restart ssh &>/dev/null

# Add PHP repository quietly
add-apt-repository --yes ppa:ondrej/php &>/dev/null

# Set root password if first time setup
if [ ! -e /opt/ovf/.configured ]; then
    echo "root:pnet" | chpasswd &>/dev/null
fi

# Detect hypervisor and resize root filesystem if needed
systemd-detect-virt -v > /tmp/hypervisor

resize() {
    ROOTLV=$(mount | grep ' / ' | awk '{print $1}')
    lvextend -l +100%FREE "$ROOTLV"
    echo "Resizing ROOT FS"
    resize2fs "$ROOTLV"
}

if fgrep -e kvm -e none /tmp/hypervisor &>/dev/null; then
    grep -q kvm /tmp/hypervisor && resize &>/dev/null
    grep -q none /tmp/hypervisor && resize &>/dev/null
fi

# Purge conflicting packages silently
apt-get purge -y docker.io containerd runc php8* -q &>/dev/null

rm -f /var/lib/dpkg/lock* &>/dev/null

# Install basic dependencies
apt-get install -y ifupdown unzip &>/dev/null

echo -e "${GREEN}Downloading dependencies for PNETLAB${NO_COLOR}"

# Install huge list of packages (kept as is)
sudo apt install -y resolvconf php7.4 php7.4-yaml php7.4-common php7.4-cli php7.4-curl php7.4-gd php7.4-mbstring php7.4-mysql php7.4-sqlite3 php7.4-xml php7.4-zip libapache2-mod-php7.4 libnet-pcap-perl duc libspice-client-glib-2.0-8 libtinfo5 libncurses5 libncursesw5 php-gd ntpdate vim dos2unix apache2 bridge-utils build-essential cpulimit debconf-utils dialog dmidecode genisoimage iptables lib32gcc1 lib32z1 pastebinit php-xml libc6 libc6-i386 libelf1 libpcap0.8 libsdl1.2debian logrotate lsb-release lvm2 ntp php rsync sshpass autossh php-cli php-imagick php-mysql php-sqlite3 plymouth-label python3-pexpect sqlite3 tcpdump telnet uml-utilities zip libguestfs-tools cgroup-tools libyaml-0-2 php-curl php-mbstring net-tools php-zip python2 libapache2-mod-php mysql-server libavcodec58 libavformat58 libavutil56 libswscale5 libfreerdp-client2-2 libfreerdp-server2-2 libfreerdp-shadow-subsystem2-2 libfreerdp-shadow2-2 libfreerdp2-2 winpr-utils gir1.2-pango-1.0 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpangoxft-1.0-0 pango1.0-tools pkg-config libssh2-1 libtelnet2 libvncclient1 libvncserver1 libwebsockets15 libpulse0 libpulse-mainloop-glib0 libssl1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libwebp6 libwebpmux3 libwebpdemux2 libcairo2 libcairo-gobject2 libcairo-script-interpreter2 libjpeg62 libpng16-16 libtool libuuid1 libossp-uuid16 default-jdk default-jdk-headless tomcat9 tomcat9-admin tomcat9-docs libaio1 libasound2 libbrlapi0.7 libcacard0 libepoxy0 libfdt1 libgbm1 libgcc-s1 libglib2.0-0 libgnutls30 libibverbs1 libjpeg8 libncursesw6 libnettle7 libnuma1 libpixman-1-0 libpmem1 librdmacm1 libsasl2-2 libseccomp2 libslirp0 libspice-server1 libtinfo6 libusb-1.0-0 libusbredirparser1 libvirglrenderer1 zlib1g qemu-system-common libxenmisc4.11 libcapstone3 libvdeplug2 libnfs13 udhcpd libxss1 libxencall1 libxendevicemodel1 libxenevtchn1 libxenforeignmemory1 libxengnttab1 libxenstore3.0 libxentoollog1 udhcpd libxss1 libxentoolcore1 libxentoollog1 libxencall1 libxendevicemodel1 libxenevtchn1 libxenmisc4.11 libcapstone3 libvdeplug2 libnfs13 php7.4 php7.4-cli php-common php7.4-curl php7.4-gd php7.4-mbstring php7.4-mysql php7.4-sqlite3 php7.4-xml php7.4-zip libapache2-mod-php7.4

# Ensure correct PHP alternative set
update-alternatives --set php /usr/bin/php &>/dev/null

echo -e "${GREEN}Downloading PNETLAB PACKAGES ...${NO_COLOR}"

rm -rf /tmp/* &>/dev/null
cd /tmp || exit 1

echo -e "${GREEN}Downloading Packages${NO_COLOR}"

# Function to download and install deb packages only if not already installed
install_if_missing() {
    local package_name=$1
    local version_pattern=$2
    local url=$3
    local file_name=$4

    if ! dpkg-query -l | grep -q "${package_name}" | grep -q "${version_pattern}"; then
        wget --content-disposition -q --show-progress "$url"
        if [[ "$file_name" == *.zip ]]; then
            unzip "$file_name" &>/dev/null
            dpkg -i $(dirname "$file_name")/*.deb
        else
            dpkg -i "$file_name"
        fi
    fi
}

# Kernel
if ! dpkg-query -l | grep -q "linux-image-5.17.15-pnetlab-uksm-2" | grep -q "5.17.15-pnetlab-uksm-2-1"; then
    wget --content-disposition -q --show-progress "$URL_KERNEL"
    unzip "/tmp/$KERNEL" &>/dev/null
    dpkg -i /tmp/pnetlab_kernel/*.deb
fi

# Pre-Docker
install_if_missing "docker-ce" "" "$URL_PRE_DOCKER" "/tmp/pre-docker.zip"

# TPM (swtpm)
install_if_missing "swtpm" "" "$URL_PNET_TPM" "/tmp/swtpm-focal.zip"

# PNET Docker
install_if_missing "pnetlab-docker" "6.0.0-30" "$URL_PNET_DOCKER" "/tmp/pnetlab-docker_*.deb"

# PNET Schema
install_if_missing "pnetlab-schema" "6.0.0-30" "$URL_PNET_SCHEMA" "/tmp/pnetlab-schema_*.deb"

# PNET Guacamole
install_if_missing "pnetlab-guacamole" "6.0.0-7" "$URL_PNET_GUACAMOLE" "/tmp/pnetlab-guacamole_*.deb"

# PNET VPC
install_if_missing "pnetlab-vpcs" "6.0.0-30" "$URL_PNET_VPC" "/tmp/pnetlab-vpcs_*.deb"

# PNET Dynamips
install_if_missing "pnetlab-dynamips" "6.0.0-30" "$URL_PNET_DYNAMIPS" "/tmp/pnetlab-dynamips_*.deb"

# PNET Wireshark
install_if_missing "pnetlab-wireshark" "6.0.0-30" "$URL_PNET_WIRESHARK" "/tmp/pnetlab-wireshark_6.0.0-30_amd64.deb"

# PNET QEMU
install_if_missing "pnetlab-qemu" "6.0.0-30" "$URL_PNET_QEMU" "/tmp/pnetlab-qemu_*.deb"

# Update /etc/hosts and hostname
if ! grep -q "127.0.1.1 pnetlab.example.com pnetlab" /etc/hosts; then
    echo "127.0.2.1 pnetlab.example.com pnetlab" >> /etc/hosts 2>/dev/null
fi

echo "pnetlab" > /etc/hostname 2>/dev/null

# Install main pnetlab package
echo -e "${GREEN}Installing pnetlab...${NO_COLOR}"
wget --content-disposition -q --show-progress "$URL_PNET_PNETLAB"
dpkg -i /tmp/pnetlab_6*.deb

# Detect cloud environment tuning functions
gcp_tune() {
    cd /sys/class/net/ || return
    for i in ens*; do
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$(cat $i/address)\", ATTR{type}==\"1\", KERNEL==\"ens*\", NAME=\"$i\""
    done > /etc/udev/rules.d/70-persistent-net.rules

    sed -i -e 's/NAME="ens.*/NAME="eth0"/' /etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/ens4/eth0/' /etc/netplan/50-cloud-init.yaml
    sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    apt-mark hold linux-image-gcp
    mv /boot/vmlinuz-*gcp /root
    update-grub2
}

azure_kernel_tune() {
    apt update
    echo "options kvm_intel nested=1 vmentry_l1d_flush=never" > /etc/modprobe.d/qemu-system-x86.conf
    sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    # sudo -i # commented out since running interactive shell inside script usually not ideal
}

# Detect cloud and apply tuning
if dmidecode -t bios | grep -q Google; then
    gcp_tune
fi

if uname -a | grep -q -- "-azure "; then
    azure_kernel_tune
fi

apt autoremove -y -q
apt autoclean -y -q

echo -e "${GREEN}Upgrade has been done successfully${NO_COLOR}"
echo -e "${GREEN}Default credentials: username=root password=pnet. Make sure to reboot if you install pnetlab for the first time.${NO_COLOR}"

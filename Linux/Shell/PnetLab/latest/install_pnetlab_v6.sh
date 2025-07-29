#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

clear
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NO_COLOR='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NO_COLOR} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NO_COLOR} $*"; }
log_error() { echo -e "${RED}[ERROR]${NO_COLOR} $*"; }

if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root."
    exit 1
fi

log_info "Updating repositories and installing required base packages..."
echo "deb [trusted=yes] https://eduardojonck.com/repo/pnetlab/v6/latest ./" > /etc/apt/sources.list.d/eduardojonck.list
apt-get update -qq
apt-get install -y ifupdown docker-ce unzip resolvconf wget libnet-pcap-perl duc libspice-client-glib-2.0-8 libtinfo5 libncurses5 libncursesw5 ntpdate vim dos2unix apache2 bridge-utils build-essential cpulimit debconf-utils dialog dmidecode genisoimage iptables lib32gcc1 lib32z1 pastebinit libc6 libc6-i386 libelf1 libpcap0.8 libsdl1.2debian logrotate lsb-release lvm2 ntp rsync sshpass autossh plymouth-label python3-pexpect sqlite3 tcpdump telnet uml-utilities zip libguestfs-tools cgroup-tools libyaml-0-2 net-tools python2 mysql-server libavcodec58 libavformat58 libavutil56 libswscale5 libfreerdp-client2-2 libfreerdp-server2-2 libfreerdp-shadow-subsystem2-2 libfreerdp-shadow2-2 libfreerdp2-2 winpr-utils gir1.2-pango-1.0 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpangoxft-1.0-0 pango1.0-tools pkg-config libssh2-1 libtelnet2 libvncclient1 libvncserver1 libwebsockets15 libpulse0 libpulse-mainloop-glib0 libssl1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libwebp6 libwebpmux3 libwebpdemux2 libcairo2 libcairo-gobject2 libcairo-script-interpreter2 libjpeg62 libpng16-16 libtool libuuid1 libossp-uuid16 default-jdk default-jdk-headless tomcat9 tomcat9-admin tomcat9-docs libaio1 libasound2 libbrlapi0.7 libcacard0 libepoxy0 libfdt1 libgbm1 libgcc-s1 libglib2.0-0 libgnutls30 libibverbs1 libjpeg8 libncursesw6 libnettle7 libnuma1 libpixman-1-0 libpmem1 librdmacm1 libsasl2-2 libseccomp2 libslirp0 libspice-server1 libtinfo6 libusb-1.0-0 libusbredirparser1 libvirglrenderer1 zlib1g qemu-system-common libxenmisc4.11 libcapstone3 libvdeplug2 libnfs13 udhcpd libxss1 libxencall1 libxendevicemodel1 libxenevtchn1 libxenforeignmemory1 libxengnttab1 libxenstore3.0 libxentoollog1 libxentoolcore1

log_info "Validating essential commands..."
for cmd in wget unzip dpkg systemctl systemd-detect-virt lvextend resize2fs; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Command '$cmd' not found. Please install it before running this script."
        exit 1
    fi
done

UBUNTU_VERSION=$(lsb_release -r -s)
if [[ "$UBUNTU_VERSION" != "20.04" ]]; then
    log_error "Upgrade denied: This script supports only UBUNTU 20.04."
    exit 1
fi
log_info "Ubuntu version: $UBUNTU_VERSION"

rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock /var/cache/apt/archives/lock
dpkg --configure -a

sed -i -e "s/^#*PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
sed -i -e "s/^#*DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/" /etc/systemd/system.conf
systemctl restart ssh

log_info "Remove old version PHP"
apt purge php* -y

log_info "Installing PHP 7.4 for PNETLAB 6"
echo "deb [trusted=yes] https://eduardojonck.com/repo/pnetlab/v6/latest ./" > /etc/apt/sources.list.d/eduardojonck.list
apt-get install -y \
php7.4 \
php7.4-yaml \
php7.4-common \
php7.4-cli \
php7.4-curl \
php7.4-gd \
php7.4-mbstring \
php7.4-mysql \
php7.4-sqlite3 \
php7.4-xml \
php7.4-zip \
libapache2-mod-php7.4 \
php-gd \
php \
php-cli \
php-imagick \
php-mysql \
php-sqlite3 \
php-xml \
php-curl \
php-mbstring \
php-zip \
php-common
update-alternatives --set php /usr/bin/php7.4 &>/dev/null

if [ ! -e /opt/ovf/.configured ]; then
    echo "root:pnet" | chpasswd
    log_info "Root password set to default 'pnet'"
fi

resize_root_fs() {
    ROOTLV=$(mount | grep ' / ' | awk '{print $1}')
    if [[ "$ROOTLV" =~ ^/dev/mapper/ ]]; then
        log_info "Resizing root logical volume ($ROOTLV)..."
        lvextend -l +100%FREE "$ROOTLV"
        resize2fs "$ROOTLV"
        log_info "Resize complete."
    else
        log_warn "Root volume is not a logical volume. Skipping resize."
    fi
}

HYPERVISOR=$(systemd-detect-virt -v || echo none)
if [[ "$HYPERVISOR" == "kvm" || "$HYPERVISOR" == "none" ]]; then
    resize_root_fs
fi


log_info "Installing main PNETLAB package..."
sudo apt install -y pnetlab-docker pnetlab-dynamips pnetlab-guacamole pnetlab-qemu pnetlab-schema pnetlab-vpcs pnetlab-wireshark pnetlab

if ! grep -q "pnetlab.example.com pnetlab" /etc/hosts; then
    echo "127.0.2.1 pnetlab.example.com pnetlab" >> /etc/hosts
    log_info "Added entry to /etc/hosts"
fi
echo "pnetlab" >/etc/hostname

gcp_tune() {
    log_info "GCP environment detected. Adjusting settings..."
    cd /sys/class/net/
    for i in ens*; do
        echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="'$(cat $i/address)'", ATTR{type}=="1", KERNEL=="ens*", NAME="'$i'"'
    done > /etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/NAME="ens.*/NAME="eth0"/' /etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/ens4/eth0/' /etc/netplan/50-cloud-init.yaml
    sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    apt-mark hold linux-image-gcp
    mv /boot/vmlinuz-*gcp /root || true
    update-grub2
}

azure_kernel_tune() {
    log_info "Azure environment detected. Adjusting settings..."
    apt update
    echo "options kvm_intel nested=1 vmentry_l1d_flush=never" >/etc/modprobe.d/qemu-system-x86.conf
    sed -i -e 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
}

if dmidecode -t bios | grep -q Google; then
    gcp_tune
fi

if uname -a | grep -q -- "-azure "; then
    azure_kernel_tune
fi

log_info "Cleaning up unnecessary packages..."
apt autoremove -y
apt autoclean -y

log_info "Upgrade completed successfully!"
log_info "Default credentials: username=root password=pnet"

if [ ! -e /opt/ovf/.configured ]; then
    log_warn "Reboot required to apply initial changes."
    read -rp "Do you want to reboot now? (y/N): " REBOOT_ANSWER
    if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
        reboot
    else
        log_warn "Please reboot manually later."
    fi
fi

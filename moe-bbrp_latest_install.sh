#!/bin/bash

### Thanks MoeClub for the script

# Check root
[ "$EUID" -ne '0' ] && echo -e "\n\nError: This script must be run as root!\n\n" && exit 1;

# Donwload
## Check latest version
kernel_ver_backup="5.10.30-bbrplus"
kernel_ver=$(wget -qO- "https://github.com/tim1014/MoeBBRplus/tags"|grep "releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/'|sed -r 's/.*tag\/(.+)\">.*/\1/'|grep -o '.*bbrplus')
[[ -z ${kernel_ver} ]] && kernel_ver=${kernel_ver_backup}

headurl="https://github.com/tim1014/MoeBBRplus/releases/download/${kernel_ver}/linux-headers-${kernel_ver}_${kernel_ver}_amd64.deb"
imgurl="https://github.com/tim1014/MoeBBRplus/releases/download/${kernel_ver}/linux-image-${kernel_ver}_${kernel_ver}_amd64.deb"

echo -e "\n\nDownload Header\n\n"
wget --no-check-certificate -qP '/tmp' $headurl
echo -e "\n\nDownload Image\n\n"
wget --no-check-certificate -qP '/tmp' $imgurl

# Install Kernel
dpkg -i "/tmp/linux-headers-${kernel_ver}_${kernel_ver}_amd64.deb"
dpkg -i "/tmp/linux-image-${kernel_ver}_${kernel_ver}_amd64.deb"
[ $? -eq 0 ] || exit 1 

# Update /etc/sysctl.conf
sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
while [ -z "$(sed -n '$p' /etc/sysctl.conf)" ]; do sed -i '$d' /etc/sysctl.conf; done
sed -i '$a\net.core.default_qdisc=fq_pie\nnet.ipv4.tcp_congestion_control=bbrplus\n\n' /etc/sysctl.conf

: << 'COMMENT' # Remove other kernel and update-grub (commented for better compatibility)
img="linux-image-${kernel_ver}"
header="linux-headers-${kernel_ver}"
while true; do
  List_Kernel="$(dpkg -l |grep 'linux-image\|linux-modules\|linux-generic\|linux-headers' |grep -v "${img}\|${header}")"
  Num_Kernel="$(echo "$List_Kernel" |sed '/^$/d' |wc -l)"
  [ "$Num_Kernel" -eq "0" ] && break
  for kernel in `echo "$List_Kernel" |awk '{print $2}'`
    do
      if [ -f "/var/lib/dpkg/info/${kernel}.prerm" ]; then
        sed -i 's/linux-check-removal/#linux-check-removal/' "/var/lib/dpkg/info/${kernel}.prerm"
        sed -i 's/uname -r/echo purge/' "/var/lib/dpkg/info/${kernel}.prerm"
      fi
      dpkg --force-depends --purge "$kernel"
    done
  done
apt-get autoremove -y
COMMENT

echo -e "\n\n\n\nPlease use command: \n\ndpkg -l |grep 'linux-image\|linux-modules\|linux-generic\|linux-headers'\napt purge [kernel/header name] \n\nTo search and manual remove unnecessary kernel. \n\nAfter that please reboot...\n\n\n\n"

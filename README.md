# Create necessary directories
sudo mkdir -p /srv/containers/pihole-pxe/tftpboot/{grub,ubuntu}
sudo mkdir -p /srv/containers/pihole-pxe/tftpboot/pxelinux.cfg

# Download GRUB and PXELINUX files
sudo apt-get install grub-efi-amd64-signed pxelinux syslinux-common

# Copy required files
sudo cp /usr/lib/BOOTX64.EFI /srv/containers/pihole-pxe/tftpboot/
sudo cp /usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed /srv/containers/pihole-pxe/tftpboot/grubx64.efi
sudo cp /usr/lib/syslinux/pxelinux.0 /srv/containers/pihole-pxe/tftpboot/
sudo cp /usr/lib/syslinux/ldlinux.c32 /srv/containers/pihole-pxe/tftpboot/
sudo cp /usr/lib/syslinux/menu.c32 /srv/containers/pihole-pxe/tftpboot/

PXELinux Default Configuration
# /srv/containers/pihole-pxe/tftpboot/pxelinux.cfg/default
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300
ONTIMEOUT ubuntu-live

MENU TITLE PXE Boot Menu

LABEL ubuntu-live
    MENU LABEL Ubuntu 24.04 Live Install
    KERNEL ubuntu/vmlinuz
    APPEND initrd=ubuntu/initrd root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://10.0.0.8/ubuntu/ubuntu-24.04-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://10.0.0.8/cloud-init/ cloud-config-url=/dev/null

    GRUB Configuration
    # /srv/containers/pihole-pxe/tftpboot/grub/grub.cfg
set timeout=5
set default=0

menuentry "Ubuntu 24.04 Live Install" {
    linux /ubuntu/vmlinuz root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://10.0.0.8/ubuntu/ubuntu-24.04-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://10.0.0.8/cloud-init/ cloud-config-url=/dev/null
    initrd /ubuntu/initrd
}

# Create directories for web serving
sudo mkdir -p /srv/containers/pihole-pxe/http/{ubuntu,cloud-init}

# Download Ubuntu 24.04
cd /srv/containers/pihole-pxe/http/ubuntu
sudo wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Mount the ISO and extract kernel and initrd
sudo mkdir /mnt/ubuntu
sudo mount -o loop ubuntu-24.04-live-server-amd64.iso /mnt/ubuntu
sudo cp /mnt/ubuntu/casper/vmlinuz /srv/containers/pihole-pxe/tftpboot/ubuntu/
sudo cp /mnt/ubuntu/casper/initrd /srv/containers/pihole-pxe/tftpboot/ubuntu/
sudo umount /mnt/ubuntu



Cloud-Init Meta-Data Configuration
# /srv/containers/pihole-pxe/http/cloud-init/meta-data
instance-id: ubuntu-server
local-hostname: ubuntu-server

Cloud-Init User-Data Configuration
# /srv/containers/pihole-pxe/http/cloud-init/user-data
#cloud-config
autoinstall:
  version: 1
  locale: Europe/Berlin
  keyboard:
    layout: de
  network:
    network:
      version: 2
      ethernets:
        ens18:
          dhcp4: true
  storage:
    layout:
      name: direct
  identity:
    hostname: ubuntu-server
    username: ubuntu
    password: "$6$examplesalt$fwJX/mNbqXjG4r5zLHjBYzTbJ0IrQxscV3Sup.4HGVBuiETRN3dlVqtFuDWqX2Z8t6UFBl/HWlG7Kr6YdAYLx1" # Password: ubuntu
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - qemu-guest-agent
  user-data:
    disable_root: false
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
    - chmod 440 /target/etc/sudoers.d/ubuntu

Updated Portainer Stack Configuration

version: '3'

services:
  pihole:
    container_name: pihole-pxe
    image: pihole/pihole:latest
    network_mode: host
    environment:
      TZ: 'Europe/Berlin'
      WEBPASSWORD: 'swortfish'
      ServerIP: '10.0.0.8'
      DHCP_ACTIVE: 'true'
      DHCP_START: '10.33.1.50'
      DHCP_END: '10.33.1.200'
      DHCP_ROUTER: '10.0.0.1'
      DHCP_LEASETIME: '24'
    volumes:
      - /srv/containers/pihole-pxe/etc-pihole:/etc/pihole
      - /srv/containers/pihole-pxe/etc-dnsmasq.d:/etc/dnsmasq.d
      - /srv/containers/pihole-pxe/tftpboot:/tftpboot
      - /srv/containers/pihole-pxe/http:/var/www/html
    cap_add:
      - NET_ADMIN
      - NET_RAW
    restart: unless-stopped

  nginx:
    container_name: pxe-nginx
    image: nginx:alpine
    network_mode: host
    volumes:
      - /srv/containers/pihole-pxe/http:/usr/share/nginx/html:ro
    restart: unless-stopped

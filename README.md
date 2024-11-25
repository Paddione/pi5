version: '3'

networks:
  proxy_network:
    external: true
  pxe_network:
    ipam:
      config:
        - subnet: 172.20.0.0/16

services:
  pihole:
    container_name: pihole-pxe
    image: pihole/pihole:latest
    networks:
      - proxy_network
      - pxe_network
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"  # DHCP
      - "69:69/udp"  # TFTP
      - "4011:4011/udp"  # PXE
    environment:
      TZ: 'Europe/Berlin'
      WEBPASSWORD: 'swortfish'
      ServerIP: '10.0.0.8'
      DHCP_ACTIVE: 'true'
      VIRTUAL_HOST: 'pihole.yourdomain.com'
      VIRTUAL_PORT: '80'
    volumes:
      - /srv/containers/pihole-pxe/etc-pihole:/etc/pihole
      - /srv/containers/pihole-pxe/etc-dnsmasq.d:/etc/dnsmasq.d
      - /srv/containers/pihole-pxe/tftpboot:/tftpboot
    cap_add:
      - NET_ADMIN
      - NET_BIND_SERVICE
    restart: unless-stopped

  pxe-web:
    container_name: pxe-web
    image: nginx:alpine
    networks:
      - proxy_network
      - pxe_network
    volumes:
      - /srv/containers/pihole-pxe/http:/usr/share/nginx/html:ro
    environment:
      VIRTUAL_HOST: 'pxe.yourdomain.com'
      VIRTUAL_PORT: '80'
    restart: unless-stopped


  Updated DNSMasq Configuration
# /srv/containers/pihole-pxe/etc-dnsmasq.d/02-dhcp.conf

# Match MAC addresses starting with 12:34:56
dhcp-mac=set:pxeclients,12:34:56:*:*:*

# Define ranges for different client groups
# PXE clients get 10.33.1.x
dhcp-range=tag:pxeclients,10.33.1.50,10.33.1.200,24h

# All other clients get 10.0.1.x
dhcp-range=tag:!pxeclients,10.0.1.50,10.0.1.200,24h

# Common DHCP options for all clients
dhcp-option=option:router,10.0.0.1
dhcp-option=option:dns-server,172.20.0.2  # This should be the Pi-hole container's IP in the pxe_network

# PXE boot configuration
dhcp-boot=tag:pxeclients,pxelinux.0
pxe-service=tag:pxeclients,x86PC,"PXE Boot",pxelinux
pxe-service=tag:pxeclients,BC_EFI,"UEFI Boot",grubx64.efi

# Enable logging for troubleshooting
log-dhcp
log-queries

# Enable TFTP
enable-tftp
tftp-root=/tftpboot

# Set network boot as first option for PXE clients
dhcp-option=tag:pxeclients,vendor:PXEClient,6,1

# Architecture detection
dhcp-match=set:bios,option:client-arch,0
dhcp-match=set:efi64,option:client-arch,7
dhcp-match=set:efi32,option:client-arch,6

# Boot file selection
dhcp-boot=tag:pxeclients,tag:bios,pxelinux.0
dhcp-boot=tag:pxeclients,tag:efi64,grubx64.efi
dhcp-boot=tag:pxeclients,tag:efi32,grubia32.efi
  

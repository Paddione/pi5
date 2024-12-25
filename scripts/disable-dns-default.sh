sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 10.0.0.8" > /etc/resolv.conf'
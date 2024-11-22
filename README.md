# PI5 Infrastructure Configuration

Infrastructure as Code for pi5.korczewski.de provisioning server.

## Components
- Cobbler for PXE boot and system provisioning
- Docker containers for services:
  - Grafana for monitoring
  - Prometheus for metrics
  - Uptime Kuma for status page
  - GitLab Runner for CI/CD
- DNS and DHCP server for network management
- Automated backups to GitHub
- Monitoring and alerting

## Directory Structure
```
.
├── cloud-init/               # Cloud-init configurations
├── docker/                   # Docker compose files and configurations
├── ansible/                  # Ansible playbooks for testing and deployment
├── scripts/                  # Utility scripts
├── configs/                  # Service configurations
│   ├── cobbler/
│   ├── dhcp/
│   ├── dns/
│   └── monitoring/
├── docs/                     # Documentation
└── .github/                  # GitHub Actions workflows
```

## Quick Start
1. Clone repository
2. Set up secrets in GitHub repository
3. Deploy using cloud-init
4. Run initial tests

## Secrets Required
- GITHUB_TOKEN (automatic)
- SSH_PRIVATE_KEY (for server access)
- DOCKER_PASSWORD
- GRAFANA_PASSWORD

## Access URLs
- Grafana: https://grafana.korczewski.de
- Prometheus: https://prometheus.korczewski.de
- Status: https://status.korczewski.de

## Maintenance
- Daily backups
- Automated updates
- Health monitoring

## License
MIT

# Initial Deployment Guide for PI5 Infrastructure

## Prerequisites
1. Raspberry Pi 5 with Ubuntu Server 24.04
2. 128GB USB drive
3. Domain access to korczewski.de
4. Network access to FritzBox

## Pre-Deployment Steps

### 1. DNS Configuration
Add these CNAME records to your domain:
```
cobbler.korczewski.de     -> pi5.korczewski.de
puppet.korczewski.de      -> pi5.korczewski.de
grafana.korczewski.de     -> pi5.korczewski.de
prometheus.korczewski.de  -> pi5.korczewski.de
status.korczewski.de      -> pi5.korczewski.de
```

### 2. Storage Preparation
1. Connect the 128GB USB drive
2. Drive will be automatically partitioned:
   - 40GB for OS images (/var/lib/cobbler/images)
   - 40GB for backups (/var/lib/cobbler/backups)
   - 48GB for logs and data (/var/lib/cobbler/data)

## Deployment Steps

### 1. Initial Server Setup
```bash
# Copy cloud-init configuration
sudo cp cloud-init/base/cloud-init.yaml /etc/cloud/cloud.cfg.d/99_custom.cfg

# Trigger cloud-init
sudo cloud-init clean
sudo cloud-init init
```

### 2. Verify Services
Run the quick test script:
```bash
./scripts/tests/quick-test.sh
```

### 3. Access Points
- Grafana: https://grafana.korczewski.de (admin/swortfish)
- Prometheus: https://prometheus.korczewski.de
- Status Page: https://status.korczewski.de

## Post-Deployment Configuration

### 1. DHCP Setup
The DHCP server is configured to:
- Only respond to MAC addresses starting with BC:24:11
- Assign IPs in range 10.33.1.100 - 10.33.1.200
- Work alongside FritzBox (10.0.0.0/8)

### 2. Adding Custom MAC-IP Pairs
```bash
# Edit DHCP configuration
sudo vim /etc/dhcp/dhcpd.conf

# Add host entry
host custom-host {
    hardware ethernet BC:24:11:XX:XX:XX;
    fixed-address 10.33.1.XXX;
}

# Restart DHCP server
sudo systemctl restart isc-dhcp-server
```

### 3. DynDNS Configuration
DynDNS updates are configured to run every 30 minutes via cron.

## Verification Steps

### 1. System Services
```bash
# Check Docker services
docker ps

# Check DHCP server
systemctl status isc-dhcp-server

# Check DNS server
systemctl status bind9
```

### 2. Network Configuration
```bash
# Test DNS resolution
dig @localhost grafana.korczewski.de

# Test DHCP scope
dhcpd -t -cf /etc/dhcp/dhcpd.conf
```

### 3. Storage Setup
```bash
# Verify mounts
df -h | grep cobbler

# Check permissions
ls -la /var/lib/cobbler/
```

## Troubleshooting

### Common Issues

1. DHCP not assigning IPs:
```bash
# Check DHCP logs
journalctl -u isc-dhcp-server -f

# Verify network interface
ip a
```

2. DNS resolution fails:
```bash
# Check bind9 logs
journalctl -u bind9 -f

# Test local resolution
nslookup grafana.korczewski.de localhost
```

3. Docker containers not starting:
```bash
# Check container logs
docker logs <container_name>

# Check compose logs
docker-compose -f /etc/docker/compose/docker-compose.yml logs
```

### Recovery Steps

1. Service failure:
```bash
# Restart failed service
sudo systemctl restart [service_name]

# Check logs
journalctl -xe
```

2. Storage issues:
```bash
# Remount filesystems
sudo mount -a

# Check filesystem
sudo xfs_repair /dev/sda1  # Be careful with this command
```

## Security Notes

1. Default Credentials:
   - Grafana: admin/swortfish
   - Change these after first login!

2. Firewall Rules:
   - DHCP (67/UDP)
   - DNS (53/TCP+UDP)
   - HTTP(S) (80,443/TCP)
   - Monitoring ports (3000,9090/TCP)

## Maintenance

### Regular Tasks
1. Check logs: `journalctl -f`
2. Monitor disk usage: `df -h`
3. Check service status: `systemctl list-units --state=failed`

### Backup Points
1. Configuration files in /etc
2. Docker volumes
3. DHCP leases
4. DNS zone files

## Support
For issues or questions, create an issue at:
https://github.com/paddione/pi5/issues

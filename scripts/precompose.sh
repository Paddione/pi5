#!/bin/bash


# Create project structure
mkdir -p /home/patrick/pi5/ginxhole/config/{npm,pihole}
mkdir -p /home/patrick/pi5/ginxhole/pihole/etc-dnsmasq.d
mkdir -p config/npm/{data,letsencrypt}

# Create NPM config files
cat > config/npm/production.json << EOL
{
  "database": {
    "engine": "knex-native",
    "knex": {
      "client": "sqlite3",
      "connection": {
        "filename": "/data/database.sqlite"
      }
    }
  }
}
EOL

cat > config/npm/config.json << EOL
{
  "database": {
    "engine": "knex-native",
    "knex": {
      "client": "sqlite3",
      "connection": {
        "filename": "/data/database.sqlite"
      }
    }
  }
}
EOL

# Create Pi-hole config files
cat > config/pihole/setupVars.conf << EOL
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=${SERVER_IP}/24
IPV6_ADDRESS=
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=all
EOL

cat > config/pihole/custom.list << EOL
10.0.0.7 pve.korczewski.de
10.0.0.8 rasp-1.korczewski.de
10.0.0.9 pve2.korczewski.de
10.0.0.10 k3s-node1.korczewski.de
10.0.0.11 k3s-node2.korczewski.de
10.0.0.88 rasp-2.korczewski.de
EOL

cat > config/pihole/dnsmasq.d/02-custom.conf << EOL
address=/pve.korczewski.de/10.0.0.7
address=/rasp-1.korczewski.de/10.0.0.8
address=/pve2.korczewski.de/10.0.0.9
address=/k3s-node1.korczewski.de/10.0.0.10
address=/k3s-node2.korczewski.de/10.0.0.11
address=/rasp-2.korczewski.de/10.0.0.88
EOL

touch config/pihole/pihole-FTL.conf

# Set permissions
chmod -R 755 config/
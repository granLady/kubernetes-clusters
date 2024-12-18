#!/usr/bin/bash

###############################################################
#  TITRE: 
#
#  AUTEUR:   Xavier
#  VERSION: 
#  CREATION:  
#  MODIFIE: 
#
#  DESCRIPTION: 
###############################################################



# Variables ###################################################

VERSION="1.6.1"

# Functions ###################################################


node_exporter_install(){
useradd -rs /bin/false node_exporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz 2>&1 > /dev/null
tar -xzf node_exporter-${VERSION}.linux-amd64.tar.gz  2>&1 > /dev/null
mv node_exporter-${VERSION}.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter
}


node_exporter_systemd(){
echo "
[Unit]
Description=Node Exporter
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/node_exporter.service
}


node_exporter_restart(){
systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
}

# Let's Go !! #################################################

node_exporter_install
node_exporter_systemd
node_exporter_restart

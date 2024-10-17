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

IP_DNS=$(hostname -I | awk '{print $2}')
IP_DNS_REVERSE=$(hostname -I | awk '{print $2}' | awk -F. '{print $3"."$2"."$1}')
IP_RANGE=$(hostname -I | awk '{print $2}' | awk -F. '{print $1"."$2"."$3}')
FILE_REVERSE_ZONE=/etc/bind/zones/${IP_DNS_REVERSE}.in-addr.arpa.zone

# Functions ###################################################



# Let's Go !! #################################################

apt -y install bind9 bind9utils

echo 'RESOLVCONF=no
OPTIONS="-4 -u bind"
' | tee -a /etc/default/named

systemctl restart bind9
systemctl enable bind9

mkdir -p /etc/bind/zones/

echo 'include "/etc/bind/zones.conf";' | tee -a /etc/bind/named.conf

echo '
zone "'${IP_DNS_REVERSE}'.in-addr.arpa" in {
  type master;
  file "'${FILE_REVERSE_ZONE}'";
  zone-statistics yes;
};

zone "xavki" in {
  type master;
  file "/etc/bind/zones/xavki.zone";
  zone-statistics yes;
};
' > /etc/bind/zones.conf

echo '
$TTL 3600
@  IN  SOA     dns.xavki. root.xavki. (
		2023031601  ; serial
		3600        ;Refresh
		1800        ;Retry
		604800      ;Expire
		86400       ;Minimum TTL
)
		IN  NS      dns.xavki.
		IN  A       '${IP_DNS}'
		IN  MX 10   dns.xavki.
' > /etc/bind/zones/xavki.zone

echo 'dns        IN  A       '${IP_DNS} >> /etc/bind/zones/xavki.zone

awk '$1 ~ "192" {print $2"      IN  A      "$1}' /etc/hosts >> /etc/bind/zones/xavki.zone

echo '
$TTL 3600
@   IN  SOA     dns.xavki. root.xavki. (
		2023031601  ;Serial
		3600        ;Refresh
		1800        ;Retry
		604800      ;Expire
		86400       ;Minimum TTL
)
		IN  NS      dns.xavki.

77      IN  PTR     dns.xavki.
81      IN  PTR     kafka4.xavki.
78      IN  PTR     kafka1.xavki.
' > ${FILE_REVERSE_ZONE}

echo '
acl internal-network {
		'${IP_RANGE}'.0/24;
};
' >> /etc/bind/named.conf.options

systemctl restart named

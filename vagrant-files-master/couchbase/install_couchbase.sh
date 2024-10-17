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

set -euxo pipefail


# Variables ###################################################

VERSION="7.0.0"
OS="ubuntu20.04"


# Functions ###################################################

install_repository(){
#curl -fsSL -O https://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-amd64.deb
#sudo dpkg -i couchbase-release-1.0-amd64.deb 2>&1 >/dev/null
#sudo apt update -qq 2>&1 >/dev/null
#wget -q https://packages.couchbase.com/releases/7.0.0/couchbase-server-community_7.0.0-ubuntu20.04_amd64.deb

wget -q https://packages.couchbase.com/releases/${VERSION}/couchbase-server-enterprise_${VERSION}-${OS}_amd64.deb

}

install_prerequisite(){

# Disable THP
sudo /bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
sudo sed -i s/"quiet splash"/"transparent_hugepage=never quiet splash"/g /etc/default/grub
sudo update-grub

# Set swappiness to 0
sudo /bin/bash -c 'echo vm.swappiness = 0 > /etc/sysctl.d/99-sysctl.conf'
sudo sysctl -p
}

install_couchbase(){
#sudo apt install -y -qq couchbase-server 2>&1 >/dev/null
#sudo apt install -y -qq couchbase-server-community 2>&1 >/dev/null
#sudo dpkg -i couchbase-server-community_7.0.0-ubuntu20.04_amd64.deb 2>&1 >/dev/null

sudo dpkg -i couchbase-server-enterprise_${VERSION}-${OS}_amd64.deb 2>&1 >/dev/null

}

initialize_cluster(){
/opt/couchbase/bin/couchbase-cli cluster-init -c couch1 --cluster-username xavki --cluster-password 123456 --services data,query,index,fts
}

join_cluster(){
/opt/couchbase/bin/couchbase-cli server-add -c http://couch1:8091 --username xavki --password 123456 --server-add http://$(hostname -I | awk '{print $2}'):8091 --server-add-username xavki --server-add-password 123456 --services data,query,index,fts
}

run_rebalance(){
/opt/couchbase/bin/couchbase-cli rebalance -c http://couch1:8091 --username xavki --password 123456
}

create_bucket(){
/opt/couchbase/bin/couchbase-cli bucket-create -c http://couch1:8091 --username xavki --password 123456 --bucket xavki --bucket-type couchbase --bucket-ramsize 512
}

create_user(){
/opt/couchbase/bin/couchbase-cli user-manage -c http://couch1:8091 --username xavki --password 123456 --set --rbac-username user1 --rbac-password 123456 --rbac-name "user1" --roles data_reader[xavki],data_writer[xavki],fts_searcher[xavki],fts_admin[xavki],query_delete[xavki],query_insert[xavki],query_select[xavki],query_update[xavki],query_manage_index[xavki] --auth-domain local
}

create_index(){
/opt/couchbase/bin/cbq -u user1 -p 123456 -e "http://couch1:8091" --script "CREATE PRIMARY INDEX ON default:xavki"
}

python_insert(){

sudo apt install -y -qq python3-pip 2>&1 >/dev/null

pip3 install -q testresources couchbase==3.2.0

echo "#!/usr/bin/python3

from couchbase.cluster import Cluster,ClusterOptions
from couchbase.auth import PasswordAuthenticator

cluster = Cluster('couchbase://192.168.16.10:8091',ClusterOptions(
 PasswordAuthenticator('xavki', '123456')))

cb = cluster.bucket('xavki')

print('Insertion début...')

for i in range(1,500000):
  try:
    key = 'doc_' + str(i)
    name = 'name_' + str(i)
    city = 'paris_' + str(i)
    value = {'name': name, 'city': city}
    cb.upsert(key, value)
  except Exception as e:
    print(e)
print('Insertion terminée...')
" >/home/vagrant/insert_couch.py
chmod +x /home/vagrant/insert_couch.py
time /home/vagrant/insert_couch.py

}

# Let's Go !! #################################################

install_repository
install_prerequisite
install_couchbase

sleep 10

if [[ "$1" == "init" ]];then
	sleep 20
  initialize_cluster
  create_bucket
  python_insert
fi

if [[ "$1" == "join" ]];then
  sleep 20
  join_cluster
  sleep 5
  run_rebalance
fi




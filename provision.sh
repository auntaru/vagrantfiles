#!/usr/bin/env sh

set -x
set -e

SERVICE_OPTION=${1:-""}

cat << EOF | sudo tee /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3.10/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum clean all
# MariaDB-10.0
# yum -y install MariaDB-Galera-server MariaDB-client galera
yum -y install mariadb-server galera

cat << EOF | sudo tee /etc/my.cnf.d/server.cnf > /dev/null
[mariadb]
wsrep_provider='/usr/lib64/galera/libgalera_smm.so'
wsrep_cluster_address=gcomm://192.168.33.11,192.168.33.12,192.168.33.13
wsrep_node_address=$(ip -f inet -o addr show | grep 192.168.33. | cut -d "/" -f 1 | awk '{print $NF}')
binlog_format=ROW
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_doublewrite=1
wsrep_on=ON
wsrep_cluster_name="auntaru_mariadb"
log-error = /var/lib/mysql/error.log
EOF

#disable SELINUX
if test `getenforce` = 'Enforcing'; then setenforce 0; fi
sed -Ei 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# systemctl stop firewalld.service
# systemctl disable firewalld.service

# service mysql start ${SERVICE_OPTION}

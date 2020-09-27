#!/bin/bash
sudo su -
# variables
password="Cluster^123"

# mysql installation
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/sysconfig/selinux 
setenforce 0 # I had problems on creation of cluster level because of SELinux

yum install -y wget
wget https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm
yum localinstall -y mysql80-community-release-el8-1.noarch.rpm
yum install -y mysql-server mysql-shell mysql-router  

systemctl enable mysqld
systemctl start mysqld
systemctl status mysqld

yum update -y
yum install -y nmap mc
dnf --enablerepo=HighAvailability -y install pacemaker pcs
systemctl enable --now pcsd
# echo MyStrongPassw0rd | passwd --stdin hacluster
# pcs host auth mysql01 mysql02 mysql03 -u hacluster -p MyStrongPassw0rd


systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld


# cluster configuration
mysql -e "create user 'mycluster' identified by '$password'"
mysql -e "grant all privileges on *.* to 'mycluster'@'%' with grant option"
mysql -e "reset master"

echo "
 192.168.88.22 mysql8-cos8-node1 mysql01 hyperv-primary-cos8
 192.168.88.24 mysql8-cos8-node2 mysql02 hyperv-standby-cos8
 192.168.88.28 mysql8-cos8-node3 mysql03 hyperv-proxy-cos8
" >> /etc/hosts


echo $1

if [ $1 = "primary" ] ; then
    echo " MySQL01 default Primary "
    mysqlsh -e "dba.configureInstance('mycluster@mysql01',{password:'$password',interactive:false,restart:true})"
    sleep 15 # waiting for first instance
    mysqlsh mycluster@mysql01 --password=$password -e "dba.createCluster('mycluster',{ipWhitelist: '192.168.88.22/24'})"
    mysql -e "create user 'mysqlrouter' identified by '$password'"
    echo $password | mysqlrouter --bootstrap mycluster@mysql01 --user=mysqlrouter
    systemctl enable mysqlrouter
    systemctl start mysqlrouter
    systemctl start pcsd.service
    systemctl enable pcsd.service
    echo MyStrongPassw0rd | passwd --stdin hacluster
    pcs host auth mysql01 mysql02 mysql03 -u hacluster -p MyStrongPassw0rd
elif [ $1 = "secondary" ] ; then
    echo " MySQL02 defaut Secondary "
    mysqlsh -e "dba.configureInstance('mycluster@mysql02',{password:'$password',interactive:false,restart:true})"
    sleep 15 # waiting for first instance
    mysqlsh mycluster@mysql01 --password=$password -e "dba.getCluster().addInstance('mycluster@mysql02:3306',{password:'$password',ipWhitelist: '192.168.88.24/24',interactive:false,recoveryMethod:'clone'});"	
    echo $password | mysqlrouter --bootstrap mycluster@mysql01 --user=mysqlrouter
    systemctl enable mysqlrouter
    systemctl start mysqlrouter
    systemctl enable pcsd.service
    systemctl start pcsd.service
    echo MyStrongPassw0rd | passwd --stdin hacluster
    pcs host auth mysql01 mysql02 mysql03 -u hacluster -p MyStrongPassw0rd
else
    echo " MySQL03 default Router "
    mysqlsh -e "dba.configureInstance('mycluster@mysql03',{password:'$password',interactive:false,restart:true})"
    sleep 15 # waiting for first instance
    mysqlsh mycluster@mysql01 --password=$password -e "dba.getCluster().addInstance('mycluster@mysql03:3306',{password:'$password',ipWhitelist: '192.168.88.28/24',interactive:false,recoveryMethod:'clone'});"
    # echo $password | mysqlrouter --bootstrap mycluster@mysql01 --conf-base-port 3306 --user=mysqlrouter
    cat /etc/mysqlrouter/mysqlrouter.conf
    echo $password | mysqlrouter --bootstrap mycluster@mysql01 --user=mysqlrouter
    cat /etc/mysqlrouter/mysqlrouter.conf
    sed -n '/^#/!p' /etc/mysqlrouter/mysqlrouter.conf
    systemctl enable mysqlrouter
    systemctl start mysqlrouter
    tail /var/log/mysqlrouter/mysqlrouter.log
    systemctl enable pcsd.service
    systemctl start pcsd.service
    sleep 15 # waiting for
    echo MyStrongPassw0rd | passwd --stdin hacluster
    pcs host auth mysql01 mysql02 mysql03 -u hacluster -p MyStrongPassw0rd
    sudo pcs cluster setup routercluster mysql01 mysql02 mysql03
    sleep 15 # waiting for
    sudo pcs cluster start --all  
    sleep 15 # waiting for
    sudo crm_mon -1
    sudo pcs property set stonith-enabled=false
    sudo pcs property set no-quorum-policy=ignore
    sudo pcs resource defaults migration-threshold=1
    sudo pcs resource create Router_VIP ocf:heartbeat:IPaddr2 ip=192.168.88.11 cidr_netmask=24 op monitor interval=5s
    crm_mon -1
    sudo pcs resource list | grep router
    sudo pcs resource create mysqlrouter systemd:mysqlrouter clone
    sudo crm_mon -1
    sudo pcs constraint colocation add Router_VIP with mysqlrouter-clone score=INFINITY
    sudo pcs cluster stop --all
    sudo pcs cluster start --all
    sleep 15 # waiting for
    sudo pcs status --full
fi

echo "group_replication_group_seeds = '192.168.88.22:33061,192.168.88.24:33061,192.168.88.28:33061'" >> /etc/my.cnf.d/mysql-server.cnf

ps -ef | grep mysql	
nmap -p- localhost
pcs status --full
pcs config
ip a | grep global
ps -ef | grep pacemaker
mysqlsh -f /tmp/innodb-cluster-status.js


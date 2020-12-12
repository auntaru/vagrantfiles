#!/usr/bin/env sh

# https://www.percona.com/blog/2019/10/11/how-to-set-up-streaming-replication-in-postgresql-12/
# https://www.cybertec-postgresql.com/en/upgrading-and-updating-postgresql/

set -x
set -e

# yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
#dnf install https://download.postgresql.org/pub/repos/yum/9.6/fedora/fedora-31-x86_64/pgdg-fedora-repo-latest.noarch.rpm
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y module disable postgresql
#yum -y install epel-release yum-utils
#yum-config-manager --enable pgdg12
yum-config-manager --enable pgdg96
#yum -y install postgresql12 postgresql12-server postgresql12-contrib mc iproute net-tools
#dnf -y module enable postgresql:9.6
#dnf -y install @postgresql:9.6 
dnf -y install postgresql96 postgresql96-server postgresql96-contrib mc iproute net-tools pgbouncer pgbconsole
#dnf -y install mc iproute net-tools pgbouncer pgbconsole
yum-config-manager --enable pgdg12
yum -y install postgresql12 postgresql12-server postgresql12-contrib

yum clean all
INSTALL_DIR="/data"
mkdir -m a=rwx ${INSTALL_DIR}
chown postgres:postgres ${INSTALL_DIR}

INSTALL_DIR12="/data12"
mkdir -m u=rwx ${INSTALL_DIR12}
chown postgres:postgres ${INSTALL_DIR12}
chmod 700 $INSTALL_DIR
chmod 700 $INSTALL_DIR12


#USER postgres

echo $1 
if [ $1 = "define-primary" ] ; then
    echo " Primary PostgreSQL "
    # su - postgres -c "/usr/pgsql-12/bin/initdb -D /data"
    su - postgres -c '/usr/pgsql-9.6/bin/initdb -D /data'
    # su - postgres -c '/usr/bin/initdb -D /data'
    echo "listen_addresses='*'" >> /data/postgresql.conf
    echo "max_wal_senders = 5" >> /data/postgresql.conf
    echo "wal_keep_segments = 500" >> /data/postgresql.conf
    echo "hot_standby = on" >> /data/postgresql.conf
    echo "wal_level = replica" >> /data/postgresql.conf
    echo "max_wal_size = 1GB" >> /data/postgresql.conf
    echo "host all  all    0.0.0.0/0  trust" >> /data/pg_hba.conf
    echo "host replication replicator 0.0.0.0/0 trust" >> /data/pg_hba.conf
    # su - postgres -c "/usr/pgsql-12/bin/pg_ctl start -D /data" ; 
    # su - postgres -c "/usr/pgsql-12/bin/psql -c 'CREATE USER replicator with REPLICATION'";
    su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl -D /data start";
    # su - postgres -c "/usr/bin/pg_ctl -D /data start";
    su - postgres -c "/usr/pgsql-9.6/bin/psql -c 'CREATE USER replicator with REPLICATION'";
    # su - postgres -c "/usr/bin/psql -c 'CREATE USER replicator with REPLICATION'";
    su - postgres -c "/usr/pgsql-9.6/bin/psql -c 'CREATE USER pgb with SUPERUSER'";    
    #su - postgres -c "/usr/bin/psql -c 'CREATE USER pgb with SUPERUSER'";    
    su - postgres -c "/usr/pgsql-9.6/bin/psql -c 'CREATE database pgb owner pgb'";
    #su - postgres -c "/usr/bin/psql -c 'CREATE database pgb owner pgb'";
    su - postgres -c "/usr/pgsql-9.6/bin/psql -d pgb -c 'CREATE TABLE a AS SELECT id AS a, id AS b, id AS c FROM generate_series(1, 500000) AS id'"
    su - postgres -c "/usr/pgsql-9.6/bin/psql -d pgb -c 'CREATE INDEX idx_a_a ON a (a)'"
    su - postgres -c "/usr/pgsql-9.6/bin/psql -d pgb -c 'CREATE TABLE b AS SELECT * FROM a'"
    su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl -D /data stop"
    su - postgres -c "/usr/pgsql-12/bin/initdb -D /data12"
    su - postgres -c "time /usr/pgsql-12/bin/pg_upgrade -d /data -D /data12 -b /usr/pgsql-9.6/bin -B /usr/pgsql-12/bin "
    echo "listen_addresses='*'" >> /data12/postgresql.conf
    echo "host replication replicator 0.0.0.0/0 trust" >> /data12/pg_hba.conf
    su - postgres -c "/usr/pgsql-12/bin/pg_ctl -D /data12 -o ' -p5433' start"
    su - postgres -c "/usr/pgsql-12/bin/pg_ctl -D /data12 status"
    su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl -D /data start"
    su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl -D /data status"
    netstat -vatn | grep 543
    ps -ef | grep postgres
elif [ $1 = "define-standby" ] ; then
    echo " entered else of if - no replication setup yet "
    chmod 700 $INSTALL_DIR
    chmod 700 $INSTALL_DIR12
    su - postgres -c "/usr/pgsql-9.6/bin/pg_basebackup -h 192.168.44.90 -U replicator --no-password -p 5432 -D $INSTALL_DIR -Fp -Xs -P -R "; 
    sleep 5
    #su - postgres -c "/usr/pgsql-12/bin/initdb -D /data12"
    #su - postgres -c "time /usr/pgsql-12/bin/pg_upgrade -d /data -D /data12 -b /usr/pgsql-9.6/bin -B /usr/pgsql-12/bin "
    su - postgres -c "/usr/pgsql-12/bin/pg_basebackup -h 192.168.44.90 -U replicator --no-password -p 5433 -D $INSTALL_DIR12 -Fp -Xs -P -R "; 
    su - postgres -c "/usr/pgsql-9.6/bin/pg_ctl start -D /data" ;
    # echo "standby_mode = 'on'" > /data12/recovery.conf
    # echo "primary_conninfo = 'user=replicator host=192.168.44.90 port=5433'" >> /data12/recovery.conf
    su - postgres -c "/usr/pgsql-12/bin/pg_ctl -D /data12 -o ' -p5433' start"
    su - postgres -c "/usr/pgsql-12/bin/pg_ctl -D /data12 status"
    netstat -vatn | grep 543
    ps -ef | grep postgres
else
    /usr/bin/pgbouncer -d -u pgbouncer /tmp/pgbouncer.ini
    sleep 5
    netstat -vatn | grep 6432
    /usr/pgsql-9.6/bin/psql -U pgb -h 127.0.0.1 -p 6432 pgb -c "\c";
    /usr/pgsql-9.6/bin/psql -U pgb -h 127.0.0.1 -p 6432 pgb -c "\l+";
    /usr/pgsql-9.6/bin/psql -U pgb -h 127.0.0.1 -p 6432 pgb -c "\dn+";
    /usr/pgsql-9.6/bin/psql -U pgb -h 127.0.0.1 -p 6432 pgb -c "\du+";
    ps -ef | grep pgbounder
fi

# disable SELINUX
if test `getenforce` = 'Enforcing'; then setenforce 0; fi
sed -Ei 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

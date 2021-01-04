#!/usr/bin/env sh

set -x

# https://docs.couchdb.org/en/latest/install/unix.html
# https://www.howtoforge.com/tutorial/how-to-install-apache-couchdb-on-centos-7/
# https://www.tecmint.com/install-apache-couchdb-on-centos-8/
# https://medium.com/@willizoe/installing-apache-couchdb-on-centos-8-a2bfb8e51a74
# https://docs.couchdb.org/en/latest/setup/single-node.html
# https://docs.couchdb.org/en/latest/setup/cluster.html
# https://downloads.apache.org/couchdb/source/
# SSL certificates (HTTPS) in CouchDB: 
# https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=48203146  
#
# A Guide to CouchDB Installation, Configuration and Monitoring
# https://www.monitis.com/blog/a-guide-to-couchdb-installation-configuration-and-monitoring/
# Last updated on 21.03.2019
# 
# https://archive.apache.org/dist/couchdb/source/1.7.2/
# https://archive.apache.org/dist/couchdb/1.2.1/
# https://archive.apache.org/dist/couchdb/releases/1.2.0/apache-couchdb-1.2.0.tar.gz
# https://archive.apache.org/dist/couchdb/notes/1.6.0/apache-couchdb-1.6.0.html

# https://www.cyberciti.biz/faq/add-create-a-sudo-user-on-centos-linux-8/



create_certificates () {
# BEGIN create_certificates
set -x
set -e
#domain=couchdb
#commonname=$domain

#Change to your company details
# country=CH ; state=Zurich ; locality=Zurich ; organization=CLOUD ; organizationalunit=iT; email=admin@cloud.ch
country=RO
state=Europe
locality=TSR
organization=DBA
organizationalunit=CLOUD
commonname=couchdb.eu
email=admin@couchdb.eu

#Optional
#password=Apache.CouchDB.3

# creating SSL certificates

#  commands that require manuaL entry for company details : 
#  sudo openssl genrsa -out /opt/couchdb/couch.key 2048
#  sudo openssl req -new -key /opt/couchdb/couch.key -out /opt/couchdb/couch.csr
#  sudo openssl x509 -req -sha256 -days 1095 -in /opt/couchdb/couch.csr -signkey /opt/couchdb/couch.key -out /opt/couchdb/couch.crt

# SSL with pass + automatic details
#sudo openssl genrsa -passout pass:$password -out /opt/couchdb/couch.key 2048
#sudo openssl req -new -key /opt/couchdb/couch.key -out /opt/couchdb/couch.csr -passin pass:$password -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" 
#sudo openssl x509 -req -sha256 -days 1095 -in /opt/couchdb/couch.csr -signkey /opt/couchdb/couch.key -out /opt/couchdb/couch.crt

sudo openssl genrsa -out /opt/couchdb/couch.key 2048
sudo openssl req -new -key /opt/couchdb/couch.key -out /opt/couchdb/couch.csr -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" 
sudo openssl x509 -req -sha256 -days 1095 -in /opt/couchdb/couch.csr -signkey /opt/couchdb/couch.key -out /opt/couchdb/couch.crt


# adding couchdb user to root group + change password
# In CentOS 8 Linux server all members of the wheel group have sudo access.
sudo usermod -aG wheel couchdb
# adduser -G wheel couchdb
sudo echo -e "couch24\ncouch24" | passwd couchdb
# https://www.systutorials.com/changing-linux-users-password-in-one-command-line/

# assign certificates to couchdb user : 
sudo chown couchdb:couchdb /opt/couchdb/couch.crt
sudo chown couchdb:couchdb /opt/couchdb/couch.key
# END create_certificates
}


movies_restore_bulk_docs () {
# BEGIN restore_bulk_docs
cat > /root/movies.db.dump.json << ENDJSON
{
  "docs": [
    {
      "_id": "_design/sample",
      "views": {
        "actors": {
          "map": "function(doc) { if (doc.actors) { for (i = 0; i < doc.actors.length; i++) { emit([doc.actors[i].first_name, doc.actors[i].last_name], doc.title); } } }"
        },
        "directors": {
          "map": "function(doc) { emit(doc.title, doc.director) }"
        },
        "actorsdirectors": {
          "map": "function(doc) { if (doc.actors) { for (i = 0; i < doc.actors.length; i++) { emit([doc.actors[i].first_name, doc.actors[i].last_name], [ doc.title , doc.director] ); } } }"
        },
        "genrecount": {
          "reduce": "_count",
          "map": "function (doc) { emit(doc.genre, doc.title) ; }"
        },
        "genre": {
          "map": "function (doc) { emit(doc.genre, doc.title) ; }"
        },
        "conflicts": {
          "map": "function (doc) {  if(doc._conflicts) {  emit(doc._conflicts, null); } }"
        }
      },
      "shows": {
        "title": "function(doc, req) { if (doc.title != null) { return '<h1>' + doc.title + '</h1>' } }",
        "detail": "function(doc, req) { var output ; if (doc.title !== null) { output =  '<h1>' + doc.title + '</h1>' ; output += '<p>' + doc.genre + '</p>' ; output += '<p>'  + doc.year    + '</p>' ; output += '<p>'  + doc.country + '</p>' ; output += '<p>'  + ' Director = ' + doc.director.last_name +  ' ' + doc.director.first_name + '</p>' ; output += '<h2>' + doc.summary + '</h2><ul>' ; for(i=0;i<doc.actors.length;i++) { output += '<li>' + doc.actors[i].first_name + ' ' + doc.actors[i].last_name + ' as ' + doc.actors[i].role + '</li>' ; } output += '</ul>' ; return output } }"
      },
      "language": "javascript"
    },
    {
      "_id": "f96b64a80ecaffd8c12dbd4e4f004b74",
      "title": "Spider-Man",
      "year": "2002",
      "genre": "Action",
      "summary": "On a school field trip, Peter Parker (Maguire) is bitten by a genetically modified spider. He wakes up the next morning with incredible powers. After witnessing the death of his uncle (Robertson), Parkers decides to put his new skills to use in order to rid the city of evil, but someone else has other plans. The Green Goblin (Dafoe) sees Spider-Man as a threat and must dispose of him.",
      "country": "USA",
      "director": {
        "last_name": "Raimi",
        "first_name": "Sam",
        "birth_date": "1959"
      },
      "actors": [
        {
          "first_name": "Tobey",
          "last_name": "Maguire",
          "birth_date": "1975",
          "role": "Spider-Man / Peter Parker"
        },
        {
          "first_name": "Kirsten",
          "last_name": "Dunst",
          "birth_date": "1982",
          "role": "Mary Jane Watson"
        },
        {
          "first_name": "Willem",
          "last_name": "Dafoe",
          "birth_date": "1955",
          "role": "Green Goblin / Norman Osborn"
        }
      ]
    },
    {
      "_id": "f96b64a80ecaffd8c12dbd4e4f0088d0",
      "title": "Unforgiven",
      "year": "1992",
      "genre": "Western",
      "summary": "The town of Big Whisky is full of normal people trying to lead quiet lives. Cowboys try to make a living. Sheriff 'Little Bill' tries to build a house and keep a heavy-handed order. The town whores just try to get by.Then a couple of cowboys cut up a whore. Unsatisfied with Bill's justice, the prostitutes put a bounty on the cowboys. The bounty attracts a young gun billing himself as 'The Schofield Kid', and aging killer William Munny. Munny reformed for his young wife, and has been raising crops and two children in peace. But his wife is gone. Farm life is hard. And Munny is no good at it. So he calls his old partner Ned, saddles his ornery nag, and rides off to kill one more time, blurring the lines between heroism and villainy, man and myth.",
      "country": "USA",
      "director": {
        "last_name": "Eastwood",
        "first_name": "Clint",
        "birth_date": "1930"
      },
      "actors": [
        {
          "first_name": "Clint",
          "last_name": "Eastwood",
          "birth_date": "1930",
          "role": "William Munny"
        },
        {
          "first_name": "Gene",
          "last_name": "Hackman",
          "birth_date": "1930",
          "role": "Little Bill Dagget"
        },
        {
          "first_name": "Morgan",
          "last_name": "Freeman",
          "birth_date": "1937",
          "role": "Ned Logan"
        }
      ]
    },
    {
      "_id": "f96b64a80ecaffd8c12dbd4e4f00913b",
      "title": "A History of Violence",
      "year": "2005",
      "genre": "Crime",
      "summary": "Tom Stall, a humble family man and owner of a popular neighborhood restaurant, lives a quiet but fulfilling existence in the Midwest. One night Tom foils a crime at his place of business and, to his chagrin, is plastered all over the news for his heroics. Following this, mysterious people follow the Stalls' every move, concerning Tom more than anyone else. As this situation is confronted, more lurks out over where all these occurrences have stemmed from compromising his marriage, family relationship and the main characters' former relations in the process.",
      "country": "USA",
      "director": {
        "last_name": "Cronenberg",
        "first_name": "David",
        "birth_date": "1943"
      },
      "actors": [
        {
          "first_name": "Ed",
          "last_name": "Harris",
          "birth_date": "1950",
          "role": "Carl Fogarty"
        },
        {
          "first_name": "Vigo",
          "last_name": "Mortensen",
          "birth_date": "1958",
          "role": "Tom Stall"
        },
        {
          "first_name": "Maria",
          "last_name": "Bello",
          "birth_date": "1967",
          "role": "Eddie Stall"
        },
        {
          "first_name": "William",
          "last_name": "Hurt",
          "birth_date": "1950",
          "role": "Richie Cusack"
        }
      ]
    },
    {
      "_id": "f96b64a80ecaffd8c12dbd4e4f0097ad",
      "title": "Marie Antoinette",
      "year": "2006",
      "genre": "Drama",
      "summary": "Based on Antonia Fraser's book about the ill-fated Archduchess of Austria and later Queen of France, 'Marie Antoinette' tells the story of the most misunderstood and abused woman in history, from her birth in Imperial Austria to her later life in France.",
      "country": "USA",
      "director": {
        "last_name": "Coppola",
        "first_name": "Sofia",
        "birth_date": "1971"
      },
      "actors": [
        {
          "first_name": "Kirsten",
          "last_name": "Dunst",
          "birth_date": "1982",
          "role": "Marie Antoinette"
        },
        {
          "first_name": "Jason",
          "last_name": "Schwartzman",
          "birth_date": "1980",
          "role": "Louis XVI"
        }
      ]
    },
    {
      "_id": "f96b64a80ecaffd8c12dbd4e4f00bf3f",
      "title": "The Social network",
      "year": "2010",
      "genre": "Drama",
      "summary": "On a fall night in 2003, Harvard undergrad and computer programming genius Mark Zuckerberg sits down at his computer and heatedly begins working on a new idea. In a fury of blogging and programming, what begins in his dorm room soon becomes a global social network and a revolution in communication. A mere six years and 500 million     friends later, Mark Zuckerberg is the youngest billionaire in history... but for this entrepreneur, success leads to both personal and legal complications.",
      "country": "USA",
      "director": {
        "last_name": "Fincher",
        "first_name": "David",
        "birth_date": "1962"
      },
      "actors": [
        {
          "first_name": "Jesse",
          "last_name": "Eisenberg",
          "birth_date": "1983",
          "role": "Mark Zuckerberg"
        },
        {
          "first_name": "Rooney",
          "last_name": "Mara",
          "birth_date": "1985",
          "role": "Erica Albright"
        },
        {
          "first_name": "Andrew",
          "last_name": "Garfield",
          "birth_date": "1983",
          "role": "Eduardo Saverin"
        },
        {
          "first_name": "Justin",
          "last_name": "Timberlake",
          "birth_date": "1981",
          "role": "Sean Parker"
        }
      ]
    }
  ]
}
ENDJSON

curl -X PUT http://admin:dba@localhost:5984/movies_restored
curl -d @/root/movies.db.dump.json -H "Content-type: application/json" -X POST http://admin:dba@localhost:5984/movies_restored/_bulk_docs

# END restore_bulk_docs
}


#bidirectional_replication () {
# BEGIN bidirectional_replication
#curl -X POST http://admin:dba@192.168.83.86:5984/_node/couchdb@192.168.83.86/_replicate -d '{"source":"http://admin:dba@192.168.83.86:5984/_node/couchdb@172.16.0.90/newdb", "target":"http://admin:dba@192.168.83.89:5984/_node/couchdb@192.168.83.89/newdb","continuous":true}' -H "Content-Type: application/json"
#curl -X POST http://admin:dba@192.168.83.89:5984/_node/couchdb@192.168.83.89/_replicate -d '{"source":"http://admin:dba@192.168.83.89:5984/_node/couchdb@192.168.83.89/newdb", "target":"http://admin:dba@172.16.0.90:5984/_node/couchdb@192.168.83.86/newdb","continuous":true}' -H "Content-Type: application/json"
# END bidirectional_replication
#}

create_cluster () {
# BEGIN create_cluster
# https://docs.couchdb.org/en/latest/setup/cluster.html
# aLL nodes : 
# curl -X POST -H "Content-Type: application/json" http://admin:dba@127.0.0.1:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"dba", "node_count":"2"}'
# 1st node = coordination-node --- To join 1st node to the cluster, run these commands for each node you want to add:  
# curl -X POST -H "Content-Type: application/json" http://admin:password@<setup-coordination-node>:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"atos", "port": 5984, "node_count": "3", "remote_node": "<remote-node-ip>", "remote_current_user": "<remote-node-username>", "remote_current_password": "<remote-node-password>" }'
# curl -X POST -H "Content-Type: application/json" http://admin:password@<setup-coordination-node>:5984/_cluster_setup -d '{"action": "add_node", "host":"<remote-node-ip>", "port": <remote-node-port>, "username": "admin", "password":"password"}'
# Once this is done run the following command to complete the cluster setup and add the system databases:
# curl -X POST -H "Content-Type: application/json" http://admin:password@<setup-coordination-node>:5984/_cluster_setup -d '{"action": "finish_cluster"}'
# Verify install:
# curl http://admin:password@<setup-coordination-node>:5984/_cluster_setup
# Verify all cluster nodes are connected:
# curl http://admin:password@<setup-coordination-node>:5984/_membership
#
curl -X POST -H "Content-Type: application/json" http://admin:dba@192.168.83.86:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"dba", "node_count":"2"}'
curl -X POST -H "Content-Type: application/json" http://admin:dba@192.168.83.89:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"dba", "node_count":"2"}'
curl -X POST -H "Content-Type: application/json" http://admin:dba@192.168.83.86:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"dba", "port": 5984, "node_count": "2", "remote_node": "192.168.83.89", "remote_current_user": "admin", "remote_current_password": "dba" }'
curl -X POST -H "Content-Type: application/json" http://admin:dba@192.168.83.86:5984/_cluster_setup -d '{"action": "add_node", "host":"192.168.83.89", "port": "5984", "username": "admin", "password":"dba"}'
curl -X POST -H "Content-Type: application/json" http://admin:dba@192.168.83.86:5984/_cluster_setup -d '{"action": "finish_cluster"}'

curl -X GET http://admin:atos@localhost:5984/_membership

# END create_cluster
}


#disable SELINUX
if test `getenforce` = 'Enforcing'; then setenforce 0; fi
sed -Ei 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

#stop firewall
systemctl stop firewalld
systemctl disable firewalld
#systemctl status firewalld

# cat << END1 | sudo tee /etc/yum.repos.d/apache-couchdb.repo > /dev/null
cat > /etc/yum.repos.d/apache-couchdb.repo << END1
[bintray--apache-couchdb-rpm]
name=bintray--apache-couchdb-rpm
# baseurl=http://apache.bintray.com/couchdb-rpm/el$releasever/$basearch/
# baseurl=http://apache.bintray.com/couchdb-rpm/el7/x86_64/
baseurl=http://apache.bintray.com/couchdb-rpm/el8/x86_64/
gpgcheck=0
repo_gpgcheck=0
enabled=1
END1

dnf clean packages
# dnf -y update
dnf -y install epel-release 
# dnf makecache
dnf clean packages
dnf -y install yum-utils mc iproute net-tools curl jq
dnf clean packages
dnf -y --enablerepo=bintray--apache-couchdb-rpm clean metadata
# dnf clean packages
# yum clean all
dnf -y install couchdb
# dnf install -y couchdb
# yum -y remove  couchdb-3.1.1
# yum -y install couchdb-3.1.1
# yum -y install couchdb-2.3.1
dnf clean packages

# creating backup of local.ini and default.ini as initially installed 
sed -n '/^;/!p' /opt/couchdb/etc/local.ini
sed -n '/^;/!p' /opt/couchdb/etc/default.ini
# cp /opt/couchdb/etc/local.ini /opt/couchdb/etc/ini.local.ini.bak
# cp /opt/couchdb/etc/default.ini /opt/couchdb/etc/ini.default.ini.bak
# sed -n '/^;/!p' /opt/couchdb/etc/ini.local.ini.bak
# sed -n '/^;/!p' /opt/couchdb/etc/ini.default.ini.bak

# in order to ssh into VM without << vagrnt ssh hostname >> / directly with << ssh ip >> 
# sed -n '/^#/!p' /etc/ssh/sshd_config
# sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# systemctl restart sshd.service

create_certificates

# setting in default.ini : 5984 http access on all interfaces / ips
cat /opt/couchdb/etc/default.ini | grep bind_address
cat /opt/couchdb/etc/default.ini | grep port
# cat /opt/couchdb/etc/local.ini | grep -i UUID

sed -i 's/^;bind_address =.*/bind_address = 0.0.0.0/' /opt/couchdb/etc/default.ini
sed -i 's/^;port =.*/port = 5984/' /opt/couchdb/etc/local.ini

# setting in local.ini : 5984 http access on all interfaces / ips
cat > /opt/couchdb/etc/local.ini << END2

[chttpd]
port = 5984
bind_address = 0.0.0.0

[ssl]
enable = true
cert_file = /opt/couchdb/couch.crt
key_file = /opt/couchdb/couch.key

[admins]
admin = dba
couchdb = couch24

END2

cat /opt/couchdb/etc/local.ini
cat /opt/couchdb/etc/local.ini | grep bind_address
cat /opt/couchdb/etc/local.ini | grep port
cat /opt/couchdb/etc/local.ini | grep admin


# /opt/couchdb/etc/vm.args
cat /opt/couchdb/etc/vm.args | grep name






echo $1
if [ $1 == "define-first" ]
then
    # 192.168.83.86
	cat /opt/couchdb/etc/vm.args | grep name 
	sed -i 's/^-name.*/-name couchdb@192.168.83.86/' /opt/couchdb/etc/vm.args
echo " entered if : define-first "
else
echo " entered else : define-second "
    # 192.168.83.89
	sed -i 's/^-name.*/-name couchdb@192.168.83.89/' /opt/couchdb/etc/vm.args
fi
echo "-kernel inet_dist_listen_min 9100" >>      /opt/couchdb/etc/vm.args
echo "-kernel inet_dist_listen_max 9200" >>      /opt/couchdb/etc/vm.args


# systemctl start couchdb
# systemctl enable couchdb
systemctl enable --now couchdb.service
systemctl status couchdb
netstat -plntu
ps -fu couchdb --forest
# systemctl restart couchdb

#firewall-cmd --add-port=5984/tcp --permanent
#firewall-cmd --reload

sleep 10

# admin:dba
curl -s http://admin:dba@localhost:5984
# curl -s http://admin:dba@localhost:5984 | jq
# curl -X PUT http://localhost:5984/_config/admins/admin -d '"dba"'

# curl -X PUT http:///admin:dba@localhost:5984/_config/admins/newuser -d '"newpass"'
# curl -X PUT http://admin:dba@localhost:5984/_users
# curl -X PUT http://admin:dba@127.0.0.1:5984/_replicator
#curl -X PUT http://admin:dba@localhost:5984/newdb
#curl -X PUT http://admin:dba@localhost:5984/jnosqlfilescanner
curl -X GET http://admin:dba@localhost:5984/_all_dbs

curl -i -k -X GET https://admin:dba@localhost:6984
# curl -k -X GET https://admin:dba@192.168.83.86:6984
# curl -k -X GET https://admin:dba@192.168.83.89:6984
#  curl -k -X GET https://admin:dba@localhost:6984/_membership
#  curl --noproxy "*" -i -k -X GET http://admin:dba@192.168.83.86:5984/_node/couchdb@192.168.83.86/_all_dbs
#  curl --noproxy "*" -i -k -X GET http://admin:dba@192.168.83.86:5984/_node/couchdb@192.168.83.86/_stats


if [ $1 == "define-first" ]
then
    # 192.168.83.86
echo " entered if :  define-first "
else
echo " entered else : define-second - create cluster & restore_db"
    # 192.168.83.89
    create_cluster
    movies_restore_bulk_docs
fi

echo "Complete"


# url -X GET http://admin:dba@localhost:5984/_users/_all_docs?include_docs=true
# less /var/log/couchdb/couchdb.log
# tail /var/log/couchdb/couchdb.log
# tail -f /var/log/couchdb/couchdb.log
 
# https://docs.couchdb.org/en/latest/setup/cluster.html
#
# Create admin user and password:
# curl -s -X PUT http://admin:dba@localhost:5984/_node/_local/_config/admins/atos -d '"atos-hsmdi"'
# curl -s -X PUT http://admin:dba@localhost:5984/_node/_local/_config/admins/user -d '"passwd"'
#
# curl -X PUT http://admin:dba@localhost:5984/jnosqlfilescanner
# 
# bind the clustered interface to all IP addresses availble on this machine
# curl -X PUT http://admin:dba@localhost:5984/_node/_local/_config/chttpd/bind_address -d '"0.0.0.0"'
# 
# get two UUIDs to use later on setup. Be sure to use the SAME UUIDs on all nodes.
# curl http://admin:dba@localhost:5984/_uuids?count=2 
# # result # {"uuids":["FIRST-UUID-GOES-HERE","SECOND-UUID-GOES-HERE"]}
# # result # {"uuids":["53b5aba89eadcac2d6d60b6c190000eb","53b5aba89eadcac2d6d60b6c19000308"]}
# If not using the setup wizard / API endpoint, the following 2 steps are required:
# Set the UUID of the node to the first UUID you previously obtained:
# curl -X PUT http://admin:dba@localhost:5984/_node/_local/_config/couchdb/uuid -d '"FIRST-UUID-GOES-HERE"'
#
# Set the shared http secret for cookie creation to the second UUID:
# curl -X PUT http://admin:dba@localhost:5984/_node/_local/_config/couch_httpd_auth/secret -d '"SECOND-UUID-GOES-HERE"'
#
# Access Apache CouchDB from a web browser
# http://<your-server-ip-address>:5984/_utils/
# http://admin:dba@192.168.83.86:5984/_utils/
# http://admin:dba@192.168.83.89:5984/_utils/
# 
# Access Apache CouchDB version from Linux terminal 
# curl http://admin:dba@192.168.83.89:5984
# curl http://admin:dba@192.168.83.86:5984
# curl -X GET http://admin:dba@192.168.83.89:5984/_users/_all_docs?include_docs=true
#
#   curl -X GET http://admin:dba@192.168.83.89:5984/_all_dbs
#   curl -X GET https://admin:dba@192.168.83.89:5984/_all_dbs
# 

#delete_localhost_node_from_cluster () {
# BEGIN delete_node_from_cluster
# https://docs.couchdb.org/en/latest/cluster/nodes.html#removing-a-node
# curl -X GET http://admin:dba@localhost:5984/_membership
# curl -X GET http://admin:dba@172.16.0.90:5984/_node/_local/_nodes/couchdb@127.0.0.1
### response ### {"_id":"couchdb@127.0.0.1","_rev":"1-967a00dff5e02add41819138abb3284d"}
# curl -X DELETE http://admin:dba@172.16.0.90:5984/_node/_local/_nodes/couchdb@127.0.0.1?rev=1-967a00dff5e02add41819138abb3284d
# curl -X GET http://admin:dba@localhost:5984/_membership
# END delete_node_from_cluster
# }


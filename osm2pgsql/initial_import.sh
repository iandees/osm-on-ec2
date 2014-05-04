#!/bin/bash

# Update apt repo
apt-get update -qq

# Set up raid0 on ephemeral drives
apt-get install -qq -y mdadm xfsprogs
yes | mdadm --create /dev/md0 --level=0 -c256 --raid-devices=2 /dev/xvdb /dev/xvdc
echo 'DEVICE /dev/xvdb /dev/xvdc' > /etc/mdadm.conf
blockdev --setra 65536 /dev/md0
mkfs.xfs -f /dev/md0
mkdir -p /mnt/md0
mount -t xfs -o noatime /dev/md0 /mnt/md0

# Install and configure PostgreSQL and PostGIS
apt-get install -qq -y postgresql-9.3 postgresql-9.3-postgis-2.1
pg_dropcluster --stop 9.3 main
pg_createcluster -d /mnt/md0/postgresql  --start 9.3 main
sudo -u postgres createuser ubuntu
sudo -u postgres createdb -E UTF8 -O ubuntu gis
sudo -u postgres psql -d gis -c 'CREATE EXTENSION postgis;'
sudo -u postgres psql -d gis -c 'CREATE EXTENSION hstore;'
sudo -u postgres psql -d gis -c 'ALTER TABLE geometry_columns OWNER TO ubuntu; ALTER TABLE spatial_ref_sys OWNER TO ubuntu;'
sed -i 's/shared_buffers = 128MB/shared_buffers = 20GB/' /etc/postgresql/9.3/main/postgresql.conf
sed -i 's/#maintenance_work_mem = 16MB/maintenance_work_mem = 40GB/' /etc/postgresql/9.3/main/postgresql.conf
sed -i 's/#autovacuum = on/autovacuum = off/' /etc/postgresql/9.3/main/postgresql.conf
sed -i 's/#checkpoint_segments = 3/checkpoint_segments = 64/' /etc/postgresql/9.3/main/postgresql.conf
service postgresql restart

# Install and configure osm2pgsql
apt-get -qq -y install git autoconf libtool build-essential libxml2-dev libbz2-dev zlib1g-dev libgeos-dev libgeos++-dev libprotobuf-c0-dev protobuf-c-compiler libproj-dev postgresql-server-dev-9.3 lua5.2 liblua5.2-dev
sudo su - ubuntu
mkdir /home/ubuntu/src
cd /home/ubuntu/src
git clone git://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql
./autogen.sh
./configure
make
sudo make install

# Start initial import of planet
curl -s http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf | osm2pgsql --slim -r pbf -d gis -j -C 20000 --number-processes 8 /dev/stdin
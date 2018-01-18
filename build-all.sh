#!/bin/bash
set -e

pushd rpm

# First clear old packages
sudo rm -fr RPMS/*

# First build the package creation containers locally
docker build -t zabbix-rpm:centos5 -f Dockerfile.centos5 .
docker build -t zabbix-rpm:centos6 -f Dockerfile.centos6 .
docker build -t zabbix-rpm:centos7 -f Dockerfile.centos7 .

# Then run the following commands to produce new installation packages for different platforms
docker run --rm -v $(pwd)/RPMS:/usr/src/redhat/RPMS zabbix-rpm:centos5
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos6
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos7

# Modify CentOS 5 package name to include "el5" tag similarly to the others
sudo rename 's/zabbix-agent-pulssi-([0-9.-]+)\.x86_64\.rpm/zabbix-agent-pulssi-$1.el5.x86_64.rpm/' RPMS/x86_64/*.rpm

# Remove "centos" from CentOS 7 package name
sudo rename 's/zabbix-agent-pulssi-([0-9.-]+)\.el7\.centos\.x86_64\.rpm/zabbix-agent-pulssi-$1.el7.x86_64.rpm/' RPMS/x86_64/*.rpm

popd

pushd debian

# First build the package creation containers locally
docker build -t zabbix-deb:debian7 -f Dockerfile.debian7 .
docker build -t zabbix-deb:debian8 -f Dockerfile.debian8 .
docker build -t zabbix-deb:debian9 -f Dockerfile.debian9 .
docker build -t zabbix-deb:debian8docker -f Dockerfile.debian8.docker-host-monitoring .

# Then run the following commands to produce new installation packages for different platforms
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian7
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian8
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian9
docker run --rm -v $(pwd)/DEB:/DEB zabbix-deb:debian8docker

popd


echo "--------------"
echo "BUILD COMPLETE"
echo "--------------"

echo "Upload the following zabbix-agent rpm packages to Github releases:"
ls -la rpm/RPMS/x86_64/zabbix-agent*.rpm
ls -la debian/DEB/zabbix-agent*.deb

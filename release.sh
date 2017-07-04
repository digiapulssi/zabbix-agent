#!/bin/bash
set -e

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
sudo rename 's/zabbix-agent-([0-9.-]+)\.digiapulssi\.x86_64\.rpm/zabbix-agent-$1.digiapulssi.el5.x86_64.rpm/' RPMS/x86_64/*.rpm

# Remove "centos" from CentOS 7 package name
sudo rename 's/zabbix-agent-([0-9.-]+)\.digiapulssi\.el7\.centos\.x86_64\.rpm/zabbix-agent-$1.digiapulssi.el7.x86_64.rpm/' RPMS/x86_64/*.rpm

echo "Upload the following zabbix-agent rpm package to Github releases:"
ls -la RPMS/x86_64/zabbix-agent*.rpm

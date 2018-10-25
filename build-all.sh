#!/bin/bash
set -e

RENAME=rename
if [ -f /etc/redhat-release ]; then
  # We're depending or Perl version of rename that ships by default in Debian-based distros but not in CentOS/Redhat
  RENAME=/usr/local/bin/rename
  if [ ! -f $RENAME ]; then
    sudo yum install perl-CPAN
    sudo cpan<<EOF
      install Module::Build
      install File::Rename
EOF
  fi
fi

pushd rpm

# First clear old packages
sudo rm -fr RPMS/*

# First build the package creation containers locally
#docker build -t zabbix-rpm:centos5 -f Dockerfile.centos5 .
docker build -t zabbix-rpm:centos6 -f Dockerfile.centos6 .
docker build -t zabbix-rpm:centos7 -f Dockerfile.centos7 .

# Download github packages for CentOS 5 build in host, because github requires TLS 1.2 which is not available
# from inside CentOS 5 docker container
#wget -nv -O /tmp/pulssi-3.4.4.tar.gz https://github.com/digiapulssi/zabbix/tarball/pulssi-3.4.4
#wget -O /tmp/zabbix-monitoring-scripts.tar.gz https://github.com/digiapulssi/zabbix-monitoring-scripts/tarball/master

# Run the following commands to produce new installation packages for different platforms
#docker run --rm -v $(pwd)/RPMS:/usr/src/redhat/RPMS -v /tmp/pulssi-3.4.4.tar.gz:/tmp/pulssi-3.4.4.tar.gz:ro -v /tmp/zabbix-monitoring-scripts.tar.gz:/tmp/zabbix-monitoring-scripts.tar.gz:ro zabbix-rpm:centos5
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos6
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos7

# Modify CentOS 5 package name to include "el5" tag similarly to the others
#sudo $RENAME 's/zabbix-agent-pulssi-([0-9.-]+)\.x86_64\.rpm/zabbix-agent-pulssi-$1.el5.x86_64.rpm/' RPMS/x86_64/*.rpm

# Remove "centos" from CentOS 7 package name
sudo $RENAME 's/zabbix-agent-pulssi-([0-9.-]+)\.el7\.centos\.x86_64\.rpm/zabbix-agent-pulssi-$1.el7.x86_64.rpm/' RPMS/x86_64/*.rpm

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

# Overview

Build Digia Pulssi specific Zabbix Agent installation packages. The changes introduced by Pulssi are as follows:

- Use a forked Zabbix agent at https://github.com/digiapulssi/zabbix. The changes in the forked version
  enable new configuration features that allow better control at the monitored host as to the files and
  logs monitored
- Bundle monitoring scripts at https://github.com/digiapulssi/zabbix-monitoring-scripts

# Download

Download the latest installation packages from https://github.com/digiapulssi/zabbix-agent/releases/latest

# Installation and Configuration

Install the RPM package fitting with the following command:

```
yum localinstall zabbix-agent-3.2.3.digiapulssi.elX.x86_64.rpm
(replace X with your CentOS/RedHat/Oracle Linux version number)
```

After installation, you should configure the following sections in /etc/zabbix/zabbix_agentd.conf file.
Find the current configuration lines and replace them as follows:
```
Server=ZABBIX_PROXY_OR_SERVER_ADDRESS
ServerActive=ZABBIX_PROXY_OR_SERVER_ADDRESS
Hostname=
# TBD Check Jenni's email

Optional settings:
LogFileSize=50 (to enable automatic log rotation with 50 MB limit)
```

After configuration, you can start the agent:
```
service zabbix-agent start
```

# Troubleshooting

Zabbix agent log is located by default in /var/log/zabbix/zabbix_agentd.log

Firewall openings can be checked with one of the following tools, depending on your system:
```
10051
telnet ZABBIX_PROXY_OR_SERVER_ADDRESS 10051
nc -zv ZABBIX_PROXY_OR_SERVER_ADDRESS 10051
```

# How to Release a New Version (for Digia Pulssi Developers)

First build the package creation containers:

docker build -t zabbix-rpm:centos5 -f Dockerfile.centos5 .
docker build -t zabbix-rpm:centos6 -f Dockerfile.centos6 .
docker build -t zabbix-rpm:centos7 -f Dockerfile.centos7 .

Then run the following commands to produce new installation packages for different platforms:

docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos5
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos6
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos7

Finally, copy the zabbix-agent rpm packages from RPMS folder to Github releases section.

# Implementation Notes

The packaging has been adapted from the instructions at http://zabbix.org/wiki/Docs/howto/rebuild_rpms

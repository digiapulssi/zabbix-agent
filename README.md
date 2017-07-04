# Overview

Build Digia Pulssi specific Zabbix Agent installation packages. The changes introduced by Pulssi are as follows:

- Use a forked Zabbix agent at https://github.com/digiapulssi/zabbix. The changes in the forked version
  enable new configuration features that allow better control at the monitored host as to the files and
  logs monitored
- Bundle monitoring scripts at https://github.com/digiapulssi/zabbix-monitoring-scripts
- Default configuration does not define hostname but takes it from system hostname
- Default configuration defines Timeout of 15 seconds (instead of default 3 seconds)

# Download

Download the latest installation packages from https://github.com/digiapulssi/zabbix-agent/releases/latest

- CentOS / RedHat / Oracle Linux 5.x: zabbix-agent-VERSION.digiapulssi.el5.x86_64.rpm
- CentOS / RedHat / Oracle Linux 6.x: zabbix-agent-VERSION.digiapulssi.el6.x86_64.rpm
- CentOS / RedHat / Oracle Linux 7.x: zabbix-agent-VERSION.digiapulssi.el7.x86_64.rpm

# Installation and Configuration

Install the RPM package with the following command:

```
yum localinstall zabbix-agent-VERSION.digiapulssi.elVER.x86_64.rpm
```

After installation, you should configure the following sections in /etc/zabbix/zabbix_agentd.conf file.
Find the current configuration lines and replace them as follows:
```
(Under Passive checks related)
Server=ZABBIX_SERVER_SOURCE_ADDRESS1,ZABBIX_SERVER_SOURCE_ADDRESS2

(Under Active checks related)
ServerActive=ZABBIX_SERVER_DEST_ADDRESS
```

In elevated security level systems (Vahti korotettu) you should configure all
the allowed monitored files under AllowedPath setting. The files configured must
not contain sensitive (ST III) information.

```
(Under ADVANCED CONTROL OVER FILES)
AllowedPath=PATH_TO_FILE1
AllowedPath=PATH_TO_FILE2

To allow monitoring of all files under /var/log/example/:
AllowedPath=/var/log/example/.*
```

After configuration, you can start the agent and configure it to auto-start on boot:
```
service zabbix-agent start
chkconfig zabbix-agent on
```

# Upgade over Existing Zabbix Agent Installation

In case you already have the official Zabbix Agent installed on your system,
you should uninstall it before installing digiapulssi version (in order to
get the latest configuration files that will not be installed if there
is an existing version in the system).

```
yum erase zabbix-agent
```

# Troubleshooting

Zabbix agent log is located by default in /var/log/zabbix/zabbix_agentd.log.
Check for the following lines which indicate connection problems:

```
84:20170704:065535.728 active check configuration update from [ZABBIX_SERVER_DEST_ADDRESS:10051] started to fail (cannot connect to [[ZABBIX_SERVER_DEST_ADDRESS]:10051]: [111] Connection refused
```

Firewall openings for active checks can be checked with one of the following tools, depending on your system:
```
telnet ZABBIX_SERVER_DEST_ADDRESS 10051
nc -zv ZABBIX_SERVER_DEST_ADDRESS 10051

# Without any additional tools (from bash):
# The command should run 1-2 seconds and then exit with status code 0.
# If firewall openings are not ok the command runs 1-2 minutes and then prints Connection timed out.
cat < /dev/tcp/ZABBIX_SERVER_DEST_ADDRESS/10051; echo $?
```

# Installation of Custom Monitoring Scripts

Sometimes you need to install custom monitoring scripts to your host.
A custom monitoring script consists of a script file and a configuration files.
Install the files to the following locations:

- Script file: /etc/zabbix/scripts
- Configuration file (something.conf): /etc/zabbix/zabbix-agentd.d/

# How to Release a New Version (for Digia Pulssi Developers)

First build the package creation containers:

docker build -t zabbix-rpm:centos5 -f Dockerfile.centos5 .
docker build -t zabbix-rpm:centos6 -f Dockerfile.centos6 .
docker build -t zabbix-rpm:centos7 -f Dockerfile.centos7 .

Then run the following commands to produce new installation packages for different platforms:

docker run --rm -v $(pwd)/RPMS:/usr/src/redhat/RPMS zabbix-rpm:centos5
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos6
docker run --rm -v $(pwd)/RPMS:/root/rpmbuild/RPMS zabbix-rpm:centos7

Finally, copy the zabbix-agent rpm packages from RPMS folder to Github releases section.

- Note that CentOS 5 package name must be modified to include "el5" tag similarly to the others
- Remove "centos" from CentOS 7 package name

# Implementation Notes

The packaging has been adapted from the instructions at http://zabbix.org/wiki/Docs/howto/rebuild_rpms

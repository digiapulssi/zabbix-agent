# Overview

Build Digia Pulssi specific Zabbix Agent installation packages. The changes introduced by Pulssi are as follows:

- Use a forked Zabbix agent at https://github.com/digiapulssi/zabbix. The changes in the forked version
  enable new security features that allow better control at the monitored host as to the files and
  logs monitored
- Bundle monitoring scripts at https://github.com/digiapulssi/zabbix-monitoring-scripts
- Default configuration does not define hostname but takes it from system hostname
- Default configuration defines Timeout of 15 seconds (instead of default 3 seconds)

# Download

Download the latest installation packages from https://github.com/digiapulssi/zabbix-agent/releases/latest

- CentOS / RedHat / Oracle Linux 5.x: zabbix-agent-pulssi-VERSION.el5.x86_64.rpm
- CentOS / RedHat / Oracle Linux 6.x: zabbix-agent-pulssi-VERSION.el6.x86_64.rpm
- CentOS / RedHat / Oracle Linux 7.x: zabbix-agent-pulssi-VERSION.el7.x86_64.rpm
- Debian 7 (Wheezy): zabbix-agent-pulssi_VERSION.wheezy-1_amd64.deb
- Debian 8 (Jessie): zabbix-agent-pulssi_VERSION.jessie-1_amd64.deb

# Installation and Configuration

### Install over Existing Zabbix Agent Installation

In case you already have the official Zabbix Agent installed on your system,
you should uninstall it before installing digiapulssi version.

```
yum erase zabbix-agent (CentOS / RedHat / Orace Linux)
apt-get purge zabbix-agent (Debian)
```

### Installation on CentOS / RedHat / Oracle Linux

Install the downloaded RPM package with the following command:

```
yum localinstall zabbix-agent-pulssi-VERSION.DISTRIBUTION.x86_64.rpm
(for CentOS/RedHat/Oracle Linux 5.x you need to add --nogpgcheck flag)
```

Make the configuration changes (see below), start the agent and configure it to auto-start on boot:

```
service zabbix-agent start
chkconfig zabbix-agent on
```

### Installation on Debian

Install the downloaded DEB package either with `dpkg -i` or `gdebi` command:

Alternative 1: Use `dpkg -i` and install dependencies manually:
```
dpkg -i zabbix-agent-pulssi_VERSION.DISTRIBUTION-1_amd64.deb
(the command shows missing dependencies as `Package nnn not installed`)
apt-get install --fix-broken
(this will install the missing dependencies and finish zabbix-agent-pulssi package installation)
```

Alternative 2: Use `gdebi` that installs dependencies automatically:

```
apt-get update
apt-get install gdebi
gdebi zabbix-agent-pulssi_VERSION.DISTRIBUTION-1_amd64.deb
```

Make the configuration changes (see below), and restart the agent:

```
service zabbix-agent-pulssi restart
```

### Configuration

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

# Troubleshooting

Zabbix agent log is located by default in /var/log/zabbix/zabbix_agentd.log.
Check for the following lines which indicate connection problems:

```
84:20170704:065535.728 active check configuration update from [ZABBIX_SERVER_DEST_ADDRESS:10051] started to fail (cannot connect to [[ZABBIX_SERVER_DEST_ADDRESS]:10051]: [111] Connection refused
```

The next line indicates that connection works but the host is not yet configured in Digia Pulssi side:
```
64:20170704:071034.703 no active checks on server [ZABBIX_SERVER_DEST_ADDRESS:10051]: host [HOSTNAME] not found
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

Modify the file permissions as follows (the owner should be root):

```
chmod 0755 /etc/zabbix/scripts/SCRIPTNAME
chmod 0644 /etc/zabbix/zabbix-agentd.d/SCRIPTNAME.conf
```

NOTE! Do not leave any backup files etc. under /etc/zabbix/zabbix-agend.d/ because
all the files in the directory are considered as actual configuration files and loaded by Zabbix Agent.

# How to Release a New Version (for Digia Pulssi Developers)

Update PULSSI_RELEASE_VERSION in Dockerfile files (see below).

Run the build script in the repository root directory:

```
./build-all.sh
```

After building the release, create a new release in Github and upload the packages there.

# Implementation Notes

The packaging has been adapted from the instructions at http://zabbix.org/wiki/Docs/howto/rebuild_rpms

# Versioning Practices

Environment variables controlling the versions are defined in Dockerfile.* files.

PULSSI_RELEASE_VERSION environment variable defines Digia Pulssi release/build number
eg. 3.2.3-PULSSI_RELEASE_VERSION.

To release a package based on a newer Zabbix Agent version:

- Update ZABBIX_VERSION
- Set PULSSI_RELEASE_VERSION to 0
- Update URL_ZABBIX_SRPM

To release a newer Digia Pulssi specific Zabbix Agent version using the same Zabbix Agent version than before:

- Increase PULSSI_RELEASE_VERSION by 1

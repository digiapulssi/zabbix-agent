#/bin/bash
set -e

# Run this command only inside docker container with proper environment variables set
# (see usage in Dockerfile.* files)

# Get latest sources from Pulssi repository, including Pulssi changes
BUILDDIR=$(pwd)
wget -nv https://github.com/digiapulssi/zabbix/tarball/branch-$ZABBIX_VERSION
mkdir zabbix-$ZABBIX_VERSION
tar zxf branch-$ZABBIX_VERSION -C zabbix-$ZABBIX_VERSION --strip 1

pushd zabbix-$ZABBIX_VERSION

# Compile tarball so that it's identical to the nightly build
# See: https://www.zabbix.org/wiki/Compilation_instructions

# file paths are so close to 99 long that adding digiapulssi to version number makes them too long with old tar version
./bootstrap.sh
./configure
make dbschema
make css
make gettext
mkdir src/zabbix_java/bin # this is some workaround documented nowhere but necessary for make dist to work...
make dist
popd

# Download and install source package containing Debian packaging sources
mkdir /deb
cd /deb
dget -u "$URL_ZABBIX_DSC"
cd zabbix-$ZABBIX_VERSION

# Update the source package with our latest build

# Get the current version number (like 1:3.2.3-1+wheezy)
# and add digiapulssi to the Release number (like 1:3.2.3-1.X.digiapulssi+wheezy)
#   X ($PULSSI_RELEASE_VERSION) defines Pulssi subversion number in case we want to release
#                               multiple versions of a single Zabbix Agent version&release
CURRENT_VERSION=$(dpkg-parsechangelog | sed -n 's/^Version: //p')
NEW_VERSION=$(echo "$CURRENT_VERSION" | sed -e 's/^\(.*\)+\(.*\)$/\1.'${PULSSI_RELEASE_VERSION}'.digiapulssi+\2/')

uupdate "$BUILDDIR/zabbix-$ZABBIX_VERSION/zabbix-$ZABBIX_VERSION.tar.gz" -v "$NEW_VERSION"
cd ../zabbix-*digiapulssi*

# Default configuration changes
# Do not specify Hostname but use system hostname by default
sed -i '/^Hostname=Zabbix server/d' conf/zabbix_agentd.conf
# Bigger timeout
sed -i '/^# Timeout=3/a Timeout=15' conf/zabbix_agentd.conf

# Get Pulssi monitoring scripts
wget https://github.com/digiapulssi/zabbix-monitoring-scripts/tarball/master
tar --wildcards -zxvf master */scripts --strip 1
tar --wildcards -zxvf master */config --strip 1
rm -f master

##############################################################33
# Monitoring scripts under /etc/zabbix/scripts

echo "etc/zabbix/scripts" >> debian/zabbix-agent.dirs

# Add each script file individually to files section
for scriptpath in scripts/*; do
   scriptfile=$(basename $scriptpath)
   echo "scripts/$scriptfile etc/zabbix/scripts" >> debian/zabbix-agent.install
done

# Executable rights in post-install script
sed -i -e '/configure/a \    chmod 755 /etc/zabbix/scripts/*' debian/zabbix-agent.postinst

##############################################################33
# Monitoring script configuration files under /etc/zabbix/zabbix_agentd.d

# Add each configuration file individually to files section
for confpath in config/*; do
   conffile=$(basename $confpath)
   echo "config/$conffile etc/zabbix/zabbix_agentd.d" >> debian/zabbix-agent.install
done

# Add our packaging modifications in
dpkg-source --commit . digiapulssi-packaging-changes

# Compile sources and make debian package
debuild -us -uc

# Copy debian files under /DEB volume mount
cp ../zabbix-agent*.deb /DEB/

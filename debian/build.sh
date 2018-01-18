#/bin/bash
set -e

# Run this command only inside docker container with proper environment variables set
# (see usage in Dockerfile.* files)

# Get latest sources from Pulssi repository, including Pulssi changes
BUILDDIR=$(pwd)
wget -nv https://github.com/digiapulssi/zabbix/tarball/$ZABBIX_BRANCH
mkdir zabbix-$ZABBIX_VERSION
tar zxf $ZABBIX_BRANCH -C zabbix-$ZABBIX_VERSION --strip 1

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
# and update the Release/build number (like 1:3.2.3-X+wheezy)
CURRENT_VERSION=$(dpkg-parsechangelog | sed -n 's/^Version: //p')
NEW_VERSION=$(echo "$CURRENT_VERSION" | sed -e 's/^\(.*\)-[0-9]\++\(.*\)$/\1-'${PULSSI_RELEASE_VERSION}'+\2/')

UUPDATE_OUT=$(uupdate "$BUILDDIR/zabbix-$ZABBIX_VERSION/zabbix-$ZABBIX_VERSION.tar.gz" -v "$NEW_VERSION")
echo "$UUPDATE_OUT"

# uupdate tells the new directory name in its standard output
#    Do a "cd ../zabbix-3.2.3-1+wheezy" to see the new package
NEW_DIR=$(echo "$UUPDATE_OUT" | sed -n 's/.*Do a "cd \(.*\)" to see the new package/\1/p')
cd "$NEW_DIR"

# Change zabbix-agent package name to zabbix-agent-pulssi
sed -i 's/^Package: zabbix-agent$/Package: zabbix-agent-pulssi/' debian/control
sed -i 's/dh_installinit -p zabbix-agent/dh_installinit -p zabbix-agent-pulssi/' debian/rules
rename 's/zabbix-agent\.(.*)$/zabbix-agent-pulssi.$1/' debian/zabbix-agent.*

# jq as dependency because it's required by docker monitoring script and
# usually by other monitoring scripts too
sed -i 's/^\(Depends: \${shlibs:Depends}, \${misc:Depends}, adduser, lsb-base\)$/\1, jq/' debian/control

# Default configuration changes
# Do not specify Hostname but use system hostname by default
sed -i '/^Hostname=Zabbix server/d' conf/zabbix_agentd.conf
# Bigger timeout
sed -i '/^# Timeout=3/a Timeout=15' conf/zabbix_agentd.conf

# Get Pulssi monitoring scripts
mkdir zabbix-monitoring-scripts
pushd zabbix-monitoring-scripts
wget https://github.com/digiapulssi/zabbix-monitoring-scripts/tarball/master
tar --wildcards -zxvf master */etc/zabbix/scripts --strip 3
tar --wildcards -zxvf master */etc/zabbix/zabbix_agentd.d --strip 3
rm -f master
popd

##############################################################33
# Monitoring scripts under /etc/zabbix/scripts

echo "etc/zabbix/scripts" >> debian/zabbix-agent-pulssi.dirs

# Add each script file individually to files section
for scriptpath in zabbix-monitoring-scripts/scripts/*; do
   scriptfile=$(basename $scriptpath)
   echo "zabbix-monitoring-scripts/scripts/$scriptfile etc/zabbix/scripts" >> debian/zabbix-agent-pulssi.install
done

# Executable rights in post-install script
sed -i -e '/configure/a \    chmod 755 /etc/zabbix/scripts/*' debian/zabbix-agent-pulssi.postinst

##############################################################33
# Monitoring script configuration files under /etc/zabbix/zabbix_agentd.d

# Add each configuration file individually to files section
for confpath in zabbix-monitoring-scripts/zabbix_agentd.d/*; do
   conffile=$(basename $confpath)
   echo "zabbix-monitoring-scripts/zabbix_agentd.d/$conffile etc/zabbix/zabbix_agentd.d" >> debian/zabbix-agent-pulssi.install
done

# Add our packaging modifications in
EDITOR=/bin/true dpkg-source --commit . digiapulssi-packaging-changes

# Compile sources and make debian package
debuild -us -uc

# Copy debian files under /DEB volume mount
cp ../zabbix-agent-pulssi*.deb /DEB/

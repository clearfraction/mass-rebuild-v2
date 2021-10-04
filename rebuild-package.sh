#!/bin/bash
# disable proxy
unset http_proxy
unset no_proxy 
unset https_proxy

# install rpm devtools
cd /home
swupd update --quiet 
swupd bundle-add curl dnf git --quiet 
git clone https://github.com/clearfraction/"$1".git && mv "$1"/* .
# manage dependencies
shopt -s expand_aliases && alias dnf='dnf -q -y --releasever=latest --disableplugin=changelog,needs_restarting'
dnf config-manager --add-repo https://cdn.download.clearlinux.org/current/x86_64/os
dnf groupinstall build srpm-build && dnf install createrepo_c
[ -d "/tmp/repository" ] && createrepo_c --database /tmp/repository && dnf config-manager --add-repo /tmp/repository
dnf builddep *.spec

# build the package
rpmbuild --quiet -bb *.spec --define "_topdir $PWD" \
         --define "_sourcedir $PWD" --undefine=_disable_source_fetch \
         --define "abi_package %{nil}"

# deployment
count=`ls -1 $PWD/RPMS/*/*.rpm 2>/dev/null | wc -l`
if [ $count != 0 ]
then
echo "Start deployment..."
[ ! -d "/tmp/repository" ] && mkdir /tmp/repository
mv $PWD/RPMS/*/*.rpm /tmp/repository
fi 

#!/bin/bash
################################################################################
# Post ini creation script: 
#
# 1/ Copies fio ini files to the shared drive 
# 2/ Creates base directories on the cluster
# 3/ Sets the ACL's
###
SOURCE="$HOME/jobsuite"
DEST="/cygdrive/a/ini"

if [ ! -e  ${DEST} ]
then
	echo "Stage directory does not exist. Making directory"
	mkdir -p ${DEST}
else
	echo "Stage directory ${DEST} exists. Renaming to ${DEST}.$$"
	mv ${DEST} ${DEST}.$$
	mkdir -p ${DEST}
fi
echo "Copying job suite to ${DEST}"
cp -rp ${SOURCE}/* ${DEST}

echo "Staging workers/nodes.conf files"
cp -f ini/*.conf /cygdrive/c/FIO
cp -f ini/*.conf /cygdrive/a/config

echo "Setting windows ACL's on ${DEST}"
getfacl   /cygdrive/c/Users/desktop.ini | setfacl -f - /cygdrive/a/ini/*


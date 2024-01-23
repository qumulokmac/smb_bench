#!/bin/bash

###
# copy results from $HOME/smb_bench/jobsuite to  /cygdrive/a/ini
###
SOURCE="$HOME/jobsuite"
DEST="/cygdrive/a/ini"
DTS=`date +%Y%m%d%H%m%S`
ARCHIVE="/cygdrive/c/FIO/archive"
mkdir -p /cygdrive/a/FIODATA /cygdrive/a/FIO ${ARCHIVE}/${DTS}

if [ ! -e  ${DEST} ]
then
	echo "Stage directory does not exist. Making directory"
	mkdir -p ${DEST}
else
	echo "Stage directory ${DEST} exists. Archiving to ${ARCHIVE}/${DEST}.$$"
	mv ${DEST}/* ${ARCHIVE}/${DTS}
	mkdir -p ${DEST}
fi
echo "Copying job suite to ${DEST}"
cp -rp ${SOURCE}/* ${DEST}

echo "Staging workers/nodes.conf files"
cp -f ini/*.conf /cygdrive/c/FIO
cp -f ini/*.conf /cygdrive/a/config
echo "Setting windows ACL's on ${DEST}"
getfacl   /cygdrive/c/Users/desktop.ini | setfacl -f - /cygdrive/a/ini/*



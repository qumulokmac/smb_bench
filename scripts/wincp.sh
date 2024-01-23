#!/bin/bash

SOURCE="jobsuite"
DEST="/cygdrive/a/ini"
DTS=`date +%Y%m%d%H%m%S`
ARCHIVE="/cygdrive/c/FIO/archive/${DTS}"

mkdir -p /cygdrive/a/FIODATA ${ARCHIVE}

if [ ! -e  ${DEST} ]
then
        echo "Shared directory does not exist. Making directory"
        mkdir -p ${DEST}
else
        echo "Stage directory ${DEST} exists. Archiving to ${ARCHIVE}/${DEST}.$$"
        mv ${DEST} ${ARCHIVE}/${DEST}.$$
        mkdir -p ${DEST}
fi
echo "Copying job suite to ${DEST}"
cp -rp ${SOURCE}/* ${DEST}

echo "Staging workers/nodes.conf files"
cp -f /cygdrive/c/FIO/*.conf /cygdrive/a/config
echo "Setting windows ACL's on ${DEST}"
getfacl   /cygdrive/c/Users/desktop.ini | setfacl -f - /cygdrive/a/ini/*
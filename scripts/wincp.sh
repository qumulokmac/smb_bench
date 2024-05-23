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
        echo "Stage directory ${DEST} exists. Archiving"
		mkdir -p ${ARCHIVE}/ini.$$
		
        mv ${DEST} ${ARCHIVE}/ini.$$
        mkdir -p ${DEST}
fi
echo "Copying job suite to ${DEST}"
cp -rp ${SOURCE}/* ${DEST}

echo "Staging config files"
cp -f /cygdrive/c/FIO/*.{conf,ps1} /cygdrive/a/config
echo "Setting windows ACL's on ${DEST}"
getfacl   /cygdrive/c/Users/desktop.ini | setfacl -f - /cygdrive/a/ini/*

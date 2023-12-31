#!/bin/bash

###
# copy results from $HOME/smb_bench/jobsuite to  /cygdrive/a/ini
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

echo "Setting windows ACL's on ${DEST}"
getfacl   /cygdrive/c/Users/desktop.ini | setfacl -f - /cygdrive/a/ini/*

#!/bin/bash

###
# Wrapping INI's around a wrapper of JPC's to batch smb_bench for numerous FIO configurations
#
# You need to create the template using: 
# "XXX" for the JPC value
# "YYY" for the unique name and ini name 
#
###

TEMPDIR="/tmp/wrapper.$$"
mkdir $TEMPDIR 
for inifile in testconfig-01.ini testconfig-02.ini testconfig-03.ini testconfig-04.ini testconfig-05.ini testconfig-06.ini 
do
	echo "Starting $inifile at: `date`"	
	for JPC in 1 8 16 32 64 96 128 256
	do
	   cd
	   sed -e "s/XXX/${JPC}/g" ${TEMPDIR}/smbbench_config_template.json | sed -e "s/YYY/${inifile}/g" > ${TEMPDIR}/.stub.$JPC.inifile	   	   
	   cp ${TEMPDIR}/.stub.$JPC.inifile ~/ini/smbbench_config.json
	   
	   echo "Starting smb_bench for $inifile with $JPC JPC's"
	   ~/smb_bench.sh
	done
	echo "Finished $inifile at: `date`"	
done

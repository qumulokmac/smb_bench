#!/bin/bash

###
# Wrapping INI's around a wrapper of JPC's
#
# You need to create the template using: 
# "XXX" for the JPC value
# "YYY" for the unique name and ini name 
###

for inifile in smb-seqread-1024f-1mbs-8qd-test1 smb-seqwrite-1024f-1mbs-8qd-test2 smb-randwrite-1024f-64kbs-16qd-test4 smb-randread-1024f-8kbs-32qd-test5 smb-randwrite-1024f-8kbs-32qd-test6 smb-randrw-70mix1024f-8kbs-32qd-test7
do
	echo "Starting $inifile at: `date`"	
	for JPC in 1 8 16 32 64 96 128 256
	do
	   cd
	   sed -e "s/XXX/${JPC}/g" ~/kjmtmp/smbbench_config_template.json | sed -e "s/YYY/${inifile}/g" > ~/kjmtmp/.stub.$JPC.inifile	   	   
	   cp ~/kjmtmp/.stub.$JPC.inifile ~/ini/smbbench_config.json
	   
	   echo "Starting smb_bench for $inifile with $JPC JPC's"
	   ~/smb_bench.sh
	done
	echo "Finished $inifile at: `date`"	
done

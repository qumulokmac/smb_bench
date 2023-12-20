#!/bin/bash

CONFFILE='vm-ip-addresses.conf'

while IFS=: read -r host rip; do
	echo "Name is $host with IP $rip"
	cat RDP.template | sed -e "s/IPADDRESSHERE/$rip/g" > $host.rdp 
done < ${CONFFILE}




Quick instructions on how to make the RDP session files for MacOS

  # Note: The required format is colon dilimited: hostname:ipaddress

1/ Get a list of the worker IP addresses
  WORKER_COMMON_NAME="coop"
  az vm list-ip-addresses | grep $WORKER_COMMON_NAME | sort -Vr  | awk '{print $1 ":" $2}' > vm-ip-addresses.conf

2/ Modify the template file "RDP.template" to suit your needs.  
  - Be sure to replace the IP address in the template file to match: "address:s:IPADDRESSHERE"

3/ Add the vm host:ip pairs to the vm-ip-addresses.conf file

4/ Run the script make-rdp-files.sh

5/ Import the *.rdp files in MacOS Remote Desktop App

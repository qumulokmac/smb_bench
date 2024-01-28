#!/bin/bash
################################################################################
# Script:  setup_smbb_step1_configs.sh
# Date:    Jan 27 2024
# kmac@qumulo.com
#
# Add the names or IP addresses of the workers and ANQ nodes to the
#     workers.conf and nodes.conf respectively
#
# workers.conf: ~/cygdrive/c/FIO/workers.conf
# nodes.conf: ~/cygdrive/c/FIO/nodes.conf
#
# NOTE:  You need to have the Azure CLI configured before running this script!!
#
################################################################################

HOST=`hostname`
if [[ "${HOST}" =~ "maestro" ]]
then
 RESOURCE_GROUP=`echo $HOST | sed -e 's/maestro/rg/g'`
else
  declare -a OPTIONS=()
  declare -a RGS=`az group list -o json | jq '.[] | .name'|sed -e 's/"//g'|sort -n`
  declare -i index=0
  printf "\nPlease select the index for the workers resource group: \n\n"
  for rg in $RGS
  do
        printf "${index}: $rg \n"
        OPTIONS[$index]=$rg
        index=$((index+1))
  done
  echo ""
  printf "   > "
  read answer
  echo ""
  RESOURCE_GROUP=${OPTIONS[$answer]}
fi

az vm list-ip-addresses --resource-group ${RESOURCE_GROUP} --output json | jq '.[] | .virtualMachine.name' | grep -v maestro | sed -e 's/\"//g' > /cygdrive/c/FIO/workers.conf

printf "\n\nThe following entries have been added to the workers.conf file:\n\n"
cat /cygdrive/c/FIO/workers.conf
echo ""

###
# Now nodes.
###
declare -a CLUSTERS=`az resource list --resource-type "Qumulo.Storage/fileSystems" -o json  | jq -r '.[] | .name'`
declare -a OPTIONS=()
declare -i index=0
printf "\nPlease select the cluster: \n\n"
for cluster in $CLUSTERS
do
        printf "${index}: $cluster \n"
        OPTIONS[$index]=$cluster
        index=$((index+1))
done
echo ""
printf "   > "
read answer
echo ""
ANQ_CLUSTER=${OPTIONS[$answer]}

az network nic list -o json | jq --arg name "${ANQ_CLUSTER}" '.[] | select(.name | startswith($name)).ipConfigurations[0].privateIPAddress' | sed -e 's/\"//g' > /cygdrive/c/FIO/nodes.conf

printf "\n\nThe following entries have been added to the nodes.conf file for cluster ${ANQ_CLUSTER}:\n\n"
cat /cygdrive/c/FIO/nodes.conf
echo ""


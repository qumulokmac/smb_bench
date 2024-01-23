#!/bin/bash 
################################################################################
#
# smb_bench.sh
#
# Author:	kmac@qumulo.com
# Date:		12/15/2023
#
# SMB Bench script to create the config files for all workers, distribute them, 
#	and launch the powershell script that launches FIO on all of the worker hosts.
#
################################################################################

#######################################################################################
# User modifiable config fields are now in the ini/smbbench_config.json file
#######################################################################################

CONFIGFILE='ini/smbbench_config.json'
if [ ! -e $CONFIGFILE ] 
then
	echo "SMB Bench config file $CONFIGFILE does not exist."
	exit -1
else
	result=$(jq -r '.smbbench_settings[] | select(.type == "cygwin" or .type == "global") | "\(.name)=\(.value)"' ini/smbbench_config.json)
	eval "$result"
fi

if [[ $UNIQUE_RUN_IDENTIFIER == "" ]]
then
	echo "UNIQUE_RUN_IDENTIFIER not set.  Check $CONFIGFILE"
	exit -2
fi

if [[ ! -e $FIO_TEMPLATE ]]
then
	echo "The FIO Tamplate file $FIO_TEMPLATE does not exist"
	exit -3
fi

DTS=`date +%Y%m%d%H%m%S` 
WORKERS_CONF="ini/workers.conf"
NODES_CONF="ini/nodes.conf"
JOBSUITEDIR="jobsuite"
POSTSCRIPT="${HOME}/scripts/wincp.sh"
MYRND=`date +%Y%m%d%H%m%S`-${DTS}
SUFFIX=`echo $FIO_TEMPLATE | sed -e 's|ini/||g'`
SUITENAME=`echo $FIO_TEMPLATE | sed -e 's|ini\/||g' | sed -e 's/\.ini//g'`
RESULTDIR="/cygdrive/a/results"
ARCHIVE="${HOME}/._archive"

#############################

echo ""
echo "This will create FIO job files with the following settings: "
echo ""
cat $FIO_TEMPLATE

echo ""
echo "MOUNTS_PER_CLIENT: $MOUNTS_PER_CLIENT"
echo "JOBS_PER_CLIENT: $JOBS_PER_CLIENT"
echo "Number of worker hosts: `wc -l $WORKERS_CONF`"
echo ""
echo "Mounted drives: `df -h`"
echo "Worker hosts: 	`wc -l $WORKERS_CONF`"
echo "Proceed? [y|n]"
read answer
answer='y'
case $answer in

	[yY] | [yY][Ee][Ss]	)
	echo "$0 starting at `date`"   
	echo ""
	;;

    [nN] | [n|N][O|o] )	
	echo "Canceling per user request" 
	exit 0 
    ;;

  *)
    echo "Hugh?: $answer"
    exit 1
    ;;
esac

declare -a HOSTS=(`cat $WORKERS_CONF`)
declare -a NODES=(`cat $NODES_CONF`)

echo ""
echo "Validating worker hosts network connectivity..."
echo ""

for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))
do
  ping -n 2 "${HOSTS[$hostindex]}" >/dev/null
  if [ $? -ne 0 ]
  then
    echo "Worker host ${HOSTS[$hostindex]} is not pingable, please investigate"
    exit 1
  fi
done

echo ""
echo "Worker hosts are all responging, checking nodes..."
echo ""

for (( nodeindex=0; nodeindex<${#NODES[@]}; nodeindex++ ))
do
  ping -n 2 ${NODES[$nodeindex]} >/dev/null
  if [ $? -ne 0 ]
  then
    echo "NODE ${NODES[$nodeindex]} is not pingable, please investigate"
    exit 1
  fi
done

if [ -e $JOBSUITEDIR ]
then
	RENAMETO="${ARCHIVE}/${JOBSUITEDIR}.${MYRND}"
	echo "Output directory $JOBSUITEDIR exists. Renaming to $RENAMETO"
	mv  $JOBSUITEDIR $RENAMETO
fi

echo ""
echo "Checking that the result directory ($RESULTDIR) is available..."
if [ -e $RESULTDIR ]
then
	echo "Prior results directory $RESULTDIR exists, renaming to $RESULTDIR.${MYRND}"
	mv $RESULTDIR $RESULTDIR.${MYRND}
	mkdir -p ${RESULTDIR}
else
	mkdir -p ${RESULTDIR}
fi

if [[ ! -e "/cygdrive/a/FIODATA" ]]
then
	mkdir -p /cygdrive/a/config /cygdrive/a/FIODATA
	cp ${WORKERS_CONF} /cygdrive/a/config
fi

for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))
do 
  echo "${HOSTS[$hostindex]}"
  mkdir -p "/cygdrive/a/FIODATA/${HOSTS[$hostindex]}"	${JOBSUITEDIR}

	FIO_RESULTS_FILE="${HOSTS[$hostindex]}_${UNIQUE_RUN_IDENTIFIER}_smbbench-results.json"
	FIO_INI_FILENAME="${HOSTS[$hostindex]}_${UNIQUE_RUN_IDENTIFIER}_smbbench.ini"
	
	cp -p ${FIO_TEMPLATE} "${JOBSUITEDIR}/${FIO_INI_FILENAME}"
	cp -p scripts/workerScript.ps1 /cygdrive/a/config/
	
	DLCOUNT=0
	for (( jobid=0; jobid<$JOBS_PER_CLIENT; jobid++ ))
	do
		if [[ $DLCOUNT == $(($MOUNTS_PER_CLIENT-1)) ]]
		then
		  DLCOUNT=0
		else
		  DLCOUNT=$((DLCOUNT+1))
		fi
		DRIVE_LETTER=`echo $((DLCOUNT+70))| awk '{printf("%c",$1)}'`
		echo "[job${jobid}]" >> "${JOBSUITEDIR}/${FIO_INI_FILENAME}"
		echo "directory=${DRIVE_LETTER}\\:FIODATA\\${HOSTS[$hostindex]}"  >> "${JOBSUITEDIR}/${FIO_INI_FILENAME}"
		echo "numjobs=1"  >> "${JOBSUITEDIR}/${FIO_INI_FILENAME}"
		echo ""  >> "${JOBSUITEDIR}/${FIO_INI_FILENAME}"
	done
  done
echo ""

if [ -e ${POSTSCRIPT} ]
then
	echo "Running post script $POSTSCRIPT"
	eval bash ${POSTSCRIPT}
fi

powershell ./scripts/run_smbbench.ps1

echo "$0 finished at `date`"
echo ""
exit $?

#!/bin/bash 
################################################################################
#
# make-fiojobs-one-fio.sh
#
# Author:	kmac@qumulo.com
# Date:		12/15/2023
#
# Wrapper script to create batch and FIO ini files
#
################################################################################

#############################
# Configurable variables
#############################

MOUNTS_PER_CLIENT=16
FIO_NUM_JOBS=256
WORKERS_CONF="ini/workers.conf"
FIO_TEMPLATE="ini/randrw-50rwmix-20KBbs.ini"
JOBSUITEDIR="jobsuite"
POSTSCRIPT="${HOME}/scripts/wincp.sh"
MYRND="$$$RANDOM"
SUFFIX=`echo $FIO_TEMPLATE | sed -e 's|ini/||g'`
SUITENAME=`echo $FIO_TEMPLATE | sed -e 's|ini\/||g' | sed -e 's/\.ini//g'`
RESULTDIR="/cygdrive/a/results"
UNIQUE_RUN_IDENTIFIER="mrcooper"
###
# Note: The UNIQUE_RUN_IDENTIFIER should match the same variable name used in the powershell script
###

#############################

echo ""
echo "This will create FIO job files with the following settings: "
echo ""
cat $FIO_TEMPLATE

echo ""
echo "MOUNTS_PER_CLIENT: $MOUNTS_PER_CLIENT"
echo "FIO_NUM_JOBS: $FIO_NUM_JOBS"
echo "Number of worker hosts: `wc -l $WORKERS_CONF`"
echo ""
echo "Mounted drives: `df -h`"
echo "Worker hosts: 	`wc -l $WORKERS_CONF`"
echo "Proceed? [y|n]"
read answer
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
	#exit 1
    ;;
esac

if [ -e $JOBSUITEDIR ]
then
	RENAMETO="$JOBSUITEDIR.${MYRND}"
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

DTS=`date +%Y%m%d%H%m%S` 
declare -a HOSTS=(`cat $WORKERS_CONF`)

for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))
do 
    echo "${HOSTS[$hostindex]}"
  	mkdir -p /cygdrive/a/FIODATA/${HOSTS[$hostindex]}

	BASEDIR="${JOBSUITEDIR}"
	mkdir -p $BASEDIR

	FIO_RESULTS_FILE="${HOSTS[$hostindex]}_${UNIQUE_RUN_IDENTIFIER}_smbbench-results.json"
	FIO_INI_FILENAME="${HOSTS[$hostindex]}_${UNIQUE_RUN_IDENTIFIER}_smbbench.ini"
	cp -p ${FIO_TEMPLATE} "${BASEDIR}/${FIO_INI_FILENAME}"

	DLCOUNT=0
	for (( jobid=0; jobid<$FIO_NUM_JOBS; jobid++ ))
	do
		if [[ $DLCOUNT == $(($MOUNTS_PER_CLIENT-1)) ]]
		then
		  DLCOUNT=0
		else
		  DLCOUNT=$((DLCOUNT+1))
		fi
		DRIVE_LETTER=`echo $((DLCOUNT+70))| awk '{printf("%c",$1)}'`
		echo "[job${jobid}]" >> "${BASEDIR}/${FIO_INI_FILENAME}"
		echo "directory=${DRIVE_LETTER}\\:FIODATA\\${HOSTS[$hostindex]}"  >> "${BASEDIR}/${FIO_INI_FILENAME}"
		echo "numjobs=1"  >> "${BASEDIR}/${FIO_INI_FILENAME}"
		echo ""  >> "${BASEDIR}/${FIO_INI_FILENAME}"
	done
  done
echo ""

if [ -e ${POSTSCRIPT} ]
then
	echo "Running post script $POSTSCRIPT"
	eval bash ${POSTSCRIPT}
fi

echo "$0 finished at `date`"
echo ""
exit $?

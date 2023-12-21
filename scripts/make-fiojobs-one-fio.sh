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

MOUNTS_PER_CLIENT=14
JOBS_PER_CLIENT=16
WORKERS_CONF="ini/workers.conf"
FIO_TEMPLATE="ini/mrcoop-randrw-50rwmix.ini"
JOBSUITEDIR="jobsuite"
POSTSCRIPT="${HOME}/scripts/wincp.sh"
MYRND="$$$RANDOM"
SUFFIX=`echo $FIO_TEMPLATE | sed -e 's|ini/||g'`
SUITENAME=`echo $FIO_TEMPLATE | sed -e 's|ini\/||g' | sed -e 's/\.ini//g'`
RESULTDIR="F:\results\\$SUITENAME-JPC_${JOBS_PER_CLIENT}-MPC_${MOUNTS_PER_CLIENT}"


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
DTS=`date +%Y%m%d%H%m%S` 
declare -a HOSTS=(`cat $WORKERS_CONF`)

for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))
do 
  echo -n "${HOSTS[$hostindex]}"
  FILECONST="${HOSTS[$hostindex]}-${DTS}-${JOBS_PER_CLIENT}-JPC"
	BASEDIR="${JOBSUITEDIR}/${HOSTS[$hostindex]}"
	mkdir -p $BASEDIR
	FIO_LOGFILE="fiolog-${FILECONST}-${JOBS_PER_CLIENT}.json"
	WIN_BATCH_FILE="fiorun-${FILECONST}-${JOBS_PER_CLIENT}.bat"
	FIO_INI_FILENAME="fioini-${FILECONST}-${JOBS_PER_CLIENT}-${SUFFIX}"
	cp -p ${FIO_TEMPLATE} "${BASEDIR}/${FIO_INI_FILENAME}"

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
		# echo "DRIVE_LETTER is $DRIVE_LETTER"
		echo "[job${jobid}]" >> "${BASEDIR}/${FIO_INI_FILENAME}"
		echo "directory=${DRIVE_LETTER}\\:FIODATA\\${HOSTS[$hostindex]}"  >> "${BASEDIR}/${FIO_INI_FILENAME}"
		echo "numjobs=1"  >> "${BASEDIR}/${FIO_INI_FILENAME}"
		echo ""  >> "${BASEDIR}/${FIO_INI_FILENAME}"
	done

	echo "REM Batch File $WIN_BATCH_FILE " >> "${BASEDIR}/${WIN_BATCH_FILE}"
	echo "" >> "${BASEDIR}/${WIN_BATCH_FILE}"
	
	echo "if not exist \"F:\FIODATA\\${HOSTS[$hostindex]}\"  MKDIR \"F:\FIODATA\\${HOSTS[$hostindex]}\" " >> "${BASEDIR}/${WIN_BATCH_FILE}"
	
	
    # echo "MKDIR F:\FIODATA\\${HOSTS[$hostindex]} "  >> "${BASEDIR}/${WIN_BATCH_FILE}"
	echo -n "C:\\fio\\fio-master\\fio --thread --output-format=json --output=${RESULTDIR}\\"  >> "${BASEDIR}/${WIN_BATCH_FILE}"
	echo "${FIO_LOGFILE} C:\\FIO\\${FIO_INI_FILENAME}" >> "${BASEDIR}/${WIN_BATCH_FILE}"
	echo -n "."
	echo ""
done
echo ""

###
# Create the Powershell script to spawn all of the FIO jobs for a given host
###
echo "Creating powershell spawn scripts"
for (( hostindex=0; hostindex<${#HOSTS[@]}; hostindex++ ))  
do 
  BASEDIR="${JOBSUITEDIR}/${HOSTS[$hostindex]}"
  SPAWNFILE="${BASEDIR}/spawn-fio-procs-${HOSTS[$hostindex]}.ps1"  
  echo '$batchScripts = @(' >>${SPAWNFILE}
  
  declare -i count=1
  for file in `ls -1 ${BASEDIR}/fiorun-*.bat | sort -V` 
  do
    file=`echo $file | sed -e "s|$BASEDIR\/||g" `
    # echo "Adding bat script $file to ${SPAWNFILE}"
    echo -n "\"C:\FIO\\$file\""  >>${SPAWNFILE}
	echo ')'  >>${SPAWNFILE}
    count=$((count+1))
  done
  cat >> "${SPAWNFILE}" <<EOFF

\$jobs = @()
foreach (\$scriptPath in \$batchScripts) {
    \$job = Start-Job -ScriptBlock {
        param(\$scriptPath)
        & \$scriptPath
    } -ArgumentList \$scriptPath
    \$jobs += \$job
}

Wait-Job -Job \$jobs
 
\$results = Receive-Job -Job \$jobs

foreach (\$result in \$results) {
    Write-Output "Job Result: \$result"
}

Remove-Job -Job \$jobs 

EOFF

done

if [ -e ${POSTSCRIPT} ]
then
	echo "Running post script $POSTSCRIPT"
	eval bash ${POSTSCRIPT}
fi

echo "$0 finished at `date`"
echo ""
exit $?

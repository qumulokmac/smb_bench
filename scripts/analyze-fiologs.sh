#!/bin/bash 
################################################################################
# Name:  	analyze-fiologs.sh
# Descr:	Script to parse a directory of FIO json logs and report on aggregated IOPS/BW/Lat
# Author: 	kmac@qumulo.com
# Date:		12/20/2023
#
# Usage:	analyze-fiologs.sh directory
#		- The directory should contain nothing but FIO json output
#
################################################################################
DIRECTORY=$1 
if [ -z $DIRECTORY ]
then
  echo "Usage: $0 directory"
  exit 5
fi

declare TOTAL_READ_IOPS=0
declare TOTAL_WRITE_IOPS=0
declare TOTAL_WRITE_BW=0
declare TOTAL_READ_BW=0
declare TOTAL_IOPS=0
declare TOTAL_BW=0
declare TOTAL_READ_LATENCY_MEAN=0
declare TOTAL_WRITE_LATENCY_MEAN=0
declare TOTAL_READ_LATENCY_P99=0
declare TOTAL_WRITE_LATENCY_P99=0
declare -i NUMJOBS=0

printf "Analyzing JSON logs in ${DIRECTORY}\n"
for file in `find ${DIRECTORY} -name "*.json" -type f `
do
  printf '.'
  NUMJOBS=$(($NUMJOBS+`jq -r '.jobs | length' $file`))
  RIOPS=`jq -r '[.. | objects | .read.iops] | add' $file`
  WIOPS=`jq -r '[.. | objects | .write.iops] | add' $file`
  READ_BW=`jq -r '[.. | objects | .read.bw] | add' $file`
  WRITE_BW=`jq -r '[.. | objects | .write.bw] | add' $file`

  READ_LATENCY_MEAN=`jq  -r ' [.. | objects | .read.clat_ns.mean] | add' $file`
  WRITE_LATENCY_MEAN=`jq -r ' [.. | objects | .write.clat_ns.mean] | add' $file`
  READ_LATENCY_P99=`jq   -r ' [.. | objects | .read.clat_ns.percentile."99.900000"] | add ' $file`
  WRITE_LATENCY_P99=`jq  -r ' [.. | objects | .write.clat_ns.percentile."99.900000"] | add ' $file`

  TOTAL_READ_IOPS=`echo ${TOTAL_READ_IOPS}+${RIOPS} | bc`
  TOTAL_WRITE_IOPS=`echo ${TOTAL_WRITE_IOPS}+${WIOPS} | bc`
  TOTAL_READ_BW=`echo ${TOTAL_READ_BW}+${READ_BW} | bc`
  TOTAL_WRITE_BW=`echo ${TOTAL_WRITE_BW}+${WRITE_BW} | bc`
  TIME_ELAPSED=`jq -r '.jobs[0].elapsed' $file`

  TOTAL_READ_LATENCY_MEAN=`echo ${READ_LATENCY_MEAN}+${TOTAL_READ_LATENCY_MEAN} | bc`
  TOTAL_WRITE_LATENCY_MEAN=`echo ${WRITE_LATENCY_MEAN}+${TOTAL_WRITE_LATENCY_MEAN} | bc`
  TOTAL_READ_LATENCY_P99=`echo ${READ_LATENCY_P99}+${TOTAL_READ_LATENCY_P99} | bc`
  TOTAL_WRITE_LATENCY_P99=`echo ${WRITE_LATENCY_P99}+${TOTAL_WRITE_LATENCY_P99} | bc`

done
TOTAL_READ_IOPS=${TOTAL_READ_IOPS%.*}
TOTAL_WRITE_IOPS=${TOTAL_WRITE_IOPS%.*}
TOTAL_READ_BW=${TOTAL_READ_BW%.*}
TOTAL_WRITE_BW=${TOTAL_WRITE_BW%.*}
TOTAL_IOPS=$((TOTAL_READ_IOPS+TOTAL_WRITE_IOPS))
TOTAL_BW=$((TOTAL_READ_BW+TOTAL_WRITE_BW))

TOTAL_READ_LATENCY_MEAN=${TOTAL_READ_LATENCY_MEAN%.*}
TOTAL_WRITE_LATENCY_MEAN=${TOTAL_WRITE_LATENCY_MEAN%.*}
TOTAL_READ_LATENCY_P99=${TOTAL_READ_LATENCY_P99%.*}
TOTAL_WRITE_LATENCY_P99=${TOTAL_WRITE_LATENCY_P99%.*}

TOTAL_READ_LATENCY_MEAN=$((TOTAL_READ_LATENCY_MEAN/NUMJOBS))
TOTAL_WRITE_LATENCY_MEAN=$((TOTAL_WRITE_LATENCY_MEAN/NUMJOBS))
TOTAL_READ_LATENCY_P99=$((TOTAL_READ_LATENCY_P99/NUMJOBS))
TOTAL_WRITE_LATENCY_P99=$((TOTAL_WRITE_LATENCY_P99/NUMJOBS))

printf "\n\nFIO LOG ANALYSIS FOR: $DIRECTORY\n"
printf "\tJOB RUNTIME:\t\t\t$TIME_ELAPSED (seconds)\n"
printf "\tNUMBER FIO JOBS:\t\t$NUMJOBS\n\n"

printf "TOTALS:\n"
printf "\tTOTAL BANDWIDTH:\t\t%'d KB/s\n" $TOTAL_BW
printf "\tTOTAL IOPS:\t\t\t%'d IOPS\n\n" $TOTAL_IOPS

printf "BY OPERATION:\n"
printf "\tREAD IOPS:\t\t\t%'d IOPS\n" $TOTAL_READ_IOPS
printf "\tWRITE IOPS:\t\t\t%'d IOPS\n" $TOTAL_WRITE_IOPS
printf "\tREAD BANDWIDTH:\t\t\t%'d KB/s\n" $TOTAL_READ_BW
printf "\tWRITE BANDWIDTH:\t\t%'d KB/s\n" $TOTAL_WRITE_BW

printf "\nLATENCY AVERAGES:\n"
printf "\tMEAN READ LATENCY:\t\t$((TOTAL_READ_LATENCY_MEAN/1000000)) (ms)\n"
printf "\tMEAN WRITE LATENCY:\t\t$((TOTAL_WRITE_LATENCY_MEAN/1000000)) (ms)\n"
printf "\tP99 READ LATENCY:\t\t$((TOTAL_READ_LATENCY_P99/1000000)) (ms)\n"
printf "\tP99 WRITE LATENCY:\t\t$((TOTAL_WRITE_LATENCY_P99/1000000)) (ms)\n"







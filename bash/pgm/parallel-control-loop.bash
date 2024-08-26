#! /usr/bin/bash

function dttm_3_decimals() {
	if [ $1 -eq 1 ]; then 
	local dt=`date +"%Y%m%d:%H:%M:%S.%N"`
		echo "`head -c 21 <<< $dt`"
	else
		echo '                     '
	fi
}

function display_jobs_array() {
	echo ; echo "Info: $(dttm_3_decimals 1) Display $totalJobs jobs:"
	for (( jobNumber= 1; jobNumber <= totalJobs; jobNumber++ )); do
		echo "Info: ajProcessor[$jobNumber]=${ajProcessor[$jobNumber]}. ajRC[$jobNumber]=${ajRC[$jobNumber]}. ajProcessId[$jobNumber]=${ajProcessId[$jobNumber]}."
		echo "        ajCmd[$jobNumber]=${ajCmd[$jobNumber]}."
		echo "        ajOccurrence[$jobNumber]=${ajOccurrence[$jobNumber]}. ajLogFile[$jobNumber]=${ajLogFile[$jobNumber]}."
	done
	echo 
}

function display_imaginary_servers_array() {
	local L_jobNumber=
	local L_msg=""
	echo ; echo "Info: $(dttm_3_decimals 1) Display $maxProcessingUnit imaginary servers:"
	for (( processorNumber= 1; processorNumber <= maxProcessingUnit; processorNumber++ )); do
		L_msg="Info: IS $processorNumber isAssignedJob ${isAssignedJob[$processorNumber]} isState ${isState[$processorNumber]} \
isOccurrence ${isOccurrence[$processorNumber]}"
		L_jobNumber=${isAssignedJob[$processorNumber]}
		if [ $L_jobNumber -ge 1 ]; then
			L_msg+=" process id ${ajProcessId[$L_jobNumber]}."
		else
			L_msg+="."
		fi
		echo $L_msg
	done
	echo 
}

function show_6_vars() {
	echo "Info:                              jobHighWaterMark=$jobHighWaterMark. ajInProgress=$ajInProgress. ajWaiting=$ajWaiting. ajFinished=$ajFinished."
	echo "Info:                              isIdle=$isIdle. isBusy=$isBusy."
}

# isIdle=$maxProcessingUnit
# isBusy=0
# ajWaiting=$totalJobs
# ajFinished=0   # <-- When ajFinished is totalJobs then we are done!
# ajInProgress=0
# jobHighWaterMark=0    # jobHighWaterMark from 1 to totalJobs i.e. ${#ajCmd[@]}
function show_internal_state() {
	echo ; echo "Info: $(dttm_3_decimals 1) show_internal_state begin."
	echo "Info: maxProcessingUnit=$maxProcessingUnit. totalJobs=$totalJobs. jobHighWaterMark=$jobHighWaterMark."
	echo "         ajInProgress=$ajInProgress. ajWaiting=$ajWaiting. ajFinished=$ajFinished."
	echo "         isBusy=$isBusy. isIdle=$isIdle."
	echo "         logPath=$logPath. maxRetry=$maxRetry."
	echo "         waitIntervalSec=$waitIntervalSec. maxIterationLimit=$maxIterationLimit."
	# echo "Info: $(dttm_3_decimals 0) show_internal_state end."
	echo
}

function start_a_new_job() # $1 the imaginary server, 1..maxProcessingUnit. $2 the job number, 1..totalJobs. 
{
	# Requires 2 input parameters.
	local L_processorNumber=$1
	local L_jobNumber=$2
	local L_cmd=""

	jobHighWaterMark=$L_jobNumber
	isAssignedJob[$L_processorNumber]=$L_jobNumber
	isState[$L_processorNumber]=1
	isOccurrence[$L_processorNumber]=1
	let isIdle--
	let isBusy++

	ajProcessor[$L_jobNumber]=$L_processorNumber
	let ajWaiting--
	let ajInProgress++
	L_cmd=${ajCmd[$L_jobNumber]}
	ajOccurrence[$L_jobNumber]=1
	ajStartTimestamp[$L_jobNumber]="\"$(dttm_3_decimals 1)\""
	ajLogFile[$L_jobNumber]=${logPath}/a${L_jobNumber}-${ajOccurrence[$L_jobNumber]}.txt
	nohup $L_cmd > ${ajLogFile[$L_jobNumber]} 2>&1 &
	ajProcessId[$L_jobNumber]=$!
	ajRC[$L_jobNumber]=-1
}

function rerun_job() # $1 the imaginary server, 1..maxProcessingUnit.
{
	# Requires 1 input parameter.
	local L_processorNumber=$1
	local L_cmd=""
	local L_jobNumber=${isAssignedJob[$L_processorNumber]}

	let isIdle--
	let isBusy++

	let ajInProgress++

	L_cmd=${ajCmd[$L_jobNumber]}
	let ajOccurrence[$L_jobNumber]++
	ajLogFile[$L_jobNumber]=${logPath}/a${L_jobNumber}-${ajOccurrence[$L_jobNumber]}.txt
	ajStartTimestamp[$L_jobNumber]=\"$(dttm_3_decimals 1)\"
	nohup $L_cmd > ${ajLogFile[$L_jobNumber]} 2>&1 &
	ajProcessId[$L_jobNumber]=$!
	ajRC[$L_jobNumber]=-1

	isState[$L_processorNumber]=1
	let isOccurrence[$L_processorNumber]++
}

function build_statusDescription() {
	local L_jobNumber=$1
	local tmpTxt=${ajStatusDescription[$L_jobNumber]}
	local newTxt=
	if [ ${ajOccurrence[$L_jobNumber]} -eq 1 ]; then
		:
	else
		newTxt=", "
	fi
	newTxt+="{ \"is\":${ajProcessor[$L_jobNumber]}\
 , \"job\":$L_jobNumber\
 , \"iteration\":${ajOccurrence[$L_jobNumber]}\
 , \"RC\":${ajRC[$L_jobNumber]}\
 , \"startTimestamp\":${ajStartTimestamp[$L_jobNumber]}\
 , \"endTimestamp\":${ajEndTimestamp[$L_jobNumber]}\
 , \"log\":\"${ajLogFile[$L_jobNumber]}\" }"
 	ajStatusDescription[$L_jobNumber]+="$newTxt"
}

function wrapup_statusDescription() {
	for (( jobNumber= 1; jobNumber <= $totalJobs; jobNumber++ )); do
		ajStatusDescription[$jobNumber]+=" ] }"
	done
}

function display_statusDescription() {
#	wrapup_statusDescription

	echo "Info: Jobs run status"
	echo "{ \"runStatus\": ["; 
	echo "${ajStatusDescription[1]}"

	for (( jobNumber= 2; jobNumber <= $totalJobs; jobNumber++ )); do
		echo ", ${ajStatusDescription[$jobNumber]}"; 
	done
	echo "] }"; echo 
}







# Main program begins:::
# Usage:   parallel-control-loop-2-parms.bash parameter-file-path command-file-path
# cd this-pgm-folder
# nohup ./parallel-control-loop-2-parms.bash ../parms/parms-10.txt ../parms/commands-10.txt  > ../logs-10/run-log.txt 2>&1 &


echo "Info: $(dttm_3_decimals 1) on `hostname`"
selfPgm=`readlink -f $0`
echo "Info: $selfPgm $* starting"; echo

n_args=$#
echo "Info: n_args=${n_args}"
if [ $n_args -ge 2 ]; then
	parmFile=`readlink -f $1`
	commandFile=`readlink -f $2`
	echo "Info: parmFile=${parmFile}. commandFile=${commandFile}."; echo
else
	echo "ERROR: Required input for parameter-file-path & command-file-path absent."
	echo "ERROR: Abort RC=2"
	exit 2
fi


# Read parmFile to get parameters.    Remove comments and empty lines.  

# the last line must have a \n, new line character
# Use od -xc FileName      to see the file content in hex
# Add || [ -n "$line" ]    to the loop condition

# while IFS= read -r line   # Success
# while read line           # Success
while IFS= read -r line || [ -n "$line" ] 
do
	newLine="${line#"${line%%[![:space:]]*}"}"   # Remove leading spaces

	if [[ $newLine =~ ^# ]]; then
		# echo "Info: Ignore begins with #"
		:
	elif [ ! -n "$newLine" ]; then
		# echo "Info: Empty line"
		:
	else
		echo "Info: $newLine"
		eval $newLine
	fi
done < "$parmFile"

# printf 'Info: logPath=%s\n' "${logPath}"
logPath=`readlink -f $logPath`
printf 'Info: logPath=%s\n' "${logPath}"
printf '\n'



# aj prefix for All Jobs
# is prefix for Imaginary Servers. Imaginary server was called processing unit.

# Read commandFile to get all jobs info.    Remove comments and empty lines.
# setup jobs array when reading the commandFile    
ajStatusDescription=()
ajProcessor=()    # Values 1..maxProcessingUnit
ajRC=()           # Return code: -1: the default, for not run yet. 
ajProcessId=()
ajStartTimestamp=()
ajEndTimestamp=()
ajCmd=()
ajOccurrence=()   # # of executions for this job: 0, 1, ... maxRetry.
ajLogFile=()

isAssignedJob=()
isState=()
isOccurrence=()


idx=1
while IFS= read -r line || [ -n "$line" ]
do
	newLine="${line#"${line%%[![:space:]]*}"}"   # Remove leading spaces
	if [[ $newLine =~ ^# ]]; then
		# echo "Info: Ignore begins with #"
		:
	elif [ ! -n "$newLine" ]; then
		# echo "Info: Empty line"
		:
	else
		# echo "Info: $newLine"
		ajStatusDescription[$idx]=
		ajCmd[$idx]="$newLine"  # Populate ajCmd array.
		ajRC[$idx]=-1       # -1: the default, for not run yet.
		ajProcessId[$idx]=-1
		ajProcessor[$idx]=0
		ajStartTimestamp[$idx]=0
		ajEndTimestamp[$idx]=0
		ajLogFile[$idx]="/dev/null"
		ajOccurrence[$idx]=0    # # of executions for this job: 0: the default, for not run yet.
		let idx++
	fi
done < "$commandFile"

totalJobs=${#ajCmd[@]}
printf '\n\nInfo: totalJobs=%s\n\n' "${totalJobs}" 


if [ $totalJobs -lt $maxProcessingUnit ]; then
	echo "Info: $(dttm_3_decimals 1) $maxProcessingUnit imaginary servers more than $totalJobs jobs. Reset # of imaginary servers to $totalJobs, same as # of jobs."
	maxProcessingUnit=$totalJobs
elif [ $totalJobs -gt $maxProcessingUnit ]; then
	echo "Info: $(dttm_3_decimals 1) $totalJobs jobs more than $maxProcessingUnit imaginary servers."
else
	echo "Info: $(dttm_3_decimals 1) $maxProcessingUnit imaginary servers same as $totalJobs jobs. All assigned and running."
fi
echo 

# Verify jobs initialization.
display_jobs_array

# setup Imaginary Servers, maxProcessingUnit
for (( idx= 1; idx <= maxProcessingUnit; idx++ )); do
	isAssignedJob[$idx]=0
	isState[$idx]=0
	isOccurrence[$idx]=0
done
echo 

# Verify processing Units initialization.
display_imaginary_servers_array









# Initially assign every imaginary server a job and start running! 

durationSecond=3600*${maxDurationHour}
startSecond=$(date +%s)
startDttm=`date -d @${startSecond}`

# is prefix for Processing Unit
isIdle=$maxProcessingUnit
isBusy=0
ajFinished=0   # <-- When ajFinished is totalJobs then we are done!
ajWaiting=$totalJobs
ajInProgress=0
jobHighWaterMark=0    # jobHighWaterMark ranges from 1 to totalJobs i.e. ${#ajCmd[@]}
# The 1st round of assigning jobs to imaginary server.
processorNumber=1
jobNumber=1
while [ $processorNumber -le $maxProcessingUnit ] && [ $jobNumber -le $totalJobs ]; do
	start_a_new_job $processorNumber $jobNumber		
	let processorNumber++
	let jobNumber++
done

let processorNumber--
let jobNumber--

show_internal_state
display_jobs_array
echo ; echo 
display_imaginary_servers_array



continueFlag=1
iterationCounter=1
# maxIterationLimit=20
while [ $continueFlag -eq 1 ] && [ $ajFinished -lt $totalJobs ] && [ $iterationCounter -le $maxIterationLimit ]; do
	env sleep ${waitIntervalSec}s
	msg="Info: $(dttm_3_decimals 1) ${iterationCounter} iteration $maxProcessingUnit ISs $totalJobs jobs."
	msg+=" ISs $isIdle idle, $isBusy busy."
	msg+=" Jobs $ajFinished finished, $ajInProgress in progress, $ajWaiting waiting, and $jobHighWaterMark high water mark."
	echo $msg

	processorNumber=1
	while [ $processorNumber -le $maxProcessingUnit ]; do
		msg="Info: $(dttm_3_decimals 0) IS ${processorNumber}"
		if [ ${isAssignedJob[$processorNumber]} -eq 0 ]; then   # A 1-1: processor idle?
			msg+=" idle. "

			if [ $ajFinished -eq $totalJobs ] && [ $ajWaiting -eq 0 ]; then
				continueFlag=0
				msg+="Jobs $ajFinished all finished."
			elif [ $ajWaiting -ge 1 ] && [ $jobHighWaterMark -lt $totalJobs ]; then
				let jobHighWaterMark++
				start_a_new_job $processorNumber $jobHighWaterMark		
				msg+="Start new job $jobHighWaterMark, $ajFinished finished, $ajWaiting waiting."
			else
				msg+="Jobs $ajFinished finished, $ajInProgress in progress, $ajWaiting waiting."
			fi
			echo $msg
			let processorNumber++
			continue
		fi    # A 1-1: processor idle? Done!



		currentJobNumber=${isAssignedJob[$processorNumber]}
		msg+=" running job $currentJobNumber process id ${ajProcessId[$currentJobNumber]}"
		# Processing Unit was assigned job so check if job finished
		ps ${ajProcessId[$currentJobNumber]} > /dev/null 2>&1
		ps_in_progress_RC=$?
		if [ $ps_in_progress_RC -eq 0 ]; then    # B 1-1: Job still running?
			# Processing Unit assigned job still in progress
			msg+=" in progress."
			echo $msg
			let processorNumber++
			continue
		fi    # B 1-1: Job still running? Done!



		# Processing Unit assigned job finished
		# Get its RC, ajRC[$currentJobNumber]
		ajEndTimestamp[$currentJobNumber]="\"$(dttm_3_decimals 1)\""
		let isIdle++
		let isBusy--
		let ajInProgress--
		ajRC[$currentJobNumber]=`tail -1 ${ajLogFile[$currentJobNumber]}`

		# Each job should log its RC at the end of its log!
		# If no RC logged then RC=1 is assumed!
		if [ -z "${ajRC[$currentJobNumber]}" ]; then
			ajRC[$currentJobNumber]=1
			msg+=", reset RC to 1. This job must be enhanced to log its RC at the end of its log file"
		fi
		msg+=", RC ${ajRC[$currentJobNumber]} with ${ajOccurrence[$currentJobNumber]} runs"
		build_statusDescription $currentJobNumber

		if [ ${ajRC[${currentJobNumber}]} -gt 1 ] && [ ${ajOccurrence[${currentJobNumber}]} -ge $maxRetry ]; then
		   	# C 1-4: RC > 1 & equal to maxRetry   No more rerun:
			msg+=", $maxRetry limit reached no more rerun. "
			let ajFinished++
			if [ $ajWaiting -ge 1 ] && [ $jobHighWaterMark -lt $totalJobs ]; then
				# Start a new job!
				theNewJobNumber=$((jobHighWaterMark+1))
				start_a_new_job $processorNumber $theNewJobNumber
				msg+="Start new job $theNewJobNumber process id ${ajProcessId[$theNewJobNumber]}."		
			elif [ $ajFinished -lt $totalJobs ]; then
				isAssignedJob[$processorNumber]=0
				isOccurrence[$processorNumber]=0
				msg+="No more job to run. "
			else
				isAssignedJob[$processorNumber]=0
				isOccurrence[$processorNumber]=0
				msg+="Jobs all finished. "
				continueFlag=0
			fi
		elif [ ${ajRC[${currentJobNumber}]} -gt 1 ] && [ ${ajOccurrence[${currentJobNumber}]} -lt $maxRetry ]; then
		# C 2-4: RC > 1 & less than maxRetry   OK to rerun:
			msg+=", rerun $((ajOccurrence[${currentJobNumber}]+1))"
			rerun_job $processorNumber
			msg+=" process id ${ajProcessId[${currentJobNumber}]}."
		else
		# C 3-4: RC & maxRetry & ajWaiting: RC=0
		# Finished successfully
			let ajFinished++
			if [ $ajWaiting -gt 0 ]; then
				# Start a new job!
				theNewJobNumber=$((jobHighWaterMark+1))
				start_a_new_job $processorNumber $theNewJobNumber
				msg+=". Start new job $theNewJobNumber process id ${ajProcessId[${theNewJobNumber}]}, $ajWaiting waiting."
			elif [ $ajFinished -eq $totalJobs ]; then
				isAssignedJob[$processorNumber]=0
				isOccurrence[$processorNumber]=0
				continueFlag=0
				msg+=". Jobs $ajFinished finished, $ajInProgress in progress, $ajWaiting waiting."
			else
				isAssignedJob[$processorNumber]=0
				isOccurrence[$processorNumber]=0
				msg+=". Jobs $ajFinished finished, $ajInProgress in progress, $ajWaiting waiting."
			fi	
		fi    # C 4-4

		# msg+="."  
		echo $msg
		let processorNumber++
	done  	# while [ $processorNumber -lt $maxProcessingUnit ]; do
	let iterationCounter++
	echo 

done   # while [ $continueFlag -eq 1 ] && [ $ajFinished -lt $totalJobs ] && [ $iterationCounter -le $maxIterationLimit ]; do

let iterationCounter--
msg="Info: $(dttm_3_decimals 1) ${iterationCounter} iteration $maxProcessingUnit ISs $totalJobs jobs."
msg+=" ISs $isIdle idle, $isBusy busy."
msg+=" Jobs $ajFinished finished, $ajInProgress in progress, $ajWaiting waiting, and $jobHighWaterMark high water mark."
echo $msg

if [ $iterationCounter -gt $maxIterationLimit ]; then
	echo 
	msg="WARNING: $(dttm_3_decimals 1) ${iterationCounter} iteration > $maxIterationLimit maxIterationLimit. Some jobs are NOT finished yet."
	echo $msg
fi



echo ; echo
display_statusDescription



echo ; echo
echo "Info: $selfPgm $* end"
echo "Info: $(dttm_3_decimals 1) on `hostname`"; echo ; echo 

exit 0

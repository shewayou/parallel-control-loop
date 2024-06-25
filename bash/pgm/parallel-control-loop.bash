#! /usr/bin/bash

function dttm_3_decimals() {
	if [ $1 -eq 1 ]; then 
	local dt=`date +"%Y%m%d:%H:%M:%S.%N"`
		echo "`head -c 21 <<< $dt`"
	else
		echo '                     '
	fi
}

display_jobs_array() {
	echo ; echo "Info: $(dttm_3_decimals 1) totalJobs=$totalJobs display:"
	for (( jobNumber= 1; jobNumber <= totalJobs; jobNumber++ )); do
		echo "Info: ajProcessor[$jobNumber]=${ajProcessor[$jobNumber]}. ajRC[$jobNumber]=${ajRC[$jobNumber]}. ajProcessId[$jobNumber]=${ajProcessId[$jobNumber]}."
		echo "        ajCmd[$jobNumber]=${ajCmd[$jobNumber]}."
		echo "        ajOccurrence[$jobNumber]=${ajOccurrence[$jobNumber]}. ajLogFile[$jobNumber]=${ajLogFile[$jobNumber]}."
	done
	echo 
}

display_processing_units_array() {
	echo ; echo "Info: $(dttm_3_decimals 1) maxProcessingUnit=$maxProcessingUnit display:"
	for (( processorNumber= 1; processorNumber <= maxProcessingUnit; processorNumber++ )); do
		echo "Info: puAssignedJob[$processorNumber]=${puAssignedJob[$processorNumber]}. puState[$processorNumber]=${puState[$processorNumber]}. puOccurrence[$processorNumber]=${puOccurrence[$processorNumber]}."
	done
	echo 
}

show_6_vars() {
	echo "Info:                              jobHighWaterMark=$jobHighWaterMark. ajInProgress=$ajInProgress. ajWaiting=$ajWaiting. ajFinished=$ajFinished."
	echo "Info:                              puIdle=$puIdle. puBusy=$puBusy."
}


# puIdle=$maxProcessingUnit
# puBusy=0
# ajWaiting=$totalJobs
# ajFinished=0   # <-- When ajFinished is totalJobs then we are done!
# ajInProgress=0
# jobHighWaterMark=0    # jobHighWaterMark from 1 to totalJobs i.e. ${#ajCmd[@]}
show_internal_state() {
	echo ; echo "Info: $(dttm_3_decimals 1) show_internal_state begin."
	echo "Info: maxProcessingUnit=$maxProcessingUnit. totalJobs=$totalJobs. jobHighWaterMark=$jobHighWaterMark."
	echo "         ajInProgress=$ajInProgress. ajWaiting=$ajWaiting. ajFinished=$ajFinished."
	echo "         puBusy=$puBusy. puIdle=$puIdle."
	echo "         maxRetry=$maxRetry. logFolder=$logFolder. waitIntervalSec=$waitIntervalSec."
	# echo "Info: $(dttm_3_decimals 0) show_internal_state end."
	echo
}



start_a_new_job() # $1 the processing unit, 1..maxProcessingUnit. $2 the job number, 1..totalJobs. 
{
	# Requires 2 input parameters.
	local L_processorNumber=$1
	local L_jobNumber=$2
	local L_cmd=""

	jobHighWaterMark=$L_jobNumber
	puAssignedJob[$L_processorNumber]=$L_jobNumber
	puState[$L_processorNumber]=1
	puOccurrence[$L_processorNumber]=1
	let puIdle--
	let puBusy++

	ajProcessor[$L_jobNumber]=$L_processorNumber
	let ajWaiting--
	let ajInProgress++
	L_cmd=${ajCmd[$L_jobNumber]}
	ajOccurrence[$L_jobNumber]=1
	ajLogFile[$L_jobNumber]=${logFolder}/a${L_jobNumber}-${ajOccurrence[$L_jobNumber]}.txt
	nohup $L_cmd > ${ajLogFile[$L_jobNumber]} 2>&1 &
	ajProcessId[$L_jobNumber]=$!
	ajRC[$L_jobNumber]=-1
}

rerun_job() # $1 the processing unit, 1..maxProcessingUnit.
{
	# Requires 1 input parameter.
	local L_processorNumber=$1
	local L_cmd=""
	local L_jobNumber=${puAssignedJob[$L_processorNumber]}

	let puIdle--
	let puBusy++

	let ajInProgress++

	L_cmd=${ajCmd[$L_jobNumber]}
	let ajOccurrence[$L_jobNumber]++
	ajLogFile[$L_jobNumber]=${logFolder}/a${L_jobNumber}-${ajOccurrence[$L_jobNumber]}.txt
	nohup $L_cmd > ${ajLogFile[$L_jobNumber]} 2>&1 &
	ajProcessId[$L_jobNumber]=$!
	ajRC[$L_jobNumber]=-1

	puState[$L_processorNumber]=1
	let puOccurrence[$L_processorNumber]++
}


# Usage:   parallel-control-loop-2-parms.bash parameter-file-path command-file-path

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

# printf 'Info: logFolder=%s\n' "${logFolder}"
logFolder=`readlink -f $logFolder`
printf 'Info: logFolder=%s\n' "${logFolder}"
printf '\n'



# Read commandFile to get all jobs info.    Remove comments and empty lines.
# setup jobs array when reading the commandFile    aj prefix for All Jobs
ajProcessor=()    # Values 1..maxProcessingUnit
ajRC=()           # Return code: -1: the default, for not run yet. 
ajProcessId=()
ajCmd=()
ajOccurrence=()   # # of executions for this job: 0, 1, ... maxRetry.
ajLogFile=()

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
		ajCmd[$idx]="$newLine"  # Populate ajCmd array.
		ajRC[$idx]=-1       # -1: the default, for not run yet.
		ajProcessId[$idx]=-1
		ajProcessor[$idx]=0
		ajLogFile[$idx]="/dev/null"
		ajOccurrence[$idx]=0    # # of executions for this job: 0: the default, for not run yet.
		let idx++
	fi
done < "$commandFile"

totalJobs=${#ajCmd[@]}
printf '\n\nInfo: totalJobs=%s\n\n' "${totalJobs}" 


if [ $totalJobs -lt $maxProcessingUnit ]; then
	echo "Info: $(dttm_3_decimals 1) More processing unit, $maxProcessingUnit, than jobs, $totalJobs. Reset maxProcessingUnit to $totalJobs, same as jobs."
	maxProcessingUnit=$totalJobs
elif [ $totalJobs -gt $maxProcessingUnit ]; then
	echo "Info: $(dttm_3_decimals 1) More jobs, $totalJobs, than processing unit, $maxProcessingUnit."
else
	echo "Info: $(dttm_3_decimals 1) Same processing unit, $maxProcessingUnit, as jobs, $totalJobs. All assigned and running."
fi
echo 

# Verify jobs initialization.
display_jobs_array

# setup processing units, maxProcessingUnit
for (( idx= 1; idx <= maxProcessingUnit; idx++ )); do
	puAssignedJob[$idx]=0
	puState[$idx]=0
	puOccurrence[$idx]=0
done
echo 

# Verify processing Units initialization.
display_processing_units_array









# Initially assign every processing unit a job and start running! 

durationSecond=3600*${maxDurationHour}
startSecond=$(date +%s)
startDttm=`date -d @${startSecond}`
continueFlag=1
counter=0


# pu prefix for Processing Unit
puIdle=$maxProcessingUnit
puBusy=0
ajFinished=0   # <-- When ajFinished is totalJobs then we are done!
ajWaiting=$totalJobs
ajInProgress=0
jobHighWaterMark=0    # jobHighWaterMark ranges from 1 to totalJobs i.e. ${#ajCmd[@]}
# The 1st round of assigning jobs to processing unit.
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
display_processing_units_array
echo ; echo 



continueFlag=1
iterationCounter=1
maxIterationLimit=20
while [ $continueFlag -eq 1 ] && [ $ajFinished -lt $totalJobs ] && [ $iterationCounter -le $maxIterationLimit ]; do
	env sleep ${waitIntervalSec}s
	msg="Info: $(dttm_3_decimals 1) $maxProcessingUnit PUs for $totalJobs jobs ${iterationCounter} iteration."
	msg+=" PUs $puIdle idle, $puBusy busy."
	msg+=" $ajFinished jobs finished, $ajInProgress in progress, $ajWaiting waiting, and $jobHighWaterMark is job high water mark."
	echo $msg

	processorNumber=1
	while [ $processorNumber -le $maxProcessingUnit ]; do
		msg="Info: $(dttm_3_decimals 0) PU ${processorNumber}"
		if [ ${puAssignedJob[$processorNumber]} -gt 0 ]; then   # A 1-3: processor busy or not?
			currentJobNumber=${puAssignedJob[$processorNumber]}
			msg+=" running job $currentJobNumber and process id ${ajProcessId[$currentJobNumber]}"
			# Processing Unit was assigned job so check if job finished
			ps ${ajProcessId[$currentJobNumber]} > /dev/null 2>&1
			ps_in_progress_RC=$?
			if [ $ps_in_progress_RC -eq 0 ]; then    # B 1-3: Job running or not?
				# Processing Unit assigned job still in progress
				msg+=" in progress"
			else    # B 2-3: Job running or not? No, job finished! Next check its RC & maxRetry & ajWaiting!
				# Processing Unit assigned job finished
				# Get its RC, ajRC[$currentJobNumber]
				let puIdle++
				let puBusy--
				let ajInProgress--
				ajRC[$currentJobNumber]=`tail -1 ${ajLogFile[$currentJobNumber]}`
				if [ -z "${ajRC[$currentJobNumber]}" ]; then
					ajRC[$currentJobNumber]=1
					msg+=", reset RC to ${ajRC[$currentJobNumber]}"
				fi
				msg+=" RC ${ajRC[$currentJobNumber]} with ${ajOccurrence[$currentJobNumber]} runs"

				if [ ${ajRC[${currentJobNumber}]} -gt 1 ] && [ ${ajOccurrence[${currentJobNumber}]} -ge $maxRetry ]; then
			    # C 1-4: RC & maxRetry & ajWaiting: RC> 1 && no more rerun
					msg+=", $maxRetry limit reached no more rerun"
					let ajFinished++
					if [ $ajWaiting -ge 1 ] && [ $jobHighWaterMark -lt $totalJobs ]; then
						# Start a new job!
						theNewJobNumber=$((jobHighWaterMark+1))
						start_a_new_job $processorNumber $theNewJobNumber
						msg+=", start new job $theNewJobNumber"		
					elif [ $ajFinished -lt $totalJobs ]; then
						puAssignedJob[$processorNumber]=0
						puOccurrence[$processorNumber]=0
						msg+=", no more job to run"
					else
						puAssignedJob[$processorNumber]=0
						puOccurrence[$processorNumber]=0
						msg+=", all jobs done"
						continueFlag=0
					fi
				elif [ ${ajRC[${currentJobNumber}]} -gt 1 ] && [ ${ajOccurrence[${currentJobNumber}]} -lt $maxRetry ]; then
				# C 2-4: RC & maxRetry & ajWaiting: RC> 1 && rerun
					msg+=", rerun $((ajOccurrence[${currentJobNumber}]+1))"
					rerun_job $processorNumber
				else
				# C 3-4: RC & maxRetry & ajWaiting: RC=0
				# Finished successfully
					let ajFinished++
					if [ $ajWaiting -gt 0 ]; then
						# Start a new job!
						theNewJobNumber=$((jobHighWaterMark+1))
						start_a_new_job $processorNumber $theNewJobNumber
						msg+=", start new job $theNewJobNumber, $ajWaiting waiting"
					elif [ $ajFinished -eq $totalJobs ]; then
						puAssignedJob[$processorNumber]=0
						puOccurrence[$processorNumber]=0
						continueFlag=0
						msg+=", $ajInProgress in progress, $ajWaiting waiting, $ajFinished jobs finished"
					else
						puAssignedJob[$processorNumber]=0
						puOccurrence[$processorNumber]=0
						msg+=", $ajInProgress in progress, $ajWaiting waiting, $ajFinished jobs finished, $totalJobs jobs"
					fi	
				fi    # C 4-4
			fi    # B 3-3: Job running or not? Done!
		else    # A 2-3: processor busy or not? Idle, NOT busy 
			msg+=" idle"

			if [ $ajFinished -eq $totalJobs ] && [ $ajWaiting -eq 0 ]; then
				continueFlag=0
				msg+=" all finished $ajInProgress in progress, $ajWaiting waiting, $ajFinished jobs"
			elif [ $ajWaiting -ge 1 ] && [ $jobHighWaterMark -lt $totalJobs ]; then
				let jobHighWaterMark++
				start_a_new_job $processorNumber $jobHighWaterMark		
				msg+=" start new job $jobHighWaterMark, $ajWaiting waiting, $ajFinished jobs"
			else
				msg+=" $ajInProgress in progress, $ajWaiting waiting, $ajFinished jobs"
			fi
		fi    # A 3-3: processor busy or not? Done!
		msg+="."
		echo $msg
		let processorNumber++
	done  	# while [ $processorNumber -lt $maxProcessingUnit ]; do
	let iterationCounter++
	echo 

done   # while [ $continueFlag -eq 1 ] && [ $ajFinished -lt $totalJobs ] && [ $iterationCounter -le 10 ]; do

msg="Info: $(dttm_3_decimals 1) $maxProcessingUnit PUs for $totalJobs jobs ${iterationCounter} iteration."
msg+=" PUs $puIdle idle, $puBusy busy."
msg+=" Jobs $ajFinished finished, $ajInProgress in progress, $ajWaiting waiting, and $jobHighWaterMark is job high water mark."
echo $msg


echo ; echo
echo "Info: $selfPgm $* end"
echo "Info: $(dttm_3_decimals 1) on `hostname`"; echo ; echo 

exit 0

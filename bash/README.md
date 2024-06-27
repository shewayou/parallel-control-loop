folder structure:
pgm/
    parallel-control-loop.bash      the core program
    run1-positive-RC.bash           utility to simulate a long running job which ends with a positive return code
    run1.bash                       utility to simulate a long running job which ends with zero return code

parms/
    parms-1.txt                     parameters for the core program
    commands-1.txt                  all the jobs the core program needs to run



sample usage:
appPath=/home/ec2-user/environment
logPath=/home/ec2-user/environment/logs
dttm=`date +"%Y%m%d-%H%M%S"`;echo $dttm
nohup ${appPath}/pgm/parallel-control-loop.bash ${appPath}/parms/parms-1.txt ${appPath}/parms/commands-1.txt \
 > ${logPath}/run-results-${dttm}.log 2>&1 &

After it's finished, review <log-path>/run-results-${dttm}.log for execution details


If parallel-control-loop.bash cannot be executed on Linux,
it could be the file is \r\n at the end of each line. 
The \r needs to be removed. Use the tr -d '\r' command to fix it. Sample below:
mv parallel-control-loop.bash windows-parallel-control-loop.bash
cat windows-parallel-control-loop.bash | tr -d '\r' > parallel-control-loop.bash
chmod +x parallel-control-loop.bash

Repeat for the other utility bash programs too.



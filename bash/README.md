
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




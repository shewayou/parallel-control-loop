Problem statement: Have Y #s of jobs and they all can run independent of each other. Can I run these jobs in parallel, instead of sequentially, and know their execution results?

Assumption: This is Linux environment and all jobs run on a single Linux machine.

This solution: A bash script, "parallel-control-loop.bash", implements X #s of "imaginary servers" to run in parallel X #s of jobs. And every so often, say every T seconds, it checks on all these imaginary servers.
When an imaginary server is idle, examine return code (execution status) of the job that was run. If return code is 0 or 1, then this imaginary server will start a new job. If return code greater than 1, the same 
job will be run again, up to N times. Repeat for all imaginary servers and assign new jobs to run until all Y #s of jobs are finished or up to the limit of wall-clock duration is reached. Finally output some JSON strings indicating all jobs run status, see sample below.

Future Enhancements:
1) Implement this control loop in Python and Microsoft PowerShell languages.
2) Adapt to ssh command in Linux environment so that each job can run on different host via ssh command.
3) Write a Python to analyze all jobs run status to report on start/finish time, wall-clock duration and so on. <-- Implemented in Release v1.1.2.
4) Fully implement "up to the limit of wall-clock duration is reached", the wall-clock duration check.
5) Other user-friendliness issues such as logging. <-- Implemented in Release v1.1.2.


Sample run status JSON strings:
{ "runStatus": [
{ "is":1 , "job":1 , "iteration":1 , "RC":0 , "startTimestamp":"20240701:23:54:48.732" , "endTimestamp":"20240701:23:55:00.926" , "log":"/home/ec2-user/environment/logs-3/a1-1.txt" }
, { "is":2 , "job":2 , "iteration":1 , "RC":0 , "startTimestamp":"20240701:23:54:48.739" , "endTimestamp":"20240701:23:55:19.119" , "log":"/home/ec2-user/environment/logs-3/a2-1.txt" }
, { "is":3 , "job":3 , "iteration":1 , "RC":4 , "startTimestamp":"20240701:23:54:48.753" , "endTimestamp":"20240701:23:55:07.018" , "log":"/home/ec2-user/environment/logs-3/a3-1.txt" }, { "is":3 , "job":3 , "iteration":2 , "RC":4 , "startTimestamp":"20240701:23:55:07.024" , "endTimestamp":"20240701:23:55:25.238" , "log":"/home/ec2-user/environment/logs-3/a3-2.txt" }, { "is":3 , "job":3 , "iteration":3 , "RC":4 , "startTimestamp":"20240701:23:55:25.244" , "endTimestamp":"20240701:23:55:43.390" , "log":"/home/ec2-user/environment/logs-3/a3-3.txt" }
, { "is":1 , "job":4 , "iteration":1 , "RC":0 , "startTimestamp":"20240701:23:55:00.932" , "endTimestamp":"20240701:23:55:25.181" , "log":"/home/ec2-user/environment/logs-3/a4-1.txt" }
, { "is":2 , "job":5 , "iteration":1 , "RC":4 , "startTimestamp":"20240701:23:55:19.127" , "endTimestamp":"20240701:23:55:37.322" , "log":"/home/ec2-user/environment/logs-3/a5-1.txt" }, { "is":2 , "job":5 , "iteration":2 , "RC":4 , "startTimestamp":"20240701:23:55:37.330" , "endTimestamp":"20240701:23:55:55.472" , "log":"/home/ec2-user/environment/logs-3/a5-2.txt" }, { "is":2 , "job":5 , "iteration":3 , "RC":4 , "startTimestamp":"20240701:23:55:55.480" , "endTimestamp":"20240701:23:56:13.666" , "log":"/home/ec2-user/environment/logs-3/a5-3.txt" }
, { "is":1 , "job":6 , "iteration":1 , "RC":0 , "startTimestamp":"20240701:23:55:25.187" , "endTimestamp":"20240701:23:56:07.573" , "log":"/home/ec2-user/environment/logs-3/a6-1.txt" }
, { "is":3 , "job":7 , "iteration":1 , "RC":0 , "startTimestamp":"20240701:23:55:43.396" , "endTimestamp":"20240701:23:56:07.630" , "log":"/home/ec2-user/environment/logs-3/a7-1.txt" }
, { "is":1 , "job":8 , "iteration":1 , "RC":0 , "startTimestamp":"20240701:23:56:07.585" , "endTimestamp":"20240701:23:56:25.726" , "log":"/home/ec2-user/environment/logs-3/a8-1.txt" }
] }



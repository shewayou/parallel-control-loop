#! /usr/bin/bash

# Usage:   run2-no-RC.bash NUMBER[smhd]
 
 
echo "Info: `date` on `hostname`"
selfPgm=`readlink -f $0`
echo "Info: $selfPgm $* starting"; echo

# n_args=$#
# echo "Info: n_args=${n_args}"
# if [ $n_args -gt 2 ]; then
#     echo "Info: $n_args received"
# elif [ $n_args -eq 2 ]; then
#     timeUnit=$2
# elif [ $n_args -eq 1 ]; then
# else
#     echo "Info: $n_args > 0"
# fi

cmd="env sleep $*"
echo "Info: `date` $cmd to start"
eval $cmd
RC=$?
echo "Info: `date` $cmd end RC=$RC"; echo


echo "Info: $selfPgm $* end"
echo "Info: `date` on `hostname`"; echo ; echo 

# echo "0"    # Forgotten to echo its own RC. 




exit 0


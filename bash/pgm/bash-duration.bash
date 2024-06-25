#! /usr/bin/bash

function date_3_decimals() {
    local dt=`date +"%Y%m%d:%H:%M:%S.%N"`
    dt=`head -c 21 <<< $dt`
    echo "$dt"
}

echo "Info: $(date_3_decimals)"


startSecond=$(date +%s.%N)
startDttm=`date -d @${startSecond}`


# nanosecond is 9 digits integer. Use head -c 21 to truncate and show only 3 decimal places after second"
startDttm2=`date -d @${startSecond} +"%Y%m%d:%H:%M:%S.%N"`
startDttm2=`head -c 21 <<< $startDttm2`   # head -c 21 b/c "yyyymmdd:hh:mm:ss." this is 18 characters long.

echo "Info: $startDttm2"
echo "Info: $startDttm"
echo "Info: startSecond=$startSecond"

sleepSeconds=$1

env sleep $sleepSeconds

endSecond=$(date +%s.%N)
endDttm=`date -d @${endSecond}`
endDttm2=`date -d @${endSecond} +"%Y%m%d:%H:%M:%S.%N"`
endDttm2=`head -c 21 <<< $endDttm2`
echo "Info: $endDttm2"
echo "Info: $endDttm"
echo "Info: endSecond=$endSecond"

# durationSeconds=$((endSecond-startSecond))
# echo "Info: durationSeconds=$durationSeconds"



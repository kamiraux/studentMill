#! /usr/bin/env bash

if test $# -lt 2
then
    echo "Usage: $0 EXEC_TIMEOUT ABSOLUTE_TIMEOUT" >&2
    exit 1
fi


child_exec_timeout="$1"
child_abs_timeout="$2"

# Block until process has started and read its pid
read child_pid

echo Child PID: $child_pid

ps_line=`ps -p $child_pid -o time=''`


# INV_WAIT must be equal to '1 / WAIT'
WAIT=0.1    ### Change these two value together !
INV_WAIT=10 ### Change these two value together !


NB_LOOP=0
MAX_NB_LOOP=$(($child_abs_timeout * $INV_WAIT))
while test "$ps_line" != ""
do
    ps_line=`echo "$ps_line" | sed 's/ //g'`
    OLD_IFS="$IFS"
    IFS=':.'
    read time_min time_sec time_csec <<EOF
$ps_line
EOF
#    echo "$ps_line -- $time_min -- $time_sec -- $time_csec"
    IFS="$OLD_IFS"
    time_min=$((10#${time_min}))
    time_sec=$((10#$time_sec))
    if test $(($time_min * 60 + $time_sec)) -ge "$child_exec_timeout" \
        || test $NB_LOOP -ge $MAX_NB_LOOP
    then
        kill -9 $child_pid
        break 1
    else
        sleep $WAIT
        ps_line=`ps -p $child_pid -o time=''`
        NB_LOOP=$(($NB_LOOP + 1))
    fi
done

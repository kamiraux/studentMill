#! /bin/sh

logfile="$1"
config_file="$2"
login="$3"


> ${logfile}_${login}.log \
    2>&1 0>&1 \
    ./launch_student.sh "$config_file" "$login"

#! /bin/sh

logfile="$1"
config_file="$2"
login="$3"
id_worker="$4"

> ${logfile}_${login}.log \
    2>&1 0>&1 \
    exe/launch_student.sh "$config_file" "$login" "$id_worker"

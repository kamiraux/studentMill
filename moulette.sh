#! /usr/bin/env bash

# Usage
if test $# -lt 1
then
    echo "Usage: ${0} config_file" >&2
    exit 1
fi

# Configuration
if test -e "$1"
then
    echo "Moving to '"`dirname "$1"`"'"
    cd `dirname "$1"`
    source `basename "$1"`
 else
    echo "Unable to find '$1'" >&2
    exit 1
fi

CONFIG_ABS=`realpath "$1"`

rm -rf "/tmp/${M_PROJECT_NAME}_${M_RTOKEN}"
TMP_PROJ_DIR=`mktemp -d "/tmp/${M_PROJECT_NAME}_${M_RTOKEN}"`
chmod 711 "$TMP_PROJ_DIR"

# Pre-processing
echo "Compilation of tests"
> "${M_LOG_FILE_NAME}_pre_process".out \
    2> "${M_LOG_FILE_NAME}_pre_process".err \
    "${M_MOULETTE_ASSETS}"/pre_process.sh "$CONFIG_ABS"


# Launch tests for each student
echo "Launching tests"
gmake -j $M_NB_WORKERS \
    -f "${M_MOULETTE_ASSETS}"/parallelism/Makefile \
    CONFIG_ABS="$CONFIG_ABS" \
    STUDENTS_FILE="$M_STUDENT_LIST_FILE" \
    LOG="${M_LOG_FILE_NAME}" \
    MOULETTE_ASSETS="${M_MOULETTE_ASSETS}" \
    launch

# for student in `cat $M_STUDENT_LIST_FILE`
# do
#     echo "Student: $student"
#     > "${M_LOG_FILE_NAME}_${student}".out \
#         2>&1 \
#         "${M_MOULETTE_ASSETS}"/launch_student.sh "$CONFIG_ABS" "$student"

#  "${M_LOG_FILE_NAME}_${student}".err \
#done




#rm -rf "/tmp/${M_PROJECT_NAME}_${M_RTOKEN}"

function realpath()
{
    test ${1:0:1} = "/" && echo "$1" || echo "$PWD/${1#./}"
}

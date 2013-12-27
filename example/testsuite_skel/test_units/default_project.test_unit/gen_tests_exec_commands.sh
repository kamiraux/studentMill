#! /bin/sh

NAMES=`find . -name '*.arg'`

if test "$NAMES" = ""
then
    NAMES=`basename "$PWD"`
    NAMES=${NAMES%.test}
    echo "${NAMES},./test_bin" > test_exec_commands
else
    echo "$NAMES" | sed -e 's#^./##
s#.arg$#,./test_bin#' > test_exec_commands
fi

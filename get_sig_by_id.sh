#! /usr/bin/env bash

if test $# -lt 2
then
    echo "Usage: $0 SIGNAL ARCH" >&2
    exit 1
fi

SIGNAL=$1
ARCH=$2

SIG=`grep "^${SIGNAL}," "SIGNALS_${ARCH}" | cut -d, -f 2`

if test "$SIG" = ""
then
    SIG="Signal id $SIGNAL"
fi

echo "$SIG"

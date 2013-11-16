#! /usr/bin/env bash

SIGNAL=$1
ARCH=$2

SIG=`grep "^${SIGNAL}," "SIGNALS_${ARCH}" | cut -d, -f 2`

if "$SIG" = ""
then
    SIG="Signal id $SIGNAL"
fi

echo "$SIG"

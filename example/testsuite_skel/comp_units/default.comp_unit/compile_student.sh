#! /bin/sh

M_MAKE=$1

if test -e configure
then
    echo "    configure"
    ./configure
fi
if test -e Makefile
then
    echo "    make"
    ${M_MAKE} some_rule_to_call
fi

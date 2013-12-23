#! /usr/bin/env bash

if test $# -lt 3
then
    echo too few arguments >&2
    echo Usage: ./gen_trace.sh config_file_abs login_x results_dir >&2
else
    source "$1"
    LOGIN="$2"
    RES_DIR="$3"
    if test ${M_TRACE_GENERATOR:0:1} = "/"
    then
        GEN_COMMAND="$M_TRACE_GENERATOR"
    else
        GEN_COMMAND="$M_MOULETTE_ASSETS/trace_generators/$M_TRACE_GENERATOR"
    fi
    pushd "$RES_DIR"
    "$GEN_COMMAND" "$LOGIN" "`dirname "$GEN_COMMAND"`" > "$M_TRACE_DIR/$LOGIN"
    popd # Come back from result direcory

fi

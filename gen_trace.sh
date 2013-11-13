#! /bin/sh

if test $# -lt 2
then
    echo too few arguments >&2
    echo Usage: ./launch config_file_abs login_x results_dir >&2
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
    pushd `dirname "$GEN_COMMAND"`
    "$GEN_COMMAND" "$LOGIN" "$TESTS_RESULTS" > "$M_TRACE_DIR/$LOGIN"
    popd # Come back from trace direcory

fi

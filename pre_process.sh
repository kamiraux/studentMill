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
    source "$1"
 else
    echo "Unable to find '$1'" >&2
    exit 1
fi

source "$1"

# Pre processing of tests
# -> typically test object files compilation
echo "Pre-treatment for tests"
pushd "$M_TESTS_FOLDER"
# Change rights of compile_student.sh scripts to allow execution by students
chmod go+rx `find comp_unit -name "compile_student.sh"`

for test_dir in `find . -type d -name "*.test"`
do
    echo "  "$test_dir
    pushd "$test_dir"
    if test -e "ref_test_unit"
    then
        REF_TEST_UNIT=`cat ref_test_unit`
        echo "    Using test unit: '$REF_TEST_UNIT'"
        if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/configure
        then
            CONFIGURE="$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/configure
            ARGS="$M_TESTS_FOLDER/test_units/$REF_TEST_UNIT"
        fi
        if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/Makefile
        then
            MAKEFILE="$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/Makefile
        fi
        if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/gen_test_exec_commands.sh
        then
            GEN_TESTS="$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/gen_test_exec_commands.sh
        fi
    fi
    if test -e configure
    then
        CONFIGURE=./configure
        ARGS=
    fi
    if test -e Makefile
    then
        MAKEFILE=Makefile
    fi
    if test -e gen_test_exec_commands.sh
    then
        GEN_TESTS=./gen_test_exec_commands.sh
    fi

    test "$CONFIGURE" != "" \
        && (echo "    configure"
        "$CONFIGURE" $ARGS)

    test "$MAKEFILE" != "" \
        && (echo "    $M_MAKE"
        $M_MAKE -f "$MAKEFILE" common_compilation)

    test "$GEN_TESTS" != "" \
        && (echo "    Generating test execution commands"
        "$GEN_TESTS")

    popd
done
popd

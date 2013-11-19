#! /usr/bin/env bash

LOGIN="$1"
GENERETOR_ASSETS="$2"


gen_rec ()
{
    TEST_NAME=`basename "$1"`
    TEST_ID=`echo "$1" | sed 's#/#__#g'`

    if test -e test.name
    then
        TEST_NAME=`cat test.name`
    fi
    if test -e test.result
    then
        # We are a result directory
        # Gen trace
        RESULT=`cat test.result`
        if test "$RESULT" = "PASS"
        then
            VALUE=1
        else
            VALUE=0
        fi
        for i in `seq $2`
        do
            printf '#'
        done
        echo " Test: $TEST_NAME - $RESULT"
        if test -e test.error
        then
            #LOG=`cat test.error`
            echo "Info:"
            echo "`cat test.error`"
        fi

        echo
    else
        # Not in result dir
        # Gen group xml
        for i in `seq $2`
        do
            printf '#'
        done
        echo " Test group: $TEST_NAME"
        # Browse sub directories
        for dir in `ls -d */ 2> /dev/null`
        do
            pushd "$dir" > /dev/null
            gen_rec "$1/${dir%/}" $(($2 + 1))
            popd > /dev/null # Come back from $dir
        done
    fi
}



for dir in `ls -d */ 2> /dev/null`
do
    pushd "$dir" > /dev/null
    gen_rec "${dir%/}" 1
    popd > /dev/null # Come back from $dir
done

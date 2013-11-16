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
        echo '<eval type="test" id="'"$TEST_ID"'">
<name>'"$TEST_NAME"'</name>'
        if test -e test.error
        then
            #LOG=`cat test.error`
            echo '<log type="Info">
'"`cat test.error`"'
</log>'
        # else
        #     LOG=
        fi

        echo '<value>'"$VALUE"'</value>
<status>'"$RESULT"'</status>
</eval>'
    else
        # Not in result dir
        # Gen group xml
        echo '<group id="'"$TEST_ID"'" name="'"$TEST_NAME"'">'
        # Browse sub directories
        for dir in `ls -d */ 2> /dev/null`
        do
            pushd "$dir" > /dev/null
            gen_rec "$1/${dir%/}"
            popd > /dev/null # Come back from $dir
        done
        # Gen end group xml
        echo '</group>'
    fi
}


echo '<?xml version="1.0"?>
<trace type="mill">
    <group id="root_trace" name="Project">'


for dir in `ls -d */ 2> /dev/null`
do
    pushd "$dir" > /dev/null
    gen_rec "${dir%/}"
    popd > /dev/null # Come back from $dir
done

echo '</group>
</trace>'

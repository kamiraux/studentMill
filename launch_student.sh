#! /bin/sh

##### Sandboxed calls !

if test $# -lt 2
then
    echo too few arguments >&2
    echo Usage: ./launch config_file_abs login_x >&2
else
    # Constatnts
    TIMEOUT_EXEC_ABS_RATIO=3
    # End

    LOGIN=$2
    source "$1"
    export M_MAKE

    SAN_TB="${M_TARBALLS_FOLDER}/${LOGIN}_sanitized"
    USER_COMP_DIR="/home/$LOGIN}/${M_PROJECT_NAME}_${M_RTOKEN}"
    echo $LOGIN

    echo "--- Pre processiong ---"
    echo "Copying tarball"
    cp -rf "$M_TARBALLS_FOLDER"/"$LOGIN" "$SAN_TB"
    echo "Sanitizing"
    pushd "$SAN_TB"
    # Remove check directory
    rm -rf check

    # Sanity check
    echo "Sanity check"
     # AUTHORS
    if test "* $LOGIN" != "`head -n 1 AUTHORS`"
        echo "Fail AUTHORS !"
    fi
     # Dirty files
    # Coding style check
    popd # come back from sanitized tarball


    # Create user login_x
    echo "Creating user '$LOGIN'"
    ## For freeBSD
    pw groupadd "$LOGIN"
    pw useradd  "$LOGIN" -g "$LOGIN"
    USER_ID=`id -u "$LOGIN"`
    test -d /home/"$LOGIN" || mkdir /home/"$LOGIN"
    chown "$LOGIN:$LOGIN" /home/"$LOGIN"
    chmod 100 /home/"$LOGIN"
    ##

    echo "Creating compilation directory"
    mkdir "$USER_COMP_DIR"
    chmod 100 "$USER_COMP_DIR"

    echo "Creating temporary directory for tests"
    TMP_TEST_DIR=`mktemp -d "/tmp/${M_PROJECT_NAME}_${M_RTOKEN}/${LOGIN}-XXXX"`

    CHEAT=false

    # Student compilation for each compilation unit
    echo "--- Compilation of compilation units ---"
    pushd "$M_TESTS_FOLDER"/comp_units
    for comp_unit in *.comp_unit
    do
        echo "  "$comp_unit
        pushd "$comp_unit"
        cp -rf "$SAN_TB" "${USER_COMP_DIR}/${comp_unit}"
        if test -e "pre_comp_tb_changes.sh"
        then
            # This script must assume to be launched where it is (ie. in
            # the `.comp_unit` folder) and the first argument is the path
            # to the tarball to modify
            echo "    Pre compilation changes"
            ./pre_comp_tb_changes.sh "${USER_COMP_DIR}/${comp_unit}"
        fi

        chown -R "$LOGIN":"$LOGIN" "${USER_COMP_DIR}/${comp_unit}"

        # Compile the student code
        # Compute timeouts
        EXEC_TIMEOUT=3
        ABS_TIMEOUT=

        if test -e exec_timeout
        then
            EXEC_TIMEOUT=1`cat exec_timeout`
        fi
        if test -e abs_timeout
        then
            ABS_TIMEOUT=1`cat abs_timeout`
        fi
        test "$ABS_TIMEOUT" = "" \
            && ABS_TIMEOUT=$(($TIMEOUT_EXEC_ABS_RATIO * $EXEC_TIMEOUT))

        echo "  Timeout set to:
    Exec: $EXEC_TIMEOUT
    Abs:  $ABS_TIMEOUT"
        if test -e "compile_student.sh"
        then
            echo "    Student compilation"
            pushd "${USER_COMP_DIR}/${comp_unit}"
            # This script must assume to be launched in the sanitized tarball
            # folder of the current compilation unit
            ##### "${M_TESTS_FOLDER}/${comp_unit}/compile_student.sh"
            "$M_MOULETTE_ASSETS/sandbox" \
                "${USER_COMP_DIR}/${comp_unit}.out" \
                "${USER_COMP_DIR}/${comp_unit}.err" \
                "${USER_COMP_DIR}/${comp_unit}.ret" \
                $USER_ID \
                "${M_TESTS_FOLDER}/${comp_unit}/compile_student.sh"
                | "$M_MOULETTE_ASSETS/kill_timeout" $EXEC_TIMEOUT $ABS_TIMEOUT
            popd
            # TODO: kill remaining processes
        fi


        # Check that expected output are present
        # external authorized functions
        if test -d expected
            echo "    Checking for expected files"
            EXPTECTATION=true
            ERROR_MSG=
            for expected in `ls expected` # TODO: only folders
            do
                pushd "expected/${expected}"
                for expected_file in `cat expected_files`
                do
                    FILE_TO_TEST="${USER_COMP_DIR}/${comp_unit}/${expected_file}"
                    if test -e "$FILE_TO_TEST"
                    then
                        echo "      ${FILE_TO_TEST} is present"
                        if test -e authorized_functions
                        then
                            AUTH_FUN_FILE="$M_TESTS_FOLDER/comp_units/${comp_unit}/expected/${expected}/authorized_functions"
                            USED_FUNCTIONS=`${M_MOULETTE_ASSETS}/import_check.sh "$FILE_TO_TEST" "$AUTH_FUN_FILE"`
                            if test "$USED_FUNCTIONS" != ""
                            then
                                echo "/!\ Cheat detected: using forbidden function '${used_fun}'"
                                CHEAT=true
                                EXPTECTATION=false
                                ERROR_MSG="${ERROR_MSG}Forbidden functions detected in file '${file_to_test}':\n${USED_FUNCTIONS}\n"
                            fi
                        fi
                    else
                        echo "      File: '${file_to_test}' not found"
                        ERROR_MSG="${ERROR_MSG}File: '${file_to_test}' not found\n"
                        EXPTECTATION=false
                    fi
                done
                popd # Come back form expectation folder
            done

            if $EXPTECTATION
            then
                echo "    -> Success"
            else
                echo "    -> Failure"
                rm -rf "${USER_COMP_DIR}/${comp_unit}"
                echo "$ERROR_MSG" > "${USER_COMP_DIR}/${comp_unit}.error"
                echo "Compilation error log:" >> "${USER_COMP_DIR}/${comp_unit}.error"
                cat "${USER_COMP_DIR}/${comp_unit}.err" >> "${USER_COMP_DIR}/${comp_unit}.error"
            fi
        fi
        popd # Come back from comp_unit folder
    done
    popd # Come back form $M_TEST_FOLDER

    if $CHEAT
    then
        exit 2
    fi

    TESTS_RESULTS="${TMP_TEST_DIR}/results"
    mkdir -p "$TESTS_RESULTS"

    # Launch
    echo "--- Tests ---"
    pushd "$M_TESTS_FOLDER"
    for test_dir in `find . -type d -name "*.test"`
    do
        echo "Test: $test_dir"
        TEST_STATUS=true
        REF_COMP_UNIT="default"
        REF_TEST_UNIT=
        pushd "$test_dir"
        if test -e "ref_comp_unit"
        then
            REF_COMP_UNIT=`cat ref_comp_unit`
        fi
        echo "  Using compilation unit: ${REF_COMP_UNIT}"
        if test -e "ref_test_unit"
        then
            REF_TEST_UNIT=`cat ref_test_unit`
        fi
        echo "  Using compilation unit: ${REF_COMP_UNIT}"
        echo "  Using test unit: ${REF_TEST_UNIT}"

        # Create directories for test result
        TEST_RESULT="$TESTS_RESULTS/${test_dir%.test}"
        mkdir -p "$TEST_RESULT"

        if test -d "${USER_COMP_DIR}/${REF_COMP_UNIT}".comp_unit
            # Create directories for test execution and test output
            mkdir -p "${TMP_TEST_DIR}/${test_dir}"
            TEST_OUT="${TMP_TEST_DIR}/${test_dir}.output"
            mkdir -p "$TEST_OUT"

            # Compile/link the test
            CONFIGURE=
            if test -e configure
            then
                CONFIGURE="$PWD/configure"
            elif "$REF_TEST_UNIT" != ""
            then
                if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/configure
                then
                    CONFIGURE="$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/configure
                fi
            fi
            MAKEFILE=
            if test -e Makefile
            then
                MAKEFILE="$PWD/Makefile"
            elif "$REF_TEST_UNIT" != ""
            then
                if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/Makefile
                then
                    MAKEFILE="$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/Makefile
                fi
            fi
            pushd "${TMP_TEST_DIR}/${test_dir}"
            test "$CONFIGURE" != "" \
                && (echo "  Compilation/link: configure"
                "$CONFIGURE")
            if test "$MAKEFILE" != ""
            then
                echo "  Compilation/link: $M_MAKE"
                $M_MAKE -f "$MAKEFILE" \
                    COMP_UNIT_DIR="${USER_COMP_DIR}/${REF_COMP_UNIT}.comp_unit" \
                    TEST_DIR="${M_TESTS_FOLDER}/${test_dir}" \
                    test_compilation
            fi
#            chown -R root "${M_TESTS_FOLDER}/${test_dir}"
#            chmod -R 711 "${M_TESTS_FOLDER}/${test_dir}"
            popd # Come back from test directory


            # Copy test_data
            if test -e required_data
            then
                echo "  Copying required data for test"
                REQUIRED_DATA=`cat required_data`
                if test "$REQUIRED_DATA" = "all"
                    cp -rf "$M_TESTS_FOLDER"/test_data "${TMP_TEST_DIR}/${test_dir}"
               else
                    OLD_IFS="$IFS"
                    IFS=$'\n'
                    for line in $REQUIRED_DATA
                    do
                        DIR="${TMP_TEST_DIR}/${test_dir}/test_data/"`dirname "$line"`
                        test -d "$DIR" || mkdir -p "$DIR"
                        cp -rf "$M_TESTS_FOLDER/test_data/$line" "$DIR"
                    done
                    IFS="$OLD_IFS"
                fi
                chown -R "$LOGIN:$LOGIN" "${TMP_TEST_DIR}/${test_dir}/test_data"
            fi


            # Execute pre_test script
            # TODO:
            PRE_TEST_SCRIPT=
            if test -e pre_test.sh
            then
                PRE_TEST_SCRIPT="$PWD/pre_test.sh"
            elif "$REF_TEST_UNIT" != ""
            then
                if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/pre_test.sh
                then
                    PRE_TEST_SCRIPT="$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/pre_test.sh
                fi
            fi
            if test "$PRE_TEST_SCRIPT" != ""
            then
                echo "  Pre test script execution"
                pushd "`dirname "$PRE_TEST_SCRIPT"`"
                "$PRE_TEST_SCRIPT" "${TMP_TEST_DIR}/${test_dir}"
                popd # Come back from script folder
            fi

            # Execute the test
            # Compute timeouts
            EXEC_TIMEOUT=3
            ABS_TIMEOUT=

            if test -e exec_timeout
            then
                EXEC_TIMEOUT=1`cat exec_timeout`
            elif "$REF_TEST_UNIT" != ""
            then
                if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/exec_timeout
                then
                    EXEC_TIMEOUT=`cat "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/exec_timeout`
                fi
            fi
            if test -e abs_timeout
            then
                ABS_TIMEOUT=1`cat abs_timeout`
            elif "$REF_TEST_UNIT" != ""
            then
                if test -e "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/abs_timeout
                then
                    ABS_TIMEOUT=`cat "$M_TESTS_FOLDER"/test_units/"$REF_TEST_UNIT"/abs_timeout`
                fi
            fi
            test "$ABS_TIMEOUT" = "" \
                && ABS_TIMEOUT=$(($TIMEOUT_EXEC_ABS_RATIO * $EXEC_TIMEOUT))

            echo "  Timeout set to:
    Exec: $EXEC_TIMEOUT
    Abs:  $ABS_TIMEOUT"

            pushd "${TMP_TEST_DIR}/${test_dir}"
            if test -e "${M_TESTS_FOLDER}/${test_dir}/"test_exec_commands
            then
                echo "  Launch test"
                OLD_IFS="$IFS"
                IFS=','
                while read test_id test_command
                do
                    # TODO: It may be a good idea to re-copy test data to prevent student breaking it

                    IFS="$OLD_IFS"
                    test_id_file="${M_TESTS_FOLDER}/${test_dir}/${test_id}"

                    TEST_ARGS=
                    test -e "${test_id_file}.arg" \
                        && TEST_ARGS=`cat "${test_id_file}.arg"`

                    if test -e "${test_id_file}.in"
                    then
                        cat "${test_id_file}.in" | "$M_MOULETTE_ASSETS/sandbox" \
                            "$TEST_OUT/$test_id.out" \
                            "$TEST_OUT/$test_id.err" \
                            "$TEST_OUT/$test_id.ret" \
                            $USER_ID \
                            "$test_command" $TEST_ARGS \
                            | "$M_MOULETTE_ASSETS/kill_timeout" $EXEC_TIMEOUT $ABS_TIMEOUT
                    else
                        "$M_MOULETTE_ASSETS/sandbox" \
                            "$TEST_OUT/$test_id.out" \
                            "$TEST_OUT/$test_id.err" \
                            "$TEST_OUT/$test_id.ret" \
                            $USER_ID \
                            "$test_command" $TEST_ARGS \
                            | "$M_MOULETTE_ASSETS/kill_timeout" $EXEC_TIMEOUT $ABS_TIMEOUT
                    fi

                    # Kill every remaining processes
                    killall -9 -u "$LOGIN"

                    IFS=','
                done < "${M_TESTS_FOLDER}/${test_dir}/"test_exec_commands
                IFS="$OLD_IFS"
            fi
            popd # Come back from test directory


            # Compute reslut

            if test -e "${M_TESTS_FOLDER}/${test_dir}/"test_exec_commands
            then
                echo "  Computing test results"
                OLD_IFS="$IFS"
                IFS=','
                while read test_id test_command
                do
                    IFS="$OLD_IFS"
                    test_id_file="${M_TESTS_FOLDER}/${test_dir}/${test_id}"
                    test_output_file="$TEST_OUT/${test_id}"
                    test_result_dir="$TEST_RESULT/${test_id}"
                    current_test_result=true
                    error_message=

                    mkdir -p "$test_result_dir"

                    if test -e "$test_id_file.ret"
                    then
                        REF_RET=`cat "$test_id_file.ret"`
                        STU_RET=`cat "$test_output_file.ret"`
                        if test "$REF_RET" != "$STU_RET"
                        then
                            current_test_result=false
                            error_message="${error_message}Wrong exit code: sould be '$REF_RET' but mine is '$STU_RET'\n\n"
                        fi
                    else
                        STU_RET=`cat "$test_output_file.ret"`
                        if test "$STU_RET" -ge 1000
                        then
                            SIGNAL=$(("$STU_RET" - 1000))
                            pushd "$M_MOULETTE_ASSETS"
                            SIGNAL=`./get_sig_by_id.sh "$SIGNAL" "$M_ARCH"`
                            popd
                            current_test_result=false
                            error_message="${error_message}Program received signal '$SIGNAL'\n\n"
                        fi
                    fi
                    if test -e "$test_id_file.out"
                    then
                        DIFF=`diff -u --label ref -label my "$test_id_file.out" "$test_output_file.out"`
                        if $? != 0
                        then
                            current_test_result=false
                            if test ${#DIFF} -lt $M_MAX_DISPLAY_DIFF_LENGTH
                            then
                                error_message="${error_message}Standard outputs differ:\n"
                                error_message="${error_message}${DIFF}\n\n"
                            else
                                error_message="${error_message}Standard outputs differ.\n\n"
                            fi
                        fi
                    fi
                    if test -e "$test_id_file.err"
                    then
                        DIFF=`diff -u --label ref -label my "$test_id_file.err" "$test_output_file.err"`
                        if $? != 0
                        then
                            current_test_result=false
                            if test ${#DIFF} -lt $M_MAX_DISPLAY_DIFF_LENGTH
                            then
                                error_message="${error_message}Error outputs differ:\n"
                                error_message="${error_message}${DIFF}\n\n"
                            else
                                error_message="${error_message}Error outputs differ.\n\n"
                            fi
                        fi
                    fi

                    # Check diff for ref files
                    if test -e "$test_id_file.diff_comp"
                    then
                        #TODO
                        OLD_IFS="$IFS"
                        IFS=','
                        while read ref_file my_file
                        do
                            IFS="$OLD_IFS"
                            ref_file="${M_TESTS_FOLDER}/${test_dir}/$ref_file"
                            my_file="${TMP_TEST_DIR}/${test_dir}/$my_file"
                            DIFF=`diff -u --label ref -label my "$ref_file" "$my_file"`
                            DIFF_RET=$?
                            if "$DIFF_RET" != 0
                            then
                                current_test_result=false
                                if "$DIFF_RET" = 1
                                then
                                    if test ${#DIFF} -lt $M_MAX_DISPLAY_DIFF_LENGTH
                                    then
                                        error_message="${error_message}Output file differ:\n"
                                        error_message="${error_message}${DIFF}\n\n"
                                    else
                                        error_message="${error_message}Output file differ.\n\n"
                                    fi
                                else
                                    error_message="${error_message}Output file has not been created correctly.\n\n"
                                fi
                            fi
                            IFS=','
                        done < "$test_id_file.diff_comp"
                        IFS="$OLD_IFS"
                    else
                        if test -e "$test_id_file.ref"
                        then
                            DIFF=`diff -u --label ref -label my "$test_id_file.ref" "${TMP_TEST_DIR}/${test_dir}/${test_id}.my"`
                            DIFF_RET=$?
                            if "$DIFF_RET" != 0
                            then
                                current_test_result=false
                                if "$DIFF_RET" = 1
                                then
                                    if test ${#DIFF} -lt $M_MAX_DISPLAY_DIFF_LENGTH
                                    then
                                        error_message="${error_message}Output file differ:\n"
                                        error_message="${error_message}${DIFF}\n\n"
                                    else
                                        error_message="${error_message}Output file differ.\n\n"
                                    fi
                                else
                                    error_message="${error_message}Output file has not been created correctly.\n\n"
                                fi
                            fi
                        fi
                    fi


                    if $current_test_result
                    then
                        echo PASS > "${test_result_dir}/test.result"
                    else
                        echo FAIL > "${test_result_dir}/test.result"
                        echo "$error_message" > "${test_result_dir}/test.error"
                    fi

                    IFS=','
                done < "${M_TESTS_FOLDER}/${test_dir}/"test_exec_commands
                IFS="$OLD_IFS"
            fi


            COMPUTE_RESULT=
            test -e "${M_TESTS_FOLDER}/${test_dir}/compute_result.sh" \
                && COMPUTE_RESULT="${M_TESTS_FOLDER}/${test_dir}/compute_result.sh" \
                || test -e "$M_TESTS_FOLDER/test_units/$REF_TEST_UNIT/compute_result.sh" \
                && COMPUTE_RESULT="$M_TESTS_FOLDER/test_units/$REF_TEST_UNIT/compute_result.sh"

            if "$COMPUTE_RESULT" != ""
            then
                pushd "$TEST_RESULT"

                # This script must generate the test.result file and may generate a test.error file
                #  Param1: Path to the test dir (ref)
                #  Param2: Path to the output dir
                #  Param3: Path to the test exec dir
                "COMPUTE_RESULT"                        \
                    "${M_TESTS_FOLDER}/${test_dir}"     \
                    "${TEST_OUT}"                       \
                    "${TMP_TEST_DIR}/${test_dir}"

                popd # Come back from test result folder
            fi


            if "$M_LIMIT_DISK_USAGE"
            then
                rm -rf ${TMP_TEST_DIR}/${test_dir}
            fi
        else
            echo "  -> Failed: Unable to find compilation unit '${REF_COMP_UNIT}'"
            echo FAIL > "$TEST_RESULT"/test.result
            echo "Compilation failed" > "$TEST_RESULT"/test.error

            if test -e "${USER_COMP_DIR}/${REF_COMP_UNIT}".error
            then
                cat "${USER_COMP_DIR}/${REF_COMP_UNIT}".error >> "$TEST_RESULT"/test.error
            fi
        fi
        popd
    done
    popd # Come back from $M_TESTS_FOLDER


    # Generate trace
    "$M_MOULETTE_ASSETS"/gen_trace.sh "$1" "$LOGIN" "$TESTS_RESULTS"
fi

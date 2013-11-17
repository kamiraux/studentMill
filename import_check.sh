#! /usr/bin/env bash

if test $# -lt 2
then
    echo "Usage: $0 FILE AUTH" >&2
    exit 1
fi


FILE="$1"
AUTH="$2"

EXPORTED_FUNCTIONS=$(nm -g "$FILE" \
    | grep -E ' (T|B) ' \
    | cut -d ' ' -f 3 \
    | sed -e ':a
N
$!ba
s/\n/|/g')

USED_FUNCTIONS=$(nm -g -u "$FILE" \
    | sed 's/ *//' \
    | grep 'U.*' \
    | cut -d " " -f 2 \
    | grep '^[a-zA-Z].*' \
    | cut -d '@' -f 1)

AUTH_FUN_REGEX=$(sed -e ':a
N
$!ba
s/\n/|/g
s/*/.*/g' "$AUTH")


for fun in $USED_FUNCTIONS
do
    echo "$fun" | grep -E "$AUTH_FUN_REGEX" > /dev/null \
        || echo "$fun" | grep -E "$EXPORTED_FUNCTIONS" > /dev/null \
        || echo "$fun"
done

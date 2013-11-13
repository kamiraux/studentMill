#! /bin/sh

FILE="$1"
AUTH="$2"

USED_FUNCTIONS=$(nm -g -u "$FILE" \
    | sed 's/ *//' \
    | grep 'U.*' \
    | cut --delimiter=" " -f 2 \
    | grep '^[a-zA-Z].*' \
    | cut --delimiter='@' -f 1)

AUTH_FUN_REGEX=$(sed -e ':a
N
$!ba
s/\n/|/g
s/*/.*/g' "$AUTH")


for fun in $USED_FUNCTIONS
do
    echo "$fun" | grep -E "$AUTH_FUN_REGEX" > /dev/null || echo "$fun"
done

CC=gcc
#CPPFLAGS=
#CFLAGS=
#LDFLAGS=

-include rules.mk

SRC=$(wildcard *.c)
OBJS=${SRC:.c=.o}

common_compilation: ${OBJS}


test_compilation: test_bin

test_bin: SRC=$(wildcard ${TEST_DIR}/*.c)
test_bin: OBJS=${SRC:.c=.o}
test_bin: ${OBJS} ${COMP_UNIT_DIR}/some_dependency.a
	${CC} -o $@ $^

# Makefile
CC=gcc
CPPFLAGS+=
CFLAGS+=
LDFLAGS+=

SAND_SRC=sandbox.c
SAND_OBJS=${SAND_SRC:.c=.o}

all: sandbox


clean:
	${RM} sandbox

# END

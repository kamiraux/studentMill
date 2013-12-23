# Makefile

CC?=gcc
CPPFLAGS+=
CFLAGS+=
LDFLAGS+=

SAND_SRC=modules/isolation/sandbox.c
SAND_OBJS=${SAND_SRC:.c=.o}

PARA_SRC=modules/parallelism/parallel.c
PARA_OBJS=${PARA_SRC:.c=.o}

TARGETS=exe/sandbox exe/parallel

all: ${TARGETS}

exe/sandbox: ${SAND_OBJS}
	${CC} ${LDFLAGS} -o $@ $^

exe/parallel: ${PARA_OBJS}
	${CC} ${LDFLAGS} -o $@ $^

doc: doc/index.html

index.html: README
	mkdir -p doc
	pandoc -f markdown -t html -o index.html $^

clean:
	${RM} ${TARGETS}
	${RM} -r doc

.PHONY: doc

# END

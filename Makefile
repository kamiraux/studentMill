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

doc/index.html: README
	mkdir -p doc
	pandoc -f markdown -t html --email-obfuscation=references --number-sections --toc --toc-depth=3 -o $@ $^

clean:
	${RM} ${TARGETS}
	${RM} -r doc

.PHONY: doc

# END

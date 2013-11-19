# Makefile used for paralellism

#STUDENTS= titi tata toto tutu tete bla blo bli
STUDENTS=$(shell cat ${STUDENTS_FILE})

launch: ${STUDENTS}

${STUDENTS}:
	@echo $@
	@${MOULETTE_ASSETS}/launch_student.sh ${CONFIG_ABS} $@ > ${LOG}_$@.log 2>&1

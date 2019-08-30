# $OpenBSD$

PROGS =			mcsend mcrecv
WARNINGS =		Yes
CLEANFILES =		*.log
REGRESS_TARGETS =
MSG !!=			echo $$RANDOM

REGRESS_TARGETS +=	run-localhost
run-localhost:
	@echo '======== $@ ========'
	./mcrecv -i 127.0.0.1 -t 5 >recv.log -- \
	./mcsend -i 127.0.0.1 -m '${MSG}' >send.log
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-loop
run-localhost-loop:
	@echo '======== $@ ========'
	./mcrecv -i 127.0.0.1 -t 5 >recv.log -- \
	./mcsend -i 127.0.0.1 -l 1 -m '${MSG}' >send.log
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-noloop
run-localhost-noloop:
	@echo '======== $@ ========'
	./mcrecv -i 127.0.0.1 -t 2 >recv.log -- \
	./mcsend -i 127.0.0.1 -l 0 -m '${MSG}' >send.log
	grep '> ${MSG}$$' send.log
	! grep '< ${MSG}$$' recv.log

.include <bsd.regress.mk>

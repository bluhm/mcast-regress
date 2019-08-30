# $OpenBSD$

PROGS =			mcsend mcrecv
WARNINGS =		Yes
CLEANFILES =		*.log
REGRESS_TARGETS =
MSG !!=			echo $$RANDOM


REGRESS_TARGETS +=	run-loopback
run-loopback:
	./mcrecv -t 5 >recv.log &
	./mcsend -m '${MSG}' >send.log
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

.include <bsd.regress.mk>

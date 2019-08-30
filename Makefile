# $OpenBSD$

PROGS =		mcsend mcrecv
WARNINGS =	Yes

REGRESS_TARGETS =
REGRESS_TARGETS +=	run-loopback
run-loopback:
	./mcrecv -t 5 >recv.log &
	./mcsend >send.log
	grep foo send.log
	grep foo recv.log

.include <bsd.regress.mk>

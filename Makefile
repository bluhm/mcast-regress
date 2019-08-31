# $OpenBSD$

PROGS =			mcsend mcrecv
WARNINGS =		Yes
CLEANFILES =		*.log
REGRESS_TARGETS =
MSG !!=			echo $$RANDOM

REGRESS_TARGETS +=	run-localhost
run-localhost:
	@echo '\n======== $@ ========'
	# send over localhost interface
	./mcrecv -f recv.log -i 127.0.0.1 -r 5 -- \
	./mcsend -f send.log -i 127.0.0.1 -m '${MSG}'
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-loop
run-localhost-loop:
	@echo '\n======== $@ ========'
	# explicitly enable loop back on multicast interface
	./mcrecv -f recv.log -i 127.0.0.1 -r 5 -- \
	./mcsend -f send.log -i 127.0.0.1 -l 1 -m '${MSG}'
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-noloop
run-localhost-noloop:
	@echo '\n======== $@ ========'
	# disable loop back on multicast interface, must fail
	./mcrecv -f recv.log -i 127.0.0.1 -n 1 -- \
	./mcsend -f send.log -i 127.0.0.1 -l 0 -m '${MSG}'
	grep '> ${MSG}$$' send.log
	! grep '< ' recv.log

REGRESS_TARGETS +=	run-localhost-ttl0
run-localhost-ttl0:
	@echo '\n======== $@ ========'
	# send over localhost interface
	./mcrecv -f recv.log -i 127.0.0.1 -r 5 -- \
	./mcsend -f send.log -i 127.0.0.1 -m '${MSG}' -t 0
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

.include <bsd.regress.mk>

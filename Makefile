# $OpenBSD: Makefile,v 1.1.1.1 2019/09/05 01:50:34 bluhm Exp $

PROGS =			mc6send mc6recv mc6route
WARNINGS =		Yes
CLEANFILES =		stamp-* *.log
MSG !!=			echo $$RANDOM

SEND =		${.OBJDIR}/mc6send
RECV =		${.OBJDIR}/mc6recv
ROUTE =		${.OBJDIR}/mc6route
LOCALHOST =	lo0
LOCAL =		${LOCAL_IF}
REMOTE =	${REMOTE_IF}
OTHER =		${OTHER_IF}
TARGET =	${TARGET_IF}
GROUP_LOCAL =	ff02::123

# Currently sending link-local packets via loopback does not work
# due to wrong scope id.  This has to be investigated.
REGRESS_EXPECTED_FAILURES = run-localhost-local

REGRESS_SETUP_ONCE =	setup-sudo
setup-sudo:
	${SUDO} true
.if ! empty(REMOTE_SSH)
	ssh -t ${REMOTE_SSH} ${SUDO} true
.endif
.if ! empty(TARGET_SSH)
	ssh -t ${TARGET_SSH} ${SUDO} true
.endif

REGRESS_TARGETS +=	run-localhost
run-localhost:
	@echo '\n======== $@ ========'
	# send over localhost interface
	${RECV} -f recv.log -i ${LOCALHOST} -r 5 -- \
	${SEND} -f send.log -i ${LOCALHOST} -m '${MSG}'
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-loop
run-localhost-loop:
	@echo '\n======== $@ ========'
	# explicitly enable loop back on multicast interface
	${RECV} -f recv.log -i ${LOCALHOST} -r 5 -- \
	${SEND} -f send.log -i ${LOCALHOST} -l 1 -m '${MSG}'
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-loop0
run-localhost-loop0:
	@echo '\n======== $@ ========'
	# disable loop back on multicast interface, must fail
	${RECV} -f recv.log -i ${LOCALHOST} -n 1 -- \
	${SEND} -f send.log -i ${LOCALHOST} -l 0 -m '${MSG}'
	grep '> ${MSG}$$' send.log
	! grep '< ' recv.log

REGRESS_TARGETS +=	run-localhost-ttl0
run-localhost-ttl0:
	@echo '\n======== $@ ========'
	# send over localhost interface
	${RECV} -f recv.log -i ${LOCALHOST} -r 5 -- \
	${SEND} -f send.log -i ${LOCALHOST} -m '${MSG}' -t 0
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localhost-local
run-localhost-local:
	@echo '\n======== $@ ========'
	# send over localhost interface
	${RECV} -f recv.log -g ${GROUP_LOCAL} -i ${LOCALHOST} -r 5 -- \
	${SEND} -f send.log -g ${GROUP_LOCAL} -i ${LOCALHOST} -m '${MSG}' -t 0
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localaddr
run-localaddr:
	@echo '\n======== $@ ========'
	# send over a local physical interface
	${RECV} -f recv.log -i ${LOCAL} -r 5 -- \
	${SEND} -f send.log -i ${LOCAL} -m '${MSG}'
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localaddr-loop0
run-localaddr-loop0:
	@echo '\n======== $@ ========'
	# send over physical interface to loopback, ttl is 0
	${RECV} -f recv.log -i ${LOCAL} -n 1 -- \
	${SEND} -f send.log -i ${LOCAL} -l 0 -m '${MSG}'
	grep '> ${MSG}$$' send.log
	! grep '< ' recv.log

REGRESS_TARGETS +=	run-localaddr-ttl0
run-localaddr-ttl0:
	@echo '\n======== $@ ========'
	# send over physical interface to loopback, ttl is 0
	${RECV} -f recv.log -i ${LOCAL} -r 5 -- \
	${SEND} -f send.log -i ${LOCAL} -m '${MSG}' -t 0
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-localaddr-local
run-localaddr-local:
	@echo '\n======== $@ ========'
	# send over physical interface to loopback, ttl is 0
	${RECV} -f recv.log -g ${GROUP_LOCAL} -i ${LOCAL} -r 5 -- \
	${SEND} -f send.log -g ${GROUP_LOCAL} -i ${LOCAL} -m '${MSG}' -t 0
	grep '> ${MSG}$$' send.log
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-remoteaddr
run-remoteaddr:
	@echo '\n======== $@ ========'
	# send over a local physical interface
	${RECV} -f recv.log -i ${LOCAL} -r 5 -- \
	ssh ${REMOTE_SSH} ${SEND} -f ${.OBJDIR}/send.log \
	    -i ${REMOTE} -m '${MSG}'
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-remoteaddr-loop0
run-remoteaddr-loop0:
	@echo '\n======== $@ ========'
	# send over a local physical interface
	${RECV} -f recv.log -i ${LOCAL} -r 5 -- \
	ssh ${REMOTE_SSH} ${SEND} -f ${.OBJDIR}/send.log \
	    -i ${REMOTE} -l 0 -m '${MSG}'
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-remoteaddr-ttl0
run-remoteaddr-ttl0:
	@echo '\n======== $@ ========'
	# send over a local physical interface
	${RECV} -f recv.log -i ${LOCAL} -n 2 -- \
	ssh ${REMOTE_SSH} ${SEND} -f ${.OBJDIR}/send.log \
	    -i ${REMOTE} -m '${MSG}' -t 0
	! grep '< ' recv.log

REGRESS_TARGETS +=	run-forward
run-forward:
	@echo '\n======== $@ ========'
	# start multicast router, start receiver, start sender
	ssh ${REMOTE_SSH} ${SUDO} pkill mcroute mc6route || true
	ssh ${REMOTE_SSH} ${SUDO} ${ROUTE} -f ${.OBJDIR}/route.log \
	    -b -i ${OTHER} -o ${REMOTE} -r 5
.if empty(TARGET_SSH)
	${RECV} -f recv.log -i ${LOCAL} -r 5 -- \
	${SEND} -f send.log \
	    -i ${TARGET} -l 0 -m '${MSG}' -t 2
	grep '> ${MSG}$$' send.log
.else
	${RECV} -f recv.log -i ${LOCAL} -r 5 -- \
	ssh ${TARGET_SSH} ${SEND} -f ${.OBJDIR}/send.log \
	    -i ${TARGET} -l 0 -m '${MSG}' -t 2
.endif
	grep '< ${MSG}$$' recv.log

REGRESS_TARGETS +=	run-forward-ttl1
run-forward-ttl1:
	@echo '\n======== $@ ========'
	# try to get ttl 1 over multicast router, must fail
	ssh ${REMOTE_SSH} ${SUDO} pkill mcroute mc6route || true
	ssh ${REMOTE_SSH} ${SUDO} ${ROUTE} -f ${.OBJDIR}/route.log \
	    -b -i ${OTHER} -o ${REMOTE} -n 3
.if empty(TARGET_SSH)
	${RECV} -f recv.log -i ${LOCAL} -n 2 -- \
	${SEND} -f send.log \
	    -i ${TARGET} -l 0 -m '${MSG}' -t 1
	grep '> ${MSG}$$' send.log
.else
	${RECV} -f recv.log -i ${LOCAL} -n 2 -- \
	ssh ${TARGET_SSH} ${SEND} -f ${.OBJDIR}/send.log \
	    -i ${TARGET} -l 0 -m '${MSG}' -t 1
.endif
	! grep '< ' recv.log

REGRESS_TARGETS +=	run-forward-local
run-forward-local:
	@echo '\n======== $@ ========'
	# try to get local multicast group over router, must fail
	ssh ${REMOTE_SSH} ${SUDO} pkill mcroute mc6route || true
	ssh ${REMOTE_SSH} ${SUDO} ${ROUTE} -f ${.OBJDIR}/route.log \
	    -b -g ${GROUP_LOCAL} -i ${OTHER} -o ${REMOTE} -n 3
.if empty(TARGET_SSH)
	${RECV} -f recv.log -g ${GROUP_LOCAL} -i ${LOCAL} -n 2 -- \
	${SEND} -f send.log \
	    -g ${GROUP_LOCAL} -i ${TARGET} -l 0 -m '${MSG}' -t 2
	grep '> ${MSG}$$' send.log
.else
	${RECV} -f recv.log -g ${GROUP_LOCAL} -i ${LOCAL} -n 2 -- \
	ssh ${TARGET_SSH} ${SEND} -f ${.OBJDIR}/send.log \
	    -g ${GROUP_LOCAL} -i ${TARGET} -l 0 -m '${MSG}' -t 2
.endif
	! grep '< ' recv.log

stamp-remote-build:
	ssh ${REMOTE_SSH} ${MAKE} -C ${.CURDIR} ${PROGS}
	date >$@

stamp-target-build:
	ssh ${TARGET_SSH} ${MAKE} -C ${.CURDIR} ${PROGS}
	date >$@

${REGRESS_TARGETS}: ${PROGS}
${REGRESS_TARGETS:M*-remoteaddr*}: stamp-remote-build
${REGRESS_TARGETS:M*-forward*}: stamp-remote-build
.if ! empty(TARGET_SSH)
${REGRESS_TARGETS:M*-forward*}: stamp-target-build
.endif

.if empty(LOCAL)
REGRESS_SKIP_TARGETS +=	${REGRESS_TARGETS:M*-localaddr*}
REGRESS_SKIP_TARGETS +=	${REGRESS_TARGETS:M*-remoteaddr*}
REGRESS_SKIP_TARGETS +=	${REGRESS_TARGETS:M*-forward*}
.endif
.if empty(REMOTE) || empty(REMOTE_SSH)
REGRESS_SKIP_TARGETS +=	${REGRESS_TARGETS:M*-remoteaddr*}
REGRESS_SKIP_TARGETS +=	${REGRESS_TARGETS:M*-forward*}
.endif
.if empty(OTHER) || empty(TARGET)
REGRESS_SKIP_TARGETS +=	${REGRESS_TARGETS:M*-forward*}
.endif

check-setup:
	! ssh ${REMOTE_SSH} route -n get 224/4
	ssh ${REMOTE_SSH} sysctl net.inet.ip.mforwarding | fgrep =1
	ssh ${REMOTE_SSH} sysctl net.inet6.ip6.mforwarding | fgrep =1

.include <bsd.regress.mk>

stamp-remote-build: ${SRCS}
stamp-target-build: ${SRCS}

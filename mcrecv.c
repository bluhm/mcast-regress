/*	$OpenBSD$	*/
/*
 * Copyright (c) 2019 Alexander Bluhm <bluhm@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/socket.h>

#include <arpa/inet.h>
#include <netinet/in.h>

#include <err.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void __dead usage(void);

void __dead
usage(void)
{
	fprintf(stderr,
"mcrecv [-b] [-g group] [-i ifaddr] [-p port] [-t timeout]\n"
"    -b              fork to background\n"
"    -g group        multicast group\n"
"    -i ifaddr       multicast interface address\n"
"    -p port         destination port number\n"
"    -t timeout      timeout in seconds\n");
	exit(2);
}

int
main(int argc, char *argv[])
{
	struct sockaddr_in sin;
	struct ip_mreq mreq;
	const char *errstr, *group, *ifaddr;
	char msg[256];
	ssize_t n;
	int ch, s, back, port;
	unsigned int timeout;

	back = 0;
	group = "224.0.0.123";
	ifaddr = "0.0.0.0";
	port = 12345;
	timeout = 0;
	while ((ch = getopt(argc, argv, "bg:i:p:t:")) != -1) {
		switch (ch) {
		case 'b':
			back = 1;
		case 'g':
			group = optarg;
			break;
		case 'i':
			ifaddr = optarg;
			break;
		case 'p':
			port= strtonum(optarg, 1, 0xffff, &errstr);
			if (errstr != NULL)
				errx(1, "port is %s: %s", errstr, optarg);
			break;
		case 't':
			timeout = strtonum(optarg, 1, INT_MAX, &errstr);
			if (errstr != NULL)
				errx(1, "timeout is %s: %s", errstr, optarg);
			break;
		default:
			usage();
		}
	}
	argc -= optind;
	argv += optind;
	if (argc)
		usage();

	s = socket(AF_INET, SOCK_DGRAM, 0);
	if (s == -1)
		err(1, "socket");
	if (inet_pton(AF_INET, group, &mreq.imr_multiaddr) == -1)
		err(1, "inet_pton %s", group);
	if (inet_pton(AF_INET, ifaddr, &mreq.imr_interface) == -1)
		err(1, "inet_pton %s", ifaddr);
	if (setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq,
	    sizeof(mreq)) == -1)
		err(1, "setsockopt IP_ADD_MEMBERSHIP %s %s", group, ifaddr);

	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	sin.sin_port = htons(port);
	if (inet_pton(AF_INET, group, &sin.sin_addr) == -1)
		err(1, "inet_pton %s", group);
	if (bind(s, (struct sockaddr *)&sin, sizeof(sin)) == -1)
		err(1, "bind %s:%d", group, port);

	if (back) {
		switch (fork()) {
		case -1:
			err(1, "fork");
		case 0:
			break;
		default:
			_exit(0);
		}
	}
	if (timeout) {
		if (alarm(timeout) == (unsigned  int)-1)
			err(1, "alarm %u", timeout);
	}
	n = recv(s, msg, sizeof(msg) - 1, 0);
	if (n == -1)
		err(1, "recv");
	msg[n] = '\0';
	printf("<<< %s\n", msg);

	return 0;
}

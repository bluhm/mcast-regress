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
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void __dead usage(void);

void __dead
usage(void)
{
	fprintf(stderr, "mcsend [-i ifaddr] [-g group] [-p port]\n"
	    "    -i ifaddr       multicast interface address\n"
	    "    -g group        multicast group\n"
	    "    -p port         destination port number\n");
	exit(2);
}

int
main(int argc, char *argv[])
{
	struct sockaddr_in sin;
	const char *errstr, *ifaddr, *group, *port;
	ssize_t n;
	int ch, s, pnum;

	ifaddr = NULL;
	group = "224.0.0.123";
	port = "12345";
	while ((ch = getopt(argc, argv, "g:i:p:")) != -1) {
		switch (ch) {
		case 'g':
			group = optarg;
			break;
		case 'i':
			ifaddr = optarg;
			break;
		case 'p':
			port = optarg;
			break;
		default:
			usage();
		}
	}
	argc -= optind;
	argv += optind;

	s = socket(AF_INET, SOCK_DGRAM, 0);
	if (s == -1)
		err(1, "socket");
	if (ifaddr != NULL) {
		struct in_addr addr;

		if (inet_pton(AF_INET, ifaddr, &addr) == -1)
			err(1, "inet_pton %s", ifaddr);
		if (setsockopt(s, IPPROTO_IP, IP_MULTICAST_IF, &addr,
		    sizeof(addr)) == -1)
			err(1, "setsockopt IP_MULTICAST_IF %s", ifaddr);
	}

	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	pnum = strtonum(port, 1, 0xffff, &errstr);
	if (errstr != NULL)
		errx(1, "port number is %s: %s", errstr, port);
	sin.sin_port = htons(pnum);
	if (inet_pton(AF_INET, group, &sin.sin_addr) == -1)
		err(1, "inet_pton %s", group);
	if (connect(s, (struct sockaddr *)&sin, sizeof(sin)) == -1)
		err(1, "connect %s:%d", group, pnum);

	n = send(s, "foo\n", 4, 0);
	if (n == -1)
		err(1, "send");
	if (n != 4)
		errx(1, "send %zd", n);

	return 0;
}

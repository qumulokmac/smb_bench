#!/usr/bin/env python3
# Copyright (c) 2020 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.

# qumulo_python_versions = { 2, 3 }

from __future__ import print_function

"""
This script provides a relatively simple TCP-based distributed barrier:
multiple instances can be run on different machines and they will all
block until an expected number are present and accounted for.

The same <master> and <count> must be passed to every instance.

The --local=N option is an optimization for the case when a large number of
processes will participate in the barrier on only a few machines. Rather
that have every process form a separate connection to the master host,
which can make the barrier sluggish, all processes that share a host will
connect to one process on that host - and these "local masters" will
then coordinate with the <master> host to complete the barrier.

If --local=N is used, <count> must be equal to the number of distinct host
machines participating in the barrier, since just one process on each
host will participate in remote synchronization. The value of N determines
how many processes on each host must participate in order to clear the
barrier. A different value of N may be used for each host.

Example:

    Run on machine with ip 10.0.1.42    |   Run on machine with ip 10.0.1.43
    ------------------------------------+-----------------------------------
    $ barrier.py 10.0.1.42 2 -l 3 &     |   $ barrier.py 10.0.1.42 2 -l 2 &
    $ barrier.py 10.0.1.42 2 -l 3 &     |   $ sleep 10
    $ barrier.py 10.0.1.42 2 -l 3 &     |   $ barrier.py 10.0.1.42 2 -l 2

If the above command sequences are run starting at the same time, all the
barrier.py processes on both machines will remain blocked until the
second barrier.py instance on duc43 runs. Note the different numbers of local
participants.
"""

# XXX qitah: this script has to run in a standard python environment
# outside our toolchain, so it only depends on built-in libraries.
import argparse
import logging
import os
import socket
import subprocess
import threading
import time


def current_machine_is_master(master_ip):
    # `hostname -I` gives us all the configured addresses on all network
    # interfaces on the local machine, except for loopback interface and IPv6 link-local
    # addresses. The returned addresses don't guarantee any specific ordering so
    # we will check against all of them.
    ips = (
        subprocess.check_output(['hostname', '-I'], encoding='UTF-8')
        .rstrip()
        .split(' ')
    )
    logging.info('Local machine ip addrs: {}, master ip {}'.format(ips, master_ip))
    return any(master_ip == ip for ip in ips)


def server(ip, port, count, timeout, before_proceed=None):
    """
    Listen on @a port; after exactly @a count connections, send a short
    message to all of them, then close the sockets. If @a before_proceed
    is not None, call it before responding to connected clients.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.settimeout(timeout)

    # Silently ignore EADDRINUSE; only one process on the master host
    # needs to listen for connections from peers.
    try:
        s.bind((ip, port))
        s.listen(count)
    except socket.error as e:
        if e.errno != 98:
            raise
        return

    logging.info('[barrier] listening on {}:{}.'.format(ip, port))
    connections = []

    while len(connections) < count:
        conn, addr = s.accept()
        connections.append(conn)

        # Accepting a little bit of data from the client seems to prevent
        # noisy "connection reset by peer" errors in the client processes.
        conn.recv(1)

        logging.info(
            '[barrier] accepted connection {}/{} from {}:{}'.format(
                len(connections), count, *addr
            )
        )

    if before_proceed is not None:
        before_proceed()

    for conn in connections:
        conn.sendall(b'!')

    for conn in connections:
        conn.shutdown(1)
        conn.close()

    s.shutdown(1)
    s.close()

    logging.info('[barrier] cleaned up')


def start_server(ip, port, count, timeout, before_proceed=None):
    server_thread = threading.Thread(
        target=server, args=(ip, port, count, timeout, before_proceed)
    )

    server_thread.start()


def barrier_wait(host, port, timeout):
    """
    Attempt to connect to @a host at @a port until a connection is accepted.
    Once connected, wait for the server to send anything at all and return.
    Raise an exception if this does not happen within @a timeout seconds.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Poll until master becomes available
    connected = False
    elapsed = 0
    start = time.time()
    while elapsed < timeout:
        try:
            s.connect((host, port))
            connected = True
            break
        except socket.error:
            time.sleep(0.1)
        elapsed = time.time() - start

    s.settimeout(timeout - elapsed)

    if not connected:
        raise RuntimeError('timed out connecting to master')

    logging.info('[waiter] connected - waiting on {}:{}'.format(host, port))
    s.sendall(b'?')
    response = s.recv(1)
    if response == b'!':
        logging.info('[waiter] cleared barrier {}:{}.'.format(host, port))
    else:
        raise RuntimeError('invalid response received: {}'.format(response))


def main(opt):
    if opt.logdir is not None:
        logpath = os.path.join(opt.logdir, 'barrier.{}.log'.format(os.getpid()))
        print('Logging to {}'.format(logpath))
    else:
        logpath = None

    logging.basicConfig(
        format='%(asctime)s: %(message)s',
        level=logging.INFO,
        filename=logpath,
        filemode='w',
    )

    # Start the remote (master) barrier server.
    if current_machine_is_master(opt.master):
        start_server(opt.master, opt.port, opt.count, opt.timeout)

    if opt.local is not None:
        # Start the local barrier server. It waits for all local participants
        # to arrive, then blocks on contacting the remote barrier server.
        start_server(
            '127.0.0.1',
            opt.local_port,
            int(opt.local),
            opt.timeout,
            lambda: barrier_wait(opt.master, opt.port, opt.timeout),
        )
        barrier_wait('localhost', opt.local_port, opt.timeout)
    else:
        barrier_wait(opt.master, opt.port, opt.timeout)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__
    )

    parser.add_argument(
        'master', type=str, help='IP of one participant to coordinate the barrier.',
    )

    parser.add_argument(
        'count',
        type=int,
        help='Number of participants that must reach the barrier in order '
        'for all participants to proceed.',
    )

    parser.add_argument(
        '-l',
        '--local',
        metavar='N',
        dest='local',
        type=int,
        default=None,
        help='Use a local barrier expecting N processes on the local host. '
        'Recommended if a large number of participants will run on '
        'one machine',
    )

    parser.add_argument(
        '--port',
        dest='port',
        type=int,
        default=31337,
        help='Use this port for the barrier server. [default: 31337]',
    )

    parser.add_argument(
        '--local-port',
        metavar='PORT',
        dest='local_port',
        type=int,
        default=31338,
        help='Use this port for local barrier server. [default: 31338]',
    )

    parser.add_argument(
        '--timeout',
        metavar='SECONDS',
        dest='timeout',
        type=int,
        default='10',
        help='Exit with status 1 after this duration if unable to connect '
        'or receive response from barrier server. [default: 10]',
    )

    parser.add_argument(
        '--logdir',
        metavar='PATH',
        dest='logdir',
        type=str,
        default=None,
        help='If specified, log activity in a file named "barrier.{pid}.log".',
    )

    try:
        main(parser.parse_args())
    except Exception as e:
        logging.exception(e)
        raise

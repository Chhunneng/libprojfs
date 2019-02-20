#!/bin/sh
#
# Copyright (C) 2018-2019 GitHub, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/ .

test_description='projfs file operation locking tests

Check that projfs file operation notification events are issued serially for a
given path.
'

. ./test-lib.sh

projfs_start test_projfs_handlers source target \
	--timeout 1 --lock-file lock || exit 1

# Since a system daemon may trigger a projection, and if not, our wait_mount
# will have done so, we need to reset the top-level directory's projection
# flag after we suspect all the daemons have probed the new mount point.
# TODO: Define and use a projected subdir instead (when proj lists are ready).
sleep 1
setfattr -n user.projection.empty -v 0x01 source

test_expect_success 'test concurrent access does not trigger failure' '
	projfs_exec_twice ls target
'

projfs_stop || exit 1

test_expect_success 'check no event error messages' '
	test_must_be_empty test_projfs_handlers.err
'

# TODO: Use '--timeout 2' and add '--lock-timeout 1', and pass the latter
#	flag to projfs to override the PROJ_WAIT_MSEC default of 5 secs.
projfs_start test_projfs_handlers source target \
	--timeout 6 --lock-file lock || exit 1

# TODO: Define and use a projected subdir instead (when proj lists are ready).
sleep 1
setfattr -n user.projection.empty -v 0x01 source

test_expect_success 'test concurrent access does trigger failure' '
	test_must_fail projfs_exec_twice ls target
'

projfs_stop || exit 1

test_expect_success 'check no event error messages' '
	test_must_be_empty test_projfs_handlers.err
'

# TODO: Instead of expecting to see this in the output from 'ls', create a
#	simple helper program to just run a given syscall like opendir()
#	and report strerror(errno), and then use that instead of 'ls' above.
err=$("$TEST_DIRECTORY"/get_strerror EAGAIN);

test_expect_success 'check all command error messages' '
	grep -q "$err" "$EXEC_ERR"
'

test_done


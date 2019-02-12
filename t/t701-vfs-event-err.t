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

test_description='projfs VFS API file operation event handler error tests

Check that projfs file operation notification and permission request
events respond to handler errors through the VFS API.
'

. ./test-lib.sh
. "$TEST_DIRECTORY"/test-lib-event.sh

projfs_start test_vfsapi_handlers source target --retval-file retval || exit 1
echo EOutOfMemory > retval

# TODO: we expect mkdir to create a dir despite the handler error and
#	regardless of mkdir's failure exit code
projfs_event_printf error ENOMEM vfs create_dir d1
test_expect_success 'test event handler error on directory creation' '
	test_must_fail projfs_event_exec mkdir target/d1 &&
	test_path_is_dir target/d1
'

# TODO: we expect touch to create a file despite the handler error and
#	to not report a failure exit code
projfs_event_printf error ENOMEM vfs create_file f1.txt
test_expect_success 'test event handler error on file creation' '
	test_might_fail projfs_event_exec touch target/f1.txt &&
	test_path_is_file target/f1.txt
'

projfs_event_printf error ENOMEM vfs delete_file f1.txt
test_expect_success 'test event handler error on file deletion' '
	test_must_fail projfs_event_exec rm target/f1.txt &&
	test_path_is_file target/f1.txt
'

projfs_event_printf error ENOMEM vfs delete_dir d1
test_expect_success 'test event handler error on directory deletion' '
	test_must_fail projfs_event_exec rmdir target/d1 &&
	test_path_is_dir target/d1
'

rm retval
projfs_stop || exit 1

test_expect_success 'check all event notifications' '
	test_cmp test_vfsapi_handlers.log "$EVENT_LOG"
'

test_expect_success 'check all event error messages' '
	test_cmp test_vfsapi_handlers.err "$EVENT_ERR"
'

test_done


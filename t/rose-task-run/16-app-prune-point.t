#!/bin/bash
#-------------------------------------------------------------------------------
# Copyright (C) 2012-2019 British Crown (Met Office) & Contributors.
#
# This file is part of Rose, a framework for meteorological suites.
#
# Rose is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Rose is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Rose. If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------
# Test "rose_prune" built-in application:
# Prune items at a fixed cycle point, instead of an offset against the current.
# Prune items in a location other than datac or work.
#-------------------------------------------------------------------------------
. $(dirname $0)/test_header
skip_all "TEST-DISABLED: Awaiting App upgrade to Python3"
tests 2

export ROSE_CONF_PATH=
mkdir -p "${HOME}/cylc-run"
SUITE_RUN_DIR=$(mktemp -d --tmpdir="${HOME}/cylc-run" 'rose-test-battery.XXXXXX')
NAME="$(basename "${SUITE_RUN_DIR}")"
#-------------------------------------------------------------------------------
TEST_KEY="${TEST_KEY_BASE}"
run_pass "${TEST_KEY}" \
    rose suite-run -C "${TEST_SOURCE_DIR}/${TEST_KEY_BASE}" --name="${NAME}" \
    --no-gcontrol --host='localhost' --debug -- --no-detach --debug

TEST_KEY="${TEST_KEY_BASE}-prune.log"
sed 's/[0-9]*-[0-9]*-[0-9]*T[0-9]*:[0-9]*:[0-9]*+[0-9]*/YYYY-MM-DDTHHMM/g'\
    "${SUITE_RUN_DIR}/prune.log" > stamp-removed.log

sed '/^\[INFO\] YYYY-MM-DDTHHMM export ROSE_TASK_CYCLE_TIME=/p;
    /^\[INFO\] YYYY-MM-DDTHHMM delete: /!d' \
    "stamp-removed.log" >'edited-prune.log'
file_cmp "${TEST_KEY}" 'edited-prune.log' <<__LOG__
[INFO] YYYY-MM-DDTHHMM export ROSE_TASK_CYCLE_TIME=19900101T0000Z
[INFO] YYYY-MM-DDTHHMM delete: var/19700101T0000Z/a.file
[INFO] YYYY-MM-DDTHHMM delete: var/19700101T0000Z/b.file
[INFO] YYYY-MM-DDTHHMM delete: var/19700101T0000Z/c.file
[INFO] YYYY-MM-DDTHHMM delete: var/19800101T0000Z
[INFO] YYYY-MM-DDTHHMM delete: work/19700101T0000Z
[INFO] YYYY-MM-DDTHHMM delete: work/19800101T0000Z
__LOG__
#-------------------------------------------------------------------------------
rose suite-clean -q -y "${NAME}"
exit 0

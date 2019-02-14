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
# Test "rose suite-log --update TASK", without site/user configurations.
#-------------------------------------------------------------------------------
. $(dirname $0)/test_header
skip_all "skipped: TEST-DISABLED: Awaiting App upgrade to Python3"
#-------------------------------------------------------------------------------
if [[ $TEST_KEY_BASE == *-remote* ]]; then
    JOB_HOST=$(rose config 't' 'job-host')
    if [[ -z $JOB_HOST ]]; then
        skip_all '"[t]job-host" not defined'
    fi
    JOB_HOST=$(rose host-select -q $JOB_HOST)
fi
#-------------------------------------------------------------------------------
tests 4
#-------------------------------------------------------------------------------
# Run the suite.
export CYLC_CONF_PATH=
export ROSE_CONF_PATH=
TEST_KEY=$TEST_KEY_BASE
SUITE_RUN_DIR=$(mktemp -d --tmpdir=$HOME/cylc-run 'rose-test-battery.XXXXXX')
NAME=$(basename $SUITE_RUN_DIR)
if [[ -n ${JOB_HOST:-} ]]; then
    rose suite-run -q -C $TEST_SOURCE_DIR/$TEST_KEY_BASE --name=$NAME \
        --no-gcontrol --host=localhost \
        -D "[jinja2:suite.rc]HOST=\"$JOB_HOST\"" -- --no-detach --debug
else
    rose suite-run -q -C $TEST_SOURCE_DIR/$TEST_KEY_BASE --name=$NAME \
        --no-gcontrol --host=localhost -- --no-detach --debug
fi
#-------------------------------------------------------------------------------
TEST_KEY=$TEST_KEY_BASE-before-log.out
if [[ -n ${JOB_HOST:-} ]]; then
    run_fail "$TEST_KEY-log.out" \
        test -f $SUITE_RUN_DIR/log/job/1/my_task_2/01/job.out
else
    pass "$TEST_KEY-log.out"
fi
TEST_KEY=$TEST_KEY_BASE-command
run_pass "$TEST_KEY" rose suite-log -n $NAME -U 'my_task_2' --debug
file_cmp "$TEST_KEY.err" "$TEST_KEY.err" </dev/null
file_test "$TEST_KEY-log.out" $SUITE_RUN_DIR/log/job/1/my_task_2/01/job.out
#-------------------------------------------------------------------------------
rose suite-clean -q -y $NAME
exit 0

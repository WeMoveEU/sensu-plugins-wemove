#!/bin/bash
# Check if git repository in given directory is up to date.
# Originally snatched from https://github.com/mdebski/nagios-plugins/blob/master/check_git

PLUGINS_PATH="/usr/lib/nagios/plugins"

. $PLUGINS_PATH/utils.sh

if [ $# -ne 1 ]; then
 echo "UNKNOWN: $0 plugin needs 1 arguments - directory"
 exit $STATE_UNKNOWN
fi

(cd $1 && git status | grep "publish your local commits" > /dev/null 2>&1)
if [ $? -eq 0 ]; then
        echo "WARNING: unpushed changes in $1"
	exit $STATE_WARNING
fi

echo "OK: nothing to push"	
exit $STATE_OK
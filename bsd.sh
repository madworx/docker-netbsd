#!/bin/bash

set -eE
set -o pipefail

#
# We've  disabled the  status  reports  due to  the  fact that  stderr
# doesn't seem to be propagated properly when doing 'docker exec'.
#
if ! ssh root@localhost -p "${SSH_PORT}" -oConnectTimeout=10 /bin/echo ok > /dev/null 2>&1 ; then
    #echo "Checking SSH connectivity..." 1>&2
    while ! ssh root@localhost -p "${SSH_PORT}" -oConnectTimeout=3 /bin/echo ok > /dev/null 2>&1 ; do
        #echo "   Waiting..." 1>&2
        sleep 1
    done
fi

if [ -z "$1" ] ; then
   exec ssh root@localhost -t -p "${SSH_PORT}" -q /bin/sh
else
   exec ssh root@localhost -t -p "${SSH_PORT}" -q "$@"
fi

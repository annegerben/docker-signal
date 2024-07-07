#!/bin/sh

trap "exit" TERM QUIT INT
trap "kill_SIGNAL" EXIT

kill_SIGNAL() {
    RC=$?

    if [ -n "${SIGNAL_PID:-}" ]; then
        kill "$SIGNAL_PID"
        wait $SIGNAL_PID
        exit $?
    fi

    rm -f /tmp/.signal_restart_requested
    exit $RC
}

export HOME=/config
cd "$HOME"

while true
do
    # Start SIGNAL.
    /usr/bin/SIGNAL &

    # Wait until it dies.
    SIGNAL_PID=$!
    wait $SIGNAL_PID
    RC=$?
    SIGNAL_PID=

    # Exit now if SIGNAL exit was not requested by user.
    if [ ! -f /tmp/.signal_restart_requested ]; then
        exit $RC
    fi

    rm /tmp/.signal_restart_requested
done

# vim:ft=sh:ts=4:sw=4:et:sts=4

#!/bin/sh

INSTALL_PATH="./"
UNPACKER="nzbau_unpacker"
JOB_CHECKER="nzbau_jobchecker"
LOG_FILE="/var/log/nzbau.log"



case $1 in
start)
    echo -n "Starting nzbau... "
    
    # is the job checker already running?
    if [ -n "$(pgrep -f $INSTALL_PATH$JOB_CHECKER)" ]; then
        echo "$JOB_CHECKER is already started." >&2
    else
        # starts the job checker
        "$INSTALL_PATH$JOB_CHECKER.sh" 2>> $LOG_FILE &
        if [ $? -ne 0 ]; then
            echo "failed! Could not start $JOB_CHECKER." >&2
            exit 1
        fi
    fi
    
    
    
    # is the unpacker already running?
    if [ -n "$(pgrep -f $INSTALL_PATH$UNPACKER)" ]; then
        echo "$UNPACKER is already started." >&2
        # both job checker and unpacker are started. We can stop the launch script
        exit 1
    else
        # starts the unpacker
        "$INSTALL_PATH$UNPACKER.sh" 2>> $LOG_FILE &
        if [ $? -ne 0 ]; then
            echo "failed! Could not start $UNPACKER." >&2
            exit 1
        fi
    fi
    
    
    
    echo "done!"
    exit 0
    
    ;;
stop)
    echo -n "Stopping nzbau... "
    
    # is the job checker running?
    if [ -z "$(pgrep -f $INSTALL_PATH$JOB_CHECKER)" ]; then
        echo "failed! $JOB_CHECKER is not running." >&2
    else
        # stops the job checker
        pkill -TERM -f "$INSTALL_PATH$JOB_CHECKER"
        if [ $? -ne 0 ]; then
            echo "failed! Could not stop $JOB_CHECKER." >&2
            exit 1
        fi
    fi
    
    
    
    # is the unpacker running?
    if [ -z "$(pgrep -f $INSTALL_PATH$UNPACKER)" ]; then
        echo "failed! $UNPACKER is not running." >&2
        # neither job_checker nor unpacker is running. We can stop the launch script
        exit 1
    else
        # stops the unpacker
        pkill -TERM -f "$INSTALL_PATH$UNPACKER"
        if [ $? -ne 0 ]; then
            echo "failed! Could not stop $UNPACKER." >&2
            exit 1
        fi
    fi
    
    
    
    echo "done!"
    exit 0
    ;;
*)
    echo "Usage: /etc/init.d/nzbaud.sh {start|stop}"
    exit 1
    ;;
esac

exit 0


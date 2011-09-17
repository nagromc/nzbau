#!/bin/sh
# nzbau (NZB Auto Unpack/Unrar)
# Author: Morgan Courbet



# loads configuration file
. ./nzbau.conf

# gets a timestamp for logging
alias timestamp="date +[%Y-%m-%d\ %T]"

# gets the list of directories where work was found
lookforwork () {
    find "$1" -type d | sed 1d | while read directory
    do
        if [ "$(find "$directory" -prune -print -name \*.[pP][aA][rR]2 -o -name \*.[rR][aA][rR])" ] ; then
            echo "$directory/"
        fi
    done
}





### SCRIPT STARTS HERE ###

# creates the queue file if does not exist
if [ ! -f "$QUEUE_FILE" ]; then
    touch "$QUEUE_FILE"
fi

while [ true ] ; do
    # we will add each new job in the queue file
    lookforwork "$BASE_DIR$DOWNLOADED_DIR" | while read newjob
    do
        while read line; do
            if [ "$line" = "$newjob" ]; then
                #echo "$(timestamp) Job \"$newjob\" already in queue file"
                # no need to look for this job in the queue file. Steps to the next job
                continue 2
            fi
        done < "$QUEUE_FILE"
        
        echo "$(timestamp) Adding job \"$newjob\" in queue file"
        echo "$newjob" >> "$QUEUE_FILE"
    done
    
    sleep $SLEEP_TIME
done


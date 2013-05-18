#!/bin/sh
# nzbau (NZB Auto Unpack/Unrar)
# Author: Morgan Courbet



# loads configuration file
. ./nzbau.conf

# the name of the potential rewritten linuxren.sh script
LINUXREN_GOOD=linuxren_good.sh

# gets a timestamp for logging
alias timestamp="date +[%Y-%m-%d\ %T]"

# gets the last minute system load
alias sysload="cut /proc/loadavg -d ' ' -f 1"

# gets the first line of the queue file
alias nextjob="head -n 1 $QUEUE_FILE"

# deletes the first line of the queue file
alias delcurjob="sed -i 1d $QUEUE_FILE"

# extracts and execute a potential linuxren.sh file
# parameter 1: the path where to do the work
# returns: 0 if alright, another value otherwise
linuxren () {
    renamerar=`ls "$1" | grep "rename.rar$"`
    # if an *rename.rar exists
    if [ -f "$1$renamerar" ]; then
        echo "Found \"$1$renamerar\". Trying to unpack it..."
        
        islinuxrenpresent=`unrar l $1$renamerar | grep "^[[:space:]]*linuxren\.sh[[:space:]]*"`
        # if the script linuxren.sh is present
        if [ -n "$islinuxrenpresent" ]; then
            # tries to unpack it
            unrar x -o+ "$1$renamerar" linuxren.sh "$1"
            if [ $? -ne 0 ]; then
                return $?
            fi
            
            # removes bad things in this script
            sed "/\`\|\\$\|\.\/\|exec/d" "$1"linuxren.sh | sed -n "/^mv \"\?[^[:space:]]*\"\?[[:space:]]*\"\?[^[:space:]]*\"\?$/p ; /^#\!/p" > "$1$LINUXREN_GOOD"
            
            # makes the good script executable
            chmod u+x "$1$LINUXREN_GOOD"
            
            # saves the current working directory
            scriptwd=`pwd`
            # moves to the target path to rename files
            cd "$1"
            # renames files
            echo "Executing \"$1$LINUXREN_GOOD\"..."
            sh "$LINUXREN_GOOD"
            # comes back to home
            cd "$scriptwd"
            return 0
        fi
    else
        echo "Nothing to rename in \"$1\""
    fi
}

# gets the "main" par2 file from a folder
# parameter 1: the path where to find the "main" par2 file
mainpar2 () {
    ls "$1"*.[pP][aA][rR]2 | head -n 1
}

# checks which par2 file to scan
# parameter 1: the path where there is an assumed par2 file
# returns: 0 if alright, 255 if the par2 file were not found, another value
#          otherwise
repair () {
    echo "Checking files in $1..."
    
    # gets the main par2 file
    par2file="$(mainpar2 "$1")"
    # if the main par2 file exists
    if [ -f "$par2file" ]; then
        # verifies and, if necessary, repairs the files
        par2 repair "$par2file"
        if [ $? -ne 0 ]; then
            return $?
        else
            # deletes par2 files
            rm -f "$1"*.[pP][aA][rR]2
            return 0
        fi
    else
        echo "Unable to find main par2 file in \"$1\"" >&2
        return 255
    fi
}

# unpacks rar archive
# parameter 1: the path where to find the "main" par2 file
# returns: 0 if alright, > 0 if something bad happened while unraring
# @todo: assemble xxx.avi, xxx.avi.000, xxx.avi.001, etc.
# @todo: manage 7zip archives
unpack () {
    # archive_name.partxxx.rar fashion?
    partxxrar_file=`ls "$1" | grep "\.part[[:digit:]]\+\.rar$" | head -n 1`
    if [ -f "$1$partxxrar_file" ]; then
        unrar x -o+ "$1$partxxrar_file" "$BASE_DIR$UNPACKED_DIR`basename $1`/"
        if [ $? -ne 0 ]; then
            return $?
        else
            # deletes rar files
            rm -f "$1"*.[rR][aA][rR]
            return 0
        fi
    else
        # archive_name.r00 archive_name.r01 ... archive_name.rar fashion?
        rar_file=`ls "$1" | grep -v "\.rename\.rar$" | grep "\.rar$"`
        if [ -f "$1$rar_file" ]; then
            unrar x -o+ "$1$rar_file" "$BASE_DIR$UNPACKED_DIR`basename $1`/"
            if [ $? -ne 0 ]; then
                return $?
            else
                # deletes rar files
                rm -f "$1"*.[rR][aA0-9][rR0-9]
                return 0
            fi
        fi
    fi
}

# waits for next job
waitforwork () {
    sleep $SLEEP_TIME
    sysload="$(sysload)"
}





### SCRIPT STARTS HERE ###

# init
sysload="$(sysload)"

while [ true ] ; do
    # Step 1: checks if the system is not overloaded
    if [ $sysload \< $SYSLOAD_THRESHOLD ]; then
    
        # Step 2: checks the queue for work to be done
        pathtojob="$(nextjob)" >&2
        if [ $? -ne 0 ]; then
            echo "$(timestamp) The file \"$QUEUE_FILE\" could not be found. Maybe the job checker is not running?" >&2
        fi
        
        # if the queue file is empty
        if [ -z "$pathtojob" ] ; then
            # we wait and check again later for work
            waitforwork
            continue
        fi
        
        
        # if the directory does not exists
        if [ ! -d "$pathtojob" ] ; then
            echo "\"$pathtojob\" is not a valid path. Step to next job..." >&2
            # deletes the current job to process the next one
            delcurjob
            waitforwork
            continue
        fi
        
        
        echo "$(timestamp) Starting work in \"$pathtojob\"..."
        # Step 3: tries to rename the files with linuxren.sh
        echo "$(timestamp) Trying to rename files in \"$pathtojob\"..."
        linuxren "$pathtojob"
        if [ $? -ne 0 ]; then
            echo "$(timestamp) Unable to rename files from linuxren.sh in \"$pathtojob\". Removing job \"$pathtojob\" from queue" >&2
            delcurjob
            waitforwork
            continue
        fi
        
        
        # Step 4: tries to repair
        echo "$(timestamp) Trying to repair files in \"$pathtojob\"..."
        repair "$pathtojob"
        if [ $? -ne 0 ]; then
            case $? in
            255)
                # prints a message and goes on
                echo "$(timestamp) Could not find par2 files. Trying to unpack regardless repairing."
                ;;
            *)
                echo "$(timestamp) Unable to repair the files in \"$pathtojob\". Removing job \"$pathtojob\" from queue" >&2
                delcurjob
                waitforwork
                continue
                ;;
            esac
        fi
        
        
        # Step 5: tries to unpack
        echo "$(timestamp) Trying to unpack files in \"$pathtojob\"..."
        unpack "$pathtojob"
        if [ $? -ne 0 ]; then
            echo "$(timestamp) Unable to unpack the files in \"$pathtojob\". Removing job \"$pathtojob\" from queue" >&2
            delcurjob
            waitforwork
            continue
        fi
        
        
        echo "$(timestamp) The files in \"$pathtojob\" have been successfully unpacked!"
        # at this point, everything went ok. We can delete the current job...
        delcurjob
        # ...then wait and process the next one
        waitforwork
        
    fi
done


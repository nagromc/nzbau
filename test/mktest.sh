#!/bin/sh
# nzbau (NZB Auto Unpack/Unrar) installer
# Author: Morgan Courbet



repairAndCheck=0



init () {
    if [ $# -ne 3 ]; then
        return 1
    fi

    fileUrl="$1"
    fileName=`basename $fileUrl`
    
    # removes all file related to the original file
    rm -r "$3"
    # gets the file
    wget -nc -P "$3" "$fileUrl"
    cd "$3"
    # makes a backup of the original file
    cp "$fileName" "$fileName.org"
    if [ "$2" = rar ]; then
        # makes multiple rar files
        rar a -v1k "$fileName.rar" "$fileName"
        # makes par2 files
        par2create -r20 -n3 "$fileName" *.rar
    elif [ "$2" = splt ]; then
        # splits the original file into pieces
        split --suffix-length=3 --numeric-suffixes --bytes=1000 "$fileName" "$fileName."
        # makes par2 files
        par2create -r20 -n3 "$fileName" *.[0-9][0-9][0-9]
    else
        return 1
    fi
    # removes the original file
    rm "$fileName"
    cd ..
}



checkUnrar () {
    if [ $repairAndCheck = 1 ]; then
        cd "$2"
        # repairs the files if necessary
        par2repair "$1.par2"
        # unrar the files
        unrar x -o+ "$1.part1.rar"
        # prints diff to make sure the files are identical
        diff "$1" "$1.org"
        cd ..
    fi
}



checkJoined () {
    if [ $repairAndCheck = 1 ]; then
        cd "$2"
        # repairs the files if necessary
        par2repair "$2/$1.par2"
        # joins the files
        cat "$2/$1".[0-9][0-9][0-9] > "$2/$1"
        # prints diff to make sure the files are identical
        diff "$2/$1" "$2/$1.org"
        cd ..
    fi
}



# test 1 : everything is okay (RAR)
test1 () {
    basefolder=01
    allOkUrl="http://www.google.com/intl/en_ALL/images/srpr/logo1w.png"
    allOkName=`basename "$allOkUrl"`

    init "$allOkUrl" rar "$basefolder"
    checkUnrar "$allOkName" "$basefolder"
}



# test 2 : one file is missing (RAR)
test2 () {
    basefolder=02
    missingFileUrl="http://www.google.com/intl/en_ALL/images/srpr/logo1w.png"
    missingFileName=`basename "$missingFileUrl"`

    init "$missingFileUrl" rar "$basefolder"
    # removes a file
    rm "$basefolder/$missingFileName.part2.rar"
    checkUnrar "$missingFileName" "$basefolder"
}



# test 3 : altered file (RAR)
test3 () {
    basefolder=03
    alteredFileUrl="http://www.google.com/intl/en_ALL/images/srpr/logo1w.png"
    alteredFileName=`basename "$alteredFileUrl"`

    init "$alteredFileUrl" rar "$basefolder"
    # add some random string at the end of the file
    echo $RANDOM >> "$basefolder/$alteredFileName.part2.rar"
    checkUnrar "$alteredFileName" "$basefolder"
}



# test 4 : everything is okay (split)
test4 () {
    basefolder=04
    allOkUrl="http://www.google.com/intl/en_ALL/images/srpr/logo1w.png"
    allOkName=`basename "$allOkUrl"`

    init "$allOkUrl" splt "$basefolder"
    checkJoined "$allOkName" "$basefolder"
}



# test 5 : one file is missing (split)
test5 () {
    basefolder=05
    missingFileUrl="http://www.google.com/intl/en_ALL/images/srpr/logo1w.png"
    missingFileName=`basename "$missingFileUrl"`

    init "$missingFileUrl" splt "$basefolder"
    # removes a file
    rm "$basefolder/$missingFileName.002"
    checkJoined "$missingFileName" "$basefolder"
}



# test 6 : altered file (split)
test6 () {
    basefolder=06
    alteredFileUrl="http://www.google.com/intl/en_ALL/images/srpr/logo1w.png"
    alteredFileName=`basename "$alteredFileUrl"`

    init "$alteredFileUrl" splt "$basefolder"
    # add some random string at the end of the file
    echo $RANDOM >> "$basefolder/$alteredFileName.002"
    checkJoined "$alteredFileName" "$basefolder"
}



test1
test2
test3
test4
test5
test6


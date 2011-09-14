nzbau (*NZB* *A*uto *U*npack/*U*nrar)
=====================================

nzbau allows Synology's NASes users to automatically repair and unpack NZB 
downloads from DSM's Download Station.


Requirements
============

This script needs the command `uptime` to be installed on your Synology. It can 
be installed with the package `procps`:

    ipkg install procps

Please see the [official synology wiki](http://forum.synology.com/wiki/index.php/How_to_Install_Bootstrap)
for more details about using `ipkg` on your Synology.


Usage
=====

To run properly, you need to execute `nzbau\_jobchecker.sh` **and** 
`nzbau\_unpacker.sh`. The second script will unpack the "raw downloads" detected 
by the first one.

You can edit `nzbau.conf` to configure the scripts.


Todo
====

* Move unpacked files into a specific directory
* Send email when a file is unpaked or when an error occurs
* Add a start script to run `nzbau` automatically with the Synology.
* Integrate nzbau in the Synology's package center.


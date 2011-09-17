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

You can edit `nzbau.conf` to configure the scripts.

To run properly, you need to execute both `nzbau_jobchecker.sh` **and** 
`nzbau_unpacker.sh`. The second script will unpack the "raw downloads" detected 
by the first one.

It is possible to run the scripts when the system boots with the launch script 
`S99nzbaud.sh`. Make sure the permissions of the launch script are set to 755 
(`chmod 755 S99nzbaud.sh`) and put it in `/usr/local/etc/rc.d/`.
Note that `nzbaud.sh` is prefixed with `S99` to indicate to the Synology system
that this script must be executed last.


Todo
====

* Move unpacked files into a specific directory
* Send email when a file is unpaked or when an error occurs
* Add a start script to run `nzbau` automatically with the Synology.
* Integrate nzbau in the Synology's package center.


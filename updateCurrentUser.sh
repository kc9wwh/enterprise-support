#!/bin/sh

currentUser=$(/usr/bin/stat -f%Su /dev/console)
/usr/local/bin/jamf recon -endUsername $currentUser

exit 0
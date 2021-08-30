#!/bin/bash

if ! [[ $EUID = 0 ]]; then
    echo "Please run this script with 'sudo'..."
    exit 1
fi

for drive in $(ls /dev/sd[a-z][1-9])
do
    echo -en "$drive \t"
    smartctl -H $drive | grep "Health Status"
done

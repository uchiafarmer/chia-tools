#!/bin/bash
# Runs a smart-health scan of attached storage

if ! [[ $EUID = 0 ]]; then
    echo "Please run this script with 'sudo'..."
    exit 1
fi

for drive in $(ls /dev/sd*[1-9])
do
    echo -en "$drive \t"
    smartctl -H $drive | grep "Health Status"
done

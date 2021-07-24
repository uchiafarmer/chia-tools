#!/bin/bash
#
# MIT License
# 
# Copyright (c) 2021 uchiafarmer
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Plot Filter -- A small script to separate OG plots from NFT plots.

DEBUG=true

function usage {
    echo
    echo "usage: ./plotfilter.sh [OPTIONS...]"
    echo
    echo -e "  -t\t target directory (default: current directory)"
    echo -e "  -d\t destination directory "\
                        "(default: '[target directory]/plots-og')"
    echo -e "  -i\t interactive mode (default: false)"
    echo -e "  -v\t verbose mode"
    echo -e "  -h\t displays this help information"
    echo
    exit 1
}

# Get options
while getopts t:d:vih OPT
do
    case "$OPT" in
        t) TARGET_DIR=$OPTARG;;
        d) DEST_DIR=$OPTARG;;
        i) INTERACTIVE=true;;
        v) VERBOSE=true;;
        h) usage;;
        *) echo
            echo "bad option:"
            usage;;
    esac
done

# load defaults
if [ -z $VERBOSE ]; then
    VERBOSE=false
fi
if [ -z $TARGET_DIR ]; then
    TARGET_DIR=$PWD
fi
if [ -z $DEST_DIR ]; then
    DEST_DIR=$TARGET_DIR/plots-og
fi
if [ -z $INTERACTIVE ]; then
    INTERACTIVE=false
fi

if $DEBUG; then 
    echo
    echo "TARGET_DIR=$TARGET_DIR"
    echo "DEST_DIR=$DEST_DIR"
    echo "INTERACTIVE=$INTERACTIVE"
    echo "VERBOSE=$VERBOSE"
    echo
fi

# Check if path directory exists
if [ -d $TARGET_DIR ]; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "target directory found: $TARGET_DIR"
    fi
else
    echo "error: target directory not found"
    echo
    exit 1
fi

# Check if destination directory  exists. if not, create it
if [ -d $DEST_DIR ]; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then 
        echo "destination directory found: $DEST_DIR"
    fi
else
    if [[ $VERBOSE = true || $DEBUG = true ]]; then 
        echo -n "destination directory not found, creating new directory: "
        echo $DEST_DIR
    fi
    mkdir -p $DEST_DIR
    if ! [ $? = 0 ]; then
        echo "error: could not create destination directory"
        echo
        exit 1
    fi
fi

# chia checking code
# check for chia environment
if echo $VIRTUAL_ENV | grep chia-blockchain &> /dev/null; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "'chia-blockchain' virtual environment detected. proceeding."
    fi
else
    echo
    echo "Please run this program with the 'chia-blockchain'" \
            "environment activated"
    echo
    exit 1
fi

# Check if $TARGET_PATH is in `chia plots show`
#     if not, add to chia plots with `chia plots add -d $TARGET_PATH`
#  
# CHECK_OUTPUT=$(chia plots check -g $PATH -n $MIN_PROOFS)
#
# Remove path from `chia plots`
#
# Parse $CHECK_OUTPUT to SED
#   Search for plot filename
#       Save plot name to variable PLOT_FNAME
#   Add next line (pool key line)
#       Check for pool key, save value to variable POOL_KEY
#       if [ $POOL_KEY = 'None']
#           move plot to dir $DESTN_DIR
#           $DESTN_DIR could be another drive, use proper write method.
#               `mv` plot to $DESTN_DIR
#
# Repeat until all plots checked
#
# Print summary 
#   n plots found
#
# End of program.

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
# 
# Usage Example: ./plotfilter.sh -t /media/foo/bar
#            or: ./plotfilter.sh -n -t /media/foo/bar 
#            or: ./plotfilter.sh -t /media/foo/bar -d /media/foo/bar/og-plots

DEBUG=false

function usage {
    echo
    echo "usage: plotfilter [OPTIONS...]"
    echo
    echo "Example:   plotfilter -n -t /media/foo/bar "
    echo "     or:   plotfilter -t /media/foo/bar "
    echo "     or:   plotfilter -t /media/foo/bar -d" \
         "/media/foo/bar/og-plots"
    echo
    echo -e "  -t <PATH>\t target directory [OPTIONAL]"
    echo -e "\t\t (Default: 'current working directory')"
    echo -e "  -d <PATH>\t destination directory [OPTIONAL]"
    echo -e "\t\t (Default: '<target directory>/og-plots')"
    echo -e "  -n\t\t dry run (no files will be moved or modified)"
    echo -e "  -v\t\t verbose mode"
    echo -e "  -h\t\t displays this help information"
    echo
    echo "NOTE: Use absolute pathnames for <PATH> (e.g /home/<USER HOME>/og-plots)"
    echo
    exit 1
}

# Get options
while getopts d:hnt:v OPT
do
    case "$OPT" in
        d) DEST_DIR=$OPTARG;;
        h) usage;;
        n) DRY_RUN=true;;
        t) TARGET_DIR=$OPTARG;;
        v) VERBOSE=true;;
        *) echo "Uknown option"
            usage;;
    esac
done

# load defaults, check options
if [ -z $TARGET_DIR ]; then
    TARGET_DIR=$PWD
fi
if [ -z $DEST_DIR ]; then
    DEST_DIR=$TARGET_DIR/og-plots
fi
if [ -z $DRY_RUN ]; then
    DRY_RUN=false
fi
if [ -z $VERBOSE ]; then
    VERBOSE=false
fi

if $DEBUG; then 
    echo "$(date): debug information:"
    echo
    echo "TARGET_DIR=$TARGET_DIR"
    echo "DRY_RUN=$DRY_RUN"
    echo "DEST_DIR=$DEST_DIR"
    echo "VERBOSE=$VERBOSE"
    echo
fi

# Notify user if this is a dry run
if $DRY_RUN; then
    echo "$(date): ========================="
    echo "$(date): INFO: Dry run in progress"
    echo "$(date): ========================="
fi

# Check if path directory exists
if [ -d $TARGET_DIR ]; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "$(date): Target directory found: $TARGET_DIR"
    fi
else
    echo "$(date): Error: target directory not found"
    echo
    exit 1
fi

# Check if destination directory  exists. if not, create it
if [ -d $DEST_DIR ]; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then 
        echo "$(date): Destination directory found: $DEST_DIR"
    fi
    DEST_DIR_WAS_CREATED=false
else
    if [[ $VERBOSE = true || $DEBUG = true ]]; then 
        echo -n "$(date): Destination directory not found," \
                "creating new directory: "
        echo $DEST_DIR
    fi
    if $DRY_RUN; then
        if [[ $VERBOSE = true || $DEBUG = true ]]; then 
            echo "$(date): Dry run. Skipping."
        fi
    else
        # Make destination directory
        mkdir -p $DEST_DIR

        # Check successful operation or fail
        if ! [ $? = 0 ]; then
            echo "$(date): Error: could not create destination directory"
            echo
            exit 1
        else
            if [[ $VERBOSE = true || $DEBUG = true ]]; then 
                echo "$(date): Destination directory was created: $DEST_DIR"
            fi
            DEST_DIR_WAS_CREATED=true
        fi
    fi
fi

# chia checking code
# check for chia environment
if echo $VIRTUAL_ENV | grep chia-blockchain &> /dev/null; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "$(date): 'chia-blockchain' virtual environment detected:" \
             "proceeding"
    fi
else
    echo "$(date): Please run this program with the 'chia-blockchain'" \
            "environment activated"
    exit 1
fi

# Check if target directory is in `chia plots show`
IFS=$'\n'
if chia plots show | grep -i $TARGET_DIR &> /dev/null; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "$(date): Target directory already exists in 'chia plot' paths"
    fi
    ADDED_TO_CHIA_PLOTS=false
else
    echo "$(date): WARNING: Target directory does not exist" \
                  "in 'chia plots' paths"
    echo "$(date): Adding target directory to 'chia plots'"
    chia plots add -d $TARGET_DIR &> /dev/null
    if chia plots show | grep -i $TARGET_DIR &> /dev/null; then
        echo "$(date): Target directory successfully added."
        ADDED_TO_CHIA_PLOTS=true
    else
        echo "$(date): Error. could not verify target directory was added to "\
             "'chia plots' paths"
        echo
        exit 1
    fi
fi

# Grab 'chia plots check' output
echo "$(date): Scanning target directory..."
PLOTS_CHECK=$(chia plots check -g $TARGET_DIR -n 5 2>&1)
echo "$(date): Scan complete"

# If target directory was added to 'chia plots' by this program,
# remove it here
if $ADDED_TO_CHIA_PLOTS; then
    echo "$(date): Cleaning up." \
         "Removing target directory from 'chia plots' paths"
    chia plots remove -d $TARGET_DIR &> /dev/null
fi
# Check plots for OG plots
echo "$(date): Checking plots... "
OG_COUNT=0
MOVED_COUNT=0
for line in $PLOTS_CHECK
do
    # Search for plot filename
    if echo $line | grep "Testing plot" &> /dev/null
    then
        # Store plot filename
        PLOT_FNAME=$(echo $line | awk '{ print $8 }')
        if $DEBUG; then
            echo "$(date): Found plot: $PLOT_FNAME"
        fi
    fi
    
    # Check for pool key
    if echo $line | grep "Pool public key:" &> /dev/null
    then
        # Store key value
        POOL_PK=$(echo $line | awk '{ print $9 }')
        if $DEBUG; then
            echo "$(date): Pool public key: '$POOL_PK'"
        fi

        # Check if key is equal to None
        # Why doesn't [[ "$POOL_PK" == "None" ]] work?
        if echo $POOL_PK | grep 'None' &> /dev/null
        then
            if [[ $VERBOSE = true || $DEBUG = true ]]; then
                echo "$(date): NFT plot found: $PLOT_FNAME"
                if $DEBUG; then
                    echo "$(date): Skipping"
                fi
            fi
        else
            # If not None, move plot to desination directory
            echo "$(date): OG plot found: $PLOT_FNAME"
            if $DRY_RUN; then
                if $DEBUG; then
                    echo "$(date): Dry run. Skipping."
                fi
            else
                if [[ $VERBOSE = true || $DEBUG = true ]]; then
                    echo "$(date): Moving plot to: $DEST_DIR"
                fi
                mv $PLOT_FNAME $DEST_DIR
                if ! [ $? = 0 ]; then
                    echo "$(date): Copy failed."
                else
                    if $DEBUG; then
                        echo "$(date): Move command finished sucessfully."
                    fi
                    (( MOVED_COUNT++ ))
                fi
            fi
            (( OG_COUNT++ ))
        fi
    fi
    if $DEBUG; then
        sleep 0.1
    fi
# Repeat until all plots checked
done
echo "$(date): Finished."

# If no plots were found, and $DEST_DIR was created, remove it.
if [[ $DEST_DIR_WAS_CREATED = true && $OG_COUNT = 0 ]]; then
        if [[ $VERBOSE = true || $DEBUG = true ]]; then
            echo "$(date): Clean up. Destination directory was not needed." \
            "Removing..."
        fi
        # Remove unused destination directory
        rm -r $DEST_DIR
fi

# Print summary 
echo "$(date): === Summary ==="
echo "$(date): OG plots found: $OG_COUNT"
echo "$(date): OG plots moved: $MOVED_COUNT"
if [[ $MOVED_COUNT > 0 ]]; then
    echo "$(date): Moved plots location: $DEST_DIR"
fi

# End of program.
echo "$(date): Program complete."

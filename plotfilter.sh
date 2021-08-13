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
TIMESTAMP=true

function usage {
    # Display usage instructions
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
    echo -e "  -o <FILE>\t output list of discovered plots to csv file"
    echo -e "  -v\t\t verbose mode"
    echo -e "  -h\t\t displays this help information"
    echo
    echo "NOTE: Use absolute pathnames for <PATH>" \
         "(e.g /home/<USER HOME>/og-plots)"
    echo
    exit 1
}

function tstamp {
    # Add a timestamp to output
    DATE_FORMAT="+%F %T.%3N"
    if $TIMESTAMP; then
        STAMP=$(date "$DATE_FORMAT")
        echo "${STAMP} "
    fi
}

# Get options
while getopts d:hnt:vo: OPT
do
    case "$OPT" in
        d) DEST_DIR=$OPTARG;;
        h) usage;;
        n) DRY_RUN=true;;
        o) OUTPUT_FILE=$OPTARG;;
        t) TARGET_DIR=$OPTARG;;
        v) VERBOSE=true;;
        *) echo "Uknown option"
            usage;;
    esac
done

# load defaults, check options
if [ -z $TARGET_DIR ]; then
    TARGET_DIR=$PWD
else
    # Remove trailing slash if there is one
    TARGET_DIR=${TARGET_DIR%/}
fi
if [ -z $DEST_DIR ]; then
    DEST_DIR=$TARGET_DIR/og-plots
else
    # Remove trailing slash if there is one
    DEST_DIR=${DEST_DIR%/}
fi
if [ -z $DRY_RUN ]; then
    DRY_RUN=false
fi
if [ -z $VERBOSE ]; then
    VERBOSE=false
fi

if $DEBUG; then 
    echo "$(tstamp) debug information:"
    echo
    echo "TARGET_DIR=$TARGET_DIR"
    echo "DRY_RUN=$DRY_RUN"
    echo "DEST_DIR=$DEST_DIR"
    echo "VERBOSE=$VERBOSE"
    echo
fi

# Notify user if this is a dry run
if $DRY_RUN; then
    echo "$(tstamp) ========================="
    echo "$(tstamp) INFO: Dry run in progress"
    echo "$(tstamp) ========================="
fi

# Check if target directory exists
if [ -d $TARGET_DIR ]; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "$(tstamp) Target directory found: $TARGET_DIR"
    fi
else
    echo "$(tstamp) Error: target directory not found"
    echo
    exit 1
fi

# Check if destination directory exists. if not, create it
if [ -d $DEST_DIR ]; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then 
        echo "$(tstamp) Destination directory found: $DEST_DIR"
    fi
    DEST_DIR_WAS_CREATED=false
else
    if [[ $VERBOSE = true || $DEBUG = true ]]; then 
        echo -n "$(tstamp) Destination directory not found," \
                "creating new directory: "
        echo $DEST_DIR
    fi
    if $DRY_RUN; then
        if [[ $VERBOSE = true || $DEBUG = true ]]; then 
            echo "$(tstamp) Dry run. Skipping."
        fi
    else
        # Make destination directory
        mkdir -p $DEST_DIR

        # Check successful operation or fail
        if ! [ $? = 0 ]; then
            echo "$(tstamp) Error: could not create destination directory"
            echo
            exit 1
        else
            if [[ $VERBOSE = true || $DEBUG = true ]]; then 
                echo "$(tstamp) Destination directory was created: $DEST_DIR"
            fi
            DEST_DIR_WAS_CREATED=true
        fi
    fi
fi

# chia checking code
# check for chia environment
if echo $VIRTUAL_ENV | grep chia-blockchain &> /dev/null; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "$(tstamp) 'chia-blockchain' virtual environment detected:" \
             "proceeding"
    fi
else
    echo "$(tstamp) Please run this program with the 'chia-blockchain'" \
            "environment activated"
    exit 1
fi

# Check if target directory is in `chia plots show`
IFS=$'\n'
if chia plots show | grep -i $TARGET_DIR &> /dev/null; then
    if [[ $VERBOSE = true || $DEBUG = true ]]; then
        echo "$(tstamp) Target directory already exists in 'chia plot' paths"
    fi
    ADDED_TO_CHIA_PLOTS=false
else
    echo "$(tstamp) WARNING: Target directory does not exist" \
                  "in 'chia plots' paths"
    echo "$(tstamp) Adding target directory to 'chia plots'"
    chia plots add -d $TARGET_DIR &> /dev/null
    if chia plots show | grep -i $TARGET_DIR &> /dev/null; then
        echo "$(tstamp) Target directory successfully added."
        ADDED_TO_CHIA_PLOTS=true
    else
        echo "$(tstamp) Error. could not verify target directory was added "\
             "to 'chia plots' paths"
        echo
        exit 1
    fi
fi

# Create a tempfile for plot check output
if $DEBUG; then
    echo "$(tstamp) Creating temp file for 'chia plots check' output"
fi
TEMP_FILE=$(mktemp -t tmp.XXXXXX)
if [ $? = 0 ]; then
    if $DEBUG; then
        echo "$(tstamp) Created temp file: $TEMP_FILE"
    fi
else
    echo "Failed to create temporary file for scanning process."
    echo
    exit 1
fi

# Check if output file exists
if [ -f $OUTPUT_FILE ]; then
    if $DEBUG; then
        echo "$(tstamp) $OUTPUT_FILE exists, overwriting..."
    fi
    cat /dev/null &> $OUTPUT_FILE
else
    if $DEBUG; then
        echo "$(tstamp) $OUTPUT_FILE not found. Creating..."
    fi
    touch $OUTPUT_FILE
fi

# Run 'chia plots check' in the background and output to tempfile
echo "$(tstamp) Scanning target directory"
chia plots check -g $TARGET_DIR -n 5 2> $TEMP_FILE &
PID=$!
if $DEBUG; then
    echo "$(tstamp) Started background process: $PID"
fi

# trap Ctrl-C to clean up sub-procress
trap "kill $PID; echo; exit 1;" SIGINT

echo "$(tstamp) This may take awhile, please be patient... "
STARTED=$(tstamp)

function check_progress {
    # Show progress of 'chia plots check' scan
    TOTAL=$(cat $TEMP_FILE | grep 'Loaded' | awk '{ print $10 }')
    PROGRESS=$(cat $TEMP_FILE | grep 'Testing plot' | wc -l)
    echo -e -n "$STARTED Progress: (${PROGRESS:-0}/${TOTAL:-0})\r"
}

# While waiting for process to complete, show progress
while [ -d /proc/$PID ]
do
    check_progress
    sleep 0.1
done
# When the process is complete show final result
check_progress

# Get 'chia plots check' output
PLOTS_CHECK=$(cat $TEMP_FILE)
echo
echo "$(tstamp) Scan complete"

# remove trap for normal operation
trap - SIGINT

# Clean up temp file
if $DEBUG; then
    echo "$(tstamp) Clean up. Removing temp file: $TEMP_FILE"
fi
rm $TEMP_FILE

# If target directory was added to 'chia plots' by this program,
# remove it here
if $ADDED_TO_CHIA_PLOTS; then
    echo "$(tstamp) Cleaning up." \
         "Removing target directory from 'chia plots' paths"
    chia plots remove -d $TARGET_DIR &> /dev/null
fi

# Check plots for OG plots
echo "$(tstamp) Checking plots... "
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
            echo "$(tstamp) Found plot: $PLOT_FNAME"
        fi
    fi
    
    # Check for pool key
    if echo $line | grep "Pool public key:" &> /dev/null
    then
        # Store key value
        POOL_PK=$(echo $line | awk '{ print $9 }')
        if $DEBUG; then
            echo "$(tstamp) Pool public key: '$POOL_PK'"
        fi

        # Check if key is equal to None
        if echo $POOL_PK | grep 'None' &> /dev/null
        then
            # If output file specified, add to file
            if ! [ -z $OUTPUT_FILE ]; then
                echo "NFT,$PLOT_FNAME" >> "$OUTPUT_FILE"
            fi

            if [[ $VERBOSE = true || $DEBUG = true ]]; then
                echo "$(tstamp) NFT plot found: $PLOT_FNAME"
                if $DEBUG; then
                    echo "$(tstamp) Skipping"
                fi
            fi
        else
            # If output file specified, add to file
            if ! [ -z $OUTPUT_FILE ]; then
                echo "OG,$PLOT_FNAME" >> "$OUTPUT_FILE"
            fi
            # If not None, move plot to desination directory
            echo "$(tstamp) OG plot found: $PLOT_FNAME"
            if $DRY_RUN; then
                if $DEBUG; then
                    echo "$(tstamp) Dry run. Skipping."
                fi
            else
                if [[ $VERBOSE = true || $DEBUG = true ]]; then
                    echo "$(tstamp) Moving plot to: $DEST_DIR"
                fi
                mv $PLOT_FNAME $DEST_DIR
                if ! [ $? = 0 ]; then
                    echo "$(tstamp) Copy failed."
                else
                    if $DEBUG; then
                        echo "$(tstamp) Move command finished sucessfully."
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
echo "$(tstamp) Finished."

# If no plots were found, and $DEST_DIR was created, remove it.
if [[ $DEST_DIR_WAS_CREATED = true && $OG_COUNT = 0 ]]; then
        if [[ $VERBOSE = true || $DEBUG = true ]]; then
            echo "$(tstamp) Clean up. Destination directory was not needed." \
            "Removing..."
        fi
        # Remove unused destination directory
        rm -r $DEST_DIR
fi

# Print summary 
echo "$(tstamp) === Summary ==="
echo "$(tstamp) OG plots found: $OG_COUNT"
echo "$(tstamp) OG plots moved: $MOVED_COUNT"
if [[ $MOVED_COUNT > 0 ]]; then
    echo "$(tstamp) Moved plots to location: $DEST_DIR"
    echo "$(tstamp) *** Please add this directory to your Chia program if" \
        "you wish to continue farming with them. ***"
fi

echo "$(tstamp) Program complete."
echo
# End of program.

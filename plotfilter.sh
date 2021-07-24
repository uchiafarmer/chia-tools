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

# TODO
# 
# Check for the arguments
#     -t Target path(s)
#          If no paths specified use $PWD
#     -d Directory to place OG plots (Default: plots-og)
#     -v Verbosity
#     -i Interactive Mode?
#     -h Print the help string
# 
# Check if path directory exists:
# If not,
#   print error msg 'directory does not exist'
#   exit
#
# Check if $DESTN_DIR exists, if not, create it in $TARGET_PATH dir
# 
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

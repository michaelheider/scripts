#!/bin/bash

# first argument: filename
# transform specified .tif to a .pdf
#
# Michael Heider
# 2021-07-23

# print passed message to stderr in red
function error {
	RED='\033[0;31m'
	RESET='\033[0m'
	>&2 echo -e "$RED$1$RESET"
}

# check that libtiff-tools is installed, provides `tiff2pdf` command
REQUIRED_PKG="libtiff-tools"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
if [ "" = "$PKG_OK" ]; then
	error "Package $REQUIRED_PKG is required. Please install." 
	exit 2
fi

# get params
if (( $# == 0 )); then
	error "Missing first parameter: File name."
	exit 1
fi
oldName="$1"

# check file exists
if [ ! -f "$oldName" ]; then
	error "'$oldName' does not exist."
	exit 1
fi

# check correct file type
type=$(file -b "$oldName" | awk '{print $1;}')
if [ "$type" != "TIFF" ]; then
	error "'$oldName' is not in TIFF format."
	exit 1
fi

# strip .tif if avaiable and add .pdf
newName="${oldName%.tif}.pdf"

tiff2pdf "$oldName" -o "$newName"

echo "write $newName"

